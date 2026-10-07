-- =========================================================================
-- 0087_live_recitation.sql
-- Live reciting: the student recites in a screen of its own, the device's
-- speech recognition follows word by word (the hidden ayahs uncover as they
-- are read, a forgotten or wrong word stops the student with a red mark),
-- and the result - every word with its state, the heard text, the mistakes -
-- is sent to the teacher in one step. A recording goes with it when the
-- device could record at the same time (the browser); the app sends the
-- result alone (Android cannot record while it recognises speech).
--
-- The result comes from the student's device, so it is what the student saw,
-- not a verdict: the teacher listens (when there is a recording) and decides.
-- =========================================================================

alter table public.recitation_submissions
  add column if not exists source text not null default 'recording' check (source in ('recording', 'live'));

create or replace function public.submit_live_recitation(
  p_org uuid, p_student uuid, p_type text, p_surah integer, p_ayah_from integer, p_ayah_to integer,
  p_result jsonb, p_transcript text default null, p_audio_path text default null, p_duration integer default null,
  p_note text default null, p_client_ref uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_circle uuid; v_words jsonb; v_total integer; v_ok integer; v_score numeric;
begin
  if p_student is null or not (p_student = any (public.linked_student_ids(p_org))) then raise exception 'غير مصرّح'; end if;
  perform public._assert_can_write(p_org);
  if p_client_ref is not null then
    select id into v_id from public.recitation_submissions where client_ref = p_client_ref and organization_id = p_org;
    if found then return v_id; end if;
  end if;
  if p_type not in ('new_memorization', 'recent_review', 'distant_review') then raise exception 'نوع التسميع غير صالح'; end if;
  perform public.validate_ayah_range(p_surah, p_ayah_from, p_ayah_to);
  if p_audio_path is not null and (split_part(p_audio_path, '/', 1) <> p_org::text or split_part(p_audio_path, '/', 2) <> p_student::text) then
    raise exception 'ملف التسجيل غير صالح';
  end if;

  -- keep only the expected shape: [{a, i, s, h?}], states ok / missing / wrong; the score is recomputed here
  v_words := coalesce((
    select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
             'a', (w->>'a')::int, 'i', (w->>'i')::int, 's', w->>'s', 'h', left(nullif(w->>'h', ''), 40))) order by ord)
      from jsonb_array_elements(case when jsonb_typeof(p_result->'words') = 'array' then p_result->'words' else '[]'::jsonb end)
           with ordinality as x(w, ord)
     where w->>'s' in ('ok', 'missing', 'wrong') and (w->>'a') ~ '^\d{1,3}$' and (w->>'i') ~ '^\d{1,4}$'
       and (w->>'a')::int between p_ayah_from and p_ayah_to), '[]'::jsonb);
  v_total := jsonb_array_length(v_words);
  if v_total = 0 or v_total > 3000 then raise exception 'نتيجة التسميع غير صالحة'; end if;
  select count(*) filter (where w->>'s' = 'ok') into v_ok from jsonb_array_elements(v_words) w;
  v_score := round(v_ok * 100.0 / v_total, 1);

  select circle_id into v_circle from public.students_profile where id = p_student;
  insert into public.recitation_submissions (organization_id, student_id, circle_id, achievement_type, surah, ayah_from, ayah_to,
                                             audio_path, duration_sec, source, auto_score, auto_result, transcript, checked_at,
                                             submitted_by, client_ref)
  values (p_org, p_student, v_circle, p_type::public.achievement_type, p_surah, p_ayah_from, p_ayah_to,
          p_audio_path, least(greatest(coalesce(p_duration, 0), 0), 1800), 'live', v_score,
          jsonb_build_object('words', v_words, 'total', v_total, 'ok', v_ok,
                             'missing', (select count(*) from jsonb_array_elements(v_words) w where w->>'s' = 'missing'),
                             'wrong', (select count(*) from jsonb_array_elements(v_words) w where w->>'s' = 'wrong'),
                             'extra', 0, 'score', v_score, 'live', true),
          left(nullif(btrim(coalesce(p_transcript, '')), ''), 6000), now(), auth.uid(), p_client_ref)
  returning id into v_id;
  -- straight to the teacher (notification included)
  perform public.submit_recitation(v_id, p_note);
  return v_id;
end;
$$;
revoke all on function public.submit_live_recitation(uuid, uuid, text, integer, integer, integer, jsonb, text, text, integer, text, uuid) from public, anon;
grant execute on function public.submit_live_recitation(uuid, uuid, text, integer, integer, integer, jsonb, text, text, integer, text, uuid) to authenticated;

-- the apps see where a recitation came from
create or replace function public._recitation_json(r public.recitation_submissions)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', r.id, 'student_id', r.student_id, 'kind', r.kind, 'type', r.achievement_type, 'surah', r.surah,
    'ayah_from', r.ayah_from, 'ayah_to', r.ayah_to, 'audio_path', r.audio_path, 'duration', r.duration_sec,
    'status', r.status, 'auto_score', r.auto_score, 'auto_result', r.auto_result, 'checked_at', r.checked_at,
    'mistakes', r.mistakes, 'grade', r.grade, 'student_note', r.student_note, 'teacher_note', r.teacher_note,
    'submitted_at', r.submitted_at, 'reviewed_at', r.reviewed_at, 'created_at', r.created_at, 'source', r.source,
    'student', (select full_name from public.students_profile where id = r.student_id),
    'circle', (select name from public.circles where id = r.circle_id),
    'reviewer', (select full_name from public.profiles where id = r.reviewed_by));
$$;
revoke all on function public._recitation_json(public.recitation_submissions) from public, anon, authenticated;

notify pgrst, 'reload schema';
