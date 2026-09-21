-- =========================================================================
-- 0047_round_polish.sql
--   * attendance reminders reach the primary teacher AND the circle's assistants
--   * teacher performance counts the circles/students a teacher assists in
--   * index for the notification centre's per-type counters
-- =========================================================================
create index if not exists notifications_org_event_idx on public.notifications (organization_id, event_key);

-- who is told that a circle has no attendance yet today: primary + assistants
create or replace function public.send_attendance_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; c record; v_local timestamp; v_hour integer; v_n integer := 0; v_users uuid[];
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    continue when public.org_setting(e.id, 'attendance_reminder_enabled', 'true') <> 'true';
    continue when (public._notif_settings(e.id)).is_paused;
    v_local := now() at time zone e.tz;
    v_hour := public._digest_setting(e.id, 'attendance_reminder_hour', 11);
    continue when extract(hour from v_local)::integer < v_hour or extract(hour from v_local)::integer >= 21;

    for c in
      select ci.id, ci.name, ci.teacher_id from public.circles ci
      where ci.organization_id = e.id and ci.status = 'active'
        and (ci.teacher_id is not null or exists (select 1 from public.circle_assistants a where a.circle_id = ci.id))
        and public.center_working_days(e.id, v_local::date, v_local::date, ci.id) > 0
        and exists (select 1 from public.students_profile s where s.circle_id = ci.id and s.status = 'active')
        and not exists (select 1 from public.attendance a where a.circle_id = ci.id and a.session_date = v_local::date)
        and not exists (select 1 from public.attendance_reminders_sent r where r.circle_id = ci.id and r.for_date = v_local::date)
    loop
      insert into public.attendance_reminders_sent (circle_id, for_date) values (c.id, v_local::date) on conflict do nothing;
      select array_agg(distinct u) into v_users from (
        select c.teacher_id as u where c.teacher_id is not null
        union select a.user_id from public.circle_assistants a where a.circle_id = c.id) x;
      perform public._notify(e.id, v_users, 'attendance_reminder', 'لم يُسجَّل حضور حلقتك اليوم', c.name, c.id,
        jsonb_build_object('الحلقة', c.name));
      v_n := v_n + 1;
    end loop;
  end loop;
  return v_n;
end;
$$;

-- teacher performance: circles and students include the ones the teacher assists in
do $$
declare r record; v_def text; v_new text;
begin
  select p.oid into r from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = 'admin_teacher_performance';
  v_def := pg_get_functiondef(r.oid);
  v_new := regexp_replace(v_def, '\mc\.teacher_id\s*=\s*m\.user_id', 'public._is_circle_teacher(c.id, m.user_id)', 'g');
  if v_new = v_def then raise exception 'admin_teacher_performance: nothing to patch'; end if;
  execute v_new;
end $$;

revoke all on function public.send_attendance_reminders() from public, anon, authenticated;
notify pgrst, 'reload schema';
