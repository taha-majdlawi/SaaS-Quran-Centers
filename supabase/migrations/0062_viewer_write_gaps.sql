-- =========================================================================
-- 0062_viewer_write_gaps.sql
-- Security audit fix: three direct-table paths a read-only ("viewer", 0028)
-- admin could still write through, because the table is either exempt from
-- a_deny_readonly_write or has no organization_id column for it to key on.
--
-- 1. account_admin_grants (exempt as a "control table"): policy ALL for
--    is_org_admin with direct DML granted. A viewing admin could
--    INSERT {organization_id, user_id: <any account>} and give that account
--    FULL, writable admin rights - an escalation straight out of read-only.
--    Nothing in the apps or any RPC writes this table (it is managed out of
--    band), so direct writes are simply revoked.
-- 2. deletion_requests (exempt as personal state): a viewing admin could
--    PATCH any request's status directly, skipping review_deletion_request's
--    _assert_can_write. Both apps use request_account_deletion /
--    review_deletion_request only, so direct writes are revoked.
-- 3. organizations (keyed by id, not organization_id, so the 0028 loop never
--    saw it): a viewing admin could rename the center, swap its logo/colours
--    or change its time zone with a direct UPDATE. The settings screens do
--    update it directly, so it gets a write-lock trigger instead of a revoke.
-- =========================================================================

revoke insert, update, delete on public.account_admin_grants from authenticated, anon;
revoke insert, update, delete on public.deletion_requests from authenticated, anon;

create or replace function public._deny_readonly_org_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- no signed-in user = platform job / service role; _assert_can_write already treats that as allowed
  perform public._assert_can_write(old.id);
  return new;
end;
$$;
revoke all on function public._deny_readonly_org_update() from public, anon, authenticated;

drop trigger if exists a_deny_readonly_write on public.organizations;
create trigger a_deny_readonly_write before update on public.organizations
  for each row execute function public._deny_readonly_org_update();

notify pgrst, 'reload schema';
