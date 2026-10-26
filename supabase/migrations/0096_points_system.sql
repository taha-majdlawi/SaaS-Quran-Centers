-- 0096: the points system (from the Iqra spec), per center.
--
--   1. Scoring a recitation by PAGES - a per-center choice (setting points_mode):
--        per_recitation (default, unchanged): every recitation is worth its grade's points;
--        per_page: points = max(1, round(pages x grade points x type factor)), where the grade's
--                  points are "per page", memorization counts 1 and review 0.5, and pages are
--                  the share of every mushaf page the ayah range touches (Madinah mushaf, 604).
--      Each recitation still freezes its points when it is written; changing the mode or the
--      values only affects what is recorded afterwards.
--   2. point_adjustments - one ledger for every point that is neither a recitation nor serd:
--        attendance (per status, from a start date the admin picks), teacher bonus / penalty
--        for a reason from the center's list, and one opening balance per student.
--      total_points = recitations + approved serd + this ledger, kept by triggers.
--   3. get_student_points_breakdown - "how did I earn my points": every point explained, and
--      the rows always add up to the total (recompute_all_points repairs a drifted total).

-- ---------------------------------------------------------------------
-- 1. Pages of a recitation
-- ---------------------------------------------------------------------
-- How many pages the ayahs a..b (absolute ids, 1..6236) cover: each page they touch counts by
-- the share of its ayahs inside the range. Al-Fatiha = 1.0, Al-Ikhlas ~ 0.27, the mushaf = 604.
create or replace function public.ayah_range_pages(p_a integer, p_b integer)
returns numeric language sql stable security definer set search_path = public as $$
  with pg as (
    select page, first_ayah_id as f,
           coalesce(lead(first_ayah_id) over (order by page) - 1, 6236) as l
    from public.quran_pages
  )
  select coalesce(sum((least(p_b, l) - greatest(p_a, f) + 1)::numeric / (l - f + 1)), 0)
  from pg where p_a is not null and p_b is not null and l >= p_a and f <= p_b;
$$;

create or replace function public.recitation_pages(p_surah_from integer, p_ayah_from integer,
  p_surah_to integer default null, p_ayah_to integer default null)
returns numeric language plpgsql stable security definer set search_path = public as $$
declare v_a integer; v_b integer;
begin
  if p_surah_from is null or p_ayah_from is null then return null; end if;
  v_a := public._ayah_id(p_surah_from, p_ayah_from);
  v_b := public._ayah_id(coalesce(p_surah_to, p_surah_from), coalesce(p_ayah_to, p_ayah_from));
  if v_a is null or v_b is null then return null; end if;
  if v_b < v_a then return public.ayah_range_pages(v_b, v_a); end if;
  return public.ayah_range_pages(v_a, v_b);
end;
$$;
revoke all on function public.ayah_range_pages(integer, integer) from public, anon;
revoke all on function public.recitation_pages(integer, integer, integer, integer) from public, anon;
grant execute on function public.ayah_range_pages(integer, integer) to authenticated;
grant execute on function public.recitation_pages(integer, integer, integer, integer) to authenticated;

-- ---------------------------------------------------------------------
-- 2. The center's scoring mode, and the points of one recitation
-- ---------------------------------------------------------------------
create or replace function public.points_mode(p_org uuid)
returns text language sql stable security definer set search_path = public as $$
  select case when public.org_setting(p_org, 'points_mode', 'per_recitation') = 'per_page'
              then 'per_page' else 'per_recitation' end;
$$;
grant execute on function public.points_mode(uuid) to authenticated;

create or replace function public.compute_recitation_points(p_org uuid, p_type text, p_grade text,
  p_surah_from integer, p_ayah_from integer, p_surah_to integer default null, p_ayah_to integer default null)
