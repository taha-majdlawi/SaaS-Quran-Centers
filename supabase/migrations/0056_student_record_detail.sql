-- =========================================================================
-- 0056_student_record_detail.sql
-- Backs the student "سجلّي" (record) screen polish round: a monthly points
-- total and a per-grade points breakdown, computed server-side from each
-- achievement's own FROZEN points_awarded (never a live grade_points()
-- lookup) so the numbers can never drift from students_profile.total_points
-- even after an admin changes a grade's point value later - same reasoning
-- as the existing get_student_dashboard.recent (0016).
--
-- Also returns the student's full recitation/attendance history (capped,
-- not the 20-row home preview) so the record screen can search/filter and
-- group sessions client-side without a second round trip per filter change.
-- =========================================================================

create or replace function public.student_record_detail(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_monthly_points integer; v_points_breakdown jsonb; v_recitations jsonb; v_attendance jsonb;
begin
  if not (p_student = any (public.linked_student_ids(p_org)) or public.is_org_staff(p_org)) then
    raise exception 'غير مصرّح';
  end if;

  select coalesce(sum(da.points_awarded), 0)::int into v_monthly_points
  from public.daily_achievements da
  where da.student_id = p_student
    and date_trunc('month', da.created_at) = date_trunc('month', now());

  select coalesce(jsonb_agg(jsonb_build_object(
      'grade', t.grade, 'count', t.cnt, 'points_each', t.each, 'total', t.total
    ) order by t.each desc), '[]'::jsonb) into v_points_breakdown
  from (
    select da.grade as grade, count(*)::int as cnt, da.points_awarded as each,
           (count(*) * da.points_awarded)::int as total
    from public.daily_achievements da
    where da.student_id = p_student and da.grade is not null
    group by da.grade, da.points_awarded
  ) t
  where t.each > 0;

  select coalesce(jsonb_agg(r order by r.created_at desc), '[]'::jsonb) into v_recitations from (
    select da.id, da.achievement_type as type, da.surah_from as surah, da.ayah_from, da.ayah_to,
           da.grade, coalesce(g.label, da.grade) as grade_label, da.points_awarded, da.notes,
           da.created_at, da.session_group_id
    from public.daily_achievements da
    left join public.recitation_grades g on g.organization_id = da.organization_id and g.key = da.grade
    where da.student_id = p_student
    order by da.created_at desc limit 300
  ) r;

  select coalesce(jsonb_agg(jsonb_build_object('date', a.session_date, 'status', a.status) order by a.session_date desc), '[]'::jsonb)
    into v_attendance
  from (select * from public.attendance where student_id = p_student order by session_date desc limit 200) a;

  return jsonb_build_object(
    'monthly_points', v_monthly_points,
    'points_breakdown', v_points_breakdown,
    'recitations', v_recitations,
    'attendance', v_attendance
  );
end;
$$;

grant execute on function public.student_record_detail(uuid, uuid) to authenticated;
revoke all on function public.student_record_detail(uuid, uuid) from public, anon;

notify pgrst, 'reload schema';
