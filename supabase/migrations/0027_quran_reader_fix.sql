-- 0026's ayah validation used the wrong column name (surah instead of surah_number).
create or replace function public._check_ayah(p_surah integer, p_ayah integer)
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if p_surah is null or p_ayah is null or not exists (
    select 1 from public.surah_ayah_counts where surah_number = p_surah and p_ayah between 1 and ayah_count
  ) then raise exception 'السورة أو الآية غير صحيحة'; end if;
end;
$$;
revoke all on function public._check_ayah(integer, integer) from public, anon, authenticated;
