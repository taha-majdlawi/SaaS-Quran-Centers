-- =========================================================================
-- 0021_market_badges_challenges.sql
-- سوق النقاط، الشارات، لوحة الصدارة، ومنافسات الحلقات - rebuilt to match the
-- eqraa design, per center.
--
-- MARKET. Items are priced in the center's own CURRENCY (rate + symbol are
-- the admin's). The rate is applied by a CONVERT-ONCE LEDGER (student_wallets):
-- each earned point is turned into currency exactly once, at the rate in force
-- when it converted, so changing the rate never re-values what a student
-- already holds. The rate is reduced with gcd to its smallest exact block, so
-- conversion is pure integer arithmetic (no rounding drift). The spendable
-- balance is DERIVED (converted - non-cancelled purchases), so cancelling a
-- purchase refunds it by construction. Purchases copy the item name and the
-- price paid; stock is restored on cancel.
--
-- BADGES. Admin-defined rules, auto-awarded (recitation / attendance / serd
-- events call the evaluator), optionally expiring, or awarded by hand (single
-- student or a whole circle). Rules: points, recitation count, count of a
-- chosen recitation grade, streak, weekly attendance %, a completed juz (all
-- eight eighths approved), number of passed serd. Progress toward every badge
-- is readable, earned or not.
--
-- LEADERBOARD + CIRCLE CHALLENGES. The circle board is behind the center's
-- flag. A challenge ranks circles by an AVERAGE PER STUDENT (never a raw sum,
-- so a five-student circle is not beaten by size alone) over a date range.
--
-- The earlier simplified tables (0004) held no production data and are
-- replaced.
-- =========================================================================

drop table if exists public.circle_challenge_entries cascade;
drop table if exists public.circle_challenges cascade;
drop table if exists public.student_badges cascade;
drop table if exists public.badges cascade;
drop table if exists public.student_wallets cascade;
drop table if exists public.market_purchases cascade;
drop table if exists public.market_items cascade;
drop table if exists public.currency_config cascade;
drop table if exists public.points_config cascade;

-- ---------------------------------------------------------------------
-- 1. Market
-- ---------------------------------------------------------------------
create table public.market_config (
  organization_id  uuid primary key references public.organizations (id) on delete cascade,
  -- "points_per_unit points = unit_value <symbol>", e.g. 1000 points = 10 ₪
  points_per_unit  integer not null default 1000 check (points_per_unit > 0),
  unit_value       numeric(12,2) not null default 10 check (unit_value > 0),
  currency_symbol  text not null default '₪' check (char_length(currency_symbol) between 1 and 8),
  updated_at       timestamptz not null default now()
);

