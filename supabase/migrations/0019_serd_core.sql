-- =========================================================================
-- 0019_serd_core.sql
-- السرد القرآني - a graded, continuous recitation of whole juz (or a half /
-- quarter / eighth of one), scored by counting mistakes. Rebuilt to match the
-- eqraa design, but per center:
--
--   * every center owns its error weights, pass mark, points-per-juz and the
--     amounts a stage may recite (organization-scoped, not one global row);
--   * THE FREEZE RULE: score, error weights, points and the pass mark are
--     copied onto the session when graded/approved and never recomputed, so
--     changing a setting only affects FUTURE sessions;
--   * a session needs an admin's approval before it counts, and points are
--     awarded on approval only;
--   * the examiner (who listened) is not necessarily the circle teacher;
--   * a session can be scheduled by an admin - open to any teacher, or
--     assigned to one;
--   * the atomic unit of an amount is the EIGHTH, so coverage and points are
--     exact integer arithmetic.
--
-- The earlier simplified serd tables (0003/0013/0015) held no production data
-- and are replaced.
-- =========================================================================

drop table if exists public.serd_session_errors cascade;
drop table if exists public.serd_session_parts cascade;
drop table if exists public.serd_sessions cascade;
drop table if exists public.serd_error_types cascade;
drop table if exists public.serd_stage_portions cascade;
drop table if exists public.serd_config cascade;
drop type if exists public.serd_session_type;
drop type if exists public.serd_session_status;

-- ---------------------------------------------------------------------
-- 1. The thirty juz, named by their opening words (how a halaqa says them)
-- ---------------------------------------------------------------------
create table if not exists public.juz_reference (
  number smallint primary key check (number between 1 and 30),
  name   text not null
);
insert into public.juz_reference (number, name) values
  (1,'آلم'), (2,'سيقول'), (3,'تلك الرسل'), (4,'لن تنالوا'), (5,'والمحصنات'),
  (6,'لا يحب الله'), (7,'وإذا سمعوا'), (8,'ولو أننا'), (9,'قال الملأ'),
  (10,'واعلموا'), (11,'يعتذرون'), (12,'وما من دابة'), (13,'وما أبرئ'),
  (14,'ربما'), (15,'سبحان الذي'), (16,'قال ألم'), (17,'اقترب للناس'),
  (18,'قد أفلح'), (19,'وقال الذين'), (20,'أمّن خلق'), (21,'اتل ما أوحي'),
  (22,'ومن يقنت'), (23,'وما لي'), (24,'فمن أظلم'), (25,'إليه يرد'),
  (26,'حم'), (27,'قال فما خطبكم'), (28,'قد سمع'), (29,'تبارك الذي'), (30,'عمّ')
on conflict (number) do update set name = excluded.name;
alter table public.juz_reference enable row level security;
create policy "juz_reference_read" on public.juz_reference for select to authenticated using (true);

-- ---------------------------------------------------------------------
-- 2. Per-center settings
-- ---------------------------------------------------------------------
create table public.serd_config (
  organization_id       uuid primary key references public.organizations (id) on delete cascade,
  pass_percent          numeric(5,2) not null default 80 check (pass_percent between 0 and 100),
  points_per_juz        integer not null default 50 check (points_per_juz >= 0),
  -- 1 = whole juz, 2 = half, 4 = quarter, 8 = eighth. 1 is always allowed.
  allowed_denominators  smallint[] not null default '{1}',
  updated_at            timestamptz not null default now()
);

-- Per-stage override (a children's stage may recite halves / quarters and
-- needs its own pass mark, because the score ignores how MUCH was recited).
create table public.serd_stage_portions (
  organization_id       uuid not null references public.organizations (id) on delete cascade,
  stage_id              uuid not null references public.stages (id) on delete cascade,
  allowed_denominators  smallint[] not null default '{1}',
  pass_percent          numeric(5,2) check (pass_percent is null or pass_percent between 0 and 100),
  updated_at            timestamptz not null default now(),
  primary key (stage_id)
);

create table public.serd_error_types (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations (id) on delete cascade,
  name              text not null,
  -- "every N of these costs X%" - stored as the pair the admin thinks in.
  errors_per_unit   integer not null default 1 check (errors_per_unit > 0),
  percent_per_unit  numeric(5,2) not null default 1 check (percent_per_unit >= 0),
  is_active         boolean not null default true,
  sort_order        integer not null default 0,
  created_at        timestamptz not null default now()
);
create index serd_error_types_org_idx on public.serd_error_types (organization_id, sort_order);

