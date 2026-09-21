-- =========================================================================
-- 0045_gatherings_external_recitations.sql
-- Ported from eqraa, per center:
--   * gatherings (المجالس): a teacher/admin uploads a shared activity with the
--     names of who attended (free text); the admin links each name to a real
--     student, which records that student's attendance for the day
--   * external recitations (التسميع الخارجي): a teacher records a recitation
--     for a student from another circle by NAME; the admin links it to a
--     student and only then is the recitation written (same points rules)
-- =========================================================================
create extension if not exists pg_trgm with schema extensions;

-- ---------------------------------------------------------------------
-- 1. tables
-- ---------------------------------------------------------------------
-- 0003 created two unused skeleton tables for these names (no screens ever wrote to them); replace them with the real design
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'attendance_gatherings' and column_name = 'occurred_on') then
    if exists (select 1 from public.attendance_gatherings) or exists (select 1 from public.attendance_gathering_entries) then
      raise exception 'attendance_gatherings (old skeleton) has rows - migrate them by hand first';
    end if;
    drop table public.attendance_gathering_entries;
    drop table public.attendance_gatherings;
  end if;
end $$;

create table if not exists public.attendance_gatherings (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null references public.organizations (id) on delete cascade,
  title               text not null,
  activity_type_id    uuid references public.activity_types (id) on delete set null,
  activity_type_label text,
  session_date        date not null,
  location            text,
  notes               text,
  calendar_entry_id   uuid references public.center_calendar (id) on delete set null,
  created_by          uuid not null references auth.users (id),
  status              text not null default 'pending' check (status in ('pending', 'reviewed')),
  reviewed_by         uuid references auth.users (id),
  reviewed_at         timestamptz,
  created_at          timestamptz not null default now()
);
create index if not exists attendance_gatherings_org_idx on public.attendance_gatherings (organization_id, status, session_date desc);

create table if not exists public.attendance_gathering_entries (
  id                 uuid primary key default gen_random_uuid(),
  organization_id    uuid not null references public.organizations (id) on delete cascade,
  gathering_id       uuid not null references public.attendance_gatherings (id) on delete cascade,
  raw_name           text not null,
  status             text not null default 'pending' check (status in ('pending', 'matched', 'skipped')),
  matched_student_id uuid references public.students_profile (id) on delete set null,
  matched_by         uuid references auth.users (id),
  matched_at         timestamptz,
  created_at         timestamptz not null default now()
);
create index if not exists gathering_entries_gathering_idx on public.attendance_gathering_entries (gathering_id);
create index if not exists gathering_entries_student_idx on public.attendance_gathering_entries (matched_student_id);

create table if not exists public.external_recitation_requests (
  id                 uuid primary key default gen_random_uuid(),
  organization_id    uuid not null references public.organizations (id) on delete cascade,
  teacher_id         uuid not null references auth.users (id),
  raw_student_name   text not null,
  type               text not null check (type in ('new_memorization', 'recent_review', 'distant_review')),
  surah_number       integer not null,
  ayah_from          integer not null,
  ayah_to            integer not null,
  grade              text not null,
  notes              text,
  recorded_at        timestamptz not null,
  status             text not null default 'pending' check (status in ('pending', 'matched', 'rejected')),
  matched_student_id uuid references public.students_profile (id) on delete set null,
  achievement_id     uuid references public.daily_achievements (id) on delete set null,
  reviewed_by        uuid references auth.users (id),
  reviewed_at        timestamptz,
  reject_reason      text,
  client_ref         uuid not null unique default gen_random_uuid(),
  created_at         timestamptz not null default now()
);
create index if not exists external_recitation_org_idx on public.external_recitation_requests (organization_id, status, created_at desc);

