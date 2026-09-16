-- =========================================================================
-- 0019_chat_read_tracking.sql
--
-- Backs the unread-thread indicator on apps/mobile's chat_list_screen:
-- chat_thread_participants had no notion of "read up to when", so there was
-- no way to tell a thread with a new message from one the viewer already
-- saw. No RLS change needed - chat_participants_manage_self (0005) already
-- lets a participant update their OWN row, which covers this new column.
-- =========================================================================

alter table public.chat_thread_participants add column if not exists last_read_at timestamptz;