returns integer language plpgsql stable security definer set search_path = public as $$
declare v_gp integer; v_factor numeric; v_pages numeric;
begin
  v_gp := public.grade_points(p_org, p_grade);
  if public.points_mode(p_org) <> 'per_page' then return v_gp; end if;
  if v_gp <= 0 then return 0; end if;
  v_factor := case when p_type = 'new_memorization' then 1 else 0.5 end;
  v_pages := public.recitation_pages(p_surah_from, p_ayah_from, p_surah_to, p_ayah_to);
  if v_pages is null then return greatest(1, round(v_gp * v_factor))::integer; end if;
  return greatest(1, round(v_pages * v_gp * v_factor))::integer;
end;
$$;
revoke all on function public.compute_recitation_points(uuid, text, text, integer, integer, integer, integer) from public, anon;
grant execute on function public.compute_recitation_points(uuid, text, text, integer, integer, integer, integer) to authenticated;

-- Freeze the points when a recitation is written. Editing THIS record re-prices it when what the
-- price depends on changed (the grade; in per-page mode also the type and the ayahs) and no new
-- points were given; other edits (a note, the date) never touch them, nor does a change of the
-- center's values touch untouched history.
create or replace function public.stamp_achievement_points()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if new.points_awarded is null or new.points_awarded = 0 then
      new.points_awarded := public.compute_recitation_points(new.organization_id, new.achievement_type::text,
        new.grade, new.surah_from, new.ayah_from, new.surah_to, new.ayah_to);
    end if;
  elsif tg_op = 'UPDATE' then
    if new.points_awarded is not distinct from old.points_awarded and (
         new.grade is distinct from old.grade
         or (public.points_mode(new.organization_id) = 'per_page' and (
               new.achievement_type is distinct from old.achievement_type
               or new.surah_from is distinct from old.surah_from or new.ayah_from is distinct from old.ayah_from
               or new.surah_to is distinct from old.surah_to or new.ayah_to is distinct from old.ayah_to))) then
      new.points_awarded := public.compute_recitation_points(new.organization_id, new.achievement_type::text,
        new.grade, new.surah_from, new.ayah_from, new.surah_to, new.ayah_to);
    end if;
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 3. Reasons for a teacher's bonus / penalty, and attendance values
-- ---------------------------------------------------------------------
create table if not exists public.point_reasons (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  name            text not null check (char_length(btrim(name)) between 1 and 60),
  points          integer not null check (points between 1 and 100),
  kind            text not null check (kind in ('bonus', 'penalty')),
  is_active       boolean not null default true,
  sort_order      integer not null default 0,
  created_at      timestamptz not null default now()
);
create index if not exists point_reasons_org_idx on public.point_reasons (organization_id, kind, sort_order);
alter table public.point_reasons enable row level security;
revoke all on public.point_reasons from anon, authenticated;
grant select on public.point_reasons to authenticated;
drop policy if exists "point_reasons_select_member" on public.point_reasons;
create policy "point_reasons_select_member" on public.point_reasons for select
  using (public.is_org_member(organization_id));

create table if not exists public.attendance_point_values (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  status          public.attendance_status not null,
  points          integer not null default 0 check (points between -100 and 100),
  primary key (organization_id, status)
);
alter table public.attendance_point_values enable row level security;
revoke all on public.attendance_point_values from anon, authenticated;
grant select on public.attendance_point_values to authenticated;
drop policy if exists "attendance_point_values_select_member" on public.attendance_point_values;
create policy "attendance_point_values_select_member" on public.attendance_point_values for select
  using (public.is_org_member(organization_id));

