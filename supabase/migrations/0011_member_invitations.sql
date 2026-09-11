-- =========================================================================
-- 0011_member_invitations.sql
-- Lets an org admin invite a teacher/admin/guardian/student by email, and
-- lets the invitee accept via a token link, without needing outbound email
-- delivery configured yet - the admin shares the link (WhatsApp, etc.)
-- themselves. All three are SECURITY DEFINER RPCs, each checking authority
-- internally, since organization_invitations RLS (0001) is admin-only and
-- an unauthenticated invitee can't pass that check to read their own invite.
-- =========================================================================

alter table public.organization_invitations
  add constraint organization_invitations_token_key unique (token);

create or replace function public.create_invitation(org_id uuid, invite_email text, invite_role public.user_role)
returns table (token uuid)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(org_id) then
    raise exception 'not authorized';
  end if;

  return query
  insert into public.organization_invitations (organization_id, email, role, invited_by)
  values (org_id, invite_email, invite_role, auth.uid())
  on conflict (organization_id, email, role)
    do update set token = gen_random_uuid(), expires_at = now() + interval '7 days', accepted_at = null
  returning organization_invitations.token;
end;
$$;

grant execute on function public.create_invitation(uuid, text, public.user_role) to authenticated;

create or replace function public.get_invitation(invite_token uuid)
returns table (organization_name text, organization_slug text, email text, role public.user_role, valid boolean)
language plpgsql security definer set search_path = public as $$
declare
  inv record;
begin
  select i.email, i.role, i.accepted_at, i.expires_at, o.name as org_name, o.slug as org_slug
  into inv
  from public.organization_invitations i
  join public.organizations o on o.id = i.organization_id
  where i.token = invite_token;

  if inv is null then
    return query select null::text, null::text, null::text, null::public.user_role, false;
    return;
  end if;

  return query
  select inv.org_name, inv.org_slug, inv.email, inv.role, (inv.accepted_at is null and inv.expires_at > now());
end;
$$;

grant execute on function public.get_invitation(uuid) to anon, authenticated;

create or replace function public.accept_invitation(invite_token uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  inv public.organization_invitations;
begin
  if auth.uid() is null then
    raise exception 'must be authenticated';
  end if;

  select * into inv from public.organization_invitations where token = invite_token;

  if inv is null or inv.accepted_at is not null or inv.expires_at < now() then
    raise exception 'invalid or expired invitation';
  end if;

  insert into public.organization_members (organization_id, user_id, role, status, invited_by)
  values (inv.organization_id, auth.uid(), inv.role, 'active', inv.invited_by)
  on conflict (organization_id, user_id) do update set role = inv.role, status = 'active';

  update public.organization_invitations set accepted_at = now() where token = invite_token;
end;
$$;

grant execute on function public.accept_invitation(uuid) to authenticated;

create or replace function public.list_org_members(org_id uuid)
returns table (id uuid, user_id uuid, role public.user_role, status text, full_name text, email text, created_at timestamptz)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_member(org_id) then
    raise exception 'not authorized';
  end if;

  return query
  select m.id, m.user_id, m.role, m.status, p.full_name, u.email, m.created_at
  from public.organization_members m
  left join public.profiles p on p.id = m.user_id
  left join auth.users u on u.id = m.user_id
  where m.organization_id = org_id
  order by m.created_at;
end;
$$;

grant execute on function public.list_org_members(uuid) to authenticated;

create or replace function public.list_org_invitations(org_id uuid)
returns table (id uuid, email text, role public.user_role, token uuid, expires_at timestamptz, accepted_at timestamptz)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(org_id) then
    raise exception 'not authorized';
  end if;

  return query
  select i.id, i.email, i.role, i.token, i.expires_at, i.accepted_at
  from public.organization_invitations i
  where i.organization_id = org_id
  order by i.created_at desc;
end;
$$;

grant execute on function public.list_org_invitations(uuid) to authenticated;
