-- =========================================================================
-- 0044_parity_round2.sql
-- Ported from eqraa, per center:
--   * spaced review (SM-2 style): what each student should review today
--   * teachers' own attendance (self check-in + admin correction)
--   * dropout-risk tags for the admin dashboard
--   * append-only teacher notes on a student (list / add)
--   * global search (students / teachers / circles)
--   * teacher performance + daily trend for the admin dashboard
--   * full data export (JSON) for the admin
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. spaced review
-- ---------------------------------------------------------------------
create table if not exists public.memorization_review_state (
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  student_id       uuid not null references public.students_profile (id) on delete cascade,
  surah_number     integer not null check (surah_number between 1 and 114),
  ease_factor      numeric not null default 2.5,
  interval_days    integer not null default 1,
  last_reviewed_at date,
  next_due_at      date,
  last_grade       text,
  updated_at       timestamptz not null default now(),
  primary key (student_id, surah_number)
);
create index if not exists memorization_review_due_idx on public.memorization_review_state (organization_id, next_due_at);
alter table public.memorization_review_state enable row level security;
revoke all on public.memorization_review_state from anon, authenticated;

drop trigger if exists a_deny_readonly_write on public.memorization_review_state;
create trigger a_deny_readonly_write before insert or update or delete on public.memorization_review_state
  for each row execute function public._deny_readonly_write();

-- grade quality 2..5 from the grade's points relative to the center's best grade
create or replace function public._grade_quality(p_org uuid, p_grade text)
returns numeric language sql stable security definer set search_path = public as $$
  select case
    when p_grade is null then 3
    else coalesce((
      select case when mx.m = 0 then 3
                  when g.points::numeric / mx.m >= 0.95 then 5
                  when g.points::numeric / mx.m >= 0.75 then 4
                  when g.points::numeric / mx.m >= 0.5 then 3 else 2 end
      from public.recitation_grades g
      cross join lateral (select max(points) as m from public.recitation_grades where organization_id = p_org and is_active) mx
      where g.organization_id = p_org and g.key = p_grade), 3) end;
$$;

create or replace function public._srs_apply(p_org uuid, p_student uuid, p_surah integer, p_type text, p_grade text, p_date date)
returns void language plpgsql security definer set search_path = public as $$
declare v_q numeric; v_ease numeric; v_int integer;
begin
  if p_surah is null or p_surah < 1 or p_surah > 114 then return; end if;
  if p_type = 'new_memorization' then
    insert into public.memorization_review_state (organization_id, student_id, surah_number, ease_factor, interval_days, last_reviewed_at, next_due_at, last_grade, updated_at)
    values (p_org, p_student, p_surah, 2.5, 1, p_date, p_date + 1, p_grade, now())
    on conflict (student_id, surah_number) do update set ease_factor = 2.5, interval_days = 1, last_reviewed_at = p_date, next_due_at = p_date + 1,
      last_grade = p_grade, updated_at = now();
  else
    v_q := public._grade_quality(p_org, p_grade);
    select ease_factor, interval_days into v_ease, v_int from public.memorization_review_state where student_id = p_student and surah_number = p_surah;
    v_ease := greatest(1.3, coalesce(v_ease, 2.5) + (0.1 - (5 - v_q) * (0.08 + (5 - v_q) * 0.02)));
    v_int := case when v_q < 3 then 1 else greatest(1, round(coalesce(v_int, 1) * v_ease)::integer) end;
    insert into public.memorization_review_state (organization_id, student_id, surah_number, ease_factor, interval_days, last_reviewed_at, next_due_at, last_grade, updated_at)
    values (p_org, p_student, p_surah, v_ease, v_int, p_date, p_date + v_int, p_grade, now())
    on conflict (student_id, surah_number) do update set ease_factor = v_ease, interval_days = v_int, last_reviewed_at = p_date,
      next_due_at = p_date + v_int, last_grade = p_grade, updated_at = now();
  end if;
end;
$$;

create or replace function public.trg_srs_achievement()
returns trigger language plpgsql security definer set search_path = public as $$
declare s integer; v_date date;
begin
  if new.surah_from is null then return new; end if;
  v_date := (new.created_at at time zone coalesce((select timezone from public.organizations where id = new.organization_id), 'UTC'))::date;
  for s in select generate_series(new.surah_from::integer, greatest(new.surah_from, coalesce(new.surah_to, new.surah_from))::integer) loop
    perform public._srs_apply(new.organization_id, new.student_id, s, new.achievement_type::text, new.grade, v_date);
  end loop;
  return new;
