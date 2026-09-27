-- =========================================================================
-- 0067_plans_usage_alerts.sql
-- Billing, continued:
--   1. The four launch plans (free / basic / advanced / enterprise).
--   2. A free plan to fall back to: when a trial or paid period ends (after
--      the grace period) a center whose size fits the free plan moves onto it
--      instead of becoming read-only. Only a center too big for it is locked.
--   3. Plan usage (students / teachers vs the plan's limits) exposed to the
--      center's staff, so the apps can say "5 students left on your plan".
--   4. Alerts to the center's admins AND teachers: subscription ending in
--      60 / 30 / 7 / 3 / 1 day(s), grace started, moved to the free plan,
--      student/teacher capacity nearly or completely used.
--   5. One list for the platform owner: every center that needs attention.
-- Like 0066, nothing here locks or downgrades anything while the platform
-- setting billing_enforce is off.
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. launch plans (existing codes are left untouched: edit them in the console)
-- ---------------------------------------------------------------------
insert into public.plans (code, name, price_cents, yearly_price_cents, currency, limits, features, is_active) values
  ('free',       'مجانية (بذرة)', 0,    0,     'USD', '{"max_students": 30,  "max_teachers": 2}',     '{}', true),
  ('basic',      'الأساسية',      1200, 12000, 'USD', '{"max_students": 100, "max_teachers": 8}',     '{}', true),
  ('advanced',   'المتقدمة',      2500, 25000, 'USD', '{"max_students": 300, "max_teachers": 25}',    '{}', true),
  ('enterprise', 'المؤسسات',      5000, 50000, 'USD', '{"max_students": null, "max_teachers": null}', '{}', true)
on conflict (code) do nothing;

-- the plan an expired center falls back to (the owner can point it elsewhere, or clear it)
insert into public.platform_settings (key, value)
select 'billing_free_plan_id', id::text from public.plans where code = 'free'
on conflict (key) do nothing;

create or replace function public._free_plan_id()
returns uuid language sql stable security definer set search_path = public as $$
  select p.id from public.plans p
  where p.id = nullif(public._platform_setting('billing_free_plan_id', ''), '')::uuid and p.is_active;
$$;
revoke all on function public._free_plan_id() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 2. usage vs the plan
-- ---------------------------------------------------------------------
create or replace function public._org_usage(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  -- counted exactly like _enforce_plan_limits (0034) so the numbers never disagree with the refusal
  with l as (
    select nullif(p.limits ->> 'max_students', '')::integer as max_s, nullif(p.limits ->> 'max_teachers', '')::integer as max_t, p.name as plan_name, p.id as plan_id
    from public.organizations o left join public.plans p on p.id = o.plan_id where o.id = p_org
  ), c as (
    select (select count(*) from public.students_profile where organization_id = p_org and status = 'active')::integer as s,
           (select count(*) from public.organization_members where organization_id = p_org and role = 'teacher' and status = 'active')::integer as t
  )
  select jsonb_build_object(
    'plan_id', l.plan_id, 'plan_name', l.plan_name,
    'students', c.s, 'max_students', l.max_s, 'students_left', case when l.max_s is null then null else greatest(l.max_s - c.s, 0) end,
    'teachers', c.t, 'max_teachers', l.max_t, 'teachers_left', case when l.max_t is null then null else greatest(l.max_t - c.t, 0) end)
  from l, c;
$$;
revoke all on function public._org_usage(uuid) from public, anon, authenticated;

create or replace function public._fits_plan(p_org uuid, p_plan uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(
    (select (nullif(p.limits ->> 'max_students', '') is null
               or (select count(*) from public.students_profile where organization_id = p_org and status = 'active') <= (p.limits ->> 'max_students')::integer)
        and (nullif(p.limits ->> 'max_teachers', '') is null
               or (select count(*) from public.organization_members where organization_id = p_org and role = 'teacher' and status = 'active') <= (p.limits ->> 'max_teachers')::integer)
     from public.plans p where p.id = p_plan), false);
$$;
revoke all on function public._fits_plan(uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. billing state gains 'free' (on the free plan: never expires, never locked)
-- ---------------------------------------------------------------------
create or replace function public._billing_state(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare o public.organizations; v_grace integer; v_enforce boolean; v_paid timestamptz; v_until timestamptz; v_state text; v_kind text;
        v_free uuid := public._free_plan_id(); v_grace_i interval;
begin
  select * into o from public.organizations where id = p_org;
  if not found then return null; end if;
  v_grace := coalesce(nullif(public._platform_setting('billing_grace_days', '7'), '')::integer, 7);
  v_grace_i := make_interval(days => v_grace);
  v_enforce := public._platform_setting('billing_enforce', 'false') = 'true';
  select max(current_period_end) into v_paid from public.subscriptions
   where organization_id = p_org and status in ('active', 'trialing', 'past_due');

  if o.status in ('suspended', 'cancelled') then
    v_state := o.status;
  elsif v_paid is not null and now() < v_paid + v_grace_i then
    v_kind := 'paid'; v_until := v_paid;                 -- a running (or just-ended) paid period
  elsif o.status = 'trial' and o.trial_ends_at is not null and now() < o.trial_ends_at + v_grace_i then
    v_kind := 'trial'; v_until := o.trial_ends_at;       -- a running (or just-ended) trial
  elsif v_free is not null and o.plan_id = v_free then
    v_state := 'free';                                   -- on the free plan: nothing ever runs out
  elsif v_paid is not null then
    v_kind := 'paid'; v_until := v_paid;
  elsif o.status = 'trial' and o.trial_ends_at is not null then
    v_kind := 'trial'; v_until := o.trial_ends_at;
  else
    v_state := 'active';                                 -- activated by hand with no end date
  end if;

  if v_state is null then
    v_state := case
      when now() < v_until then case v_kind when 'trial' then 'trial' else 'active' end
      when now() < v_until + v_grace_i then 'grace'
      else 'expired' end;
  end if;

  return jsonb_build_object(
    'state', v_state,
    'kind', v_kind,
    'until', v_until,
    'days_left', case when v_until is null then null else ceil(extract(epoch from (v_until - now())) / 86400)::integer end,
    'grace_ends', case when v_until is null then null else v_until + v_grace_i end,
    'grace_days', v_grace,
    'enforced', v_enforce,
    'locked', v_enforce and v_state in ('expired', 'suspended', 'cancelled'),
    'plan_id', o.plan_id,
    'free_plan_available', v_free is not null);
end;
$$;

-- my_access: staff (admins + teachers) also get the plan usage
create or replace function public.my_access(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not public.is_org_member(p_org) then jsonb_build_object('is_read_only', false) else
    jsonb_build_object(
      'is_read_only', public._is_read_only(p_org),
      'account_read_only', public._account_read_only(p_org),
      'reason', case when public._account_read_only(p_org) then 'account' when public._org_locked(p_org) then 'billing' end,
      'billing', public._billing_state(p_org),
      'usage', case when public.is_org_staff(p_org) then public._org_usage(p_org) end) end;
$$;

-- the admin's billing page shows the usage too
create or replace function public.billing_overview(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة للمشرف فقط'; end if;
  return jsonb_build_object(
    'billing', public._billing_state(p_org),
    'usage', public._org_usage(p_org),
    'org_status', (select status from public.organizations where id = p_org),
    'current_plan', (select jsonb_build_object('id', p.id, 'name', p.name) from public.organizations o join public.plans p on p.id = o.plan_id where o.id = p_org),
    'plans', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'price_cents', p.price_cents, 'yearly_price_cents', p.yearly_price_cents,
                         'currency', p.currency, 'limits', p.limits, 'is_free', p.id = public._free_plan_id()) order by p.price_cents)
                       from public.plans p where p.is_active), '[]'::jsonb),
    'instructions', nullif(public._platform_setting('billing_instructions', ''), ''),
    'requests', coalesce((select jsonb_agg(jsonb_build_object('id', r.id, 'plan', p.name, 'period', r.period, 'amount_cents', r.amount_cents, 'currency', r.currency,
                            'method', r.method, 'reference', r.reference, 'status', r.status, 'created_at', r.created_at, 'review_note', r.review_note,
                            'period_start', r.period_start, 'period_end', r.period_end) order by r.created_at desc)
                          from (select * from public.billing_requests where organization_id = p_org order by created_at desc limit 20) r
                          join public.plans p on p.id = r.plan_id), '[]'::jsonb));
end;
$$;

-- nobody pays for the free plan
create or replace function public.billing_submit_request(p_org uuid, p_plan uuid, p_period text, p_method text, p_reference text default null, p_note text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare pl public.plans; v_amount integer; v_id uuid;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if public._account_read_only(p_org) then raise exception 'هذا حساب عرض — البيانات للاطّلاع فقط' using errcode = 'insufficient_privilege'; end if;
  if p_period not in ('monthly', 'yearly') then raise exception 'اختر المدة'; end if;
  if p_method not in ('bank_transfer', 'wallet', 'cash', 'other') then raise exception 'اختر طريقة الدفع'; end if;
  select * into pl from public.plans where id = p_plan and is_active;
  if not found then raise exception 'الخطة غير متاحة'; end if;
  if p_plan = public._free_plan_id() then raise exception 'الخطة المجانية لا تحتاج دفعًا'; end if;
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

-- ---------------------------------------------------------------------
-- 4. alerts to the center (admins + teachers) and the daily job
-- ---------------------------------------------------------------------
insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, default_audience, roles, sort) values
  ('capacity_warning', 'سعة الخطة', '{العنوان}', '{الوصف}', '{العنوان,الوصف}', 'source', '{admin,teacher}', 230),
  ('billing_downgraded', 'التحويل للخطة المجانية', '{العنوان}', '{الوصف}', '{العنوان,الوصف}', 'source', '{admin,teacher}', 240)
on conflict (event_key) do nothing;
update public.notification_defaults set roles = '{admin,teacher}' where event_key = 'billing_reminder';

create or replace function public._org_staff_users(p_org uuid)
returns uuid[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(user_id), array[]::uuid[]) from public.organization_members
   where organization_id = p_org and role::text in ('admin', 'teacher') and status = 'active';
$$;
revoke all on function public._org_staff_users(uuid) from public, anon, authenticated;

create or replace function public._left_text(p_n integer, p_one text, p_many text)
returns text language sql immutable as $$
  select case when p_n = 1 then p_one || ' واحد' when p_n = 2 then p_one || 'ان' else p_n || ' ' || p_many end;
$$;
revoke all on function public._left_text(integer, text, text) from public, anon, authenticated;

-- Daily. Replaces send_billing_reminders (0066): expiry reminders, the free-plan
-- fallback and capacity alerts in one pass. Every alert is deduplicated, so a
-- rerun (or a manual call) never repeats one.
create or replace function public.send_billing_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare o record; b jsonb; u jsonb; v_days integer; v_n integer := 0; v_what text; v_staff uuid[]; v_admins uuid[];
        v_free uuid := public._free_plan_id(); v_left integer; v_key text;
begin
  if public._platform_setting('billing_enforce', 'false') <> 'true' then return 0; end if;
  for o in select id from public.organizations where status in ('trial', 'active') loop
    b := public._billing_state(o.id);
    u := public._org_usage(o.id);
    v_staff := public._org_staff_users(o.id);
    v_admins := public._org_admins(o.id);
    v_days := (b ->> 'days_left')::integer;
    v_what := case b ->> 'kind' when 'trial' then 'الفترة التجريبية' else 'اشتراك المركز' end;

    -- a) expiry ahead: 60 / 30 / 7 / 3 / 1 day(s)
    if b ->> 'state' in ('trial', 'active') and v_days in (60, 30, 7, 3, 1) then
      perform public._notify(o.id, v_staff, 'billing_reminder',
        case b ->> 'kind' when 'trial' then 'تنتهي ' else 'ينتهي ' end || v_what || ' خلال '
          || case v_days when 60 then 'شهرين' when 30 then 'شهر' when 1 then 'يوم واحد' else v_days || ' أيام' end,
        case when v_free is not null then 'بعدها ينتقل المركز للخطة المجانية إن كان حجمه يناسبها، وإلا يصبح للقراءة فقط — جدّد من «الاشتراك والدفع»'
             else 'جدّد الاشتراك من صفحة «الاشتراك والدفع» حتى لا يتحول المركز للقراءة فقط' end,
        null, null, true, 'billing|' || o.id || '|' || (b ->> 'until') || '|' || v_days);
      v_n := v_n + 1;
    -- b) ended, grace running
    elsif b ->> 'state' = 'grace' then
      perform public._notify(o.id, v_staff, 'billing_reminder',
        case b ->> 'kind' when 'trial' then 'انتهت ' else 'انتهى ' end || v_what,
        'مهلة حتى ' || to_char((b ->> 'grace_ends')::timestamptz, 'YYYY-MM-DD') || ' — جدّد من «الاشتراك والدفع»', null, null, true,
        'billing|' || o.id || '|' || (b ->> 'until') || '|grace');
      v_n := v_n + 1;
    -- c) grace over: fall back to the free plan when the center fits it
    elsif b ->> 'state' = 'expired' and v_free is not null and public._fits_plan(o.id, v_free) then
      update public.organizations set plan_id = v_free, status = 'active', updated_at = now() where id = o.id;
      perform public._notify(o.id, v_staff, 'billing_downgraded', 'انتقل المركز إلى الخطة المجانية',
        'انتهى ' || v_what || ' — يعمل المركز الآن على الخطة المجانية بحدودها. للترقية: «الاشتراك والدفع»', null, null, true,
        'downgrade|' || o.id || '|' || (b ->> 'until'));
      insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
      values (o.id, null, 'update', 'organizations', o.id, jsonb_build_object('billing', 'downgraded_to_free'));
      v_n := v_n + 1;
      u := public._org_usage(o.id); -- the limits just changed
    end if;

    -- d) capacity: <= 5 students left, <= 1 teacher left, full
    v_left := (u ->> 'students_left')::integer;
    if v_left is not null and v_left <= 5 then
      v_key := 'cap|' || o.id || '|s|' || (u ->> 'plan_id') || '|' || (u ->> 'max_students') || '|' || case when v_left = 0 then 'full' else 'low' end;
      perform public._notify(o.id, v_staff, 'capacity_warning',
        case when v_left = 0 then 'وصل المركز للحد الأقصى من الطلاب (' || (u ->> 'max_students') || ')'
             else 'تبقى ' || public._left_text(v_left, 'طالب', 'طلاب') || ' يمكن إضافتهم ضمن خطة المركز' end,
        'للمزيد رقّوا الخطة من «الاشتراك والدفع»', null, null, true, v_key);
      v_n := v_n + 1;
    end if;
    v_left := (u ->> 'teachers_left')::integer;
    if v_left is not null and v_left <= 1 then
      v_key := 'cap|' || o.id || '|t|' || (u ->> 'plan_id') || '|' || (u ->> 'max_teachers') || '|' || case when v_left = 0 then 'full' else 'low' end;
      perform public._notify(o.id, v_admins, 'capacity_warning',
        case when v_left = 0 then 'وصل المركز للحد الأقصى من المعلمين (' || (u ->> 'max_teachers') || ')'
             else 'تبقى إضافة معلم واحد فقط ضمن خطة المركز' end,
        'للمزيد رقّوا الخطة من «الاشتراك والدفع»', null, null, true, v_key);
      v_n := v_n + 1;
    end if;
  end loop;
  return v_n;
