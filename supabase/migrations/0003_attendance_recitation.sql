-- =========================================================================
-- 0003_attendance_recitation.sql
-- Attendance, memorization log, and the "Serd" (سرد) recitation-exam
-- subsystem. Maps legacy: attendance, attendance_gatherings,
-- daily_achievements, serd_*, juz_reference, student_notes.
-- =========================================================================

create type public.attendance_status as enum ('present', 'absent', 'excused', 'late');

create table public.attendance (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  student_id       uuid not null references public.students_profile (id) on delete cascade,
  circle_id        uuid references public.circles (id) on delete set null,
  session_date     date not null,
  status           public.attendance_status not null default 'present',
  recorded_by      uuid references auth.users (id),
  created_at       timestamptz not null default now(),
  unique (student_id, session_date)
);

create index attendance_org_idx on public.attendance (organization_id);

-- One-off gatherings (trips, exam days, special sessions) distinct from
-- regular circle attendance.
create table public.attendance_gatherings (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  title            text not null,
  occurred_on      date not null,
  created_by       uuid references auth.users (id),
  created_at       timestamptz not null default now()
);

create table public.attendance_gathering_entries (
  id            uuid primary key default gen_random_uuid(),
  gathering_id  uuid not null references public.attendance_gatherings (id) on delete cascade,
  student_id    uuid not null references public.students_profile (id) on delete cascade,
  status        public.attendance_status not null default 'present',
  created_at    timestamptz not null default now(),
  unique (gathering_id, student_id)
);

-- ---------------------------------------------------------------------
-- Daily memorization / review log. `points_awarded` is captured at write
-- time (frozen) so later changes to points_config don't rewrite history.
-- ---------------------------------------------------------------------
create type public.achievement_type as enum ('new_memorization', 'recent_review', 'distant_review');

create table public.daily_achievements (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  student_id       uuid not null references public.students_profile (id) on delete cascade,
  circle_id        uuid references public.circles (id) on delete set null,
  achievement_type public.achievement_type not null,
  surah_from       smallint,
  ayah_from        smallint,
  surah_to         smallint,
  ayah_to          smallint,
  grade            numeric(4, 1),
  points_awarded   integer not null default 0,
  recorded_by      uuid references auth.users (id),
  created_at       timestamptz not null default now()
);

create index daily_achievements_org_idx on public.daily_achievements (organization_id);
create index daily_achievements_student_idx on public.daily_achievements (student_id);

-- Global reference data: Quran structure is the same for every tenant.
create table public.juz_reference (
  number  smallint primary key,
  name    text not null
);

alter table public.juz_reference enable row level security;
create policy "juz_reference_select_authenticated" on public.juz_reference
  for select using (auth.role() = 'authenticated');

