-- =========================================================================
-- 0037_deletion_requests_attendance_reminders.sql
-- 1. Account / data deletion requests (an app-store requirement): any member
--    can ask from inside the app or the portal; the center admin reviews.
-- 2. Attendance reminder: on a working day, once the center's chosen hour has
--    passed, a teacher whose circle has no attendance recorded yet gets one
--    inbox reminder (per circle per day).
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. deletion requests
-- ---------------------------------------------------------------------
create or replace function public.request_account_deletion(p_org uuid, p_reason text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_role public.user_role; v_id uuid; v_admins uuid[]; v_name text;
begin
  v_role := public._org_role_of(p_org, auth.uid());
  if v_role is null then raise exception 'غير مصرّح'; end if;
  if exists (select 1 from public.deletion_requests where organization_id = p_org and requester_id = auth.uid() and status = 'pending') then
    raise exception 'لديك طلب قيد المراجعة بالفعل';
  end if;
  insert into public.deletion_requests (organization_id, requester_type, requester_id, target_user_id, reason)
  values (p_org, v_role::text::public.deletion_requester_type, auth.uid(), auth.uid(), nullif(left(btrim(coalesce(p_reason, '')), 500), ''))
  returning id into v_id;

  select array_agg(user_id) into v_admins from public.organization_members where organization_id = p_org and role = 'admin' and status = 'active';
  select full_name into v_name from public.profiles where id = auth.uid();
  perform public._notify(p_org, v_admins, 'deletion_request', 'طلب حذف بيانات', coalesce(v_name, 'عضو') || ' يطلب حذف حسابه وبياناته', v_id);
  return v_id;
end;
$$;

create or replace function public.my_deletion_request(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select (select jsonb_build_object('id', id, 'status', status, 'created_at', created_at, 'reviewed_at', reviewed_at)
          from public.deletion_requests where organization_id = p_org and requester_id = auth.uid()
          order by created_at desc limit 1);
$$;

create or replace function public.list_deletion_requests(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', r.id, 'status', r.status, 'role', r.requester_type, 'reason', r.reason,
             'name', p.full_name, 'email', u.email, 'created_at', r.created_at, 'reviewed_at', r.reviewed_at,
             'student', (select string_agg(sp.full_name, '، ') from public.students_profile sp
                         where sp.id = any (public._students_of_user(p_org, r.requester_id)))) order by (r.status = 'pending') desc, r.created_at desc)
    from public.deletion_requests r
    left join public.profiles p on p.id = r.requester_id
    left join auth.users u on u.id = r.requester_id
    where r.organization_id = p_org), '[]'::jsonb);
end;
$$;

create or replace function public.review_deletion_request(p_org uuid, p_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare r public.deletion_requests%rowtype;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if p_status not in ('approved', 'rejected', 'completed') then raise exception 'حالة غير صحيحة'; end if;
  select * into r from public.deletion_requests where id = p_id and organization_id = p_org;
  if not found then raise exception 'الطلب غير موجود'; end if;
  update public.deletion_requests set status = p_status::public.deletion_status, reviewed_by = auth.uid(), reviewed_at = now() where id = p_id;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'deletion_requests', p_id, jsonb_build_object('status', p_status));
  perform public._notify(p_org, array[r.requester_id], 'deletion_reviewed',
    case p_status when 'rejected' then 'رُفض طلب حذف بياناتك' when 'approved' then 'وُوفق على طلب حذف بياناتك' else 'اكتمل حذف بياناتك' end,
    null, p_id);
end;
$$;

-- ---------------------------------------------------------------------
-- 2. attendance reminders
-- ---------------------------------------------------------------------
create table if not exists public.attendance_reminders_sent (
  circle_id  uuid not null references public.circles (id) on delete cascade,
  for_date   date not null,
  sent_at    timestamptz not null default now(),
  primary key (circle_id, for_date)
);
alter table public.attendance_reminders_sent enable row level security;
revoke all on public.attendance_reminders_sent from anon, authenticated;

create or replace function public.send_attendance_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; c record; v_local timestamp; v_hour integer; v_n integer := 0;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    continue when public.org_setting(e.id, 'attendance_reminder_enabled', 'true') <> 'true';
    v_local := now() at time zone e.tz;
    v_hour := public._digest_setting(e.id, 'attendance_reminder_hour', 11);
    continue when extract(hour from v_local)::integer < v_hour or extract(hour from v_local)::integer >= 21;

    for c in
      select ci.id, ci.name, ci.teacher_id from public.circles ci
      where ci.organization_id = e.id and ci.status = 'active' and ci.teacher_id is not null
        and public.center_working_days(e.id, v_local::date, v_local::date, ci.id) > 0
        and exists (select 1 from public.students_profile s where s.circle_id = ci.id and s.status = 'active')
        and not exists (select 1 from public.attendance a where a.circle_id = ci.id and a.session_date = v_local::date)
        and not exists (select 1 from public.attendance_reminders_sent r where r.circle_id = ci.id and r.for_date = v_local::date)
    loop
      insert into public.attendance_reminders_sent (circle_id, for_date) values (c.id, v_local::date) on conflict do nothing;
      perform public._notify(e.id, array[c.teacher_id], 'attendance_reminder', 'لم يُسجَّل حضور حلقتك اليوم', c.name, c.id);
      v_n := v_n + 1;
    end loop;
  end loop;
  return v_n;
end;
$$;

select cron.schedule('attendance-reminders', '20 * * * *', 'select public.send_attendance_reminders()');

-- ---------------------------------------------------------------------
-- privileges
-- ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['request_account_deletion(uuid, text)', 'my_deletion_request(uuid)', 'list_deletion_requests(uuid)', 'review_deletion_request(uuid, uuid, text)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on function public.send_attendance_reminders() from public, anon, authenticated;
grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
