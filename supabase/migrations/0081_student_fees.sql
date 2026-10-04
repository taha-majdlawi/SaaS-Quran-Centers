-- =====================================================================
-- 0081: student fees (optional - off by default)
-- ---------------------------------------------------------------------
-- Most Quran centers are free, so the whole feature stays hidden until the
-- admin switches it on (organization_settings 'flag_fees_enabled'); the
-- platform owner can also switch it off ('fees' in the feature catalog).
--
--   fee_plans          what a center charges: monthly (issued automatically
--                      every month), per term or once (issued by the admin)
--   student_fee_plans  each student's plan, discount % or full exemption
--   fee_charges        what a student owes: auto monthly, issued for a plan,
--                      or a one-off; can be waived / cancelled
--   fee_payments       money received, with a receipt number per center;
--                      voided rather than deleted
--
-- A student's balance = charges already due - payments (positive = owes).
-- No payment-to-charge allocation: centers think in "how much is left".
-- Only the admin sees and records money; a family sees its own children.
-- Families get a receipt notification on payment and an overdue reminder
-- (at most weekly), in their language (0080).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. tables
-- ---------------------------------------------------------------------
create table if not exists public.fee_plans (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  name            text not null check (char_length(btrim(name)) between 1 and 80),
  amount          numeric(12,2) not null check (amount >= 0),
  period          text not null check (period in ('monthly', 'term', 'once')),
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);
create index if not exists fee_plans_org_idx on public.fee_plans (organization_id);

create table if not exists public.student_fee_plans (
  student_id       uuid primary key references public.students_profile (id) on delete cascade,
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  plan_id          uuid references public.fee_plans (id) on delete set null,
  discount_percent numeric(5,2) not null default 0 check (discount_percent between 0 and 100),
  exempt           boolean not null default false,
  note             text check (note is null or char_length(note) <= 300),
  updated_at       timestamptz not null default now(),
  updated_by       uuid
);
create index if not exists student_fee_plans_org_idx on public.student_fee_plans (organization_id, plan_id);

create table if not exists public.fee_charges (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  student_id      uuid not null references public.students_profile (id) on delete cascade,
  plan_id         uuid references public.fee_plans (id) on delete set null,
  period_key      text,                                    -- '2026-10' for an automatic monthly charge
  title           text not null check (char_length(btrim(title)) between 1 and 120),
  amount          numeric(12,2) not null check (amount >= 0),
  due_date        date not null,
  status          text not null default 'open' check (status in ('open', 'waived', 'cancelled')),
  created_at      timestamptz not null default now(),
  created_by      uuid
);
create index if not exists fee_charges_student_idx on public.fee_charges (student_id, due_date);
create index if not exists fee_charges_org_idx on public.fee_charges (organization_id, due_date);
-- one automatic monthly charge per student and month, whatever happens to the plan
create unique index if not exists fee_charges_auto_key on public.fee_charges (student_id, period_key) where period_key is not null;

create table if not exists public.fee_payments (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  student_id      uuid not null references public.students_profile (id) on delete cascade,
  amount          numeric(12,2) not null check (amount > 0),
  method          text not null default 'cash' check (method in ('cash', 'transfer', 'card', 'wallet', 'other')),
  paid_on         date not null,
  receipt_no      integer not null,
  note            text check (note is null or char_length(note) <= 300),
  client_ref      uuid,
  recorded_by     uuid,
  created_at      timestamptz not null default now(),
  voided_at       timestamptz,
  voided_by       uuid,
  void_reason     text,
  unique (organization_id, receipt_no)
);
create index if not exists fee_payments_student_idx on public.fee_payments (student_id, paid_on desc);
create index if not exists fee_payments_org_idx on public.fee_payments (organization_id, paid_on desc);
create unique index if not exists fee_payments_client_ref_key on public.fee_payments (client_ref) where client_ref is not null;

