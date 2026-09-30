-- =====================================================================
-- 0072: one-page profiles for the dashboard
-- ---------------------------------------------------------------------
-- Clicking a student, teacher or circle name opens a page with everything
-- about it. Three read-only RPCs gather that in one round trip each:
--
--   student_profile(org, student)            who / where / contact / guardian /
--                                             plan / standing; the achievements
--                                             of a period come from student_report
--   teacher_profile(org, member|user, from, to)
--   circle_profile(org, circle, from, to)
--
-- Who may look: an admin, a member with the "reports" module, and the people
-- the thing belongs to (the student's teacher, the teacher him/herself, a
-- teacher or assistant of the circle).
-- =====================================================================

create or replace function public.student_profile(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare s public.students_profile%rowtype; c public.circles%rowtype; v_today date; v_out jsonb;
begin
  select * into s from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if not (public.is_org_admin(p_org) or public.member_has_module(p_org, 'reports')
          or public._is_circle_teacher(s.circle_id)) then
    raise exception 'غير مصرّح';
  end if;
  select * into c from public.circles where id = s.circle_id;
  v_today := (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;

  select jsonb_build_object(
    'id', s.id, 'name', s.full_name, 'code', s.student_code, 'status', s.status, 'birth_date', s.birth_date,
    'phone', s.phone, 'whatsapp', s.whatsapp, 'address', s.address, 'next_plan', s.next_plan, 'joined', s.created_at,
    'total_points', s.total_points, 'parts_count', s.total_parts_count, 'saved_parts', s.saved_parts_numbers,
    'circle', case when c.id is null then null else jsonb_build_object('id', c.id, 'name', c.name,
        'stage', (select st.name from public.stages st where st.id = c.stage_id)) end,
    'teacher', (select jsonb_build_object('member_id', m.id, 'name', pr.full_name)
                from public.organization_members m left join public.profiles pr on pr.id = m.user_id
                where m.organization_id = p_org and m.user_id = c.teacher_id limit 1),
    'guardian', (select jsonb_build_object('member_id', m.id, 'name', pr.full_name, 'phone', pr.phone,
                          'email', (select u.email from auth.users u where u.id = m.user_id))
                 from public.organization_members m left join public.profiles pr on pr.id = m.user_id
                 where m.id = s.guardian_member_id),
    'has_login', s.member_id is not null,
    'last_recited', (select max(created_at) from public.daily_achievements where student_id = s.id),
    'recitations_total', (select count(*) from public.daily_achievements where student_id = s.id),
    -- place in the circle by points (active students)
    'rank', case when s.circle_id is null then null else
        (select 1 + count(*) from public.students_profile o
          where o.circle_id = s.circle_id and o.status = 'active' and o.total_points > s.total_points) end,
    'circle_size', (select count(*) from public.students_profile o where o.circle_id = s.circle_id and o.status = 'active'),
    -- the last 14 days, one mark per day (null = no record)
    'last_days', (select jsonb_agg(jsonb_build_object('date', d::date,
                    'att', (select a.status::text from public.attendance a where a.student_id = s.id and a.session_date = d::date limit 1),
                    'rec', (select count(*) from public.daily_achievements da where da.student_id = s.id
                             and (da.created_at at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date = d::date))
                    order by d)
                  from generate_series(v_today - 13, v_today, interval '1 day') d)
  ) into v_out;
  return v_out;
end;
$$;

create or replace function public.teacher_profile(p_org uuid, p_id uuid, p_from date default null, p_to date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_from date := coalesce(p_from, date_trunc('month', current_date)::date);
  v_to date := coalesce(p_to, current_date);
  v_a timestamptz; v_b timestamptz; m public.organization_members%rowtype; v_out jsonb;
begin
  -- the page may link with the membership id or the user id
  select * into m from public.organization_members where organization_id = p_org and (id = p_id or user_id = p_id)
   order by (id = p_id) desc limit 1;
  if not found then raise exception 'المعلم غير موجود'; end if;
  if not (public.is_org_admin(p_org) or public.member_has_module(p_org, 'reports') or m.user_id = auth.uid()) then
    raise exception 'غير مصرّح';
  end if;
  if v_to < v_from then raise exception 'تاريخ النهاية قبل البداية'; end if;
  if v_to - v_from > 731 then raise exception 'الفترة أطول من سنتين'; end if;
  v_a := v_from::timestamptz; v_b := (v_to + 1)::timestamptz;

  with my_circles as (
    select c.id, c.name, c.status, c.stage_id, 'primary'::text as kind from public.circles c
     where c.organization_id = p_org and c.teacher_id = m.user_id
    union
    select c.id, c.name, c.status, c.stage_id, 'assistant' from public.circles c
      join public.circle_assistants a on a.circle_id = c.id
     where c.organization_id = p_org and a.user_id = m.user_id and c.teacher_id is distinct from m.user_id
  ), recs as (
    select * from public.daily_achievements
     where organization_id = p_org and recorded_by = m.user_id and created_at >= v_a and created_at < v_b
  )
  select jsonb_build_object(
    'from', v_from, 'to', v_to,
    'teacher', jsonb_build_object('member_id', m.id, 'user_id', m.user_id, 'role', m.role, 'status', m.status, 'joined', m.created_at,
        'name', (select full_name from public.profiles where id = m.user_id),
        'phone', (select phone from public.profiles where id = m.user_id),
        'email', (select email from auth.users where id = m.user_id),
        'last_active', (select max(created_at) from public.daily_achievements where organization_id = p_org and recorded_by = m.user_id)),
    'circles', coalesce((select jsonb_agg(jsonb_build_object('id', mc.id, 'name', mc.name, 'status', mc.status, 'kind', mc.kind,
        'stage', (select st.name from public.stages st where st.id = mc.stage_id),
        'students', (select count(*) from public.students_profile s where s.circle_id = mc.id and s.status = 'active'),
        'recitations', (select count(*) from public.daily_achievements a where a.circle_id = mc.id and a.created_at >= v_a and a.created_at < v_b),
        'points', (select coalesce(sum(points_awarded), 0) from public.daily_achievements a where a.circle_id = mc.id and a.created_at >= v_a and a.created_at < v_b),
        'attendance_rate', (select case when count(*) filter (where at.status::text in ('present','late','absent')) = 0 then null
                   else round(100.0 * count(*) filter (where at.status::text in ('present','late')) / count(*) filter (where at.status::text in ('present','late','absent')), 1) end
              from public.attendance at join public.students_profile s on s.id = at.student_id
             where s.circle_id = mc.id and at.session_date between v_from and v_to))
        order by mc.kind desc, mc.name) from my_circles mc), '[]'::jsonb),
    'totals', jsonb_build_object(
        'students', (select count(*) from public.students_profile s where s.status = 'active' and s.circle_id in (select id from my_circles)),
        'recitations', (select count(*) from recs),
        'reciting_students', (select count(distinct student_id) from recs),
        'points', (select coalesce(sum(points_awarded), 0) from recs),
        'serd', (select count(*) from public.serd_sessions ss where ss.organization_id = p_org and ss.examiner_id = m.user_id
                  and ss.status in ('submitted', 'approved') and ss.session_date between v_from and v_to),
        'present', (select count(*) from public.teacher_attendance t where t.organization_id = p_org and t.teacher_id = m.user_id and t.date between v_from and v_to and t.status::text = 'present'),
        'late', (select count(*) from public.teacher_attendance t where t.organization_id = p_org and t.teacher_id = m.user_id and t.date between v_from and v_to and t.status::text = 'late'),
        'absent', (select count(*) from public.teacher_attendance t where t.organization_id = p_org and t.teacher_id = m.user_id and t.date between v_from and v_to and t.status::text = 'absent'),
        'excused', (select count(*) from public.teacher_attendance t where t.organization_id = p_org and t.teacher_id = m.user_id and t.date between v_from and v_to and t.status::text = 'excused')),
    'by_type', coalesce((select jsonb_agg(jsonb_build_object('type', k, 'count', n)) from
        (select achievement_type::text k, count(*) n from recs group by 1) t), '[]'::jsonb),
    'daily', coalesce((select jsonb_agg(jsonb_build_object('date', d, 'recitations', n) order by d) from
        (select created_at::date d, count(*) n from recs group by 1) t), '[]'::jsonb),
    'recent', coalesce((select jsonb_agg(jsonb_build_object('at', r.created_at, 'student_id', r.student_id, 'student', s.full_name,
        'type', r.achievement_type::text, 'surah_from', r.surah_from, 'ayah_from', r.ayah_from, 'surah_to', r.surah_to, 'ayah_to', r.ayah_to,
        'grade', r.grade, 'points', r.points_awarded) order by r.created_at desc)
        from (select * from recs order by created_at desc limit 40) r join public.students_profile s on s.id = r.student_id), '[]'::jsonb),
    'attendance', coalesce((select jsonb_agg(jsonb_build_object('date', t.date, 'circle', c.name, 'status', t.status, 'checked_in_at', t.checked_in_at,
        'note', t.note, 'set_by_admin', t.set_by_admin) order by t.date desc)
        from public.teacher_attendance t join public.circles c on c.id = t.circle_id
        where t.organization_id = p_org and t.teacher_id = m.user_id and t.date between v_from and v_to), '[]'::jsonb),
    'serd', coalesce((select jsonb_agg(jsonb_build_object('date', ss.session_date, 'student_id', ss.student_id, 'student', ss.student_name,
        'juz', ss.juz_numbers, 'score', ss.score_percent, 'status', ss.status) order by ss.session_date desc)
        from (select * from public.serd_sessions where organization_id = p_org and examiner_id = m.user_id
              and status in ('submitted', 'approved', 'rejected') and session_date between v_from and v_to
              order by session_date desc limit 30) ss), '[]'::jsonb)
  ) into v_out;
  return v_out;
end;
$$;

create or replace function public.circle_profile(p_org uuid, p_circle uuid, p_from date default null, p_to date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_from date := coalesce(p_from, date_trunc('month', current_date)::date);
  v_to date := coalesce(p_to, current_date);
  v_a timestamptz; v_b timestamptz; c public.circles%rowtype; v_out jsonb;
begin
  select * into c from public.circles where id = p_circle and organization_id = p_org;
  if not found then raise exception 'الحلقة غير موجودة'; end if;
  if not (public.is_org_admin(p_org) or public.member_has_module(p_org, 'reports') or public._is_circle_teacher(p_circle)) then
    raise exception 'غير مصرّح';
  end if;
  if v_to < v_from then raise exception 'تاريخ النهاية قبل البداية'; end if;
  if v_to - v_from > 731 then raise exception 'الفترة أطول من سنتين'; end if;
  v_a := v_from::timestamptz; v_b := (v_to + 1)::timestamptz;

  with recs as (
    select * from public.daily_achievements where circle_id = p_circle and created_at >= v_a and created_at < v_b
  ), att as (
    select a.* from public.attendance a join public.students_profile s on s.id = a.student_id
     where s.circle_id = p_circle and a.session_date between v_from and v_to
  )
  select jsonb_build_object(
    'from', v_from, 'to', v_to,
    'circle', jsonb_build_object('id', c.id, 'name', c.name, 'status', c.status, 'capacity', c.capacity, 'schedule', c.schedule,
        'created_at', c.created_at, 'stage', (select st.name from public.stages st where st.id = c.stage_id)),
    'teacher', (select jsonb_build_object('member_id', m.id, 'name', pr.full_name, 'phone', pr.phone)
                from public.organization_members m left join public.profiles pr on pr.id = m.user_id
                where m.organization_id = p_org and m.user_id = c.teacher_id limit 1),
    'assistants', coalesce((select jsonb_agg(jsonb_build_object('member_id', m.id, 'name', pr.full_name) order by pr.full_name)
                from public.circle_assistants ca join public.organization_members m on m.organization_id = p_org and m.user_id = ca.user_id
                left join public.profiles pr on pr.id = ca.user_id where ca.circle_id = p_circle), '[]'::jsonb),
    'totals', jsonb_build_object(
        'students', (select count(*) from public.students_profile where circle_id = p_circle and status = 'active'),
        'recitations', (select count(*) from recs),
        'reciting_students', (select count(distinct student_id) from recs),
        'points', (select coalesce(sum(points_awarded), 0) from recs),
        'present', (select count(*) from att where status::text = 'present'),
        'late', (select count(*) from att where status::text = 'late'),
        'absent', (select count(*) from att where status::text = 'absent'),
        'excused', (select count(*) from att where status::text = 'excused'),
        'attendance_rate', (select case when count(*) filter (where status::text in ('present','late','absent')) = 0 then null
                   else round(100.0 * count(*) filter (where status::text in ('present','late')) / count(*) filter (where status::text in ('present','late','absent')), 1) end from att),
        'serd_approved', (select count(*) from public.serd_sessions ss join public.students_profile s on s.id = ss.student_id
                          where s.circle_id = p_circle and ss.status = 'approved' and ss.session_date between v_from and v_to),
        'teacher_days', (select count(*) from public.teacher_attendance t where t.circle_id = p_circle and t.date between v_from and v_to and t.status::text in ('present', 'late'))),
    'students', coalesce((select jsonb_agg(jsonb_build_object('id', s.id, 'name', s.full_name, 'code', s.student_code, 'status', s.status,
        'total_points', s.total_points, 'parts_count', s.total_parts_count,
        'recitations', (select count(*) from recs r where r.student_id = s.id),
        'points', (select coalesce(sum(points_awarded), 0) from recs r where r.student_id = s.id),
        'attendance_rate', (select case when count(*) filter (where status::text in ('present','late','absent')) = 0 then null
                   else round(100.0 * count(*) filter (where status::text in ('present','late')) / count(*) filter (where status::text in ('present','late','absent')), 1) end
              from att where att.student_id = s.id),
        'last_recited', (select max(created_at) from public.daily_achievements d where d.student_id = s.id))
        order by (s.status = 'active') desc, s.total_points desc, s.full_name)
        from public.students_profile s where s.circle_id = p_circle), '[]'::jsonb),
    'by_type', coalesce((select jsonb_agg(jsonb_build_object('type', k, 'count', n)) from
        (select achievement_type::text k, count(*) n from recs group by 1) t), '[]'::jsonb),
    'daily', coalesce((select jsonb_agg(jsonb_build_object('date', d, 'recitations', n) order by d) from
        (select created_at::date d, count(*) n from recs group by 1) t), '[]'::jsonb),
    'recent', coalesce((select jsonb_agg(jsonb_build_object('at', r.created_at, 'student_id', r.student_id, 'student', s.full_name,
        'type', r.achievement_type::text, 'surah_from', r.surah_from, 'ayah_from', r.ayah_from, 'surah_to', r.surah_to, 'ayah_to', r.ayah_to,
        'grade', r.grade, 'points', r.points_awarded, 'by', (select full_name from public.profiles where id = r.recorded_by)) order by r.created_at desc)
        from (select * from recs order by created_at desc limit 40) r join public.students_profile s on s.id = r.student_id), '[]'::jsonb)
  ) into v_out;
  return v_out;
end;
$$;

do $$
declare f text;
begin
  foreach f in array array['student_profile(uuid, uuid)', 'teacher_profile(uuid, uuid, date, date)', 'circle_profile(uuid, uuid, date, date)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
