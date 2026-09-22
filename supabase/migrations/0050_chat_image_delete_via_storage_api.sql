-- =========================================================================
-- 0050_chat_image_delete_via_storage_api.sql
-- Supabase refuses a direct DELETE on storage.objects ("use the Storage API
-- instead") - delete_chat_message (0048) tried exactly that and would fail
-- the moment a deleted message actually carried a picture. Fixed the way
-- market-images/org-logos already do it (0036/0039): an RLS delete policy
-- for the uploader's own file, and the client calls storage.remove() itself
-- right after the RPC succeeds. The RPC now hands back the path to remove.
-- =========================================================================
drop policy if exists "chat_images_delete" on storage.objects;
create policy "chat_images_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'chat-images' and public._chat_upload_ok(name));

drop function if exists public.delete_chat_message(uuid);
create function public.delete_chat_message(p_message uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare m public.chat_messages%rowtype;
begin
  select * into m from public.chat_messages where id = p_message;
  if not found or m.sender_id <> auth.uid() then raise exception 'غير مصرّح'; end if;
  if m.deleted_at is not null then return jsonb_build_object('image_path', null); end if; -- already gone: quietly succeed
  update public.chat_messages set body = '', image_path = null, deleted_at = now() where id = p_message;
  return jsonb_build_object('image_path', m.image_path);
end;
$$;
revoke all on function public.delete_chat_message(uuid) from public, anon;
grant execute on function public.delete_chat_message(uuid) to authenticated;

notify pgrst, 'reload schema';
