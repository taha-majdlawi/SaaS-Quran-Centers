-- =========================================================================
-- 0020_calendar_core.sql
-- تقويم المركز - holidays, closures, events, registration with seats, waiting
-- list, guardian consent and results. Rebuilt to match the eqraa design, but
-- per center:
--
--   * ONE table for holidays and events: they are the same row with a
--     different answer to "was the center open" (is_working_day). That flag
--     feeds the attendance denominator (center_working_days), so a holiday
--     stops counting against every student's attendance %.
--   * Entry TYPES are a per-center catalogue the admin edits (holiday, trip,
--     competition, ...), each deciding whether it is a working day by default,
--     whether students can register, and whether a guardian must consent.
--     The entry keeps a COPY of the type's key / working-day flag, so editing
--     or deleting a type never rewrites history or attendance.
--   * audience is role + circle + stage, evaluated in ONE function
--     (_calendar_visible) that the policies and the reads all call.
--   * registration goes through guarded RPCs only (seats locked per entry, so
--     two people cannot take the last seat; waiting list with auto-promotion).
--   * guardian consent: a per-registration token; the public link is answered
--     through a server route holding the service key (anon has no access).
--   * scheduled serd shows on the calendar (read from serd_sessions, not
--     copied), and the weekly serd days are marked.
--
-- The earlier simplified tables (0006) held no production data and are
-- replaced. `activities` is a separate module and is untouched.
-- =========================================================================

drop table if exists public.calendar_waitlist cascade;
drop table if exists public.calendar_registrations cascade;
drop table if exists public.center_calendar cascade;
drop table if exists public.calendar_entry_types cascade;

-- ---------------------------------------------------------------------
-- 1. Types (per-center catalogue)
-- ---------------------------------------------------------------------
create table public.calendar_entry_types (
  id                        uuid primary key default gen_random_uuid(),
  organization_id           uuid not null references public.organizations (id) on delete cascade,
  key                       text not null,
  name                      text not null,
  default_is_working        boolean not null default true,
  color                     text not null default '#64748b',
  sort_order                integer not null default 0,
  is_active                 boolean not null default true,
  supports_registration     boolean not null default false,
  requires_guardian_consent boolean not null default false,
  created_at                timestamptz not null default now(),
  unique (organization_id, key)
);

create or replace function public.seed_calendar_defaults(p_org uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.calendar_entry_types where organization_id = p_org) then return; end if;
  insert into public.calendar_entry_types
    (organization_id, key, name, default_is_working, color, sort_order, supports_registration, requires_guardian_consent) values
    (p_org, 'holiday',     'إجازة',        false, '#ef4444', 1, false, false),
    (p_org, 'closure',     'إغلاق طارئ',   false, '#f97316', 2, false, false),
    (p_org, 'event',       'فعالية',        true,  '#3b82f6', 3, true,  false),
    (p_org, 'trip',        'رحلة',          true,  '#14b8a6', 4, true,  true),
    (p_org, 'competition', 'مسابقة',        true,  '#a855f7', 5, true,  false),
    (p_org, 'exam',        'اختبار',        true,  '#eab308', 6, true,  false),
    (p_org, 'note',        'إعلان',         true,  '#64748b', 7, false, false);
end;
$$;

create or replace function public.trg_seed_calendar_defaults()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.seed_calendar_defaults(new.id);
  return new;
end;
$$;
drop trigger if exists trg_organizations_seed_calendar on public.organizations;
create trigger trg_organizations_seed_calendar after insert on public.organizations
  for each row execute function public.trg_seed_calendar_defaults();

select public.seed_calendar_defaults(id) from public.organizations;

-- ---------------------------------------------------------------------
-- 2. Entries
-- ---------------------------------------------------------------------
create table public.center_calendar (
  id                    uuid primary key default gen_random_uuid(),
  organization_id       uuid not null references public.organizations (id) on delete cascade,
  type_id               uuid references public.calendar_entry_types (id) on delete set null,
  -- Copies of the type at the time the entry was written (see header).
  kind                  text not null default 'event',
  is_working_day        boolean not null default true,
  title                 text not null,
  description           text,
  start_date            date not null,
  end_date              date not null,
  starts_at             time,
  location              text,
  audience              text not null default 'all' check (audience in ('all', 'teachers', 'students', 'guardians')),
  circle_id             uuid references public.circles (id) on delete cascade,
  stage_id              uuid references public.stages (id) on delete cascade,
  capacity              integer check (capacity is null or capacity > 0),
  registration_open     boolean not null default true,
  registration_deadline date,
  created_by            uuid references auth.users (id),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  check (end_date >= start_date)
);
create index center_calendar_org_range_idx on public.center_calendar (organization_id, start_date, end_date);
create index center_calendar_nonworking_idx on public.center_calendar (organization_id, start_date, end_date)
  where is_working_day = false;