end;
$$;
drop trigger if exists z_srs_achievement on public.daily_achievements;
create trigger z_srs_achievement after insert on public.daily_achievements for each row execute function public.trg_srs_achievement();

-- history replay so the schedule is useful from day one
do $$
declare r record; s integer;
begin
  for r in select * from public.daily_achievements where surah_from is not null order by created_at loop
    for s in select generate_series(r.surah_from::integer, greatest(r.surah_from, coalesce(r.surah_to, r.surah_from))::integer) loop
      perform public._srs_apply(r.organization_id, r.student_id, s, r.achievement_type::text, r.grade,
        (r.created_at at time zone coalesce((select timezone from public.organizations where id = r.organization_id), 'UTC'))::date);
    end loop;
  end loop;
end $$;

-- what is due today: the admin sees every circle, a teacher only their own
create or replace function public.due_reviews(p_org uuid, p_circle uuid default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_today date; v_admin boolean := public.is_org_admin(p_org);
begin
  if not (v_admin or public.is_org_staff(p_org)) then raise exception 'غير مصرّح'; end if;
  v_today := (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
  return coalesce((
    select jsonb_agg(jsonb_build_object('student_id', x.student_id, 'student_name', x.full_name, 'circle_id', x.circle_id, 'circle_name', x.circle_name,
             'surah', x.surah_number, 'due', x.next_due_at, 'days_overdue', v_today - x.next_due_at, 'last_grade', x.last_grade) order by x.next_due_at, x.full_name)
    from (
      select m.student_id, sp.full_name, sp.circle_id, c.name as circle_name, m.surah_number, m.next_due_at, m.last_grade
      from public.memorization_review_state m
      join public.students_profile sp on sp.id = m.student_id and sp.status = 'active'
      left join public.circles c on c.id = sp.circle_id
      where m.organization_id = p_org and m.next_due_at <= v_today
        and (p_circle is null or sp.circle_id = p_circle)
        and (v_admin or c.teacher_id = auth.uid())
      order by m.next_due_at, sp.full_name limit 300) x), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- 2. teachers' own attendance
-- ---------------------------------------------------------------------
create table if not exists public.teacher_attendance (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  teacher_id       uuid not null references auth.users (id) on delete cascade,
  circle_id        uuid not null references public.circles (id) on delete cascade,
  status           public.attendance_status not null default 'present',
  date             date not null,
  checked_in_at    timestamptz,
  note             text,
  set_by_admin     boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (teacher_id, circle_id, date)
);
create index if not exists teacher_attendance_org_date on public.teacher_attendance (organization_id, date desc);
alter table public.teacher_attendance enable row level security;
revoke all on public.teacher_attendance from anon, authenticated;
drop trigger if exists a_deny_readonly_write on public.teacher_attendance;
create trigger a_deny_readonly_write before insert or update or delete on public.teacher_attendance
  for each row execute function public._deny_readonly_write();

create or replace function public.teacher_check_in(p_org uuid, p_circle uuid, p_date date default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_today date; v_date date; v_id uuid;
begin
  perform public._assert_can_write(p_org);
  if not exists (select 1 from public.circles where id = p_circle and organization_id = p_org and teacher_id = auth.uid()) then
    raise exception 'هذه الحلقة ليست إحدى حلقاتك';
  end if;
  v_today := (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
  v_date := coalesce(p_date, v_today);
  if v_date > v_today then raise exception 'لا يمكن تسجيل حضور ليوم لم يأتِ بعد'; end if;
  insert into public.teacher_attendance (organization_id, teacher_id, circle_id, status, date, checked_in_at, set_by_admin)
  values (p_org, auth.uid(), p_circle, 'present', v_date, now(), false)
  on conflict (teacher_id, circle_id, date) do update
    set checked_in_at = now(), status = case when public.teacher_attendance.set_by_admin then public.teacher_attendance.status else 'present' end, updated_at = now()
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'date', v_date);
end;
$$;

create or replace function public.teacher_today_attendance(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('circle_id', circle_id, 'checked_in_at', checked_in_at, 'status', status)), '[]'::jsonb)
  from public.teacher_attendance
  where organization_id = p_org and teacher_id = auth.uid()
    and date = (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
$$;

create or replace function public.admin_set_teacher_attendance(p_org uuid, p_teacher uuid, p_circle uuid, p_date date, p_status text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if not exists (select 1 from public.circles where id = p_circle and organization_id = p_org and teacher_id = p_teacher) then
    raise exception 'هذه الحلقة ليست حلقة هذا المعلم';
  end if;
  insert into public.teacher_attendance (organization_id, teacher_id, circle_id, status, date, note, set_by_admin)
  values (p_org, p_teacher, p_circle, p_status::public.attendance_status, p_date, nullif(btrim(coalesce(p_note, '')), ''), true)
  on conflict (teacher_id, circle_id, date) do update
    set status = excluded.status, note = excluded.note, set_by_admin = true, updated_at = now()
  returning id into v_id;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'teacher_attendance', v_id, jsonb_build_object('teacher_id', p_teacher, 'date', p_date, 'status', p_status));
end;
$$;

-- one teacher's history, or (p_teacher null) everyone for one day
create or replace function public.admin_teacher_attendance(p_org uuid, p_teacher uuid, p_from date, p_to date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', ta.id, 'teacher_id', ta.teacher_id, 'teacher_name', pr.full_name, 'circle_id', ta.circle_id, 'circle_name', c.name,
             'status', ta.status, 'date', ta.date, 'checked_in_at', ta.checked_in_at, 'note', ta.note, 'set_by_admin', ta.set_by_admin) order by ta.date desc, pr.full_name)
    from public.teacher_attendance ta
    join public.circles c on c.id = ta.circle_id
    left join public.profiles pr on pr.id = ta.teacher_id
    where ta.organization_id = p_org and (p_teacher is null or ta.teacher_id = p_teacher) and ta.date between p_from and p_to), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- 3. dropout-risk tags + teacher performance + daily trend
-- ---------------------------------------------------------------------
create or replace function public.admin_dropout_risk(p_org uuid, p_limit integer default 25)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_limit integer := greatest(1, least(coalesce(p_limit, 25), 100)); v_today date;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  v_today := (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', t.id, 'name', t.full_name, 'circle', t.circle_name, 'last_at', t.last_recitation, 'idle_days', t.idle_days, 'tag', t.risk_tag)
                     order by t.last_recitation nulls first)
    from (
      select b.*, public.center_working_days(p_org, coalesce(b.last_recitation::date, b.enrolled_at::date), v_today, b.circle_id) as idle_days,
        case
          when b.att_total >= 3 and b.att_present::numeric / b.att_total >= 0.5 and b.recent_count = 0 then 'attendance_gap'
          when b.last_recitation is null then 'never'
          when b.prior_count > 0 and b.recent_count = 0 then 'regressed'
          when b.prior_count > 0 and b.recent_count > 0 and b.recent_count < b.prior_count * 0.5 then 'slowing'
        end as risk_tag
      from (
        select sp.id, sp.full_name, sp.circle_id, coalesce(c.name, 'بدون حلقة') as circle_name, sp.created_at as enrolled_at,
          (select max(a.created_at) from public.daily_achievements a where a.student_id = sp.id) as last_recitation,
          (select count(*) from public.daily_achievements a where a.student_id = sp.id and a.created_at >= now() - interval '30 days') as recent_count,
          (select count(*) from public.daily_achievements a where a.student_id = sp.id and a.created_at >= now() - interval '60 days' and a.created_at < now() - interval '30 days') as prior_count,
          (select count(*) from public.attendance t where t.student_id = sp.id and t.session_date >= v_today - 30) as att_total,
          (select count(*) filter (where t.status::text in ('present', 'late')) from public.attendance t where t.student_id = sp.id and t.session_date >= v_today - 30) as att_present
        from public.students_profile sp left join public.circles c on c.id = sp.circle_id
        where sp.organization_id = p_org and sp.status = 'active' and sp.created_at < now() - interval '7 days') b) t
    where t.risk_tag is not null and t.idle_days >= 5
    limit v_limit), '[]'::jsonb);
