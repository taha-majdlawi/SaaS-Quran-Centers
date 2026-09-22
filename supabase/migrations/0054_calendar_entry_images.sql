-- =========================================================================
-- 0054_calendar_entry_images.sql
-- Multi-image support for calendar/event entries - the one real gap vs the
-- eqraa reference's registrable calendar entries (calendar_entry_images).
-- Everything else about bustan's calendar/registration system (admin-
-- customizable entry types, capacity, registration deadline, self/guardian
-- registration, waitlist, consent) is already a superset of eqraa's.
--
-- Writes go through admin-only SECURITY DEFINER RPCs (matching
-- center_calendar itself, 0020 - direct table writes stay revoked so every
-- write is validated and audited the same way). Reads follow whoever can
-- already see the entry, via the existing public._calendar_visible() helper.
-- =========================================================================

create table public.calendar_entry_images (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  entry_id        uuid not null references public.center_calendar (id) on delete cascade,
  image_url       text not null,
  caption         text,
  sort_order      integer not null default 0,
  created_by      uuid references auth.users (id),
  created_at      timestamptz not null default now()
);

create index calendar_entry_images_entry_idx on public.calendar_entry_images (entry_id, sort_order);

alter table public.calendar_entry_images enable row level security;

create policy "calendar_entry_images_select" on public.calendar_entry_images for select
  using (public._calendar_visible(entry_id));

revoke insert, update, delete on public.calendar_entry_images from authenticated;

create or replace function public.admin_add_calendar_image(p_org uuid, p_entry uuid, p_image_url text, p_caption text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_next integer;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if not exists (select 1 from public.center_calendar where id = p_entry and organization_id = p_org) then
    raise exception 'الفعالية غير موجودة';
  end if;
  if nullif(btrim(coalesce(p_image_url, '')), '') is null then raise exception 'الصورة مطلوبة'; end if;
  select coalesce(max(sort_order), -1) + 1 into v_next from public.calendar_entry_images where entry_id = p_entry;
  insert into public.calendar_entry_images (organization_id, entry_id, image_url, caption, sort_order, created_by)
  values (p_org, p_entry, p_image_url, nullif(btrim(coalesce(p_caption, '')), ''), v_next, auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.admin_delete_calendar_image(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  delete from public.calendar_entry_images where id = p_id and organization_id = p_org;
end;
$$;

-- p_ids is the images' new front-to-back order; anything not listed keeps its position.
create or replace function public.admin_reorder_calendar_images(p_org uuid, p_entry uuid, p_ids uuid[])
returns void language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_pos integer := 0;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if not exists (select 1 from public.center_calendar where id = p_entry and organization_id = p_org) then
    raise exception 'الفعالية غير موجودة';
  end if;
  foreach v_id in array p_ids loop
    update public.calendar_entry_images set sort_order = v_pos
      where id = v_id and entry_id = p_entry and organization_id = p_org;
    v_pos := v_pos + 1;
  end loop;
end;
$$;

grant execute on function public.admin_add_calendar_image(uuid, uuid, text, text) to authenticated;
grant execute on function public.admin_delete_calendar_image(uuid, uuid) to authenticated;
grant execute on function public.admin_reorder_calendar_images(uuid, uuid, uuid[]) to authenticated;
revoke all on function public.admin_add_calendar_image(uuid, uuid, text, text) from public, anon;
revoke all on function public.admin_delete_calendar_image(uuid, uuid) from public, anon;
revoke all on function public.admin_reorder_calendar_images(uuid, uuid, uuid[]) from public, anon;

-- Storage: public bucket (event photos are non-sensitive), same <org>/<file>
-- convention as org-logos (0039) / market-images (0036). Admin-only, and
-- blocked for a read-only viewer account the same way logo uploads are.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('event-images', 'event-images', true, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

create or replace function public._event_image_upload_ok(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
     and coalesce(array_length(string_to_array(p_name, '/'), 1), 0) = 2
     and split_part(p_name, '/', 1) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     and public.is_org_admin(split_part(p_name, '/', 1)::uuid)
     and not public._is_read_only(split_part(p_name, '/', 1)::uuid);
$$;
grant execute on function public._event_image_upload_ok(text) to authenticated;
revoke all on function public._event_image_upload_ok(text) from public, anon;

create policy "event_images_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'event-images' and public._event_image_upload_ok(name));
create policy "event_images_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'event-images' and public._event_image_upload_ok(name));

notify pgrst, 'reload schema';