do $$
declare t text;
begin
  foreach t in array array['attendance_gatherings', 'attendance_gathering_entries', 'external_recitation_requests'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('drop trigger if exists a_deny_readonly_write on public.%I', t);
    execute format('create trigger a_deny_readonly_write before insert or update or delete on public.%I for each row execute function public._deny_readonly_write()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 2. notification types
-- ---------------------------------------------------------------------
insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, lead_hours, roles, sort) values
  ('gathering_submitted', 'رفع مجلس جديد',         'مجلس جديد بانتظار الربط',       '{العنوان} — {عدد} اسم من {المعلم}', array['العنوان', 'عدد', 'المعلم'], null, array['admin'], 170),
  ('external_submitted',  'تسميع خارجي جديد',       'تسميع خارجي بانتظار الربط',     '{الطالب} — من {المعلم}',            array['الطالب', 'المعلم'], null, array['admin'], 180),
  ('external_reviewed',   'نتيجة التسميع الخارجي',  '{الحالة}',                       '{الطالب}',                          array['الحالة', 'الطالب'], null, array['teacher'], 190)
on conflict (event_key) do update set name = excluded.name, available_vars = excluded.available_vars, roles = excluded.roles, sort = excluded.sort;

-- ---------------------------------------------------------------------
-- 3. helpers
-- ---------------------------------------------------------------------
create or replace function public._org_today(p_org uuid)
returns date language sql stable security definer set search_path = public as $$
  select (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
$$;

create or replace function public._org_admins(p_org uuid)
returns uuid[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(user_id), array[]::uuid[]) from public.organization_members where organization_id = p_org and role::text = 'admin' and status = 'active';
$$;

create or replace function public._assert_gathering_staff(p_org uuid)
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if auth.uid() is null or not public.is_org_staff(p_org) then raise exception 'غير مصرّح لك بهذا الإجراء'; end if;
  if not public.is_org_admin(p_org) and not public.member_has_module(p_org, 'attendance') then raise exception 'ليست لديك صلاحية على الحضور'; end if;
end;
$$;

create or replace function public._gathering_maybe_finish(p_gathering uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.attendance_gathering_entries where gathering_id = p_gathering and status = 'pending') then
    update public.attendance_gatherings set status = 'reviewed', reviewed_by = auth.uid(), reviewed_at = now() where id = p_gathering and status <> 'reviewed';
  else
    update public.attendance_gatherings set status = 'pending' where id = p_gathering and status = 'reviewed';
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 4. gatherings
-- ---------------------------------------------------------------------
create or replace function public.submit_gathering(
  p_org uuid, p_title text, p_type uuid, p_date date, p_location text, p_notes text, p_names text[])
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_title text := nullif(btrim(coalesce(p_title, '')), ''); v_date date := coalesce(p_date, public._org_today(p_org));
        v_label text; v_id uuid; v_name text; v_count integer := 0; v_who text;
begin
  perform public._assert_can_write(p_org);
  perform public._assert_gathering_staff(p_org);
  if v_title is null then raise exception 'اكتب اسم النشاط'; end if;
  if v_date > public._org_today(p_org) then raise exception 'لا يمكن رفع حضور بتاريخ مستقبلي'; end if;
  if p_names is null or array_length(p_names, 1) is null then raise exception 'أضف اسمًا واحدًا على الأقل'; end if;
  if array_length(p_names, 1) > 300 then raise exception 'الحد الأقصى 300 اسم في المرة'; end if;
  if p_type is not null then
    select name into v_label from public.activity_types where id = p_type and organization_id = p_org;
    if v_label is null then raise exception 'نوع النشاط غير موجود'; end if;
  end if;
  insert into public.attendance_gatherings (organization_id, title, activity_type_id, activity_type_label, session_date, location, notes, created_by)
  values (p_org, v_title, p_type, v_label, v_date, nullif(btrim(coalesce(p_location, '')), ''), nullif(btrim(coalesce(p_notes, '')), ''), auth.uid())
  returning id into v_id;
  foreach v_name in array p_names loop
    v_name := btrim(coalesce(v_name, ''));
    continue when v_name = '' or length(v_name) > 120;
    insert into public.attendance_gathering_entries (organization_id, gathering_id, raw_name) values (p_org, v_id, v_name);
    v_count := v_count + 1;
  end loop;
  if v_count = 0 then raise exception 'أضف اسمًا واحدًا على الأقل'; end if;
  select full_name into v_who from public.profiles where id = auth.uid();
  perform public._notify(p_org, public._org_admins(p_org), 'gathering_submitted', 'مجلس جديد بانتظار الربط', v_title, v_id,
    jsonb_build_object('العنوان', v_title, 'عدد', v_count::text, 'المعلم', coalesce(v_who, '')));
  return jsonb_build_object('id', v_id, 'names_count', v_count);
end;
$$;

-- mine (staff) — the admin sees all of them in admin_list_gatherings
create or replace function public.my_gatherings(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', g.id, 'title', g.title, 'activity_type_label', g.activity_type_label, 'session_date', g.session_date,
    'status', g.status,
    'total', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = g.id),
    'matched', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = g.id and e.status = 'matched'),
    'skipped', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = g.id and e.status = 'skipped')) order by g.session_date desc, g.created_at desc), '[]'::jsonb)
  from public.attendance_gatherings g where g.organization_id = p_org and g.created_by = auth.uid();