-- Staff-authored notes on a student, optionally visible to guardians.
create table public.student_notes (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  student_id       uuid not null references public.students_profile (id) on delete cascade,
  author_id        uuid references auth.users (id),
  body             text not null,
  visibility       text not null default 'staff_only' check (visibility in ('staff_only', 'guardian_visible')),
  created_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Serd (سرد) - full/partial recitation exam subsystem
-- ---------------------------------------------------------------------
create table public.serd_config (
  organization_id  uuid primary key references public.organizations (id) on delete cascade,
  settings         jsonb not null default '{}',
  updated_at       timestamptz not null default now()
);

create table public.serd_stage_portions (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  stage_id         uuid references public.stages (id) on delete cascade,
  description      text not null,
  sort_order       integer not null default 0
);

create table public.serd_error_types (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  name             text not null,
  penalty_points   integer not null default 0
);

create type public.serd_session_type as enum ('full', 'partial');
create type public.serd_session_status as enum ('pending', 'scheduled', 'in_progress', 'completed', 'cancelled');

create table public.serd_sessions (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  student_id       uuid not null references public.students_profile (id) on delete cascade,
  circle_id        uuid references public.circles (id) on delete set null,
  session_type     public.serd_session_type not null default 'partial',
  status           public.serd_session_status not null default 'pending',
  scheduled_at     timestamptz,
  examiner_id      uuid references auth.users (id),
  created_at       timestamptz not null default now()
);

create index serd_sessions_org_idx on public.serd_sessions (organization_id);

create table public.serd_session_parts (
  id          uuid primary key default gen_random_uuid(),
  session_id  uuid not null references public.serd_sessions (id) on delete cascade,
  portion_id  uuid references public.serd_stage_portions (id),
  grade       numeric(4, 1)
);

create table public.serd_session_errors (
  id             uuid primary key default gen_random_uuid(),
  session_id     uuid not null references public.serd_sessions (id) on delete cascade,
  error_type_id  uuid references public.serd_error_types (id),
  count          integer not null default 1,
  note           text
);

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.attendance enable row level security;
alter table public.attendance_gatherings enable row level security;
alter table public.attendance_gathering_entries enable row level security;
alter table public.daily_achievements enable row level security;
alter table public.student_notes enable row level security;
alter table public.serd_config enable row level security;
alter table public.serd_stage_portions enable row level security;
alter table public.serd_error_types enable row level security;
alter table public.serd_sessions enable row level security;
alter table public.serd_session_parts enable row level security;
alter table public.serd_session_errors enable row level security;

create policy "attendance_select_org" on public.attendance for select using (public.is_org_member(organization_id));
create policy "attendance_write_staff" on public.attendance for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "gatherings_select_org" on public.attendance_gatherings for select using (public.is_org_member(organization_id));
create policy "gatherings_write_staff" on public.attendance_gatherings for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "gathering_entries_select" on public.attendance_gathering_entries for select using (
  exists (select 1 from public.attendance_gatherings g where g.id = gathering_id and public.is_org_member(g.organization_id))
);
create policy "gathering_entries_write" on public.attendance_gathering_entries for all using (
  exists (select 1 from public.attendance_gatherings g where g.id = gathering_id and public.is_org_staff(g.organization_id))
) with check (
  exists (select 1 from public.attendance_gatherings g where g.id = gathering_id and public.is_org_staff(g.organization_id))
);

create policy "daily_achievements_select_org" on public.daily_achievements for select using (public.is_org_member(organization_id));
create policy "daily_achievements_write_staff" on public.daily_achievements for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "student_notes_select_staff" on public.student_notes for select using (
  public.is_org_staff(organization_id)
  or (visibility = 'guardian_visible' and exists (
    select 1 from public.students_profile s
    join public.organization_members m on m.id = s.guardian_member_id
    where s.id = student_id and m.user_id = auth.uid()
  ))
);
create policy "student_notes_write_staff" on public.student_notes for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "serd_config_select_org" on public.serd_config for select using (public.is_org_member(organization_id));
create policy "serd_config_write_admin" on public.serd_config for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "serd_portions_select_org" on public.serd_stage_portions for select using (public.is_org_member(organization_id));
create policy "serd_portions_write_admin" on public.serd_stage_portions for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "serd_error_types_select_org" on public.serd_error_types for select using (public.is_org_member(organization_id));
create policy "serd_error_types_write_admin" on public.serd_error_types for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "serd_sessions_select_org" on public.serd_sessions for select using (public.is_org_member(organization_id));
create policy "serd_sessions_write_staff" on public.serd_sessions for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "serd_session_parts_select" on public.serd_session_parts for select using (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.is_org_member(s.organization_id))
);
create policy "serd_session_parts_write" on public.serd_session_parts for all using (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.is_org_staff(s.organization_id))
) with check (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.is_org_staff(s.organization_id))
);

create policy "serd_session_errors_select" on public.serd_session_errors for select using (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.is_org_member(s.organization_id))
);
create policy "serd_session_errors_write" on public.serd_session_errors for all using (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.is_org_staff(s.organization_id))
) with check (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.is_org_staff(s.organization_id))
);