create or replace function public.seed_market_defaults(p_org uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.market_config (organization_id) values (p_org) on conflict do nothing;
end;
$$;
create or replace function public.trg_seed_market_defaults()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.seed_market_defaults(new.id);
  return new;
end;
$$;
drop trigger if exists trg_organizations_seed_market on public.organizations;
create trigger trg_organizations_seed_market after insert on public.organizations
  for each row execute function public.trg_seed_market_defaults();
select public.seed_market_defaults(id) from public.organizations;

create table public.market_items (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  name            text not null,
  description     text,
  image_url       text,
  price_currency  numeric(12,2) not null check (price_currency >= 0),
  stock           integer check (stock is null or stock >= 0),   -- null = unlimited
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);
create index market_items_org_idx on public.market_items (organization_id, is_active);

create table public.market_purchases (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  student_id      uuid not null references public.students_profile (id) on delete cascade,
  item_id         uuid references public.market_items (id) on delete set null,
  item_name       text not null,                 -- copied: the item can be renamed / removed
  currency_spent  numeric(12,2) not null check (currency_spent >= 0),
  status          text not null default 'pending' check (status in ('pending', 'fulfilled', 'cancelled')),
  created_by      uuid references auth.users (id),
  decided_at      timestamptz,
  decided_by      uuid references auth.users (id),
  created_at      timestamptz not null default now()
);
create index market_purchases_student_idx on public.market_purchases (student_id, status);
create index market_purchases_org_status_idx on public.market_purchases (organization_id, status, created_at desc);

-- The convert-once ledger.
create table public.student_wallets (
  student_id        uuid primary key references public.students_profile (id) on delete cascade,
  organization_id   uuid not null references public.organizations (id) on delete cascade,
  converted_points  bigint not null default 0 check (converted_points >= 0),
  total_converted   numeric(12,2) not null default 0 check (total_converted >= 0),
  updated_at        timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 2. Badges
-- ---------------------------------------------------------------------
create table public.badges (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  name            text not null,
  description     text,
  icon            text not null default '🏅',
  color           text not null default '#f59e0b' check (color ~ '^#[0-9a-fA-F]{6}$'),
  -- manual | points_threshold | recitations_count | grade_count | streak_days
  -- | weekly_attendance | juz_complete | serd_passed_count
  rule_type       text not null default 'manual'
                    check (rule_type in ('manual', 'points_threshold', 'recitations_count', 'grade_count',
                                         'streak_days', 'weekly_attendance', 'juz_complete', 'serd_passed_count')),
  threshold       integer not null default 0 check (threshold >= 0),
  param           text,                                     -- grade key for grade_count
  duration_days   integer check (duration_days is null or duration_days > 0),  -- null = permanent
  is_active       boolean not null default true,
  sort_order      integer not null default 0,
  created_at      timestamptz not null default now()
);
create index badges_org_idx on public.badges (organization_id, sort_order);

create table public.student_badges (
  id          uuid primary key default gen_random_uuid(),
  badge_id    uuid not null references public.badges (id) on delete cascade,
  student_id  uuid not null references public.students_profile (id) on delete cascade,
  awarded_by  uuid references auth.users (id),           -- null = automatic
  awarded_at  timestamptz not null default now(),
  expires_at  timestamptz,
  unique (badge_id, student_id)
);
create index student_badges_student_idx on public.student_badges (student_id);

-- ---------------------------------------------------------------------
-- 3. Challenges (circle vs circle)
-- ---------------------------------------------------------------------
create table public.circle_challenges (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  title           text not null,
  description     text,
  metric          text not null check (metric in ('points', 'recitations', 'attendance')),
  starts_on       date not null,
  ends_on         date not null,
  created_by      uuid references auth.users (id),
  created_at      timestamptz not null default now(),
  check (ends_on >= starts_on)
);
create index circle_challenges_org_idx on public.circle_challenges (organization_id, starts_on desc);

-- ---------------------------------------------------------------------
-- 4. RLS: reads only; every write goes through an audited RPC
-- ---------------------------------------------------------------------
alter table public.market_config enable row level security;
alter table public.market_items enable row level security;
alter table public.market_purchases enable row level security;
alter table public.student_wallets enable row level security;
alter table public.badges enable row level security;
alter table public.student_badges enable row level security;
alter table public.circle_challenges enable row level security;

create policy "market_config_select" on public.market_config for select using (public.is_org_member(organization_id));
create policy "market_items_select" on public.market_items for select
  using (public.is_org_admin(organization_id) or (is_active and public.is_org_member(organization_id)));
create policy "market_purchases_select" on public.market_purchases for select
  using (public.is_org_admin(organization_id) or student_id = any (public.linked_student_ids(organization_id)));
create policy "student_wallets_select" on public.student_wallets for select
  using (public.is_org_admin(organization_id) or student_id = any (public.linked_student_ids(organization_id)));
create policy "badges_select" on public.badges for select using (public.is_org_member(organization_id));
create policy "student_badges_select" on public.student_badges for select using (
  exists (select 1 from public.badges b where b.id = badge_id and public.is_org_admin(b.organization_id))
  or student_id = any (public.linked_student_ids((select organization_id from public.badges b where b.id = badge_id)))
  or public._teaches_student(student_id)
);
create policy "circle_challenges_select" on public.circle_challenges for select using (public.is_org_member(organization_id));

revoke insert, update, delete on public.market_config, public.market_items, public.market_purchases,
  public.student_wallets, public.badges, public.student_badges, public.circle_challenges from authenticated;

-- ---------------------------------------------------------------------
-- 5. Wallet primitives
-- ---------------------------------------------------------------------
-- Rate reduced to its smallest exact block: block_points points are worth
-- exactly block_units minor units (1/100 of the currency), no rounding.
create or replace function public._currency_block(p_org uuid, out block_points bigint, out block_units bigint)
language plpgsql stable security definer set search_path = public as $$
declare v_ppu bigint; v_units bigint; v_gcd bigint;
begin
  select points_per_unit, round(unit_value * 100)::bigint into v_ppu, v_units
    from public.market_config where organization_id = p_org;
  if v_ppu is null or v_ppu <= 0 or v_units is null or v_units <= 0 then
    block_points := 0; block_units := 0; return;
  end if;
  v_gcd := gcd(v_ppu, v_units);
  block_points := v_ppu / v_gcd;
  block_units := v_units / v_gcd;
end;
$$;

create or replace function public._currency_spent(p_student uuid)
returns numeric language sql stable security definer set search_path = public as $$
  select coalesce(sum(currency_spent), 0)::numeric(12,2)
  from public.market_purchases where student_id = p_student and status <> 'cancelled';
$$;

-- Converts ONLY the delta between earned points and already-converted points,
-- at the rate in force now, in whole blocks (leftover points wait).
create or replace function public._sync_wallet(p_org uuid, p_student uuid)
returns jsonb language plpgsql volatile security definer set search_path = public as $$
declare v_earned bigint; v_conv bigint; v_total numeric(12,2); v_bp bigint; v_bu bigint; v_blocks bigint;
begin
  select coalesce(total_points, 0) into v_earned from public.students_profile
   where id = p_student and organization_id = p_org;
  if not found then return null; end if;
  insert into public.student_wallets (student_id, organization_id) values (p_student, p_org)
    on conflict (student_id) do nothing;
  select converted_points, total_converted into v_conv, v_total
    from public.student_wallets where student_id = p_student for update;
  if v_earned - v_conv > 0 then
    select block_points, block_units into v_bp, v_bu from public._currency_block(p_org);
    if v_bp > 0 then
      v_blocks := (v_earned - v_conv) / v_bp;
      if v_blocks > 0 then
        update public.student_wallets
           set converted_points = converted_points + v_blocks * v_bp,
               total_converted = total_converted + (v_blocks * v_bu)::numeric / 100, updated_at = now()
         where student_id = p_student
        returning converted_points, total_converted into v_conv, v_total;
      end if;
    end if;
  end if;
  return jsonb_build_object('earned_points', v_earned, 'converted_points', v_conv, 'total_converted', v_total,
    'pending_points', greatest(v_earned - v_conv, 0), 'spent', public._currency_spent(p_student),
    'balance', v_total - public._currency_spent(p_student));
end;
$$;

-- ---------------------------------------------------------------------
-- 6. Market RPCs
-- ---------------------------------------------------------------------
create or replace function public._market_enabled(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.org_setting(p_org, 'flag_market_enabled', 'true') = 'true';
$$;

-- Market of one student, as their family (or staff) sees it.
create or replace function public.get_student_market(p_org uuid, p_student uuid)
returns jsonb language plpgsql volatile security definer set search_path = public as $$
begin
  if not (public.is_org_admin(p_org) or p_student = any (public.linked_student_ids(p_org))) then
    raise exception 'غير مصرّح';
  end if;
  return jsonb_build_object(
    'enabled', public._market_enabled(p_org),
    'symbol', (select currency_symbol from public.market_config where organization_id = p_org),
    'wallet', public._sync_wallet(p_org, p_student),
    'items', coalesce((select jsonb_agg(jsonb_build_object('id', i.id, 'name', i.name, 'description', i.description,
               'image_url', i.image_url, 'price', i.price_currency, 'stock', i.stock) order by i.created_at desc)
               from public.market_items i where i.organization_id = p_org and i.is_active), '[]'::jsonb),
    'purchases', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'item_name', p.item_name, 'spent', p.currency_spent,
               'status', p.status, 'created_at', p.created_at, 'decided_at', p.decided_at) order by p.created_at desc)
               from public.market_purchases p where p.student_id = p_student), '[]'::jsonb)
  );
