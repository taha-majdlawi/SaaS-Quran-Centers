-- =========================================================================
-- 0088_center_features.sql
-- The center admin decides which features the center uses.
--
--   available  = what the platform allows the center: the owner's switch for
--                the center, else the platform-wide switch, else the center's
--                plan, else on (unchanged - _feature_available, formerly the
--                body of platform_feature_enabled);
--   on         = available, and not switched off by the center's admin.
-- So by default a center has exactly what its plan / the owner gives it; the
-- admin can switch any of it off (and back on), never on beyond it.
-- platform_feature_enabled now answers "on", so every existing check (menus,
-- member_has_module, chat, market, fees) follows the admin's choice too.
--
-- New features in the catalog: the mushaf, recorded / live recitations, the
-- daily portion, and the growing tree.
-- =========================================================================

create table if not exists public.organization_feature_prefs (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  key             text not null,
  enabled         boolean not null,
  updated_by      uuid references auth.users (id) on delete set null,
  updated_at      timestamptz not null default now(),
  primary key (organization_id, key)
);
alter table public.organization_feature_prefs enable row level security;
revoke all on public.organization_feature_prefs from anon, authenticated;
drop trigger if exists a_deny_readonly_write on public.organization_feature_prefs;
create trigger a_deny_readonly_write before insert or update or delete on public.organization_feature_prefs
  for each row execute function public._deny_readonly_write();

create or replace function public._feature_catalog()
returns text[] language sql immutable as $$
  select array['students', 'circles', 'attendance', 'serd', 'points', 'badges', 'market', 'circle-challenges', 'activities',
               'calendar', 'announcements', 'chat', 'notifications', 'reports', 'certificates', 'fees',
               'quran', 'recitations', 'wird', 'garden_tree'];
$$;

-- what the platform allows the center (the former platform_feature_enabled)
create or replace function public._feature_available(p_org uuid, p_key text)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(
    (select f.enabled from public.feature_flags f where f.key = p_key and f.organization_id = p_org limit 1),
    (select f.enabled from public.feature_flags f where f.key = p_key and f.organization_id is null limit 1),
    (select (p.features ->> p_key)::boolean from public.organizations o join public.plans p on p.id = o.plan_id
      where o.id = p_org and p.features ? p_key limit 1),
    true);
$$;

-- available, and not switched off by the center
create or replace function public.platform_feature_enabled(p_org uuid, p_key text)
returns boolean language sql stable security definer set search_path = public as $$
  select public._feature_available(p_org, p_key)
     and coalesce((select c.enabled from public.organization_feature_prefs c where c.organization_id = p_org and c.key = p_key), true);
$$;

-- the admin's page: every feature, whether the plan allows it and whether the center uses it
create or replace function public.center_features(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة لمدير المركز'; end if;
  return (select jsonb_agg(jsonb_build_object(
            'key', k,
            'available', public._feature_available(p_org, k),
            'enabled', public.platform_feature_enabled(p_org, k)) order by ord)
          from unnest(public._feature_catalog()) with ordinality as x(k, ord));
end;
$$;

-- saves the whole list at once: p_off = the available features the center does not use
create or replace function public.set_center_features(p_org uuid, p_off text[])
returns void language plpgsql security definer set search_path = public as $$
declare k text;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذا الإجراء لمدير المركز'; end if;
  perform public._assert_can_write(p_org);
  foreach k in array public._feature_catalog() loop
    if k = any (coalesce(p_off, '{}')) then
      insert into public.organization_feature_prefs (organization_id, key, enabled, updated_by)
      values (p_org, k, false, auth.uid())
      on conflict (organization_id, key) do update set enabled = false, updated_by = auth.uid(), updated_at = now();
    else
      -- on = back to "whatever the plan allows" (switching on beyond the plan is not possible)
      delete from public.organization_feature_prefs where organization_id = p_org and key = k;
    end if;
  end loop;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'organization_feature_prefs', p_org, jsonb_build_object('off', coalesce(p_off, '{}')));
end;
$$;

-- a center that switched recitations off takes none (any path)
create or replace function public.trg_recitations_enabled()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not public.platform_feature_enabled(new.organization_id, 'recitations') then
    raise exception 'التسميع المسجّل غير مفعّل في هذا المركز';
  end if;
  return new;
end;
$$;
drop trigger if exists trg_recitations_enabled on public.recitation_submissions;
create trigger trg_recitations_enabled before insert on public.recitation_submissions
  for each row execute function public.trg_recitations_enabled();

-- the daily-portion reminder follows the switch
create or replace function public.send_wird_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; st public.notification_settings; v_local timestamp; v_today date; v_new jsonb; v_label text; v_n integer := 0;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    st := public._notif_settings(e.id);
    continue when st.is_paused or not public._notif_event_on(e.id, 'wird_reminder') or not public.platform_feature_enabled(e.id, 'wird');
    v_local := now() at time zone e.tz;
    v_today := v_local::date;
    -- once, in the afternoon (16:00-16:59 at the center)
    continue when extract(hour from v_local) <> 16;
    for s in
      select sp.id, sp.full_name, sp.circle_id from public.students_profile sp
       where sp.organization_id = e.id and sp.status = 'active' and sp.circle_id is not null
         and public.center_working_days(e.id, v_today, v_today, sp.circle_id) > 0
         and not exists (select 1 from public.daily_achievements d where d.student_id = sp.id and (d.created_at at time zone e.tz)::date = v_today)
         and not exists (select 1 from public.recitation_submissions r where r.student_id = sp.id and r.status <> 'draft' and (r.created_at at time zone e.tz)::date = v_today)
         -- something to recite: a memorization history or today's review portion
         and (exists (select 1 from public.daily_achievements d where d.student_id = sp.id and d.achievement_type::text = 'new_memorization')
              or exists (select 1 from public.student_review_plans p where p.student_id = sp.id and p.plan_date = v_today and p.status = 'approved'))
    loop
      v_new := public._suggest_new(s.id, v_today, e.tz);
      v_label := case when v_new is null then '' else public._surah_range_label((v_new->>'surah')::int, (v_new->>'ayah_from')::int, (v_new->>'ayah_to')::int) end;
      perform public._notify(e.id, public._student_family_users(s.id), 'wird_reminder', 'ورد اليوم بانتظارك', v_label, s.id,
        jsonb_build_object('اسم_الطالب', s.full_name, 'المقطع', v_label), true,
        'wird_reminder|' || s.id::text || '|' || v_today::text);
      v_n := v_n + 1;
    end loop;
  end loop;
  return v_n;
end;
$$;

revoke all on function public._feature_available(uuid, text) from public, anon, authenticated;
revoke all on function public.trg_recitations_enabled() from public, anon, authenticated;
revoke all on function public.send_wird_reminders() from public, anon, authenticated;
revoke all on function public.center_features(uuid) from public, anon;
revoke all on function public.set_center_features(uuid, text[]) from public, anon;
grant execute on function public.center_features(uuid), public.set_center_features(uuid, text[]) to authenticated;

notify pgrst, 'reload schema';
