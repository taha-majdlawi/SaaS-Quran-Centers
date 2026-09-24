-- =========================================================================
-- 0057_daily_achievements_rpc_only.sql
-- Security audit fix. The raw daily_achievements table was still writable
-- over REST by any teacher (0051's "daily_achievements_write_scoped" and the
-- older "daily_achievements_write_admin" policies), and that path skipped
-- every rule log_recitation enforces:
--   * the policy only looked at the row's OWN circle_id, which the caller
--     picks - a teacher could insert {student_id: <any student>, circle_id:
--     <my circle>} and the row was accepted, for students outside their
--     circles (and for another center's student, since organization_id isn't
--     tied to the circle either);
--   * stamp_achievement_points keeps a client-supplied points_awarded, so a
--     direct insert with points_awarded = 100000 went straight into
--     students_profile.total_points (leaderboards, badges, market currency);
--   * no 'students' module check, no grade validation, no backdate limit.
-- No app writes this table directly (web + mobile both go through
-- log_recitation / update_recitation / delete_recitation, which are
-- SECURITY DEFINER and unaffected), so writes become RPC-only - the same
-- pattern as every other audited table. Reads are unchanged.
-- =========================================================================

drop policy if exists "daily_achievements_write_scoped" on public.daily_achievements;
drop policy if exists "daily_achievements_write_admin" on public.daily_achievements;
revoke insert, update, delete on public.daily_achievements from authenticated, anon;

notify pgrst, 'reload schema';