end;
$$;

create or replace function public.admin_teacher_performance(p_org uuid, p_days integer default 7)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_days integer := least(greatest(coalesce(p_days, 7), 1), 90); v_from timestamptz := now() - make_interval(days => least(greatest(coalesce(p_days, 7), 1), 90));
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('teacher_id', m.user_id, 'name', pr.full_name,
        'circles', (select count(*) from public.circles c where c.organization_id = p_org and c.teacher_id = m.user_id and c.status = 'active'),
        'students', (select count(*) from public.students_profile s join public.circles c on c.id = s.circle_id where c.teacher_id = m.user_id and s.organization_id = p_org and s.status = 'active'),
        'recitations', (select count(*) from public.daily_achievements a where a.organization_id = p_org and a.recorded_by = m.user_id and a.created_at >= v_from),
        'reciting_students', (select count(distinct a.student_id) from public.daily_achievements a where a.organization_id = p_org and a.recorded_by = m.user_id and a.created_at >= v_from),
        'check_ins', (select count(*) from public.teacher_attendance t where t.organization_id = p_org and t.teacher_id = m.user_id and t.date >= current_date - v_days and t.status::text in ('present', 'late')),
        'last_active', (select max(a.created_at) from public.daily_achievements a where a.organization_id = p_org and a.recorded_by = m.user_id))
      order by (select count(*) from public.daily_achievements a where a.organization_id = p_org and a.recorded_by = m.user_id and a.created_at >= v_from) desc)
    from public.organization_members m join public.profiles pr on pr.id = m.user_id
    where m.organization_id = p_org and m.role::text = 'teacher' and m.status = 'active'), '[]'::jsonb);
