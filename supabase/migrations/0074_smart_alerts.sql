-- =====================================================================
-- 0074: smart alerts
-- ---------------------------------------------------------------------
-- Three automatic alerts on top of the notification center (0043), so each
-- one has an editable template, an audience, an on/off switch and a personal
-- mute, and goes out as an instant push like every other notification:
--
--   student_idle_teacher      a student has not recited for N working days
--                             -> the circle's teachers (before the family:
--                                the existing student_idle waits idle_days)
--   student_absences          absent N times within the last W days
--                             -> the admins (at most once a week per student)
--   teacher_checkin_reminder  a teacher has not checked in to a circle by the
--                             set time on a working day -> that teacher
--
-- The thresholds live in notification_settings next to idle_days.
-- =====================================================================

alter table public.notification_settings
  add column if not exists idle_teacher_days      integer not null default 2  check (idle_teacher_days between 1 and 30),
  add column if not exists absence_alert_count    integer not null default 3  check (absence_alert_count between 2 and 30),
  add column if not exists absence_alert_window   integer not null default 14 check (absence_alert_window between 7 and 90),
  add column if not exists checkin_reminder_time  time    not null default '10:00';

insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, lead_hours, roles, sort) values
  ('teacher_checkin_reminder', 'تذكير المعلم بتسجيل حضوره', 'لم تسجّل حضورك اليوم', 'حلقة {الحلقة} — سجّل حضورك من التطبيق',
     array['الحلقة'], null, array['teacher'], 131),
  ('student_idle_teacher', 'تنبيه المعلم: طالب متأخر عن التسميع', 'لم يسمّع {اسم_الطالب} منذ {الأيام} أيام', '{الحلقة}',
     array['اسم_الطالب','الأيام','الحلقة'], null, array['admin','teacher'], 139),
  ('student_absences', 'تنبيه المشرف: غياب متكرر', 'غياب متكرر: {اسم_الطالب}', 'غاب {العدد} مرات في آخر {المدة} يومًا · {الحلقة}',
     array['اسم_الطالب','العدد','المدة','الحلقة'], null, array['admin'], 145)
on conflict (event_key) do update set name = excluded.name, available_vars = excluded.available_vars, roles = excluded.roles, sort = excluded.sort;

create or replace function public._notif_settings(p_org uuid)
returns public.notification_settings language plpgsql stable security definer set search_path = public as $$
declare r public.notification_settings;
begin
  select * into r from public.notification_settings where organization_id = p_org;
  if not found then
    r.organization_id := p_org; r.quiet_from := '21:00'; r.quiet_to := '07:00'; r.day_start_time := '07:00';
    r.late_grace_hours := 12; r.idle_days := 3; r.is_paused := false; r.updated_at := now();
    r.idle_teacher_days := 2; r.absence_alert_count := 3; r.absence_alert_window := 14; r.checkin_reminder_time := '10:00';
  end if;
  return r;
end;
$$;

-- is this event switched on for the center (default exists, template not disabled)?
create or replace function public._notif_event_on(p_org uuid, p_event text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.notification_defaults d where d.event_key = p_event)
     and not exists (select 1 from public.notification_templates t where t.organization_id = p_org and t.event_key = p_event and not t.is_enabled);
$$;

