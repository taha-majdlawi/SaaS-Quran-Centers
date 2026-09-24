-- =========================================================================
-- 0060_student_read_rpcs_scoping.sql
-- Security audit fix - 0051's pattern, on the student-portal read RPCs
-- (SECURITY DEFINER, so they bypass the RLS 0051 scoped):
--   * get_student_dashboard (0016), student_record_detail (0056) and
--     attendance_rate (0016/0020) let ANY teacher read ANY student of the
--     center - the dashboard even returns the student's phone, WhatsApp and
--     address, the record returns the full recitation + attendance history.
--   * student_record_detail and attendance_rate also never checked that
--     p_student belongs to p_org, and filter only by student_id: the admin
--     of ANY center (self-serve signup makes that anyone) could read another
--     center's student by passing their own org id + that student's id.
-- One helper now decides "may the caller see this student", with the same
-- rule student_report (0044) already uses: the student must be in p_org, and
-- the caller is its admin, a teacher with the 'reports' module, the
-- student's own circle teacher/assistant, or the student / guardian.
-- Function bodies are otherwise unchanged.
-- =========================================================================

create or replace function public._can_view_student(p_org uuid, p_student uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
     and exists (select 1 from public.students_profile where id = p_student and organization_id = p_org)
     and (public.is_org_admin(p_org)
          or public.member_has_module(p_org, 'reports')
          or public._teaches_student(p_student)
          or p_student = any (public.linked_student_ids(p_org)));
$$;
revoke all on function public._can_view_student(uuid, uuid) from public, anon;
grant execute on function public._can_view_student(uuid, uuid) to authenticated;

create or replace function public.attendance_rate(p_org uuid, p_student uuid, p_from date, p_to date)
returns numeric language plpgsql stable security definer set search_path = public as $$
declare v_working integer; v_present integer; v_circle uuid;
begin
  if not public._can_view_student(p_org, p_student) then
    raise exception 'غير مصرّح';
  end if;
  select circle_id into v_circle from public.students_profile where id = p_student;
  v_working := public.center_working_days(p_org, p_from, p_to, v_circle);
  if v_working = 0 then return null; end if;
  select count(*) into v_present from public.attendance a
   where a.student_id = p_student and a.session_date between p_from and p_to
     and a.status in ('present', 'late');
  return round(least(v_present, v_working)::numeric * 100 / v_working, 1);
end;
$$;

create or replace function public.get_student_dashboard(p_org uuid, p_student_id uuid default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_student   uuid;
  v_sp        record;
  v_circle    record;
  v_teacher   text;
  v_tz        text;
  v_today     date;
  v_week_from date;
  v_stats     jsonb;
  v_recent    jsonb;
  v_streak    integer := 0;
  v_longest   integer := 0;
  v_run       integer := 0;
  v_dates     date[];
  v_n         integer;
  i           integer;
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;

  select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = p_org;
  v_today := (now() at time zone v_tz)::date;
  v_week_from := v_today - 6;

  if p_student_id is not null then
    v_student := p_student_id;
  else
    v_student := (public.linked_student_ids(p_org))[1];
  end if;
  if v_student is null then
    return jsonb_build_object('linked', false);
  end if;
  if not public._can_view_student(p_org, v_student) then
    raise exception 'غير مصرّح';
  end if;

  select * into v_sp from public.students_profile where id = v_student and organization_id = p_org;
  if not found then return jsonb_build_object('linked', false); end if;

  select c.id, c.name, c.teacher_id, s.name as stage_name into v_circle
  from public.circles c left join public.stages s on s.id = c.stage_id where c.id = v_sp.circle_id;
  if v_circle.teacher_id is not null then
    select full_name into v_teacher from public.profiles where id = v_circle.teacher_id;
  end if;

  -- streak = consecutive days (ending today or yesterday) with a recitation
  select array_agg(x.d order by x.d desc) into v_dates from (
    select distinct (created_at at time zone v_tz)::date as d
    from public.daily_achievements where student_id = v_student
  ) x;

  if v_dates is not null then
    v_n := array_length(v_dates, 1);
    if v_dates[1] >= v_today - 1 then
      v_streak := 1;
      for i in 2..v_n loop
        exit when v_dates[i - 1] - v_dates[i] <> 1;
        v_streak := v_streak + 1;
      end loop;
    end if;
    v_run := 1;
    v_longest := 1;
    for i in 2..v_n loop
      if v_dates[i - 1] - v_dates[i] = 1 then v_run := v_run + 1; else v_run := 1; end if;
      v_longest := greatest(v_longest, v_run);
    end loop;
  end if;

  select jsonb_build_object(
    'total_recitations', (select count(*) from public.daily_achievements where student_id = v_student),
    'recitations_this_week', (select count(*) from public.daily_achievements
        where student_id = v_student and (created_at at time zone v_tz)::date >= v_week_from),
    'recitations_last_week', (select count(*) from public.daily_achievements
        where student_id = v_student
          and (created_at at time zone v_tz)::date between v_week_from - 7 and v_week_from - 1),
    'ayahs_this_week', coalesce((select sum(ayah_to - ayah_from + 1) from public.daily_achievements
        where student_id = v_student and achievement_type = 'new_memorization'
          and (created_at at time zone v_tz)::date >= v_week_from), 0),
    'weekly_attendance_rate', public.attendance_rate(p_org, v_student, v_week_from, v_today),
    'monthly_attendance_rate', public.attendance_rate(p_org, v_student, v_today - 29, v_today),
    'current_streak', v_streak,
    'longest_streak', v_longest,
    'last_recitation_at', (select max(created_at) from public.daily_achievements where student_id = v_student)
  ) into v_stats;

  select coalesce(jsonb_agg(r order by r.created_at desc), '[]'::jsonb) into v_recent from (
    select da.id, da.achievement_type as type, da.surah_from as surah, da.ayah_from, da.ayah_to,
           da.grade, coalesce(g.label, da.grade) as grade_label, da.points_awarded, da.notes,
           da.created_at, da.session_group_id
    from public.daily_achievements da
    left join public.recitation_grades g on g.organization_id = da.organization_id and g.key = da.grade
    where da.student_id = v_student
    order by da.created_at desc limit 20
  ) r;

  return jsonb_build_object(
    'linked', true,
    'student', jsonb_build_object(
      'id', v_sp.id, 'full_name', v_sp.full_name, 'student_code', v_sp.student_code,
      'total_points', v_sp.total_points, 'next_plan', v_sp.next_plan,
      'total_progress', v_sp.total_progress, 'total_parts_count', v_sp.total_parts_count,
      'saved_parts_numbers', v_sp.saved_parts_numbers,
      'phone', v_sp.phone, 'whatsapp', v_sp.whatsapp, 'address', v_sp.address,
      'status', v_sp.status
    ),
    'circle', case when v_circle.id is null then null else jsonb_build_object(
      'id', v_circle.id, 'name', v_circle.name, 'stage', v_circle.stage_name, 'teacher', v_teacher) end,
    'stats', v_stats,
    'recent', v_recent
  );
end;
$$;

create or replace function public.student_record_detail(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_monthly_points integer; v_points_breakdown jsonb; v_recitations jsonb; v_attendance jsonb;
begin
  if not public._can_view_student(p_org, p_student) then
    raise exception 'غير مصرّح';
  end if;

  select coalesce(sum(da.points_awarded), 0)::int into v_monthly_points
  from public.daily_achievements da
  where da.student_id = p_student
    and date_trunc('month', da.created_at) = date_trunc('month', now());

  select coalesce(jsonb_agg(jsonb_build_object(
      'grade', t.grade, 'count', t.cnt, 'points_each', t.each, 'total', t.total
    ) order by t.each desc), '[]'::jsonb) into v_points_breakdown
  from (
    select da.grade as grade, count(*)::int as cnt, da.points_awarded as each,
           (count(*) * da.points_awarded)::int as total
    from public.daily_achievements da
    where da.student_id = p_student and da.grade is not null
    group by da.grade, da.points_awarded
  ) t
  where t.each > 0;

  select coalesce(jsonb_agg(r order by r.created_at desc), '[]'::jsonb) into v_recitations from (
    select da.id, da.achievement_type as type, da.surah_from as surah, da.ayah_from, da.ayah_to,
           da.grade, coalesce(g.label, da.grade) as grade_label, da.points_awarded, da.notes,
           da.created_at, da.session_group_id
    from public.daily_achievements da
    left join public.recitation_grades g on g.organization_id = da.organization_id and g.key = da.grade
    where da.student_id = p_student
    order by da.created_at desc limit 300
  ) r;

  select coalesce(jsonb_agg(jsonb_build_object('date', a.session_date, 'status', a.status) order by a.session_date desc), '[]'::jsonb)
    into v_attendance
  from (select * from public.attendance where student_id = p_student order by session_date desc limit 200) a;

  return jsonb_build_object(
    'monthly_points', v_monthly_points,
    'points_breakdown', v_points_breakdown,
    'recitations', v_recitations,
    'attendance', v_attendance
  );
end;
$$;

notify pgrst, 'reload schema';