end;
$$;

create or replace function public.admin_daily_trend(p_org uuid, p_days integer default 14)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_days integer := least(greatest(coalesce(p_days, 14), 3), 60); v_tz text; v_today date;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  v_tz := coalesce((select timezone from public.organizations where id = p_org), 'UTC');
  v_today := (now() at time zone v_tz)::date;
  return coalesce((
    select jsonb_agg(jsonb_build_object('date', d::date,
      'recitations', (select count(*) from public.daily_achievements a where a.organization_id = p_org and (a.created_at at time zone v_tz)::date = d::date),
      'attendance', (select count(*) from public.attendance t where t.organization_id = p_org and t.session_date = d::date and t.status::text in ('present', 'late'))) order by d)
    from generate_series(v_today - (v_days - 1), v_today, interval '1 day') d), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- 4. teacher notes on a student (append-only, never shown to the student)
-- ---------------------------------------------------------------------
create or replace function public.list_student_notes(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not (public.is_org_admin(p_org) or (public.is_org_staff(p_org) and public._teaches_student(p_student))) then raise exception 'غير مصرّح'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', n.id, 'body', n.body, 'visibility', n.visibility, 'created_at', n.created_at, 'author', pr.full_name,
             'mine', n.author_id = auth.uid()) order by n.created_at desc)
    from public.student_notes n left join public.profiles pr on pr.id = n.author_id
    where n.organization_id = p_org and n.student_id = p_student), '[]'::jsonb);
end;
$$;

create or replace function public.add_student_note(p_org uuid, p_student uuid, p_body text, p_visibility text default 'staff_only')
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_body text := nullif(btrim(coalesce(p_body, '')), '');
begin
  perform public._assert_can_write(p_org);
  if not (public.is_org_admin(p_org) or (public.is_org_staff(p_org) and public._teaches_student(p_student))) then raise exception 'غير مصرّح'; end if;
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then raise exception 'الطالب غير موجود'; end if;
  if v_body is null then raise exception 'اكتب الملاحظة'; end if;
  if length(v_body) > 1000 then raise exception 'الملاحظة حتى 1000 حرف'; end if;
  if p_visibility not in ('staff_only', 'guardian_visible') then raise exception 'ظهور غير معروف'; end if;
  insert into public.student_notes (organization_id, student_id, author_id, body, visibility) values (p_org, p_student, auth.uid(), v_body, p_visibility)
  returning id into v_id;
  return v_id;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. global search
