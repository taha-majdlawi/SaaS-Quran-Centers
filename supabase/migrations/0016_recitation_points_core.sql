-- =========================================================================
-- 0016_recitation_points_core.sql
-- Phase 1 of eqraa_app parity: the recitation + points core, with every
-- value that eqraa hard-codes turned into a PER-CENTER setting.
--
--   * recitation_grades  - grade names + points (eqraa: excellent 20 ...)
--   * organization_settings - flags, prayer settings, back-date window ...
--   * center_weekdays    - working days (attendance % is measured on these)
--   * surah_ayah_counts  - canonical reference data + validate_ayah_range()
--   * students_profile   - phone/address/next_plan/total_points ...
--   * daily_achievements - grade key, notes, client_ref, session group
--   * triggers: freeze points at write time, keep total_points in sync
--   * log_recitation()   - the ONLY write path teachers use (mirrors eqraa's
--                          log_recitation_and_award_points incl. caller checks)
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. Canonical Quran reference data (global, read-only)
-- ---------------------------------------------------------------------
create table if not exists public.surah_ayah_counts (
  surah_number integer primary key check (surah_number between 1 and 114),
  ayah_count   integer not null check (ayah_count > 0)
);

insert into public.surah_ayah_counts (surah_number, ayah_count) values
(1,7),(2,286),(3,200),(4,176),(5,120),(6,165),(7,206),(8,75),(9,129),(10,109),(11,123),(12,111),(13,43),(14,52),(15,99),(16,128),(17,111),(18,110),(19,98),(20,135),(21,112),(22,78),(23,118),(24,64),(25,77),(26,227),(27,93),(28,88),(29,69),(30,60),(31,34),(32,30),(33,73),(34,54),(35,45),(36,83),(37,182),(38,88),(39,75),(40,85),(41,54),(42,53),(43,89),(44,59),(45,37),(46,35),(47,38),(48,29),(49,18),(50,45),(51,60),(52,49),(53,62),(54,55),(55,78),(56,96),(57,29),(58,22),(59,24),(60,13),(61,14),(62,11),(63,11),(64,18),(65,12),(66,12),(67,30),(68,52),(69,52),(70,44),(71,28),(72,28),(73,20),(74,56),(75,40),(76,31),(77,50),(78,40),(79,46),(80,42),(81,29),(82,19),(83,36),(84,25),(85,22),(86,17),(87,19),(88,26),(89,30),(90,20),(91,15),(92,21),(93,11),(94,8),(95,8),(96,19),(97,5),(98,8),(99,8),(100,11),(101,11),(102,8),(103,3),(104,9),(105,5),(106,4),(107,7),(108,3),(109,6),(110,3),(111,5),(112,4),(113,5),(114,6)
on conflict (surah_number) do update set ayah_count = excluded.ayah_count;

do $$
declare v_total integer; v_rows integer;
begin
  select sum(ayah_count), count(*) into v_total, v_rows from public.surah_ayah_counts;
  if v_rows <> 114 or v_total <> 6236 then
    raise exception 'surah_ayah_counts is wrong: % surahs totalling % (expected 114 / 6236)', v_rows, v_total;
  end if;
end $$;

alter table public.surah_ayah_counts enable row level security;
drop policy if exists "surah_ayah_counts_read" on public.surah_ayah_counts;
create policy "surah_ayah_counts_read" on public.surah_ayah_counts for select to authenticated using (true);

create or replace function public.validate_ayah_range(p_surah integer, p_from integer, p_to integer)
returns void language plpgsql stable set search_path = public as $$
declare v_max integer;
begin
  if p_surah is null or p_surah < 1 or p_surah > 114 then
    raise exception 'رقم السورة غير صالح';
  end if;
  if p_from is null or p_to is null or p_from < 1 then
    raise exception 'نطاق الآيات غير صالح';
  end if;
  if p_to < p_from then
    raise exception 'آية النهاية يجب ألا تسبق آية البداية';
  end if;
  select ayah_count into v_max from public.surah_ayah_counts where surah_number = p_surah;
  if p_to > v_max then
    raise exception 'هذه السورة % آية فقط، ولا تحتوي آية %', v_max, p_to;
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 2. Per-center configuration tables
-- ---------------------------------------------------------------------
create table public.recitation_grades (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  key             text not null check (key ~ '^[a-z0-9_]{1,40}$'),
  label           text not null,
  points          integer not null default 0 check (points >= 0),
  sort_order      integer not null default 0,
  is_active       boolean not null default true,
  primary key (organization_id, key)
);

create table public.organization_settings (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  key             text not null,
  value           text,
  updated_at      timestamptz not null default now(),
  primary key (organization_id, key)
);