create or replace function public.seed_serd_defaults(p_org uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.serd_config (organization_id) values (p_org) on conflict do nothing;
  if not exists (select 1 from public.serd_error_types where organization_id = p_org) then
    insert into public.serd_error_types (organization_id, name, errors_per_unit, percent_per_unit, sort_order) values
      (p_org, 'خطأ تلقيني', 3, 1.0, 1),
      (p_org, 'خطأ تنبيهي', 5, 1.0, 2),
      (p_org, 'خطأ تجويدي', 5, 0.5, 3),
      (p_org, 'خطأ في التشكيل', 10, 0.5, 4);
  end if;
end;
$$;

create or replace function public.trg_seed_serd_defaults()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.seed_serd_defaults(new.id);
  return new;
end;
$$;
drop trigger if exists trg_organizations_seed_serd on public.organizations;
create trigger trg_organizations_seed_serd after insert on public.organizations
  for each row execute function public.trg_seed_serd_defaults();

select public.seed_serd_defaults(id) from public.organizations;

-- ---------------------------------------------------------------------
-- 3. Sessions
-- ---------------------------------------------------------------------
create table public.serd_sessions (
  id                    uuid primary key default gen_random_uuid(),
  organization_id       uuid not null references public.organizations (id) on delete cascade,
  -- NULL until linked: the examiner may hear a child whose file they don't
  -- have; an admin links it before approving.
  student_id            uuid references public.students_profile (id) on delete set null,
  -- What was typed when nobody could be picked; kept after linking.
  student_name          text not null,
  -- Who actually listened (not necessarily the circle teacher).
  examiner_id           uuid references auth.users (id) on delete set null,
  -- Scheduled sessions only: NULL = open to any teacher.
  assigned_teacher_id   uuid references auth.users (id) on delete set null,
  -- Derived from the parts; kept for cheap filtering.
  juz_numbers           smallint[] not null default '{}',
  session_date          date not null default current_date,
  -- scheduled: registered, nobody has recited yet. submitted: graded, waiting
  -- on the admin. approved: counts. rejected: kept, not counted.
  status                text not null default 'submitted'
                          check (status in ('scheduled', 'submitted', 'approved', 'rejected')),
  score_percent         numeric(5,2),
  notes                 text,
  reject_reason         text,
  -- Frozen at approval.
  points_awarded        integer not null default 0,
  pass_percent_applied  numeric(5,2),
  approved_by           uuid references auth.users (id),
  approved_at           timestamptz,
  client_ref            uuid unique,
  created_at            timestamptz not null default now()
);
create index serd_sessions_org_status_idx on public.serd_sessions (organization_id, status, session_date desc);
create index serd_sessions_student_idx on public.serd_sessions (student_id, session_date desc);
create index serd_sessions_examiner_idx on public.serd_sessions (examiner_id);

create table public.serd_session_parts (
  id             uuid primary key default gen_random_uuid(),
  session_id     uuid not null references public.serd_sessions (id) on delete cascade,
  juz_number     smallint not null check (juz_number between 1 and 30),
  portion_den    smallint not null default 1 check (portion_den in (1, 2, 4, 8)),
  portion_index  smallint not null default 1 check (portion_index >= 1),
  -- The eighths this part covers, as a bitmask (whole = 255, first half = 15).
  eighths_mask   smallint not null check (eighths_mask between 1 and 255),
  check (portion_index <= portion_den),
  unique (session_id, juz_number, portion_den, portion_index)
);
create index serd_session_parts_session_idx on public.serd_session_parts (session_id);

create table public.serd_session_errors (
  id                uuid primary key default gen_random_uuid(),
  session_id        uuid not null references public.serd_sessions (id) on delete cascade,
  error_type_id     uuid references public.serd_error_types (id) on delete set null,
  -- Copied, not joined: the type may later be renamed / re-weighted / deleted
  -- and this row must still explain the score it produced.
  type_name         text not null,
  errors_per_unit   integer not null,
  percent_per_unit  numeric(5,2) not null,
  error_count       integer not null default 0 check (error_count >= 0),
  deducted_percent  numeric(5,2) not null default 0,
  unique (session_id, error_type_id)
);

-- ---------------------------------------------------------------------
-- 4. Eighth arithmetic + labels
-- ---------------------------------------------------------------------
create or replace function public.serd_portion_mask(p_den smallint, p_index smallint)
returns smallint language sql immutable as $$
  select ((((1 << (8 / p_den::int)) - 1) << ((p_index::int - 1) * (8 / p_den::int))))::smallint;
$$;

create or replace function public.serd_mask_eighths(p_mask smallint)
returns smallint language sql immutable as $$
  select coalesce(sum(case when (p_mask::int >> b) & 1 = 1 then 1 else 0 end), 0)::smallint
  from generate_series(0, 7) as b;
$$;

create or replace function public.serd_portion_label(p_den smallint, p_index smallint)
returns text language sql immutable as $$
  select case p_den
    when 1 then ''
    else (case p_den when 2 then 'النصف ' when 4 then 'الربع ' else 'الثُمن ' end)
      || (array['الأول','الثاني','الثالث','الرابع','الخامس','السادس','السابع','الثامن'])[p_index::int]
  end;
$$;

-- ---------------------------------------------------------------------
-- 5. Access
-- ---------------------------------------------------------------------
-- Does the caller teach this student (their circle's teacher)?
create or replace function public._teaches_student(p_student uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.students_profile sp
    join public.circles c on c.id = sp.circle_id
    where sp.id = p_student and c.teacher_id = auth.uid()
  );
$$;

alter table public.serd_config enable row level security;
alter table public.serd_stage_portions enable row level security;
alter table public.serd_error_types enable row level security;
alter table public.serd_sessions enable row level security;
alter table public.serd_session_parts enable row level security;
alter table public.serd_session_errors enable row level security;

-- Settings: staff read (the grading screen needs the error types); writes go
-- through audited RPCs only.
create policy "serd_config_select" on public.serd_config for select
  using (public.is_org_staff(organization_id));
create policy "serd_stage_portions_select" on public.serd_stage_portions for select
  using (public.is_org_staff(organization_id));
create policy "serd_error_types_select" on public.serd_error_types for select
  using (public.is_org_staff(organization_id));

-- Sessions: admin sees all; a teacher with the serd module sees what they
-- heard, open/assigned tasks, and sessions of students in their circle; a
-- student/guardian sees only APPROVED sessions of their own linked student.
create policy "serd_sessions_select" on public.serd_sessions for select using (
  public.is_org_admin(organization_id)
  or (
    public.member_has_module(organization_id, 'serd')
    and (
      examiner_id = auth.uid()
      or (status = 'scheduled' and (assigned_teacher_id is null or assigned_teacher_id = auth.uid()))
      or (student_id is not null and public._teaches_student(student_id))
    )
  )
  or (status = 'approved' and student_id = any (public.linked_student_ids(organization_id)))
);

-- Parts / errors are readable exactly when their session is (the subquery is
-- itself filtered by the policy above).
create policy "serd_session_parts_select" on public.serd_session_parts for select using (
  exists (select 1 from public.serd_sessions s where s.id = session_id)
);
create policy "serd_session_errors_select" on public.serd_session_errors for select using (
  exists (select 1 from public.serd_sessions s where s.id = session_id)
);

revoke insert, update, delete on public.serd_config, public.serd_stage_portions, public.serd_error_types,
  public.serd_sessions, public.serd_session_parts, public.serd_session_errors from authenticated;

-- ---------------------------------------------------------------------
-- 6. Points: mirror trigger (approved + linked only), like daily_achievements
-- ---------------------------------------------------------------------
create or replace function public.sync_serd_total_points()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_old int := 0; v_new int := 0;
begin
  if tg_op <> 'INSERT' and old.status = 'approved' and old.student_id is not null then
    v_old := coalesce(old.points_awarded, 0);
  end if;
  if tg_op <> 'DELETE' and new.status = 'approved' and new.student_id is not null then
    v_new := coalesce(new.points_awarded, 0);
  end if;
  if tg_op <> 'INSERT' and v_old <> 0 then
    update public.students_profile set total_points = coalesce(total_points, 0) - v_old where id = old.student_id;
  end if;
  if tg_op <> 'DELETE' and v_new <> 0 then
    update public.students_profile set total_points = coalesce(total_points, 0) + v_new where id = new.student_id;
  end if;
  return case tg_op when 'DELETE' then old else new end;
end;
$$;
drop trigger if exists trg_sync_serd_total_points on public.serd_sessions;
create trigger trg_sync_serd_total_points after insert or update or delete on public.serd_sessions
  for each row execute function public.sync_serd_total_points();

-- ---------------------------------------------------------------------
-- 7. Policy resolution (amounts allowed, pass mark)
-- ---------------------------------------------------------------------
create or replace function public.serd_allowed_denominators(p_org uuid, p_student uuid)
returns smallint[] language plpgsql stable security definer set search_path = public as $$
declare v_list smallint[];
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  if p_student is not null then
    select sp2.allowed_denominators into v_list
    from public.students_profile sp
    join public.circles c on c.id = sp.circle_id
    join public.serd_stage_portions sp2 on sp2.stage_id = c.stage_id
    where sp.id = p_student and sp.organization_id = p_org;
  end if;
  if v_list is null then
    select allowed_denominators into v_list from public.serd_config where organization_id = p_org;
  end if;
  v_list := coalesce(v_list, '{1}'::smallint[]);
  if not (1 = any (v_list)) then v_list := v_list || 1::smallint; end if;
  return v_list;
end;
$$;

create or replace function public.serd_pass_percent(p_org uuid, p_student uuid)
returns numeric language plpgsql stable security definer set search_path = public as $$
declare v_pass numeric;
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  if p_student is not null then
    select sp2.pass_percent into v_pass
    from public.students_profile sp
    join public.circles c on c.id = sp.circle_id
    join public.serd_stage_portions sp2 on sp2.stage_id = c.stage_id
    where sp.id = p_student and sp.organization_id = p_org and sp2.pass_percent is not null;
  end if;
  if v_pass is null then
    select pass_percent into v_pass from public.serd_config where organization_id = p_org;
  end if;
  return coalesce(v_pass, 80);
end;
$$;

-- Everything the grading screen needs in ONE call: settings, error types,
-- per-stage amounts (so the picker works for any student).
create or replace function public.serd_grading_setup(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_staff(p_org) then raise exception 'غير مصرّح'; end if;
  return jsonb_build_object(
    'pass_percent', (select pass_percent from public.serd_config where organization_id = p_org),
    'points_per_juz', (select points_per_juz from public.serd_config where organization_id = p_org),
    'default_denominators', (select to_jsonb(allowed_denominators) from public.serd_config where organization_id = p_org),
    'error_types', coalesce((
      select jsonb_agg(jsonb_build_object('id', e.id, 'name', e.name, 'errors_per_unit', e.errors_per_unit,
               'percent_per_unit', e.percent_per_unit, 'is_active', e.is_active) order by e.sort_order, e.name)
      from public.serd_error_types e where e.organization_id = p_org), '[]'::jsonb),
    'stages', coalesce((
      select jsonb_agg(jsonb_build_object('stage_id', sp.stage_id, 'stage_name', st.name,
               'denominators', to_jsonb(sp.allowed_denominators), 'pass_percent', sp.pass_percent))
      from public.serd_stage_portions sp join public.stages st on st.id = sp.stage_id
      where sp.organization_id = p_org), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------
-- 8. Internal: write the parts of a session (validated) and grade errors
-- ---------------------------------------------------------------------
create or replace function public._serd_write_parts(p_org uuid, p_session uuid, p_student uuid, p_parts jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_allowed smallint[] := public.serd_allowed_denominators(p_org, p_student);
  v_item jsonb; v_juz smallint; v_den smallint; v_idx smallint; v_mask smallint;
  v_seen jsonb := '{}'::jsonb;
begin
  if p_parts is null or jsonb_typeof(p_parts) <> 'array' or jsonb_array_length(p_parts) = 0 then
    raise exception 'اختر جزءاً واحداً على الأقل';
  end if;
  delete from public.serd_session_parts where session_id = p_session;

  for v_item in select * from jsonb_array_elements(p_parts) loop
    v_juz := (v_item->>'juz')::smallint;
    v_den := coalesce((v_item->>'den')::smallint, 1);
    v_idx := coalesce((v_item->>'index')::smallint, 1);
    if v_juz is null or v_juz < 1 or v_juz > 30 then raise exception 'رقم الجزء يجب أن يكون بين 1 و 30'; end if;
    if v_den not in (1, 2, 4, 8) or v_idx < 1 or v_idx > v_den then raise exception 'مقدار غير صالح'; end if;
    if not (v_den = any (v_allowed)) then
      raise exception 'هذا المقدار غير مسموح لمرحلة الطالب في هذا المركز';
    end if;
    v_mask := public.serd_portion_mask(v_den, v_idx);
    -- Overlap inside one session (e.g. a half and a quarter of the same half)
    -- would count the same eighths twice.
    if (coalesce((v_seen->>v_juz::text)::int, 0) & v_mask::int) <> 0 then
      raise exception 'الأجزاء المدخلة متداخلة';
    end if;
    v_seen := jsonb_set(v_seen, array[v_juz::text],
                        to_jsonb(coalesce((v_seen->>v_juz::text)::int, 0) | v_mask::int));
    insert into public.serd_session_parts (session_id, juz_number, portion_den, portion_index, eighths_mask)
    values (p_session, v_juz, v_den, v_idx, v_mask);
  end loop;

  update public.serd_sessions set juz_numbers = coalesce((
    select array_agg(distinct juz_number order by juz_number) from public.serd_session_parts where session_id = p_session
  ), '{}') where id = p_session;
end;
$$;

create or replace function public._serd_write_errors(p_org uuid, p_session uuid, p_errors jsonb)
returns numeric language plpgsql security definer set search_path = public as $$
declare
  v_total numeric(6,2) := 0; v_item jsonb; v_type public.serd_error_types%rowtype;
  v_count integer; v_deduct numeric(6,2);
begin
  delete from public.serd_session_errors where session_id = p_session;
  for v_item in select * from jsonb_array_elements(coalesce(p_errors, '[]'::jsonb)) loop
    v_count := greatest(0, coalesce((v_item->>'count')::int, 0));
    continue when v_count = 0;
    select * into v_type from public.serd_error_types
      where id = (v_item->>'type_id')::uuid and organization_id = p_org;
    if not found then continue; end if;
    -- Exact proportion, not integer division: "3 mistakes = 1%" must not turn
    -- two mistakes into a free pass.
    v_deduct := round(v_count * v_type.percent_per_unit / v_type.errors_per_unit, 2);
    v_total := v_total + v_deduct;
    insert into public.serd_session_errors (session_id, error_type_id, type_name, errors_per_unit,
                                            percent_per_unit, error_count, deducted_percent)
    values (p_session, v_type.id, v_type.name, v_type.errors_per_unit, v_type.percent_per_unit, v_count, v_deduct);
  end loop;
  return greatest(0, 100 - v_total);
end;
$$;

revoke all on function public._serd_write_parts(uuid, uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public._serd_write_errors(uuid, uuid, jsonb) from public, anon, authenticated;

create or replace function public._assert_serd_grader(p_org uuid)
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if auth.uid() is null or not public.is_org_staff(p_org) or not public.member_has_module(p_org, 'serd') then
    raise exception 'غير مصرّح لك بهذا الإجراء';
  end if;
end;
$$;
revoke all on function public._assert_serd_grader(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 9. Teacher: submit a graded session (new, or complete a scheduled one)
-- ---------------------------------------------------------------------
create or replace function public.teacher_submit_serd(
  p_org          uuid,
  p_student      uuid,
  p_student_name text,
  p_parts        jsonb,           -- [{"juz":30,"den":2,"index":1}, ...]
  p_date         date,
  p_notes        text,
  p_errors       jsonb,           -- [{"type_id": uuid, "count": int}, ...]
  p_client_ref   uuid default null,
  p_session_id   uuid default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_name text := nullif(btrim(coalesce(p_student_name, '')), '');
  v_session uuid; v_status text; v_assigned uuid; v_org uuid; v_score numeric;
  v_student uuid := p_student;
begin
  perform public._assert_serd_grader(p_org);

  if p_client_ref is not null then
    select id into v_session from public.serd_sessions where client_ref = p_client_ref and organization_id = p_org;
    if v_session is not null then
      return jsonb_build_object('session_id', v_session, 'duplicate', true);
    end if;
  end if;
  if coalesce(p_date, current_date) > current_date then
    raise exception 'لا يمكن تسجيل سرد بتاريخ مستقبلي';
  end if;

  if p_session_id is not null then
    select status, assigned_teacher_id, organization_id, student_id
      into v_status, v_assigned, v_org, v_student
      from public.serd_sessions where id = p_session_id for update;
    if not found or v_org <> p_org then raise exception 'السرد المجدول غير موجود'; end if;
    -- Refused, never silently overwritten: two teachers may open the same task.
    if v_status <> 'scheduled' then raise exception 'هذا السرد لم يعد متاحاً — ربما رصده معلم آخر'; end if;
    if v_assigned is not null and v_assigned <> auth.uid() and not public.is_org_admin(p_org) then
      raise exception 'هذا السرد مخصّص لمعلم آخر';
    end if;
    update public.serd_sessions set
      examiner_id = auth.uid(), session_date = coalesce(p_date, current_date), status = 'submitted',
      notes = coalesce(nullif(btrim(coalesce(p_notes, '')), ''), notes),
      client_ref = coalesce(p_client_ref, client_ref),
      student_name = coalesce(v_name, student_name)
    where id = p_session_id;
    v_session := p_session_id;
  else
    if v_student is null and v_name is null then raise exception 'اسم الطالب مطلوب'; end if;
    if v_student is not null and not exists (
      select 1 from public.students_profile where id = v_student and organization_id = p_org
    ) then raise exception 'الطالب غير موجود في هذا المركز'; end if;
    insert into public.serd_sessions (organization_id, student_id, student_name, examiner_id, session_date, status, notes, client_ref)
    values (p_org, v_student,
            coalesce(v_name, (select full_name from public.students_profile where id = v_student)),
            auth.uid(), coalesce(p_date, current_date), 'submitted',
            nullif(btrim(coalesce(p_notes, '')), ''), p_client_ref)
    returning id into v_session;
  end if;

  perform public._serd_write_parts(p_org, v_session, v_student, p_parts);
  v_score := public._serd_write_errors(p_org, v_session, p_errors);
  update public.serd_sessions set score_percent = v_score where id = v_session;

  return jsonb_build_object('session_id', v_session, 'duplicate', false, 'score_percent', v_score);
end;
$$;

-- ---------------------------------------------------------------------
-- 10. Admin: schedule, review (approve / reject / link), delete
-- ---------------------------------------------------------------------
create or replace function public.admin_schedule_serd(
  p_org uuid, p_student uuid, p_parts jsonb, p_date date default null,
  p_notes text default null, p_teacher uuid default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then
    raise exception 'الطالب غير موجود في هذا المركز';
  end if;
  -- Checked, not trusted: a task assigned to a non-teacher is invisible to all.
  if p_teacher is not null and not exists (
    select 1 from public.organization_members
    where organization_id = p_org and user_id = p_teacher and role = 'teacher' and status = 'active'
  ) then raise exception 'المعلم المحدّد غير موجود'; end if;

  insert into public.serd_sessions (organization_id, student_id, student_name, session_date, status, notes, assigned_teacher_id)
  values (p_org, p_student, (select full_name from public.students_profile where id = p_student),
          coalesce(p_date, current_date), 'scheduled', nullif(btrim(coalesce(p_notes, '')), ''), p_teacher)
  returning id into v_id;
  perform public._serd_write_parts(p_org, v_id, p_student, p_parts);
  return jsonb_build_object('session_id', v_id);
end;
$$;

create or replace function public.admin_review_serd(
  p_session uuid, p_decision text, p_student uuid default null, p_reason text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_s public.serd_sessions%rowtype; v_student uuid; v_pass numeric; v_points integer := 0;
  v_eighths integer; v_ppj integer; v_passed boolean; v_was_approved boolean;
begin
  select * into v_s from public.serd_sessions where id = p_session for update;
  if not found then raise exception 'السرد غير موجود'; end if;
  if not public.is_org_admin(v_s.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if v_s.status = 'scheduled' then raise exception 'لم يُرصد هذا السرد بعد'; end if;

  v_student := coalesce(p_student, v_s.student_id);
  if p_student is not null and not exists (
    select 1 from public.students_profile where id = p_student and organization_id = v_s.organization_id
  ) then raise exception 'الطالب غير موجود في هذا المركز'; end if;
  v_was_approved := v_s.status = 'approved';

  if p_decision = 'approve' then
    if v_student is null then raise exception 'اربط السرد بطالب قبل اعتماده'; end if;
    if v_s.score_percent is null then raise exception 'لا يمكن اعتماد سرد لم يُرصد بعد'; end if;

    if v_was_approved then
      -- Correcting the link of an already-approved session changes the link and
      -- NOTHING else: never re-price a past session at today's settings.
      update public.serd_sessions set student_id = v_student,
        student_name = coalesce((select full_name from public.students_profile where id = v_student), student_name)
      where id = p_session;
      v_points := v_s.points_awarded;
    else
      v_pass := public.serd_pass_percent(v_s.organization_id, v_student);
      v_passed := v_s.score_percent >= v_pass;
      select coalesce(sum(public.serd_mask_eighths(eighths_mask)), 0) into v_eighths
        from public.serd_session_parts where session_id = p_session;
      select points_per_juz into v_ppj from public.serd_config where organization_id = v_s.organization_id;
      -- Proportional: half a juz is half the points, so two halves never beat one juz.
      v_points := case when v_passed then round(coalesce(v_ppj, 0) * v_eighths / 8.0) else 0 end;
      update public.serd_sessions set
        student_id = v_student,
        student_name = coalesce((select full_name from public.students_profile where id = v_student), student_name),
        status = 'approved', approved_by = auth.uid(), approved_at = now(), reject_reason = null,
        points_awarded = v_points, pass_percent_applied = v_pass
      where id = p_session;
    end if;
  elsif p_decision = 'reject' then
    update public.serd_sessions set status = 'rejected', reject_reason = nullif(btrim(coalesce(p_reason, '')), ''),
      approved_by = auth.uid(), approved_at = now(), points_awarded = 0
    where id = p_session;
  else
    raise exception 'قرار غير معروف';
  end if;

  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (v_s.organization_id, auth.uid(), 'review_serd', 'serd_sessions', p_session,
          jsonb_build_object('decision', p_decision, 'score', v_s.score_percent, 'points', v_points,
                             'was_approved', v_was_approved));
  return jsonb_build_object('session_id', p_session, 'status', p_decision, 'points_awarded', v_points);
end;
$$;

create or replace function public.admin_delete_serd(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_org uuid;
begin
  select organization_id into v_org from public.serd_sessions where id = p_session;
  if v_org is null then raise exception 'السرد غير موجود'; end if;
  if not public.is_org_admin(v_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  delete from public.serd_sessions where id = p_session; -- points trigger reverses the award
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (v_org, auth.uid(), 'delete', 'serd_sessions', p_session);
end;
$$;

-- ---------------------------------------------------------------------
-- 11. Admin: settings (audited - these move every FUTURE grade)
-- ---------------------------------------------------------------------
create or replace function public.set_serd_settings(
  p_org uuid, p_pass_percent numeric, p_points_per_juz integer, p_denominators smallint[]
) returns void language plpgsql security definer set search_path = public as $$
declare v_before jsonb; v_list smallint[];
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if p_pass_percent < 0 or p_pass_percent > 100 then raise exception 'حد النجاح يجب أن يكون بين 0 و 100'; end if;
  if p_points_per_juz < 0 then raise exception 'النقاط لا يمكن أن تكون سالبة'; end if;
  if exists (select 1 from unnest(coalesce(p_denominators, '{}')) d where d not in (1, 2, 4, 8)) then
    raise exception 'المقادير المسموحة هي: الجزء كاملاً، النصف، الربع، الثُمن';
  end if;
  select array_agg(distinct d order by d) into v_list from unnest(coalesce(p_denominators, '{}') || 1::smallint) d;

  perform public.seed_serd_defaults(p_org);
  select to_jsonb(c) - 'organization_id' into v_before from public.serd_config c where organization_id = p_org;
  update public.serd_config set pass_percent = p_pass_percent, points_per_juz = p_points_per_juz,
    allowed_denominators = v_list, updated_at = now() where organization_id = p_org;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, diff)
  values (p_org, auth.uid(), 'update', 'serd_config',
          jsonb_build_object('before', v_before,
            'after', jsonb_build_object('pass_percent', p_pass_percent, 'points_per_juz', p_points_per_juz,
                                        'allowed_denominators', v_list)));
end;
$$;

create or replace function public.save_serd_error_type(
  p_org uuid, p_id uuid, p_name text, p_errors_per_unit integer, p_percent_per_unit numeric,
  p_is_active boolean, p_sort_order integer
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id; v_before jsonb;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if nullif(btrim(coalesce(p_name, '')), '') is null then raise exception 'اسم نوع الخطأ مطلوب'; end if;
  if p_errors_per_unit < 1 then raise exception 'عدد الأخطاء يجب أن يكون 1 أو أكثر'; end if;
  if p_percent_per_unit < 0 or p_percent_per_unit > 100 then raise exception 'النسبة بين 0 و 100'; end if;

  if v_id is null then
    insert into public.serd_error_types (organization_id, name, errors_per_unit, percent_per_unit, is_active, sort_order)
    values (p_org, btrim(p_name), p_errors_per_unit, p_percent_per_unit, coalesce(p_is_active, true), coalesce(p_sort_order, 0))
    returning id into v_id;
  else
    select to_jsonb(e) - 'organization_id' into v_before from public.serd_error_types e
      where id = v_id and organization_id = p_org;
    if v_before is null then raise exception 'نوع الخطأ غير موجود'; end if;
    update public.serd_error_types set name = btrim(p_name), errors_per_unit = p_errors_per_unit,
      percent_per_unit = p_percent_per_unit, is_active = coalesce(p_is_active, true),
      sort_order = coalesce(p_sort_order, sort_order)
    where id = v_id and organization_id = p_org;
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), case when p_id is null then 'create' else 'update' end, 'serd_error_types', v_id,
          jsonb_build_object('before', v_before, 'after', jsonb_build_object('name', btrim(p_name),
            'errors_per_unit', p_errors_per_unit, 'percent_per_unit', p_percent_per_unit, 'is_active', p_is_active)));
  return v_id;
end;
$$;

create or replace function public.delete_serd_error_type(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  delete from public.serd_error_types where id = p_id and organization_id = p_org;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), 'delete', 'serd_error_types', p_id);
end;
$$;

-- Per-stage override. Both NULL/empty removes the override.
create or replace function public.set_serd_stage_policy(
  p_org uuid, p_stage uuid, p_denominators smallint[], p_pass_percent numeric
) returns void language plpgsql security definer set search_path = public as $$
declare v_list smallint[];
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if not exists (select 1 from public.stages where id = p_stage and organization_id = p_org) then
    raise exception 'المرحلة غير موجودة';
  end if;
  if p_pass_percent is not null and (p_pass_percent < 0 or p_pass_percent > 100) then
    raise exception 'حد النجاح بين 0 و 100';
  end if;
  if exists (select 1 from unnest(coalesce(p_denominators, '{}')) d where d not in (1, 2, 4, 8)) then
    raise exception 'مقدار غير صالح';
  end if;
  if p_pass_percent is null and coalesce(array_length(p_denominators, 1), 0) = 0 then
    delete from public.serd_stage_portions where stage_id = p_stage and organization_id = p_org;
  else
    select array_agg(distinct d order by d) into v_list from unnest(coalesce(p_denominators, '{}') || 1::smallint) d;
    insert into public.serd_stage_portions (organization_id, stage_id, allowed_denominators, pass_percent)
    values (p_org, p_stage, v_list, p_pass_percent)
    on conflict (stage_id) do update set allowed_denominators = excluded.allowed_denominators,
      pass_percent = excluded.pass_percent, updated_at = now();
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'serd_stage_portions', p_stage,
          jsonb_build_object('allowed_denominators', v_list, 'pass_percent', p_pass_percent));
end;
$$;

-- ---------------------------------------------------------------------
-- 12. Reads
-- ---------------------------------------------------------------------
create or replace function public._serd_parts_json(p_session uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'juz', p.juz_number, 'juz_name', coalesce(jr.name, ''), 'den', p.portion_den, 'index', p.portion_index,
      'eighths', 8 / p.portion_den, 'label', public.serd_portion_label(p.portion_den, p.portion_index))
    order by p.juz_number desc, p.portion_index), '[]'::jsonb)
  from public.serd_session_parts p left join public.juz_reference jr on jr.number = p.juz_number
  where p.session_id = p_session;
$$;
revoke all on function public._serd_parts_json(uuid) from public, anon, authenticated;

create or replace function public._serd_row_json(p_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', s.id, 'student_id', s.student_id, 'student_name', s.student_name,
    'student_code', sp.student_code, 'circle_name', c.name,
    'circle_teacher_name', ct.full_name,
    'examiner_name', ex.full_name, 'assigned_teacher_name', asg.full_name,
    'assigned_teacher_id', s.assigned_teacher_id,
    'session_date', s.session_date, 'status', s.status, 'score_percent', s.score_percent,
    'points_awarded', s.points_awarded, 'pass_percent_applied', s.pass_percent_applied,
    'notes', s.notes, 'reject_reason', s.reject_reason,
    'parts', public._serd_parts_json(s.id),
    'total_eighths', coalesce((select sum(public.serd_mask_eighths(eighths_mask)) from public.serd_session_parts where session_id = s.id), 0),
    'errors', coalesce((select jsonb_agg(jsonb_build_object('name', e.type_name, 'count', e.error_count, 'deducted', e.deducted_percent) order by e.type_name)
                        from public.serd_session_errors e where e.session_id = s.id), '[]'::jsonb))
  from public.serd_sessions s
  left join public.students_profile sp on sp.id = s.student_id
  left join public.circles c on c.id = sp.circle_id
  left join public.profiles ct on ct.id = c.teacher_id
  left join public.profiles ex on ex.id = s.examiner_id
  left join public.profiles asg on asg.id = s.assigned_teacher_id
  where s.id = p_id;
$$;
revoke all on function public._serd_row_json(uuid) from public, anon, authenticated;

-- The admin's queue (waiting work first), pageable.
create or replace function public.admin_serd_list(
  p_org uuid, p_status text default null, p_from date default null, p_to date default null,
  p_search text default null, p_limit integer default 100, p_offset integer default 0
) returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_total bigint; v_rows jsonb;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  select count(*) into v_total from public.serd_sessions s
   where s.organization_id = p_org and (p_status is null or s.status = p_status)
     and (p_from is null or s.session_date >= p_from) and (p_to is null or s.session_date <= p_to)
     and (p_search is null or btrim(p_search) = '' or s.student_name ilike '%' || p_search || '%');

  select coalesce(jsonb_agg(public._serd_row_json(t.id) order by
      case t.status when 'submitted' then 0 when 'scheduled' then 1 else 2 end, t.session_date desc, t.created_at desc), '[]'::jsonb)
    into v_rows
  from (
    select s.* from public.serd_sessions s
     where s.organization_id = p_org and (p_status is null or s.status = p_status)
       and (p_from is null or s.session_date >= p_from) and (p_to is null or s.session_date <= p_to)
       and (p_search is null or btrim(p_search) = '' or s.student_name ilike '%' || p_search || '%')
     order by case s.status when 'submitted' then 0 when 'scheduled' then 1 else 2 end, s.session_date desc, s.created_at desc
     limit greatest(1, least(coalesce(p_limit, 100), 500)) offset greatest(0, coalesce(p_offset, 0))
  ) t;
  return jsonb_build_object('total', v_total, 'rows', v_rows);
end;
$$;

-- Open tasks (or assigned to me). Overdue ones sort below live ones and drop
-- off a teacher's list after 60 days (they stay in the admin queue).
create or replace function public.teacher_scheduled_serd(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._assert_serd_grader(p_org);
  return coalesce((
    select jsonb_agg(public._serd_row_json(t.id) || jsonb_build_object(
             'assigned_to_me', t.assigned_teacher_id = auth.uid(), 'overdue', t.session_date < current_date)
           order by (t.assigned_teacher_id = auth.uid()) desc nulls last,
                    (t.session_date < current_date) asc, t.session_date asc)
    from (
      select s.* from public.serd_sessions s
      where s.organization_id = p_org and s.status = 'scheduled'
        and s.session_date >= current_date - 60
        and (public.is_org_admin(p_org) or s.assigned_teacher_id is null or s.assigned_teacher_id = auth.uid())
    ) t), '[]'::jsonb);
end;
$$;

-- What I graded (the examiner's own list, newest first).
create or replace function public.teacher_my_serd(p_org uuid, p_limit integer default 60)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._assert_serd_grader(p_org);
  return coalesce((
    select jsonb_agg(public._serd_row_json(t.id) order by t.session_date desc, t.created_at desc)
    from (
      select s.* from public.serd_sessions s
      where s.organization_id = p_org and s.examiner_id = auth.uid() and s.status <> 'scheduled'
      order by s.session_date desc, s.created_at desc
      limit greatest(1, least(coalesce(p_limit, 60), 200))
    ) t), '[]'::jsonb);
end;
$$;

-- One student's APPROVED record. A juz counts as done only when all eight of
-- its eighths are covered (two different halves complete a juz; the same half
-- twice does not) - a partial recital must never read as a whole juz.
create or replace function public.serd_student_summary(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_result jsonb;
begin
  if not (
    public.is_org_admin(p_org)
    or public.member_has_module(p_org, 'serd')
    or p_student = any (public.linked_student_ids(p_org))
  ) then raise exception 'غير مصرّح'; end if;
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then
    raise exception 'الطالب غير موجود';
  end if;

  with approved as (
    select id from public.serd_sessions where student_id = p_student and organization_id = p_org and status = 'approved'
  ), coverage as (
    select p.juz_number as juz, bit_or(p.eighths_mask::int) as mask
    from public.serd_session_parts p join approved a on a.id = p.session_id group by p.juz_number
  )
  select jsonb_build_object(
    'sessions_count', (select count(*) from approved),
    'average_score', (select round(avg(score_percent), 1) from public.serd_sessions where id in (select id from approved)),
    'best_score', (select max(score_percent) from public.serd_sessions where id in (select id from approved)),
    'last_date', (select max(session_date) from public.serd_sessions where id in (select id from approved)),
    'total_points', (select coalesce(sum(points_awarded), 0) from public.serd_sessions where id in (select id from approved)),
    'juz_done', coalesce((select jsonb_agg(juz order by juz desc) from coverage where mask = 255), '[]'::jsonb),
    'juz_progress', coalesce((select jsonb_agg(jsonb_build_object('juz', c.juz, 'juz_name', coalesce(jr.name, ''),
                       'eighths', public.serd_mask_eighths(c.mask::smallint)) order by c.juz desc)
                     from coverage c left join public.juz_reference jr on jr.number = c.juz where c.mask <> 255), '[]'::jsonb),
    'eighths_total', coalesce((select sum(public.serd_mask_eighths(mask::smallint)) from coverage), 0),
    'sessions', coalesce((select jsonb_agg(public._serd_row_json(t.id) order by t.session_date desc)
                          from (select s.* from public.serd_sessions s
                                where s.id in (select id from approved) order by s.session_date desc limit 30) t), '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

-- Report over a date range; every figure measures APPROVED sessions only.
create or replace function public.admin_serd_report(p_org uuid, p_from date default null, p_to date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_from date := coalesce(p_from, current_date - 30); v_to date := coalesce(p_to, current_date);
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return (
    select jsonb_build_object(
      'from', v_from, 'to', v_to,
      'total', count(*),
      'approved', count(*) filter (where status = 'approved'),
      'pending', count(*) filter (where status in ('submitted', 'scheduled')),
      'rejected', count(*) filter (where status = 'rejected'),
      'average_score', round(avg(score_percent) filter (where status = 'approved'), 1),
      'students', count(distinct student_id) filter (where status = 'approved'),
      'points', coalesce(sum(points_awarded) filter (where status = 'approved'), 0),
      'by_juz', coalesce((select jsonb_agg(jsonb_build_object('juz', j.juz, 'count', j.n) order by j.juz desc)
          from (select p.juz_number as juz, count(distinct p.session_id) as n
                from public.serd_session_parts p join public.serd_sessions s2 on s2.id = p.session_id
                where s2.organization_id = p_org and s2.status = 'approved' and s2.session_date between v_from and v_to
                group by 1) j), '[]'::jsonb),
      'by_error_type', coalesce((select jsonb_agg(jsonb_build_object('name', e.type_name, 'total', e.total, 'sessions', e.n) order by e.total desc)
          from (select se.type_name, sum(se.error_count) as total, count(*) as n
                from public.serd_session_errors se join public.serd_sessions s3 on s3.id = se.session_id
                where s3.organization_id = p_org and s3.status = 'approved' and s3.session_date between v_from and v_to
                group by se.type_name) e), '[]'::jsonb),
      'by_examiner', coalesce((select jsonb_agg(jsonb_build_object('name', x.name, 'count', x.n) order by x.n desc)
          from (select coalesce(pr.full_name, '—') as name, count(*) as n
                from public.serd_sessions s4 left join public.profiles pr on pr.id = s4.examiner_id
                where s4.organization_id = p_org and s4.status <> 'scheduled' and s4.session_date between v_from and v_to
                group by 1) x), '[]'::jsonb)
    )
    from public.serd_sessions where organization_id = p_org and session_date between v_from and v_to
  );
end;
$$;

-- ---------------------------------------------------------------------
-- 13. Grants (0018 policy: authenticated only)
-- ---------------------------------------------------------------------
revoke all on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated, service_role;
grant execute on function public.get_invitation(uuid) to anon;
revoke execute on function public._serd_write_parts(uuid, uuid, uuid, jsonb) from authenticated;
revoke execute on function public._serd_write_errors(uuid, uuid, jsonb) from authenticated;
revoke execute on function public._assert_serd_grader(uuid) from authenticated;
revoke execute on function public._serd_parts_json(uuid) from authenticated;
revoke execute on function public._serd_row_json(uuid) from authenticated;
