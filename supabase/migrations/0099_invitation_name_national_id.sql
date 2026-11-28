-- 0099: an invitation carries the person's name and national ID, and an admin can set a member's name.
--
-- Until now an invitation held only an email and a role, so whoever accepted it joined with no name
-- (the members list showed just the email) and no ID to sign in with. Now the admin who invites may
-- enter the official name and the national ID (both optional on the invitation, as the email may be
-- all they know); accepting the invitation writes them to the account:
--   * the name goes to profiles.full_name when the account has none yet (an existing account keeps
--     the name it already has - the invitation never renames someone);
--   * the ID goes to organization_members.national_id (0095), so the person can sign in with it.
-- A clash on the ID (someone else already has it in the center) never blocks joining: the ID is
-- left empty and the admin sees it on the member's page. create_invitation refuses it up front.
--
-- Also:
--   * set_member_name(), for an admin to give (or fix) the name of any member of the center - the
--     members edit page had no name field at all;
--   * cancel_invitation(), to withdraw an invitation (there was no way to);
--   * create_invitation refuses a "student" invitation (a student needs a student record, made
--     from the students page) and an email that is already an active member (the link would do
--     nothing - it never demotes - unless it makes them admin).

alter table public.organization_invitations add column if not exists full_name text;
alter table public.organization_invitations add column if not exists national_id text;

do $$ begin
  alter table public.organization_invitations add constraint organization_invitations_national_id_format
    check (national_id is null or national_id ~ '^[A-Z0-9]{4,20}$');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------
-- create_invitation: + name, + national ID (optional, so the old 3-argument calls still work)
-- ---------------------------------------------------------------------
drop function if exists public.create_invitation(uuid, text, public.user_role);

create or replace function public.create_invitation(
  org_id uuid, invite_email text, invite_role public.user_role,
  invite_name text default null, invite_national_id text default null)
returns table (token uuid)
language plpgsql security definer set search_path = public as $$
declare
  v_email text := lower(btrim(coalesce(invite_email, '')));
  v_name text := nullif(btrim(coalesce(invite_name, '')), '');
  v_nid text := nullif(btrim(coalesce(invite_national_id, '')), '');
begin
  if not public.is_org_admin(org_id) then
    raise exception 'not authorized';
  end if;
  perform public._assert_can_write(org_id);
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'بريد إلكتروني غير صالح';
  end if;
  -- a student needs a student record (circle, number) that a link cannot make: students are added
  -- from the students page, which creates both. A student invited by email was an empty account.
  if invite_role = 'student' then
    raise exception 'الطلاب يُضافون من صفحة الطلاب (بحلقة ورقم)، لا بدعوة' using errcode = '22023';
  end if;
  -- already an active member: the link would change nothing (it never demotes - 0097), unless it
  -- makes them admin
  if exists (select 1 from public.organization_members m join auth.users u on u.id = m.user_id
              where m.organization_id = org_id and lower(u.email) = v_email and m.status = 'active'
                and (m.role = 'admin' or invite_role <> 'admin')) then
    raise exception 'هذا البريد عضو في المركز بالفعل — غيّر دوره من صفحة الأعضاء' using errcode = '23505';
  end if;
  if v_name is not null and char_length(v_name) > 120 then
    raise exception 'الاسم طويل جدًا';
  end if;
  if v_nid is not null then
    if v_nid !~ '^[A-Z0-9]{4,20}$' then
      raise exception 'رقم الهوية غير صالح';
    end if;
    -- the ID of someone else in this center (staff or student); a person already at the center
    -- under this very email is the same person, so their own ID does not count
    if exists (select 1 from public.organization_members m
                where m.organization_id = org_id and m.national_id = v_nid
                  and m.user_id is distinct from (select u.id from auth.users u where lower(u.email) = v_email limit 1))
       or exists (select 1 from public.students_profile s
                   left join public.organization_members sm on sm.id = s.member_id
                  where s.organization_id = org_id and s.national_id = v_nid
                    and sm.user_id is distinct from (select u.id from auth.users u where lower(u.email) = v_email limit 1))
       or exists (select 1 from public.organization_invitations i
                   where i.organization_id = org_id and i.national_id = v_nid and i.accepted_at is null
                     and i.expires_at > now() and i.email <> v_email) then
      raise exception 'رقم الهوية مستخدم لشخص آخر في هذا المركز' using errcode = '23505';
    end if;
  end if;

  return query
  insert into public.organization_invitations (organization_id, email, role, invited_by, full_name, national_id)
  values (org_id, v_email, invite_role, auth.uid(), v_name, v_nid)
  on conflict (organization_id, email, role)
    do update set token = gen_random_uuid(), expires_at = now() + interval '7 days', accepted_at = null,
                  invited_by = auth.uid(),
                  full_name = coalesce(excluded.full_name, public.organization_invitations.full_name),
                  national_id = coalesce(excluded.national_id, public.organization_invitations.national_id)
  returning organization_invitations.token;