end;
$$;

create or replace function public.purchase_market_item(p_org uuid, p_student uuid, p_item uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_source text; i public.market_items%rowtype; v_wallet jsonb;
begin
  v_source := public._act_source(p_org, p_student);
  if coalesce(v_source, '') not in ('self', 'guardian') then raise exception 'غير مصرّح'; end if;
  if not public._market_enabled(p_org) then raise exception 'سوق النقاط غير مفعّل حالياً'; end if;

  select * into i from public.market_items where id = p_item and organization_id = p_org for update;
  if not found then raise exception 'العنصر غير موجود'; end if;
  if not i.is_active then raise exception 'هذا العنصر غير متاح'; end if;
  if i.stock is not null and i.stock <= 0 then raise exception 'نفد المخزون'; end if;

  v_wallet := public._sync_wallet(p_org, p_student);
  if v_wallet is null then raise exception 'الطالب غير موجود'; end if;
  if (v_wallet->>'balance')::numeric < i.price_currency then raise exception 'رصيدك غير كافٍ'; end if;

  insert into public.market_purchases (organization_id, student_id, item_id, item_name, currency_spent, created_by)
  values (p_org, p_student, i.id, i.name, i.price_currency, auth.uid());
  if i.stock is not null then update public.market_items set stock = stock - 1 where id = i.id; end if;
  return jsonb_build_object('balance', (v_wallet->>'balance')::numeric - i.price_currency);
end;
$$;

-- Internal: change a purchase's status; cancelling restores stock and refunds
-- (the balance is derived, so the refund is automatic).
create or replace function public._set_purchase_status(p_purchase uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare p public.market_purchases%rowtype;
begin
  select * into p from public.market_purchases where id = p_purchase for update;
  if not found then raise exception 'الطلب غير موجود'; end if;
  if p.status = p_status then return; end if;
  -- a cancelled purchase is final: its stock went back and the seat may be taken
  if p.status = 'cancelled' then raise exception 'الطلب ملغى ولا يمكن تغييره'; end if;
  update public.market_purchases set status = p_status, decided_at = now(), decided_by = auth.uid() where id = p_purchase;
  if p_status = 'cancelled' and p.item_id is not null then
    update public.market_items set stock = stock + 1 where id = p.item_id and stock is not null;
  end if;
end;
$$;

create or replace function public.admin_set_purchase_status(p_purchase uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare v_org uuid;
begin
  if p_status not in ('pending', 'fulfilled', 'cancelled') then raise exception 'حالة غير معروفة'; end if;
  select organization_id into v_org from public.market_purchases where id = p_purchase;
  if v_org is null then raise exception 'الطلب غير موجود'; end if;
  if not public.is_org_admin(v_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._set_purchase_status(p_purchase, p_status);
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (v_org, auth.uid(), 'update', 'market_purchases', p_purchase, jsonb_build_object('status', p_status));
end;
$$;

-- A family may withdraw an order that is still pending.
create or replace function public.cancel_my_purchase(p_purchase uuid)
returns void language plpgsql security definer set search_path = public as $$
declare p public.market_purchases%rowtype;
begin
  select * into p from public.market_purchases where id = p_purchase;
  if not found then raise exception 'الطلب غير موجود'; end if;
  if coalesce(public._act_source(p.organization_id, p.student_id), '') not in ('self', 'guardian') then
    raise exception 'غير مصرّح'; end if;
  if p.status <> 'pending' then raise exception 'لا يمكن إلغاء طلب تمت معالجته'; end if;
  perform public._set_purchase_status(p_purchase, 'cancelled');
end;
$$;

create or replace function public.admin_market_overview(p_org uuid)
returns jsonb language plpgsql volatile security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return jsonb_build_object(
    'enabled', public._market_enabled(p_org),
    'config', (select jsonb_build_object('points_per_unit', points_per_unit, 'unit_value', unit_value,
                'currency_symbol', currency_symbol) from public.market_config where organization_id = p_org),
    'items', coalesce((select jsonb_agg(jsonb_build_object('id', i.id, 'name', i.name, 'description', i.description,
               'image_url', i.image_url, 'price', i.price_currency, 'stock', i.stock, 'is_active', i.is_active)
               order by i.created_at desc) from public.market_items i where i.organization_id = p_org), '[]'::jsonb),
    'purchases', coalesce((select jsonb_agg(x order by case x->>'status' when 'pending' then 0 else 1 end, (x->>'created_at') desc)
       from (select jsonb_build_object('id', p.id, 'student_id', p.student_id, 'student_name', sp.full_name,
               'student_code', sp.student_code, 'item_name', p.item_name, 'spent', p.currency_spent, 'status', p.status,
               'created_at', p.created_at, 'decided_at', p.decided_at) as x
             from public.market_purchases p join public.students_profile sp on sp.id = p.student_id
             where p.organization_id = p_org order by p.created_at desc limit 300) t), '[]'::jsonb)
  );
end;
$$;

create or replace function public.admin_market_wallets(p_org uuid)
returns jsonb language plpgsql volatile security definer set search_path = public as $$
declare r record; v_rows jsonb := '[]'::jsonb; v_w jsonb;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  for r in select id, full_name, student_code from public.students_profile
           where organization_id = p_org and status = 'active' order by full_name loop
    v_w := public._sync_wallet(p_org, r.id);
    v_rows := v_rows || jsonb_build_array(jsonb_build_object('student_id', r.id, 'student_name', r.full_name,
                'student_code', r.student_code) || coalesce(v_w, '{}'::jsonb));
  end loop;
  return v_rows;
end;
$$;

create or replace function public.save_market_item(
  p_org uuid, p_id uuid, p_name text, p_description text, p_image_url text, p_price numeric, p_stock integer, p_is_active boolean
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if nullif(btrim(coalesce(p_name, '')), '') is null then raise exception 'اسم العنصر مطلوب'; end if;
  if p_price is null or p_price < 0 then raise exception 'السعر غير صالح'; end if;
  if p_stock is not null and p_stock < 0 then raise exception 'المخزون غير صالح'; end if;
  if v_id is null then
    insert into public.market_items (organization_id, name, description, image_url, price_currency, stock, is_active)
    values (p_org, btrim(p_name), nullif(btrim(coalesce(p_description, '')), ''), nullif(btrim(coalesce(p_image_url, '')), ''),
            round(p_price, 2), p_stock, coalesce(p_is_active, true)) returning id into v_id;
  else
    update public.market_items set name = btrim(p_name), description = nullif(btrim(coalesce(p_description, '')), ''),
      image_url = nullif(btrim(coalesce(p_image_url, '')), ''), price_currency = round(p_price, 2), stock = p_stock,
      is_active = coalesce(p_is_active, true) where id = v_id and organization_id = p_org;
    if not found then raise exception 'العنصر غير موجود'; end if;
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), case when p_id is null then 'create' else 'update' end, 'market_items', v_id);
  return v_id;
end;
$$;

create or replace function public.delete_market_item(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  delete from public.market_items where id = p_id and organization_id = p_org;  -- purchases keep item_name
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), 'delete', 'market_items', p_id);
end;
$$;

-- The rate. Applies only to points that convert AFTER the change.
create or replace function public.set_market_config(p_org uuid, p_points_per_unit integer, p_unit_value numeric, p_symbol text)
returns void language plpgsql security definer set search_path = public as $$
declare v_before jsonb; v_symbol text := nullif(btrim(coalesce(p_symbol, '')), '');
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if p_points_per_unit is null or p_points_per_unit <= 0 then raise exception 'عدد النقاط يجب أن يكون أكبر من صفر'; end if;
  if p_unit_value is null or p_unit_value <= 0 then raise exception 'قيمة الوحدة يجب أن تكون أكبر من صفر'; end if;
  if v_symbol is null or char_length(v_symbol) > 8 then raise exception 'رمز العملة مطلوب (8 أحرف كحد أقصى)'; end if;
  perform public.seed_market_defaults(p_org);
  select to_jsonb(c) - 'organization_id' into v_before from public.market_config c where organization_id = p_org;
  update public.market_config set points_per_unit = p_points_per_unit, unit_value = round(p_unit_value, 2),
    currency_symbol = v_symbol, updated_at = now() where organization_id = p_org;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, diff)
  values (p_org, auth.uid(), 'update', 'market_config',
          jsonb_build_object('before', v_before, 'after', jsonb_build_object('points_per_unit', p_points_per_unit,
            'unit_value', round(p_unit_value, 2), 'symbol', v_symbol)));
end;
$$;

-- ---------------------------------------------------------------------
-- 7. Badges: measuring and awarding
-- ---------------------------------------------------------------------
create or replace function public._recitation_streak(p_student uuid, p_tz text)
returns integer language plpgsql stable security definer set search_path = public as $$
declare v_dates date[]; v_cursor date; v_today date := (now() at time zone p_tz)::date; v_n integer := 0;
begin
  select array_agg(distinct (created_at at time zone p_tz)::date) into v_dates
    from public.daily_achievements where student_id = p_student;
  if v_dates is null then return 0; end if;
  if v_today = any (v_dates) then v_cursor := v_today;
  elsif v_today - 1 = any (v_dates) then v_cursor := v_today - 1;
  else return 0; end if;
  while v_cursor = any (v_dates) loop v_n := v_n + 1; v_cursor := v_cursor - 1; end loop;
  return v_n;
end;
$$;

-- Current value of a badge's rule for a student, and the goal it must reach.
create or replace function public._badge_progress(b public.badges, p_student uuid, out progress numeric, out goal numeric)
language plpgsql stable security definer set search_path = public as $$
declare v_tz text; v_working integer; v_present integer; v_circle uuid;
begin
  goal := b.threshold;
  case b.rule_type
    when 'points_threshold' then
      select coalesce(total_points, 0) into progress from public.students_profile where id = p_student;
    when 'recitations_count' then
      select count(*) into progress from public.daily_achievements where student_id = p_student;
    when 'grade_count' then
      select count(*) into progress from public.daily_achievements where student_id = p_student and grade = b.param;
    when 'streak_days' then
      select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = b.organization_id;
      progress := public._recitation_streak(p_student, v_tz);
    when 'weekly_attendance' then
      select circle_id into v_circle from public.students_profile where id = p_student;
      v_working := public.center_working_days(b.organization_id, current_date - 6, current_date, v_circle);
      select count(*) into v_present from public.attendance
        where student_id = p_student and session_date between current_date - 6 and current_date and status in ('present', 'late');
      progress := case when v_working > 0 then round(least(v_present, v_working)::numeric * 100 / v_working, 1) else 0 end;
    when 'juz_complete' then
      goal := 8;   -- all eight eighths of juz `threshold`
      select coalesce(public.serd_mask_eighths(bit_or(p.eighths_mask)::smallint), 0) into progress
        from public.serd_session_parts p join public.serd_sessions s on s.id = p.session_id
       where s.student_id = p_student and s.status = 'approved' and p.juz_number = b.threshold;
    when 'serd_passed_count' then
      select count(*) into progress from public.serd_sessions
       where student_id = p_student and status = 'approved' and score_percent >= coalesce(pass_percent_applied, 0);
    else
      progress := 0;
  end case;
  progress := coalesce(progress, 0);
end;
$$;

create or replace function public._evaluate_badges(p_student uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_org uuid; b public.badges%rowtype; v_p numeric; v_g numeric;
begin
  select organization_id into v_org from public.students_profile where id = p_student;
  if v_org is null then return; end if;
  for b in select * from public.badges where organization_id = v_org and is_active and rule_type <> 'manual' loop
    select progress, goal into v_p, v_g from public._badge_progress(b, p_student);
    -- goal 0 (no threshold set) would award everything to everyone; require a positive goal
    if v_g > 0 and v_p >= v_g then
      insert into public.student_badges (badge_id, student_id, awarded_at, expires_at)
      values (b.id, p_student, now(), case when b.duration_days is null then null else now() + make_interval(days => b.duration_days) end)
      on conflict (badge_id, student_id) do update
        set expires_at = excluded.expires_at
        -- a permanent badge never gains an expiry; a renewed timed one restarts its clock
        where public.student_badges.expires_at is not null or excluded.expires_at is not null;
    end if;
  end loop;
end;
$$;

create or replace function public.trg_evaluate_badges()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public._evaluate_badges(new.student_id);
  return new;
end;
$$;
drop trigger if exists trg_badges_after_recitation on public.daily_achievements;
create trigger trg_badges_after_recitation after insert on public.daily_achievements
  for each row execute function public.trg_evaluate_badges();
drop trigger if exists trg_badges_after_attendance on public.attendance;
create trigger trg_badges_after_attendance after insert or update of status on public.attendance
  for each row execute function public.trg_evaluate_badges();

create or replace function public.trg_evaluate_badges_serd()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'approved' and new.student_id is not null then
    perform public._evaluate_badges(new.student_id);
  end if;
  return new;
end;
$$;
drop trigger if exists trg_badges_after_serd on public.serd_sessions;
create trigger trg_badges_after_serd after insert or update of status on public.serd_sessions
  for each row execute function public.trg_evaluate_badges_serd();

-- Every badge of the center with the student's progress toward it.
create or replace function public.get_student_badges(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not (public.is_org_admin(p_org) or p_student = any (public.linked_student_ids(p_org))
          or public._teaches_student(p_student)) then raise exception 'غير مصرّح'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', b.id, 'name', b.name, 'description', b.description, 'icon', b.icon, 'color', b.color,
      'rule_type', b.rule_type, 'threshold', b.threshold, 'param', b.param,
      'progress', pr.progress, 'goal', pr.goal,
      'earned', sb.id is not null and (sb.expires_at is null or sb.expires_at > now()),
      'awarded_at', sb.awarded_at, 'expires_at', sb.expires_at) order by b.sort_order, b.name)
    from public.badges b
    cross join lateral public._badge_progress(b, p_student) pr
    left join public.student_badges sb on sb.badge_id = b.id and sb.student_id = p_student
    where b.organization_id = p_org and b.is_active
  ), '[]'::jsonb);