create table public.center_weekdays (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  dow             smallint not null check (dow between 0 and 6),  -- 0 = Sunday
  label           text not null,
  is_working      boolean not null default true,
  is_serd_day     boolean not null default false,
  primary key (organization_id, dow),
  check (not (is_serd_day and not is_working))
);

alter table public.recitation_grades enable row level security;
alter table public.organization_settings enable row level security;
alter table public.center_weekdays enable row level security;

create policy "recitation_grades_select_org" on public.recitation_grades for select using (public.is_org_member(organization_id));
create policy "recitation_grades_write_admin" on public.recitation_grades for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "organization_settings_select_org" on public.organization_settings for select using (public.is_org_member(organization_id));
create policy "organization_settings_write_admin" on public.organization_settings for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "center_weekdays_select_org" on public.center_weekdays for select using (public.is_org_member(organization_id));
create policy "center_weekdays_write_admin" on public.center_weekdays for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

-- Defaults every center starts with (all editable afterwards by its admin).
create or replace function public.seed_organization_defaults(p_org uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.recitation_grades (organization_id, key, label, points, sort_order) values
    (p_org, 'excellent',  'ممتاز',    20, 1),
    (p_org, 'very_good',  'جيد جداً', 15, 2),
    (p_org, 'good',       'جيد',      10, 3),
    (p_org, 'acceptable', 'مقبول',     5, 4)
  on conflict do nothing;

  insert into public.organization_settings (organization_id, key, value) values
    (p_org, 'backdate_days',                '60'),
    (p_org, 'phone_country_code',           ''),
    (p_org, 'whatsapp_group_link',          ''),
    (p_org, 'center_location_label',        ''),
    (p_org, 'prayer_lat',                   ''),
    (p_org, 'prayer_lng',                   ''),
    (p_org, 'prayer_calc_method',           'umm_al_qura'),
    (p_org, 'prayer_madhab',                'shafi'),
    (p_org, 'flag_market_enabled',          'true'),
    (p_org, 'flag_leaderboard_enabled',     'true'),
    (p_org, 'flag_teacher_manage_students', 'true')
  on conflict do nothing;

  insert into public.center_weekdays (organization_id, dow, label, is_working) values
    (p_org, 0, 'الأحد',     true),
    (p_org, 1, 'الاثنين',   true),
    (p_org, 2, 'الثلاثاء',  true),
    (p_org, 3, 'الأربعاء',  true),
    (p_org, 4, 'الخميس',    true),
    (p_org, 5, 'الجمعة',    false),
    (p_org, 6, 'السبت',     false)
  on conflict do nothing;
end;
$$;

create or replace function public.trg_seed_organization_defaults()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.seed_organization_defaults(new.id);
  return new;
end;
$$;

drop trigger if exists organizations_seed_defaults on public.organizations;
create trigger organizations_seed_defaults
  after insert on public.organizations
  for each row execute function public.trg_seed_organization_defaults();

-- Existing centers get the same defaults.
do $$
declare r record;
begin
  for r in select id from public.organizations loop
    perform public.seed_organization_defaults(r.id);
  end loop;
end $$;

create or replace function public.org_setting(p_org uuid, p_key text, p_default text default null)
returns text language sql stable security definer set search_path = public as $$
  select coalesce(
    (select value from public.organization_settings where organization_id = p_org and key = p_key),
    p_default
  );
$$;

-- ---------------------------------------------------------------------
-- 3. Student + achievement columns
-- ---------------------------------------------------------------------
alter table public.students_profile
  add column if not exists phone              text,
  add column if not exists whatsapp           text,
  add column if not exists address            text,
  add column if not exists total_points       integer not null default 0,
  add column if not exists next_plan          text,
  add column if not exists total_progress     numeric not null default 0,
  add column if not exists total_parts_count  integer not null default 0,
  add column if not exists saved_parts_numbers integer[] not null default '{}';

alter table public.attendance add column if not exists notes text;

-- The numeric grade never matched eqraa (a named grade whose points are
-- configured per center). Replace it with the grade KEY.
alter table public.daily_achievements drop column if exists grade;
alter table public.daily_achievements
  add column grade            text,
  add column notes            text,
  add column client_ref       uuid,
  add column synced_at        timestamptz not null default now(),
  add column session_group_id uuid;

create unique index daily_achievements_client_ref_key
  on public.daily_achievements (client_ref) where client_ref is not null;
create index daily_achievements_student_created_idx
  on public.daily_achievements (student_id, created_at desc);

-- ---------------------------------------------------------------------
-- 4. Freeze points at write time + keep total_points in sync
-- ---------------------------------------------------------------------
create or replace function public.grade_points(p_org uuid, p_grade text)
returns integer language sql stable security definer set search_path = public as $$
  select coalesce(
    (select points from public.recitation_grades where organization_id = p_org and key = p_grade),
    0
  );
$$;

create or replace function public.stamp_achievement_points()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if new.points_awarded is null or new.points_awarded = 0 then
      new.points_awarded := public.grade_points(new.organization_id, new.grade);
    end if;
  elsif tg_op = 'UPDATE' then
    -- Correcting the grade of THIS record re-prices it at the current value;
    -- untouched history is never re-valued when a center changes its points.
    if new.grade is distinct from old.grade
       and new.points_awarded is not distinct from old.points_awarded then
      new.points_awarded := public.grade_points(new.organization_id, new.grade);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_stamp_achievement_points on public.daily_achievements;
create trigger trg_stamp_achievement_points
  before insert or update on public.daily_achievements
  for each row execute function public.stamp_achievement_points();

create or replace function public.sync_student_total_points()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update public.students_profile set total_points = total_points + coalesce(new.points_awarded, 0)
      where id = new.student_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.students_profile set total_points = total_points - coalesce(old.points_awarded, 0)
      where id = old.student_id;
    return old;
  elsif tg_op = 'UPDATE' then
    if new.student_id is distinct from old.student_id
       or new.points_awarded is distinct from old.points_awarded then
      update public.students_profile set total_points = total_points - coalesce(old.points_awarded, 0)
        where id = old.student_id;
      update public.students_profile set total_points = total_points + coalesce(new.points_awarded, 0)
        where id = new.student_id;
    end if;
    return new;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_sync_student_total_points on public.daily_achievements;
create trigger trg_sync_student_total_points
  after insert or update or delete on public.daily_achievements
  for each row execute function public.sync_student_total_points();

-- ---------------------------------------------------------------------
-- 5. Write access: teachers go through log_recitation() only
-- ---------------------------------------------------------------------
drop policy if exists "daily_achievements_write_staff" on public.daily_achievements;
create policy "daily_achievements_write_admin" on public.daily_achievements for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create or replace function public._assert_can_record_for_student(p_org uuid, p_student uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_circle uuid; v_teacher uuid;
begin
  if auth.uid() is null or not public.is_org_staff(p_org) then
    raise exception 'غير مصرّح لك بهذا الإجراء';
  end if;

  select sp.circle_id, c.teacher_id into v_circle, v_teacher
  from public.students_profile sp
  left join public.circles c on c.id = sp.circle_id
  where sp.id = p_student and sp.organization_id = p_org;
  if not found then
    raise exception 'الطالب غير موجود في هذا المركز';
  end if;

  if not public.is_org_admin(p_org) then
    if not public.member_has_module(p_org, 'students') then
      raise exception 'ليست لديك صلاحية على الطلاب';
    end if;
    if v_teacher is distinct from auth.uid() then
      raise exception 'هذا الطالب ليس ضمن حلقتك';
    end if;
  end if;
  return v_circle;
end;
$$;

create or replace function public.log_recitation(
  p_org              uuid,
  p_student_id       uuid,
  p_type             text,
  p_surah            integer,
  p_ayah_from        integer,
  p_ayah_to          integer,
  p_grade            text,
  p_notes            text        default null,
  p_client_ref       uuid        default null,
  p_recorded_at      timestamptz default null,
  p_session_group_id uuid        default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_circle    uuid;
  v_recorded  timestamptz;
  v_days      integer;
  v_tz        text;
  v_existing  record;
  v_id        uuid;
  v_points    integer;
  v_total     integer;
begin
  v_circle := public._assert_can_record_for_student(p_org, p_student_id);

  if p_client_ref is not null then
    select id, points_awarded into v_existing
    from public.daily_achievements where client_ref = p_client_ref and organization_id = p_org;
    if found then
      select total_points into v_total from public.students_profile where id = p_student_id;
      return jsonb_build_object('achievement_id', v_existing.id,
        'points_awarded', coalesce(v_existing.points_awarded, 0),
        'new_total_points', v_total, 'was_duplicate', true);
    end if;
  end if;

  if p_type not in ('new_memorization', 'recent_review', 'distant_review') then
    raise exception 'نوع الإنجاز غير صالح';
  end if;

  if not exists (
    select 1 from public.recitation_grades
    where organization_id = p_org and key = p_grade and is_active
  ) then
    raise exception 'تقدير غير معروف في هذا المركز';
  end if;

  perform public.validate_ayah_range(p_surah, p_ayah_from, p_ayah_to);

  v_days := coalesce(nullif(public.org_setting(p_org, 'backdate_days', '60'), '')::integer, 60);
  v_recorded := coalesce(p_recorded_at, now());
  if v_recorded > now() + interval '1 hour' or v_recorded < now() - make_interval(days => v_days) then
    v_recorded := now();
  end if;

  insert into public.daily_achievements (
    organization_id, student_id, circle_id, achievement_type,
    surah_from, ayah_from, surah_to, ayah_to,
    grade, notes, client_ref, recorded_by, created_at, session_group_id
  ) values (
    p_org, p_student_id, v_circle, p_type::public.achievement_type,
    p_surah, p_ayah_from, p_surah, p_ayah_to,
    p_grade, nullif(trim(p_notes), ''), p_client_ref, auth.uid(), v_recorded, p_session_group_id
  ) returning id, points_awarded into v_id, v_points;

  -- A recitation counts as attendance for that day (never overwrites a mark
  -- the teacher already made).
  select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = p_org;
  insert into public.attendance (organization_id, student_id, circle_id, session_date, status, recorded_by)
  values (p_org, p_student_id, v_circle, (v_recorded at time zone v_tz)::date, 'present', auth.uid())
  on conflict (student_id, session_date) do nothing;

  select total_points into v_total from public.students_profile where id = p_student_id;
  return jsonb_build_object('achievement_id', v_id, 'points_awarded', coalesce(v_points, 0),
    'new_total_points', v_total, 'was_duplicate', false);
end;
$$;

create or replace function public.update_recitation(
  p_id uuid, p_type text, p_surah integer, p_ayah_from integer, p_ayah_to integer,
  p_grade text, p_notes text default null
) returns void language plpgsql security definer set search_path = public as $$
declare v_row record;
begin
  select id, organization_id, student_id into v_row from public.daily_achievements where id = p_id;
  if not found then raise exception 'السجل غير موجود'; end if;
  perform public._assert_can_record_for_student(v_row.organization_id, v_row.student_id);

  if p_type not in ('new_memorization', 'recent_review', 'distant_review') then
    raise exception 'نوع الإنجاز غير صالح';
  end if;
  if not exists (select 1 from public.recitation_grades
                 where organization_id = v_row.organization_id and key = p_grade and is_active) then
    raise exception 'تقدير غير معروف في هذا المركز';
  end if;
  perform public.validate_ayah_range(p_surah, p_ayah_from, p_ayah_to);

  update public.daily_achievements set
    achievement_type = p_type::public.achievement_type,
    surah_from = p_surah, surah_to = p_surah,
    ayah_from = p_ayah_from, ayah_to = p_ayah_to,
    grade = p_grade, notes = nullif(trim(p_notes), '')
  where id = p_id;
end;
$$;

revoke all on function public.log_recitation(uuid, uuid, text, integer, integer, integer, text, text, uuid, timestamptz, uuid) from public, anon;
grant execute on function public.log_recitation(uuid, uuid, text, integer, integer, integer, text, text, uuid, timestamptz, uuid) to authenticated;
revoke all on function public.update_recitation(uuid, text, integer, integer, integer, text, text) from public, anon;
grant execute on function public.update_recitation(uuid, text, integer, integer, integer, text, text) to authenticated;
revoke all on function public._assert_can_record_for_student(uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 6. Attendance measured on WORKING days (not on days a sheet was opened)
-- ---------------------------------------------------------------------
create or replace function public.working_days_between(p_org uuid, p_from date, p_to date)
returns integer language sql stable security definer set search_path = public as $$
  select count(*)::integer
  from generate_series(p_from, p_to, interval '1 day') d
  join public.center_weekdays w
    on w.organization_id = p_org and w.dow = extract(dow from d)::smallint
  where w.is_working;
$$;

create or replace function public.attendance_rate(p_org uuid, p_student uuid, p_from date, p_to date)
returns numeric language plpgsql stable security definer set search_path = public as $$
declare v_working integer; v_present integer;
begin
  if p_student <> all (public.linked_student_ids(p_org)) and not public.is_org_staff(p_org) then
    raise exception 'غير مصرّح';
  end if;
  v_working := public.working_days_between(p_org, p_from, p_to);
  if v_working = 0 then return null; end if;
  select count(*) into v_present from public.attendance a
   where a.student_id = p_student and a.session_date between p_from and p_to
     and a.status in ('present', 'late');
  return round(least(v_present, v_working)::numeric * 100 / v_working, 1);
end;
$$;

-- ---------------------------------------------------------------------
-- 7. Student home in ONE call (eqraa: get_student_dashboard)
-- ---------------------------------------------------------------------
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
  if not (v_student = any (public.linked_student_ids(p_org))) and not public.is_org_staff(p_org) then
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

grant execute on function public.get_student_dashboard(uuid, uuid) to authenticated;
grant execute on function public.attendance_rate(uuid, uuid, date, date) to authenticated;
grant execute on function public.org_setting(uuid, text, text) to authenticated;

notify pgrst, 'reload schema';