-- Defaults (the spec's): every center starts with them and edits them afterwards.
create or replace function public.seed_point_defaults(p_org uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.attendance_point_values (organization_id, status, points) values
    (p_org, 'present', 1), (p_org, 'absent', -1), (p_org, 'late', 0), (p_org, 'excused', 0)
  on conflict do nothing;
  if not exists (select 1 from public.point_reasons where organization_id = p_org) then
    insert into public.point_reasons (organization_id, name, points, kind, sort_order) values
      (p_org, 'الالتزام',             3, 'bonus',   1),
      (p_org, 'الأدب وحسن الخلق',     3, 'bonus',   2),
      (p_org, 'المشاركة والتفاعل',    2, 'bonus',   3),
      (p_org, 'مساعدة الزملاء',       2, 'bonus',   4),
      (p_org, 'المشاغبة',             2, 'penalty', 1),
      (p_org, 'المشاجرة',             5, 'penalty', 2),
      (p_org, 'عدم التسميع',          2, 'penalty', 3);
  end if;
end;
$$;
revoke all on function public.seed_point_defaults(uuid) from public, anon, authenticated;

create or replace function public.trg_seed_point_defaults()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.seed_point_defaults(new.id);
  return new;
end;
$$;
drop trigger if exists organizations_seed_point_defaults on public.organizations;
create trigger organizations_seed_point_defaults
  after insert on public.organizations
  for each row execute function public.trg_seed_point_defaults();

do $$
declare r record;
begin
  for r in select id from public.organizations loop
    perform public.seed_point_defaults(r.id);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 4. The ledger
-- ---------------------------------------------------------------------
create table if not exists public.point_adjustments (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  student_id      uuid not null references public.students_profile (id) on delete cascade,
  source          text not null check (source in ('attendance', 'bonus', 'penalty', 'opening')),
  points          integer not null check (points between -100000 and 100000),
  attendance_id   uuid unique references public.attendance (id) on delete cascade,
  reason_id       uuid references public.point_reasons (id) on delete set null,
  reason_label    text,
  note            text check (note is null or char_length(note) <= 500),
  awarded_by      uuid references auth.users (id) on delete set null,
  occurred_on     date not null default current_date,
  client_ref      uuid unique,
  created_at      timestamptz not null default now(),
  check ((source = 'bonus' and points > 0) or (source = 'penalty' and points < 0)
         or source in ('attendance', 'opening')),
  check ((source = 'attendance') = (attendance_id is not null))
);
create unique index if not exists point_adjustments_one_opening
  on public.point_adjustments (student_id) where source = 'opening';
create index if not exists point_adjustments_student_idx on public.point_adjustments (student_id, occurred_on desc);
create index if not exists point_adjustments_org_idx on public.point_adjustments (organization_id, occurred_on);
create index if not exists point_adjustments_reason_idx on public.point_adjustments (reason_id);
create index if not exists point_adjustments_awarded_by_idx on public.point_adjustments (awarded_by);

alter table public.point_adjustments enable row level security;
revoke all on public.point_adjustments from anon, authenticated;
grant select on public.point_adjustments to authenticated;
drop policy if exists "point_adjustments_select_viewer" on public.point_adjustments;
create policy "point_adjustments_select_viewer" on public.point_adjustments for select
  using (public._can_view_student(organization_id, student_id));

-- keeps students_profile.total_points in step (by the difference)
create or replace function public.sync_adjustment_total_points()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    update public.students_profile set total_points = coalesce(total_points, 0) - old.points where id = old.student_id;
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    update public.students_profile set total_points = coalesce(total_points, 0) + new.points where id = new.student_id;
  end if;
  return null;
end;
$$;
drop trigger if exists trg_sync_adjustment_total_points on public.point_adjustments;
create trigger trg_sync_adjustment_total_points
  after insert or update of points, student_id or delete on public.point_adjustments
  for each row execute function public.sync_adjustment_total_points();

-- ---------------------------------------------------------------------
-- 5. Attendance points
-- ---------------------------------------------------------------------
-- The day attendance starts to count (setting attendance_points_from); empty = not counted.
create or replace function public.attendance_points_from(p_org uuid)
returns date language plpgsql stable security definer set search_path = public as $$
declare v text := public.org_setting(p_org, 'attendance_points_from', '');
begin
  if v ~ '^\d{4}-\d{2}-\d{2}$' then return v::date; end if;
  return null;
end;
$$;
grant execute on function public.attendance_points_from(uuid) to authenticated;

-- Recording (or correcting) a day writes that day's points; a correction replaces them, it never
-- adds on top. Deleting the day deletes them (the foreign key). A note edit changes nothing.
create or replace function public.sync_attendance_points()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_from date; v_points integer;
begin
  if tg_op = 'UPDATE' and new.status = old.status and new.student_id = old.student_id
     and new.session_date = old.session_date then
    return null;
  end if;
  v_from := public.attendance_points_from(new.organization_id);
  if v_from is not null and new.session_date >= v_from then
    select points into v_points from public.attendance_point_values
      where organization_id = new.organization_id and status = new.status;
  end if;
  if coalesce(v_points, 0) = 0 then
    delete from public.point_adjustments where attendance_id = new.id;
  else
    insert into public.point_adjustments (organization_id, student_id, source, points, attendance_id, awarded_by, occurred_on)
    values (new.organization_id, new.student_id, 'attendance', v_points, new.id, new.recorded_by, new.session_date)
    on conflict (attendance_id) do update
      set points = excluded.points, student_id = excluded.student_id, occurred_on = excluded.occurred_on;
  end if;
  return null;
end;
$$;
drop trigger if exists trg_sync_attendance_points on public.attendance;
create trigger trg_sync_attendance_points
  after insert or update on public.attendance
  for each row execute function public.sync_attendance_points();

-- The admin sets the value of each status and the day to start from (null = stop counting).
-- Days already counted keep their points; days before the new start date lose them, and days
-- from it that were not counted yet are counted now at the current values.
create or replace function public.set_attendance_points(p_org uuid, p_present integer, p_absent integer,
  p_late integer, p_excused integer, p_from date)
returns integer language plpgsql security definer set search_path = public as $$
declare v_old date; v_count integer := 0;
begin
  perform public._assert_can_write(p_org);
  if not public.is_org_admin(p_org) then raise exception 'للمشرف فقط' using errcode = '42501'; end if;
  if least(p_present, p_absent, p_late, p_excused) < -100 or greatest(p_present, p_absent, p_late, p_excused) > 100
     or p_present is null or p_absent is null or p_late is null or p_excused is null then
    raise exception 'نقاط الحضور بين -100 و100';
  end if;
  v_old := public.attendance_points_from(p_org);

  insert into public.attendance_point_values (organization_id, status, points) values
    (p_org, 'present', p_present), (p_org, 'absent', p_absent), (p_org, 'late', p_late), (p_org, 'excused', p_excused)
  on conflict (organization_id, status) do update set points = excluded.points;
  insert into public.organization_settings (organization_id, key, value)
  values (p_org, 'attendance_points_from', coalesce(p_from::text, ''))
  on conflict (organization_id, key) do update set value = excluded.value;

  if p_from is null then
    delete from public.point_adjustments where organization_id = p_org and source = 'attendance';
  else
    delete from public.point_adjustments pa using public.attendance a
     where pa.attendance_id = a.id and pa.organization_id = p_org and a.session_date < p_from;
    insert into public.point_adjustments (organization_id, student_id, source, points, attendance_id, awarded_by, occurred_on)
    select a.organization_id, a.student_id, 'attendance', v.points, a.id, a.recorded_by, a.session_date
      from public.attendance a
      join public.attendance_point_values v on v.organization_id = a.organization_id and v.status = a.status
     where a.organization_id = p_org and a.session_date >= p_from and v.points <> 0
    on conflict (attendance_id) do nothing;
    get diagnostics v_count = row_count;
  end if;

  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'attendance_point_values', null, jsonb_build_object(
    'present', p_present, 'absent', p_absent, 'late', p_late, 'excused', p_excused, 'from', p_from, 'old_from', v_old));
  return v_count;
end;
$$;
revoke all on function public.set_attendance_points(uuid, integer, integer, integer, integer, date) from public, anon;
grant execute on function public.set_attendance_points(uuid, integer, integer, integer, integer, date) to authenticated;

-- ---------------------------------------------------------------------
-- 6. Settings the admin changes: the mode, the reasons
-- ---------------------------------------------------------------------
create or replace function public.set_points_mode(p_org uuid, p_mode text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_can_write(p_org);
  if not public.is_org_admin(p_org) then raise exception 'للمشرف فقط' using errcode = '42501'; end if;
  if p_mode not in ('per_recitation', 'per_page') then raise exception 'طريقة احتساب غير معروفة'; end if;
  insert into public.organization_settings (organization_id, key, value) values (p_org, 'points_mode', p_mode)
  on conflict (organization_id, key) do update set value = excluded.value;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'organization_settings', null, jsonb_build_object('points_mode', p_mode));
end;
$$;
revoke all on function public.set_points_mode(uuid, text) from public, anon;
grant execute on function public.set_points_mode(uuid, text) to authenticated;

-- Add (p_id null) or change a reason. Past entries keep the name and points they were given.
create or replace function public.save_point_reason(p_org uuid, p_id uuid, p_name text, p_points integer,
  p_kind text, p_active boolean default true, p_sort integer default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_name text := btrim(coalesce(p_name, ''));
begin
  perform public._assert_can_write(p_org);
  if not public.is_org_admin(p_org) then raise exception 'للمشرف فقط' using errcode = '42501'; end if;
  if char_length(v_name) not between 1 and 60 then raise exception 'اسم السبب مطلوب (حتى 60 حرفاً)'; end if;
  if p_points is null or p_points not between 1 and 100 then raise exception 'النقاط بين 1 و100'; end if;
  if p_kind not in ('bonus', 'penalty') then raise exception 'نوع غير معروف'; end if;
  if p_id is null then
    insert into public.point_reasons (organization_id, name, points, kind, is_active, sort_order)
    values (p_org, v_name, p_points, p_kind, coalesce(p_active, true),
            coalesce(p_sort, (select coalesce(max(sort_order), 0) + 1 from public.point_reasons
                              where organization_id = p_org and kind = p_kind)))
    returning id into v_id;
  else
    update public.point_reasons
       set name = v_name, points = p_points, kind = p_kind, is_active = coalesce(p_active, is_active),
           sort_order = coalesce(p_sort, sort_order)
     where id = p_id and organization_id = p_org
    returning id into v_id;
    if v_id is null then raise exception 'السبب غير موجود'; end if;
  end if;
  return v_id;
end;
$$;
revoke all on function public.save_point_reason(uuid, uuid, text, integer, text, boolean, integer) from public, anon;
grant execute on function public.save_point_reason(uuid, uuid, text, integer, text, boolean, integer) to authenticated;

create or replace function public.delete_point_reason(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_can_write(p_org);
  if not public.is_org_admin(p_org) then raise exception 'للمشرف فقط' using errcode = '42501'; end if;
  delete from public.point_reasons where id = p_id and organization_id = p_org;
end;
$$;
revoke all on function public.delete_point_reason(uuid, uuid) from public, anon;
grant execute on function public.delete_point_reason(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 7. A teacher's bonus / penalty
-- ---------------------------------------------------------------------
-- The teacher picks a reason, never a number: the value and its sign come from the reason.
-- client_ref makes a retry from the app's offline queue a success, not a second entry.
create or replace function public.teacher_award_points(p_org uuid, p_student uuid, p_reason uuid,
  p_note text default null, p_date date default null, p_client_ref uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare r public.point_reasons; v_existing record; v_id uuid; v_points integer; v_date date; v_days integer;
  v_total integer;
begin
  perform public._assert_can_write(p_org);
  if p_client_ref is not null then
    select id, points into v_existing from public.point_adjustments
     where client_ref = p_client_ref and organization_id = p_org;
    if found then
      select total_points into v_total from public.students_profile where id = p_student;
      return jsonb_build_object('id', v_existing.id, 'points', v_existing.points,
        'new_total_points', v_total, 'was_duplicate', true);
    end if;
  end if;
  perform public._assert_can_record_for_student(p_org, p_student);

  select * into r from public.point_reasons where id = p_reason and organization_id = p_org and is_active;
  if not found then raise exception 'السبب غير موجود أو غير مفعّل'; end if;
  if p_note is not null and char_length(p_note) > 500 then raise exception 'الملاحظة طويلة'; end if;

  v_days := coalesce(nullif(public.org_setting(p_org, 'backdate_days', '60'), '')::integer, 60);
  v_date := coalesce(p_date, current_date);
  if v_date > current_date + 1 or v_date < current_date - v_days then v_date := current_date; end if;

  v_points := case when r.kind = 'bonus' then r.points else -r.points end;
  insert into public.point_adjustments (organization_id, student_id, source, points, reason_id, reason_label,
    note, awarded_by, occurred_on, client_ref)
  values (p_org, p_student, r.kind, v_points, r.id, r.name, nullif(btrim(coalesce(p_note, '')), ''),
    auth.uid(), v_date, p_client_ref)
  returning id into v_id;

  select total_points into v_total from public.students_profile where id = p_student;
  return jsonb_build_object('id', v_id, 'points', v_points, 'new_total_points', v_total, 'was_duplicate', false);
end;
$$;
revoke all on function public.teacher_award_points(uuid, uuid, uuid, text, date, uuid) from public, anon;
grant execute on function public.teacher_award_points(uuid, uuid, uuid, text, date, uuid) to authenticated;

-- Undo an entry: the teacher their own bonus / penalty within two days; the admin any bonus,
-- penalty or opening balance. Attendance points follow the attendance record, not this.
create or replace function public.delete_point_adjustment(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare a public.point_adjustments;
begin
  perform public._assert_can_write(p_org);
  select * into a from public.point_adjustments where id = p_id and organization_id = p_org;
  if not found then raise exception 'السجل غير موجود'; end if;
  if a.source = 'attendance' then raise exception 'نقاط الحضور تتبع سجل الحضور — عدّل الحضور نفسه'; end if;
  if not public.is_org_admin(p_org) then
    if a.source = 'opening' or a.awarded_by is distinct from auth.uid() or a.created_at < now() - interval '2 days' then
      raise exception 'يمكنك حذف ما سجّلته بنفسك خلال يومين فقط — بعدها اطلب من المشرف' using errcode = '42501';
    end if;
    perform public._assert_can_record_for_student(p_org, a.student_id);
  end if;
  delete from public.point_adjustments where id = p_id;
end;
$$;
revoke all on function public.delete_point_adjustment(uuid, uuid) from public, anon;
grant execute on function public.delete_point_adjustment(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 8. Opening balance (points a student brings from before Bustan)
-- ---------------------------------------------------------------------
-- One per student; setting it again replaces it, 0 removes it.
create or replace function public.set_opening_balance(p_org uuid, p_student uuid, p_points integer, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_can_write(p_org);
  if not public.is_org_admin(p_org) then raise exception 'للمشرف فقط' using errcode = '42501'; end if;
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then
    raise exception 'الطالب غير موجود';
  end if;
  if p_points is not null and p_points not between -100000 and 100000 then raise exception 'رقم غير صالح'; end if;
  if coalesce(p_points, 0) = 0 then
    delete from public.point_adjustments where student_id = p_student and source = 'opening';
    return;
  end if;
  insert into public.point_adjustments (organization_id, student_id, source, points, note, awarded_by)
  values (p_org, p_student, 'opening', p_points, nullif(btrim(coalesce(p_note, '')), ''), auth.uid())
  on conflict (student_id) where source = 'opening'
  do update set points = excluded.points, note = excluded.note, awarded_by = excluded.awarded_by, created_at = now();
end;
$$;
revoke all on function public.set_opening_balance(uuid, uuid, integer, text) from public, anon;
grant execute on function public.set_opening_balance(uuid, uuid, integer, text) to authenticated;

-- ---------------------------------------------------------------------
-- 9. "How did I earn my points"
-- ---------------------------------------------------------------------
-- Read by the admin, the student's teacher (and whoever may view the student), the student and
-- their guardian. Recitations are grouped by type x grade, bonus / penalty by reason.
create or replace function public.get_student_points_breakdown(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_total integer; v_rows jsonb; v_summary jsonb; v_recent jsonb; v_admin boolean;
begin
  if not public._can_view_student(p_org, p_student) then
    raise exception 'غير مصرّح لك بهذا الإجراء' using errcode = '42501';
  end if;
  v_admin := public.is_org_admin(p_org);
  select coalesce(total_points, 0) into v_total from public.students_profile where id = p_student;

  with rec as (
    select d.achievement_type::text as type, d.grade, count(*)::integer as cnt,
           sum(coalesce(public.recitation_pages(d.surah_from, d.ayah_from, d.surah_to, d.ayah_to), 0)) as pages,
           sum(coalesce(d.points_awarded, 0))::integer as pts
      from public.daily_achievements d
     where d.student_id = p_student
     group by d.achievement_type, d.grade
  ), rows as (
    select 1 as ord, jsonb_build_object('kind', 'opening', 'count', 1, 'points', a.points, 'note', a.note) as j, 0 as sub
      from public.point_adjustments a where a.student_id = p_student and a.source = 'opening'
    union all
    select 2, jsonb_build_object('kind', 'recitation', 'type', r.type, 'grade', r.grade,
             'label', coalesce(g.label, r.grade), 'count', r.cnt, 'pages', round(r.pages, 2), 'points', r.pts),
           case r.type when 'new_memorization' then 0 when 'recent_review' then 100 else 200 end + coalesce(g.sort_order, 99)
      from rec r left join public.recitation_grades g on g.organization_id = p_org and g.key = r.grade
    union all
    select 3, jsonb_build_object('kind', 'serd', 'count', count(*), 'points', sum(coalesce(s.points_awarded, 0))), 0
      from public.serd_sessions s where s.student_id = p_student and s.status = 'approved'
      having count(*) > 0
    union all
    select 4, jsonb_build_object('kind', 'attendance', 'count', count(*), 'points', sum(a.points)), 0
      from public.point_adjustments a where a.student_id = p_student and a.source = 'attendance'
      having count(*) > 0
    union all
    select case a.source when 'bonus' then 5 else 6 end,
           jsonb_build_object('kind', a.source, 'label', coalesce(a.reason_label, ''), 'count', count(*), 'points', sum(a.points)),
           -abs(sum(a.points))::integer
      from public.point_adjustments a where a.student_id = p_student and a.source in ('bonus', 'penalty')
      group by a.source, a.reason_label
  )
  select coalesce(jsonb_agg(j order by ord, sub), '[]'::jsonb) into v_rows from rows;

  select jsonb_build_object(
    'recitations', (select count(*) from public.daily_achievements where student_id = p_student),
    'memorized_pages', round(coalesce((select sum(public.recitation_pages(surah_from, ayah_from, surah_to, ayah_to))
        from public.daily_achievements where student_id = p_student and achievement_type = 'new_memorization'), 0), 2),
    'revision_pages', round(coalesce((select sum(public.recitation_pages(surah_from, ayah_from, surah_to, ayah_to))
        from public.daily_achievements where student_id = p_student and achievement_type <> 'new_memorization'), 0), 2),
    'attended_days', (select count(*) from public.attendance where student_id = p_student and status in ('present', 'late')),
    'absent_days', (select count(*) from public.attendance where student_id = p_student and status = 'absent'),
    'serd_sessions', (select count(*) from public.serd_sessions where student_id = p_student and status = 'approved')
  ) into v_summary;

  -- the latest bonus / penalty / opening entries, with whether the caller may undo them
  select coalesce(jsonb_agg(x order by x->>'created_at' desc), '[]'::jsonb) into v_recent from (
    select jsonb_build_object('id', a.id, 'source', a.source, 'points', a.points, 'label', a.reason_label,
             'note', a.note, 'occurred_on', a.occurred_on, 'created_at', a.created_at,
             'by', (select p.full_name from public.profiles p where p.id = a.awarded_by),
             'can_delete', not public._account_read_only(p_org) and not public._org_locked(p_org) and (v_admin or (a.source <> 'opening' and a.awarded_by = auth.uid()
                                         and a.created_at >= now() - interval '2 days'))) as x
      from public.point_adjustments a
     where a.student_id = p_student and a.source <> 'attendance'
     order by a.created_at desc limit 30
  ) t;

  return jsonb_build_object(
    'mode', public.points_mode(p_org),
    'total_points', v_total,
    'rows_sum', coalesce((select sum((j->>'points')::integer) from jsonb_array_elements(v_rows) j), 0),
    'summary', v_summary,
    'rows', v_rows,
    'recent', v_recent);
end;
$$;
revoke all on function public.get_student_points_breakdown(uuid, uuid) from public, anon;
grant execute on function public.get_student_points_breakdown(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 10. Repair: add every student's total up again from the frozen values (nothing is re-priced)
-- ---------------------------------------------------------------------
create or replace function public.recompute_all_points(p_org uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare v_count integer;
begin
  perform public._assert_can_write(p_org);
  if not public.is_org_admin(p_org) then raise exception 'للمشرف فقط' using errcode = '42501'; end if;
  with t as (
    select sp.id,
      coalesce((select sum(points_awarded) from public.daily_achievements where student_id = sp.id), 0)
      + coalesce((select sum(points_awarded) from public.serd_sessions where student_id = sp.id and status = 'approved'), 0)
      + coalesce((select sum(points) from public.point_adjustments where student_id = sp.id), 0) as total
    from public.students_profile sp where sp.organization_id = p_org
  )
  update public.students_profile sp set total_points = t.total
    from t where sp.id = t.id and sp.total_points is distinct from t.total;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function public.recompute_all_points(uuid) from public, anon;
grant execute on function public.recompute_all_points(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 11. Locks: a viewing account / a locked center writes nothing (the tables are RPC-only anyway),
--     and the helpers are not for visitors
-- ---------------------------------------------------------------------
drop trigger if exists a_deny_readonly_write on public.point_reasons;
create trigger a_deny_readonly_write before insert or update or delete on public.point_reasons
  for each row execute function public._deny_readonly_write();
drop trigger if exists a_deny_readonly_write on public.attendance_point_values;
create trigger a_deny_readonly_write before insert or update or delete on public.attendance_point_values
  for each row execute function public._deny_readonly_write();
drop trigger if exists a_deny_readonly_write on public.point_adjustments;
create trigger a_deny_readonly_write before insert or update or delete on public.point_adjustments
  for each row execute function public._deny_readonly_write();

revoke all on function public.points_mode(uuid) from public, anon;
grant execute on function public.points_mode(uuid) to authenticated;
revoke all on function public.attendance_points_from(uuid) from public, anon;
grant execute on function public.attendance_points_from(uuid) to authenticated;
revoke all on function public.trg_seed_point_defaults() from public, anon, authenticated;
revoke all on function public.sync_adjustment_total_points() from public, anon, authenticated;
revoke all on function public.sync_attendance_points() from public, anon, authenticated;

notify pgrst, 'reload schema';
