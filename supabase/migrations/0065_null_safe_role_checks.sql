-- =========================================================================
-- 0065_null_safe_role_checks.sql
-- CRITICAL security fix. is_org_admin() (0001) was
--     current_role_in_org(org) = 'admin' or exists(...) or is_platform_owner()
-- and current_role_in_org() is NULL for anyone who is not a member of that
-- center, so for an outsider the whole expression is NULL, not false.
-- In RLS a NULL is "deny", but inside plpgsql
--     if not public.is_org_admin(p_org) then raise exception ...; end if;
-- `not NULL` is NULL, the IF is skipped, and the function carries on.
-- is_org_staff() and member_has_module() (and _can_issue_certificates on
-- top of it) inherited the same NULL.
--
-- Exploit (verified on a replica): ANY signed-in account - a student of
-- another center, or anyone after self-serve signup; center ids are readable
-- by every signed-in user - could call e.g.
--     rpc('admin_export_data',        {p_org: <any center>})  -> the whole center's data
--     rpc('admin_market_wallets',     {p_org: <any center>})
--     rpc('admin_send_notification',  {p_org: <any center>, ...}) -> push to its members
-- and every other RPC guarded only by "if not is_org_admin/is_org_staff/
-- member_has_module(...)". Members of the center were never affected (their
-- role is non-NULL, so the comparison is a real false).
--
-- Fix at the source: the three helpers now always return true/false, so every
-- existing guard written as `if not ...` becomes correct without touching the
-- ~150 functions that use them. Same logic otherwise.
-- =========================================================================

create or replace function public.is_org_admin(org uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(public.current_role_in_org(org) = 'admin', false)
    or exists (
      select 1 from public.account_admin_grants
      where organization_id = org and user_id = auth.uid()
    )
    or public.is_platform_owner();
$$;

create or replace function public.is_org_staff(org uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(public.current_role_in_org(org) in ('admin', 'teacher'), false) or public.is_org_admin(org);
$$;

create or replace function public.member_has_module(org_id uuid, module text)
returns boolean language sql security definer stable set search_path = public as $$
  select public.is_platform_owner() or coalesce(
    public.platform_feature_enabled(org_id, module) and (
      public.is_org_admin(org_id) or exists (
        select 1 from public.organization_members m
        where m.organization_id = org_id and m.user_id = auth.uid() and m.status = 'active'
          and m.role = 'teacher' and module = any (m.permissions))), false);
$$;

notify pgrst, 'reload schema';
