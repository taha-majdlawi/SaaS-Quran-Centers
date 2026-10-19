-- 0095: a national ID number for students and staff, and a way to sign in with it.
--
-- A student signs in with their number at the center OR their national ID; a teacher or admin
-- with their email OR their national ID - always the same password. The ID only points at the
-- account: the web (lib/auth/national-id.ts) finds the account behind an ID with the service key
-- and signs in with the password as usual, so nothing here reveals who an ID belongs to.
--
-- Stored normalised (lib/auth/national-id.ts): Latin letters and digits only, upper case, 4-20
-- long - Arabic-Indic digits, spaces and dashes are converted / dropped before it gets here.

alter table public.students_profile add column if not exists national_id text;
alter table public.organization_members add column if not exists national_id text;

do $$ begin
  alter table public.students_profile add constraint students_profile_national_id_format
    check (national_id is null or national_id ~ '^[A-Z0-9]{4,20}$');
exception when duplicate_object then null; end $$;
do $$ begin
  alter table public.organization_members add constraint organization_members_national_id_format
    check (national_id is null or national_id ~ '^[A-Z0-9]{4,20}$');
exception when duplicate_object then null; end $$;

-- one person per ID in a center (the same ID may exist in two centers)
create unique index if not exists students_profile_national_id_uniq
  on public.students_profile (organization_id, national_id) where national_id is not null;
create unique index if not exists organization_members_national_id_uniq
  on public.organization_members (organization_id, national_id) where national_id is not null;

-- ...across both tables too: a student's ID may not be a teacher's in the same center, unless it is
-- the same account (a student record's account is its member_id).
create or replace function public._national_id_unique_in_center()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_user uuid; v_clash boolean;
begin
  if new.national_id is null then return new; end if;
  if tg_table_name = 'students_profile' then
    select m.user_id into v_user from public.organization_members m where m.id = new.member_id;
    select exists (
      select 1 from public.organization_members m
      where m.organization_id = new.organization_id and m.national_id = new.national_id
        and m.user_id is distinct from v_user
    ) into v_clash;
  else
    select exists (
      select 1 from public.students_profile sp
      left join public.organization_members m on m.id = sp.member_id
      where sp.organization_id = new.organization_id and sp.national_id = new.national_id
        and m.user_id is distinct from new.user_id
    ) into v_clash;
  end if;
  if v_clash then
    raise exception 'national id already used in this center' using errcode = '23505';
  end if;
  return new;
end;
$$;
revoke all on function public._national_id_unique_in_center() from public, anon, authenticated;

drop trigger if exists students_profile_national_id_unique on public.students_profile;
create trigger students_profile_national_id_unique
  before insert or update of national_id, member_id on public.students_profile
  for each row execute function public._national_id_unique_in_center();
drop trigger if exists organization_members_national_id_unique on public.organization_members;
create trigger organization_members_national_id_unique
  before insert or update of national_id on public.organization_members
  for each row execute function public._national_id_unique_in_center();

-- who may write it: the same people as the rest of the row (RLS: admins; for students also the
-- circle's teacher where the center allows it). Column grants, as 0093 set for these tables.
grant insert (national_id), update (national_id) on public.students_profile to authenticated;
-- (organization_members.national_id is written through set_member_national_id below)

-- Every member of a center may read the center's membership rows (RLS), so the ID must not be one
-- of the columns they can read: SELECT becomes per column, every column but national_id. Admins see
-- the ID of a member through member_national_id(); the sign-in lookup runs with the service key.
revoke select on public.organization_members from authenticated, anon;
grant select (id, organization_id, user_id, role, status, invited_by, created_at, permissions)
  on public.organization_members to authenticated;

-- A center's admin reads / sets a staff member's ID (the teacher edit page, the app's member edit).
create or replace function public.member_national_id(p_org uuid, p_member uuid)
returns text language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'not allowed' using errcode = '42501'; end if;
  return (select national_id from public.organization_members where id = p_member and organization_id = p_org);
end;
$$;
revoke all on function public.member_national_id(uuid, uuid) from public, anon;
grant execute on function public.member_national_id(uuid, uuid) to authenticated;

create or replace function public.set_member_national_id(p_org uuid, p_member uuid, p_national_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'not allowed' using errcode = '42501'; end if;
  update public.organization_members
     set national_id = nullif(btrim(coalesce(p_national_id, '')), '')
   where id = p_member and organization_id = p_org;
  if not found then raise exception 'no such member' using errcode = 'P0002'; end if;
end;
$$;
revoke all on function public.set_member_national_id(uuid, uuid, text) from public, anon;
grant execute on function public.set_member_national_id(uuid, uuid, text) to authenticated;
