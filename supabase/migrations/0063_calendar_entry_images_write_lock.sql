-- =========================================================================
-- 0063_calendar_entry_images_write_lock.sql
-- Security audit: calendar_entry_images (0054) has organization_id but was
-- created without the a_deny_readonly_write trigger every such table carries
-- (0028) - it was the only non-exempt table listed by
-- tables_without_write_lock(), and supabase/tests/invariants.sql fails on it.
-- Not exploitable today (direct writes are revoked and all three admin_*
-- image RPCs already call _assert_can_write), so this is the belt-and-braces
-- layer the rule asks for, not a hole being closed.
-- =========================================================================

drop trigger if exists a_deny_readonly_write on public.calendar_entry_images;
create trigger a_deny_readonly_write before insert or update or delete on public.calendar_entry_images
  for each row execute function public._deny_readonly_write();
