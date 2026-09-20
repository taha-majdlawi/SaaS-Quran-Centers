-- =========================================================================
-- 0026_quran_reader.sql
-- المصحف - the reader itself needs no tables (text and recitations are read
-- from public sources by the clients); what belongs to a PERSON is where they
-- stopped and what they bookmarked, per center. Every member (staff, student,
-- guardian) has their own; nobody can read anybody else's.
--
-- Which reciters a center offers, and its default, are ordinary per-center
-- settings (organization_settings: quran_reciters, quran_default_reciter).
-- =========================================================================

create table public.quran_positions (
  user_id          uuid not null references auth.users (id) on delete cascade,
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  surah            smallint not null check (surah between 1 and 114),
  ayah             smallint not null check (ayah >= 1),
  updated_at       timestamptz not null default now(),
  primary key (user_id, organization_id)
);

create table public.quran_bookmarks (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  surah            smallint not null check (surah between 1 and 114),
  ayah             smallint not null check (ayah >= 1),
  note             text check (note is null or char_length(note) <= 200),
  created_at       timestamptz not null default now(),
  unique (user_id, organization_id, surah, ayah)
);
create index quran_bookmarks_user_idx on public.quran_bookmarks (user_id, organization_id, created_at desc);

alter table public.quran_positions enable row level security;
alter table public.quran_bookmarks enable row level security;
create policy "quran_positions_own" on public.quran_positions for select using (user_id = auth.uid());
create policy "quran_bookmarks_own" on public.quran_bookmarks for select using (user_id = auth.uid());
revoke insert, update, delete on public.quran_positions, public.quran_bookmarks from authenticated;

-- Ayah numbers are validated against the real surah lengths (surah_ayah_counts, 0016).
create or replace function public._check_ayah(p_surah integer, p_ayah integer)
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if p_surah is null or p_ayah is null or not exists (
    select 1 from public.surah_ayah_counts where surah_number = p_surah and p_ayah between 1 and ayah_count
  ) then raise exception 'السورة أو الآية غير صحيحة'; end if;
end;
$$;

create or replace function public.save_reading_position(p_org uuid, p_surah integer, p_ayah integer)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  perform public._check_ayah(p_surah, p_ayah);
  insert into public.quran_positions (user_id, organization_id, surah, ayah) values (auth.uid(), p_org, p_surah, p_ayah)
  on conflict (user_id, organization_id) do update set surah = excluded.surah, ayah = excluded.ayah, updated_at = now();
end;
$$;

create or replace function public.get_reading_state(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  return jsonb_build_object(
    'position', (select jsonb_build_object('surah', surah, 'ayah', ayah, 'updated_at', updated_at)
                 from public.quran_positions where user_id = auth.uid() and organization_id = p_org),
    'bookmarks', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'surah', surah, 'ayah', ayah, 'note', note,
                             'created_at', created_at) order by created_at desc)
                           from public.quran_bookmarks where user_id = auth.uid() and organization_id = p_org), '[]'::jsonb),
    'reciters', public.org_setting(p_org, 'quran_reciters', ''),
    'default_reciter', public.org_setting(p_org, 'quran_default_reciter', '')
  );
end;
$$;

-- Adds the bookmark, or removes it if it is already there (returns whether it now exists).
create or replace function public.toggle_bookmark(p_org uuid, p_surah integer, p_ayah integer, p_note text default null)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  perform public._check_ayah(p_surah, p_ayah);
  delete from public.quran_bookmarks where user_id = auth.uid() and organization_id = p_org and surah = p_surah and ayah = p_ayah;
  if found then return false; end if;
  insert into public.quran_bookmarks (user_id, organization_id, surah, ayah, note)
  values (auth.uid(), p_org, p_surah, p_ayah, nullif(left(btrim(coalesce(p_note, '')), 200), ''));
  return true;
end;
$$;

revoke all on function public._check_ayah(integer, integer) from public, anon, authenticated;
revoke all on function public.save_reading_position(uuid, integer, integer) from public, anon;
revoke all on function public.get_reading_state(uuid) from public, anon;
revoke all on function public.toggle_bookmark(uuid, integer, integer, text) from public, anon;
grant execute on function public.save_reading_position(uuid, integer, integer) to authenticated;
grant execute on function public.get_reading_state(uuid) to authenticated;
grant execute on function public.toggle_bookmark(uuid, integer, integer, text) to authenticated;
