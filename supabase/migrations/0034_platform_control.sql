-- =========================================================================
-- 0034_platform_control.sql
-- The platform owner's control plane. Everything here is a SECURITY DEFINER
-- function that first checks is_platform_owner(); nothing is reachable by a
-- center admin.
--   * center detail / edit / members / settings / delete / create
--   * per-center + platform-wide FEATURE switches (enforced in
--     member_has_module, chat and the market, and hidden in the UIs)
--   * plans with real limits (max students / teachers) enforced on insert
--   * platform settings (self-serve signup on/off, default plan, trial days)
--   * notices shown to every center's users
--   * accounts overview + an owner audit log
-- =========================================================================

-- ---------------------------------------------------------------------
-- tables
-- ---------------------------------------------------------------------
create table if not exists public.platform_settings (
  key         text primary key,
  value       text not null,
  updated_at  timestamptz not null default now()
);
create table if not exists public.platform_notices (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 2 and 120),
  body        text check (body is null or char_length(body) <= 600),
  level       text not null default 'info' check (level in ('info', 'warning', 'critical')),
  is_active   boolean not null default true,
  ends_at     timestamptz,
  created_by  uuid references auth.users (id),
  created_at  timestamptz not null default now()
);
create table if not exists public.platform_audit_log (
  id          bigserial primary key,
  actor_id    uuid references auth.users (id) on delete set null,
  action      text not null,
  target      text,
  detail      jsonb,
  created_at  timestamptz not null default now()
);
create index if not exists platform_audit_log_created_idx on public.platform_audit_log (created_at desc);
alter table public.platform_settings enable row level security;
alter table public.platform_notices enable row level security;
alter table public.platform_audit_log enable row level security;
revoke all on public.platform_settings, public.platform_notices, public.platform_audit_log from anon, authenticated;
revoke all on sequence public.platform_audit_log_id_seq from anon, authenticated;

create index if not exists feature_flags_key_idx on public.feature_flags (key, organization_id);

-- ---------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------
create or replace function public._plat_guard()
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_platform_owner() then raise exception 'غير مصرّح'; end if;
end;
$$;

create or replace function public._plat_log(p_action text, p_target text, p_detail jsonb default null)
returns void language sql security definer set search_path = public as $$
  insert into public.platform_audit_log (actor_id, action, target, detail) values (auth.uid(), p_action, p_target, p_detail);
$$;

create or replace function public._platform_setting(p_key text, p_default text)
returns text language sql stable security definer set search_path = public as $$
  select coalesce((select value from public.platform_settings where key = p_key), p_default);
$$;

-- The feature catalog = the module keys the apps already use.
create or replace function public._feature_catalog()
returns text[] language sql immutable as $$
  select array['students', 'circles', 'attendance', 'serd', 'points', 'badges', 'market', 'circle-challenges', 'activities',
               'calendar', 'announcements', 'chat', 'notifications', 'reports', 'certificates'];
$$;

-- override of the center > platform default > the center's plan > on
create or replace function public.platform_feature_enabled(p_org uuid, p_key text)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(
    (select f.enabled from public.feature_flags f where f.key = p_key and f.organization_id = p_org limit 1),
    (select f.enabled from public.feature_flags f where f.key = p_key and f.organization_id is null limit 1),
    (select (p.features ->> p_key)::boolean from public.organizations o join public.plans p on p.id = o.plan_id
      where o.id = p_org and p.features ? p_key limit 1),
    true);
$$;

-- modules switched off for a center (members call this to hide what is off)
create or replace function public.disabled_modules(p_org uuid)
returns text[] language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  return coalesce((select array_agg(k) from unnest(public._feature_catalog()) k where not public.platform_feature_enabled(p_org, k)), array[]::text[]);
end;
$$;

-- staff access now also requires the feature to be on (the platform owner bypasses)
create or replace function public.member_has_module(org_id uuid, module text)
returns boolean language sql security definer stable set search_path = public as $$
  select public.is_platform_owner() or (
    public.platform_feature_enabled(org_id, module) and (
      public.is_org_admin(org_id) or exists (
        select 1 from public.organization_members m
        where m.organization_id = org_id and m.user_id = auth.uid() and m.status = 'active'
          and m.role = 'teacher' and module = any (m.permissions))));
