-- 0071: indexes the planner was missing.
-- Every org-scoped read (RLS: organization_id = ...) and every user delete
-- (the ON DELETE SET NULL / CASCADE checks on these columns) otherwise scans
-- the whole table. The big tables first (attendance, audit_log), then the
-- smaller org-scoped ones so they stay fast as centers grow.

-- user references on large tables (deleting an account)
create index if not exists attendance_recorded_by_idx on public.attendance (recorded_by);
create index if not exists audit_log_actor_idx on public.audit_log (actor_id);
create index if not exists platform_audit_log_actor_idx on public.platform_audit_log (actor_id);
create index if not exists student_badges_awarded_by_idx on public.student_badges (awarded_by);
create index if not exists student_notes_author_idx on public.student_notes (author_id);
create index if not exists device_tokens_user_idx on public.device_tokens (user_id);
create index if not exists chat_thread_prefs_user_idx on public.chat_thread_prefs (user_id);

-- org-scoped tables read through RLS
create index if not exists activities_org_idx on public.activities (organization_id);
create index if not exists activity_types_org_idx on public.activity_types (organization_id);
create index if not exists account_access_org_idx on public.account_access (organization_id);
create index if not exists gathering_entries_org_idx on public.attendance_gathering_entries (organization_id);
create index if not exists calendar_entry_images_org_idx on public.calendar_entry_images (organization_id);
create index if not exists circle_assistants_org_idx on public.circle_assistants (organization_id);
create index if not exists device_tokens_org_idx on public.device_tokens (organization_id);
create index if not exists notification_prefs_org_idx on public.notification_prefs (organization_id);
create index if not exists quran_bookmarks_org_idx on public.quran_bookmarks (organization_id);
create index if not exists quran_positions_org_idx on public.quran_positions (organization_id);
create index if not exists serd_stage_portions_org_idx on public.serd_stage_portions (organization_id);
create index if not exists student_notes_org_idx on public.student_notes (organization_id);
create index if not exists student_wallets_org_idx on public.student_wallets (organization_id);

-- lookups the screens do
create index if not exists teacher_attendance_circle_idx on public.teacher_attendance (circle_id, date);
create index if not exists external_recitations_teacher_idx on public.external_recitation_requests (teacher_id, created_at desc);
create index if not exists external_recitations_student_idx on public.external_recitation_requests (matched_student_id);
create index if not exists deletion_requests_student_idx on public.deletion_requests (target_student_id);
create index if not exists center_calendar_type_idx on public.center_calendar (type_id);
create index if not exists serd_session_errors_type_idx on public.serd_session_errors (error_type_id);

-- (student_id) alone is a prefix of daily_achievements_student_created_idx: one index fewer to write on every recitation
drop index if exists public.daily_achievements_student_idx;
