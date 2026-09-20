-- =========================================================================
-- 0033_weekly_digest_platform_overview.sql
-- 1. Weekly digest: once a week (day + hour per center, default Thursday 17:00
--    in the center's timezone) every active student's family gets an inbox
--    notification with the week in numbers. One hourly job; a bookkeeping
--    table makes each center's digest go out once per day at most.
-- 2. Platform owner overview: centers, usage, job health - and the ONLY door
--    for changing a center's status / plan (0031 closed the table columns).
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. weekly digest
-- ---------------------------------------------------------------------
create table if not exists public.weekly_digests_sent (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  sent_on         date not null,
  sent_at         timestamptz not null default now(),
  primary key (organization_id, sent_on)
);
alter table public.weekly_digests_sent enable row level security;
revoke all on public.weekly_digests_sent from anon, authenticated;

create or replace function public._digest_setting(p_org uuid, p_key text, p_default integer)
returns integer language sql stable security definer set search_path = public as $$
  select case when public.org_setting(p_org, p_key, p_default::text) ~ '^[0-9]{1,2}$'
              then public.org_setting(p_org, p_key, p_default::text)::integer else p_default end;
$$;

create or replace function public.send_weekly_digests(p_force_org uuid default null)
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; v_local timestamp; v_users uuid[]; v_from timestamptz; v_n integer; v_pts integer;
        v_att_ok integer; v_att_all integer; v_body text; v_sent integer := 0;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o
           where o.status in ('trial', 'active') and (p_force_org is null or o.id = p_force_org)
  loop
    continue when public.org_setting(e.id, 'weekly_digest_enabled', 'true') <> 'true';
    v_local := now() at time zone e.tz;
    continue when p_force_org is null and (extract(dow from v_local)::integer <> public._digest_setting(e.id, 'weekly_digest_dow', 4)
                                           or extract(hour from v_local)::integer <> public._digest_setting(e.id, 'weekly_digest_hour', 17));
    -- once per local day
    insert into public.weekly_digests_sent (organization_id, sent_on) values (e.id, v_local::date) on conflict do nothing;
    continue when not found and p_force_org is null;

    v_from := ((v_local::date - 6)::timestamp) at time zone e.tz;
    for s in select id, full_name from public.students_profile where organization_id = e.id and status = 'active' loop
      v_users := public._student_family_users(s.id);
      continue when coalesce(array_length(v_users, 1), 0) = 0;

      select count(*), coalesce(sum(points_awarded), 0) into v_n, v_pts
        from public.daily_achievements where student_id = s.id and created_at >= v_from;
      select count(*) filter (where status::text in ('present', 'late')), count(*) filter (where status::text in ('present', 'late', 'absent'))
        into v_att_ok, v_att_all from public.attendance where student_id = s.id and session_date >= v_local::date - 6;

      v_body := case when v_n > 0 then 'سمّع ' || v_n || ' مرة · +' || v_pts || ' نقطة' else 'لم يُسجَّل تسميع هذا الأسبوع' end
             || case when v_att_all > 0 then ' · حضر ' || v_att_ok || ' من ' || v_att_all || ' أيام' else '' end;
      perform public._notify(e.id, v_users, 'weekly_digest', 'ملخص أسبوع ' || s.full_name, v_body, s.id);
      v_sent := v_sent + 1;
    end loop;
  end loop;
  return v_sent;
end;
$$;

create or replace function public.get_digest_settings(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return jsonb_build_object('enabled', public.org_setting(p_org, 'weekly_digest_enabled', 'true') = 'true',
                            'dow', public._digest_setting(p_org, 'weekly_digest_dow', 4),
                            'hour', public._digest_setting(p_org, 'weekly_digest_hour', 17));
end;
$$;

create or replace function public.set_digest_settings(p_org uuid, p_enabled boolean, p_dow integer, p_hour integer)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if p_dow is null or p_dow < 0 or p_dow > 6 then raise exception 'يوم غير صحيح'; end if;
  if p_hour is null or p_hour < 0 or p_hour > 23 then raise exception 'ساعة غير صحيحة'; end if;
  insert into public.organization_settings (organization_id, key, value, updated_at) values
    (p_org, 'weekly_digest_enabled', case when coalesce(p_enabled, false) then 'true' else 'false' end, now()),
    (p_org, 'weekly_digest_dow', p_dow::text, now()),
    (p_org, 'weekly_digest_hour', p_hour::text, now())
  on conflict (organization_id, key) do update set value = excluded.value, updated_at = now();
end;
$$;

select cron.schedule('weekly-digest', '5 * * * *', 'select public.send_weekly_digests()');

-- ---------------------------------------------------------------------
-- 2. platform owner
-- ---------------------------------------------------------------------
create or replace function public.platform_overview()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_platform_owner() then raise exception 'غير مصرّح'; end if;
  return jsonb_build_object(
    'totals', jsonb_build_object(
      'orgs', (select count(*) from public.organizations),
      'trial', (select count(*) from public.organizations where status = 'trial'),
      'active', (select count(*) from public.organizations where status = 'active'),
      'suspended', (select count(*) from public.organizations where status = 'suspended'),
      'cancelled', (select count(*) from public.organizations where status = 'cancelled'),
      'new_orgs_30d', (select count(*) from public.organizations where created_at > now() - interval '30 days'),
      'users', (select count(*) from auth.users),
      'students', (select count(*) from public.students_profile where status = 'active'),
      'recitations_7d', (select count(*) from public.daily_achievements where created_at > now() - interval '7 days'),
      'recitations_30d', (select count(*) from public.daily_achievements where created_at > now() - interval '30 days'),
      'chat_images', (select count(*) from storage.objects where bucket_id = 'chat-images'),
      'chat_images_mb', coalesce((select round(sum((metadata ->> 'size')::numeric) / 1048576, 1) from storage.objects where bucket_id = 'chat-images'), 0)),
    'orgs', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', o.id, 'name', o.name, 'slug', o.slug, 'status', o.status, 'plan_id', o.plan_id, 'plan', p.name,
        'created_at', o.created_at, 'trial_ends_at', o.trial_ends_at,
        'students', (select count(*) from public.students_profile s where s.organization_id = o.id and s.status = 'active'),
        'teachers', (select count(*) from public.organization_members m where m.organization_id = o.id and m.role = 'teacher' and m.status = 'active'),
        'guardians', (select count(*) from public.organization_members m where m.organization_id = o.id and m.role = 'guardian' and m.status = 'active'),
        'recitations_7d', (select count(*) from public.daily_achievements d where d.organization_id = o.id and d.created_at > now() - interval '7 days'),
        'last_activity', (select max(d.created_at) from public.daily_achievements d where d.organization_id = o.id)
      ) order by o.created_at desc)
      from public.organizations o left join public.plans p on p.id = o.plan_id), '[]'::jsonb),
    'plans', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'name', name) order by created_at) from public.plans where is_active), '[]'::jsonb),
    'jobs', coalesce((
      select jsonb_agg(jsonb_build_object('name', j.jobname, 'schedule', j.schedule, 'active', j.active,
             'last_status', r.status, 'last_run', r.start_time, 'last_message', left(r.return_message, 200)) order by j.jobname)
      from cron.job j
      left join lateral (select status, start_time, return_message from cron.job_run_details d where d.jobid = j.jobid order by start_time desc limit 1) r on true), '[]'::jsonb));
end;
$$;

create or replace function public.platform_set_org(p_org uuid, p_status text, p_plan uuid default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_platform_owner() then raise exception 'غير مصرّح'; end if;
  if p_status not in ('trial', 'active', 'suspended', 'cancelled') then raise exception 'حالة غير صحيحة'; end if;
  if p_plan is not null and not exists (select 1 from public.plans where id = p_plan) then raise exception 'الخطة غير موجودة'; end if;
  update public.organizations set status = p_status, plan_id = coalesce(p_plan, plan_id), updated_at = now() where id = p_org;
  if not found then raise exception 'المركز غير موجود'; end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'organizations', p_org, jsonb_build_object('status', p_status, 'plan_id', p_plan));
end;
$$;

-- ---------------------------------------------------------------------
-- privileges
-- ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['get_digest_settings(uuid)', 'set_digest_settings(uuid, boolean, integer, integer)', 'platform_overview()', 'platform_set_org(uuid, text, uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  revoke all on function public.send_weekly_digests(uuid) from public, anon, authenticated;
  revoke all on function public._digest_setting(uuid, text, integer) from public, anon, authenticated;
end $$;
grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
