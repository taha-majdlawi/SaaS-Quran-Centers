-- =========================================================================
-- 0039_org_logos.sql
-- Center logos uploaded from the device. PUBLIC bucket (the logo is shown on the
-- public center page and login screens); only the center's ADMIN (not a viewing
-- account) can upload / delete, inside their own center's folder <org>/<file>.
-- The chosen file's URL is saved in organizations.logo_url as before, so every
-- screen that already shows the logo (web, mobile, certificates, login) uses it.
-- =========================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('org-logos', 'org-logos', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create or replace function public._logo_upload_ok(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
     and coalesce(array_length(string_to_array(p_name, '/'), 1), 0) = 2
     and split_part(p_name, '/', 1) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     and public.is_org_admin(split_part(p_name, '/', 1)::uuid)
     and not public._is_read_only(split_part(p_name, '/', 1)::uuid);
$$;
grant execute on function public._logo_upload_ok(text) to authenticated;
revoke all on function public._logo_upload_ok(text) from public, anon;

drop policy if exists "org_logos_insert" on storage.objects;
drop policy if exists "org_logos_delete" on storage.objects;
create policy "org_logos_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'org-logos' and public._logo_upload_ok(name));
create policy "org_logos_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'org-logos' and public._logo_upload_ok(name));

grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
