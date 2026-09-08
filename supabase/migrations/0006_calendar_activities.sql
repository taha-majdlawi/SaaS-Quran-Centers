-- =========================================================================
-- 0006_calendar_activities.sql
-- Center calendar, event registration, and general activities.
-- Maps legacy: center_calendar, calendar_entry_types, calendar_registrations,
-- calendar_waitlist (merged into calendar_registrations.status below -
-- see docs/DATA_MODEL.md), activities, activity_types.
-- "gatherings" (legacy admin module) maps to attendance_gatherings (0003).
-- =========================================================================

create table public.calendar_entry_types (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  name             text not null,
  color            text default '#0f766e'
);

create table public.center_calendar (
  id                         uuid primary key default gen_random_uuid(),
  organization_id            uuid not null references public.organizations (id) on delete cascade,
  type_id                    uuid references public.calendar_entry_types (id) on delete set null,
  title                      text not null,
  description                text,
  starts_at                  timestamptz not null,
  ends_at                    timestamptz,
  location                   text,
  requires_guardian_consent  boolean not null default false,
  image_url                  text,
  created_by                 uuid references auth.users (id),
  created_at                 timestamptz not null default now()
);

create index center_calendar_org_idx on public.center_calendar (organization_id, starts_at);

create table public.calendar_registrations (
  id            uuid primary key default gen_random_uuid(),
  event_id      uuid not null references public.center_calendar (id) on delete cascade,
  student_id    uuid not null references public.students_profile (id) on delete cascade,
  status        text not null default 'registered' check (status in ('registered', 'waitlisted', 'cancelled')),
  consented_by  uuid references public.organization_members (id),
  created_at    timestamptz not null default now(),
  unique (event_id, student_id)
);

create table public.activity_types (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  name             text not null
);

create table public.activities (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  type_id          uuid references public.activity_types (id) on delete set null,
  title            text not null,
  description      text,
  scheduled_at     timestamptz,
  created_by       uuid references auth.users (id),
  created_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.calendar_entry_types enable row level security;
alter table public.center_calendar enable row level security;
alter table public.calendar_registrations enable row level security;
alter table public.activity_types enable row level security;
alter table public.activities enable row level security;

create policy "calendar_entry_types_select_org" on public.calendar_entry_types for select using (public.is_org_member(organization_id));
create policy "calendar_entry_types_write_admin" on public.calendar_entry_types for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "center_calendar_select_org" on public.center_calendar for select using (public.is_org_member(organization_id));
create policy "center_calendar_write_staff" on public.center_calendar for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "calendar_registrations_select" on public.calendar_registrations for select using (
  exists (select 1 from public.center_calendar e where e.id = event_id and public.is_org_member(e.organization_id))
);
create policy "calendar_registrations_write_staff" on public.calendar_registrations for all using (
  exists (select 1 from public.center_calendar e where e.id = event_id and public.is_org_staff(e.organization_id))
) with check (
  exists (select 1 from public.center_calendar e where e.id = event_id and public.is_org_staff(e.organization_id))
);
create policy "calendar_registrations_guardian_consent" on public.calendar_registrations for insert with check (
  exists (
    select 1 from public.students_profile s
    join public.organization_members m on m.id = s.guardian_member_id
    where s.id = student_id and m.user_id = auth.uid()
  )
);

create policy "activity_types_select_org" on public.activity_types for select using (public.is_org_member(organization_id));
create policy "activity_types_write_admin" on public.activity_types for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "activities_select_org" on public.activities for select using (public.is_org_member(organization_id));
create policy "activities_write_staff" on public.activities for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));
