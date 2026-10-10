-- =========================================================================
-- 0094_platform_owner_mfa.sql
-- The owner's account is the strongest on the platform, so once the owner
-- has a verified second factor (TOTP, Supabase Auth MFA), the database only
-- treats them as the owner in a session that passed it (the JWT's aal is
-- aal2). A stolen password alone (aal1) then opens nothing of the console:
-- every RLS policy and owner function goes through is_platform_owner().
--
-- An owner with no factor yet keeps working at aal1 (the first sign-in, and a
-- project where MFA is off); the console sends them to set one up.
-- If auth.mfa_factors cannot be read, an aal1 owner is refused (fail closed),
-- never anyone else.
-- =========================================================================

create or replace function public.is_platform_owner()
returns boolean
language plpgsql stable security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null or not exists (select 1 from public.platform_owners where user_id = v_uid) then
    return false;
  end if;
  if coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2' then
    return true;
  end if;
  begin
    return not exists (select 1 from auth.mfa_factors f where f.user_id = v_uid and f.status::text = 'verified');
  exception when others then
    return false;
  end;
end;
$$;

comment on function public.is_platform_owner() is
  'In platform_owners, and past the second factor (aal2) once one is verified (0094).';

notify pgrst, 'reload schema';