alter table public.fee_plans enable row level security;
alter table public.student_fee_plans enable row level security;
alter table public.fee_charges enable row level security;
alter table public.fee_payments enable row level security;
-- money is read and written only through the RPCs below
revoke all on public.fee_plans, public.student_fee_plans, public.fee_charges, public.fee_payments from anon, authenticated;

do $$
declare t text;
begin
  foreach t in array array['fee_plans', 'student_fee_plans', 'fee_charges', 'fee_payments'] loop
    execute format('drop trigger if exists a_deny_readonly_write on public.%I', t);
    execute format('create trigger a_deny_readonly_write before insert or update or delete on public.%I
                    for each row execute function public._deny_readonly_write()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 2. switches and helpers
-- ---------------------------------------------------------------------
create or replace function public._feature_catalog()
returns text[] language sql immutable as $$
  select array['students', 'circles', 'attendance', 'serd', 'points', 'badges', 'market', 'circle-challenges', 'activities',
               'calendar', 'announcements', 'chat', 'notifications', 'reports', 'certificates', 'fees'];
$$;

create or replace function public._fees_enabled(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.org_setting(p_org, 'flag_fees_enabled', 'false') = 'true' and public.platform_feature_enabled(p_org, 'fees');
$$;

create or replace function public._fees_currency(p_org uuid)
returns text language sql stable security definer set search_path = public as $$
  select coalesce(nullif(public.org_setting(p_org, 'fees_currency', ''), ''),
                  (select currency_symbol from public.market_config where organization_id = p_org), '');
$$;

create or replace function public._fees_today(p_org uuid)
returns date language sql stable security definer set search_path = public as $$
  select (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
$$;

-- the admin, for every money write (and the feature must be on)
create or replace function public._fees_admin(p_org uuid)
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if not public._fees_enabled(p_org) then raise exception 'الرسوم غير مفعّلة في هذا المركز'; end if;
end;
$$;

-- "12.5" / "12" - no trailing zeros
create or replace function public._money(p numeric)
returns text language sql immutable as $$
  select rtrim(rtrim(to_char(coalesce(p, 0), 'FM999999990.00'), '0'), '.');
$$;

-- where a student stands: charged so far, paid, balance (positive = owes), what is overdue and still to come
create or replace function public._fee_balance(p_org uuid, p_student uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  with t as (select public._fees_today(p_org) as today),
  c as (
    select coalesce(sum(amount) filter (where status = 'open' and due_date <= t.today), 0) as due,
           coalesce(sum(amount) filter (where status = 'open' and due_date > t.today), 0) as upcoming,
           min(due_date) filter (where status = 'open' and due_date <= t.today) as first_due
      from public.fee_charges, t where student_id = p_student and organization_id = p_org),
  p as (select coalesce(sum(amount), 0) as paid, max(paid_on) as last_paid
          from public.fee_payments where student_id = p_student and organization_id = p_org and voided_at is null)
  select jsonb_build_object('due', c.due, 'paid', p.paid, 'balance', c.due - p.paid, 'upcoming', c.upcoming,
                            'last_paid', p.last_paid, 'first_due', c.first_due)
    from c, p;
$$;

-- the next receipt number of a center (callers hold the center's advisory lock)
create or replace function public._fee_next_receipt(p_org uuid)
returns integer language sql stable security definer set search_path = public as $$
  select coalesce(max(receipt_no), 0) + 1 from public.fee_payments where organization_id = p_org;
$$;

do $$
declare f text;
begin
  foreach f in array array['_fees_enabled(uuid)', '_fees_currency(uuid)', '_fees_today(uuid)', '_fees_admin(uuid)',
                           '_money(numeric)', '_fee_balance(uuid, uuid)', '_fee_next_receipt(uuid)'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 3. notifications (wording per language, as in 0080)
-- ---------------------------------------------------------------------
insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, lead_hours, roles, sort) values
  ('fee_payment', 'إيصال دفع الرسوم', 'تم استلام دفعة {المبلغ}', '{اسم_الطالب} · إيصال رقم {الإيصال} · المتبقي {المتبقي}',
     array['اسم_الطالب','المبلغ','الإيصال','المتبقي'], null, array['guardian','student'], 250),
  ('fee_overdue', 'تذكير الرسوم المستحقة', 'رسوم مستحقة: {اسم_الطالب}', 'المبلغ المستحق {المتبقي} — يرجى السداد لإدارة المركز',
     array['اسم_الطالب','المتبقي'], null, array['guardian','student'], 251)
on conflict (event_key) do update set name = excluded.name, available_vars = excluded.available_vars, roles = excluded.roles, sort = excluded.sort;

insert into public.notification_default_texts (event_key, lang, title_template, body_template) values
  ('fee_payment', 'en', 'Payment received: {المبلغ}', '{اسم_الطالب} · receipt no. {الإيصال} · balance {المتبقي}'),
  ('fee_payment', 'tr', 'Ödeme alındı: {المبلغ}', '{اسم_الطالب} · makbuz no. {الإيصال} · kalan {المتبقي}'),
  ('fee_payment', 'fr', 'Paiement reçu : {المبلغ}', '{اسم_الطالب} · reçu n° {الإيصال} · reste {المتبقي}'),
  ('fee_overdue', 'en', 'Fees due: {اسم_الطالب}', 'Amount due {المتبقي} — please pay the center’s office'),
  ('fee_overdue', 'tr', 'Ödenmesi gereken ücret: {اسم_الطالب}', 'Ödenecek tutar {المتبقي} — lütfen merkez yönetimine ödeyin'),
  ('fee_overdue', 'fr', 'Frais dus : {اسم_الطالب}', 'Montant dû {المتبقي} — merci de régler auprès du centre')
on conflict (event_key, lang) do update set title_template = excluded.title_template, body_template = excluded.body_template;

-- ---------------------------------------------------------------------
-- 4. settings
-- ---------------------------------------------------------------------
create or replace function public.get_fee_settings(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not (public.is_org_admin(p_org) or public.is_org_member(p_org)) then raise exception 'غير مصرّح'; end if;
  return jsonb_build_object(
    'enabled', public._fees_enabled(p_org),
    'platform_allowed', public.platform_feature_enabled(p_org, 'fees'),
    'currency', public._fees_currency(p_org),
    'due_day', public.org_setting(p_org, 'fees_due_day', '1')::integer,
    'reminder_days', public.org_setting(p_org, 'fees_reminder_days', '7')::integer);
end;
$$;

create or replace function public.set_fee_settings(p_org uuid, p_enabled boolean, p_currency text default null,
                                                  p_due_day integer default null, p_reminder_days integer default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if p_due_day is not null and p_due_day not between 1 and 28 then raise exception 'يوم الاستحقاق بين 1 و28'; end if;
  if p_reminder_days is not null and p_reminder_days not between 0 and 60 then raise exception 'أيام التذكير بين 0 و60 (0 = بلا تذكير)'; end if;
  insert into public.organization_settings (organization_id, key, value)
  select p_org, k, v from (values
      ('flag_fees_enabled', case when p_enabled then 'true' else 'false' end),
      ('fees_currency', left(btrim(p_currency), 8)),
      ('fees_due_day', p_due_day::text),
      ('fees_reminder_days', p_reminder_days::text)) s (k, v)
   where v is not null
  on conflict (organization_id, key) do update set value = excluded.value;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, diff)
  values (p_org, auth.uid(), 'update', 'organization_settings',
          jsonb_build_object('fees_enabled', p_enabled, 'currency', p_currency, 'due_day', p_due_day, 'reminder_days', p_reminder_days));
end;
$$;

-- ---------------------------------------------------------------------
-- 5. plans and students' plans
-- ---------------------------------------------------------------------
create or replace function public.save_fee_plan(p_org uuid, p_id uuid, p_name text, p_amount numeric, p_period text, p_active boolean default true)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  perform public._fees_admin(p_org);
  perform public._assert_can_write(p_org);
  if nullif(btrim(coalesce(p_name, '')), '') is null then raise exception 'اسم الخطة مطلوب'; end if;
  if p_amount is null or p_amount < 0 then raise exception 'المبلغ غير صحيح'; end if;
  if p_period not in ('monthly', 'term', 'once') then raise exception 'نوع الخطة غير صحيح'; end if;
  if p_id is null then
    insert into public.fee_plans (organization_id, name, amount, period, is_active)
    values (p_org, btrim(p_name), round(p_amount, 2), p_period, coalesce(p_active, true)) returning id into v_id;
  else
    update public.fee_plans set name = btrim(p_name), amount = round(p_amount, 2), period = p_period, is_active = coalesce(p_active, true)
     where id = p_id and organization_id = p_org returning id into v_id;
    if v_id is null then raise exception 'الخطة غير موجودة'; end if;
  end if;
  return v_id;
end;
$$;

-- a plan already charged is kept (deactivated) so old charges keep their source
create or replace function public.delete_fee_plan(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._fees_admin(p_org);
  perform public._assert_can_write(p_org);
  if exists (select 1 from public.fee_charges where plan_id = p_id) then
    update public.fee_plans set is_active = false where id = p_id and organization_id = p_org;
  else
    update public.student_fee_plans set plan_id = null where plan_id = p_id and organization_id = p_org;
    delete from public.fee_plans where id = p_id and organization_id = p_org;
  end if;
end;
$$;

-- one or many students on a plan (p_plan null = no plan); discount / exemption per student
create or replace function public.set_students_fee_plan(p_org uuid, p_students uuid[], p_plan uuid,
                                                       p_discount numeric default 0, p_exempt boolean default false, p_note text default null)
returns integer language plpgsql security definer set search_path = public as $$
declare v_n integer;
begin
  perform public._fees_admin(p_org);
  perform public._assert_can_write(p_org);
  if p_plan is not null and not exists (select 1 from public.fee_plans where id = p_plan and organization_id = p_org) then
    raise exception 'الخطة غير موجودة';
  end if;
  if coalesce(p_discount, 0) not between 0 and 100 then raise exception 'الخصم بين 0 و100٪'; end if;
  insert into public.student_fee_plans (student_id, organization_id, plan_id, discount_percent, exempt, note, updated_at, updated_by)
  select s.id, p_org, p_plan, coalesce(p_discount, 0), coalesce(p_exempt, false), nullif(left(btrim(coalesce(p_note, '')), 300), ''), now(), auth.uid()
    from public.students_profile s where s.organization_id = p_org and s.id = any (coalesce(p_students, '{}'))
  on conflict (student_id) do update set plan_id = excluded.plan_id, discount_percent = excluded.discount_percent,
    exempt = excluded.exempt, note = excluded.note, updated_at = now(), updated_by = auth.uid();
  get diagnostics v_n = row_count;
  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
-- 6. charges
-- ---------------------------------------------------------------------
-- what a student on this plan pays after their discount
create or replace function public._fee_amount(p_amount numeric, p_discount numeric)
returns numeric language sql immutable as $$
  select round(coalesce(p_amount, 0) * (100 - coalesce(p_discount, 0)) / 100, 2);
$$;
revoke all on function public._fee_amount(numeric, numeric) from public, anon, authenticated;

-- a term / one-off plan: charge everyone on it now (the exempt are skipped)
create or replace function public.issue_fee_charges(p_org uuid, p_plan uuid, p_title text, p_due_date date)
returns integer language plpgsql security definer set search_path = public as $$
declare pl public.fee_plans; v_n integer;
begin
  perform public._fees_admin(p_org);
  perform public._assert_can_write(p_org);
  select * into pl from public.fee_plans where id = p_plan and organization_id = p_org;
  if not found then raise exception 'الخطة غير موجودة'; end if;
  if nullif(btrim(coalesce(p_title, '')), '') is null then raise exception 'عنوان الرسوم مطلوب'; end if;
  insert into public.fee_charges (organization_id, student_id, plan_id, title, amount, due_date, created_by)
  select p_org, sp.student_id, pl.id, left(btrim(p_title), 120), public._fee_amount(pl.amount, sp.discount_percent),
         coalesce(p_due_date, public._fees_today(p_org)), auth.uid()
    from public.student_fee_plans sp join public.students_profile s on s.id = sp.student_id
   where sp.organization_id = p_org and sp.plan_id = pl.id and not sp.exempt and s.status = 'active'
     and public._fee_amount(pl.amount, sp.discount_percent) > 0;
  get diagnostics v_n = row_count;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'create', 'fee_charges', pl.id, jsonb_build_object('title', p_title, 'students', v_n));
  return v_n;
end;
$$;

create or replace function public.add_fee_charge(p_org uuid, p_student uuid, p_title text, p_amount numeric, p_due_date date default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  perform public._fees_admin(p_org);
  perform public._assert_can_write(p_org);
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then raise exception 'الطالب غير موجود'; end if;
  if nullif(btrim(coalesce(p_title, '')), '') is null then raise exception 'عنوان الرسوم مطلوب'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'المبلغ غير صحيح'; end if;
  insert into public.fee_charges (organization_id, student_id, title, amount, due_date, created_by)
  values (p_org, p_student, left(btrim(p_title), 120), round(p_amount, 2), coalesce(p_due_date, public._fees_today(p_org)), auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

-- waive (forgiven) / cancel (a mistake) / reopen
create or replace function public.set_fee_charge_status(p_org uuid, p_charge uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._fees_admin(p_org);
  perform public._assert_can_write(p_org);
  if p_status not in ('open', 'waived', 'cancelled') then raise exception 'حالة غير صحيحة'; end if;
  update public.fee_charges set status = p_status where id = p_charge and organization_id = p_org;
  if not found then raise exception 'الرسوم غير موجودة'; end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'fee_charges', p_charge, jsonb_build_object('status', p_status));
end;
$$;

-- the monthly charges of one center for the current month (idempotent)
create or replace function public._issue_monthly_fees(p_org uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare v_today date := public._fees_today(p_org); v_key text; v_due date; v_n integer;
begin
  v_key := to_char(v_today, 'YYYY-MM');
  v_due := make_date(extract(year from v_today)::integer, extract(month from v_today)::integer,
                     least(greatest(public.org_setting(p_org, 'fees_due_day', '1')::integer, 1), 28));
  insert into public.fee_charges (organization_id, student_id, plan_id, period_key, title, amount, due_date)
  select p_org, sp.student_id, pl.id, v_key, pl.name || ' — ' || v_key, public._fee_amount(pl.amount, sp.discount_percent), v_due
    from public.student_fee_plans sp
    join public.fee_plans pl on pl.id = sp.plan_id and pl.is_active and pl.period = 'monthly'
    join public.students_profile s on s.id = sp.student_id and s.status = 'active'
   where sp.organization_id = p_org and not sp.exempt and public._fee_amount(pl.amount, sp.discount_percent) > 0
  on conflict (student_id, period_key) where period_key is not null do nothing;
  get diagnostics v_n = row_count;
  return v_n;
end;
$$;
revoke all on function public._issue_monthly_fees(uuid) from public, anon, authenticated;

-- daily: this month's charges for every center with fees on, then the overdue reminders
create or replace function public.run_fee_jobs()
returns integer language plpgsql security definer set search_path = public as $$
declare o record; s record; v_n integer := 0; v_days integer; v_today date; b jsonb; v_cur text; v_left text;
begin
  for o in select id from public.organizations where status in ('trial', 'active') loop
    continue when not public._fees_enabled(o.id);
    v_n := v_n + public._issue_monthly_fees(o.id);

    v_days := public.org_setting(o.id, 'fees_reminder_days', '7')::integer;
    continue when v_days <= 0 or (public._notif_settings(o.id)).is_paused;
    v_today := public._fees_today(o.id);
    v_cur := public._fees_currency(o.id);
    for s in
      select distinct c.student_id, sp.full_name from public.fee_charges c
        join public.students_profile sp on sp.id = c.student_id and sp.status = 'active'
       where c.organization_id = o.id and c.status = 'open' and c.due_date <= v_today - v_days
    loop
      b := public._fee_balance(o.id, s.student_id);
      continue when (b->>'balance')::numeric <= 0;
      v_left := btrim(public._money((b->>'balance')::numeric) || ' ' || v_cur);
      perform public._notify(o.id, public._student_family_users(s.student_id), 'fee_overdue',
        'رسوم مستحقة: ' || s.full_name, 'المبلغ المستحق ' || v_left, s.student_id,
        jsonb_build_object('اسم_الطالب', s.full_name, 'المتبقي', v_left), true,
        'fee_overdue|' || s.student_id::text || '|' || to_char(v_today, 'IYYY-IW'));
    end loop;
  end loop;
  return v_n;
end;
$$;
revoke all on function public.run_fee_jobs() from public, anon, authenticated;
select cron.schedule('fee-jobs', '20 5 * * *', 'select public.run_fee_jobs()');

-- ---------------------------------------------------------------------
-- 7. payments
-- ---------------------------------------------------------------------
create or replace function public.record_fee_payment(p_org uuid, p_student uuid, p_amount numeric, p_method text default 'cash',
                                                    p_paid_on date default null, p_note text default null, p_client_ref uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_no integer; v_name text; b jsonb; v_cur text; v_left text; v_amt text;
begin
  perform public._fees_admin(p_org);
  perform public._assert_can_write(p_org);
  -- the same offline payment sent twice is recorded once
  if p_client_ref is not null then
    select id, receipt_no into v_id, v_no from public.fee_payments where client_ref = p_client_ref and organization_id = p_org;
    if v_id is not null then
      return jsonb_build_object('id', v_id, 'receipt_no', v_no, 'balance', public._fee_balance(p_org, p_student));
    end if;
  end if;
  select full_name into v_name from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'المبلغ غير صحيح'; end if;
  if coalesce(p_method, 'cash') not in ('cash', 'transfer', 'card', 'wallet', 'other') then raise exception 'طريقة الدفع غير صحيحة'; end if;
  if p_paid_on is not null and p_paid_on > public._fees_today(p_org) then raise exception 'تاريخ الدفع في المستقبل'; end if;

  perform pg_advisory_xact_lock(hashtext('fee_receipt|' || p_org::text));
  v_no := public._fee_next_receipt(p_org);
  insert into public.fee_payments (organization_id, student_id, amount, method, paid_on, receipt_no, note, client_ref, recorded_by)
  values (p_org, p_student, round(p_amount, 2), coalesce(p_method, 'cash'), coalesce(p_paid_on, public._fees_today(p_org)), v_no,
          nullif(left(btrim(coalesce(p_note, '')), 300), ''), p_client_ref, auth.uid())
  returning id into v_id;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'create', 'fee_payments', v_id, jsonb_build_object('student', p_student, 'amount', p_amount, 'receipt', v_no));

  b := public._fee_balance(p_org, p_student);
  v_cur := public._fees_currency(p_org);
  v_amt := btrim(public._money(p_amount) || ' ' || v_cur);
  v_left := btrim(public._money(greatest((b->>'balance')::numeric, 0)) || ' ' || v_cur);
  perform public._notify(p_org, public._student_family_users(p_student), 'fee_payment',
    'تم استلام دفعة ' || v_amt, v_name, p_student,
    jsonb_build_object('اسم_الطالب', v_name, 'المبلغ', v_amt, 'الإيصال', v_no::text, 'المتبقي', v_left), true,
    'fee_payment|' || v_id::text);
  return jsonb_build_object('id', v_id, 'receipt_no', v_no, 'balance', b);
end;
$$;

create or replace function public.void_fee_payment(p_org uuid, p_payment uuid, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._fees_admin(p_org);
  perform public._assert_can_write(p_org);
  update public.fee_payments set voided_at = now(), voided_by = auth.uid(), void_reason = nullif(left(btrim(coalesce(p_reason, '')), 300), '')
   where id = p_payment and organization_id = p_org and voided_at is null;
  if not found then raise exception 'الدفعة غير موجودة أو مُلغاة مسبقًا'; end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'delete', 'fee_payments', p_payment, jsonb_build_object('reason', p_reason));
end;
$$;

-- ---------------------------------------------------------------------
-- 8. reading
-- ---------------------------------------------------------------------
-- the admin's page: settings, plans, totals and every student with a plan or a balance
create or replace function public.fees_overview(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_today date; v_month_start date;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  v_today := public._fees_today(p_org);
  v_month_start := date_trunc('month', v_today)::date;
  return public.get_fee_settings(p_org) || jsonb_build_object(
    'today', v_today,
    'plans', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'amount', p.amount, 'period', p.period,
                         'active', p.is_active, 'students', (select count(*) from public.student_fee_plans sp where sp.plan_id = p.id))
                         order by p.is_active desc, p.name)
                       from public.fee_plans p where p.organization_id = p_org), '[]'::jsonb),
    'collected_month', (select coalesce(sum(amount), 0) from public.fee_payments
                         where organization_id = p_org and voided_at is null and paid_on >= v_month_start),
    'collected_total', (select coalesce(sum(amount), 0) from public.fee_payments where organization_id = p_org and voided_at is null),
    'students', coalesce((select jsonb_agg(x order by (x->>'balance')::numeric desc, x->>'name') from (
        select jsonb_build_object('id', s.id, 'name', s.full_name, 'code', s.student_code, 'circle', c.name,
                 'plan_id', sp.plan_id, 'plan', pl.name, 'discount', coalesce(sp.discount_percent, 0), 'exempt', coalesce(sp.exempt, false),
                 'note', sp.note) || public._fee_balance(p_org, s.id) as x
          from public.students_profile s
          left join public.circles c on c.id = s.circle_id
          left join public.student_fee_plans sp on sp.student_id = s.id
          left join public.fee_plans pl on pl.id = sp.plan_id
         where s.organization_id = p_org and s.status = 'active') t), '[]'::jsonb));
end;
$$;

-- one student's account: the admin, or the student / their guardian
create or replace function public.student_fees(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare s record; v_admin boolean := public.is_org_admin(p_org);
begin
  select sp.id, sp.full_name, sp.student_code into s from public.students_profile sp where sp.id = p_student and sp.organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if not (v_admin or p_student = any (public.linked_student_ids(p_org))) then raise exception 'غير مصرّح'; end if;
  if not public._fees_enabled(p_org) then return jsonb_build_object('enabled', false); end if;
  return jsonb_build_object(
    'enabled', true, 'is_admin', v_admin, 'currency', public._fees_currency(p_org), 'today', public._fees_today(p_org),
    'student', jsonb_build_object('id', s.id, 'name', s.full_name, 'code', s.student_code),
    'plan', (select jsonb_build_object('id', pl.id, 'name', pl.name, 'amount', pl.amount, 'period', pl.period,
                                       'discount', sp.discount_percent, 'exempt', sp.exempt, 'note', case when v_admin then sp.note end)
               from public.student_fee_plans sp left join public.fee_plans pl on pl.id = sp.plan_id where sp.student_id = p_student),
    'balance', public._fee_balance(p_org, p_student),
    'charges', coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'amount', c.amount, 'due_date', c.due_date,
                           'status', c.status) order by c.due_date desc, c.created_at desc)
                         from public.fee_charges c where c.student_id = p_student and c.organization_id = p_org
                          and (v_admin or c.status <> 'cancelled')), '[]'::jsonb),
    'payments', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'amount', p.amount, 'method', p.method, 'paid_on', p.paid_on,
                            'receipt_no', p.receipt_no, 'note', p.note, 'voided', p.voided_at is not null, 'void_reason', p.void_reason)
                            order by p.paid_on desc, p.receipt_no desc)
                          from public.fee_payments p where p.student_id = p_student and p.organization_id = p_org
                           and (v_admin or p.voided_at is null)), '[]'::jsonb));
