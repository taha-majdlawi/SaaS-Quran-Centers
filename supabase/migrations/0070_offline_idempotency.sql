-- 0070: offline-safe teacher writes.
-- The mobile app queues writes while offline and replays them when the
-- connection returns; a replay after a half-received answer must not add the
-- same thing twice. Recitations, serd and external recitations already carry a
-- client_ref (0016 / 0024 / 0045); notes and gatherings get one here.

alter table public.student_notes add column if not exists client_ref uuid;
create unique index if not exists student_notes_client_ref_key on public.student_notes (client_ref) where client_ref is not null;

alter table public.attendance_gatherings add column if not exists client_ref uuid;
create unique index if not exists attendance_gatherings_client_ref_key on public.attendance_gatherings (client_ref) where client_ref is not null;

drop function if exists public.add_student_note(uuid, uuid, text, text);
create or replace function public.add_student_note(p_org uuid, p_student uuid, p_body text, p_visibility text default 'staff_only', p_client_ref uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_body text := nullif(btrim(coalesce(p_body, '')), '');
begin
  perform public._assert_can_write(p_org);
  if not (public.is_org_admin(p_org) or (public.is_org_staff(p_org) and public._teaches_student(p_student))) then raise exception 'غير مصرّح'; end if;
  if p_client_ref is not null then
    select id into v_id from public.student_notes where client_ref = p_client_ref and organization_id = p_org;
    if v_id is not null then return v_id; end if;  -- already received (a replayed offline write)
  end if;
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then raise exception 'الطالب غير موجود'; end if;
  if v_body is null then raise exception 'اكتب الملاحظة'; end if;
  if length(v_body) > 1000 then raise exception 'الملاحظة حتى 1000 حرف'; end if;
  if p_visibility not in ('staff_only', 'guardian_visible') then raise exception 'ظهور غير معروف'; end if;
  insert into public.student_notes (organization_id, student_id, author_id, body, visibility, client_ref)
  values (p_org, p_student, auth.uid(), v_body, p_visibility, p_client_ref)
  returning id into v_id;
  return v_id;
end;
$$;

drop function if exists public.submit_gathering(uuid, text, uuid, date, text, text, text[]);
create or replace function public.submit_gathering(
  p_org uuid, p_title text, p_type uuid, p_date date, p_location text, p_notes text, p_names text[], p_client_ref uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_title text := nullif(btrim(coalesce(p_title, '')), ''); v_date date := coalesce(p_date, public._org_today(p_org));
        v_label text; v_id uuid; v_name text; v_count integer := 0; v_who text;
begin
  perform public._assert_can_write(p_org);
  perform public._assert_gathering_staff(p_org);
  if p_client_ref is not null then
    select id into v_id from public.attendance_gatherings where client_ref = p_client_ref and organization_id = p_org;
    if v_id is not null then
      return jsonb_build_object('id', v_id, 'duplicate', true,
        'names_count', (select count(*) from public.attendance_gathering_entries e where e.gathering_id = v_id));
    end if;
  end if;
  if v_title is null then raise exception 'اكتب اسم النشاط'; end if;
  if v_date > public._org_today(p_org) then raise exception 'لا يمكن رفع حضور بتاريخ مستقبلي'; end if;
  if p_names is null or array_length(p_names, 1) is null then raise exception 'أضف اسمًا واحدًا على الأقل'; end if;
  if array_length(p_names, 1) > 300 then raise exception 'الحد الأقصى 300 اسم في المرة'; end if;
  if p_type is not null then
    select name into v_label from public.activity_types where id = p_type and organization_id = p_org;
    if v_label is null then raise exception 'نوع النشاط غير موجود'; end if;
  end if;
  insert into public.attendance_gatherings (organization_id, title, activity_type_id, activity_type_label, session_date, location, notes, created_by, client_ref)
  values (p_org, v_title, p_type, v_label, v_date, nullif(btrim(coalesce(p_location, '')), ''), nullif(btrim(coalesce(p_notes, '')), ''), auth.uid(), p_client_ref)
  returning id into v_id;
  foreach v_name in array p_names loop
    v_name := btrim(coalesce(v_name, ''));
    continue when v_name = '' or length(v_name) > 120;
    insert into public.attendance_gathering_entries (organization_id, gathering_id, raw_name) values (p_org, v_id, v_name);
    v_count := v_count + 1;
  end loop;
  if v_count = 0 then raise exception 'أضف اسمًا واحدًا على الأقل'; end if;
  select full_name into v_who from public.profiles where id = auth.uid();
  perform public._notify(p_org, public._org_admins(p_org), 'gathering_submitted', 'مجلس جديد بانتظار الربط', v_title, v_id,
    jsonb_build_object('العنوان', v_title, 'عدد', v_count::text, 'المعلم', coalesce(v_who, '')));
  return jsonb_build_object('id', v_id, 'names_count', v_count);
end;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'add_student_note(uuid, uuid, text, text, uuid)',
    'submit_gathering(uuid, text, uuid, date, text, text, text[], uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
