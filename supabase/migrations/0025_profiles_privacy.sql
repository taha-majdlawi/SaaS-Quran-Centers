-- =========================================================================
-- 0025_profiles_privacy.sql
-- profiles_select_shared_org let ANY member of a center read the profile row
-- (name, phone, ...) of EVERY other member of it - so a student or guardian
-- could list other families' names and phone numbers. A family account now
-- sees only its own profile and the profiles of the center's STAFF (teachers
-- and admins - the people it deals with); staff still see every member.
-- Functions that show other members' names (chat contacts, rosters, member
-- lists) are SECURITY DEFINER and are unaffected.
-- =========================================================================

drop policy if exists "profiles_select_shared_org" on public.profiles;

create policy "profiles_select_shared_org" on public.profiles for select using (
  id = auth.uid()
  or public.is_platform_owner()
  or exists (
    select 1
    from public.organization_members me
    join public.organization_members them on them.organization_id = me.organization_id
    where me.user_id = auth.uid() and me.status = 'active'
      and them.user_id = profiles.id
      and (
        me.role in ('admin', 'teacher')          -- staff see every member
        or them.role in ('admin', 'teacher')     -- everyone sees the staff
      )
  )
);
