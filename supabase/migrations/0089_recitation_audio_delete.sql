-- =========================================================================
-- 0089_recitation_audio_delete.sql
-- A recording can be removed by whoever uploaded it only while it is not part
-- of a recitation sent to the teacher: a sent recording is the teacher's to
-- hear (it used to be removable at any time).
-- =========================================================================

create or replace function public._recitation_audio_deletable(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from public.recitation_submissions r where r.audio_path = p_name and r.status <> 'draft');
$$;
revoke all on function public._recitation_audio_deletable(text) from public, anon;
grant execute on function public._recitation_audio_deletable(text) to authenticated;

drop policy if exists "recitations_delete" on storage.objects;
create policy "recitations_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'recitations' and owner = auth.uid() and public._recitation_audio_deletable(name));
