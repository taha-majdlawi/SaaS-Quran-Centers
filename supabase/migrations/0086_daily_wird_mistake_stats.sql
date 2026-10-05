-- =========================================================================
-- 0086_daily_wird_mistake_stats.sql
--
--   * ورد اليوم: what the student should recite today, from their own record:
--       - new memorization: the next ayahs after the last memorized ones,
--         in the direction the student goes (forward, or surah by surah
--         backwards like most children starting from juz 30), as much as the
--         goal's pages per day (half a page without a goal), inside one surah;
--       - review: the teacher-approved portion of the day (0079), or the
--         suggestion when the teacher has not approved one.
--     Each part shows done (recorded today), sent (recorded to the teacher,
--     waiting), or still to do. Families get a reminder in the afternoon of a
--     working day when the student has recited nothing yet.
--   * إحصائيات الأخطاء: where a student keeps slipping - from the teacher's
--     tests in the mushaf and the site's checks of recorded recitations - by
--     ayah, by word and by surah.
-- =========================================================================

-- the center's "today"
create or replace function public._org_today(p_org uuid)
returns date language sql stable security definer set search_path = public as $$
  select (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
$$;

-- the next new-memorization portion, from what was recorded before p_date (null = nothing to go on)
create or replace function public._suggest_new(p_student uuid, p_date date, p_tz text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  l record; p record; v_back boolean; v_surah integer; v_from integer; v_count integer; v_pages numeric;
  v_start_id integer; v_page integer; v_page_first integer; v_next_first integer; v_end_id integer; v_to integer;
begin
  select coalesce(d.surah_to, d.surah_from) as surah, d.surah_from, d.ayah_to into l from public.daily_achievements d
   where d.student_id = p_student and d.achievement_type::text = 'new_memorization' and d.surah_from is not null and d.ayah_to is not null
     and (d.created_at at time zone p_tz)::date < p_date
   order by d.created_at desc limit 1;
  if not found then return null; end if;
  -- the direction: a student whose earlier portion was in a later surah goes backwards (114 -> 78 ...)
  select coalesce(d.surah_to, d.surah_from) as surah into p from public.daily_achievements d
   where d.student_id = p_student and d.achievement_type::text = 'new_memorization' and d.surah_from is not null
     and (d.created_at at time zone p_tz)::date < p_date and coalesce(d.surah_to, d.surah_from) <> l.surah
   order by d.created_at desc limit 1;
  v_back := found and p.surah > l.surah;

  select ayah_count into v_count from public.quran_surahs where number = l.surah;
  if l.ayah_to < v_count then
    v_surah := l.surah; v_from := l.ayah_to + 1;
  else
    v_surah := case when v_back then l.surah - 1 else l.surah + 1 end; v_from := 1;
  end if;
  if v_surah < 1 or v_surah > 114 then return null; end if; -- a khatm: nothing to suggest
  select ayah_count into v_count from public.quran_surahs where number = v_surah;

  -- as much as the goal's pages per day, measured on the mushaf pages; one surah at most
  select pages_per_day into v_pages from public.student_goals where student_id = p_student;
  v_pages := coalesce(v_pages, 0.5);
  v_start_id := public._ayah_id(v_surah, v_from);
  v_page := public._page_of(v_start_id);
  if v_pages >= 1 then
    v_end_id := coalesce((select first_ayah_id from public.quran_pages where page = v_page + ceil(v_pages)::integer), 6237) - 1;
  else
    v_page_first := (select first_ayah_id from public.quran_pages where page = v_page);
    v_next_first := coalesce((select first_ayah_id from public.quran_pages where page = v_page + 1), 6237);
    v_end_id := v_start_id + greatest(1, round((v_next_first - v_page_first) * v_pages)::integer) - 1;
  end if;
  v_to := least(v_count, v_from + greatest(v_end_id - v_start_id, 0));
  return jsonb_build_object('surah', v_surah, 'ayah_from', v_from, 'ayah_to', v_to);
end;
$$;

-- did something recorded today cover [a, b] (global ayah ids)? 'done' (in the record), 'sent' (to the teacher) or null
create or replace function public._wird_state(p_student uuid, p_types text[], p_a integer, p_b integer, p_date date, p_tz text)
returns text language sql stable security definer set search_path = public as $$
  select case
    when exists (select 1 from public.daily_achievements d
                  where d.student_id = p_student and d.achievement_type::text = any (p_types) and d.surah_from is not null
                    and (d.created_at at time zone p_tz)::date = p_date
                    and public._ayah_id(d.surah_from, d.ayah_from) <= p_b
                    and public._ayah_id(coalesce(d.surah_to, d.surah_from), d.ayah_to) >= p_a) then 'done'
    when exists (select 1 from public.recitation_submissions r
                  where r.student_id = p_student and r.status = 'submitted' and r.achievement_type::text = any (p_types)
                    and (r.submitted_at at time zone p_tz)::date = p_date
                    and public._ayah_id(r.surah, r.ayah_from) <= p_b and public._ayah_id(r.surah, r.ayah_to) >= p_a) then 'sent'
  end;
$$;

create or replace function public.student_wird(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_circle uuid; v_tz text; v_date date; v_new jsonb; v_rev jsonb; v_plan public.student_review_plans; v_state text; v_working boolean;
begin
  select circle_id into v_circle from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if not (public.is_org_admin(p_org) or public._is_circle_teacher(v_circle) or p_student = any (public.linked_student_ids(p_org))) then
    raise exception 'غير مصرّح';
  end if;
  v_tz := coalesce((select timezone from public.organizations where id = p_org), 'UTC');
  v_date := (now() at time zone v_tz)::date;
  v_working := public.center_working_days(p_org, v_date, v_date, v_circle) > 0;

  v_new := public._suggest_new(p_student, v_date, v_tz);
  if v_new is not null then
    v_state := public._wird_state(p_student, array['new_memorization'],
      public._ayah_id((v_new->>'surah')::int, (v_new->>'ayah_from')::int), public._ayah_id((v_new->>'surah')::int, (v_new->>'ayah_to')::int), v_date, v_tz);
    v_new := v_new || jsonb_build_object('state', coalesce(v_state, 'todo'));
  end if;

  select * into v_plan from public.student_review_plans where student_id = p_student and plan_date = v_date and status <> 'skipped';
  if found then
    v_rev := jsonb_build_object('surah_from', v_plan.surah_from, 'ayah_from', v_plan.ayah_from, 'surah_to', v_plan.surah_to,
                                'ayah_to', v_plan.ayah_to, 'pages', v_plan.pages, 'approved', true);
  else
    v_rev := public._suggest_review(p_org, p_student, v_date);
    if v_rev is not null then v_rev := v_rev || jsonb_build_object('approved', false); end if;
  end if;
  if v_rev is not null then
    v_state := case when v_plan.status = 'done' then 'done' else public._wird_state(p_student, array['recent_review', 'distant_review'],
      public._ayah_id((v_rev->>'surah_from')::int, (v_rev->>'ayah_from')::int), public._ayah_id((v_rev->>'surah_to')::int, (v_rev->>'ayah_to')::int), v_date, v_tz) end;
    v_rev := v_rev || jsonb_build_object('state', coalesce(v_state, 'todo'));
  end if;

  return jsonb_build_object('date', v_date, 'working_day', v_working, 'new', v_new, 'review', v_rev,
    'complete', (v_new is null or v_new->>'state' <> 'todo') and (v_rev is null or v_rev->>'state' <> 'todo') and (v_new is not null or v_rev is not null));
end;
$$;

-- ---------------------------------------------------------------------
-- the afternoon reminder: a working day, nothing recited or sent yet
-- ---------------------------------------------------------------------
create or replace function public.send_wird_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; st public.notification_settings; v_local timestamp; v_today date; v_new jsonb; v_label text; v_n integer := 0;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    st := public._notif_settings(e.id);
    continue when st.is_paused or not public._notif_event_on(e.id, 'wird_reminder');
    v_local := now() at time zone e.tz;
    v_today := v_local::date;
    -- once, in the afternoon (16:00-16:59 at the center)
    continue when extract(hour from v_local) <> 16;
    for s in
      select sp.id, sp.full_name, sp.circle_id from public.students_profile sp
       where sp.organization_id = e.id and sp.status = 'active' and sp.circle_id is not null
         and public.center_working_days(e.id, v_today, v_today, sp.circle_id) > 0
         and not exists (select 1 from public.daily_achievements d where d.student_id = sp.id and (d.created_at at time zone e.tz)::date = v_today)
         and not exists (select 1 from public.recitation_submissions r where r.student_id = sp.id and r.status <> 'draft' and (r.created_at at time zone e.tz)::date = v_today)
         -- something to recite: a memorization history or today's review portion
         and (exists (select 1 from public.daily_achievements d where d.student_id = sp.id and d.achievement_type::text = 'new_memorization')
              or exists (select 1 from public.student_review_plans p where p.student_id = sp.id and p.plan_date = v_today and p.status = 'approved'))
    loop
      v_new := public._suggest_new(s.id, v_today, e.tz);
      v_label := case when v_new is null then '' else public._surah_range_label((v_new->>'surah')::int, (v_new->>'ayah_from')::int, (v_new->>'ayah_to')::int) end;
      perform public._notify(e.id, public._student_family_users(s.id), 'wird_reminder', 'ورد اليوم بانتظارك', v_label, s.id,
        jsonb_build_object('اسم_الطالب', s.full_name, 'المقطع', v_label), true,
        'wird_reminder|' || s.id::text || '|' || v_today::text);
      v_n := v_n + 1;
    end loop;
  end loop;
  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
-- where the student keeps slipping
-- ---------------------------------------------------------------------
create or replace function public.recitation_mistake_stats(p_org uuid, p_student uuid, p_days integer default 90)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_since timestamptz := now() - make_interval(days => least(greatest(coalesce(p_days, 90), 7), 730));
begin
  if not (p_student = any (public.linked_student_ids(p_org)) or public._can_review_recitation(p_org, p_student)) then
    raise exception 'غير مصرّح';
  end if;
  return (
    with sessions as (
      select r.* from public.recitation_submissions r
       where r.organization_id = p_org and r.student_id = p_student and r.status <> 'draft' and r.created_at >= v_since
    ), m as (
      -- the teacher's marks
      select s.surah, (x->>'ayah')::int as ayah, (x->>'word')::int as word, nullif(x->>'text', '') as text, 'mistake' as kind
        from sessions s cross join lateral jsonb_array_elements(coalesce(s.mistakes, '[]'::jsonb)) x
       where s.kind = 'teacher_test'
      union all
      -- the site's check
      select s.surah, (w->>'a')::int, (w->>'i')::int, null, w->>'s'
        from sessions s cross join lateral jsonb_array_elements(coalesce(s.auto_result->'words', '[]'::jsonb)) w
       where s.kind = 'self' and w->>'s' in ('missing', 'wrong')
    )
    select jsonb_build_object(
      'days', p_days,
      'sessions', (select count(*) from sessions),
      'tests', (select count(*) from sessions where kind = 'teacher_test'),
      'checked', (select count(*) from sessions where kind = 'self' and auto_result ? 'words'),
      'mistakes', (select count(*) from m),
      'by_surah', coalesce((select jsonb_agg(jsonb_build_object('surah', surah, 'count', n) order by n desc, surah)
                              from (select surah, count(*) as n from m group by surah order by n desc limit 10) x), '[]'::jsonb),
      'by_ayah', coalesce((select jsonb_agg(jsonb_build_object('surah', surah, 'ayah', ayah, 'count', n) order by n desc, surah, ayah)
                             from (select surah, ayah, count(*) as n from m group by surah, ayah order by n desc limit 12) x), '[]'::jsonb),
      'by_word', coalesce((select jsonb_agg(jsonb_build_object('surah', surah, 'ayah', ayah, 'word', word, 'text', text, 'count', n) order by n desc)
                             from (select surah, ayah, word, max(text) as text, count(*) as n from m group by surah, ayah, word
                                    order by n desc limit 15) x), '[]'::jsonb))
  );
end;
$$;

do $$
declare f text;
begin
  foreach f in array array['student_wird(uuid, uuid)', 'recitation_mistake_stats(uuid, uuid, integer)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  foreach f in array array['_org_today(uuid)', '_suggest_new(uuid, date, text)', '_wird_state(uuid, text[], integer, integer, date, text)', 'send_wird_reminders()'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;

select cron.schedule('wird-reminders', '20 * * * *', 'select public.send_wird_reminders()');

insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, lead_hours, roles, sort) values
  ('wird_reminder', 'تذكير بورد اليوم', 'ورد اليوم بانتظارك', '{المقطع}', array['اسم_الطالب','المقطع'], null, array['guardian','student'], 262)
on conflict (event_key) do update set name = excluded.name, available_vars = excluded.available_vars, roles = excluded.roles, sort = excluded.sort;
insert into public.notification_default_texts (event_key, lang, title_template, body_template) values
  ('wird_reminder', 'en', 'Today''s portion is waiting', '{المقطع}'),
  ('wird_reminder', 'tr', 'Bugünün virdi seni bekliyor', '{المقطع}'),
  ('wird_reminder', 'fr', 'La portion du jour vous attend', '{المقطع}')
on conflict (event_key, lang) do update set title_template = excluded.title_template, body_template = excluded.body_template;

notify pgrst, 'reload schema';
