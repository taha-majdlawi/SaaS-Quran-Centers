-- =========================================================================
-- 0007_platform_and_admin.sql
-- Governance & platform-operations tables. Maps legacy: feature_flags,
-- account_access, deletion_requests, audit log (new - legacy web project
-- had per-module ad-hoc logging), site_settings.
-- =========================================================================

-- null organization_id = platform-wide default (can be overridden per org).
create table public.feature_flags (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid references public.organizations (id) on delete cascade,
  key              text not null,
  enabled          boolean not null default false,
  unique (organization_id, key)
);

-- Read-only / demo accounts, and the ability to deactivate a member without
-- deleting them (mirrors legacy `account_access`).
create table public.account_access (
  user_id          uuid not null references auth.users (id) on delete cascade,
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  is_active        boolean not null default true,
  is_read_only     boolean not null default false,
  primary key (user_id, organization_id)
);

create type public.deletion_requester_type as enum ('student', 'guardian', 'teacher', 'admin');
create type public.deletion_status as enum ('pending', 'approved', 'rejected', 'completed');

create table public.deletion_requests (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations (id) on delete cascade,
  requester_type    public.deletion_requester_type not null,
  requester_id      uuid references auth.users (id),
  target_user_id    uuid references auth.users (id),
  target_student_id uuid references public.students_profile (id),
  reason            text,
  status            public.deletion_status not null default 'pending',
  reviewed_by       uuid references auth.users (id),
  created_at        timestamptz not null default now(),
  reviewed_at       timestamptz
);

create table public.audit_log (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  actor_id         uuid references auth.users (id),
  action           text not null,             -- e.g. 'update', 'delete'
  entity_table     text not null,
  entity_id        uuid,
  diff             jsonb,
  created_at       timestamptz not null default now()
);

create index audit_log_org_idx on public.audit_log (organization_id, created_at desc);

-- Drives each tenant's own public info page (replaces legacy `site_settings`
-- powering the static landing page content).
create table public.site_settings (
  organization_id       uuid primary key references public.organizations (id) on delete cascade,
  public_site_enabled   boolean not null default false,
  hero_title            text,
  hero_body             text,
  contact_email         text,
  updated_at            timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.feature_flags enable row level security;
alter table public.account_access enable row level security;
alter table public.deletion_requests enable row level security;
alter table public.audit_log enable row level security;
alter table public.site_settings enable row level security;

create policy "feature_flags_select" on public.feature_flags for select using (
  organization_id is null or public.is_org_member(organization_id)
);
create policy "feature_flags_write_platform_owner" on public.feature_flags for all
  using (organization_id is null and public.is_platform_owner())
  with check (organization_id is null and public.is_platform_owner());
create policy "feature_flags_write_org_admin" on public.feature_flags for all
  using (organization_id is not null and public.is_org_admin(organization_id))
  with check (organization_id is not null and public.is_org_admin(organization_id));

create policy "account_access_select" on public.account_access for select using (
  user_id = auth.uid() or public.is_org_admin(organization_id)
);
create policy "account_access_write_admin" on public.account_access for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "deletion_requests_select" on public.deletion_requests for select using (
  requester_id = auth.uid() or target_user_id = auth.uid() or public.is_org_admin(organization_id)
);
create policy "deletion_requests_insert_member" on public.deletion_requests for insert with check (
  public.is_org_member(organization_id) and requester_id = auth.uid()
);
create policy "deletion_requests_review_admin" on public.deletion_requests for update
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "audit_log_select_admin" on public.audit_log for select using (public.is_org_admin(organization_id));
create policy "audit_log_insert_staff" on public.audit_log for insert with check (public.is_org_staff(organization_id));

create policy "site_settings_select_public_or_member" on public.site_settings for select using (
  public_site_enabled = true or public.is_org_member(organization_id)
);
create policy "site_settings_write_admin" on public.site_settings for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));
