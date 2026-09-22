-- =========================================================================
-- 0052_is_circle_teacher_grant.sql
-- _is_circle_teacher (0046) was revoked from `authenticated` on the
-- assumption it would only ever be called from inside other SECURITY
-- DEFINER functions. 0051 also calls it directly from RLS policy
-- expressions on circles/students_profile/attendance/daily_achievements,
-- which run as the querying role (authenticated) - it needs its own
-- execute grant to be usable there. Still off-limits to anon.
-- =========================================================================
grant execute on function public._is_circle_teacher(uuid, uuid) to authenticated;

notify pgrst, 'reload schema';
