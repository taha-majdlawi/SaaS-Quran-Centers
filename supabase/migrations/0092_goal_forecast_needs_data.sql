-- =========================================================================
-- 0092_goal_forecast_needs_data.sql
-- The khatm forecast showed dates like 2058: one recording in four weeks
-- makes a tiny pace and a date decades away. The forecast now needs at least
-- three days of new memorization in the last four weeks and is never more
-- than fifteen years ahead; otherwise there is no date and the apps say the
-- recent memorization is not enough to forecast (they already show that text
-- when forecast_date is null). Unchanged otherwise (_goal_progress, 0079).
-- =========================================================================

create or replace function public._goal_progress(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s public.students_profile%rowtype; g public.student_goals%rowtype; v_tz text; v_today date;
  v_all integer[]; v_total numeric; v_recent numeric; v_since_start numeric; v_wd_recent integer; v_wd_since integer;
  v_pace numeric; v_expected numeric; v_target integer; v_remaining numeric; v_ratio numeric; v_status text;
  v_forecast date; v_goal_date date; v_active_days integer;
begin
  select * into s from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  select * into g from public.student_goals where student_id = p_student;
  v_tz := coalesce((select timezone from public.organizations where id = p_org), 'UTC');
  v_today := (now() at time zone v_tz)::date;

  select coalesce(array_agg(a), '{}') into v_all from public._memorized_ayahs(p_student) a;
  v_total := public._ayahs_as_pages(v_all);
  -- pace: pages newly memorized over the last 28 days, per working day
  v_recent := public._ayahs_as_pages(coalesce((select array_agg(a) from public._memorized_ayahs(p_student, (v_today - 27)::timestamptz) a), '{}'));
  v_wd_recent := greatest(public.center_working_days(p_org, v_today - 27, v_today, s.circle_id), 1);
  v_pace := round(v_recent / v_wd_recent, 2);
  -- how many working days a calendar day is worth here (for turning days of work into a date)
  v_ratio := greatest(public.center_working_days(p_org, v_today + 1, v_today + 84, s.circle_id), 1)::numeric / 84;

  v_target := coalesce(g.target_pages, 604);
  v_remaining := greatest(v_target - v_total, 0);
  -- days with new memorization in those 4 weeks: one or two recordings are no pace to forecast from
  select count(distinct (d.created_at at time zone v_tz)::date) into v_active_days
    from public.daily_achievements d
   where d.student_id = p_student and d.achievement_type::text = 'new_memorization' and d.created_at >= (v_today - 27)::timestamptz;
  if v_remaining = 0 then
    v_forecast := v_today;
  elsif v_pace > 0 and v_active_days >= 3 then
    v_forecast := v_today + ceil(v_remaining / v_pace / v_ratio)::integer;
    -- decades away says nothing useful (and misleads a family): no date rather than 2058
    if v_forecast > v_today + 15 * 365 then v_forecast := null; end if;
  end if;

  if g.student_id is not null then
    v_wd_since := public.center_working_days(p_org, g.start_date, v_today, s.circle_id);
    v_expected := round(g.pages_per_day * v_wd_since, 2);
    v_since_start := public._ayahs_as_pages(coalesce((select array_agg(a) from public._memorized_ayahs(p_student, g.start_date::timestamptz) a), '{}'));
    v_status := case
      when v_remaining = 0 then 'done'
      when v_wd_since = 0 then 'on_track'
      when v_since_start >= v_expected * 1.1 then 'ahead'
      when v_since_start >= v_expected * 0.9 then 'on_track'
      else 'behind' end;
    v_goal_date := case when v_remaining = 0 then v_today else v_today + ceil(v_remaining / g.pages_per_day / v_ratio)::integer end;
  end if;

  return jsonb_build_object(
    'goal', case when g.student_id is null then null else jsonb_build_object('pages_per_day', g.pages_per_day, 'target_pages', g.target_pages, 'review_pages_per_day', g.review_pages_per_day,
             'start_date', g.start_date, 'note', g.note, 'set_by', (select full_name from public.profiles where id = g.set_by), 'updated_at', g.updated_at) end,
    'memorized_pages', v_total,
    'memorized_percent', round(100 * v_total / 604, 1),
    'target_pages', v_target,
    'remaining_pages', round(v_remaining, 2),
    'pace', v_pace,
    'recent_pages', v_recent,
    'expected_since_start', v_expected,
    'actual_since_start', v_since_start,
    'status', v_status,
    'forecast_date', v_forecast,
    'active_days', v_active_days,
    'goal_date', v_goal_date,
    'can_edit', public._can_manage_student(p_org, p_student));
end;
$$;

notify pgrst, 'reload schema';
