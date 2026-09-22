-- =========================================================================
-- 0049_chat_tombstone_constraint_fix.sql
-- A deleted message (0048) has neither text nor a picture, which the
-- original content-check (0030) did not allow - delete_chat_message's own
-- UPDATE violated it. Widen the constraint to also accept a tombstone.
-- =========================================================================
do $$
declare c text;
begin
  for c in select conname from pg_constraint
           where conrelid = 'public.chat_messages'::regclass and contype = 'c' and pg_get_constraintdef(oid) ilike '%char_length%'
  loop
    execute format('alter table public.chat_messages drop constraint %I', c);
  end loop;
end $$;
alter table public.chat_messages add constraint chat_messages_content_check
  check (char_length(body) <= 2000 and (char_length(body) >= 1 or image_path is not null or deleted_at is not null));

notify pgrst, 'reload schema';
