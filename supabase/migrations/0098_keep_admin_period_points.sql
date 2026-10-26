-- 0098: a center always keeps an admin; period points include the ledger.
--
-- 1. The last active admin of a center can no longer be removed, demoted or deactivated (the
--    members page let an admin delete or demote themselves - the same "center with no admin" that
--    0097 repaired after the invitation bug). Deleting the whole center, or the account itself,
--    still works.
-- 2. "Points this month / week / in a challenge" now count attendance and teacher bonus /
--    penalty too (0096's point_adjustments), never the opening balance - as the points spec says.
--    The total (total_points) already did.

-- ---------------------------------------------------------------------
-- 1. Never leave a center without an admin
-- ---------------------------------------------------------------------
create or replace function public._keep_one_admin()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- only an active admin leaving that role matters
  if old.role <> 'admin' or old.status <> 'active' then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if tg_op = 'UPDATE' and new.role = 'admin' and new.status = 'active' and new.organization_id = old.organization_id then
    return new;
  end if;
  -- the center itself, or the account, is being deleted: let it go
  if not exists (select 1 from public.organizations where id = old.organization_id)
     or not exists (select 1 from auth.users where id = old.user_id) then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if not exists (select 1 from public.organization_members m
                  where m.organization_id = old.organization_id and m.role = 'admin' and m.status = 'active'
                    and m.id <> old.id) then
    raise exception 'لا يمكن ترك المركز بدون مدير — عيّن مديرًا آخر أولًا' using errcode = '23514';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;
revoke all on function public._keep_one_admin() from public, anon, authenticated;

drop trigger if exists organization_members_keep_one_admin on public.organization_members;
create trigger organization_members_keep_one_admin
  before update of role, status, organization_id or delete on public.organization_members
  for each row execute function public._keep_one_admin();

-- ---------------------------------------------------------------------
-- 2. Period points: + attendance / bonus / penalty in the period (no opening balance)
-- ---------------------------------------------------------------------
create or replace function public._adjustment_points(p_student uuid, p_from date, p_to date)
returns integer language sql stable security definer set search_path = public as $$
  select coalesce(sum(points), 0)::integer from public.point_adjustments
   where student_id = p_student and source <> 'opening' and occurred_on between p_from and p_to;
$$;
revoke all on function public._adjustment_points(uuid, date, date) from public, anon, authenticated;

create or replace function public.student_record_detail(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_monthly_points integer; v_points_breakdown jsonb; v_recitations jsonb; v_attendance jsonb;
begin
  if not public._can_view_student(p_org, p_student) then
    raise exception 'غير مصرّح';
  end if;

  select coalesce(sum(da.points_awarded), 0)::int into v_monthly_points
  from public.daily_achievements da
  where da.student_id = p_student
    and date_trunc('month', da.created_at) = date_trunc('month', now());
  -- + this month's attendance / bonus / penalty (0098); never the opening balance
  v_monthly_points := v_monthly_points + public._adjustment_points(p_student,
    date_trunc('month', now())::date, (date_trunc('month', now()) + interval '1 month - 1 day')::date);

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

create or replace function public.challenge_board(p_org uuid, p_challenge uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c public.circle_challenges%rowtype; v_tz text; v_from timestamptz; v_to timestamptz;
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  select * into c from public.circle_challenges where id = p_challenge and organization_id = p_org;
  if not found then raise exception 'المنافسة غير موجودة'; end if;
  select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = p_org;
  v_from := (c.starts_on::timestamp) at time zone v_tz;
  v_to := ((c.ends_on + 1)::timestamp) at time zone v_tz;

  return jsonb_build_object('id', c.id, 'title', c.title, 'metric', c.metric, 'starts_on', c.starts_on, 'ends_on', c.ends_on,
    'status', case when current_date < c.starts_on then 'upcoming' when current_date > c.ends_on then 'ended' else 'active' end,
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object('rank', x.rk, 'circle_id', x.circle_id, 'circle_name', x.circle_name,
               'students', x.students, 'total', x.total, 'average', x.avg_value,
               'mine', x.circle_id in (select circle_id from public.students_profile where id = any (public.linked_student_ids(p_org))))
             order by x.rk)
      from (
        select t.*, rank() over (order by t.avg_value desc) as rk
        from (
          select ci.id as circle_id, ci.name as circle_name, count(sp.id) as students,
            case c.metric
              when 'points' then coalesce(sum(coalesce((select sum(da.points_awarded) from public.daily_achievements da
                    where da.student_id = sp.id and da.created_at >= v_from and da.created_at < v_to), 0)
                  + coalesce((select sum(s.points_awarded) from public.serd_sessions s
                    where s.student_id = sp.id and s.status = 'approved' and s.session_date between c.starts_on and c.ends_on), 0)
                  + public._adjustment_points(sp.id, c.starts_on, c.ends_on)), 0)
              when 'recitations' then coalesce(sum((select count(*) from public.daily_achievements da
                    where da.student_id = sp.id and da.created_at >= v_from and da.created_at < v_to)), 0)
              else coalesce(sum((select count(*) from public.attendance a
                    where a.student_id = sp.id and a.session_date between c.starts_on and c.ends_on and a.status in ('present', 'late'))), 0)
            end as total,
            round(
              (case c.metric
                when 'points' then coalesce(sum(coalesce((select sum(da.points_awarded) from public.daily_achievements da
                    where da.student_id = sp.id and da.created_at >= v_from and da.created_at < v_to), 0)
                  + coalesce((select sum(s.points_awarded) from public.serd_sessions s
                    where s.student_id = sp.id and s.status = 'approved' and s.session_date between c.starts_on and c.ends_on), 0)
                  + public._adjustment_points(sp.id, c.starts_on, c.ends_on)), 0)
                when 'recitations' then coalesce(sum((select count(*) from public.daily_achievements da
                    where da.student_id = sp.id and da.created_at >= v_from and da.created_at < v_to)), 0)
                else coalesce(sum((select count(*) from public.attendance a
                    where a.student_id = sp.id and a.session_date between c.starts_on and c.ends_on and a.status in ('present', 'late'))), 0)
              end)::numeric / greatest(count(sp.id), 1), 2) as avg_value
          from public.circles ci
          join public.students_profile sp on sp.circle_id = ci.id and sp.status = 'active'
          where ci.organization_id = p_org
          group by ci.id, ci.name
        ) t
      ) x), '[]'::jsonb));
