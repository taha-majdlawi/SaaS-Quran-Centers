-- =========================================================================
-- 0051_teacher_circle_scoping.sql
-- Closes a gap left since 0002 on purpose ("left permissive at the org level
-- as the structural starting point"): a teacher could read and WRITE every
-- circle/student/attendance/recitation row in the center, not only the ones
-- they teach (primary or assistant, 0046). A teacher now sees and touches
-- only their own circles' data; the admin is unaffected (still sees/writes
-- everything). Managing circles themselves (create/rename/assign
-- teacher+assistants/archive) becomes admin-only, matching stages/teachers/
-- members - a teacher's own circles stay visible read-only.
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. circles: read-scoped to admin / the circle's own teacher+assistants /
--    a family whose child is enrolled in it (joins elsewhere need this);
--    write becomes admin-only (was: any staff, any circle)
-- ---------------------------------------------------------------------
drop policy if exists "circles_select_org" on public.circles;
drop policy if exists "circles_write_staff" on public.circles;

drop policy if exists "circles_select_scoped" on public.circles;
create policy "circles_select_scoped" on public.circles for select using (
  public.is_org_admin(organization_id)
  or public._is_circle_teacher(id, auth.uid())
  or exists (
    select 1 from public.students_profile sp
    join public.organization_members m on m.user_id = auth.uid() and m.status = 'active'
      and (m.id = sp.member_id or m.id = sp.guardian_member_id)
    where sp.circle_id = circles.id)
);
drop policy if exists "circles_write_admin" on public.circles;
create policy "circles_write_admin" on public.circles for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

-- ---------------------------------------------------------------------
-- 2. students_profile: a teacher sees/writes only their own circles' students
--    (writes also honour the existing "let teachers manage students" toggle);
--    family access unchanged
-- ---------------------------------------------------------------------
drop policy if exists "students_profile_select_staff_or_family" on public.students_profile;
drop policy if exists "students_profile_write_staff" on public.students_profile;

drop policy if exists "students_profile_select_scoped" on public.students_profile;
create policy "students_profile_select_scoped" on public.students_profile for select using (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid()))
  or guardian_member_id in (select id from public.organization_members where user_id = auth.uid())
  or member_id in (select id from public.organization_members where user_id = auth.uid())
);
drop policy if exists "students_profile_write_scoped" on public.students_profile;
create policy "students_profile_write_scoped" on public.students_profile for all using (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid())
      and public.org_setting(organization_id, 'flag_teacher_manage_students', 'true') <> 'false')
) with check (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid())
      and public.org_setting(organization_id, 'flag_teacher_manage_students', 'true') <> 'false')
);

-- ---------------------------------------------------------------------
-- 3. attendance: a teacher only reads/marks their own circles' sessions;
--    a family only reads their own child's
-- ---------------------------------------------------------------------
drop policy if exists "attendance_select_org" on public.attendance;
drop policy if exists "attendance_write_staff" on public.attendance;

drop policy if exists "attendance_select_scoped" on public.attendance;
create policy "attendance_select_scoped" on public.attendance for select using (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid()))
  or student_id = any (public.linked_student_ids(organization_id))
);
drop policy if exists "attendance_write_scoped" on public.attendance;
create policy "attendance_write_scoped" on public.attendance for all using (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid()))
) with check (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid()))
);

-- ---------------------------------------------------------------------
-- 4. daily_achievements: read-scoped the same way. Every write in the app
--    goes through log_recitation/update_recitation (SECURITY DEFINER RPCs
--    that already check _assert_can_record_for_student and bypass RLS
--    entirely, so this doesn't affect them) - but the OLD write policy also
--    left the raw table open to any staff for any student via a direct
--    REST call, not only through those RPCs. Scoped the same way as attendance.
-- ---------------------------------------------------------------------
drop policy if exists "daily_achievements_select_org" on public.daily_achievements;
drop policy if exists "daily_achievements_write_staff" on public.daily_achievements;

drop policy if exists "daily_achievements_select_scoped" on public.daily_achievements;
create policy "daily_achievements_select_scoped" on public.daily_achievements for select using (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid()))
  or student_id = any (public.linked_student_ids(organization_id))
);
drop policy if exists "daily_achievements_write_scoped" on public.daily_achievements;
create policy "daily_achievements_write_scoped" on public.daily_achievements for all using (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid()))
) with check (
  public.is_org_admin(organization_id)
  or (circle_id is not null and public._is_circle_teacher(circle_id, auth.uid()))
);

notify pgrst, 'reload schema';