-- ---------------------------------------------------------------------
-- 3. Registrations, waiting list
-- ---------------------------------------------------------------------
create table public.calendar_registrations (
  id              uuid primary key default gen_random_uuid(),
  entry_id        uuid not null references public.center_calendar (id) on delete cascade,
  student_id      uuid not null references public.students_profile (id) on delete cascade,
  source          text not null check (source in ('self', 'guardian', 'teacher', 'admin')),
  added_by        uuid references auth.users (id),
  note            text,
  result_rank     integer check (result_rank is null or result_rank > 0),
  result_note     text,
  -- Consent is a separate state beside the registration, never a condition on
  -- it: a seat waiting on an uncertain answer would be a seat empty in practice.
  consent_status  text not null default 'not_required'
                    check (consent_status in ('not_required', 'pending', 'approved', 'declined')),
  consent_token   uuid not null default gen_random_uuid() unique,
  consent_method  text check (consent_method in ('link', 'staff')),
  consent_by      uuid references auth.users (id),
  consent_at      timestamptz,
  created_at      timestamptz not null default now(),
  unique (entry_id, student_id)
);
create index calendar_registrations_student_idx on public.calendar_registrations (student_id);

create table public.calendar_waitlist (
  id           uuid primary key default gen_random_uuid(),
  entry_id     uuid not null references public.center_calendar (id) on delete cascade,
  student_id   uuid not null references public.students_profile (id) on delete cascade,
  status       text not null default 'waiting' check (status in ('waiting', 'promoted', 'cancelled')),
  created_at   timestamptz not null default now(),
  promoted_at  timestamptz,
  unique (entry_id, student_id)
);

-- ---------------------------------------------------------------------
-- 4. Who sees what (one function, called by policies and reads alike)
-- ---------------------------------------------------------------------
create or replace function public._calendar_visible(p_entry uuid)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare
  c public.center_calendar%rowtype;
  v_role public.user_role;
  v_linked uuid[];
begin
  select * into c from public.center_calendar where id = p_entry;
  if not found then return false; end if;
  if public.is_org_admin(c.organization_id) then return true; end if;
  v_role := public.current_role_in_org(c.organization_id);
  if v_role is null then return false; end if;

  if v_role = 'teacher' then
    return public.member_has_module(c.organization_id, 'calendar')
      and c.audience in ('all', 'teachers')
      and (c.circle_id is null or exists (
        select 1 from public.circles ci where ci.id = c.circle_id and ci.teacher_id = auth.uid()));
  end if;

  if not (c.audience = 'all'
          or (c.audience = 'students' and v_role = 'student')
          or (c.audience = 'guardians' and v_role = 'guardian')) then
    return false;
  end if;
  v_linked := public.linked_student_ids(c.organization_id);
  if c.circle_id is not null and not exists (
    select 1 from public.students_profile sp where sp.id = any (v_linked) and sp.circle_id = c.circle_id
  ) then return false; end if;
  if c.stage_id is not null and not exists (
    select 1 from public.students_profile sp join public.circles ci on ci.id = sp.circle_id
    where sp.id = any (v_linked) and ci.stage_id = c.stage_id
  ) then return false; end if;
  return true;
end;
$$;

-- How may the caller act for this student? 'admin' | 'teacher' | 'self' | 'guardian' | null
create or replace function public._act_source(p_org uuid, p_student uuid)
returns text language plpgsql stable security definer set search_path = public as $$
declare v_role public.user_role;
begin
  if auth.uid() is null then return null; end if;
  if public.is_org_admin(p_org) then return 'admin'; end if;
  v_role := public.current_role_in_org(p_org);
  if v_role = 'teacher' and public.member_has_module(p_org, 'calendar') and public._teaches_student(p_student) then
    return 'teacher';
  end if;
  if p_student = any (public.linked_student_ids(p_org)) then
    if v_role = 'student' then return 'self'; end if;
    if v_role = 'guardian' then return 'guardian'; end if;
  end if;
  return null;
