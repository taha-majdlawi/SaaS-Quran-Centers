-- =========================================================================
-- 0018_enable_calendar_realtime.sql
--
-- Backs core/calendar/calendar_realtime.dart (apps/mobile), same treatment
-- as 0017 gave chat_messages: add the table to the supabase_realtime
-- publication, or the subscription receives nothing.
--
-- Unlike chat (insert-only), calendar_list_screen.dart wants to react to
-- inserts, updates AND deletes, filtered by organization_id. Postgres only
-- includes a column in a DELETE/UPDATE's old-row WAL image if it's part of
-- the table's replica identity - by default that's just the primary key, so
-- a delete's payload wouldn't carry organization_id at all and the filter
-- could never match it. REPLICA IDENTITY FULL fixes that (small table,
-- admin-authored rows only - the WAL overhead doesn't matter here the way
-- it would on a high-write table like attendance or chat_messages).
-- =========================================================================

alter table public.center_calendar replica identity full;
alter publication supabase_realtime add table public.center_calendar;
