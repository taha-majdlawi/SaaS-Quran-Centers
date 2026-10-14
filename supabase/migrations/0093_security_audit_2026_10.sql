-- =========================================================================
-- 0093_security_audit_2026_10.sql
-- Fixes from the October 2026 security audit (docs/SECURITY_AUDIT_2026-10.md).
--
-- 1. CRITICAL - account takeover. organization_members took a direct INSERT
--    from any center admin with ANY user_id: an admin (anyone can register a
--    center) added someone else's account - another center's admin, a teacher,
--    the owner - to their own center, then reset its password or changed its
--    email through the account screens (service key). Direct inserts are now
--    refused (every membership is created by provisioning, an invitation the
--    person accepts, or the owner), a direct UPDATE may only touch role /
--    status / permissions, and the account screens refuse an account that is
--    also somewhere else (_account_only_here, used by the web app).
-- 2. HIGH - plan bypass. feature_flags took writes from a center admin for
--    their own center; since 0088 those rows are the OWNER's switches for the
--    center, so an admin could switch on what their plan does not include.
--    Only the owner's functions write them now.
-- 3. MEDIUM - report_client_error is open to anyone (by design): a flood of
--    made-up errors could fill app_error_groups and push the owner without
--    end. At most 100 new kinds of error an hour, and 10 alerts an hour.
-- =========================================================================

-- 1.
revoke insert on public.organization_members from authenticated, anon;
revoke update on public.organization_members from authenticated, anon;
grant update (role, status, permissions) on public.organization_members to authenticated;
drop policy if exists organization_members_write_admin on public.organization_members;

-- may the account screens of this center change this account's password or email?
-- only when the account belongs to this center alone and is not the owner's
create or replace function public._account_only_here(p_org uuid, p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from public.organization_members m where m.user_id = p_user and m.organization_id <> p_org)
     and not exists (select 1 from public.platform_owners o where o.user_id = p_user);
$$;
revoke all on function public._account_only_here(uuid, uuid) from public, anon, authenticated;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public._account_only_here(uuid, uuid) to service_role;
  end if;
end $$;

-- 2.
drop policy if exists feature_flags_write_org_admin on public.feature_flags;

-- 3.
create or replace function public.report_client_error(
  p_source text, p_message text, p_stack text default null, p_screen text default null, p_url text default null,
  p_org uuid default null, p_app_version text default null, p_os text default null, p_device text default null,
  p_locale text default null, p_breadcrumbs jsonb default '[]', p_extra jsonb default '{}')
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid(); v_org uuid; v_role text; v_fp text; v_msg text; v_new boolean := false; v_reopened boolean := false;
  v_id uuid; g public.app_error_groups%rowtype; v_crumbs jsonb;
begin
  if p_source not in ('web', 'mobile', 'server') then return; end if;
  v_msg := left(btrim(coalesce(p_message, '')), 1000);
  if v_msg = '' then return; end if;
  -- the center only when the person really belongs to it
  if p_org is not null and v_uid is not null then
    select m.organization_id, m.role::text into v_org, v_role from public.organization_members m
     where m.organization_id = p_org and m.user_id = v_uid limit 1;
  end if;
  v_fp := public._error_fingerprint(p_source, v_msg, p_stack);
  v_crumbs := coalesce((select jsonb_agg(left(x::text, 300)) from (
                select x from jsonb_array_elements(case when jsonb_typeof(p_breadcrumbs) = 'array' then p_breadcrumbs else '[]' end) x
                limit 30) t), '[]');

  select * into g from public.app_error_groups where fingerprint = v_fp for update;
  if not found then
    -- open to everyone (a crash on the sign-in page has no account): a flood of made-up errors
    -- must not fill the table or the owner's phone - past 100 new kinds an hour, new ones are dropped
    if (select count(*) from public.app_error_groups where first_seen > now() - interval '1 hour') >= 100 then return; end if;
    insert into public.app_error_groups (fingerprint, source, message, screen, users, last_version)
    values (v_fp, p_source, v_msg, left(p_screen, 300), case when v_uid is null then '{}' else array[v_uid] end, left(p_app_version, 40));
    v_new := true;
  else
    v_reopened := g.resolved_at is not null;
    update public.app_error_groups set
      last_seen = now(), count = count + 1, screen = coalesce(left(p_screen, 300), screen), last_version = coalesce(left(p_app_version, 40), last_version),
      resolved_at = null,
      users = case when v_uid is null or v_uid = any (users) or cardinality(users) >= 50 then users else users || v_uid end
    where fingerprint = v_fp;
  end if;

  -- keep the details, within limits (the count above always goes up)
  if (select count(*) from public.app_errors where fingerprint = v_fp and created_at > now() - interval '1 hour') >= 20 then return; end if;
  if v_uid is not null and (select count(*) from public.app_errors where user_id = v_uid and created_at > now() - interval '1 hour') >= 60 then return; end if;
  if (select count(*) from public.app_errors where created_at > now() - interval '10 minutes') >= 500 then return; end if;

  insert into public.app_errors (fingerprint, source, message, stack, screen, url, user_id, organization_id, role, app_version, os, device, locale, breadcrumbs, extra)
  values (v_fp, p_source, v_msg, left(p_stack, 8000), left(p_screen, 300), left(p_url, 500), v_uid, v_org, v_role,
          left(p_app_version, 40), left(p_os, 80), left(p_device, 120), left(p_locale, 20), v_crumbs,
          case when jsonb_typeof(p_extra) = 'object' and length(p_extra::text) <= 4000 then p_extra else '{}' end)
  returning id into v_id;

  -- a new bug, or one marked fixed that came back: tell the owner now (at most once an hour per bug)
  if (v_new or v_reopened) and (g.alerted_at is null or g.alerted_at < now() - interval '1 hour')
     -- and at most 10 alerts an hour in all
     and (select count(*) from public.app_error_groups where alerted_at > now() - interval '1 hour') < 10 then
    update public.app_error_groups set alerted_at = now() where fingerprint = v_fp;
    perform public._push_dispatch('error', v_id);
  end if;
end;
$$;

notify pgrst, 'reload schema';
