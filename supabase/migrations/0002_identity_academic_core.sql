-- =========================================================================
-- 0002_identity_academic_core.sql
-- Global identity + per-organization academic structure (stages, circles,
-- student records). Maps legacy: profiles, stages, circles, students_profile.
-- =========================================================================

-- ---------------------------------------------------------------------
-- Global identity. One row per auth user, NOT organization-scoped -
-- role now lives on organization_members since a user can belong to
-- several organizations (legacy kept role directly on profiles because
-- it was single-tenant).
-- ---------------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text,
  avatar_url  text,
  phone       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

create policy "profiles_select_shared_org" on public.profiles
  for select using (
    id = auth.uid()
    or exists (
      select 1
      from public.organization_members me
      join public.organization_members them on them.organization_id = me.organization_id
      where me.user_id = auth.uid() and them.user_id = public.profiles.id
    )
    or public.is_platform_owner()
  );

create policy "profiles_update_self" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- ---------------------------------------------------------------------
-- Academic structure
-- ---------------------------------------------------------------------
create table public.stages (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  name             text not null,
  sort_order       integer not null default 0,
  created_at       timestamptz not null default now(),
  unique (organization_id, name)
);

create table public.circles (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  stage_id         uuid references public.stages (id) on delete set null,
  teacher_id       uuid references auth.users (id) on delete set null,
  name             text not null,
  capacity         integer,
  schedule         jsonb not null default '{}',   -- e.g. {"days": ["sun","tue"], "time": "16:00"}
  status           text not null default 'active' check (status in ('active', 'archived')),
  created_at       timestamptz not null default now()
);

create index circles_org_idx on public.circles (organization_id);
create index circles_teacher_idx on public.circles (teacher_id);

-- ---------------------------------------------------------------------
-- Students. Kept as a distinct record from organization_members because
-- (like legacy) not every student has a login - a guardian's account can
-- represent them, or the center enters them purely as a roster entry.
-- ---------------------------------------------------------------------
create table public.students_profile (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null references public.organizations (id) on delete cascade,
  student_code        text not null,             -- center-issued ID, matches legacy behaviour
  full_name           text not null,
  birth_date          date,
  circle_id           uuid references public.circles (id) on delete set null,
  member_id           uuid references public.organization_members (id) on delete set null, -- student's own login, if any
  guardian_member_id  uuid references public.organization_members (id) on delete set null,
  status              text not null default 'active' check (status in ('active', 'paused', 'graduated', 'withdrawn')),
  created_at          timestamptz not null default now(),
  unique (organization_id, student_code)
);

create index students_profile_org_idx on public.students_profile (organization_id);
create index students_profile_circle_idx on public.students_profile (circle_id);
create index students_profile_guardian_idx on public.students_profile (guardian_member_id);

-- ---------------------------------------------------------------------
-- RLS - standard convention: staff (teacher/admin) manage, everyone in
-- the org can read, students/guardians are further restricted to their
-- own record via policies added once auth wiring lands (left permissive
-- at the org level here as the structural starting point).
-- ---------------------------------------------------------------------
alter table public.stages enable row level security;
alter table public.circles enable row level security;
alter table public.students_profile enable row level security;

create policy "stages_select_org" on public.stages for select using (public.is_org_member(organization_id));
create policy "stages_write_admin" on public.stages for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "circles_select_org" on public.circles for select using (public.is_org_member(organization_id));
create policy "circles_write_staff" on public.circles for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "students_profile_select_staff_or_family" on public.students_profile
  for select using (
    public.is_org_staff(organization_id)
    or guardian_member_id in (select id from public.organization_members where user_id = auth.uid())
    or member_id in (select id from public.organization_members where user_id = auth.uid())
  );

create policy "students_profile_write_staff" on public.students_profile for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));