end;
$$;

-- a printable receipt
create or replace function public.fee_receipt(p_org uuid, p_payment uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare p public.fee_payments; v jsonb;
begin
  select * into p from public.fee_payments where id = p_payment and organization_id = p_org;
  if not found then raise exception 'الإيصال غير موجود'; end if;
  if not (public.is_org_admin(p_org) or p.student_id = any (public.linked_student_ids(p_org))) then raise exception 'غير مصرّح'; end if;
  select jsonb_build_object(
      'receipt_no', p.receipt_no, 'amount', p.amount, 'method', p.method, 'paid_on', p.paid_on, 'note', p.note,
      'voided', p.voided_at is not null, 'void_reason', p.void_reason, 'currency', public._fees_currency(p_org),
      'center', o.name, 'logo_url', o.logo_url,
      'student', s.full_name, 'student_code', s.student_code,
      'recorded_by', (select full_name from public.profiles where id = p.recorded_by),
      'balance', public._fee_balance(p_org, p.student_id))
    into v
    from public.organizations o, public.students_profile s where o.id = p_org and s.id = p.student_id;
  return v;
end;
$$;

-- money received in a period: by method, by day, and the list
create or replace function public.fees_report(p_org uuid, p_from date, p_to date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return jsonb_build_object(
    'currency', public._fees_currency(p_org),
    'total', (select coalesce(sum(amount), 0) from public.fee_payments
               where organization_id = p_org and voided_at is null and paid_on between p_from and p_to),
    'count', (select count(*) from public.fee_payments
               where organization_id = p_org and voided_at is null and paid_on between p_from and p_to),
    'by_method', coalesce((select jsonb_object_agg(method, total) from (
        select method, sum(amount) as total from public.fee_payments
         where organization_id = p_org and voided_at is null and paid_on between p_from and p_to group by method) t), '{}'::jsonb),
    'charged', (select coalesce(sum(amount), 0) from public.fee_charges
                 where organization_id = p_org and status = 'open' and due_date between p_from and p_to),
    'outstanding', (select coalesce(sum(greatest((public._fee_balance(p_org, s.id)->>'balance')::numeric, 0)), 0)
                      from public.students_profile s where s.organization_id = p_org),
    'payments', coalesce((select jsonb_agg(jsonb_build_object('id', p.id, 'receipt_no', p.receipt_no, 'paid_on', p.paid_on,
                            'amount', p.amount, 'method', p.method, 'student', s.full_name, 'voided', p.voided_at is not null)
                            order by p.paid_on desc, p.receipt_no desc)
                          from public.fee_payments p join public.students_profile s on s.id = p.student_id
                         where p.organization_id = p_org and p.paid_on between p_from and p_to), '[]'::jsonb));
end;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'get_fee_settings(uuid)', 'set_fee_settings(uuid, boolean, text, integer, integer)',
    'save_fee_plan(uuid, uuid, text, numeric, text, boolean)', 'delete_fee_plan(uuid, uuid)',
    'set_students_fee_plan(uuid, uuid[], uuid, numeric, boolean, text)',
    'issue_fee_charges(uuid, uuid, text, date)', 'add_fee_charge(uuid, uuid, text, numeric, date)',
    'set_fee_charge_status(uuid, uuid, text)',
    'record_fee_payment(uuid, uuid, numeric, text, date, text, uuid)', 'void_fee_payment(uuid, uuid, text)',
    'fees_overview(uuid)', 'student_fees(uuid, uuid)', 'fee_receipt(uuid, uuid)', 'fees_report(uuid, date, date)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