end;
$$;

alter table public.calendar_entry_types enable row level security;
alter table public.center_calendar enable row level security;
alter table public.calendar_registrations enable row level security;
alter table public.calendar_waitlist enable row level security;

create policy "calendar_entry_types_select" on public.calendar_entry_types for select
  using (public.is_org_member(organization_id));
create policy "center_calendar_select" on public.center_calendar for select
  using (public._calendar_visible(id));
create policy "calendar_registrations_select" on public.calendar_registrations for select using (
  exists (
    select 1 from public.center_calendar e
    where e.id = entry_id
      and (public.is_org_admin(e.organization_id)
           or student_id = any (public.linked_student_ids(e.organization_id))
           or public._teaches_student(student_id))
  )
);
create policy "calendar_waitlist_select" on public.calendar_waitlist for select using (
  exists (
    select 1 from public.center_calendar e
    where e.id = entry_id
      and (public.is_org_admin(e.organization_id)
           or student_id = any (public.linked_student_ids(e.organization_id))
           or public._teaches_student(student_id))
  )
);

revoke insert, update, delete on public.calendar_entry_types, public.center_calendar,
  public.calendar_registrations, public.calendar_waitlist from authenticated;

-- ---------------------------------------------------------------------
-- 5. Working days: the attendance denominator
-- ---------------------------------------------------------------------
-- The weekday pattern minus every dated non-working entry (counted per DAY, so
-- a holiday on a Friday, or two overlapping closures, never subtract twice).
create or replace function public.center_working_days(p_org uuid, p_from date, p_to date, p_circle uuid default null)
returns integer language sql stable security definer set search_path = public as $$
  select count(*)::integer
  from generate_series(p_from, p_to, interval '1 day') d
  join public.center_weekdays w
    on w.organization_id = p_org and w.dow = extract(dow from d)::smallint
  where w.is_working
    and not exists (
      select 1 from public.center_calendar c
      where c.organization_id = p_org and not c.is_working_day
        and d::date between c.start_date and c.end_date
        -- a closure for one circle does not close the others
        and (c.circle_id is null or c.circle_id = p_circle)
    );
$$;

create or replace function public.working_days_between(p_org uuid, p_from date, p_to date)
returns integer language sql stable security definer set search_path = public as $$
  select public.center_working_days(p_org, p_from, p_to, null);
$$;

create or replace function public.attendance_rate(p_org uuid, p_student uuid, p_from date, p_to date)
returns numeric language plpgsql stable security definer set search_path = public as $$
declare v_working integer; v_present integer; v_circle uuid;
begin
  if p_student <> all (public.linked_student_ids(p_org)) and not public.is_org_staff(p_org) then
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

-- ---------------------------------------------------------------------
-- 6. Admin: types and entries
-- ---------------------------------------------------------------------
create or replace function public.admin_save_calendar_type(
  p_org uuid, p_id uuid, p_name text, p_default_is_working boolean, p_color text,
  p_sort_order integer, p_is_active boolean, p_supports_registration boolean, p_requires_consent boolean
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if nullif(btrim(coalesce(p_name, '')), '') is null then raise exception 'اسم النوع مطلوب'; end if;
  if p_color !~ '^#[0-9a-fA-F]{6}$' then raise exception 'اللون غير صالح'; end if;
  if v_id is null then
    insert into public.calendar_entry_types (organization_id, key, name, default_is_working, color, sort_order,
                                             is_active, supports_registration, requires_guardian_consent)
    values (p_org, 'custom_' || substr(md5(random()::text || clock_timestamp()::text), 1, 8), btrim(p_name),
            coalesce(p_default_is_working, true), p_color, coalesce(p_sort_order, 0), coalesce(p_is_active, true),
            coalesce(p_supports_registration, false), coalesce(p_requires_consent, false))
    returning id into v_id;
  else
    update public.calendar_entry_types set name = btrim(p_name), default_is_working = coalesce(p_default_is_working, true),
      color = p_color, sort_order = coalesce(p_sort_order, sort_order), is_active = coalesce(p_is_active, true),
      supports_registration = coalesce(p_supports_registration, false),
      requires_guardian_consent = coalesce(p_requires_consent, false)
    where id = v_id and organization_id = p_org;
    if not found then raise exception 'النوع غير موجود'; end if;
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), case when p_id is null then 'create' else 'update' end, 'calendar_entry_types', v_id);
  return v_id;