-- ---------------------------------------------------------------------
-- idle students: the teachers first (idle_teacher_days), then the family (idle_days)
-- ---------------------------------------------------------------------
create or replace function public.send_idle_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; st public.notification_settings; v_local timestamp; v_today date; v_since date; v_idle integer; v_n integer := 0;
        v_family boolean; v_teacher boolean; v_teachers uuid[];
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    st := public._notif_settings(e.id);
    continue when st.is_paused;
    v_family := public._notif_event_on(e.id, 'student_idle');
    v_teacher := public._notif_event_on(e.id, 'student_idle_teacher');
    continue when not v_family and not v_teacher;
    v_local := now() at time zone e.tz;
    v_today := v_local::date;
    -- only in the morning window: from the day start until the late-grace limit
    continue when v_local::time < st.day_start_time or v_local >= (v_today + st.day_start_time) + make_interval(hours => st.late_grace_hours);
    continue when public.center_working_days(e.id, v_today, v_today, null) = 0;

    for s in
      select sp.id, sp.full_name, sp.circle_id, ci.name as circle_name, ci.teacher_id, la.last_day, sp.created_at
      from public.students_profile sp
      left join public.circles ci on ci.id = sp.circle_id
      cross join lateral (select max((da.created_at at time zone e.tz)::date) as last_day from public.daily_achievements da where da.student_id = sp.id) la
      where sp.organization_id = e.id and sp.status = 'active' and sp.circle_id is not null
    loop
      v_since := greatest(coalesce(s.last_day, (s.created_at at time zone e.tz)::date), v_today - 60);
      v_idle := public.center_working_days(e.id, v_since + 1, v_today, s.circle_id);

      if v_teacher and v_idle >= st.idle_teacher_days then
        select array_agg(distinct u) into v_teachers from (
          select s.teacher_id as u where s.teacher_id is not null
          union select a.user_id from public.circle_assistants a where a.circle_id = s.circle_id) x;
        if v_teachers is not null then
          perform public._notify(e.id, v_teachers, 'student_idle_teacher', 'لم يسمّع ' || s.full_name || ' منذ ' || v_idle || ' أيام',
            coalesce(s.circle_name, ''), s.id,
            jsonb_build_object('اسم_الطالب', s.full_name, 'الأيام', v_idle::text, 'الحلقة', coalesce(s.circle_name, '')), true,
            'student_idle_teacher|' || s.id::text || '|' || coalesce(s.last_day::text, 'never'));
          v_n := v_n + 1;
        end if;
      end if;

      if v_family and v_idle >= st.idle_days then
        perform public._notify(e.id, public._student_family_users(s.id), 'student_idle', 'اشتقنا لسماعك',
          'لم تسمّع منذ ' || v_idle || ' أيام', s.id,
          jsonb_build_object('اسم_الطالب', s.full_name, 'الأيام', v_idle::text, 'الحلقة', coalesce(s.circle_name, '')), true,
          'student_idle|' || s.id::text || '|' || coalesce(s.last_day::text, 'never'));
        v_n := v_n + 1;
      end if;
    end loop;
  end loop;
  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
-- repeated absence -> admins, once a week per student while it lasts
-- ---------------------------------------------------------------------
create or replace function public.send_absence_alerts()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; st public.notification_settings; v_local timestamp; v_today date; v_admins uuid[]; v_n integer := 0;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    st := public._notif_settings(e.id);
    continue when st.is_paused or not public._notif_event_on(e.id, 'student_absences');
    v_local := now() at time zone e.tz;
    v_today := v_local::date;
    continue when v_local::time < st.day_start_time or v_local >= (v_today + st.day_start_time) + make_interval(hours => st.late_grace_hours);
    select array_agg(m.user_id) into v_admins from public.organization_members m
     where m.organization_id = e.id and m.role::text = 'admin' and m.status = 'active';
    continue when v_admins is null;

    for s in
      select sp.id, sp.full_name, ci.name as circle_name, count(*) as n
      from public.attendance a
      join public.students_profile sp on sp.id = a.student_id
      left join public.circles ci on ci.id = sp.circle_id
      where a.organization_id = e.id and a.status::text = 'absent' and sp.status = 'active'
        and a.session_date > v_today - st.absence_alert_window and a.session_date <= v_today
      group by sp.id, sp.full_name, ci.name
      having count(*) >= st.absence_alert_count
    loop
      perform public._notify(e.id, v_admins, 'student_absences', 'غياب متكرر: ' || s.full_name,
        'غاب ' || s.n || ' مرات في آخر ' || st.absence_alert_window || ' يومًا', s.id,
        jsonb_build_object('اسم_الطالب', s.full_name, 'العدد', s.n::text, 'المدة', st.absence_alert_window::text, 'الحلقة', coalesce(s.circle_name, '')), true,
        'student_absences|' || s.id::text || '|' || to_char(v_today, 'IYYY-IW'));
      v_n := v_n + 1;
    end loop;
  end loop;
  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
