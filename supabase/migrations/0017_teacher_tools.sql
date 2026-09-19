-- Teacher tools (eqraa parity): next-plan editing, recitation delete, and the
-- "today" summary. All go through _assert_can_record_for_student so a teacher
-- can only touch students of their own circle and only with the students
-- module; admins can touch anyone in the center.

create or replace function public.set_student_plan(p_org uuid, p_student uuid, p_next_plan text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_can_record_for_student(p_org, p_student);
  update public.students_profile
     set next_plan = nullif(trim(p_next_plan), '')
   where id = p_student and organization_id = p_org;
end;
$$;

create or replace function public.delete_recitation(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_row record;
begin
  select id, organization_id, student_id into v_row from public.daily_achievements where id = p_id;
  if not found then raise exception 'السجل غير موجود'; end if;
  perform public._assert_can_record_for_student(v_row.organization_id, v_row.student_id);
  -- total_points is maintained by trg_sync_student_total_points (DELETE branch)
  delete from public.daily_achievements where id = p_id;
end;
$$;

-- Today at a glance: one row per circle the caller manages (admin: all).
create or replace function public.get_teacher_today(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_tz    text;
  v_today date;
  v_dow   smallint;
  v_working boolean;
  v_circles jsonb;
begin
  if auth.uid() is null or not public.is_org_staff(p_org) then
    raise exception 'غير مصرّح';
  end if;

  select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = p_org;
  v_today := (now() at time zone v_tz)::date;
  v_dow := extract(dow from v_today)::smallint;
  select coalesce(is_working, true) into v_working
    from public.center_weekdays where organization_id = p_org and dow = v_dow;

  select coalesce(jsonb_agg(row_to_json(t) order by t.name), '[]'::jsonb) into v_circles from (
    select c.id, c.name,
      (select count(*) from public.students_profile sp
         where sp.circle_id = c.id and sp.status = 'active') as students,
      (select count(distinct da.student_id) from public.daily_achievements da
         join public.students_profile sp on sp.id = da.student_id
         where sp.circle_id = c.id and (da.created_at at time zone v_tz)::date = v_today) as recited,
      (select count(*) from public.attendance a
         join public.students_profile sp on sp.id = a.student_id
         where sp.circle_id = c.id and a.session_date = v_today and a.status in ('present', 'late')) as present,
      (select count(*) from public.attendance a
         join public.students_profile sp on sp.id = a.student_id
         where sp.circle_id = c.id and a.session_date = v_today and a.status = 'absent') as absent
    from public.circles c
    where c.organization_id = p_org
      and (public.is_org_admin(p_org) or c.teacher_id = auth.uid())
  ) t;

  return jsonb_build_object('date', v_today, 'is_working_day', coalesce(v_working, true), 'circles', v_circles);
end;
$$;

revoke all on function public.set_student_plan(uuid, uuid, text) from public, anon;
grant execute on function public.set_student_plan(uuid, uuid, text) to authenticated;
revoke all on function public.delete_recitation(uuid) from public, anon;
grant execute on function public.delete_recitation(uuid) to authenticated;
revoke all on function public.get_teacher_today(uuid) from public, anon;
grant execute on function public.get_teacher_today(uuid) to authenticated;
