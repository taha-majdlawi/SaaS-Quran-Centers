-- =========================================================================
-- 0058_student_notes_scoping.sql
-- Security audit fix - same gap as 0051, on a table 0051 didn't cover.
-- student_notes kept its 0003 policies: SELECT and ALL writes for
-- is_org_staff(organization_id). The app only ever reads/writes notes through
-- list_student_notes / add_student_note (0044), which correctly require the
-- admin or the student's own circle teacher - but the raw table stayed open
-- over REST, so ANY teacher could:
--   * GET /rest/v1/student_notes  -> every 'staff_only' note on every student
--     in the center (no ids needed);
--   * PATCH/DELETE any note, including the admin's.
-- Reads are now scoped exactly like list_student_notes (admin, or a teacher
-- of that student's circle; a guardian keeps their 'guardian_visible' notes),
-- and direct writes are revoked - add_student_note is the only write path.
-- =========================================================================

drop policy if exists "student_notes_select_staff" on public.student_notes;
drop policy if exists "student_notes_write_staff" on public.student_notes;

drop policy if exists "student_notes_select_scoped" on public.student_notes;
create policy "student_notes_select_scoped" on public.student_notes for select using (
  public.is_org_admin(organization_id)
  or public._teaches_student(student_id)
  or (visibility = 'guardian_visible' and exists (
        select 1 from public.students_profile s
        join public.organization_members m on m.id = s.guardian_member_id
        where s.id = student_notes.student_id and m.user_id = auth.uid()))
);

revoke insert, update, delete on public.student_notes from authenticated, anon;

notify pgrst, 'reload schema';
