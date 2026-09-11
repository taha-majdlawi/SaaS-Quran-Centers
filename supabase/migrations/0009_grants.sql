-- =========================================================================
-- 0009_grants.sql
-- Every table so far was created via raw SQL (not the Studio table editor),
-- so none of them received Supabase's usual default GRANTs to `anon` /
-- `authenticated`. Without a base GRANT, Postgres rejects the query with
-- "permission denied" (42501) before RLS even runs - RLS policies (already
-- correct on every table) are the real access boundary; these GRANTs just
-- let the roles attempt the query at all, exactly like a fresh Supabase
-- project bootstraps by default.
-- =========================================================================

grant usage on schema public to anon, authenticated, service_role;

grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;
grant all on all functions in schema public to anon, authenticated, service_role;

alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
