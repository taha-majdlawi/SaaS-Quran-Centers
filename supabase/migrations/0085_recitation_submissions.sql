-- =========================================================================
-- 0085_recitation_submissions.sql
-- Reciting to the system, and the teacher testing from the mushaf.
--
--   * A student (or their guardian) records a recitation of a range of ayahs
--     in the mushaf. The recording is kept in the private bucket `recitations`
--     ({org}/{student}/{id}.wav), the site transcribes it and compares it with
--     the text (auto_score / auto_result - an aid, not a verdict), and the
--     student sends it to the circle's teacher.
--   * The teacher listens, then approves - which records it in the student's
--     log exactly like a recitation heard in the circle (log_recitation:
--     grade, points, attendance) - or rejects it with a note.
--   * The teacher can also test a student in the mushaf (ayahs hidden,
--     mistakes marked on the words); saving records it in the log at once and
--     keeps the marked mistakes with it.
--
-- Drafts (recorded, not yet sent) are only seen by the family.
-- =========================================================================

create table if not exists public.recitation_submissions (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  student_id       uuid not null references public.students_profile (id) on delete cascade,
  circle_id        uuid references public.circles (id) on delete set null,
  kind             text not null default 'self' check (kind in ('self', 'teacher_test')),
  achievement_type public.achievement_type not null default 'new_memorization',
  surah            smallint not null check (surah between 1 and 114),
  ayah_from        smallint not null check (ayah_from >= 1),
  ayah_to          smallint not null check (ayah_to >= ayah_from),
  audio_path       text,
  duration_sec     integer check (duration_sec is null or duration_sec between 0 and 1800),
  status           text not null default 'draft' check (status in ('draft', 'submitted', 'approved', 'rejected')),
  -- the site's automatic comparison (set by the server, never by the client)
  auto_score       numeric(5, 1) check (auto_score is null or auto_score between 0 and 100),
  auto_result      jsonb,
  transcript       text,
  checked_at       timestamptz,
  -- the teacher's marks when testing in the mushaf: [{ayah, word, text}]
  mistakes         jsonb,
  grade            text,
  student_note     text check (student_note is null or char_length(student_note) <= 300),
  teacher_note     text check (teacher_note is null or char_length(teacher_note) <= 500),
  submitted_by     uuid references auth.users (id),
  submitted_at     timestamptz,
  reviewed_by      uuid references auth.users (id),
  reviewed_at      timestamptz,
  achievement_id   uuid references public.daily_achievements (id) on delete set null,
  client_ref       uuid unique,
  created_at       timestamptz not null default now()
);
create index if not exists recitation_submissions_inbox_idx on public.recitation_submissions (organization_id, status, submitted_at desc);
create index if not exists recitation_submissions_student_idx on public.recitation_submissions (student_id, created_at desc);

-- may the caller review this student's recitations? (the circle's teacher with the students module, or an admin)
create or replace function public._can_review_recitation(p_org uuid, p_student uuid)
returns boolean language plpgsql stable security definer set search_path = public as $$
begin
  perform public._assert_can_record_for_student(p_org, p_student);
  return true;
exception when others then
  return false;
end;
$$;

alter table public.recitation_submissions enable row level security;
drop policy if exists "recitation_submissions_select" on public.recitation_submissions;
create policy "recitation_submissions_select" on public.recitation_submissions for select using (
  student_id = any (public.linked_student_ids(organization_id))
  or (status <> 'draft' and public._can_review_recitation(organization_id, student_id))
);
revoke insert, update, delete on public.recitation_submissions from anon, authenticated;

drop trigger if exists a_deny_readonly_write on public.recitation_submissions;
create trigger a_deny_readonly_write before insert or update or delete on public.recitation_submissions
  for each row execute function public._deny_readonly_write();

-- ---------------------------------------------------------------------
-- the recordings
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('recitations', 'recitations', false, 31457280, array['audio/wav', 'audio/x-wav', 'audio/wave', 'audio/webm', 'audio/mp4', 'audio/mpeg', 'audio/aac', 'audio/m4a', 'audio/x-m4a'])
on conflict (id) do update
  set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

