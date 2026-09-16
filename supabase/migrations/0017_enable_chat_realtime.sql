-- =========================================================================
-- 0017_enable_chat_realtime.sql
--
-- Backs core/chat/chat_realtime.dart (apps/mobile): a Postgres Changes
-- subscription only receives events for a table once that table is added to
-- the supabase_realtime publication - no migration had done that for any
-- table yet, so chat_thread_screen.dart's realtime listener would otherwise
-- silently receive nothing. RLS still gates which rows a given subscriber
-- actually gets (chat_messages_select_participant, 0005), same as a select.
-- =========================================================================

alter publication supabase_realtime add table public.chat_messages;
