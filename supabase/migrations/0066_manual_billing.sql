-- =========================================================================
-- 0066_manual_billing.sql
-- Billing, phase 1: manual payments (bank transfer / wallet / cash), no card
-- processor yet. The center's admin picks a plan + period and reports a
-- payment; the platform owner confirms it; the paid period is recorded in
-- the existing subscriptions table (billing_provider = 'manual'), so a card
-- provider can later write the same rows.
--
-- When a center's trial or paid period ends (plus a grace period) it becomes
-- READ-ONLY - folded into _is_read_only(), the same lock the "viewing
-- account" feature (0028) already applies to every table trigger, RPC and
-- upload. Data stays visible; nothing can be added until renewal.
--
-- SAFETY: the lock only applies while platform setting billing_enforce is
-- 'true' (default 'false'). Every center created so far defaulted to
-- status = 'trial' with a 14-day trial_ends_at, so turning it on blindly
-- would lock real centers. The owner reviews each center's status first
-- (platform console), then switches enforcement on.
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. plans: an optional yearly price (monthly stays price_cents)
-- ---------------------------------------------------------------------
alter table public.plans add column if not exists yearly_price_cents integer
  check (yearly_price_cents is null or yearly_price_cents >= 0);

drop function if exists public.platform_save_plan(uuid, text, text, integer, text, integer, integer, jsonb, boolean);
create or replace function public.platform_save_plan(
  p_id uuid, p_code text, p_name text, p_price_cents integer, p_currency text,
  p_max_students integer, p_max_teachers integer, p_features jsonb, p_active boolean,
  p_yearly_cents integer default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id; v_limits jsonb := jsonb_build_object('max_students', p_max_students, 'max_teachers', p_max_teachers);
begin
  perform public._plat_guard();
  if p_code !~ '^[a-z0-9_-]{2,30}$' then raise exception 'رمز الخطة: حروف إنجليزية صغيرة وأرقام'; end if;
  if char_length(btrim(coalesce(p_name, ''))) < 2 then raise exception 'اسم الخطة مطلوب'; end if;
  if coalesce(p_price_cents, 0) < 0 or coalesce(p_yearly_cents, 0) < 0 then raise exception 'السعر لا يكون سالبًا'; end if;
  if p_max_students is not null and p_max_students < 0 or p_max_teachers is not null and p_max_teachers < 0 then raise exception 'الحدود لا تكون سالبة'; end if;
  if v_id is null then
    insert into public.plans (code, name, price_cents, yearly_price_cents, currency, limits, features, is_active)
    values (p_code, btrim(p_name), coalesce(p_price_cents, 0), p_yearly_cents, upper(coalesce(nullif(p_currency, ''), 'USD')), v_limits, coalesce(p_features, '{}'::jsonb), coalesce(p_active, true))
    returning id into v_id;
  else
    update public.plans set code = p_code, name = btrim(p_name), price_cents = coalesce(p_price_cents, 0), yearly_price_cents = p_yearly_cents,
           currency = upper(coalesce(nullif(p_currency, ''), 'USD')), limits = v_limits, features = coalesce(p_features, '{}'::jsonb), is_active = coalesce(p_active, true)
     where id = v_id;
    if not found then raise exception 'الخطة غير موجودة'; end if;
  end if;
  perform public._plat_log('save_plan', v_id::text, jsonb_build_object('code', p_code));
  return v_id;
end;
$$;
revoke all on function public.platform_save_plan(uuid, text, text, integer, text, integer, integer, jsonb, boolean, integer) from public, anon;
grant execute on function public.platform_save_plan(uuid, text, text, integer, text, integer, integer, jsonb, boolean, integer) to authenticated;

-- ---------------------------------------------------------------------
-- 2. payment requests (reported by the center admin, confirmed by the owner)
-- ---------------------------------------------------------------------
create table public.billing_requests (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  plan_id         uuid not null references public.plans (id),
  period          text not null check (period in ('monthly', 'yearly')),
  amount_cents    integer not null check (amount_cents >= 0),
  currency        text not null,
  method          text not null check (method in ('bank_transfer', 'wallet', 'cash', 'other')),
  reference       text,
  note            text,
  status          text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  requested_by    uuid references auth.users (id),
  created_at      timestamptz not null default now(),
  reviewed_by     uuid references auth.users (id),
  reviewed_at     timestamptz,
  review_note     text,
  period_start    timestamptz,
  period_end      timestamptz
);
create index billing_requests_org_idx on public.billing_requests (organization_id, created_at desc);
create unique index billing_requests_one_pending on public.billing_requests (organization_id) where status = 'pending';

alter table public.billing_requests enable row level security;
create policy "billing_requests_select_admin" on public.billing_requests for select using (public.is_org_admin(organization_id));
revoke insert, update, delete on public.billing_requests from authenticated, anon;
-- Deliberately WITHOUT a_deny_readonly_write: a center locked for non-payment
-- must still be able to report its payment. Writes are RPC-only, and
-- billing_submit_request refuses a viewing ACCOUNT itself (see invariants.sql).

-- ---------------------------------------------------------------------
-- 3. billing state + the lock
-- ---------------------------------------------------------------------
create or replace function public._billing_state(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare o public.organizations; v_grace integer; v_enforce boolean; v_paid timestamptz; v_until timestamptz; v_state text; v_kind text;
begin
  select * into o from public.organizations where id = p_org;
  if not found then return null; end if;
  v_grace := coalesce(nullif(public._platform_setting('billing_grace_days', '7'), '')::integer, 7);
  v_enforce := public._platform_setting('billing_enforce', 'false') = 'true';
  select max(current_period_end) into v_paid from public.subscriptions
   where organization_id = p_org and status in ('active', 'trialing', 'past_due');

  if o.status in ('suspended', 'cancelled') then
    v_state := o.status;
  elsif v_paid is not null then
    v_kind := 'paid'; v_until := v_paid;
  elsif o.status = 'trial' and o.trial_ends_at is not null then
    v_kind := 'trial'; v_until := o.trial_ends_at;
  else
    v_state := 'active'; -- activated manually with no end date: never expires
  end if;

  if v_state is null then
    v_state := case
      when now() < v_until then case v_kind when 'trial' then 'trial' else 'active' end
      when now() < v_until + make_interval(days => v_grace) then 'grace'
      else 'expired' end;
  end if;

  return jsonb_build_object(
    'state', v_state,
    'kind', v_kind,
    'until', v_until,
    'days_left', case when v_until is null then null else ceil(extract(epoch from (v_until - now())) / 86400)::integer end,
    'grace_ends', case when v_until is null then null else v_until + make_interval(days => v_grace) end,
    'grace_days', v_grace,
    'enforced', v_enforce,
    'locked', v_enforce and v_state in ('expired', 'suspended', 'cancelled'),
    'plan_id', o.plan_id);
end;
$$;

create or replace function public._org_locked(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  -- the platform owner (support mode) is never locked out
  select not public.is_platform_owner() and coalesce((public._billing_state(p_org) ->> 'locked')::boolean, false);
$$;

create or replace function public._account_read_only(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(
    (select a.is_read_only from public.account_access a where a.user_id = auth.uid() and a.organization_id = p_org),
    false);
$$;

-- _is_read_only now = "this account is a viewer" OR "this center is locked".
-- Every existing caller (the table write-lock trigger via _assert_can_write,
-- the upload policies, _sync_wallet, my_access) picks it up unchanged.
create or replace function public._is_read_only(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public._account_read_only(p_org) or public._org_locked(p_org);
$$;

create or replace function public._assert_can_write(p_org uuid)
returns void language plpgsql stable security definer set search_path = public as $$
begin
  -- no signed-in user = a scheduled job / service role: never a viewing account
  if auth.uid() is null then return; end if;
  if public._account_read_only(p_org) then
    raise exception 'هذا حساب عرض — البيانات للاطّلاع فقط' using errcode = 'insufficient_privilege';
  end if;
  if public._org_locked(p_org) then
    raise exception 'انتهى اشتراك المركز — البيانات للاطّلاع فقط حتى تجديد الاشتراك' using errcode = 'insufficient_privilege';
  end if;
end;
$$;

create or replace function public.my_access(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not public.is_org_member(p_org) then jsonb_build_object('is_read_only', false) else
    jsonb_build_object(
      'is_read_only', public._is_read_only(p_org),
      'account_read_only', public._account_read_only(p_org),
      'reason', case when public._account_read_only(p_org) then 'account' when public._org_locked(p_org) then 'billing' end,
      'billing', public._billing_state(p_org)) end;
$$;

revoke all on function public._billing_state(uuid) from public, anon, authenticated;
revoke all on function public._org_locked(uuid) from public, anon, authenticated;
revoke all on function public._account_read_only(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. center admin: overview, report a payment, withdraw it
-- ---------------------------------------------------------------------
create or replace function public.billing_overview(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة للمشرف فقط'; end if;
  return jsonb_build_object(
    'billing', public._billing_state(p_org),
    'org_status', (select status from public.organizations where id = p_org),
    'current_plan', (select jsonb_build_object('id', p.id, 'name', p.name) from public.organizations o join public.plans p on p.id = o.plan_id where o.id = p_org),
    'plans', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'price_cents', p.price_cents, 'yearly_price_cents', p.yearly_price_cents,
                         'currency', p.currency, 'limits', p.limits) order by p.price_cents)
                       from public.plans p where p.is_active), '[]'::jsonb),
    'instructions', nullif(public._platform_setting('billing_instructions', ''), ''),
    'requests', coalesce((select jsonb_agg(jsonb_build_object('id', r.id, 'plan', p.name, 'period', r.period, 'amount_cents', r.amount_cents, 'currency', r.currency,
                            'method', r.method, 'reference', r.reference, 'status', r.status, 'created_at', r.created_at, 'review_note', r.review_note,
                            'period_start', r.period_start, 'period_end', r.period_end) order by r.created_at desc)
                          from (select * from public.billing_requests where organization_id = p_org order by created_at desc limit 20) r
                          join public.plans p on p.id = r.plan_id), '[]'::jsonb));
end;
$$;

create or replace function public.billing_submit_request(p_org uuid, p_plan uuid, p_period text, p_method text, p_reference text default null, p_note text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare pl public.plans; v_amount integer; v_id uuid;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  -- a viewing account may not report payments; a LOCKED center may (that is the point)
  if public._account_read_only(p_org) then raise exception 'هذا حساب عرض — البيانات للاطّلاع فقط' using errcode = 'insufficient_privilege'; end if;
  if p_period not in ('monthly', 'yearly') then raise exception 'اختر المدة'; end if;
  if p_method not in ('bank_transfer', 'wallet', 'cash', 'other') then raise exception 'اختر طريقة الدفع'; end if;
  select * into pl from public.plans where id = p_plan and is_active;
  if not found then raise exception 'الخطة غير متاحة'; end if;
  v_amount := case p_period when 'monthly' then pl.price_cents else pl.yearly_price_cents end;
  if v_amount is null then raise exception 'هذه الخطة غير متاحة بالدفع السنوي'; end if;
  if exists (select 1 from public.billing_requests where organization_id = p_org and status = 'pending') then
    raise exception 'لديك طلب دفع قيد المراجعة — انتظر تأكيده أو ألغِه أولًا';
  end if;
  insert into public.billing_requests (organization_id, plan_id, period, amount_cents, currency, method, reference, note, requested_by)
  values (p_org, p_plan, p_period, v_amount, pl.currency, p_method,
          nullif(left(btrim(coalesce(p_reference, '')), 120), ''), nullif(left(btrim(coalesce(p_note, '')), 500), ''), auth.uid())
  returning id into v_id;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'insert', 'billing_requests', v_id, jsonb_build_object('plan', pl.code, 'period', p_period, 'amount_cents', v_amount));
  return v_id;
end;
$$;

create or replace function public.billing_cancel_request(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r public.billing_requests;
begin
  select * into r from public.billing_requests where id = p_id;
  if not found or not public.is_org_admin(r.organization_id) then raise exception 'الطلب غير موجود'; end if;
  if public._account_read_only(r.organization_id) then raise exception 'هذا حساب عرض — البيانات للاطّلاع فقط' using errcode = 'insufficient_privilege'; end if;
  if r.status <> 'pending' then raise exception 'لا يمكن إلغاء طلب تمت مراجعته'; end if;
  update public.billing_requests set status = 'cancelled' where id = p_id;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. platform owner: settings, review, record a payment received directly
-- ---------------------------------------------------------------------
-- extends the period from whichever is later: now, or the current paid end
create or replace function public._billing_apply(p_request uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r public.billing_requests; v_start timestamptz; v_end timestamptz; v_sub uuid;
begin
  select * into r from public.billing_requests where id = p_request for update;
  select greatest(now(), coalesce(max(current_period_end), now())) into v_start
    from public.subscriptions where organization_id = r.organization_id and status in ('active', 'trialing', 'past_due');
  v_end := v_start + case r.period when 'monthly' then interval '1 month' else interval '1 year' end;

  select id into v_sub from public.subscriptions where organization_id = r.organization_id and billing_provider = 'manual' order by created_at desc limit 1;
  if v_sub is null then
    insert into public.subscriptions (organization_id, plan_id, billing_provider, status, current_period_end)
    values (r.organization_id, r.plan_id, 'manual', 'active', v_end);
  else
    update public.subscriptions set plan_id = r.plan_id, status = 'active', current_period_end = v_end, updated_at = now() where id = v_sub;
  end if;
  update public.organizations set status = 'active', plan_id = r.plan_id, updated_at = now() where id = r.organization_id;
  update public.billing_requests set status = 'approved', reviewed_by = auth.uid(), reviewed_at = now(), period_start = v_start, period_end = v_end
   where id = p_request;
end;
$$;
revoke all on function public._billing_apply(uuid) from public, anon, authenticated;

create or replace function public.platform_review_billing_request(p_id uuid, p_decision text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r public.billing_requests; v_plan text;
begin
  perform public._plat_guard();
  select * into r from public.billing_requests where id = p_id;
  if not found then raise exception 'الطلب غير موجود'; end if;
  if r.status <> 'pending' then raise exception 'تمت مراجعة هذا الطلب مسبقًا'; end if;
  select name into v_plan from public.plans where id = r.plan_id;
  if p_decision = 'approve' then
    perform public._billing_apply(p_id);
    update public.billing_requests set review_note = nullif(btrim(coalesce(p_note, '')), '') where id = p_id;
    select * into r from public.billing_requests where id = p_id;
    perform public._notify(r.organization_id, public._org_admins(r.organization_id), 'billing_reviewed',
      'تم تأكيد الدفع ✓', 'خطة ' || v_plan || ' مفعّلة حتى ' || to_char(r.period_end, 'YYYY-MM-DD'), p_id,
      jsonb_build_object('الحالة', 'تم تأكيد الدفع', 'الخطة', v_plan, 'حتى', to_char(r.period_end, 'YYYY-MM-DD')), true);
  elsif p_decision = 'reject' then
    if nullif(btrim(coalesce(p_note, '')), '') is null then raise exception 'اكتب سبب الرفض ليظهر للمركز'; end if;
    update public.billing_requests set status = 'rejected', reviewed_by = auth.uid(), reviewed_at = now(), review_note = btrim(p_note) where id = p_id;
    perform public._notify(r.organization_id, public._org_admins(r.organization_id), 'billing_reviewed',
      'لم يُؤكَّد الدفع', btrim(p_note), p_id, jsonb_build_object('الحالة', 'لم يُؤكَّد الدفع', 'الخطة', v_plan, 'حتى', ''), true);
  else
    raise exception 'قرار غير معروف';
  end if;
  perform public._plat_log('review_billing', r.organization_id::text, jsonb_build_object('request', p_id, 'decision', p_decision));
end;
$$;

-- A payment received outside the app (cash in hand, a transfer the center never reported).
create or replace function public.platform_record_payment(p_org uuid, p_plan uuid, p_period text, p_amount_cents integer, p_method text, p_note text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare pl public.plans; v_id uuid;
begin
  perform public._plat_guard();
  if not exists (select 1 from public.organizations where id = p_org) then raise exception 'المركز غير موجود'; end if;
  select * into pl from public.plans where id = p_plan;
  if not found then raise exception 'الخطة غير موجودة'; end if;
  if p_period not in ('monthly', 'yearly') then raise exception 'اختر المدة'; end if;
  if p_method not in ('bank_transfer', 'wallet', 'cash', 'other') then raise exception 'اختر طريقة الدفع'; end if;
  if coalesce(p_amount_cents, -1) < 0 then raise exception 'المبلغ غير صحيح'; end if;
  -- an open request from the center is superseded by this direct record
  update public.billing_requests set status = 'cancelled', review_note = 'سُجّلت الدفعة مباشرة من إدارة المنصة'
   where organization_id = p_org and status = 'pending';
  insert into public.billing_requests (organization_id, plan_id, period, amount_cents, currency, method, note, requested_by)
  values (p_org, p_plan, p_period, p_amount_cents, pl.currency, p_method, nullif(btrim(coalesce(p_note, '')), ''), auth.uid())
  returning id into v_id;
  perform public._billing_apply(v_id);
  perform public._plat_log('record_payment', p_org::text, jsonb_build_object('request', v_id, 'plan', pl.code, 'period', p_period, 'amount_cents', p_amount_cents));
  return v_id;
end;
$$;

create or replace function public.platform_billing_requests(p_status text default 'pending', p_limit integer default 100)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._plat_guard();
  return coalesce((select jsonb_agg(x order by x ->> 'created_at' desc) from (
    select jsonb_build_object('id', r.id, 'org_id', o.id, 'org_name', o.name, 'org_slug', o.slug, 'plan', p.name, 'period', r.period,
             'amount_cents', r.amount_cents, 'currency', r.currency, 'method', r.method, 'reference', r.reference, 'note', r.note,
             'status', r.status, 'created_at', r.created_at, 'requested_by', pr.full_name, 'review_note', r.review_note,
             'period_end', r.period_end, 'billing', public._billing_state(o.id)) as x
    from public.billing_requests r
    join public.organizations o on o.id = r.organization_id
    join public.plans p on p.id = r.plan_id
    left join public.profiles pr on pr.id = r.requested_by
    where p_status is null or p_status = '' or r.status = p_status
    order by r.created_at desc limit least(greatest(coalesce(p_limit, 100), 1), 500)) q), '[]'::jsonb);
end;
$$;

create or replace function public.platform_get_billing_settings()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._plat_guard();
  return jsonb_build_object(
    'enforce', public._platform_setting('billing_enforce', 'false') = 'true',
    'grace_days', coalesce(nullif(public._platform_setting('billing_grace_days', '7'), '')::integer, 7),
    'instructions', public._platform_setting('billing_instructions', ''),
    -- what switching enforcement on would lock right now (so it is never a surprise)
    'would_lock', coalesce((select jsonb_agg(jsonb_build_object('id', o.id, 'name', o.name, 'slug', o.slug, 'status', o.status, 'trial_ends_at', o.trial_ends_at) order by o.name)
                            from public.organizations o
                            where (public._billing_state(o.id) ->> 'state') in ('expired', 'suspended', 'cancelled')), '[]'::jsonb));
end;
$$;

create or replace function public.platform_set_billing_settings(p_enforce boolean, p_grace_days integer, p_instructions text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._plat_guard();
  if p_grace_days is null or p_grace_days < 0 or p_grace_days > 60 then raise exception 'مهلة السماح من 0 إلى 60 يومًا'; end if;
  insert into public.platform_settings (key, value) values
    ('billing_enforce', case when coalesce(p_enforce, false) then 'true' else 'false' end),
    ('billing_grace_days', p_grace_days::text),
    ('billing_instructions', left(coalesce(p_instructions, ''), 4000))
  on conflict (key) do update set value = excluded.value, updated_at = now();
  perform public._plat_log('billing_settings', null, jsonb_build_object('enforce', p_enforce, 'grace_days', p_grace_days));
end;
$$;

-- ---------------------------------------------------------------------
-- 6. reminders: admins hear about it 7, 3 and 1 day(s) before the end, and
--    once when the grace period starts. Only while enforcement is on (a
--    warning about a lock that will never happen would be false).
-- ---------------------------------------------------------------------
insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, default_audience, roles, sort) values
  ('billing_reminder', 'تذكير الاشتراك', '{العنوان}', '{الوصف}', '{العنوان,الوصف}', 'source', '{admin}', 210),
  ('billing_reviewed', 'نتيجة مراجعة الدفع', '{الحالة}', '{الخطة} · حتى {حتى}', '{الحالة,الخطة,حتى}', 'source', '{admin}', 220)
on conflict (event_key) do nothing;

create or replace function public.send_billing_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare o record; b jsonb; v_days integer; v_n integer := 0; v_what text;
begin
  if public._platform_setting('billing_enforce', 'false') <> 'true' then return 0; end if;
  for o in select id from public.organizations where status in ('trial', 'active') loop
    b := public._billing_state(o.id);
    v_days := (b ->> 'days_left')::integer;
    v_what := case b ->> 'kind' when 'trial' then 'الفترة التجريبية' else 'اشتراك المركز' end;
    if b ->> 'state' in ('trial', 'active') and v_days in (7, 3, 1) then
      perform public._notify(o.id, public._org_admins(o.id), 'billing_reminder',
        'ينتهي ' || v_what || ' خلال ' || v_days || ' ' || case when v_days = 1 then 'يوم' else 'أيام' end,
        'جدّد الاشتراك من صفحة «الاشتراك والدفع» حتى لا يتحول المركز للقراءة فقط', null, null, true,
        'billing|' || o.id || '|' || (b ->> 'until') || '|' || v_days);
      v_n := v_n + 1;
    elsif b ->> 'state' = 'grace' then
      perform public._notify(o.id, public._org_admins(o.id), 'billing_reminder',
        'انتهى ' || v_what, 'مهلة حتى ' || to_char((b ->> 'grace_ends')::timestamptz, 'YYYY-MM-DD') || ' ثم يتحول المركز للقراءة فقط', null, null, true,
        'billing|' || o.id || '|' || (b ->> 'until') || '|grace');
      v_n := v_n + 1;
    end if;
  end loop;
  return v_n;
end;
$$;
revoke all on function public.send_billing_reminders() from public, anon, authenticated;
select cron.schedule('billing-reminders', '0 6 * * *', 'select public.send_billing_reminders()');

-- ---------------------------------------------------------------------
-- 7. privileges
-- ---------------------------------------------------------------------
revoke all on function public.billing_overview(uuid) from public, anon;
revoke all on function public.billing_submit_request(uuid, uuid, text, text, text, text) from public, anon;
revoke all on function public.billing_cancel_request(uuid) from public, anon;
revoke all on function public.platform_review_billing_request(uuid, text, text) from public, anon;
revoke all on function public.platform_record_payment(uuid, uuid, text, integer, text, text) from public, anon;
revoke all on function public.platform_billing_requests(text, integer) from public, anon;
revoke all on function public.platform_get_billing_settings() from public, anon;
revoke all on function public.platform_set_billing_settings(boolean, integer, text) from public, anon;
grant execute on function public.billing_overview(uuid) to authenticated;
grant execute on function public.billing_submit_request(uuid, uuid, text, text, text, text) to authenticated;
grant execute on function public.billing_cancel_request(uuid) to authenticated;
grant execute on function public.platform_review_billing_request(uuid, text, text) to authenticated;
grant execute on function public.platform_record_payment(uuid, uuid, text, integer, text, text) to authenticated;
grant execute on function public.platform_billing_requests(text, integer) to authenticated;
grant execute on function public.platform_get_billing_settings() to authenticated;
grant execute on function public.platform_set_billing_settings(boolean, integer, text) to authenticated;

notify pgrst, 'reload schema';
