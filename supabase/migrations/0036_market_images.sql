-- =========================================================================
-- 0036_market_images.sql
-- Market item pictures uploaded from the device. A PUBLIC bucket (the pictures
-- are shown to the center's students; the path carries an unguessable id):
-- anyone can view a file by its URL, but only staff who manage the market
-- (module 'market', not a viewing account) can upload / delete, and only inside
-- their own center's folder  <org>/<file>.
-- Also: image_url may only be an https link (or empty).
-- =========================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('market-images', 'market-images', true, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create or replace function public._market_upload_ok(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
     and coalesce(array_length(string_to_array(p_name, '/'), 1), 0) = 2
     and split_part(p_name, '/', 1) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     and public.member_has_module(split_part(p_name, '/', 1)::uuid, 'market')
     and not public._is_read_only(split_part(p_name, '/', 1)::uuid);
$$;
grant execute on function public._market_upload_ok(text) to authenticated;
revoke all on function public._market_upload_ok(text) from public, anon;

drop policy if exists "market_images_insert" on storage.objects;
drop policy if exists "market_images_delete" on storage.objects;
create policy "market_images_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'market-images' and public._market_upload_ok(name));
create policy "market_images_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'market-images' and public._market_upload_ok(name));

create or replace function public._check_market_image()
returns trigger language plpgsql as $$
begin
  if new.image_url is not null and (new.image_url !~ '^https://' or char_length(new.image_url) > 500) then
    raise exception 'رابط الصورة يجب أن يبدأ بـ https:// (أو ارفع صورة من الجهاز)';
  end if;
  return new;
end;
$$;
drop trigger if exists market_items_check_image on public.market_items;
create trigger market_items_check_image before insert or update of image_url on public.market_items
  for each row execute function public._check_market_image();

grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
