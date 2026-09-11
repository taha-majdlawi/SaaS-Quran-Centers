-- =========================================================================
-- 0010_self_serve_signup.sql
-- organizations_insert_platform_owner (0001) only lets platform owners
-- create a tenant - correct for client-side inserts, but self-serve signup
-- (apps/web/src/app/(marketing)/signup) needs an authenticated visitor to
-- create their OWN organization. This function is the one controlled
-- backdoor: SECURITY DEFINER runs as the table owner, which bypasses RLS
-- (tables here were never put under FORCE ROW LEVEL SECURITY), so it can
-- insert into both organizations and organization_members atomically while
-- ordinary client-side inserts stay blocked by the existing policies.
-- =========================================================================

create or replace function public.create_organization_with_owner(org_name text, org_slug text)
returns table (id uuid, slug text)
language plpgsql security definer set search_path = public as $$
declare
  new_org_id uuid;
begin
  if auth.uid() is null then
    raise exception 'must be authenticated';
  end if;

  insert into public.organizations (name, slug)
  values (org_name, org_slug)
  returning organizations.id into new_org_id;

  insert into public.organization_members (organization_id, user_id, role, status)
  values (new_org_id, auth.uid(), 'admin', 'active');

  return query select new_org_id, org_slug;
end;
$$;

grant execute on function public.create_organization_with_owner(text, text) to authenticated;
