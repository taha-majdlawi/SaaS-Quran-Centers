-- =========================================================================
-- 0004_engagement.sql
-- Gamification: points, badges, the points market, and circle challenges.
-- Maps legacy: points_config, currency_config, badges, student_badges,
-- student_wallets, market_items, market_purchases, circle_challenges.
-- =========================================================================

create table public.points_config (
  organization_id  uuid primary key references public.organizations (id) on delete cascade,
  rules            jsonb not null default '{}',   -- points per achievement_type / grade band
  updated_at       timestamptz not null default now()
);

create table public.currency_config (
  organization_id  uuid primary key references public.organizations (id) on delete cascade,
  currency_name    text not null default 'نقاط',
  exchange_rate    numeric(10, 4) not null default 1,
  updated_at       timestamptz not null default now()
);

create table public.badges (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  name             text not null,
  description      text,
  icon_url         text,
  rule             jsonb,                          -- null = manually awarded, otherwise auto-award rule
  created_at       timestamptz not null default now()
);

create table public.student_badges (
  id           uuid primary key default gen_random_uuid(),
  badge_id     uuid not null references public.badges (id) on delete cascade,
  student_id   uuid not null references public.students_profile (id) on delete cascade,
  awarded_by   uuid references auth.users (id),
  awarded_at   timestamptz not null default now(),
  unique (badge_id, student_id)
);

create table public.student_wallets (
  student_id       uuid primary key references public.students_profile (id) on delete cascade,
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  balance          integer not null default 0,
  updated_at       timestamptz not null default now()
);

create table public.market_items (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  name             text not null,
  cost             integer not null check (cost >= 0),
  stock            integer,                        -- null = unlimited
  is_active        boolean not null default true,
  created_at       timestamptz not null default now()
);

create table public.market_purchases (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  student_id       uuid not null references public.students_profile (id) on delete cascade,
  item_id          uuid not null references public.market_items (id),
  cost             integer not null,
  status           text not null default 'pending' check (status in ('pending', 'fulfilled', 'cancelled')),
  created_at       timestamptz not null default now()
);

create table public.circle_challenges (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  title            text not null,
  metric           text not null,                  -- e.g. 'attendance_rate', 'points_earned'
  starts_on        date not null,
  ends_on          date not null,
  created_at       timestamptz not null default now()
);

create table public.circle_challenge_entries (
  id            uuid primary key default gen_random_uuid(),
  challenge_id  uuid not null references public.circle_challenges (id) on delete cascade,
  circle_id     uuid not null references public.circles (id) on delete cascade,
  score         numeric(10, 2) not null default 0,
  unique (challenge_id, circle_id)
);

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.points_config enable row level security;
alter table public.currency_config enable row level security;
alter table public.badges enable row level security;
alter table public.student_badges enable row level security;
alter table public.student_wallets enable row level security;
alter table public.market_items enable row level security;
alter table public.market_purchases enable row level security;
alter table public.circle_challenges enable row level security;
alter table public.circle_challenge_entries enable row level security;

create policy "points_config_select_org" on public.points_config for select using (public.is_org_member(organization_id));
create policy "points_config_write_admin" on public.points_config for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "currency_config_select_org" on public.currency_config for select using (public.is_org_member(organization_id));
create policy "currency_config_write_admin" on public.currency_config for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "badges_select_org" on public.badges for select using (public.is_org_member(organization_id));
create policy "badges_write_staff" on public.badges for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "student_badges_select_org" on public.student_badges for select using (
  exists (select 1 from public.badges b where b.id = badge_id and public.is_org_member(b.organization_id))
);
create policy "student_badges_write_staff" on public.student_badges for all using (
  exists (select 1 from public.badges b where b.id = badge_id and public.is_org_staff(b.organization_id))
) with check (
  exists (select 1 from public.badges b where b.id = badge_id and public.is_org_staff(b.organization_id))
);

create policy "student_wallets_select_org" on public.student_wallets for select using (public.is_org_member(organization_id));
create policy "student_wallets_write_staff" on public.student_wallets for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "market_items_select_org" on public.market_items for select using (public.is_org_member(organization_id));
create policy "market_items_write_staff" on public.market_items for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "market_purchases_select_org" on public.market_purchases for select using (public.is_org_member(organization_id));
create policy "market_purchases_write_staff" on public.market_purchases for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "circle_challenges_select_org" on public.circle_challenges for select using (public.is_org_member(organization_id));
create policy "circle_challenges_write_staff" on public.circle_challenges for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "circle_challenge_entries_select" on public.circle_challenge_entries for select using (
  exists (select 1 from public.circle_challenges c where c.id = challenge_id and public.is_org_member(c.organization_id))
);
create policy "circle_challenge_entries_write" on public.circle_challenge_entries for all using (
  exists (select 1 from public.circle_challenges c where c.id = challenge_id and public.is_org_staff(c.organization_id))
) with check (
  exists (select 1 from public.circle_challenges c where c.id = challenge_id and public.is_org_staff(c.organization_id))
);