$$;

create or replace function public._market_enabled(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.org_setting(p_org, 'flag_market_enabled', 'true') = 'true' and public.platform_feature_enabled(p_org, 'market');
$$;

create or replace function public._can_message(p_org uuid, p_other uuid)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_me public.user_role; v_other public.user_role;
begin
  if auth.uid() is null or p_other is null or p_other = auth.uid() then return false; end if;
  if not public.platform_feature_enabled(p_org, 'chat') then return false; end if;
  v_me := public._org_role_of(p_org, auth.uid());
  v_other := public._org_role_of(p_org, p_other);
  if v_me is null or v_other is null then return false; end if;

  if v_me = 'admin' or v_other = 'admin' then return true; end if;
  if v_me = 'teacher' and not public._teacher_has_chat(p_org, auth.uid()) then return false; end if;
  if v_other = 'teacher' and not public._teacher_has_chat(p_org, p_other) then return false; end if;

  if v_me = 'teacher' and v_other = 'teacher' then return true; end if;
  if v_me = 'teacher' and v_other in ('student', 'guardian') then
    return public._teacher_teaches_any(auth.uid(), public._students_of_user(p_org, p_other));
  end if;
  if v_me in ('student', 'guardian') and v_other = 'teacher' then
    return public._teacher_teaches_any(p_other, public._students_of_user(p_org, auth.uid()));
  end if;
  return false;
end;
$$;

-- ---------------------------------------------------------------------
-- plan limits, enforced on insert
-- ---------------------------------------------------------------------
create or replace function public._enforce_plan_limits()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_limits jsonb; v_max integer; v_cnt integer;
begin
  select p.limits into v_limits from public.organizations o join public.plans p on p.id = o.plan_id where o.id = new.organization_id;
  if v_limits is null then return new; end if;
  if tg_table_name = 'students_profile' then
    v_max := nullif(v_limits ->> 'max_students', '')::integer;
    if v_max is not null then
      select count(*) into v_cnt from public.students_profile where organization_id = new.organization_id and status = 'active';
      if v_cnt >= v_max then raise exception 'وصل المركز إلى الحد الأقصى من الطلاب في خطته (%). تواصل مع إدارة المنصة للترقية', v_max; end if;
    end if;
  elsif tg_table_name = 'organization_members' and new.role = 'teacher' and new.status = 'active' then
    v_max := nullif(v_limits ->> 'max_teachers', '')::integer;
    if v_max is not null then
      select count(*) into v_cnt from public.organization_members where organization_id = new.organization_id and role = 'teacher' and status = 'active';
      if v_cnt >= v_max then raise exception 'وصل المركز إلى الحد الأقصى من المعلمين في خطته (%). تواصل مع إدارة المنصة للترقية', v_max; end if;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists b_plan_limits on public.students_profile;
create trigger b_plan_limits before insert on public.students_profile for each row execute function public._enforce_plan_limits();
drop trigger if exists b_plan_limits on public.organization_members;
create trigger b_plan_limits before insert on public.organization_members for each row execute function public._enforce_plan_limits();

-- self-serve signup respects the platform settings (on/off, default plan, trial length)
create or replace function public.create_organization_with_owner(org_name text, org_slug text)
returns table (id uuid, slug text)
language plpgsql security definer set search_path = public as $$
declare new_org_id uuid; v_plan uuid; v_days integer;
begin
  if auth.uid() is null then raise exception 'must be authenticated'; end if;
  if public._platform_setting('signup_enabled', 'true') <> 'true' then raise exception 'التسجيل الذاتي للمراكز مغلق حاليًا'; end if;
  if lower(org_slug) in ('www', 'admin', 'api', 'app', 'id') then raise exception 'هذا الرابط محجوز'; end if;
  v_plan := nullif(public._platform_setting('default_plan_id', ''), '')::uuid;
  v_days := coalesce(nullif(public._platform_setting('trial_days', '14'), '')::integer, 14);

  insert into public.organizations (name, slug, plan_id, trial_ends_at)
  values (org_name, org_slug, v_plan, case when v_days > 0 then now() + make_interval(days => v_days) end)
  returning organizations.id into new_org_id;

  insert into public.organization_members (organization_id, user_id, role, status) values (new_org_id, auth.uid(), 'admin', 'active');
  return query select new_org_id, org_slug;
end;
$$;

-- ---------------------------------------------------------------------
-- centers
-- ---------------------------------------------------------------------
create or replace function public.platform_org_detail(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare o public.organizations%rowtype; v_plan jsonb;
begin
  perform public._plat_guard();
  select * into o from public.organizations where id = p_org;
  if not found then raise exception 'المركز غير موجود'; end if;
  select to_jsonb(p) into v_plan from public.plans p where p.id = o.plan_id;
  return jsonb_build_object(
    'org', to_jsonb(o),
    'plan', v_plan,
    'stats', jsonb_build_object(
      'students', (select count(*) from public.students_profile where organization_id = p_org and status = 'active'),
      'students_all', (select count(*) from public.students_profile where organization_id = p_org),
      'circles', (select count(*) from public.circles where organization_id = p_org),
      'recitations_30d', (select count(*) from public.daily_achievements where organization_id = p_org and created_at > now() - interval '30 days'),
      'last_activity', (select max(created_at) from public.daily_achievements where organization_id = p_org),
      'chat_images_mb', coalesce((select round(sum((metadata ->> 'size')::numeric) / 1048576, 2) from storage.objects
                                  where bucket_id = 'chat-images' and name like p_org::text || '/%'), 0)),
    'members', coalesce((
      select jsonb_agg(jsonb_build_object('id', m.id, 'user_id', m.user_id, 'name', pr.full_name, 'email', u.email, 'role', m.role,
             'status', m.status, 'permissions', m.permissions, 'created_at', m.created_at,
             'read_only', coalesce((select a.is_read_only from public.account_access a where a.user_id = m.user_id and a.organization_id = p_org), false))
             order by case m.role when 'admin' then 0 when 'teacher' then 1 else 2 end, pr.full_name)
      from public.organization_members m
      left join public.profiles pr on pr.id = m.user_id
      left join auth.users u on u.id = m.user_id
      where m.organization_id = p_org), '[]'::jsonb),
    'settings', coalesce((select jsonb_agg(jsonb_build_object('key', key, 'value', value) order by key) from public.organization_settings where organization_id = p_org), '[]'::jsonb),
    'features', (select jsonb_agg(jsonb_build_object(
        'key', k,
        'effective', public.platform_feature_enabled(p_org, k),
        'override', (select f.enabled from public.feature_flags f where f.key = k and f.organization_id = p_org limit 1),
        'platform', (select f.enabled from public.feature_flags f where f.key = k and f.organization_id is null limit 1)) order by k)
      from unnest(public._feature_catalog()) k),
    'audit', coalesce((select jsonb_agg(jsonb_build_object('at', a.created_at, 'action', a.action, 'table', a.entity_table, 'actor', pr.full_name) order by a.created_at desc)
      from (select * from public.audit_log where organization_id = p_org order by created_at desc limit 15) a
      left join public.profiles pr on pr.id = a.actor_id), '[]'::jsonb));
end;
$$;

create or replace function public.platform_update_org(
  p_org uuid, p_name text, p_timezone text, p_primary text, p_secondary text, p_logo text,
  p_status text, p_plan uuid, p_trial_ends date
) returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._plat_guard();
  if char_length(btrim(coalesce(p_name, ''))) < 2 then raise exception 'اسم المركز مطلوب'; end if;
  if p_status not in ('trial', 'active', 'suspended', 'cancelled') then raise exception 'حالة غير صحيحة'; end if;
  if p_plan is not null and not exists (select 1 from public.plans where id = p_plan) then raise exception 'الخطة غير موجودة'; end if;
  if p_primary !~ '^#[0-9a-fA-F]{6}$' or p_secondary !~ '^#[0-9a-fA-F]{6}$' then raise exception 'اللون يجب أن يكون بصيغة #rrggbb'; end if;
  if not exists (select 1 from pg_timezone_names where name = p_timezone) then raise exception 'المنطقة الزمنية غير معروفة'; end if;
  if nullif(btrim(coalesce(p_logo, '')), '') is not null and p_logo !~ '^https://' then raise exception 'رابط الشعار يجب أن يبدأ بـ https://'; end if;
  -- the slug is deliberately not editable here: student login e-mails are derived from it
  update public.organizations set name = btrim(p_name), timezone = p_timezone, primary_color = p_primary, secondary_color = p_secondary,
         logo_url = nullif(btrim(coalesce(p_logo, '')), ''), status = p_status, plan_id = p_plan, trial_ends_at = p_trial_ends::timestamptz, updated_at = now()
   where id = p_org;
  if not found then raise exception 'المركز غير موجود'; end if;
  perform public._plat_log('update_org', p_org::text, jsonb_build_object('status', p_status, 'plan', p_plan, 'name', p_name));
end;
$$;

create or replace function public.platform_create_org(p_name text, p_slug text, p_plan uuid, p_admin_email text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_slug text := lower(btrim(coalesce(p_slug, ''))); v_user uuid; v_token uuid; v_days integer; v_email text := lower(btrim(coalesce(p_admin_email, '')));
begin
  perform public._plat_guard();
  if char_length(btrim(coalesce(p_name, ''))) < 2 then raise exception 'اسم المركز مطلوب'; end if;
  if v_slug !~ '^[a-z0-9]([a-z0-9-]{0,38}[a-z0-9])?$' then raise exception 'الرابط: حروف إنجليزية صغيرة وأرقام وشرطة فقط'; end if;
  if v_slug in ('www', 'admin', 'api', 'app', 'id') then raise exception 'هذا الرابط محجوز'; end if;
  if exists (select 1 from public.organizations where slug = v_slug) then raise exception 'الرابط مستخدم من مركز آخر'; end if;
  if p_plan is not null and not exists (select 1 from public.plans where id = p_plan) then raise exception 'الخطة غير موجودة'; end if;
  v_days := coalesce(nullif(public._platform_setting('trial_days', '14'), '')::integer, 14);

  insert into public.organizations (name, slug, plan_id, trial_ends_at)
  values (btrim(p_name), v_slug, p_plan, case when v_days > 0 then now() + make_interval(days => v_days) end) returning id into v_id;

  if v_email <> '' then
    select id into v_user from auth.users where lower(email) = v_email;
    if v_user is not null then
      insert into public.organization_members (organization_id, user_id, role, status) values (v_id, v_user, 'admin', 'active')
        on conflict (organization_id, user_id) do update set role = 'admin', status = 'active';
    else
      select token into v_token from public.create_invitation(v_id, v_email, 'admin');
    end if;
  end if;
  perform public._plat_log('create_org', v_id::text, jsonb_build_object('slug', v_slug, 'admin', v_email));
  return jsonb_build_object('id', v_id, 'slug', v_slug, 'invite_token', v_token, 'admin_added', v_user is not null);
end;
$$;

create or replace function public.platform_delete_org(p_org uuid, p_slug text)
returns void language plpgsql security definer set search_path = public as $$
declare o public.organizations%rowtype;
begin
  perform public._plat_guard();
  select * into o from public.organizations where id = p_org;
  if not found then raise exception 'المركز غير موجود'; end if;
  if lower(btrim(coalesce(p_slug, ''))) <> o.slug then raise exception 'اكتب رابط المركز بالضبط لتأكيد الحذف'; end if;
  perform public._plat_log('delete_org', p_org::text, jsonb_build_object('slug', o.slug, 'name', o.name,
    'students', (select count(*) from public.students_profile where organization_id = p_org)));
  delete from public.organizations where id = p_org;
end;
$$;

create or replace function public.platform_set_member(p_member uuid, p_role public.user_role, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare m public.organization_members%rowtype; v_other_admins integer;
begin
  perform public._plat_guard();
  if p_status not in ('active', 'suspended') then raise exception 'حالة غير صحيحة'; end if;
  select * into m from public.organization_members where id = p_member;
  if not found then raise exception 'العضو غير موجود'; end if;
  if m.role = 'admin' and m.status = 'active' and (p_role <> 'admin' or p_status <> 'active') then
    select count(*) into v_other_admins from public.organization_members where organization_id = m.organization_id and role = 'admin' and status = 'active' and id <> m.id;
    if v_other_admins = 0 then raise exception 'هذا آخر مدير نشط في المركز — أضف مديرًا آخر أولًا'; end if;
  end if;
  update public.organization_members set role = p_role, status = p_status where id = p_member;
  perform public._plat_log('set_member', p_member::text, jsonb_build_object('org', m.organization_id, 'role', p_role, 'status', p_status));
end;
$$;

create or replace function public.platform_add_member(p_org uuid, p_email text, p_role public.user_role)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_user uuid; v_email text := lower(btrim(coalesce(p_email, ''))); v_token uuid;
begin
  perform public._plat_guard();
  if not exists (select 1 from public.organizations where id = p_org) then raise exception 'المركز غير موجود'; end if;
  select id into v_user from auth.users where lower(email) = v_email;
  if v_user is not null then
    insert into public.organization_members (organization_id, user_id, role, status) values (p_org, v_user, p_role, 'active')
      on conflict (organization_id, user_id) do update set role = excluded.role, status = 'active';
  else
    select token into v_token from public.create_invitation(p_org, v_email, p_role);
  end if;
  perform public._plat_log('add_member', p_org::text, jsonb_build_object('email', v_email, 'role', p_role, 'invited', v_user is null));
  return jsonb_build_object('added', v_user is not null, 'invite_token', v_token);
end;
$$;

create or replace function public.platform_set_org_setting(p_org uuid, p_key text, p_value text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._plat_guard();
  if p_key !~ '^[a-z0-9_]{2,60}$' then raise exception 'اسم الإعداد غير صحيح'; end if;
  if p_value is null then
    delete from public.organization_settings where organization_id = p_org and key = p_key;
  else
    insert into public.organization_settings (organization_id, key, value, updated_at) values (p_org, p_key, left(p_value, 500), now())
      on conflict (organization_id, key) do update set value = excluded.value, updated_at = now();
  end if;
  perform public._plat_log('org_setting', p_org::text, jsonb_build_object('key', p_key));
end;
$$;

-- ---------------------------------------------------------------------
-- features / plans / settings / notices
-- ---------------------------------------------------------------------
create or replace function public.platform_set_feature(p_org uuid, p_key text, p_enabled boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._plat_guard();
  if p_key <> all (public._feature_catalog()) then raise exception 'ميزة غير معروفة'; end if;
  delete from public.feature_flags where key = p_key and organization_id is not distinct from p_org;
  if p_enabled is not null then insert into public.feature_flags (organization_id, key, enabled) values (p_org, p_key, p_enabled); end if;
  perform public._plat_log('set_feature', coalesce(p_org::text, 'platform'), jsonb_build_object('key', p_key, 'enabled', p_enabled));
end;
$$;

create or replace function public.platform_save_plan(
  p_id uuid, p_code text, p_name text, p_price_cents integer, p_currency text,
  p_max_students integer, p_max_teachers integer, p_features jsonb, p_active boolean
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id; v_limits jsonb := jsonb_build_object('max_students', p_max_students, 'max_teachers', p_max_teachers);
begin
  perform public._plat_guard();
  if p_code !~ '^[a-z0-9_-]{2,30}$' then raise exception 'رمز الخطة: حروف إنجليزية صغيرة وأرقام'; end if;
  if char_length(btrim(coalesce(p_name, ''))) < 2 then raise exception 'اسم الخطة مطلوب'; end if;
  if coalesce(p_price_cents, 0) < 0 then raise exception 'السعر لا يكون سالبًا'; end if;
  if p_max_students is not null and p_max_students < 0 or p_max_teachers is not null and p_max_teachers < 0 then raise exception 'الحدود لا تكون سالبة'; end if;
  if v_id is null then
    insert into public.plans (code, name, price_cents, currency, limits, features, is_active)
    values (p_code, btrim(p_name), coalesce(p_price_cents, 0), upper(coalesce(nullif(p_currency, ''), 'USD')), v_limits, coalesce(p_features, '{}'::jsonb), coalesce(p_active, true))
    returning id into v_id;
  else
    update public.plans set code = p_code, name = btrim(p_name), price_cents = coalesce(p_price_cents, 0), currency = upper(coalesce(nullif(p_currency, ''), 'USD')),
           limits = v_limits, features = coalesce(p_features, '{}'::jsonb), is_active = coalesce(p_active, true) where id = v_id;
    if not found then raise exception 'الخطة غير موجودة'; end if;
  end if;
  perform public._plat_log('save_plan', v_id::text, jsonb_build_object('code', p_code));
  return v_id;
end;
$$;

create or replace function public.platform_delete_plan(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._plat_guard();
  if exists (select 1 from public.organizations where plan_id = p_id) or exists (select 1 from public.subscriptions where plan_id = p_id) then
    raise exception 'الخطة مستخدمة من مراكز — عطّلها بدل حذفها';
  end if;
  delete from public.plans where id = p_id;
  perform public._plat_log('delete_plan', p_id::text);
end;
$$;

create or replace function public.platform_get_settings()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._plat_guard();
  return jsonb_build_object(
    'signup_enabled', public._platform_setting('signup_enabled', 'true') = 'true',
    'default_plan_id', nullif(public._platform_setting('default_plan_id', ''), ''),
    'trial_days', coalesce(nullif(public._platform_setting('trial_days', '14'), '')::integer, 14));
end;
$$;

create or replace function public.platform_set_settings(p_signup boolean, p_default_plan uuid, p_trial_days integer)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._plat_guard();
  if p_trial_days is null or p_trial_days < 0 or p_trial_days > 365 then raise exception 'مدة التجربة من 0 إلى 365 يومًا'; end if;
  if p_default_plan is not null and not exists (select 1 from public.plans where id = p_default_plan) then raise exception 'الخطة غير موجودة'; end if;
  insert into public.platform_settings (key, value) values
    ('signup_enabled', case when coalesce(p_signup, false) then 'true' else 'false' end),
    ('default_plan_id', coalesce(p_default_plan::text, '')),
    ('trial_days', p_trial_days::text)
  on conflict (key) do update set value = excluded.value, updated_at = now();
  perform public._plat_log('platform_settings', null, jsonb_build_object('signup', p_signup, 'plan', p_default_plan, 'trial_days', p_trial_days));
end;
$$;

create or replace function public.platform_list_notices()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._plat_guard();
  return coalesce((select jsonb_agg(to_jsonb(n) order by n.created_at desc) from public.platform_notices n), '[]'::jsonb);
end;
$$;

create or replace function public.platform_save_notice(p_id uuid, p_title text, p_body text, p_level text, p_active boolean, p_ends timestamptz)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id;
begin
  perform public._plat_guard();
  if p_level not in ('info', 'warning', 'critical') then raise exception 'مستوى غير صحيح'; end if;
  if v_id is null then
    insert into public.platform_notices (title, body, level, is_active, ends_at, created_by)
    values (btrim(p_title), nullif(btrim(coalesce(p_body, '')), ''), p_level, coalesce(p_active, true), p_ends, auth.uid()) returning id into v_id;
  else
    update public.platform_notices set title = btrim(p_title), body = nullif(btrim(coalesce(p_body, '')), ''), level = p_level, is_active = coalesce(p_active, true), ends_at = p_ends where id = v_id;
  end if;
  perform public._plat_log('save_notice', v_id::text, jsonb_build_object('title', p_title));
  return v_id;
end;
$$;

create or replace function public.platform_delete_notice(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._plat_guard();
  delete from public.platform_notices where id = p_id;
  perform public._plat_log('delete_notice', p_id::text);
end;
$$;

-- what every signed-in user sees (banner on top of the apps)
create or replace function public.active_platform_notices()
returns jsonb language sql stable security definer set search_path = public as $$
  select case when auth.uid() is null then '[]'::jsonb else coalesce((
    select jsonb_agg(jsonb_build_object('id', id, 'title', title, 'body', body, 'level', level) order by created_at desc)
    from public.platform_notices where is_active and (ends_at is null or ends_at > now())), '[]'::jsonb) end;
$$;

-- ---------------------------------------------------------------------
-- accounts + audit
-- ---------------------------------------------------------------------
create or replace function public.platform_users(p_query text default null, p_limit integer default 30, p_offset integer default 0)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_q text := nullif(btrim(coalesce(p_query, '')), '');
begin
  perform public._plat_guard();
  return jsonb_build_object(
    'total', (select count(*) from auth.users u left join public.profiles p on p.id = u.id
              where v_q is null or u.email ilike '%' || v_q || '%' or p.full_name ilike '%' || v_q || '%'),
    'rows', coalesce((
      select jsonb_agg(x) from (
        select jsonb_build_object('id', u.id, 'email', u.email, 'name', p.full_name, 'created_at', u.created_at, 'last_sign_in', u.last_sign_in_at,
               'banned', u.banned_until is not null and u.banned_until > now(),
               'owner', exists (select 1 from public.platform_owners po where po.user_id = u.id),
               'memberships', coalesce((select jsonb_agg(jsonb_build_object('org', o.name, 'slug', o.slug, 'role', m.role, 'status', m.status))
                                        from public.organization_members m join public.organizations o on o.id = m.organization_id where m.user_id = u.id), '[]'::jsonb)) as x
        from auth.users u left join public.profiles p on p.id = u.id
        where v_q is null or u.email ilike '%' || v_q || '%' or p.full_name ilike '%' || v_q || '%'
        order by u.created_at desc limit least(greatest(p_limit, 1), 100) offset greatest(p_offset, 0)) q), '[]'::jsonb));
end;
$$;

create or replace function public.platform_audit(p_limit integer default 100)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._plat_guard();
  return coalesce((
    select jsonb_agg(x order by (x ->> 'at') desc) from (
      (select jsonb_build_object('at', a.created_at, 'source', 'platform', 'action', a.action, 'target', a.target, 'detail', a.detail, 'actor', pr.full_name) as x
        from public.platform_audit_log a left join public.profiles pr on pr.id = a.actor_id
        order by a.created_at desc limit least(greatest(p_limit, 1), 300))
      union all
      (select jsonb_build_object('at', l.created_at, 'source', 'center', 'action', l.action || ' ' || l.entity_table, 'target', o.name, 'detail', l.diff, 'actor', pr.full_name)
        from public.audit_log l join public.organizations o on o.id = l.organization_id left join public.profiles pr on pr.id = l.actor_id
        order by l.created_at desc limit least(greatest(p_limit, 1), 300))) u), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- privileges
-- ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'platform_org_detail(uuid)', 'platform_update_org(uuid, text, text, text, text, text, text, uuid, date)',
    'platform_create_org(text, text, uuid, text)', 'platform_delete_org(uuid, text)',
    'platform_set_member(uuid, public.user_role, text)', 'platform_add_member(uuid, text, public.user_role)',
    'platform_set_org_setting(uuid, text, text)', 'platform_set_feature(uuid, text, boolean)',
    'platform_save_plan(uuid, text, text, integer, text, integer, integer, jsonb, boolean)', 'platform_delete_plan(uuid)',
    'platform_get_settings()', 'platform_set_settings(boolean, uuid, integer)',
    'platform_list_notices()', 'platform_save_notice(uuid, text, text, text, boolean, timestamptz)', 'platform_delete_notice(uuid)',
    'active_platform_notices()', 'disabled_modules(uuid)', 'platform_users(text, integer, integer)', 'platform_audit(integer)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  foreach f in array array['_plat_guard()', '_plat_log(text, text, jsonb)', '_platform_setting(text, text)', '_feature_catalog()',
                           'platform_feature_enabled(uuid, text)', '_enforce_plan_limits()'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;
-- redefined above: keep them closed to API roles exactly as before
revoke all on function public._market_enabled(uuid) from public, anon, authenticated;
revoke all on function public._can_message(uuid, uuid) from public, anon, authenticated;
revoke all on function public.member_has_module(uuid, text) from public, anon;
grant execute on function public.member_has_module(uuid, text) to authenticated;
revoke all on function public.create_organization_with_owner(text, text) from public, anon;
grant execute on function public.create_organization_with_owner(text, text) to authenticated;
grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
