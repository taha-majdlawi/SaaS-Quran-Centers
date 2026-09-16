-- =========================================================================
-- 0016_guardian_calendar_consent.sql
--
-- Backs the guardian consent flow on an event's registration (mobile
-- my_portal, apps/mobile/lib/features/my_portal): a guardian can already
-- INSERT a registration for their own linked student (0006's
-- "calendar_registrations_guardian_consent"), but had no way to withdraw
-- that consent, and calendar_registrations' SELECT policy was still the
-- plain is_org_member check from 0006 - the same per-student over-exposure
-- class 0015 fixed on attendance/serd/wallets/etc, just missed here because
-- this table has no organization_id column of its own (it hangs off
-- center_calendar.id instead, hence the exists() wrapper below).
-- =========================================================================

drop policy "calendar_registrations_select" on public.calendar_registrations;
create policy "calendar_registrations_select_scoped" on public.calendar_registrations for select using (
  exists (
    select 1 from public.center_calendar e
    where e.id = event_id
      and (
        public.member_has_module(e.organization_id, 'calendar')
        or student_id = any(public.linked_student_ids(e.organization_id))
      )
  )
);

-- Also switch staff write access from the old is_org_staff check to the
-- 'calendar' module gate, matching center_calendar_write_staff (0015) -
-- previously a teacher without the calendar module could still manage
-- registrations even though they couldn't touch the event itself.
drop policy "calendar_registrations_write_staff" on public.calendar_registrations;
create policy "calendar_registrations_write_staff" on public.calendar_registrations for all using (
  exists (select 1 from public.center_calendar e where e.id = event_id and public.member_has_module(e.organization_id, 'calendar'))
) with check (
  exists (select 1 from public.center_calendar e where e.id = event_id and public.member_has_module(e.organization_id, 'calendar'))
);

-- A guardian can withdraw consent for their own linked student, mirroring
-- the existing insert policy's guardian_member_id scoping exactly.
create policy "calendar_registrations_guardian_cancel" on public.calendar_registrations for delete using (
  exists (
    select 1 from public.students_profile s
    join public.organization_members m on m.id = s.guardian_member_id
    where s.id = student_id and m.user_id = auth.uid()
  )
);