end;
$$;

create or replace function public.save_badge(
  p_org uuid, p_id uuid, p_name text, p_description text, p_icon text, p_color text, p_rule_type text,
  p_threshold integer, p_param text, p_duration_days integer, p_is_active boolean, p_sort_order integer
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if nullif(btrim(coalesce(p_name, '')), '') is null then raise exception 'اسم الشارة مطلوب'; end if;
  if p_rule_type not in ('manual', 'points_threshold', 'recitations_count', 'grade_count', 'streak_days',
                         'weekly_attendance', 'juz_complete', 'serd_passed_count') then
    raise exception 'قاعدة غير معروفة'; end if;
  if p_rule_type <> 'manual' and coalesce(p_threshold, 0) <= 0 then raise exception 'حدّد قيمة الشرط'; end if;
  if p_rule_type = 'juz_complete' and p_threshold not between 1 and 30 then raise exception 'رقم الجزء بين 1 و 30'; end if;
  if p_rule_type = 'weekly_attendance' and p_threshold > 100 then raise exception 'النسبة بين 1 و 100'; end if;
  if p_rule_type = 'grade_count' and not exists (
    select 1 from public.recitation_grades where organization_id = p_org and key = p_param
  ) then raise exception 'اختر تقديرًا صحيحًا'; end if;
  if p_color !~ '^#[0-9a-fA-F]{6}$' then raise exception 'اللون غير صالح'; end if;

  if v_id is null then
    insert into public.badges (organization_id, name, description, icon, color, rule_type, threshold, param, duration_days, is_active, sort_order)
    values (p_org, btrim(p_name), nullif(btrim(coalesce(p_description, '')), ''), coalesce(nullif(btrim(coalesce(p_icon, '')), ''), '🏅'),
            p_color, p_rule_type, coalesce(p_threshold, 0), case when p_rule_type = 'grade_count' then p_param end,
            p_duration_days, coalesce(p_is_active, true), coalesce(p_sort_order, 0)) returning id into v_id;
  else
    update public.badges set name = btrim(p_name), description = nullif(btrim(coalesce(p_description, '')), ''),
      icon = coalesce(nullif(btrim(coalesce(p_icon, '')), ''), '🏅'), color = p_color, rule_type = p_rule_type,
      threshold = coalesce(p_threshold, 0), param = case when p_rule_type = 'grade_count' then p_param end,
      duration_days = p_duration_days, is_active = coalesce(p_is_active, true), sort_order = coalesce(p_sort_order, sort_order)
    where id = v_id and organization_id = p_org;
    if not found then raise exception 'الشارة غير موجودة'; end if;
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), case when p_id is null then 'create' else 'update' end, 'badges', v_id);
  return v_id;
