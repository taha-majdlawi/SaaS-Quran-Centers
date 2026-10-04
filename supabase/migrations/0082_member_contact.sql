-- =========================================================================
-- 0082_member_contact.sql
-- A teacher's phone and WhatsApp. The phone already lived on profiles (set
-- when the account is created) but could not be edited afterwards; WhatsApp
-- is new. Both are part of the person's global profile, readable by the same
-- people as before (0025: the center's staff profiles are visible to its
-- members), and written by the center's admin through set_member_contact.
-- =========================================================================

alter table public.profiles add column if not exists whatsapp text;
alter table public.profiles drop constraint if exists profiles_whatsapp_len;
alter table public.profiles add constraint profiles_whatsapp_len check (whatsapp is null or char_length(whatsapp) <= 30);

-- digits with an optional leading +, spaces/dashes/brackets allowed; empty = none
create or replace function public._clean_phone(p text)
returns text language plpgsql immutable set search_path = public as $$
declare v text := nullif(btrim(coalesce(p, '')), '');
begin
  if v is null then return null; end if;
  if v !~ '^\+?[0-9][0-9 ()-]{3,24}$' then raise exception 'رقم الهاتف غير صحيح'; end if;
  return v;
end;
$$;

/** The phone and WhatsApp of a member of this center: its admin, or the person themself. */
create or replace function public.member_contact(p_org uuid, p_member uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_user uuid;
begin
  select user_id into v_user from public.organization_members where id = p_member and organization_id = p_org;
  if v_user is null then raise exception 'العضو غير موجود'; end if;
  if not (public.is_org_admin(p_org) or v_user = auth.uid()) then raise exception 'غير مصرّح'; end if;
  return (select jsonb_build_object('phone', phone, 'whatsapp', whatsapp) from public.profiles where id = v_user);
end;
$$;

/** Sets a member's phone and WhatsApp (admin of the center, or the person themself). */
create or replace function public.set_member_contact(p_org uuid, p_member uuid, p_phone text, p_whatsapp text)
returns void language plpgsql security definer set search_path = public as $$
declare v_user uuid;
begin
  select user_id into v_user from public.organization_members where id = p_member and organization_id = p_org;
  if v_user is null then raise exception 'العضو غير موجود'; end if;
  if not (public.is_org_admin(p_org) or v_user = auth.uid()) then raise exception 'غير مصرّح'; end if;
  perform public._assert_can_write(p_org);
  update public.profiles set phone = public._clean_phone(p_phone), whatsapp = public._clean_phone(p_whatsapp) where id = v_user;
end;
$$;

revoke all on function public._clean_phone(text) from public, anon, authenticated;
revoke all on function public.member_contact(uuid, uuid) from public, anon;
revoke all on function public.set_member_contact(uuid, uuid, text, text) from public, anon;
grant execute on function public.member_contact(uuid, uuid) to authenticated;
grant execute on function public.set_member_contact(uuid, uuid, text, text) to authenticated;

-- the teacher's profile page shows the WhatsApp number too (0073, one line added)
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
        'whatsapp', (select whatsapp from public.profiles where id = m.user_id),
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