$$;

create or replace function public.delete_gathering(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare g public.attendance_gatherings; v_started boolean;
begin
  select * into g from public.attendance_gatherings where id = p_id;
  if g.id is null then raise exception 'النشاط غير موجود'; end if;
  perform public._assert_can_write(g.organization_id);
  if public.is_org_admin(g.organization_id) then
    -- the admin may delete anything; linked attendance stays (edit it from the attendance screen)
    delete from public.attendance_gatherings where id = p_id;
    return;
  end if;
  if g.created_by <> auth.uid() then raise exception 'يمكنك حذف ما رفعته أنت فقط'; end if;
  select g.reviewed_at is not null or exists (select 1 from public.attendance_gathering_entries e where e.gathering_id = p_id and e.status <> 'pending') into v_started;
  if v_started then raise exception 'بدأ المشرف مراجعة هذا النشاط — لا يمكن حذفه الآن'; end if;
  delete from public.attendance_gatherings where id = p_id;
end;
$$;

create or replace function public.admin_list_gatherings(p_org uuid, p_status text default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', g.id, 'title', g.title, 'activity_type_label', g.activity_type_label, 'session_date', g.session_date,
      'location', g.location, 'notes', g.notes, 'status', g.status, 'teacher_name', p.full_name, 'calendar_entry_id', g.calendar_entry_id,
      'total', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = g.id),
      'pending', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = g.id and e.status = 'pending'),
      'matched', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = g.id and e.status = 'matched'),
      'skipped', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = g.id and e.status = 'skipped'))
      order by g.status = 'pending' desc, g.session_date desc, g.created_at desc)
    from public.attendance_gatherings g left join public.profiles p on p.id = g.created_by
    where g.organization_id = p_org and (p_status is null or p_status = '' or g.status = p_status)), '[]'::jsonb);
end;
$$;

create or replace function public.gathering_detail(p_gathering uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare g public.attendance_gatherings;
begin
  select * into g from public.attendance_gatherings where id = p_gathering;
  if g.id is null then raise exception 'النشاط غير موجود'; end if;
  if not (public.is_org_admin(g.organization_id) or g.created_by = auth.uid()) then raise exception 'غير مصرّح'; end if;
  return jsonb_build_object(
    'id', g.id, 'title', g.title, 'activity_type_id', g.activity_type_id, 'activity_type_label', g.activity_type_label, 'session_date', g.session_date, 'location', g.location, 'notes', g.notes,
    'status', g.status, 'teacher_name', (select full_name from public.profiles where id = g.created_by), 'is_admin', public.is_org_admin(g.organization_id),
    'entries', coalesce((
      select jsonb_agg(jsonb_build_object('id', e.id, 'raw_name', e.raw_name, 'status', e.status, 'matched_student_id', e.matched_student_id,
        'matched_name', sp.full_name, 'matched_code', sp.student_code, 'matched_circle', ci.name) order by e.status = 'pending' desc, e.raw_name)
      from public.attendance_gathering_entries e
      left join public.students_profile sp on sp.id = e.matched_student_id
      left join public.circles ci on ci.id = sp.circle_id
      where e.gathering_id = p_gathering), '[]'::jsonb));
end;
$$;

create or replace function public.admin_suggest_gathering_matches(p_gathering uuid)
returns jsonb language plpgsql stable security definer set search_path = public, extensions as $$
declare g public.attendance_gatherings;
begin
  select * into g from public.attendance_gatherings where id = p_gathering;
  if g.id is null or not public.is_org_admin(g.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('entry_id', e.id, 'raw_name', e.raw_name,
      'suggestions', coalesce((
        select jsonb_agg(jsonb_build_object('student_id', c.id, 'full_name', c.full_name, 'code', c.student_code, 'circle', c.circle_name,
                'score', round(c.sim::numeric, 2)) order by c.sim desc)
        from (select s.id, s.full_name, s.student_code, ci.name as circle_name, similarity(s.full_name, e.raw_name) as sim
              from public.students_profile s left join public.circles ci on ci.id = s.circle_id
              where s.organization_id = g.organization_id and s.status = 'active' and similarity(s.full_name, e.raw_name) > 0.25
              order by similarity(s.full_name, e.raw_name) desc limit 3) c), '[]'::jsonb)) order by e.raw_name)
    from public.attendance_gathering_entries e where e.gathering_id = p_gathering and e.status = 'pending'), '[]'::jsonb);
