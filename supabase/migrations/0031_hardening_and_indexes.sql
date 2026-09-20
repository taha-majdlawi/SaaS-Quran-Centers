-- =========================================================================
-- 0031_hardening_and_indexes.sql  (audit round)
-- 1. organizations: RLS lets a center's admin UPDATE the row, and the table
--    grant covered every column - so an admin could change plan_id, status,
--    trial_ends_at or slug (free upgrade, un-suspend, hijack a slug). Admins
--    may now edit only the center's identity; billing/status/slug stay with
--    the platform owner (service role).
-- 2. students_profile: total_points / total_progress / total_parts_count /
--    saved_parts_numbers are computed by triggers and RPCs (all SECURITY
--    DEFINER, unaffected). A teacher holding the "students" module could
--    previously write them directly; no client ever does.
-- 3. audit_log: a staff member could insert rows with any actor_id.
-- 4. Indexes on hot foreign keys / filters that had none.
-- =========================================================================

revoke update on public.organizations from authenticated;
grant update (name, logo_url, primary_color, secondary_color, timezone, locale) on public.organizations to authenticated;

revoke insert, update on public.students_profile from authenticated;
grant insert (organization_id, student_code, full_name, birth_date, circle_id, member_id, guardian_member_id, status, phone, whatsapp, address, next_plan)
  on public.students_profile to authenticated;
grant update (student_code, full_name, birth_date, circle_id, member_id, guardian_member_id, status, phone, whatsapp, address)
  on public.students_profile to authenticated;

drop policy if exists "audit_log_insert_staff" on public.audit_log;
create policy "audit_log_insert_staff" on public.audit_log for insert
  with check (public.is_org_staff(organization_id) and actor_id = auth.uid());

create index if not exists attendance_circle_date_idx on public.attendance (circle_id, session_date);
create index if not exists daily_achievements_circle_idx on public.daily_achievements (circle_id, created_at desc);
create index if not exists daily_achievements_recorder_idx on public.daily_achievements (recorded_by, created_at desc);
create index if not exists students_profile_member_idx on public.students_profile (member_id);
create index if not exists students_profile_guardian_idx on public.students_profile (guardian_member_id);
create index if not exists students_profile_circle_idx on public.students_profile (circle_id);
create index if not exists calendar_waitlist_student_idx on public.calendar_waitlist (student_id);
create index if not exists center_calendar_circle_idx on public.center_calendar (circle_id) where circle_id is not null;
create index if not exists center_calendar_stage_idx on public.center_calendar (stage_id) where stage_id is not null;
create index if not exists circles_stage_idx on public.circles (stage_id);
create index if not exists circles_teacher_idx on public.circles (teacher_id);
create index if not exists student_notes_student_idx on public.student_notes (student_id);
create index if not exists market_purchases_item_idx on public.market_purchases (item_id);
create index if not exists serd_sessions_assigned_idx on public.serd_sessions (assigned_teacher_id) where assigned_teacher_id is not null;
create index if not exists serd_sessions_student_idx on public.serd_sessions (student_id);
create index if not exists chat_messages_sender_idx on public.chat_messages (sender_id);
create index if not exists announcements_circle_idx on public.announcements (circle_id) where circle_id is not null;
create index if not exists deletion_requests_org_idx on public.deletion_requests (organization_id, status);

notify pgrst, 'reload schema';
