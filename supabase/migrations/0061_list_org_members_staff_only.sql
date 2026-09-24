-- =========================================================================
-- 0061_list_org_members_staff_only.sql
-- Security audit fix. list_org_members (0015) only required is_org_member,
-- and it joins auth.users - so any STUDENT or GUARDIAN account could call
-- rpc('list_org_members', {org_id}) and get the full name, role and login
-- e-mail of every member of the center (every family's real address
-- included). Every caller in the apps is a staff screen (members, teachers,
-- circles, audit, serd scheduling - web (staff) route group + the matching
-- mobile admin/teacher screens), so the gate becomes is_org_staff.
-- Body otherwise unchanged.
-- =========================================================================

create or replace function public.list_org_members(org_id uuid)
returns table (
  id uuid, user_id uuid, role public.user_role, status text, full_name text,
  email text, permissions text[], created_at timestamptz
)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_staff(org_id) then
    raise exception 'not authorized';
  end if;
  return query
  select m.id, m.user_id, m.role, m.status, p.full_name, u.email::text, m.permissions, m.created_at
  from public.organization_members m
  left join public.profiles p on p.id = m.user_id
  left join auth.users u on u.id = m.user_id
  where m.organization_id = org_id
  order by m.created_at;
end;
$$;

notify pgrst, 'reload schema';