end;
$$;
revoke all on function public.create_invitation(uuid, text, public.user_role, text, text) from public, anon;
grant execute on function public.create_invitation(uuid, text, public.user_role, text, text) to authenticated;

-- ---------------------------------------------------------------------
-- get_invitation: + the name the admin entered (the join page shows it; the ID stays private)
-- ---------------------------------------------------------------------
drop function if exists public.get_invitation(uuid);

create or replace function public.get_invitation(invite_token uuid)
returns table (organization_name text, organization_slug text, email text, role public.user_role, valid boolean, full_name text)
language plpgsql security definer set search_path = public as $$
declare
  inv record;
begin
  select i.email, i.role, i.accepted_at, i.expires_at, i.full_name as inv_name, o.name as org_name, o.slug as org_slug
  into inv
  from public.organization_invitations i
  join public.organizations o on o.id = i.organization_id
  where i.token = invite_token;

  if inv is null then
    return query select null::text, null::text, null::text, null::public.user_role, false, null::text;
    return;
  end if;

  return query
  select inv.org_name, inv.org_slug, inv.email, inv.role, (inv.accepted_at is null and inv.expires_at > now()), inv.inv_name;
end;
$$;
revoke all on function public.get_invitation(uuid) from public;
grant execute on function public.get_invitation(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
-- list_org_invitations: + name and ID, for the admin's pending list
-- ---------------------------------------------------------------------
drop function if exists public.list_org_invitations(uuid);

create or replace function public.list_org_invitations(org_id uuid)
returns table (id uuid, email text, role public.user_role, token uuid, expires_at timestamptz, accepted_at timestamptz,
               full_name text, national_id text)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(org_id) then
    raise exception 'not authorized';
  end if;

  return query
  select i.id, i.email, i.role, i.token, i.expires_at, i.accepted_at, i.full_name, i.national_id
  from public.organization_invitations i
  where i.organization_id = org_id
  order by i.created_at desc;
end;
$$;
revoke all on function public.list_org_invitations(uuid) from public, anon;
grant execute on function public.list_org_invitations(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- accept_invitation (0097) + write the name and the ID
-- ---------------------------------------------------------------------
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

  -- the official name: only where the account has none yet
  if inv.full_name is not null then
    update public.profiles set full_name = inv.full_name
     where id = auth.uid() and nullif(btrim(coalesce(full_name, '')), '') is null;
  end if;

  -- the national ID (a second way to sign in): only where this membership has none, and never
  -- at the cost of joining - a clash (0095's unique rule) leaves it empty for the admin to fix
  if inv.national_id is not null then
    begin
      update public.organization_members set national_id = inv.national_id
       where organization_id = inv.organization_id and user_id = auth.uid() and national_id is null;
    exception when unique_violation then null;
    end;
  end if;

  update public.organization_invitations set accepted_at = now() where id = inv.id;
end;
$$;
revoke all on function public.accept_invitation(uuid) from public, anon;
grant execute on function public.accept_invitation(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- set_member_name: an admin gives (or fixes) a member's official name
-- ---------------------------------------------------------------------
-- profiles.full_name is the person's own across centers, so an account that also belongs to
-- another center (or the platform owner) is renamed only when it has no name yet.
create or replace function public.set_member_name(p_org uuid, p_member uuid, p_name text)
returns void language plpgsql security definer set search_path = public as $$
declare v_user uuid; v_name text := nullif(btrim(coalesce(p_name, '')), ''); v_current text;
begin
  if not public.is_org_admin(p_org) then raise exception 'not allowed' using errcode = '42501'; end if;
  perform public._assert_can_write(p_org);
  select user_id into v_user from public.organization_members where id = p_member and organization_id = p_org;
  if v_user is null then raise exception 'no such member' using errcode = 'P0002'; end if;
  if v_name is null then raise exception 'الاسم مطلوب'; end if;
  if char_length(v_name) > 120 then raise exception 'الاسم طويل جدًا'; end if;

  select nullif(btrim(coalesce(full_name, '')), '') into v_current from public.profiles where id = v_user;
  if v_current is not null and v_current <> v_name and not public._account_only_here(p_org, v_user) then
    raise exception 'هذا الحساب مشترك مع مركز آخر ولا يمكن تغيير اسمه من هنا' using errcode = '42501';
  end if;
  update public.profiles set full_name = v_name where id = v_user;
end;
$$;
revoke all on function public.set_member_name(uuid, uuid, text) from public, anon;
grant execute on function public.set_member_name(uuid, uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- cancel_invitation: an admin withdraws an invitation (a wrong email, a person who won't come)
-- ---------------------------------------------------------------------
create or replace function public.cancel_invitation(p_org uuid, p_invitation uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'not allowed' using errcode = '42501'; end if;
  perform public._assert_can_write(p_org);
  delete from public.organization_invitations
   where id = p_invitation and organization_id = p_org and accepted_at is null;
end;
$$;
revoke all on function public.cancel_invitation(uuid, uuid) from public, anon;
grant execute on function public.cancel_invitation(uuid, uuid) to authenticated;

notify pgrst, 'reload schema';