end;
$$;
revoke all on function public.send_billing_reminders() from public, anon, authenticated;
-- 'billing-reminders' (0066) keeps running daily and now calls the version above.

-- ---------------------------------------------------------------------
-- 5. the platform owner's attention list
-- ---------------------------------------------------------------------
create or replace function public.platform_billing_alerts()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._plat_guard();
  return jsonb_build_object(
    'enforced', public._platform_setting('billing_enforce', 'false') = 'true',
    'pending_payments', (select count(*) from public.billing_requests where status = 'pending'),
    'rows', coalesce((
      select jsonb_agg(x order by (x ->> 'severity')::integer, x ->> 'name') from (
        select jsonb_build_object(
          'id', o.id, 'name', o.name, 'slug', o.slug, 'plan', p.name, 'billing', b, 'usage', u,
          'pending_payment', exists (select 1 from public.billing_requests r where r.organization_id = o.id and r.status = 'pending'),
          'reasons', array_remove(array[
            case when b ->> 'state' in ('expired', 'suspended', 'cancelled') then 'locked' end,
            case when b ->> 'state' = 'grace' then 'grace' end,
            case when b ->> 'state' in ('trial', 'active') and (b ->> 'days_left')::integer <= case b ->> 'kind' when 'trial' then 7 else 60 end then 'expiring' end,
            case when (u ->> 'students_left')::integer <= 5 then 'students' end,
            case when (u ->> 'teachers_left')::integer <= 1 then 'teachers' end,
            case when exists (select 1 from public.billing_requests r where r.organization_id = o.id and r.status = 'pending') then 'payment' end], null),
          'severity', case
            when b ->> 'state' in ('expired', 'suspended', 'cancelled') then 1
            when b ->> 'state' = 'grace' or exists (select 1 from public.billing_requests r where r.organization_id = o.id and r.status = 'pending') then 2
            when (b ->> 'days_left')::integer <= 7 or (u ->> 'students_left')::integer = 0 or (u ->> 'teachers_left')::integer = 0 then 3
            else 4 end) as x
        from public.organizations o
        left join public.plans p on p.id = o.plan_id
        cross join lateral (select public._billing_state(o.id) as b, public._org_usage(o.id) as u) s
      ) q
      where jsonb_array_length(x -> 'reasons') > 0), '[]'::jsonb));
end;
$$;
revoke all on function public.platform_billing_alerts() from public, anon;
grant execute on function public.platform_billing_alerts() to authenticated;

notify pgrst, 'reload schema';
