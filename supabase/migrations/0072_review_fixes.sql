-- =========================================================================
-- 0072_review_fixes.sql
-- Fixes found in the pre-merge review of 0057-0071:
--   1. _billing_apply silently set organizations.status = 'active', which
--      lifted a suspension the platform owner had imposed for a reason that has
--      nothing to do with billing. Approving / recording a payment for a
--      suspended or cancelled center is now refused with a clear message: the
--      owner lifts the suspension deliberately first (platform_set_org).
--   2. platform_record_payment had no free-plan guard (billing_submit_request
--      does): the owner could "record a payment" for the plan nobody pays for.
--   3. platform_billing_requests can return "everything that is not pending"
--      (p_status = 'history'), so the owner's history table is not emptied by
--      a page of pending rows filtered out on the client.
--   4. add_student_note / submit_gathering: the client_ref replay check was a
--      SELECT followed by an INSERT, so two replays of the same offline write
--      arriving together both passed the check and the second one died on the
--      unique index with a raw error. The insert now falls back to the row the
--      first request created.
-- =========================================================================

-- 1. ---------------------------------------------------------------------
create or replace function public._billing_apply(p_request uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r public.billing_requests; v_start timestamptz; v_end timestamptz; v_sub uuid; v_status text;
begin
  select * into r from public.billing_requests where id = p_request for update;
  select status into v_status from public.organizations where id = r.organization_id;
  if v_status in ('suspended', 'cancelled') then
    raise exception 'المركز موقوف أو ملغى — ارفع الإيقاف أولًا من صفحة المركز ثم أكّد الدفع';
  end if;
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

-- 2. ---------------------------------------------------------------------
create or replace function public.platform_record_payment(p_org uuid, p_plan uuid, p_period text, p_amount_cents integer, p_method text, p_note text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare pl public.plans; v_id uuid;
begin
  perform public._plat_guard();
  if not exists (select 1 from public.organizations where id = p_org) then raise exception 'المركز غير موجود'; end if;
  select * into pl from public.plans where id = p_plan;
  if not found then raise exception 'الخطة غير موجودة'; end if;
  if p_plan = public._free_plan_id() then raise exception 'الخطة المجانية لا تحتاج دفعًا'; end if;
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

-- 3. ---------------------------------------------------------------------
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
    where p_status is null or p_status = ''
       or (p_status = 'history' and r.status <> 'pending')
       or r.status = p_status
    order by r.created_at desc limit least(greatest(coalesce(p_limit, 100), 1), 500)) q), '[]'::jsonb);
end;
$$;

-- 4. ---------------------------------------------------------------------
create or replace function public.add_student_note(p_org uuid, p_student uuid, p_body text, p_visibility text default 'staff_only', p_client_ref uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_body text := nullif(btrim(coalesce(p_body, '')), '');
begin
  perform public._assert_can_write(p_org);
  if not (public.is_org_admin(p_org) or (public.is_org_staff(p_org) and public._teaches_student(p_student))) then raise exception 'غير مصرّح'; end if;
  if p_client_ref is not null then
    select id into v_id from public.student_notes where client_ref = p_client_ref and organization_id = p_org;
    if v_id is not null then return v_id; end if;  -- already received (a replayed offline write)
  end if;
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then raise exception 'الطالب غير موجود'; end if;
  if v_body is null then raise exception 'اكتب الملاحظة'; end if;
  if length(v_body) > 1000 then raise exception 'الملاحظة حتى 1000 حرف'; end if;
  if p_visibility not in ('staff_only', 'guardian_visible') then raise exception 'ظهور غير معروف'; end if;
  begin
    insert into public.student_notes (organization_id, student_id, author_id, body, visibility, client_ref)
    values (p_org, p_student, auth.uid(), v_body, p_visibility, p_client_ref)
    returning id into v_id;
  exception when unique_violation then
    -- a concurrent replay of the same write committed first: hand back its row
    select id into v_id from public.student_notes where client_ref = p_client_ref and organization_id = p_org;
    if v_id is null then raise; end if;
  end;
  return v_id;
end;
$$;

create or replace function public.submit_gathering(
  p_org uuid, p_title text, p_type uuid, p_date date, p_location text, p_notes text, p_names text[], p_client_ref uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_title text := nullif(btrim(coalesce(p_title, '')), ''); v_date date := coalesce(p_date, public._org_today(p_org));
        v_label text; v_id uuid; v_name text; v_count integer := 0; v_who text;
begin
  perform public._assert_can_write(p_org);
  perform public._assert_gathering_staff(p_org);
  if p_client_ref is not null then
    select id into v_id from public.attendance_gatherings where client_ref = p_client_ref and organization_id = p_org;
    if v_id is not null then
      return jsonb_build_object('id', v_id, 'duplicate', true,
        'names_count', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = v_id));
    end if;
  end if;
  if v_title is null then raise exception 'اكتب اسم النشاط'; end if;
  if v_date > public._org_today(p_org) then raise exception 'لا يمكن رفع حضور بتاريخ مستقبلي'; end if;
  if p_names is null or array_length(p_names, 1) is null then raise exception 'أضف اسمًا واحدًا على الأقل'; end if;
  if array_length(p_names, 1) > 300 then raise exception 'الحد الأقصى 300 اسم في المرة'; end if;
  if p_type is not null then
    select name into v_label from public.activity_types where id = p_type and organization_id = p_org;
    if v_label is null then raise exception 'نوع النشاط غير موجود'; end if;
  end if;
  begin
    insert into public.attendance_gatherings (organization_id, title, activity_type_id, activity_type_label, session_date, location, notes, created_by, client_ref)
    values (p_org, v_title, p_type, v_label, v_date, nullif(btrim(coalesce(p_location, '')), ''), nullif(btrim(coalesce(p_notes, '')), ''), auth.uid(), p_client_ref)
    returning id into v_id;
  exception when unique_violation then
    -- a concurrent replay of the same write committed first: report it as the duplicate it is
    select id into v_id from public.attendance_gatherings where client_ref = p_client_ref and organization_id = p_org;
    if v_id is null then raise; end if;
    return jsonb_build_object('id', v_id, 'duplicate', true,
      'names_count', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = v_id));
  end;
  foreach v_name in array p_names loop
    v_name := btrim(coalesce(v_name, ''));
    continue when v_name = '' or length(v_name) > 120;
    insert into public.attendance_gathering_entries (organization_id, gathering_id, raw_name) values (p_org, v_id, v_name);
    v_count := v_count + 1;
  end loop;
  if v_count = 0 then raise exception 'أضف اسمًا واحدًا على الأقل'; end if;
  select full_name into v_who from public.profiles where id = auth.uid();
  perform public._notify(p_org, public._org_admins(p_org), 'gathering_submitted', 'مجلس جديد بانتظار الربط', v_title, v_id,
    jsonb_build_object('العنوان', v_title, 'عدد', v_count::text, 'المعلم', coalesce(v_who, '')));
  return jsonb_build_object('id', v_id, 'names_count', v_count);
end;
$$;

notify pgrst, 'reload schema';
