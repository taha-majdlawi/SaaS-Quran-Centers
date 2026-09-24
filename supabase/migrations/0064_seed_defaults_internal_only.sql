-- =========================================================================
-- 0064_seed_defaults_internal_only.sql
-- Security audit fix. seed_organization_defaults / seed_serd_defaults /
-- seed_calendar_defaults / seed_market_defaults are SECURITY DEFINER with
-- no caller check, and kept Postgres' default EXECUTE grant - so any
-- signed-in account (a student of another center, or anyone after self-serve
-- signup; organization ids are readable by every signed-in user) could call
-- e.g. rpc('seed_organization_defaults', {p_org: <another center>}) and
-- re-create the grades, weekdays and settings that center's admin had
-- deleted (a deleted grade comes back active and gradable), or its default
-- calendar types / serd error types once it had removed them all.
-- They are only meant to run from the organizations insert triggers and
-- from other SECURITY DEFINER functions (which run as the owner and are not
-- affected), so EXECUTE is withdrawn from every client role.
-- =========================================================================

revoke all on function public.seed_organization_defaults(uuid) from public, anon, authenticated;
revoke all on function public.seed_serd_defaults(uuid) from public, anon, authenticated;
revoke all on function public.seed_calendar_defaults(uuid) from public, anon, authenticated;
revoke all on function public.seed_market_defaults(uuid) from public, anon, authenticated;

notify pgrst, 'reload schema';