end;
$$;

create or replace function public.delete_badge(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  delete from public.badges where id = p_id and organization_id = p_org;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), 'delete', 'badges', p_id);
end;
$$;

-- By hand: admin anywhere, a teacher (badges module) only for their own students.
create or replace function public.award_badge(p_badge uuid, p_student uuid, p_revoke boolean default false)
returns void language plpgsql security definer set search_path = public as $$
declare b public.badges%rowtype;
begin
  select * into b from public.badges where id = p_badge;
  if not found then raise exception 'الشارة غير موجودة'; end if;
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = b.organization_id) then
    raise exception 'الطالب غير موجود في هذا المركز'; end if;
  if not (public.is_org_admin(b.organization_id)
          or (public.member_has_module(b.organization_id, 'badges') and public._teaches_student(p_student))) then
    raise exception 'غير مصرّح'; end if;
  if p_revoke then
    delete from public.student_badges where badge_id = p_badge and student_id = p_student;
  else
    insert into public.student_badges (badge_id, student_id, awarded_by, expires_at)
    values (p_badge, p_student, auth.uid(), case when b.duration_days is null then null else now() + make_interval(days => b.duration_days) end)
    on conflict (badge_id, student_id) do update set awarded_by = auth.uid(), awarded_at = now(), expires_at = excluded.expires_at;
  end if;
