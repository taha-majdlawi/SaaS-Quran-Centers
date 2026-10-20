-- 0097: an invitation is accepted only by the account it was sent to.
--
-- accept_invitation (0011) accepted a valid token for WHOEVER was signed in, and an existing
-- membership took the invitation's role ("on conflict ... do update set role"). So the admin who
-- opened the link they had just made - in the browser where they were signed in - was moved to
-- that role, and the invitee never got an account (seen live: a new center whose only admin
-- became a teacher). Now:
--   * the signed-in account's (confirmed) email must be the invitation's email;
--   * a link never lowers anyone: an existing active member keeps their role, unless the
--     invitation makes them admin.
-- The web join page (apps/web .../join) asks for the password of the invited email, or offers to
-- sign out when another account is signed in.
--
-- Repair of what the old function did: a center left with no admin gets back its creator (the
-- member who joined with the center itself and was invited by nobody), and an invitation that
-- was "accepted" by someone other than the invitee works again.

create or replace function public.accept_invitation(invite_token uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  inv public.organization_invitations;
  v_email text;
  v_confirmed timestamptz;
  v_role public.user_role;
  v_status text;
begin
  if auth.uid() is null then
    raise exception 'must be authenticated';
  end if;

  select * into inv from public.organization_invitations where token = invite_token for update;
  if inv is null or inv.accepted_at is not null or inv.expires_at < now() then
    raise exception 'invalid or expired invitation';
  end if;

  select email, email_confirmed_at into v_email, v_confirmed from auth.users where id = auth.uid();
  if v_email is null or lower(btrim(v_email)) <> lower(btrim(inv.email)) then
    raise exception 'هذه الدعوة مرسلة إلى بريد آخر — سجّل الدخول بالبريد المدعوّ' using errcode = '42501';
  end if;
  if v_confirmed is null then
    raise exception 'أكّد بريدك الإلكتروني أولاً' using errcode = '42501';
  end if;

  select role, status into v_role, v_status
    from public.organization_members where organization_id = inv.organization_id and user_id = auth.uid();
  if not found then
    insert into public.organization_members (organization_id, user_id, role, status, invited_by)
    values (inv.organization_id, auth.uid(), inv.role, 'active', inv.invited_by);
  elsif v_status <> 'active' then
    update public.organization_members set role = inv.role, status = 'active'
     where organization_id = inv.organization_id and user_id = auth.uid();
  elsif inv.role = 'admin' and v_role <> 'admin' then
    update public.organization_members set role = 'admin'
     where organization_id = inv.organization_id and user_id = auth.uid();
  end if;
  -- (an active member otherwise keeps their role: a link never demotes)

  update public.organization_invitations set accepted_at = now() where id = inv.id;
end;
$$;
revoke all on function public.accept_invitation(uuid) from public, anon;
grant execute on function public.accept_invitation(uuid) to authenticated;

-- emails are compared without case or spaces; store them that way
create or replace function public.create_invitation(org_id uuid, invite_email text, invite_role public.user_role)
returns table (token uuid)
language plpgsql security definer set search_path = public as $$
declare v_email text := lower(btrim(coalesce(invite_email, '')));
begin
  if not public.is_org_admin(org_id) then
    raise exception 'not authorized';
  end if;
  perform public._assert_can_write(org_id);
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'بريد إلكتروني غير صالح';
  end if;

  return query
  insert into public.organization_invitations (organization_id, email, role, invited_by)
  values (org_id, v_email, invite_role, auth.uid())
  on conflict (organization_id, email, role)
    do update set token = gen_random_uuid(), expires_at = now() + interval '7 days', accepted_at = null, invited_by = auth.uid()
  returning organization_invitations.token;
end;
$$;
revoke all on function public.create_invitation(uuid, text, public.user_role) from public, anon;
grant execute on function public.create_invitation(uuid, text, public.user_role) to authenticated;

-- ---------------------------------------------------------------------
-- Repair
-- ---------------------------------------------------------------------
-- A center with no active admin: its creator (joined in the same moment as the center, invited by
-- nobody) is an admin again.
update public.organization_members m
   set role = 'admin', status = 'active'
  from public.organizations o
 where o.id = m.organization_id
   and m.invited_by is null
   and abs(extract(epoch from (m.created_at - o.created_at))) < 5
   and not exists (select 1 from public.organization_members a
                    where a.organization_id = o.id and a.role = 'admin' and a.status = 'active');

-- An invitation marked accepted while its invitee is not a member of the center was taken by
-- another account: it works again (until it expires).
update public.organization_invitations i
   set accepted_at = null
 where i.accepted_at is not null
   and not exists (select 1 from public.organization_members m join auth.users u on u.id = m.user_id
                    where m.organization_id = i.organization_id and lower(u.email) = lower(i.email));

notify pgrst, 'reload schema';
