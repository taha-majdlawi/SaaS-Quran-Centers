-- =========================================================================
-- 0013_serd_grading.sql
-- serd_sessions had no place to record an outcome - the detailed
-- per-portion (serd_session_parts) and per-error-type (serd_session_errors)
-- tables stay in the schema for future granular grading, but the practical
-- v1 UI records one overall grade + a note per session.
-- =========================================================================

alter table public.serd_sessions
  add column overall_grade numeric(4, 1),
  add column notes text;