end;
$$;

create or replace function public.award_badge_to_circle(p_badge uuid, p_circle uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare b public.badges%rowtype; v_n integer;
begin
  select * into b from public.badges where id = p_badge;
  if not found then raise exception 'الشارة غير موجودة'; end if;
  if not public.is_org_admin(b.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if not exists (select 1 from public.circles where id = p_circle and organization_id = b.organization_id) then
    raise exception 'الحلقة غير موجودة'; end if;
  with ins as (
    insert into public.student_badges (badge_id, student_id, awarded_by, expires_at)
    select p_badge, sp.id, auth.uid(), case when b.duration_days is null then null else now() + make_interval(days => b.duration_days) end
    from public.students_profile sp where sp.circle_id = p_circle and sp.status = 'active'
    on conflict (badge_id, student_id) do update set awarded_by = auth.uid(), awarded_at = now(), expires_at = excluded.expires_at
    returning 1)
  select count(*) into v_n from ins;
  return v_n;
end;
$$;

create or replace function public.badge_holders(p_org uuid, p_badge uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('student_id', sp.id, 'student_name', sp.full_name,
      'student_code', sp.student_code, 'awarded_at', sb.awarded_at, 'expires_at', sb.expires_at, 'manual', sb.awarded_by is not null)
      order by sb.awarded_at desc)
    from public.student_badges sb join public.students_profile sp on sp.id = sb.student_id
    join public.badges b on b.id = sb.badge_id
    where sb.badge_id = p_badge and b.organization_id = p_org), '[]'::jsonb);