end;
$$;

create or replace function public.admin_match_gathering_entry(p_entry uuid, p_student uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare e public.attendance_gathering_entries; g public.attendance_gatherings; v_circle uuid; v_att boolean := true; v_note text;
begin
  select * into e from public.attendance_gathering_entries where id = p_entry;
  if e.id is null then raise exception 'الاسم غير موجود'; end if;
  select * into g from public.attendance_gatherings where id = e.gathering_id;
  if not public.is_org_admin(g.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(g.organization_id);
  select circle_id into v_circle from public.students_profile where id = p_student and organization_id = g.organization_id;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if v_circle is null then
    v_att := false; v_note := 'الطالب غير مسند إلى حلقة — رُبط بالنشاط دون تسجيل حضور المركز';
  else
    insert into public.attendance (organization_id, student_id, circle_id, session_date, status, recorded_by)
    values (g.organization_id, p_student, v_circle, g.session_date, 'present', auth.uid())
    on conflict (student_id, session_date) do update set status = 'present', circle_id = excluded.circle_id;
  end if;
  update public.attendance_gathering_entries set status = 'matched', matched_student_id = p_student, matched_by = auth.uid(), matched_at = now() where id = p_entry;
  perform public._gathering_maybe_finish(g.id);
  return jsonb_build_object('entry_id', p_entry, 'center_attendance', v_att, 'note', v_note);
end;
$$;

create or replace function public.admin_skip_gathering_entry(p_entry uuid)
returns void language plpgsql security definer set search_path = public as $$
declare e public.attendance_gathering_entries;
begin
  select * into e from public.attendance_gathering_entries where id = p_entry;
  if e.id is null then raise exception 'الاسم غير موجود'; end if;
  if not public.is_org_admin(e.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(e.organization_id);
  update public.attendance_gathering_entries set status = 'skipped', matched_student_id = null, matched_by = auth.uid(), matched_at = now() where id = p_entry;
  perform public._gathering_maybe_finish(e.gathering_id);
end;
$$;

create or replace function public.admin_unmatch_gathering_entry(p_entry uuid)
returns text language plpgsql security definer set search_path = public as $$
declare e public.attendance_gathering_entries;
begin
  select * into e from public.attendance_gathering_entries where id = p_entry;
  if e.id is null then raise exception 'الاسم غير موجود'; end if;
  if not public.is_org_admin(e.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(e.organization_id);
  update public.attendance_gathering_entries set status = 'pending', matched_student_id = null, matched_by = null, matched_at = null where id = p_entry;
  perform public._gathering_maybe_finish(e.gathering_id);
  return 'أُلغي الربط. حضور المركز لذلك اليوم لم يُلغَ تلقائيًا — عدّله من شاشة الحضور إن لزم.';
end;
$$;

create or replace function public.admin_update_gathering(p_id uuid, p_title text, p_type uuid, p_date date, p_location text, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
declare g public.attendance_gatherings; v_label text;
begin
  select * into g from public.attendance_gatherings where id = p_id;
  if g.id is null or not public.is_org_admin(g.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(g.organization_id);
  if nullif(btrim(coalesce(p_title, '')), '') is null then raise exception 'اكتب اسم النشاط'; end if;
  if p_date > public._org_today(g.organization_id) then raise exception 'لا يمكن أن يكون التاريخ مستقبليًا'; end if;
  if p_type is not null then select name into v_label from public.activity_types where id = p_type and organization_id = g.organization_id; end if;
  update public.attendance_gatherings set title = btrim(p_title), activity_type_id = p_type, activity_type_label = v_label, session_date = p_date,
    location = nullif(btrim(coalesce(p_location, '')), ''), notes = nullif(btrim(coalesce(p_notes, '')), '') where id = p_id;
end;
$$;

create or replace function public.gathering_add_entry(p_gathering uuid, p_name text)
returns void language plpgsql security definer set search_path = public as $$
declare g public.attendance_gatherings; v_name text := nullif(btrim(coalesce(p_name, '')), '');
begin
  select * into g from public.attendance_gatherings where id = p_gathering;
  if g.id is null then raise exception 'النشاط غير موجود'; end if;
  if not (public.is_org_admin(g.organization_id) or g.created_by = auth.uid()) then raise exception 'غير مصرّح'; end if;
  perform public._assert_can_write(g.organization_id);
  if v_name is null or length(v_name) > 120 then raise exception 'اكتب اسمًا صالحًا'; end if;
  insert into public.attendance_gathering_entries (organization_id, gathering_id, raw_name) values (g.organization_id, p_gathering, v_name);
  perform public._gathering_maybe_finish(p_gathering);
end;
$$;

create or replace function public.gathering_delete_entry(p_entry uuid)
returns void language plpgsql security definer set search_path = public as $$
declare e public.attendance_gathering_entries; g public.attendance_gatherings;
begin
  select * into e from public.attendance_gathering_entries where id = p_entry;
  if e.id is null then raise exception 'الاسم غير موجود'; end if;
  select * into g from public.attendance_gatherings where id = e.gathering_id;
  if not (public.is_org_admin(g.organization_id) or (g.created_by = auth.uid() and e.status = 'pending')) then raise exception 'غير مصرّح'; end if;
  perform public._assert_can_write(g.organization_id);
  delete from public.attendance_gathering_entries where id = p_entry;
  perform public._gathering_maybe_finish(g.id);
end;
$$;

-- ---------------------------------------------------------------------
-- 5. external recitations
-- ---------------------------------------------------------------------
create or replace function public.submit_external_recitation(
  p_org uuid, p_name text, p_type text, p_surah integer, p_from integer, p_to integer, p_grade text,
  p_notes text default null, p_recorded_at timestamptz default null, p_client_ref uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_name text := nullif(btrim(coalesce(p_name, '')), ''); v_id uuid; v_rec timestamptz := coalesce(p_recorded_at, now()); v_days integer; v_who text;
begin
  perform public._assert_can_write(p_org);
  if auth.uid() is null or not public.is_org_staff(p_org) then raise exception 'غير مصرّح لك بهذا الإجراء'; end if;
  if not public.is_org_admin(p_org) and not public.member_has_module(p_org, 'students') then raise exception 'ليست لديك صلاحية على الطلاب'; end if;
  if v_name is null or length(v_name) > 120 then raise exception 'اكتب اسم الطالب'; end if;
  if p_type not in ('new_memorization', 'recent_review', 'distant_review') then raise exception 'نوع الإنجاز غير صالح'; end if;
  if not exists (select 1 from public.recitation_grades where organization_id = p_org and key = p_grade and is_active) then raise exception 'تقدير غير معروف في هذا المركز'; end if;
  perform public.validate_ayah_range(p_surah, p_from, p_to);
  v_days := coalesce(nullif(public.org_setting(p_org, 'backdate_days', '60'), '')::integer, 60);
  if v_rec > now() + interval '1 hour' or v_rec < now() - make_interval(days => v_days) then v_rec := now(); end if;
  if p_client_ref is not null then
    select id into v_id from public.external_recitation_requests where client_ref = p_client_ref and organization_id = p_org;
    if found then return jsonb_build_object('id', v_id, 'was_duplicate', true); end if;
  end if;
  insert into public.external_recitation_requests (organization_id, teacher_id, raw_student_name, type, surah_number, ayah_from, ayah_to, grade, notes, recorded_at, client_ref)
  values (p_org, auth.uid(), v_name, p_type, p_surah, p_from, p_to, p_grade, nullif(btrim(coalesce(p_notes, '')), ''), v_rec, coalesce(p_client_ref, gen_random_uuid()))
  returning id into v_id;
  select full_name into v_who from public.profiles where id = auth.uid();
  perform public._notify(p_org, public._org_admins(p_org), 'external_submitted', 'تسميع خارجي بانتظار الربط', v_name, v_id,
    jsonb_build_object('الطالب', v_name, 'المعلم', coalesce(v_who, '')));
  return jsonb_build_object('id', v_id, 'was_duplicate', false);
end;
$$;

create or replace function public.my_external_recitations(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', r.id, 'raw_student_name', r.raw_student_name, 'type', r.type, 'surah', r.surah_number,
    'ayah_from', r.ayah_from, 'ayah_to', r.ayah_to, 'grade', r.grade, 'notes', r.notes, 'recorded_at', r.recorded_at, 'status', r.status,
    'matched_name', sp.full_name, 'reject_reason', r.reject_reason, 'points', da.points_awarded) order by r.created_at desc), '[]'::jsonb)
  from public.external_recitation_requests r
  left join public.students_profile sp on sp.id = r.matched_student_id
  left join public.daily_achievements da on da.id = r.achievement_id
  where r.organization_id = p_org and r.teacher_id = auth.uid();
$$;

create or replace function public.delete_external_recitation(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r public.external_recitation_requests;
begin
  select * into r from public.external_recitation_requests where id = p_id;
  if r.id is null then raise exception 'الطلب غير موجود'; end if;
  perform public._assert_can_write(r.organization_id);
  if r.teacher_id <> auth.uid() and not public.is_org_admin(r.organization_id) then raise exception 'يمكنك حذف ما رفعته أنت فقط'; end if;
  if r.status <> 'pending' and not public.is_org_admin(r.organization_id) then raise exception 'رُوجع هذا الطلب — لا يمكن حذفه الآن'; end if;
  delete from public.external_recitation_requests where id = p_id;
end;
$$;

create or replace function public.admin_list_external_recitations(p_org uuid, p_status text default null)
returns jsonb language plpgsql stable security definer set search_path = public, extensions as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', r.id, 'raw_student_name', r.raw_student_name, 'type', r.type, 'surah', r.surah_number, 'ayah_from', r.ayah_from,
      'ayah_to', r.ayah_to, 'grade', r.grade, 'notes', r.notes, 'recorded_at', r.recorded_at, 'status', r.status, 'teacher_name', p.full_name,
      'matched_name', sp.full_name, 'reject_reason', r.reject_reason,
      'suggestions', case when r.status = 'pending' then coalesce((
        select jsonb_agg(jsonb_build_object('student_id', c.id, 'full_name', c.full_name, 'code', c.student_code, 'circle', c.circle_name, 'score', round(c.sim::numeric, 2)) order by c.sim desc)
        from (select s.id, s.full_name, s.student_code, ci.name as circle_name, similarity(s.full_name, r.raw_student_name) as sim
              from public.students_profile s left join public.circles ci on ci.id = s.circle_id
              where s.organization_id = p_org and s.status = 'active' and similarity(s.full_name, r.raw_student_name) > 0.25
              order by similarity(s.full_name, r.raw_student_name) desc limit 3) c), '[]'::jsonb) else '[]'::jsonb end)
      order by r.status = 'pending' desc, r.created_at desc)
    from public.external_recitation_requests r
    left join public.profiles p on p.id = r.teacher_id
    left join public.students_profile sp on sp.id = r.matched_student_id
    where r.organization_id = p_org and (p_status is null or p_status = '' or r.status = p_status)), '[]'::jsonb);
end;
$$;

-- the recitation is written only now, attributed to the teacher who heard it, with the center's normal points rules
create or replace function public.admin_match_external_recitation(p_id uuid, p_student uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare r public.external_recitation_requests; v_circle uuid; v_name text; v_ach uuid; v_points integer; v_tz text;
begin
  select * into r from public.external_recitation_requests where id = p_id;
  if r.id is null then raise exception 'الطلب غير موجود'; end if;
  if not public.is_org_admin(r.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(r.organization_id);
  if r.status = 'matched' then raise exception 'رُبط هذا الطلب من قبل'; end if;
  select circle_id, full_name into v_circle, v_name from public.students_profile where id = p_student and organization_id = r.organization_id;
  if not found then raise exception 'الطالب غير موجود'; end if;
  insert into public.daily_achievements (organization_id, student_id, circle_id, achievement_type, surah_from, ayah_from, surah_to, ayah_to, grade, notes, client_ref, recorded_by, created_at)
  values (r.organization_id, p_student, v_circle, r.type::public.achievement_type, r.surah_number, r.ayah_from, r.surah_number, r.ayah_to, r.grade,
          coalesce(r.notes, 'تسميع خارجي'), r.client_ref, r.teacher_id, r.recorded_at)
  returning id, points_awarded into v_ach, v_points;
  select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = r.organization_id;
  if v_circle is not null then
    insert into public.attendance (organization_id, student_id, circle_id, session_date, status, recorded_by)
    values (r.organization_id, p_student, v_circle, (r.recorded_at at time zone v_tz)::date, 'present', r.teacher_id)
    on conflict (student_id, session_date) do nothing;
  end if;
  update public.external_recitation_requests set status = 'matched', matched_student_id = p_student, achievement_id = v_ach, reviewed_by = auth.uid(), reviewed_at = now() where id = p_id;
  perform public._notify(r.organization_id, array[r.teacher_id], 'external_reviewed', 'رُبط تسميعك الخارجي', v_name, p_id,
    jsonb_build_object('الحالة', 'رُبط تسميعك الخارجي', 'الطالب', v_name));
  return jsonb_build_object('achievement_id', v_ach, 'points_awarded', coalesce(v_points, 0));
end;
$$;

create or replace function public.admin_reject_external_recitation(p_id uuid, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r public.external_recitation_requests;
begin
  select * into r from public.external_recitation_requests where id = p_id;
  if r.id is null then raise exception 'الطلب غير موجود'; end if;
  if not public.is_org_admin(r.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(r.organization_id);
  if r.status <> 'pending' then raise exception 'رُوجع هذا الطلب من قبل'; end if;
  update public.external_recitation_requests set status = 'rejected', reject_reason = nullif(btrim(coalesce(p_reason, '')), ''), reviewed_by = auth.uid(), reviewed_at = now() where id = p_id;
  perform public._notify(r.organization_id, array[r.teacher_id], 'external_reviewed', 'رُفض تسميعك الخارجي', r.raw_student_name, p_id,
    jsonb_build_object('الحالة', 'رُفض تسميعك الخارجي', 'الطالب', r.raw_student_name));
end;
$$;

-- what waits for the admin (dashboard counters)
create or replace function public.admin_pending_reviews(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return jsonb_build_object(
    'gatherings', (select count(*) from public.attendance_gatherings where organization_id = p_org and status = 'pending'),
    'external', (select count(*) from public.external_recitation_requests where organization_id = p_org and status = 'pending'));
end;
$$;

-- ---------------------------------------------------------------------
-- privileges
-- ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array['_org_today(uuid)', '_org_admins(uuid)', '_assert_gathering_staff(uuid)', '_gathering_maybe_finish(uuid)'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
  foreach f in array array[
    'submit_gathering(uuid, text, uuid, date, text, text, text[])', 'my_gatherings(uuid)', 'delete_gathering(uuid)', 'admin_list_gatherings(uuid, text)',
    'gathering_detail(uuid)', 'admin_suggest_gathering_matches(uuid)', 'admin_match_gathering_entry(uuid, uuid)', 'admin_skip_gathering_entry(uuid)',
    'admin_unmatch_gathering_entry(uuid)', 'admin_update_gathering(uuid, text, uuid, date, text, text)', 'gathering_add_entry(uuid, text)', 'gathering_delete_entry(uuid)',
    'submit_external_recitation(uuid, text, text, integer, integer, integer, text, text, timestamptz, uuid)', 'my_external_recitations(uuid)',
    'delete_external_recitation(uuid)', 'admin_list_external_recitations(uuid, text)', 'admin_match_external_recitation(uuid, uuid)',
    'admin_reject_external_recitation(uuid, text)', 'admin_pending_reviews(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
