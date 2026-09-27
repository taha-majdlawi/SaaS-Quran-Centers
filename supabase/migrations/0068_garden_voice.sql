-- =========================================================================
-- 0068_garden_voice.sql
-- The platform speaks in the voice of its name - a garden that grows:
--   بذرة (seed) -> غرسة (sapling) -> شجرة (tree) -> بستان (orchard).
--   1. The four launch plans are renamed to that ladder - only where their
--      names are still the 0067 defaults (a name edited in the console wins).
--   2. public_plans(): the ladder's active plans for the public marketing
--      page (anon), so prices shown there always match the console.
--   3. send_billing_reminders: same logic, dedupe keys and audiences as 0067,
--      with the alert texts rewritten in the garden voice. Every alert still
--      states the facts plainly (what ends, when, the limit reached).
-- =========================================================================

update public.plans set name = 'بذرة'  where code = 'free'       and name = 'مجانية (بذرة)';
update public.plans set name = 'غرسة'  where code = 'basic'      and name = 'الأساسية';
update public.plans set name = 'شجرة'  where code = 'advanced'   and name = 'المتقدمة';
update public.plans set name = 'بستان' where code = 'enterprise' and name = 'المؤسسات';

-- only non-sensitive columns, only the active ladder plans
create or replace function public.public_plans()
returns table (code text, name text, price_cents integer, yearly_price_cents integer, currency text, max_students integer, max_teachers integer)
language sql stable security definer set search_path = public as $$
  select p.code, p.name, p.price_cents, p.yearly_price_cents, p.currency,
         nullif(p.limits ->> 'max_students', '')::integer, nullif(p.limits ->> 'max_teachers', '')::integer
    from public.plans p
   where p.is_active and p.code in ('free', 'basic', 'advanced', 'enterprise')
   order by p.price_cents, p.code;
$$;
revoke all on function public.public_plans() from public;
grant execute on function public.public_plans() to anon, authenticated;

create or replace function public.send_billing_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare o record; b jsonb; u jsonb; v_days integer; v_n integer := 0; v_what text; v_staff uuid[]; v_admins uuid[];
        v_free uuid := public._free_plan_id(); v_free_name text; v_left integer; v_key text;
begin
  if public._platform_setting('billing_enforce', 'false') <> 'true' then return 0; end if;
  select name into v_free_name from public.plans where id = v_free;
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
        '🌿 ' || case b ->> 'kind' when 'trial' then 'تنتهي ' else 'ينتهي ' end || v_what || ' خلال '
          || case v_days when 60 then 'شهرين' when 30 then 'شهر' when 1 then 'يوم واحد' else v_days || ' أيام' end,
        case when b ->> 'kind' = 'trial' then 'اسقِ غرستك لتكبر: اختر خطتك من «الاشتراك والدفع». '
             else 'اسقِ بستانك قبل أن يعطش: جدّد من «الاشتراك والدفع». ' end
          || case when v_free is not null then 'وإلا عاد المركز إلى خطة «' || coalesce(v_free_name, 'بذرة') || '» المجانية إن كان حجمه يناسبها، أو صار للقراءة فقط'
                  else 'وإلا صار المركز للقراءة فقط' end,
        null, null, true, 'billing|' || o.id || '|' || (b ->> 'until') || '|' || v_days);
      v_n := v_n + 1;
    -- b) ended, grace running
    elsif b ->> 'state' = 'grace' then
      perform public._notify(o.id, v_staff, 'billing_reminder',
        '🍂 ' || case b ->> 'kind' when 'trial' then 'انتهت ' else 'انتهى ' end || v_what || ' — بستانك ينتظر السقاية',
        'مهلة حتى ' || to_char((b ->> 'grace_ends')::timestamptz, 'YYYY-MM-DD') || ' — جدّد من «الاشتراك والدفع» ليبقى كل شيء كما هو', null, null, true,
        'billing|' || o.id || '|' || (b ->> 'until') || '|grace');
      v_n := v_n + 1;
    -- c) grace over: fall back to the free plan when the center fits it
    elsif b ->> 'state' = 'expired' and v_free is not null and public._fits_plan(o.id, v_free) then
      update public.organizations set plan_id = v_free, status = 'active', updated_at = now() where id = o.id;
      perform public._notify(o.id, v_staff, 'billing_downgraded', '🌱 عاد المركز إلى خطة «' || coalesce(v_free_name, 'بذرة') || '» المجانية',
        'انتهى ' || v_what || ' — بياناتك محفوظة كلها والمركز يعمل بحدود الخطة المجانية. اسقِ بذرتك من «الاشتراك والدفع» لتكبر من جديد', null, null, true,
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
        case when v_left = 0 then '🌳 امتلأ بستانك — وصل المركز للحد الأقصى من الطلاب (' || (u ->> 'max_students') || ')'
             else '🌿 تبقى ' || public._left_text(v_left, 'طالب', 'طلاب') || ' يمكن إضافتهم ضمن خطة المركز' end,
        case when v_left = 0 then 'وسّع بستانك لطلاب جدد: انتقل لخطة أكبر من «الاشتراك والدفع»'
             else 'بستانك يكبر، ما شاء الله! اسقِه بخطة أكبر من «الاشتراك والدفع» متى احتجت' end,
        null, null, true, v_key);
      v_n := v_n + 1;
    end if;
    v_left := (u ->> 'teachers_left')::integer;
    if v_left is not null and v_left <= 1 then
      v_key := 'cap|' || o.id || '|t|' || (u ->> 'plan_id') || '|' || (u ->> 'max_teachers') || '|' || case when v_left = 0 then 'full' else 'low' end;
      perform public._notify(o.id, v_admins, 'capacity_warning',
        case when v_left = 0 then '🌳 وصل المركز للحد الأقصى من المعلمين (' || (u ->> 'max_teachers') || ')'
             else '🌿 تبقى إضافة معلم واحد فقط ضمن خطة المركز' end,
        'لتزرع حلقات جديدة: انتقل لخطة أكبر من «الاشتراك والدفع»', null, null, true, v_key);
      v_n := v_n + 1;
    end if;
  end loop;
  return v_n;
end;
$$;
revoke all on function public.send_billing_reminders() from public, anon, authenticated;