end;
$$;

-- Re-run every automatic rule for the whole center (after editing a rule).
create or replace function public.evaluate_org_badges(p_org uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  for r in select id from public.students_profile where organization_id = p_org and status = 'active' loop
    perform public._evaluate_badges(r.id);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------
-- 8. Leaderboard (per circle, behind the center's flag)
-- ---------------------------------------------------------------------
create or replace function public.get_circle_leaderboard(p_org uuid, p_circle uuid default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_circle uuid := p_circle; v_linked uuid[];
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  if public.org_setting(p_org, 'flag_leaderboard_enabled', 'true') <> 'true' then
    return jsonb_build_object('enabled', false, 'rows', '[]'::jsonb);
  end if;
  v_linked := public.linked_student_ids(p_org);
  if not (public.is_org_staff(p_org)) then
    -- a family only ever sees the circle(s) of their own students
    select circle_id into v_circle from public.students_profile
      where id = any (v_linked) and (p_circle is null or circle_id = p_circle) limit 1;
  end if;
  if v_circle is null then return jsonb_build_object('enabled', true, 'rows', '[]'::jsonb); end if;
  return jsonb_build_object(
    'enabled', true,
    'circle_id', v_circle,
    'circle_name', (select name from public.circles where id = v_circle),
    'rows', coalesce((select jsonb_agg(jsonb_build_object('rank', t.rk, 'name', t.full_name, 'points', t.total_points,
                  'is_me', t.id = any (v_linked)) order by t.rk)
                from (select sp.id, sp.full_name, coalesce(sp.total_points, 0) as total_points,
                             rank() over (order by coalesce(sp.total_points, 0) desc) as rk
                      from public.students_profile sp
                      where sp.circle_id = v_circle and sp.organization_id = p_org and sp.status = 'active') t
                where t.rk <= 20 or t.id = any (v_linked)), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------
-- 9. Circle challenges
-- ---------------------------------------------------------------------
create or replace function public.admin_save_challenge(
  p_org uuid, p_id uuid, p_title text, p_description text, p_metric text, p_starts date, p_ends date
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if nullif(btrim(coalesce(p_title, '')), '') is null then raise exception 'عنوان المنافسة مطلوب'; end if;
  if p_metric not in ('points', 'recitations', 'attendance') then raise exception 'مقياس غير معروف'; end if;
  if p_starts is null or p_ends is null or p_ends < p_starts then raise exception 'التواريخ غير صحيحة'; end if;
  if v_id is null then
    insert into public.circle_challenges (organization_id, title, description, metric, starts_on, ends_on, created_by)
    values (p_org, btrim(p_title), nullif(btrim(coalesce(p_description, '')), ''), p_metric, p_starts, p_ends, auth.uid())
    returning id into v_id;
  else
    update public.circle_challenges set title = btrim(p_title), description = nullif(btrim(coalesce(p_description, '')), ''),
      metric = p_metric, starts_on = p_starts, ends_on = p_ends where id = v_id and organization_id = p_org;
    if not found then raise exception 'المنافسة غير موجودة'; end if;
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), case when p_id is null then 'create' else 'update' end, 'circle_challenges', v_id);
  return v_id;
end;
$$;

create or replace function public.admin_delete_challenge(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  delete from public.circle_challenges where id = p_id and organization_id = p_org;
end;
$$;

create or replace function public.list_challenges(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'description', c.description,
      'metric', c.metric, 'starts_on', c.starts_on, 'ends_on', c.ends_on,
      'status', case when current_date < c.starts_on then 'upcoming' when current_date > c.ends_on then 'ended' else 'active' end)
      order by c.starts_on desc) from public.circle_challenges c where c.organization_id = p_org), '[]'::jsonb);
end;
$$;

-- Live board: circles ranked by the AVERAGE PER STUDENT (never a raw sum).
create or replace function public.challenge_board(p_org uuid, p_challenge uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c public.circle_challenges%rowtype; v_tz text; v_from timestamptz; v_to timestamptz;
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  select * into c from public.circle_challenges where id = p_challenge and organization_id = p_org;
  if not found then raise exception 'المنافسة غير موجودة'; end if;
  select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = p_org;
  v_from := (c.starts_on::timestamp) at time zone v_tz;
  v_to := ((c.ends_on + 1)::timestamp) at time zone v_tz;

  return jsonb_build_object('id', c.id, 'title', c.title, 'metric', c.metric, 'starts_on', c.starts_on, 'ends_on', c.ends_on,
    'status', case when current_date < c.starts_on then 'upcoming' when current_date > c.ends_on then 'ended' else 'active' end,
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object('rank', x.rk, 'circle_id', x.circle_id, 'circle_name', x.circle_name,
               'students', x.students, 'total', x.total, 'average', x.avg_value,
               'mine', x.circle_id in (select circle_id from public.students_profile where id = any (public.linked_student_ids(p_org))))
             order by x.rk)
      from (
        select t.*, rank() over (order by t.avg_value desc) as rk
        from (
          select ci.id as circle_id, ci.name as circle_name, count(sp.id) as students,
            case c.metric
              when 'points' then coalesce(sum(coalesce((select sum(da.points_awarded) from public.daily_achievements da
                    where da.student_id = sp.id and da.created_at >= v_from and da.created_at < v_to), 0)
                  + coalesce((select sum(s.points_awarded) from public.serd_sessions s
                    where s.student_id = sp.id and s.status = 'approved' and s.session_date between c.starts_on and c.ends_on), 0)), 0)
              when 'recitations' then coalesce(sum((select count(*) from public.daily_achievements da
                    where da.student_id = sp.id and da.created_at >= v_from and da.created_at < v_to)), 0)
              else coalesce(sum((select count(*) from public.attendance a
                    where a.student_id = sp.id and a.session_date between c.starts_on and c.ends_on and a.status in ('present', 'late'))), 0)
            end as total,
            round(
              (case c.metric
                when 'points' then coalesce(sum(coalesce((select sum(da.points_awarded) from public.daily_achievements da
                    where da.student_id = sp.id and da.created_at >= v_from and da.created_at < v_to), 0)
                  + coalesce((select sum(s.points_awarded) from public.serd_sessions s
                    where s.student_id = sp.id and s.status = 'approved' and s.session_date between c.starts_on and c.ends_on), 0)), 0)
                when 'recitations' then coalesce(sum((select count(*) from public.daily_achievements da
                    where da.student_id = sp.id and da.created_at >= v_from and da.created_at < v_to)), 0)
                else coalesce(sum((select count(*) from public.attendance a
                    where a.student_id = sp.id and a.session_date between c.starts_on and c.ends_on and a.status in ('present', 'late'))), 0)
              end)::numeric / greatest(count(sp.id), 1), 2) as avg_value
          from public.circles ci
          join public.students_profile sp on sp.circle_id = ci.id and sp.status = 'active'
          where ci.organization_id = p_org
          group by ci.id, ci.name
        ) t
      ) x), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------
-- 10. Grants (0018 policy)
-- ---------------------------------------------------------------------
revoke all on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated, service_role;
grant execute on function public.get_invitation(uuid) to anon;
revoke execute on function public.consent_info(uuid) from authenticated;
revoke execute on function public.consent_answer(uuid, text) from authenticated;
revoke execute on function public._insert_registration(uuid, uuid, text, uuid, text) from authenticated;
revoke execute on function public._promote_waitlist(uuid) from authenticated;
revoke execute on function public._calendar_entry_json(uuid) from authenticated;
revoke execute on function public._serd_write_parts(uuid, uuid, uuid, jsonb) from authenticated;
revoke execute on function public._serd_write_errors(uuid, uuid, jsonb) from authenticated;
revoke execute on function public._assert_serd_grader(uuid) from authenticated;
revoke execute on function public._serd_parts_json(uuid) from authenticated;
revoke execute on function public._serd_row_json(uuid) from authenticated;
-- new internals
revoke execute on function public._sync_wallet(uuid, uuid) from authenticated;
revoke execute on function public._currency_block(uuid) from authenticated;
revoke execute on function public._currency_spent(uuid) from authenticated;
revoke execute on function public._set_purchase_status(uuid, text) from authenticated;
revoke execute on function public._evaluate_badges(uuid) from authenticated;
revoke execute on function public._badge_progress(public.badges, uuid) from authenticated;
revoke execute on function public._recitation_streak(uuid, text) from authenticated;
