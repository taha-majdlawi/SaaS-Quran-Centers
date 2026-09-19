-- =========================================================================
-- 0018_security_hardening.sql
-- 0009 granted ALL on every table and function to `anon` so early queries
-- would not fail with 42501. RLS is the real boundary, but "grant all to
-- anon" leaves two avoidable holes:
--   * every SECURITY DEFINER function was executable by a signed-out caller
--     (functions run with owner rights, so each one had to remember to check
--     auth.uid() - one that forgot would be a public API);
--   * TRUNCATE / TRIGGER / REFERENCES are not subject to RLS at all.
-- This narrows both to what the apps actually use.
-- =========================================================================

-- ---- tables --------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke truncate, references, trigger on all tables in schema public from authenticated;

-- A signed-out visitor may only read a center's public branding (the login
-- screen has to show which center this is). Column-level, so plan / trial
-- dates never leak.
grant select (id, name, slug, logo_url, primary_color, secondary_color, locale, timezone, status)
  on public.organizations to anon;

-- ---- functions -----------------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated, service_role;

-- The only RPC a signed-out user needs: opening an invitation link.
grant execute on function public.get_invitation(uuid) to anon;

-- ---- future objects ------------------------------------------------------
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public revoke execute on functions from public, anon;
alter default privileges in schema public grant execute on functions to authenticated, service_role;