-- {org}/{student}/{file}: the student's own account or guardian uploads
create or replace function public._recitation_upload_ok(p_name text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_org uuid; v_student uuid;
begin
  if auth.uid() is null or coalesce(array_length(string_to_array(p_name, '/'), 1), 0) <> 3 then return false; end if;
  begin
    v_org := split_part(p_name, '/', 1)::uuid;
    v_student := split_part(p_name, '/', 2)::uuid;
  exception when others then
    return false;
  end;
  return v_student = any (public.linked_student_ids(v_org)) and not public._is_read_only(v_org);
end;
$$;

-- the family, and the teacher once the recitation was sent
create or replace function public._recitation_audio_visible(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and exists (
    select 1 from public.recitation_submissions r
    where r.audio_path = p_name
      and (r.student_id = any (public.linked_student_ids(r.organization_id))
           or (r.status <> 'draft' and public._can_review_recitation(r.organization_id, r.student_id))));
$$;

revoke all on function public._recitation_upload_ok(text), public._recitation_audio_visible(text) from public, anon;
grant execute on function public._recitation_upload_ok(text), public._recitation_audio_visible(text) to authenticated;
revoke all on function public._can_review_recitation(uuid, uuid) from public, anon;
grant execute on function public._can_review_recitation(uuid, uuid) to authenticated;

drop policy if exists "recitations_select" on storage.objects;
drop policy if exists "recitations_insert" on storage.objects;
drop policy if exists "recitations_delete" on storage.objects;
create policy "recitations_select" on storage.objects for select to authenticated
  using (bucket_id = 'recitations' and public._recitation_audio_visible(name));
create policy "recitations_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'recitations' and public._recitation_upload_ok(name));
-- a discarded draft's file is removed by whoever uploaded it
create policy "recitations_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'recitations' and owner = auth.uid());

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------
-- A recorded recitation, not yet sent (the site checks it next).
create or replace function public.create_recitation(
  p_org uuid, p_student uuid, p_type text, p_surah integer, p_ayah_from integer, p_ayah_to integer,
  p_audio_path text, p_duration integer default null, p_note text default null, p_client_ref uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_circle uuid;
begin
  if p_student is null or not (p_student = any (public.linked_student_ids(p_org))) then raise exception 'غير مصرّح'; end if;
  perform public._assert_can_write(p_org);
  if p_client_ref is not null then
    select id into v_id from public.recitation_submissions where client_ref = p_client_ref and organization_id = p_org;
    if found then return v_id; end if;
  end if;
  if p_type not in ('new_memorization', 'recent_review', 'distant_review') then raise exception 'نوع التسميع غير صالح'; end if;
  perform public.validate_ayah_range(p_surah, p_ayah_from, p_ayah_to);
  if p_audio_path is null or split_part(p_audio_path, '/', 1) <> p_org::text or split_part(p_audio_path, '/', 2) <> p_student::text then
    raise exception 'ملف التسجيل غير صالح';
  end if;
  select circle_id into v_circle from public.students_profile where id = p_student;
  insert into public.recitation_submissions (organization_id, student_id, circle_id, achievement_type, surah, ayah_from, ayah_to,
                                             audio_path, duration_sec, student_note, submitted_by, client_ref)
  values (p_org, p_student, v_circle, p_type::public.achievement_type, p_surah, p_ayah_from, p_ayah_to,
          p_audio_path, p_duration, nullif(left(btrim(coalesce(p_note, '')), 300), ''), auth.uid(), p_client_ref)
  returning id into v_id;
  return v_id;
end;
$$;

-- Sends a draft to the circle's teacher.
create or replace function public.submit_recitation(p_id uuid, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r public.recitation_submissions; v_teacher uuid; v_name text;
begin
  select * into r from public.recitation_submissions where id = p_id;
  if not found or not (r.student_id = any (public.linked_student_ids(r.organization_id))) then raise exception 'غير مصرّح'; end if;
  perform public._assert_can_write(r.organization_id);
  if r.status <> 'draft' then return; end if;
  update public.recitation_submissions
     set status = 'submitted', submitted_at = now(), submitted_by = auth.uid(),
         student_note = coalesce(nullif(left(btrim(coalesce(p_note, '')), 300), ''), student_note)
   where id = p_id;
  select c.teacher_id, s.full_name into v_teacher, v_name
    from public.students_profile s left join public.circles c on c.id = s.circle_id where s.id = r.student_id;
  if v_teacher is not null then
    perform public._notify(r.organization_id, array[v_teacher], 'recitation_submitted',
      'تسميع جديد من ' || v_name, public._surah_range_label(r.surah, r.ayah_from, r.ayah_to), p_id,
      jsonb_build_object('اسم_الطالب', v_name, 'المقطع', public._surah_range_label(r.surah, r.ayah_from, r.ayah_to),
                         'النتيجة', coalesce('التقييم الآلي ' || r.auto_score || '%', ''),
                         '_i18n', public._i18n_var('النتيجة', 'automatic check ' || r.auto_score || '%',
                                                   'otomatik kontrol %' || r.auto_score, 'vérification automatique ' || r.auto_score || ' %')),
      false, 'recitation_submitted|' || p_id::text);
  end if;
end;
$$;

-- Removes a draft (the client removes its file).
create or replace function public.discard_recitation(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r public.recitation_submissions;
begin
  select * into r from public.recitation_submissions where id = p_id;
  if not found then return; end if;
  if not (r.student_id = any (public.linked_student_ids(r.organization_id))) then raise exception 'غير مصرّح'; end if;
  if r.status <> 'draft' then raise exception 'لا يمكن حذف تسميع أُرسل للمعلم'; end if;
  delete from public.recitation_submissions where id = p_id;
end;
$$;

-- "سورة البقرة ٥-١٠" for notifications
create or replace function public._surah_range_label(p_surah integer, p_from integer, p_to integer)
returns text language sql immutable set search_path = public as $$
  select 'سورة ' || coalesce((array['الفاتحة','البقرة','آل عمران','النساء','المائدة','الأنعام','الأعراف','الأنفال','التوبة','يونس','هود','يوسف','الرعد','إبراهيم','الحجر','النحل','الإسراء','الكهف','مريم','طه','الأنبياء','الحج','المؤمنون','النور','الفرقان','الشعراء','النمل','القصص','العنكبوت','الروم','لقمان','السجدة','الأحزاب','سبأ','فاطر','يس','الصافات','ص','الزمر','غافر','فصلت','الشورى','الزخرف','الدخان','الجاثية','الأحقاف','محمد','الفتح','الحجرات','ق','الذاريات','الطور','النجم','القمر','الرحمن','الواقعة','الحديد','المجادلة','الحشر','الممتحنة','الصف','الجمعة','المنافقون','التغابن','الطلاق','التحريم','الملك','القلم','الحاقة','المعارج','نوح','الجن','المزمل','المدثر','القيامة','الإنسان','المرسلات','النبأ','النازعات','عبس','التكوير','الانفطار','المطففين','الانشقاق','البروج','الطارق','الأعلى','الغاشية','الفجر','البلد','الشمس','الليل','الضحى','الشرح','التين','العلق','القدر','البينة','الزلزلة','العاديات','القارعة','التكاثر','العصر','الهمزة','الفيل','قريش','الماعون','الكوثر','الكافرون','النصر','المسد','الإخلاص','الفلق','الناس']::text[])[p_surah], p_surah::text)
         || ' ' || p_from || case when p_to <> p_from then '-' || p_to else '' end;
$$;

-- The teacher's decision. Approving writes the recitation into the student's log.
create or replace function public.review_recitation(p_id uuid, p_approve boolean, p_grade text default null,
                                                    p_type text default null, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare r public.recitation_submissions; v_log jsonb; v_note text; v_type text; v_name text;
begin
  select * into r from public.recitation_submissions where id = p_id for update;
  if not found then raise exception 'التسميع غير موجود'; end if;
  perform public._assert_can_record_for_student(r.organization_id, r.student_id);
  perform public._assert_can_write(r.organization_id);
  if r.status <> 'submitted' then raise exception 'تمت مراجعة هذا التسميع من قبل'; end if;
  v_note := nullif(left(btrim(coalesce(p_note, '')), 500), '');

  if p_approve then
    v_type := coalesce(nullif(p_type, ''), r.achievement_type::text);
    -- the submission id doubles as the log's client_ref: approving twice can't log twice
    v_log := public.log_recitation(r.organization_id, r.student_id, v_type, r.surah, r.ayah_from, r.ayah_to, p_grade,
               concat_ws(' · ', 'تسميع مسجّل', case when r.auto_score is not null then 'التقييم الآلي ' || r.auto_score || '%' end, v_note),
               r.id, coalesce(r.submitted_at, now()), null);
    update public.recitation_submissions
       set status = 'approved', grade = p_grade, achievement_type = v_type::public.achievement_type, teacher_note = v_note,
           reviewed_by = auth.uid(), reviewed_at = now(), achievement_id = (v_log ->> 'achievement_id')::uuid
     where id = p_id;
  else
    update public.recitation_submissions
       set status = 'rejected', teacher_note = v_note, reviewed_by = auth.uid(), reviewed_at = now()
     where id = p_id;
  end if;

  select full_name into v_name from public.students_profile where id = r.student_id;
  perform public._notify(r.organization_id, public._student_family_users(r.student_id), 'recitation_reviewed',
    case when p_approve then 'اعتُمد تسميعك' else 'أعاد المعلم تسميعك' end,
    public._surah_range_label(r.surah, r.ayah_from, r.ayah_to), p_id,
    jsonb_build_object('اسم_الطالب', v_name, 'المقطع', public._surah_range_label(r.surah, r.ayah_from, r.ayah_to),
                       'الحالة', case when p_approve then 'اعتُمد تسميعك' else 'أعاد المعلم تسميعك' end,
                       'الملاحظة', coalesce(v_note, ''),
                       '_i18n', public._i18n_var('الحالة',
                          case when p_approve then 'Your recitation was approved' else 'Your teacher returned your recitation' end,
                          case when p_approve then 'Dinletmeniz onaylandı' else 'Öğretmeniniz dinletmenizi geri gönderdi' end,
                          case when p_approve then 'Votre récitation a été validée' else 'Votre enseignant a renvoyé votre récitation' end)),
    true, 'recitation_reviewed|' || p_id::text);
  return jsonb_build_object('status', case when p_approve then 'approved' else 'rejected' end, 'achievement_id', v_log ->> 'achievement_id');
end;
$$;

-- The teacher tested the student in the mushaf: straight into the log, with the marked mistakes.
create or replace function public.record_teacher_test(
  p_org uuid, p_student uuid, p_type text, p_surah integer, p_ayah_from integer, p_ayah_to integer,
  p_grade text, p_mistakes jsonb default '[]'::jsonb, p_note text default null, p_client_ref uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_log jsonb; v_n integer; v_circle uuid;
begin
  if p_client_ref is not null then
    select id into v_id from public.recitation_submissions where client_ref = p_client_ref and organization_id = p_org;
    if found then return jsonb_build_object('id', v_id, 'was_duplicate', true); end if;
  end if;
  v_circle := public._assert_can_record_for_student(p_org, p_student);
  perform public._assert_can_write(p_org);
  if jsonb_typeof(coalesce(p_mistakes, '[]'::jsonb)) <> 'array' or jsonb_array_length(coalesce(p_mistakes, '[]'::jsonb)) > 500 then
    raise exception 'قائمة الأخطاء غير صالحة';
  end if;
  v_n := jsonb_array_length(coalesce(p_mistakes, '[]'::jsonb));
  v_id := gen_random_uuid();
  v_log := public.log_recitation(p_org, p_student, p_type, p_surah, p_ayah_from, p_ayah_to, p_grade,
             concat_ws(' · ', 'اختبار في المصحف', 'الأخطاء: ' || v_n, nullif(left(btrim(coalesce(p_note, '')), 500), '')),
             v_id, now(), null);
  insert into public.recitation_submissions (id, organization_id, student_id, circle_id, kind, achievement_type, surah, ayah_from, ayah_to,
                                             status, mistakes, grade, teacher_note, submitted_by, submitted_at, reviewed_by, reviewed_at,
                                             achievement_id, client_ref)
  values (v_id, p_org, p_student, v_circle, 'teacher_test', p_type::public.achievement_type, p_surah, p_ayah_from, p_ayah_to,
          'approved', coalesce(p_mistakes, '[]'::jsonb), p_grade, nullif(left(btrim(coalesce(p_note, '')), 500), ''),
          auth.uid(), now(), auth.uid(), now(), (v_log ->> 'achievement_id')::uuid, p_client_ref);
  return jsonb_build_object('id', v_id, 'achievement_id', v_log ->> 'achievement_id', 'points_awarded', v_log -> 'points_awarded');
end;
$$;

-- what a row looks like to the apps
create or replace function public._recitation_json(r public.recitation_submissions)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', r.id, 'student_id', r.student_id, 'kind', r.kind, 'type', r.achievement_type, 'surah', r.surah,
    'ayah_from', r.ayah_from, 'ayah_to', r.ayah_to, 'audio_path', r.audio_path, 'duration', r.duration_sec,
    'status', r.status, 'auto_score', r.auto_score, 'auto_result', r.auto_result, 'checked_at', r.checked_at,
    'mistakes', r.mistakes, 'grade', r.grade, 'student_note', r.student_note, 'teacher_note', r.teacher_note,
    'submitted_at', r.submitted_at, 'reviewed_at', r.reviewed_at, 'created_at', r.created_at,
    'student', (select full_name from public.students_profile where id = r.student_id),
    'circle', (select name from public.circles where id = r.circle_id),
    'reviewer', (select full_name from public.profiles where id = r.reviewed_by));
$$;

-- The teacher's inbox: what waits (or was decided) for the students the caller can record for.
create or replace function public.recitation_inbox(p_org uuid, p_status text default 'submitted', p_limit integer default 50)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_staff(p_org) then raise exception 'غير مصرّح'; end if;
  return coalesce((
    select jsonb_agg(public._recitation_json(r) order by coalesce(r.submitted_at, r.created_at) desc)
    from (select * from public.recitation_submissions r
           where r.organization_id = p_org and r.kind = 'self' and r.status <> 'draft'
             and (p_status is null or p_status = '' or r.status = p_status)
             and public._can_review_recitation(p_org, r.student_id)
           order by coalesce(r.submitted_at, r.created_at) desc
           limit least(greatest(coalesce(p_limit, 50), 1), 200)) r), '[]'::jsonb);
end;
$$;

-- One student's recitations (family: all, drafts included; staff: what was sent and the tests).
create or replace function public.student_recitations(p_org uuid, p_student uuid, p_limit integer default 30)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_family boolean := p_student = any (public.linked_student_ids(p_org));
begin
  if not v_family and not public._can_review_recitation(p_org, p_student) then raise exception 'غير مصرّح'; end if;
  return coalesce((
    select jsonb_agg(public._recitation_json(r) order by r.created_at desc)
    from (select * from public.recitation_submissions r
           where r.organization_id = p_org and r.student_id = p_student and (v_family or r.status <> 'draft')
           order by r.created_at desc limit least(greatest(coalesce(p_limit, 30), 1), 200)) r), '[]'::jsonb);
end;
$$;

-- how many wait for the caller (dashboard / menu badge)
create or replace function public.recitation_inbox_count(p_org uuid)
returns integer language sql stable security definer set search_path = public as $$
  select case when public.is_org_staff(p_org) then (
    select count(*)::integer from public.recitation_submissions r
     where r.organization_id = p_org and r.status = 'submitted' and r.kind = 'self'
       and public._can_review_recitation(p_org, r.student_id)) else 0 end;
$$;

-- Who the caller recites for, or tests, in the mushaf:
-- staff - the students they can record for; family - their own students.
create or replace function public.recitation_people(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_staff boolean := public.is_org_staff(p_org);
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  if v_staff and (public.is_org_admin(p_org) or public.member_has_module(p_org, 'students')) then
    return jsonb_build_object('mode', 'staff', 'students', coalesce((
      select jsonb_agg(jsonb_build_object('id', s.id, 'name', s.full_name, 'circle', c.name) order by c.name nulls last, s.full_name)
      from public.students_profile s left join public.circles c on c.id = s.circle_id
      where s.organization_id = p_org and s.status = 'active' and (public.is_org_admin(p_org) or c.teacher_id = auth.uid())), '[]'::jsonb));
  end if;
  return jsonb_build_object('mode', case when v_staff then 'none' else 'family' end, 'students', coalesce((
    select jsonb_agg(jsonb_build_object('id', s.id, 'name', s.full_name) order by s.full_name)
    from public.students_profile s where s.id = any (public.linked_student_ids(p_org))), '[]'::jsonb));
end;
$$;

do $$
declare f text;
begin
  foreach f in array array['create_recitation(uuid, uuid, text, integer, integer, integer, text, integer, text, uuid)',
                           'submit_recitation(uuid, text)', 'discard_recitation(uuid)',
                           'review_recitation(uuid, boolean, text, text, text)',
                           'record_teacher_test(uuid, uuid, text, integer, integer, integer, text, jsonb, text, uuid)',
                           'recitation_inbox(uuid, text, integer)', 'student_recitations(uuid, uuid, integer)',
                           'recitation_inbox_count(uuid)', 'recitation_people(uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on function public._recitation_json(public.recitation_submissions) from public, anon, authenticated;
revoke all on function public._surah_range_label(integer, integer, integer) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- notifications (wording per language, as in 0080)
-- ---------------------------------------------------------------------
insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, lead_hours, roles, sort) values
  ('recitation_submitted', 'تسميع مسجّل جديد للمراجعة', 'تسميع جديد من {اسم_الطالب}', '{المقطع} · {النتيجة}',
     array['اسم_الطالب','المقطع','النتيجة'], null, array['teacher','admin'], 260),
  ('recitation_reviewed', 'مراجعة التسميع المسجّل', '{الحالة}', '{المقطع} {الملاحظة}',
     array['اسم_الطالب','المقطع','الحالة','الملاحظة'], null, array['guardian','student'], 261)
on conflict (event_key) do update set name = excluded.name, available_vars = excluded.available_vars, roles = excluded.roles, sort = excluded.sort;

insert into public.notification_default_texts (event_key, lang, title_template, body_template) values
  ('recitation_submitted', 'en', 'New recitation from {اسم_الطالب}', '{المقطع} · {النتيجة}'),
  ('recitation_submitted', 'tr', '{اسم_الطالب} yeni bir dinletme gönderdi', '{المقطع} · {النتيجة}'),
  ('recitation_submitted', 'fr', 'Nouvelle récitation de {اسم_الطالب}', '{المقطع} · {النتيجة}'),
  ('recitation_reviewed', 'en', '{الحالة}', '{المقطع} {الملاحظة}'),
  ('recitation_reviewed', 'tr', '{الحالة}', '{المقطع} {الملاحظة}'),
  ('recitation_reviewed', 'fr', '{الحالة}', '{المقطع} {الملاحظة}')
on conflict (event_key, lang) do update set title_template = excluded.title_template, body_template = excluded.body_template;

notify pgrst, 'reload schema';