-- teacher forgot to check in -> that teacher, once per circle per day
-- ---------------------------------------------------------------------
create or replace function public.send_checkin_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; c record; st public.notification_settings; v_local timestamp; v_today date; v_n integer := 0;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    st := public._notif_settings(e.id);
    continue when st.is_paused or not public._notif_event_on(e.id, 'teacher_checkin_reminder');
    v_local := now() at time zone e.tz;
    v_today := v_local::date;
    continue when v_local::time < st.checkin_reminder_time or extract(hour from v_local)::integer >= 21;

    for c in
      select ci.id, ci.name, ci.teacher_id from public.circles ci
      where ci.organization_id = e.id and ci.status = 'active' and ci.teacher_id is not null
        and exists (select 1 from public.organization_members m where m.organization_id = e.id and m.user_id = ci.teacher_id and m.status = 'active')
        and exists (select 1 from public.students_profile s where s.circle_id = ci.id and s.status = 'active')
        and public.center_working_days(e.id, v_today, v_today, ci.id) > 0
        and not exists (select 1 from public.teacher_attendance t where t.teacher_id = ci.teacher_id and t.circle_id = ci.id and t.date = v_today)
    loop
      perform public._notify(e.id, array[c.teacher_id], 'teacher_checkin_reminder', 'لم تسجّل حضورك اليوم', c.name, c.id,
        jsonb_build_object('الحلقة', c.name), true,
        'teacher_checkin_reminder|' || c.id::text || '|' || v_today::text);
      v_n := v_n + 1;
    end loop;
  end loop;
  return v_n;
end;
$$;

revoke all on function public.send_idle_reminders() from public, anon, authenticated;
revoke all on function public.send_absence_alerts() from public, anon, authenticated;
revoke all on function public.send_checkin_reminders() from public, anon, authenticated;
revoke all on function public._notif_event_on(uuid, text) from public, anon, authenticated;

select cron.schedule('absence-alerts', '45 * * * *', 'select public.send_absence_alerts()');
select cron.schedule('checkin-reminders', '*/15 * * * *', 'select public.send_checkin_reminders()');

