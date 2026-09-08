-- =========================================================================
-- 0001_core_tenancy.sql
-- Foundation of the multi-tenant model. Every domain table added in later
-- migrations carries an `organization_id` and follows the RLS convention
-- established here:
--   * SELECT   -> public.is_org_member(organization_id) or platform owner
--   * WRITE    -> public.is_org_admin(organization_id)  or platform owner
--                 (relaxed per-table where students/teachers need write access)
-- =========================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- Roles
-- ---------------------------------------------------------------------
-- 'guardian' is new vs. the legacy single-tenant schema (legacy only had
-- student/teacher/admin; guardians were an ad-hoc `requester_type` value).
-- The web project's parent-consent / parent-progress pages show guardians
-- were already a real audience, so they become a first-class role here.
create type public.user_role as enum ('student', 'teacher', 'admin', 'guardian');

-- ---------------------------------------------------------------------
-- Organizations (tenants). One row = one Quran center.
-- ---------------------------------------------------------------------
create table public.organizations (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  slug             text not null unique,          -- used for subdomain: {slug}.quran-centers.app
  logo_url         text,
  primary_color    text default '#0f766e',
  secondary_color  text default '#f59e0b',
  locale           text not null default 'ar',
  timezone         text not null default 'Asia/Amman',
  status           text not null default 'trial'
                     check (status in ('trial', 'active', 'suspended', 'cancelled')),
  plan_id          uuid,
  trial_ends_at    timestamptz default (now() + interval '14 days'),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

comment on table public.organizations is 'A tenant: one Quran memorization center.';

-- ---------------------------------------------------------------------
-- Billing scaffold (kept minimal on purpose - wire up a real provider later)
-- ---------------------------------------------------------------------
create table public.plans (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique,             -- e.g. 'starter', 'growth', 'enterprise'
  name          text not null,
  price_cents   integer not null default 0,
  currency      text not null default 'USD',
  limits        jsonb not null default '{}',       -- e.g. {"max_students": 100, "max_teachers": 10}
  features      jsonb not null default '{}',       -- feature-flag defaults granted by this plan
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

alter table public.organizations
  add constraint organizations_plan_fk foreign key (plan_id) references public.plans (id);

create table public.subscriptions (
  id                      uuid primary key default gen_random_uuid(),
  organization_id         uuid not null references public.organizations (id) on delete cascade,
  plan_id                 uuid not null references public.plans (id),
  billing_provider        text not null default 'manual' check (billing_provider in ('manual', 'stripe')),
  external_customer_id    text,
  external_subscription_id text,
  status                  text not null default 'active'
                            check (status in ('trialing', 'active', 'past_due', 'cancelled')),
  current_period_end      timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index subscriptions_org_idx on public.subscriptions (organization_id);

-- ---------------------------------------------------------------------
-- Platform-level (cross-tenant) access - mirrors legacy `platform_owners`,
-- deliberately kept out of `user_role` so it can never be assigned per-org.
-- ---------------------------------------------------------------------
create table public.platform_owners (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now()
);

comment on table public.platform_owners is 'SaaS operators with cross-tenant access. Not an organization_members role.';

-- ---------------------------------------------------------------------
-- Organization membership - replaces legacy global `profiles.role`.
-- A user can belong to more than one organization (e.g. a teacher who
-- also runs their own center, or a guardian with children at two centers).
-- ---------------------------------------------------------------------
create table public.organization_members (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  user_id          uuid not null references auth.users (id) on delete cascade,
  role             public.user_role not null,
  status           text not null default 'active' check (status in ('invited', 'active', 'suspended')),
  invited_by       uuid references auth.users (id),
  created_at       timestamptz not null default now(),
  unique (organization_id, user_id)
);

create index organization_members_user_idx on public.organization_members (user_id);
create index organization_members_org_idx on public.organization_members (organization_id);

create table public.organization_invitations (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  email            text not null,
  role             public.user_role not null,
  token            uuid not null default gen_random_uuid(),
  invited_by       uuid references auth.users (id),
  expires_at       timestamptz not null default (now() + interval '7 days'),
  accepted_at      timestamptz,
  created_at       timestamptz not null default now(),
  unique (organization_id, email, role)
);

-- Grants admin-level capability to a member without changing their stored
-- role (mirrors legacy `account_admin_grants`, e.g. a teacher acting as admin).
create table public.account_admin_grants (
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  user_id          uuid not null references auth.users (id) on delete cascade,
  granted_by       uuid references auth.users (id),
  granted_at       timestamptz not null default now(),
  primary key (organization_id, user_id)
);

-- ---------------------------------------------------------------------
-- Helper functions (security definer so RLS policies can call them cheaply)
-- ---------------------------------------------------------------------
create or replace function public.is_platform_owner()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.platform_owners where user_id = auth.uid());
$$;

create or replace function public.current_user_org_ids()
returns setof uuid
language sql stable security definer set search_path = public as $$
  select organization_id from public.organization_members
  where user_id = auth.uid() and status = 'active';
$$;

create or replace function public.is_org_member(org uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.organization_members
    where organization_id = org and user_id = auth.uid() and status = 'active'
  ) or public.is_platform_owner();
$$;

create or replace function public.current_role_in_org(org uuid)
returns public.user_role
language sql stable security definer set search_path = public as $$
  select role from public.organization_members
  where organization_id = org and user_id = auth.uid() and status = 'active'
  limit 1;
$$;

create or replace function public.is_org_admin(org uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select public.current_role_in_org(org) = 'admin'
    or exists (
      select 1 from public.account_admin_grants
      where organization_id = org and user_id = auth.uid()
    )
    or public.is_platform_owner();
$$;

create or replace function public.is_org_staff(org uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select public.current_role_in_org(org) in ('admin', 'teacher') or public.is_org_admin(org);
$$;

-- ---------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------
alter table public.organizations enable row level security;
alter table public.plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.platform_owners enable row level security;
alter table public.organization_members enable row level security;
alter table public.organization_invitations enable row level security;
alter table public.account_admin_grants enable row level security;

create policy "organizations_select_member_or_owner" on public.organizations
  for select using (public.is_org_member(id));

create policy "organizations_insert_platform_owner" on public.organizations
  for insert with check (public.is_platform_owner());

create policy "organizations_update_admin" on public.organizations
  for update using (public.is_org_admin(id)) with check (public.is_org_admin(id));

create policy "plans_select_all_authenticated" on public.plans
  for select using (auth.role() = 'authenticated');

create policy "plans_write_platform_owner" on public.plans
  for all using (public.is_platform_owner()) with check (public.is_platform_owner());

create policy "subscriptions_select_org" on public.subscriptions
  for select using (public.is_org_member(organization_id));

create policy "subscriptions_write_platform_owner" on public.subscriptions
  for all using (public.is_platform_owner()) with check (public.is_platform_owner());

create policy "platform_owners_select_self" on public.platform_owners
  for select using (user_id = auth.uid() or public.is_platform_owner());

create policy "organization_members_select_own_org" on public.organization_members
  for select using (public.is_org_member(organization_id));

create policy "organization_members_write_admin" on public.organization_members
  for insert with check (public.is_org_admin(organization_id));

create policy "organization_members_update_admin" on public.organization_members
  for update using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "organization_members_delete_admin" on public.organization_members
  for delete using (public.is_org_admin(organization_id));

create policy "invitations_admin_only" on public.organization_invitations
  for all using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "admin_grants_admin_only" on public.account_admin_grants
  for all using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

-- ---------------------------------------------------------------------
-- updated_at trigger, reused by every later migration
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger organizations_set_updated_at
  before update on public.organizations
  for each row execute function public.set_updated_at();

create trigger subscriptions_set_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();
