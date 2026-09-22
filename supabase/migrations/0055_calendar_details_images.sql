-- =========================================================================
-- 0055_calendar_details_images.sql
-- Surfaces calendar_entry_images (0054) through calendar_entry_details, the
-- one RPC every detail view already calls (staff edit/detail, member "my
-- calendar" detail, mobile event_detail_screen) - so photos show up
-- everywhere an entry's details do, without touching each caller.
-- =========================================================================

create or replace function public.calendar_entry_details(p_org uuid, p_entry uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_base jsonb; v_admin boolean := public.is_org_admin(p_org); v_kids jsonb; v_parts jsonb; v_wait jsonb; v_images jsonb;
begin
  if not exists (select 1 from public.center_calendar where id = p_entry and organization_id = p_org)
     or not public._calendar_visible(p_entry) then
    raise exception 'الفعالية غير موجودة';
  end if;
  v_base := public._calendar_entry_json(p_entry);

  -- The caller's own children / own record, with their registration state.
  select coalesce(jsonb_agg(jsonb_build_object(
      'student_id', sp.id, 'student_name', sp.full_name,
      'registration_id', r.id, 'source', r.source, 'consent_status', r.consent_status,
      'consent_token', r.consent_token, 'result_rank', r.result_rank, 'result_note', r.result_note,
      'waiting', exists (select 1 from public.calendar_waitlist w where w.entry_id = p_entry and w.student_id = sp.id and w.status = 'waiting')
    ) order by sp.full_name), '[]'::jsonb) into v_kids
  from public.students_profile sp
  left join public.calendar_registrations r on r.entry_id = p_entry and r.student_id = sp.id
  where sp.id = any (public.linked_student_ids(p_org));

  -- Staff: the roster (admin: everyone; teacher: their own students).
  select coalesce(jsonb_agg(jsonb_build_object(
      'registration_id', r.id, 'student_id', sp.id, 'student_name', sp.full_name, 'student_code', sp.student_code,
      'circle_name', ci.name, 'source', r.source, 'consent_status', r.consent_status, 'consent_method', r.consent_method,
      'consent_token', r.consent_token, 'result_rank', r.result_rank, 'result_note', r.result_note, 'created_at', r.created_at
    ) order by r.created_at), '[]'::jsonb) into v_parts
  from public.calendar_registrations r
  join public.students_profile sp on sp.id = r.student_id
  left join public.circles ci on ci.id = sp.circle_id
  where r.entry_id = p_entry and (v_admin or public._act_source(p_org, sp.id) = 'teacher');

  select coalesce(jsonb_agg(jsonb_build_object('student_id', sp.id, 'student_name', sp.full_name, 'created_at', w.created_at)
    order by w.created_at), '[]'::jsonb) into v_wait
  from public.calendar_waitlist w join public.students_profile sp on sp.id = w.student_id
  where w.entry_id = p_entry and w.status = 'waiting' and (v_admin or public._act_source(p_org, sp.id) = 'teacher');

  select coalesce(jsonb_agg(jsonb_build_object('id', i.id, 'image_url', i.image_url, 'caption', i.caption)
    order by i.sort_order), '[]'::jsonb) into v_images
  from public.calendar_entry_images i where i.entry_id = p_entry;

  return v_base || jsonb_build_object('mine', v_kids, 'participants', v_parts, 'waitlist', v_wait, 'images', v_images);
end;
$$;

notify pgrst, 'reload schema';