end;
$$;

create or replace function public.admin_delete_calendar_type(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  -- Entries keep their kind / working-day copy; only the live link is cleared.
  delete from public.calendar_entry_types where id = p_id and organization_id = p_org;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), 'delete', 'calendar_entry_types', p_id);
end;
$$;

create or replace function public.admin_save_calendar_entry(
  p_org uuid, p_id uuid, p_type uuid, p_title text, p_description text, p_start date, p_end date,
  p_is_working_day boolean, p_audience text, p_circle uuid, p_stage uuid, p_starts_at time,
  p_location text, p_capacity integer, p_registration_open boolean, p_deadline date
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid := p_id; v_type public.calendar_entry_types%rowtype; v_end date := coalesce(p_end, p_start);
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if nullif(btrim(coalesce(p_title, '')), '') is null then raise exception 'اكتب عنوان اليوم أو الفعالية'; end if;
  if p_start is null then raise exception 'اختر تاريخ البداية'; end if;
  if v_end < p_start then raise exception 'تاريخ النهاية قبل تاريخ البداية'; end if;
  if p_audience not in ('all', 'teachers', 'students', 'guardians') then raise exception 'جمهور غير معروف'; end if;
  select * into v_type from public.calendar_entry_types where id = p_type and organization_id = p_org;
  if not found then raise exception 'اختر نوعًا صحيحًا'; end if;
  if p_circle is not null and not exists (select 1 from public.circles where id = p_circle and organization_id = p_org) then
    raise exception 'الحلقة غير موجودة'; end if;
  if p_stage is not null and not exists (select 1 from public.stages where id = p_stage and organization_id = p_org) then
    raise exception 'المرحلة غير موجودة'; end if;
  if p_capacity is not null and p_capacity < 1 then raise exception 'عدد المقاعد يجب أن يكون 1 أو أكثر'; end if;
  if p_deadline is not null and p_deadline > v_end then raise exception 'موعد إغلاق التسجيل بعد الفعالية'; end if;

  if v_id is null then
    insert into public.center_calendar (organization_id, type_id, kind, is_working_day, title, description, start_date, end_date,
        starts_at, location, audience, circle_id, stage_id, capacity, registration_open, registration_deadline, created_by)
    values (p_org, v_type.id, v_type.key, coalesce(p_is_working_day, v_type.default_is_working), btrim(p_title),
        nullif(btrim(coalesce(p_description, '')), ''), p_start, v_end, p_starts_at, nullif(btrim(coalesce(p_location, '')), ''),
        p_audience, p_circle, p_stage, p_capacity, coalesce(p_registration_open, true), p_deadline, auth.uid())
    returning id into v_id;
  else
    update public.center_calendar set type_id = v_type.id, kind = v_type.key,
        is_working_day = coalesce(p_is_working_day, v_type.default_is_working), title = btrim(p_title),
        description = nullif(btrim(coalesce(p_description, '')), ''), start_date = p_start, end_date = v_end,
        starts_at = p_starts_at, location = nullif(btrim(coalesce(p_location, '')), ''), audience = p_audience,
        circle_id = p_circle, stage_id = p_stage, capacity = p_capacity,
        registration_open = coalesce(p_registration_open, true), registration_deadline = p_deadline, updated_at = now()
    where id = v_id and organization_id = p_org;
    if not found then raise exception 'العنصر غير موجود'; end if;
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), case when p_id is null then 'create' else 'update' end, 'center_calendar', v_id);
  return v_id;
end;
$$;

create or replace function public.admin_delete_calendar_entry(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  delete from public.center_calendar where id = p_id and organization_id = p_org;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), 'delete', 'center_calendar', p_id);
end;
$$;