end;
$$;

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
  -- + each week's attendance / bonus / penalty (0098)
  w := jsonb_set(w, '{points}', to_jsonb((w->>'points')::integer + public._adjustment_points(p_student, v_end - 6, v_end)));
  p := jsonb_set(p, '{points}', to_jsonb((p->>'points')::integer + public._adjustment_points(p_student, v_end - 13, v_end - 7)));

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

create or replace function public.send_weekly_digests(p_force_org uuid default null)
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; v_local timestamp; v_users uuid[]; v_from timestamptz; v_n integer; v_pts integer;
        v_att_ok integer; v_att_all integer; v_body text; v_sent integer := 0; v_smart boolean; r jsonb;
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

      r := null;
      if v_smart then
        r := public._weekly_report(e.id, s.id, v_local::date);
      else
        select count(*), coalesce(sum(points_awarded), 0) into v_n, v_pts
          from public.daily_achievements where student_id = s.id and created_at >= v_from;
        v_pts := v_pts + public._adjustment_points(s.id, v_local::date - 6, v_local::date);
        select count(*) filter (where status::text in ('present', 'late')), count(*) filter (where status::text in ('present', 'late', 'absent'))
          into v_att_ok, v_att_all from public.attendance where student_id = s.id and session_date >= v_local::date - 6;
      end if;
      v_body := public._digest_text('ar', r, v_n, v_pts, v_att_ok, v_att_all);
      perform public._notify(e.id, v_users, 'weekly_digest', 'ملخص أسبوع ' || s.full_name, v_body, s.id,
        jsonb_build_object('اسم_الطالب', s.full_name, 'الملخص', v_body,
          '_i18n', public._i18n_var('الملخص', public._digest_text('en', r, v_n, v_pts, v_att_ok, v_att_all),
                                               public._digest_text('tr', r, v_n, v_pts, v_att_ok, v_att_all),
                                               public._digest_text('fr', r, v_n, v_pts, v_att_ok, v_att_all))), true);
      v_sent := v_sent + 1;
    end loop;
  end loop;
  return v_sent;
end;
$$;

-- ---------------------------------------------------------------------
-- 3. Switching the scoring mode can set the four usual grades to values that suit it
-- ---------------------------------------------------------------------
-- A grade's points mean "per recitation" in one mode and "per page" in the other: 20 for a page
-- is a lot. p_suggest = true sets excellent / very_good / good / acceptable to the spec's values
-- for the new mode (per page 10 / 7 / 5 / 0, per recitation 20 / 15 / 10 / 5) - only when the
-- mode really changes; renamed or extra grades are left alone.
drop function if exists public.set_points_mode(uuid, text);
create or replace function public.set_points_mode(p_org uuid, p_mode text, p_suggest boolean default false)
returns void language plpgsql security definer set search_path = public as $$
declare v_old text;
begin
  perform public._assert_can_write(p_org);
  if not public.is_org_admin(p_org) then raise exception 'للمشرف فقط' using errcode = '42501'; end if;
  if p_mode not in ('per_recitation', 'per_page') then raise exception 'طريقة احتساب غير معروفة'; end if;
  v_old := public.points_mode(p_org);
  insert into public.organization_settings (organization_id, key, value) values (p_org, 'points_mode', p_mode)
  on conflict (organization_id, key) do update set value = excluded.value;
  if p_suggest and v_old <> p_mode then
    update public.recitation_grades g
       set points = case p_mode
                      when 'per_page' then case g.key when 'excellent' then 10 when 'very_good' then 7 when 'good' then 5 else 0 end
                      else case g.key when 'excellent' then 20 when 'very_good' then 15 when 'good' then 10 else 5 end
                    end
     where g.organization_id = p_org and g.key in ('excellent', 'very_good', 'good', 'acceptable');
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'organization_settings', null,
          jsonb_build_object('points_mode', p_mode, 'from', v_old, 'grades_suggested', p_suggest and v_old <> p_mode));
end;
$$;
revoke all on function public.set_points_mode(uuid, text, boolean) from public, anon;
grant execute on function public.set_points_mode(uuid, text, boolean) to authenticated;

notify pgrst, 'reload schema';
