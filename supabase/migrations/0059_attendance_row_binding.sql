-- =========================================================================
-- 0059_attendance_row_binding.sql
-- Security audit fix. attendance stays directly writable (the web attendance
-- page and the mobile offline outbox both upsert it over REST), but 0051's
-- write policy only checked the row's OWN circle_id - a value the caller
-- chooses. Nothing tied student_id to that circle, or the circle to
-- organization_id, so:
--   * a teacher could upsert {student_id: <a student of another circle>,
--     circle_id: <my circle>} and mark that student absent/present (feeds
--     attendance rates, dropout-risk, badges, absence reminders);
--   * an admin of any center (self-serve signup makes that anyone) could
--     write rows carrying another center's organization_id/student_id.
-- WITH CHECK now requires: the student belongs to organization_id, the
-- circle (if any) belongs to the same center, and - for a non-admin - the
-- circle is one the caller teaches AND is the student's current circle.
-- USING (which existing rows a teacher may touch) is unchanged.
-- =========================================================================

create or replace function public._attendance_row_ok(p_org uuid, p_student uuid, p_circle uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and exists (
    select 1 from public.students_profile sp
    where sp.id = p_student and sp.organization_id = p_org
      and (p_circle is null or exists (select 1 from public.circles c where c.id = p_circle and c.organization_id = p_org))
      and (public.is_org_admin(p_org)
           or (p_circle is not null and sp.circle_id = p_circle and public._is_circle_teacher(p_circle, auth.uid()))));
$$;
-- used directly in an RLS policy, which runs as the querying role (see 0052)
revoke all on function public._attendance_row_ok(uuid, uuid, uuid) from public, anon;
grant execute on function public._attendance_row_ok(uuid, uuid, uuid) to authenticated;

drop policy if exists "attendance_write_scoped" on public.attendance;
create policy "attendance_write_scoped" on public.attendance for all using (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid()))
) with check (
  public._attendance_row_ok(organization_id, student_id, circle_id)
);

notify pgrst, 'reload schema';