-- ---------------------------------------------------------------------
create or replace function public.search_global(p_org uuid, p_q text, p_limit integer default 8)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_q text := btrim(coalesce(p_q, '')); v_lim integer := least(greatest(coalesce(p_limit, 8), 1), 25); v_admin boolean := public.is_org_admin(p_org); v_like text;
begin
  if not (v_admin or public.is_org_staff(p_org)) then raise exception 'غير مصرّح'; end if;
  if length(v_q) < 2 then return jsonb_build_object('students', '[]'::jsonb, 'teachers', '[]'::jsonb, 'circles', '[]'::jsonb); end if;
  v_like := '%' || replace(replace(replace(v_q, '\', '\\'), '%', '\%'), '_', '\_') || '%';
  return jsonb_build_object(
    'students', coalesce((
      select jsonb_agg(jsonb_build_object('id', s.id, 'name', s.full_name, 'code', s.student_code, 'circle', c.name, 'status', s.status) order by s.full_name)
      from (select * from public.students_profile where organization_id = p_org and (full_name ilike v_like or student_code ilike v_like) order by full_name limit v_lim) s
      left join public.circles c on c.id = s.circle_id
      where v_admin or c.teacher_id = auth.uid()), '[]'::jsonb),
    'teachers', case when v_admin then coalesce((
      select jsonb_agg(jsonb_build_object('id', m.id, 'user_id', m.user_id, 'name', pr.full_name, 'role', m.role) order by pr.full_name)
      from (select * from public.organization_members where organization_id = p_org and role::text in ('teacher', 'admin') and status = 'active') m
      join public.profiles pr on pr.id = m.user_id where pr.full_name ilike v_like), '[]'::jsonb) else '[]'::jsonb end,
    'circles', coalesce((
      select jsonb_agg(jsonb_build_object('id', c.id, 'name', c.name) order by c.name)
      from (select * from public.circles where organization_id = p_org and name ilike v_like and (v_admin or teacher_id = auth.uid()) order by name limit v_lim) c), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------
-- 6. full data export (one JSON, no logins/passwords)
-- ---------------------------------------------------------------------
create or replace function public.admin_export_data(p_org uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v jsonb;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  select jsonb_build_object(
    'exported_at', now(),
    'organization', (select to_jsonb(o) - 'plan_id' from public.organizations o where o.id = p_org),
    'stages', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.stages t where t.organization_id = p_org),
    'circles', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.circles t where t.organization_id = p_org),
    'students', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.students_profile t where t.organization_id = p_org),
    'members', (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'user_id', m.user_id, 'role', m.role, 'status', m.status, 'full_name', pr.full_name)), '[]')
                from public.organization_members m left join public.profiles pr on pr.id = m.user_id where m.organization_id = p_org),
    'recitation_grades', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.recitation_grades t where t.organization_id = p_org),
    'daily_achievements', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.daily_achievements t where t.organization_id = p_org),
    'attendance', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.attendance t where t.organization_id = p_org),
    'teacher_attendance', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.teacher_attendance t where t.organization_id = p_org),
    'student_notes', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.student_notes t where t.organization_id = p_org),
    'serd_sessions', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.serd_sessions t where t.organization_id = p_org),
    'calendar', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.center_calendar t where t.organization_id = p_org),
    'calendar_registrations', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.calendar_registrations t where t.entry_id in (select id from public.center_calendar where organization_id = p_org)),
    'announcements', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.announcements t where t.organization_id = p_org),
    'badges', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.badges t where t.organization_id = p_org),
    'student_badges', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.student_badges t where t.badge_id in (select id from public.badges where organization_id = p_org)),
    'market_items', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.market_items t where t.organization_id = p_org),
    'market_purchases', (select coalesce(jsonb_agg(to_jsonb(t)), '[]') from public.market_purchases t where t.organization_id = p_org),
    'settings', (select coalesce(jsonb_object_agg(key, value), '{}') from public.organization_settings where organization_id = p_org))
  into v;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, diff) values (p_org, auth.uid(), 'update', 'export', jsonb_build_object('export', true));
  return v;
end;
$$;

-- ---------------------------------------------------------------------
-- privileges
-- ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['_grade_quality(uuid, text)', '_srs_apply(uuid, uuid, integer, text, text, date)', 'trg_srs_achievement()'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
  foreach f in array array[
    'due_reviews(uuid, uuid)', 'teacher_check_in(uuid, uuid, date)', 'teacher_today_attendance(uuid)',
    'admin_set_teacher_attendance(uuid, uuid, uuid, date, text, text)', 'admin_teacher_attendance(uuid, uuid, date, date)',
    'admin_dropout_risk(uuid, integer)', 'admin_teacher_performance(uuid, integer)', 'admin_daily_trend(uuid, integer)',
    'list_student_notes(uuid, uuid)', 'add_student_note(uuid, uuid, text, text)', 'search_global(uuid, text, integer)', 'admin_export_data(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
