-- =====================================================================
-- 0078: students who need attention
-- ---------------------------------------------------------------------
-- One list, most urgent first, of the students a teacher (their circles,
-- primary or assistant) or an admin (the whole center) should look at today,
-- each with the reasons:
--   behind     the memorization goal is behind plan (and by how many pages)
--   idle       N working days without a recitation (from 3)
--   absences   absent N times in the last 14 days (from 2)
--   never      has never recited
-- The score weights them so that a long silence or a slipping goal rises
-- above one missed day.
-- =====================================================================

create or replace function public.students_needing_attention(p_org uuid, p_limit integer default 100)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_admin boolean := public.is_org_admin(p_org); v_tz text; v_today date; s record; g jsonb;
  v_idle integer; v_abs integer; v_deficit numeric; v_score numeric; v_reasons jsonb; v_out jsonb := '[]'::jsonb;
begin
  -- staff only: an admin sees the center, a teacher the circles they teach
  if not (v_admin or public.is_org_staff(p_org)) then
    raise exception 'غير مصرّح';
  end if;
  v_tz := coalesce((select timezone from public.organizations where id = p_org), 'UTC');
  v_today := (now() at time zone v_tz)::date;

  for s in
    select sp.id, sp.full_name, sp.student_code, sp.circle_id, sp.created_at, sp.phone, sp.whatsapp, c.name as circle_name,
           (select max((d.created_at at time zone v_tz)::date) from public.daily_achievements d where d.student_id = sp.id) as last_day,
           exists (select 1 from public.student_goals gl where gl.student_id = sp.id) as has_goal
      from public.students_profile sp
      left join public.circles c on c.id = sp.circle_id
     where sp.organization_id = p_org and sp.status = 'active' and sp.circle_id is not null
       and (v_admin or public._is_circle_teacher(sp.circle_id))
  loop
    v_reasons := '[]'::jsonb;
    v_score := 0;

    v_idle := public.center_working_days(p_org, greatest(coalesce(s.last_day, (s.created_at at time zone v_tz)::date), v_today - 60) + 1, v_today, s.circle_id);
    if s.last_day is null then
      v_reasons := v_reasons || jsonb_build_object('code', 'never', 'days', v_idle);
      v_score := v_score + 10 + least(v_idle, 30);
    elsif v_idle >= 3 then
      v_reasons := v_reasons || jsonb_build_object('code', 'idle', 'days', v_idle);
      v_score := v_score + 2 * least(v_idle, 30);
    end if;

    select count(*) into v_abs from public.attendance a
     where a.student_id = s.id and a.status::text = 'absent' and a.session_date > v_today - 14;
    if v_abs >= 2 then
      v_reasons := v_reasons || jsonb_build_object('code', 'absences', 'count', v_abs);
      v_score := v_score + 5 * v_abs;
    end if;

    if s.has_goal then
      g := public._goal_progress(p_org, s.id);
      if g->>'status' = 'behind' then
        v_deficit := round(coalesce((g->>'expected_since_start')::numeric, 0) - coalesce((g->>'actual_since_start')::numeric, 0), 1);
        v_reasons := v_reasons || jsonb_build_object('code', 'behind', 'pages', v_deficit, 'pace', g->'pace', 'goal', g->'goal'->'pages_per_day');
        v_score := v_score + 15 + least(v_deficit, 30);
      end if;
    end if;

    continue when jsonb_array_length(v_reasons) = 0;
    v_out := v_out || jsonb_build_object('id', s.id, 'name', s.full_name, 'code', s.student_code,
      'circle_id', s.circle_id, 'circle', s.circle_name, 'phone', s.phone, 'whatsapp', s.whatsapp,
      'last_recited', s.last_day, 'score', v_score, 'reasons', v_reasons);
  end loop;

  return coalesce((select jsonb_agg(x order by (x->>'score')::numeric desc, x->>'name')
                     from (select x from jsonb_array_elements(v_out) x
                           order by (x->>'score')::numeric desc limit least(greatest(coalesce(p_limit, 100), 1), 300)) t), '[]'::jsonb);
end;
$$;
revoke all on function public.students_needing_attention(uuid, integer) from public, anon;
grant execute on function public.students_needing_attention(uuid, integer) to authenticated;

notify pgrst, 'reload schema';