-- ---------------------------------------------------------------------
-- admin settings: the new thresholds
-- ---------------------------------------------------------------------
create or replace function public.admin_notification_config(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare st public.notification_settings;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة للمشرف فقط'; end if;
  st := public._notif_settings(p_org);
  return jsonb_build_object(
    'settings', jsonb_build_object('timezone', coalesce((select timezone from public.organizations where id = p_org), 'UTC'),
      'quiet_from', to_char(st.quiet_from, 'HH24:MI'), 'quiet_to', to_char(st.quiet_to, 'HH24:MI'),
      'day_start_time', to_char(st.day_start_time, 'HH24:MI'), 'late_grace_hours', st.late_grace_hours,
      'idle_days', st.idle_days, 'is_paused', st.is_paused,
      'idle_teacher_days', st.idle_teacher_days, 'absence_alert_count', st.absence_alert_count,
      'absence_alert_window', st.absence_alert_window, 'checkin_reminder_time', to_char(st.checkin_reminder_time, 'HH24:MI')),
    'templates', coalesce((
      select jsonb_agg(jsonb_build_object(
        'event_key', d.event_key, 'name', d.name, 'roles', to_jsonb(d.roles), 'available_vars', to_jsonb(d.available_vars),
        'title_template', coalesce(t.title_template, d.title_template), 'body_template', coalesce(t.body_template, d.body_template),
        'default_title', d.title_template, 'default_body', d.body_template,
        'has_lead', d.lead_hours is not null,
        'lead_hours', case when d.event_key = 'event_reminder' then public._event_lead_hours(p_org) else coalesce(t.lead_hours, d.lead_hours) end,
        'audience', coalesce(t.audience, d.default_audience), 'is_enabled', coalesce(t.is_enabled, true),
        'customized', t.event_key is not null, 'updated_at', t.updated_at,
        'updated_by_name', (select full_name from public.profiles where id = t.updated_by),
        'sent_count', (select count(*) from public.notifications n where n.organization_id = p_org and n.event_key = d.event_key))
        order by d.sort)
      from public.notification_defaults d
      left join public.notification_templates t on t.organization_id = p_org and t.event_key = d.event_key), '[]'::jsonb));
end;
$$;

drop function if exists public.admin_save_notification_settings(uuid, time, time, time, integer, integer, boolean);
create or replace function public.admin_save_notification_settings(
  p_org uuid, p_quiet_from time, p_quiet_to time, p_day_start time, p_grace integer, p_idle integer, p_paused boolean,
  p_idle_teacher integer default null, p_absence_count integer default null, p_absence_window integer default null,
  p_checkin_time time default null)
returns void language plpgsql security definer set search_path = public as $$
declare cur public.notification_settings;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  cur := public._notif_settings(p_org);
  if p_quiet_from is null or p_quiet_to is null or p_day_start is null then raise exception 'أكمل الأوقات'; end if;
  if p_grace is null or p_grace < 0 or p_grace > 72 then raise exception 'مهلة التأخير بين 0 و72 ساعة'; end if;
  if p_idle is null or p_idle < 1 or p_idle > 30 then raise exception 'أيام التأخر عن التسميع بين 1 و30'; end if;
  if p_idle_teacher is not null and (p_idle_teacher < 1 or p_idle_teacher > 30) then raise exception 'أيام تنبيه المعلم بين 1 و30'; end if;
  if p_absence_count is not null and (p_absence_count < 2 or p_absence_count > 30) then raise exception 'عدد مرات الغياب بين 2 و30'; end if;
  if p_absence_window is not null and (p_absence_window < 7 or p_absence_window > 90) then raise exception 'مدة حساب الغياب بين 7 و90 يومًا'; end if;
  insert into public.notification_settings (organization_id, quiet_from, quiet_to, day_start_time, late_grace_hours, idle_days, is_paused,
                                            idle_teacher_days, absence_alert_count, absence_alert_window, checkin_reminder_time, updated_at)
  values (p_org, p_quiet_from, p_quiet_to, p_day_start, p_grace, p_idle, coalesce(p_paused, false),
          coalesce(p_idle_teacher, cur.idle_teacher_days), coalesce(p_absence_count, cur.absence_alert_count),
          coalesce(p_absence_window, cur.absence_alert_window), coalesce(p_checkin_time, cur.checkin_reminder_time), now())
  on conflict (organization_id) do update set quiet_from = excluded.quiet_from, quiet_to = excluded.quiet_to, day_start_time = excluded.day_start_time,
    late_grace_hours = excluded.late_grace_hours, idle_days = excluded.idle_days, is_paused = excluded.is_paused,
    idle_teacher_days = excluded.idle_teacher_days, absence_alert_count = excluded.absence_alert_count,
    absence_alert_window = excluded.absence_alert_window, checkin_reminder_time = excluded.checkin_reminder_time, updated_at = now();
  insert into public.audit_log (organization_id, actor_id, action, entity_table, diff)
  values (p_org, auth.uid(), 'update', 'notification_settings', jsonb_build_object('quiet_from', p_quiet_from, 'quiet_to', p_quiet_to, 'idle_days', p_idle,
    'idle_teacher_days', p_idle_teacher, 'absence_alert_count', p_absence_count, 'absence_alert_window', p_absence_window,
    'checkin_reminder_time', p_checkin_time, 'paused', coalesce(p_paused, false)));
end;
$$;
revoke all on function public.admin_save_notification_settings(uuid, time, time, time, integer, integer, boolean, integer, integer, integer, time) from public, anon;
grant execute on function public.admin_save_notification_settings(uuid, time, time, time, integer, integer, boolean, integer, integer, integer, time) to authenticated;

notify pgrst, 'reload schema';
