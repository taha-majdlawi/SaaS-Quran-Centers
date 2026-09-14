-- =========================================================================
-- 0014_fix_list_org_members_types.sql
-- list_org_members (0011) declared `email text`, but auth.users.email is
-- `varchar(255)` - Postgres's RETURNS TABLE type-checking is strict about
-- the exact type, not just compatibility, so every call failed with
-- "42804: structure of query does not match function result type" (this
-- silently surfaced as an empty members list in apps/web, since the error
-- wasn't being displayed before commit 3639060). Explicit cast fixes it.
-- =========================================================================

create or replace function public.list_org_members(org_id uuid)
returns table (id uuid, user_id uuid, role public.user_role, status text, full_name text, email text, created_at timestamptz)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_member(org_id) then
    raise exception 'not authorized';
  end if;

  return query
  select m.id, m.user_id, m.role, m.status, p.full_name, u.email::text, m.created_at
  from public.organization_members m
  left join public.profiles p on p.id = m.user_id
  left join auth.users u on u.id = m.user_id
  where m.organization_id = org_id
  order by m.created_at;
end;
$$;
