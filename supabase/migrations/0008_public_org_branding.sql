-- =========================================================================
-- 0008_public_org_branding.sql
-- organizations_select_member_or_owner (0001) blocks anonymous visitors
-- entirely, but a tenant's login/marketing page must render its name,
-- logo, and brand colors BEFORE anyone is authenticated. None of that is
-- sensitive, so add a permissive public-read policy alongside the
-- member-only one (Postgres RLS policies are OR'd together).
-- =========================================================================

create policy "organizations_select_public" on public.organizations
  for select using (true);
