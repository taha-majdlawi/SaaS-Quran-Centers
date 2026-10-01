-- =====================================================================
-- 0077: the smart weekly report for families
-- ---------------------------------------------------------------------
-- The weekly digest (0033/0043) said "recited N times, +P points, present
-- A of B". When the center's admin switches the smart report on
-- (weekly_digest_smart, off by default) it says where the student stands on
-- the memorization goal (ahead / on track / behind, pages this week), how
-- the week compares with the one before, and the teacher's latest note for
-- the family - and the full report opens from the notification.
--
-- student_weekly_report(org, student) is that report; the family, the
-- student's teachers and admins can read it.
-- =====================================================================

-- the goal figures without the caller check, for the report and the digest job
create or replace function public._goal_progress(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s public.students_profile%rowtype; g public.student_goals%rowtype; v_tz text; v_today date;
  v_all integer[]; v_total numeric; v_recent numeric; v_since_start numeric; v_wd_recent integer; v_wd_since integer;
  v_pace numeric; v_expected numeric; v_target integer; v_remaining numeric; v_ratio numeric; v_status text;
  v_forecast date; v_goal_date date;
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
  if v_remaining = 0 then
    v_forecast := v_today;
  elsif v_pace > 0 then
    v_forecast := v_today + ceil(v_remaining / v_pace / v_ratio)::integer;
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
    'goal', case when g.student_id is null then null else jsonb_build_object('pages_per_day', g.pages_per_day, 'target_pages', g.target_pages,
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
    'goal_date', v_goal_date,
    'can_edit', public._can_manage_student(p_org, p_student));
end;
$$;
revoke all on function public._goal_progress(uuid, uuid) from public, anon, authenticated;

create or replace function public.student_goal_progress(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_circle uuid;
begin
  select circle_id into v_circle from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if not (public.is_org_admin(p_org) or public.member_has_module(p_org, 'reports') or public._is_circle_teacher(v_circle)
          or p_student = any (public.linked_student_ids(p_org))) then
    raise exception 'غير مصرّح';
  end if;
  return public._goal_progress(p_org, p_student);
end;
$$;

-- one week (ending p_week_end, default today) against the week before
create or replace function public._weekly_report(p_org uuid, p_student uuid, p_week_end date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s public.students_profile%rowtype; v_tz text; v_end date; v_a timestamptz; v_b timestamptz; v_pa timestamptz;
  w jsonb; p jsonb;
begin
  select * into s from public.students_profile where id = p_student and organization_id = p_org;
  v_tz := coalesce((select timezone from public.organizations where id = p_org), 'UTC');
  v_end := coalesce(p_week_end, (now() at time zone v_tz)::date);
  v_a := ((v_end - 6)::timestamp) at time zone v_tz;           -- this week starts
  v_b := ((v_end + 1)::timestamp) at time zone v_tz;           -- and ends
  v_pa := ((v_end - 13)::timestamp) at time zone v_tz;         -- the week before starts

  select jsonb_build_object(
      'recitations', count(*) filter (where created_at >= v_a),
      'points', coalesce(sum(points_awarded) filter (where created_at >= v_a), 0),
      'new_memorization', count(*) filter (where created_at >= v_a and achievement_type::text = 'new_memorization'),
      'reviews', count(*) filter (where created_at >= v_a and achievement_type::text <> 'new_memorization')),
    jsonb_build_object(
      'recitations', count(*) filter (where created_at < v_a),
      'points', coalesce(sum(points_awarded) filter (where created_at < v_a), 0),
      'new_memorization', count(*) filter (where created_at < v_a and achievement_type::text = 'new_memorization'),
      'reviews', count(*) filter (where created_at < v_a and achievement_type::text <> 'new_memorization'))
    into w, p
    from public.daily_achievements where student_id = p_student and created_at >= v_pa and created_at < v_b;

  -- pages newly memorized in each week
  w := w || jsonb_build_object('pages', public._ayahs_as_pages(coalesce((
          select array_agg(x) from (select generate_series(public._ayah_id(d.surah_from, d.ayah_from), public._ayah_id(coalesce(d.surah_to, d.surah_from), d.ayah_to)) x
            from public.daily_achievements d where d.student_id = p_student and d.achievement_type::text = 'new_memorization'
             and d.created_at >= v_a and d.created_at < v_b and d.surah_from is not null) t), '{}')));
  p := p || jsonb_build_object('pages', public._ayahs_as_pages(coalesce((
          select array_agg(x) from (select generate_series(public._ayah_id(d.surah_from, d.ayah_from), public._ayah_id(coalesce(d.surah_to, d.surah_from), d.ayah_to)) x
            from public.daily_achievements d where d.student_id = p_student and d.achievement_type::text = 'new_memorization'
             and d.created_at >= v_pa and d.created_at < v_a and d.surah_from is not null) t), '{}')));

  -- attendance in each week
  w := w || (select jsonb_build_object('present', count(*) filter (where status::text in ('present', 'late')), 'days', count(*) filter (where status::text in ('present', 'late', 'absent')))
               from public.attendance where student_id = p_student and session_date between v_end - 6 and v_end);
  p := p || (select jsonb_build_object('present', count(*) filter (where status::text in ('present', 'late')), 'days', count(*) filter (where status::text in ('present', 'late', 'absent')))
               from public.attendance where student_id = p_student and session_date between v_end - 13 and v_end - 7);

  return jsonb_build_object(
    'student', jsonb_build_object('id', s.id, 'name', s.full_name, 'circle', (select name from public.circles where id = s.circle_id),
        'teacher', (select pr.full_name from public.circles c join public.profiles pr on pr.id = c.teacher_id where c.id = s.circle_id),
        'next_plan', s.next_plan, 'total_points', s.total_points),
    'from', v_end - 6, 'to', v_end,
    'week', w, 'previous', p,
    'goal', public._goal_progress(p_org, p_student),
    -- the teacher's latest note meant for the family (this week or last)
    'note', (select jsonb_build_object('body', n.body, 'at', n.created_at, 'by', (select full_name from public.profiles where id = n.author_id))
               from public.student_notes n where n.student_id = p_student and n.visibility = 'guardian_visible' and n.created_at >= v_pa
              order by n.created_at desc limit 1),
    'last_recitation', (select jsonb_build_object('at', created_at, 'type', achievement_type::text, 'surah_from', surah_from, 'ayah_from', ayah_from,
                                                  'surah_to', surah_to, 'ayah_to', ayah_to, 'grade', grade)
                          from public.daily_achievements where student_id = p_student order by created_at desc limit 1));
end;
$$;
revoke all on function public._weekly_report(uuid, uuid, date) from public, anon, authenticated;

create or replace function public.student_weekly_report(p_org uuid, p_student uuid, p_week_end date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_circle uuid;
begin
  select circle_id into v_circle from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if not (public.is_org_admin(p_org) or public.member_has_module(p_org, 'reports') or public._is_circle_teacher(v_circle)
          or p_student = any (public.linked_student_ids(p_org))) then
    raise exception 'غير مصرّح';
  end if;
  return public._weekly_report(p_org, p_student, p_week_end) || jsonb_build_object('smart', public.org_setting(p_org, 'weekly_digest_smart', 'false') = 'true');
end;
$$;
revoke all on function public.student_weekly_report(uuid, uuid, date) from public, anon;
grant execute on function public.student_weekly_report(uuid, uuid, date) to authenticated;

-- "↑3" / "↓2" / "=" between two counts
create or replace function public._trend(p_now numeric, p_prev numeric)
returns text language sql immutable as $$
  select case when p_now > p_prev then ' (↑' || rtrim(to_char(p_now - p_prev, 'FM999990.9'), '.') || ')'
              when p_now < p_prev then ' (↓' || rtrim(to_char(p_prev - p_now, 'FM999990.9'), '.') || ')'
              else '' end;
$$;
revoke all on function public._trend(numeric, numeric) from public, anon, authenticated;

-- the digest job: the smart text when the admin turned it on
create or replace function public.send_weekly_digests(p_force_org uuid default null)
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; v_local timestamp; v_users uuid[]; v_from timestamptz; v_n integer; v_pts integer;
        v_att_ok integer; v_att_all integer; v_body text; v_sent integer := 0; v_smart boolean; r jsonb; w jsonb; p jsonb; g jsonb;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o
           where o.status in ('trial', 'active') and (p_force_org is null or o.id = p_force_org)
  loop
    continue when public.org_setting(e.id, 'weekly_digest_enabled', 'true') <> 'true';
    continue when p_force_org is null and (public._notif_settings(e.id)).is_paused;
    v_local := now() at time zone e.tz;
    continue when p_force_org is null and (extract(dow from v_local)::integer <> public._digest_setting(e.id, 'weekly_digest_dow', 4)
                                           or extract(hour from v_local)::integer <> public._digest_setting(e.id, 'weekly_digest_hour', 17));
    -- once per local day
    insert into public.weekly_digests_sent (organization_id, sent_on) values (e.id, v_local::date) on conflict do nothing;
    continue when not found and p_force_org is null;
    v_smart := public.org_setting(e.id, 'weekly_digest_smart', 'false') = 'true';

    v_from := ((v_local::date - 6)::timestamp) at time zone e.tz;
    for s in select id, full_name from public.students_profile where organization_id = e.id and status = 'active' loop
      v_users := public._student_family_users(s.id);
      continue when coalesce(array_length(v_users, 1), 0) = 0;

      if v_smart then
        r := public._weekly_report(e.id, s.id, v_local::date);
        w := r->'week'; p := r->'previous'; g := r->'goal';
        v_body := case when (w->>'recitations')::int > 0
                       then 'سمّع ' || case (w->>'recitations')::int when 1 then 'مرة واحدة' when 2 then 'مرتين'
                                          else (w->>'recitations') || case when (w->>'recitations')::int <= 10 then ' مرات' else ' مرة' end end
                            || public._trend((w->>'recitations')::numeric, (p->>'recitations')::numeric)
                       else 'لم يُسجَّل تسميع هذا الأسبوع' end
               || case when (w->>'pages')::numeric > 0 then ' · حفظ ' || rtrim(to_char((w->>'pages')::numeric, 'FM9990.9'), '.') || ' صفحة' else '' end
               || case g->>'status' when 'ahead' then ' · متقدّم على خطته' when 'on_track' then ' · على خطته' when 'behind' then ' · متأخر عن خطته'
                                    when 'done' then ' · أتمّ هدفه 🎉' else '' end
               || case when (w->>'days')::int > 0 then ' · حضر ' || (w->>'present') || ' من ' || (w->>'days') else '' end
               || case when r->'note' is not null and r->'note' <> 'null'::jsonb then ' · ملاحظة المعلم: ' || left(r->'note'->>'body', 120) else '' end;
      else
        select count(*), coalesce(sum(points_awarded), 0) into v_n, v_pts
          from public.daily_achievements where student_id = s.id and created_at >= v_from;
        select count(*) filter (where status::text in ('present', 'late')), count(*) filter (where status::text in ('present', 'late', 'absent'))
          into v_att_ok, v_att_all from public.attendance where student_id = s.id and session_date >= v_local::date - 6;
        v_body := case when v_n > 0 then 'سمّع ' || v_n || ' مرة · +' || v_pts || ' نقطة' else 'لم يُسجَّل تسميع هذا الأسبوع' end
               || case when v_att_all > 0 then ' · حضر ' || v_att_ok || ' من ' || v_att_all || ' أيام' else '' end;
      end if;
      perform public._notify(e.id, v_users, 'weekly_digest', 'ملخص أسبوع ' || s.full_name, v_body, s.id,
        jsonb_build_object('اسم_الطالب', s.full_name, 'الملخص', v_body), true);
      v_sent := v_sent + 1;
    end loop;
  end loop;
  return v_sent;
end;
$$;
revoke all on function public.send_weekly_digests(uuid) from public, anon, authenticated;

-- settings: the smart switch next to the day and hour
create or replace function public.get_digest_settings(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return jsonb_build_object('enabled', public.org_setting(p_org, 'weekly_digest_enabled', 'true') = 'true',
                            'dow', public._digest_setting(p_org, 'weekly_digest_dow', 4),
                            'hour', public._digest_setting(p_org, 'weekly_digest_hour', 17),
                            'smart', public.org_setting(p_org, 'weekly_digest_smart', 'false') = 'true');
end;
$$;

drop function if exists public.set_digest_settings(uuid, boolean, integer, integer);
create or replace function public.set_digest_settings(p_org uuid, p_enabled boolean, p_dow integer, p_hour integer, p_smart boolean default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if p_dow is null or p_dow < 0 or p_dow > 6 then raise exception 'يوم غير صحيح'; end if;
  if p_hour is null or p_hour < 0 or p_hour > 23 then raise exception 'ساعة غير صحيحة'; end if;
  insert into public.organization_settings (organization_id, key, value, updated_at) values
    (p_org, 'weekly_digest_enabled', case when coalesce(p_enabled, false) then 'true' else 'false' end, now()),
    (p_org, 'weekly_digest_dow', p_dow::text, now()),
    (p_org, 'weekly_digest_hour', p_hour::text, now())
  on conflict (organization_id, key) do update set value = excluded.value, updated_at = now();
  if p_smart is not null then
    insert into public.organization_settings (organization_id, key, value, updated_at)
    values (p_org, 'weekly_digest_smart', case when p_smart then 'true' else 'false' end, now())
    on conflict (organization_id, key) do update set value = excluded.value, updated_at = now();
    insert into public.audit_log (organization_id, actor_id, action, entity_table, diff)
    values (p_org, auth.uid(), 'update', 'organization_settings', jsonb_build_object('weekly_digest_smart', p_smart));
  end if;
end;
$$;
revoke all on function public.set_digest_settings(uuid, boolean, integer, integer, boolean) from public, anon;
grant execute on function public.set_digest_settings(uuid, boolean, integer, integer, boolean) to authenticated;

notify pgrst, 'reload schema';