-- ---------------------------------------------------------------------
-- 7. Registration (guarded; seats locked per entry)
-- ---------------------------------------------------------------------
-- Internal: insert a registration, deciding consent from the entry's type.
create or replace function public._insert_registration(p_entry uuid, p_student uuid, p_source text, p_added_by uuid, p_note text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_needs boolean; v_id uuid;
begin
  select coalesce(t.requires_guardian_consent, false) into v_needs
  from public.center_calendar c left join public.calendar_entry_types t on t.id = c.type_id where c.id = p_entry;
  insert into public.calendar_registrations (entry_id, student_id, source, added_by, note, consent_status)
  values (p_entry, p_student, p_source, p_added_by, nullif(btrim(coalesce(p_note, '')), ''),
          case when coalesce(v_needs, false) then 'pending' else 'not_required' end)
  returning id into v_id;
  return v_id;
end;
$$;

-- Internal: fill free seats from the waiting list, oldest first.
create or replace function public._promote_waitlist(p_entry uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_cap integer; v_taken integer; w record;
begin
  select capacity into v_cap from public.center_calendar where id = p_entry;
  loop
    select count(*) into v_taken from public.calendar_registrations where entry_id = p_entry;
    exit when v_cap is not null and v_taken >= v_cap;
    select * into w from public.calendar_waitlist where entry_id = p_entry and status = 'waiting'
      order by created_at limit 1 for update;
    exit when not found;
    perform public._insert_registration(p_entry, w.student_id, 'self', null, null);
    update public.calendar_waitlist set status = 'promoted', promoted_at = now() where id = w.id;
  end loop;
end;
$$;

create or replace function public.register_for_entry(p_org uuid, p_entry uuid, p_student uuid, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  c public.center_calendar%rowtype; v_source text; v_supports boolean; v_taken integer; v_id uuid; v_status text;
begin
  v_source := public._act_source(p_org, p_student);
  if v_source is null then raise exception 'غير مصرّح لك بتسجيل هذا الطالب'; end if;
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then
    raise exception 'الطالب غير موجود في هذا المركز'; end if;

  -- Locks the entry: two people can no longer take the last seat together.
  select * into c from public.center_calendar where id = p_entry and organization_id = p_org for update;
  if not found then raise exception 'الفعالية غير موجودة'; end if;
  if v_source in ('self', 'guardian') and not public._calendar_visible(p_entry) then
    raise exception 'الفعالية غير موجودة'; end if;

  select coalesce(t.supports_registration, false) into v_supports
    from public.calendar_entry_types t where t.id = c.type_id;
  if not coalesce(v_supports, false) then raise exception 'هذه الفعالية لا تقبل التسجيل'; end if;
  if c.end_date < current_date then raise exception 'انتهت الفعالية'; end if;
  if v_source in ('self', 'guardian') then
    if not c.registration_open then raise exception 'التسجيل مغلق'; end if;
    if c.registration_deadline is not null and current_date > c.registration_deadline then
      raise exception 'انتهى موعد التسجيل'; end if;
  end if;
  if exists (select 1 from public.calendar_registrations where entry_id = p_entry and student_id = p_student) then
    raise exception 'الطالب مسجّل بالفعل'; end if;

  select count(*) into v_taken from public.calendar_registrations where entry_id = p_entry;
  if c.capacity is not null and v_taken >= c.capacity then raise exception 'اكتملت المقاعد'; end if;

  v_id := public._insert_registration(p_entry, p_student, v_source, auth.uid(), p_note);
  update public.calendar_waitlist set status = 'cancelled' where entry_id = p_entry and student_id = p_student and status = 'waiting';
  select consent_status into v_status from public.calendar_registrations where id = v_id;
  return jsonb_build_object('registration_id', v_id, 'consent_status', v_status);
end;
$$;

create or replace function public.unregister_from_entry(p_registration uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r public.calendar_registrations%rowtype; c public.center_calendar%rowtype; v_source text;
begin
  select * into r from public.calendar_registrations where id = p_registration;
  if not found then raise exception 'التسجيل غير موجود'; end if;
  select * into c from public.center_calendar where id = r.entry_id for update;
  v_source := public._act_source(c.organization_id, r.student_id);
  if v_source is null then raise exception 'غير مصرّح'; end if;
  -- A family may only withdraw what a family registered; staff-added
  -- registrations are removed by staff.
  if v_source in ('self', 'guardian') then
    if r.source not in ('self', 'guardian') then raise exception 'سجّله المعلم أو المشرف، تواصل معه لإلغائه'; end if;
    if c.end_date < current_date then raise exception 'انتهت الفعالية'; end if;
  end if;
  delete from public.calendar_registrations where id = p_registration;
  perform public._promote_waitlist(c.id);
end;
$$;

create or replace function public.join_waitlist(p_org uuid, p_entry uuid, p_student uuid)
returns void language plpgsql security definer set search_path = public as $$
declare c public.center_calendar%rowtype; v_source text; v_taken integer;
begin
  v_source := public._act_source(p_org, p_student);
  if coalesce(v_source, '') not in ('self', 'guardian') then raise exception 'غير مصرّح'; end if;
  select * into c from public.center_calendar where id = p_entry and organization_id = p_org for update;
  if not found or not public._calendar_visible(p_entry) then raise exception 'الفعالية غير موجودة'; end if;
  if c.end_date < current_date or not c.registration_open
     or (c.registration_deadline is not null and current_date > c.registration_deadline) then
    raise exception 'التسجيل مغلق'; end if;
  if exists (select 1 from public.calendar_registrations where entry_id = p_entry and student_id = p_student) then
    raise exception 'الطالب مسجّل بالفعل'; end if;
  select count(*) into v_taken from public.calendar_registrations where entry_id = p_entry;
  if c.capacity is null or v_taken < c.capacity then raise exception 'توجد مقاعد متاحة، سجّل مباشرة'; end if;
  insert into public.calendar_waitlist (entry_id, student_id) values (p_entry, p_student)
  on conflict (entry_id, student_id) do update set status = 'waiting', created_at = now(), promoted_at = null;
end;
$$;

create or replace function public.leave_waitlist(p_org uuid, p_entry uuid, p_student uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if coalesce(public._act_source(p_org, p_student), '') not in ('self', 'guardian') then raise exception 'غير مصرّح'; end if;
  update public.calendar_waitlist set status = 'cancelled'
   where entry_id = p_entry and student_id = p_student and status = 'waiting';
end;
$$;

-- Consent recorded by staff (a phone call), or the result of an event.
create or replace function public.staff_record_consent(p_registration uuid, p_decision text)
returns void language plpgsql security definer set search_path = public as $$
declare r public.calendar_registrations%rowtype; v_org uuid; v_source text;
begin
  if p_decision not in ('approved', 'declined') then raise exception 'قرار غير معروف'; end if;
  select * into r from public.calendar_registrations where id = p_registration;
  if not found then raise exception 'التسجيل غير موجود'; end if;
  select organization_id into v_org from public.center_calendar where id = r.entry_id;
  v_source := public._act_source(v_org, r.student_id);
  if coalesce(v_source, '') not in ('admin', 'teacher') then raise exception 'غير مصرّح'; end if;
  if r.consent_status = 'not_required' then raise exception 'هذه الفعالية لا تحتاج موافقة'; end if;
  update public.calendar_registrations set consent_status = p_decision, consent_method = 'staff',
    consent_by = auth.uid(), consent_at = now() where id = p_registration;
end;
$$;

create or replace function public.set_registration_result(p_registration uuid, p_rank integer, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare v_org uuid;
begin
  select c.organization_id into v_org from public.calendar_registrations r
    join public.center_calendar c on c.id = r.entry_id where r.id = p_registration;
  if v_org is null then raise exception 'التسجيل غير موجود'; end if;
  if not public.is_org_admin(v_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  update public.calendar_registrations set result_rank = p_rank, result_note = nullif(btrim(coalesce(p_note, '')), '')
   where id = p_registration;
end;
$$;

-- Public consent link (called ONLY by the web server route with the service key).
create or replace function public.consent_info(p_token uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v jsonb;
begin
  select jsonb_build_object(
    'center', o.name, 'event', c.title, 'start_date', c.start_date, 'end_date', c.end_date,
    'starts_at', c.starts_at, 'location', c.location, 'description', c.description,
    'student', sp.full_name, 'status', r.consent_status)
  into v
  from public.calendar_registrations r
  join public.center_calendar c on c.id = r.entry_id
  join public.organizations o on o.id = c.organization_id
  join public.students_profile sp on sp.id = r.student_id
  where r.consent_token = p_token and r.consent_status <> 'not_required';
  return v;
end;
$$;

create or replace function public.consent_answer(p_token uuid, p_decision text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if p_decision not in ('approved', 'declined') then raise exception 'قرار غير معروف'; end if;
  update public.calendar_registrations set consent_status = p_decision, consent_method = 'link',
    consent_by = null, consent_at = now()
  where consent_token = p_token and consent_status <> 'not_required';
  return found;
end;
$$;

-- ---------------------------------------------------------------------
-- 8. Reads
-- ---------------------------------------------------------------------
create or replace function public._calendar_entry_json(p_entry uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', c.id, 'title', c.title, 'description', c.description,
    'start_date', c.start_date, 'end_date', c.end_date, 'starts_at', c.starts_at, 'location', c.location,
    'kind', c.kind, 'type_id', c.type_id, 'type_name', coalesce(t.name, c.kind), 'type_color', coalesce(t.color, '#64748b'),
    'is_working_day', c.is_working_day, 'audience', c.audience,
    'circle_id', c.circle_id, 'circle_name', ci.name, 'stage_id', c.stage_id, 'stage_name', st.name,
    'capacity', c.capacity, 'registration_open', c.registration_open, 'registration_deadline', c.registration_deadline,
    'supports_registration', coalesce(t.supports_registration, false),
    'requires_guardian_consent', coalesce(t.requires_guardian_consent, false),
    'taken', (select count(*) from public.calendar_registrations r where r.entry_id = c.id),
    'waiting', (select count(*) from public.calendar_waitlist w where w.entry_id = c.id and w.status = 'waiting'),
    'my_registered', exists (select 1 from public.calendar_registrations r
                             where r.entry_id = c.id and r.student_id = any (public.linked_student_ids(c.organization_id))),
    'registration_state',
      case when not coalesce(t.supports_registration, false) then 'none'
           when c.end_date < current_date then 'ended'
           when not c.registration_open then 'closed'
           when c.registration_deadline is not null and current_date > c.registration_deadline then 'closed'
           when c.capacity is not null and (select count(*) from public.calendar_registrations r where r.entry_id = c.id) >= c.capacity then 'full'
           else 'open' end)
  from public.center_calendar c
  left join public.calendar_entry_types t on t.id = c.type_id
  left join public.circles ci on ci.id = c.circle_id
  left join public.stages st on st.id = c.stage_id
  where c.id = p_entry;
$$;

create or replace function public.calendar_range(p_org uuid, p_from date, p_to date, p_circle uuid default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_role public.user_role;
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  if p_from is null or p_to is null or p_to < p_from then raise exception 'المدى الزمني غير صحيح'; end if;
  v_role := public.current_role_in_org(p_org);
  if v_role = 'teacher' and not public.member_has_module(p_org, 'calendar') then raise exception 'غير مصرّح'; end if;

  return jsonb_build_object(
    'from', p_from, 'to', p_to,
    'working_days', public.center_working_days(p_org, p_from, p_to, p_circle),
    'total_days', (p_to - p_from + 1),
    'weekdays', coalesce((select jsonb_agg(jsonb_build_object('dow', w.dow, 'label', w.label, 'is_working', w.is_working,
                  'is_serd_day', w.is_serd_day) order by w.dow) from public.center_weekdays w where w.organization_id = p_org), '[]'::jsonb),
    'types', coalesce((select jsonb_agg(jsonb_build_object('id', t.id, 'key', t.key, 'name', t.name, 'color', t.color,
                  'default_is_working', t.default_is_working, 'is_active', t.is_active,
                  'supports_registration', t.supports_registration, 'requires_guardian_consent', t.requires_guardian_consent,
                  'sort_order', t.sort_order) order by t.sort_order, t.name)
                  from public.calendar_entry_types t where t.organization_id = p_org), '[]'::jsonb),
    'entries', coalesce((select jsonb_agg(public._calendar_entry_json(c.id) order by c.start_date, c.starts_at nulls first)
                  from public.center_calendar c
                  where c.organization_id = p_org and c.start_date <= p_to and c.end_date >= p_from
                    and (p_circle is null or c.circle_id is null or c.circle_id = p_circle)
                    and public._calendar_visible(c.id)), '[]'::jsonb),
    -- Scheduled serd is a dated thing the center expects, so it lives on the
    -- calendar - read from serd_sessions (which owns it), never copied.
    'serd', coalesce((select jsonb_agg(jsonb_build_object('id', s.id, 'student_name', s.student_name,
                  'session_date', s.session_date, 'assigned', s.assigned_teacher_id is not null) order by s.session_date)
                  from public.serd_sessions s
                  where s.organization_id = p_org and s.status = 'scheduled' and s.session_date between p_from and p_to
                    and (public.is_org_admin(p_org)
                         or (v_role = 'teacher' and public.member_has_module(p_org, 'serd')
                             and (s.assigned_teacher_id is null or s.assigned_teacher_id = auth.uid()))
                         or s.student_id = any (public.linked_student_ids(p_org)))), '[]'::jsonb)
  );
end;
$$;

create or replace function public.calendar_entry_details(p_org uuid, p_entry uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_base jsonb; v_admin boolean := public.is_org_admin(p_org); v_kids jsonb; v_parts jsonb; v_wait jsonb;
begin
  if not exists (select 1 from public.center_calendar where id = p_entry and organization_id = p_org)
     or not public._calendar_visible(p_entry) then
    raise exception 'الفعالية غير موجودة';
  end if;
  v_base := public._calendar_entry_json(p_entry);

  -- The caller's own children / own record, with their registration state.
  select coalesce(jsonb_agg(jsonb_build_object(
      'student_id', sp.id, 'student_name', sp.full_name,
      'registration_id', r.id, 'source', r.source, 'consent_status', r.consent_status,
      'consent_token', r.consent_token, 'result_rank', r.result_rank, 'result_note', r.result_note,
      'waiting', exists (select 1 from public.calendar_waitlist w where w.entry_id = p_entry and w.student_id = sp.id and w.status = 'waiting')
    ) order by sp.full_name), '[]'::jsonb) into v_kids
  from public.students_profile sp
  left join public.calendar_registrations r on r.entry_id = p_entry and r.student_id = sp.id
  where sp.id = any (public.linked_student_ids(p_org));

  -- Staff: the roster (admin: everyone; teacher: their own students).
  select coalesce(jsonb_agg(jsonb_build_object(
      'registration_id', r.id, 'student_id', sp.id, 'student_name', sp.full_name, 'student_code', sp.student_code,
      'circle_name', ci.name, 'source', r.source, 'consent_status', r.consent_status, 'consent_method', r.consent_method,
      'consent_token', r.consent_token, 'result_rank', r.result_rank, 'result_note', r.result_note, 'created_at', r.created_at
    ) order by r.created_at), '[]'::jsonb) into v_parts
  from public.calendar_registrations r
  join public.students_profile sp on sp.id = r.student_id
  left join public.circles ci on ci.id = sp.circle_id
  where r.entry_id = p_entry and (v_admin or public._act_source(p_org, sp.id) = 'teacher');

  select coalesce(jsonb_agg(jsonb_build_object('student_id', sp.id, 'student_name', sp.full_name, 'created_at', w.created_at)
    order by w.created_at), '[]'::jsonb) into v_wait
  from public.calendar_waitlist w join public.students_profile sp on sp.id = w.student_id
  where w.entry_id = p_entry and w.status = 'waiting' and (v_admin or public._act_source(p_org, sp.id) = 'teacher');

  return v_base || jsonb_build_object('mine', v_kids, 'participants', v_parts, 'waitlist', v_wait);
end;
$$;

-- Students a teacher/admin may register for an entry (with current state).
create or replace function public.entry_candidates(p_org uuid, p_entry uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not (public.is_org_admin(p_org) or (public.is_org_staff(p_org) and public.member_has_module(p_org, 'calendar'))) then
    raise exception 'غير مصرّح'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('student_id', sp.id, 'student_name', sp.full_name, 'student_code', sp.student_code,
             'circle_name', ci.name, 'registered', r.id is not null) order by sp.full_name)
    from public.students_profile sp
    left join public.circles ci on ci.id = sp.circle_id
    left join public.calendar_registrations r on r.entry_id = p_entry and r.student_id = sp.id
    where sp.organization_id = p_org and sp.status = 'active'
      and (public.is_org_admin(p_org) or public._teaches_student(sp.id))
  ), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- 9. Grants (0018 policy)
-- ---------------------------------------------------------------------
revoke all on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated, service_role;
grant execute on function public.get_invitation(uuid) to anon;

-- internals: not callable from the API at all
revoke execute on function public._insert_registration(uuid, uuid, text, uuid, text) from authenticated;
revoke execute on function public._promote_waitlist(uuid) from authenticated;
revoke execute on function public._calendar_entry_json(uuid) from authenticated;
-- the public consent link goes through the server route (service key) only
revoke execute on function public.consent_info(uuid) from authenticated;
revoke execute on function public.consent_answer(uuid, text) from authenticated;
-- keep the serd internals closed as before
revoke execute on function public._serd_write_parts(uuid, uuid, uuid, jsonb) from authenticated;
revoke execute on function public._serd_write_errors(uuid, uuid, jsonb) from authenticated;
revoke execute on function public._assert_serd_grader(uuid) from authenticated;
revoke execute on function public._serd_parts_json(uuid) from authenticated;
revoke execute on function public._serd_row_json(uuid) from authenticated;
