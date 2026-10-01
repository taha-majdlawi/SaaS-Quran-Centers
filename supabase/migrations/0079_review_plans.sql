-- =====================================================================
-- 0079: the daily review portion, tied to the memorization goal
-- ---------------------------------------------------------------------
-- Every day the system suggests each student's review portion: the next N
-- memorized pages in mushaf order, continuing where the last approved
-- portion stopped and starting over after the end (the classic cyclic
-- review). N is the goal's review_pages_per_day, or - when not set - enough
-- to go over everything memorized in about 20 working days (1..20 pages).
--
-- The teacher approves a suggestion with one tap (or a whole circle at
-- once); the student and the family then see it, and it is marked done when
-- a review recitation covering it is recorded that day.
-- =====================================================================

alter table public.student_goals
  add column if not exists review_pages_per_day numeric(4,1) check (review_pages_per_day is null or (review_pages_per_day > 0 and review_pages_per_day <= 40));

create table if not exists public.student_review_plans (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  student_id      uuid not null references public.students_profile (id) on delete cascade,
  plan_date       date not null,
  page_from       smallint not null,
  page_to         smallint not null,
  surah_from      smallint not null,
  ayah_from       smallint not null,
  surah_to        smallint not null,
  ayah_to         smallint not null,
  pages           numeric(5,1) not null,
  status          text not null default 'approved' check (status in ('approved', 'done', 'skipped')),
  approved_by     uuid references auth.users (id) on delete set null,
  approved_at     timestamptz not null default now(),
  done_at         timestamptz,
  unique (student_id, plan_date)
);
create index if not exists student_review_plans_org_date_idx on public.student_review_plans (organization_id, plan_date);
alter table public.student_review_plans enable row level security;
revoke all on public.student_review_plans from anon, authenticated;
drop trigger if exists a_deny_readonly_write on public.student_review_plans;
create trigger a_deny_readonly_write before insert or update or delete on public.student_review_plans
  for each row execute function public._deny_readonly_write();

-- surah:ayah of a global ayah number
create or replace function public._ayah_ref(p_id integer)
returns table (surah smallint, ayah smallint) language sql immutable set search_path = public as $$
  select s.number, (p_id - s.first_ayah_id + 1)::smallint from public.quran_surahs s
   where p_id between s.first_ayah_id and s.first_ayah_id + s.ayah_count - 1;
$$;

create or replace function public._page_of(p_ayah integer)
returns smallint language sql stable set search_path = public as $$
  select max(page) from public.quran_pages where first_ayah_id <= p_ayah;
$$;

-- today's suggestion for one student (null when nothing is memorized)
create or replace function public._suggest_review(p_org uuid, p_student uuid, p_date date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_pages smallint[]; v_n numeric; v_count integer; v_after smallint; v_start integer; v_take integer; v_sel smallint[];
  v_first integer; v_last integer; a record; b record;
begin
  -- pages at least half memorized, in mushaf order
  with sizes as (
    select page, coalesce(lead(first_ayah_id) over (order by page), 6237) - first_ayah_id as size from public.quran_pages
  ), mine as (
    select public._page_of(m) as page, count(*) as n from public._memorized_ayahs(p_student) m group by 1
  )
  select array_agg(mine.page order by mine.page) into v_pages from mine join sizes using (page) where mine.n * 2 >= sizes.size;
  if v_pages is null or cardinality(v_pages) = 0 then return null; end if;
  v_count := cardinality(v_pages);

  -- the goal's amount, else everything once in about 20 working days
  select review_pages_per_day into v_n from public.student_goals where student_id = p_student;
  v_take := least(greatest(coalesce(round(v_n)::integer, ceil(v_count / 20.0)::integer), 1), 20, v_count);

  -- continue after the last approved portion before this day
  select page_to into v_after from public.student_review_plans
   where student_id = p_student and plan_date < p_date order by plan_date desc limit 1;
  v_start := coalesce((select min(i) from generate_subscripts(v_pages, 1) i where v_pages[i] > coalesce(v_after, 0)), 1);
  -- a portion does not wrap: at the end it stops, and the next one starts over
  v_sel := v_pages[v_start : least(v_start + v_take - 1, v_count)];

  v_first := (select min(m) from public._memorized_ayahs(p_student) m where public._page_of(m) = v_sel[1]);
  v_last := (select max(m) from public._memorized_ayahs(p_student) m where public._page_of(m) = v_sel[cardinality(v_sel)]);
  select * into a from public._ayah_ref(v_first);
  select * into b from public._ayah_ref(v_last);
  return jsonb_build_object('page_from', v_sel[1], 'page_to', v_sel[cardinality(v_sel)], 'pages', cardinality(v_sel),
    'surah_from', a.surah, 'ayah_from', a.ayah, 'surah_to', b.surah, 'ayah_to', b.ayah,
    'memorized_pages', v_count, 'cycle_start', v_start = 1);
end;
$$;

-- the teacher's list for a day: each student's approved portion or the suggestion
create or replace function public.review_plans_today(p_org uuid, p_circle uuid default null, p_date date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_admin boolean := public.is_org_admin(p_org); v_date date; s record; v_plan jsonb; v_out jsonb := '[]'::jsonb;
begin
  if not (v_admin or public.is_org_staff(p_org)) then raise exception 'غير مصرّح'; end if;
  v_date := coalesce(p_date, (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date);
  for s in
    select sp.id, sp.full_name, sp.circle_id, c.name as circle_name from public.students_profile sp
      join public.circles c on c.id = sp.circle_id
     where sp.organization_id = p_org and sp.status = 'active' and (p_circle is null or sp.circle_id = p_circle)
       and (v_admin or public._is_circle_teacher(sp.circle_id))
     order by c.name, sp.full_name
  loop
    select to_jsonb(r) - 'organization_id' - 'student_id' || jsonb_build_object('approved', true) into v_plan
      from public.student_review_plans r where r.student_id = s.id and r.plan_date = v_date;
    if v_plan is null then
      v_plan := public._suggest_review(p_org, s.id, v_date);
      if v_plan is not null then v_plan := v_plan || jsonb_build_object('approved', false, 'status', 'suggested'); end if;
    end if;
    continue when v_plan is null;
    v_out := v_out || jsonb_build_object('student_id', s.id, 'name', s.full_name, 'circle_id', s.circle_id, 'circle', s.circle_name, 'plan', v_plan);
  end loop;
  return v_out;
end;
$$;

-- approve one student's portion (the suggestion unless a range is given); idempotent
create or replace function public.approve_review_plan(p_org uuid, p_student uuid, p_date date default null,
  p_page_from integer default null, p_page_to integer default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_date date; v jsonb; v_first integer; v_last integer; a record; b record; v_row public.student_review_plans%rowtype;
begin
  perform public._assert_can_write(p_org);
  if not public._can_manage_student(p_org, p_student) then raise exception 'اعتماد المراجعة لمعلم الطالب أو المشرف'; end if;
  v_date := coalesce(p_date, (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date);
  if p_page_from is not null and p_page_to is not null then
    if p_page_from < 1 or p_page_to > 604 or p_page_to < p_page_from then raise exception 'نطاق صفحات غير صحيح'; end if;
    v_first := (select first_ayah_id from public.quran_pages where page = p_page_from);
    v_last := coalesce((select first_ayah_id from public.quran_pages where page = p_page_to + 1), 6237) - 1;
    select * into a from public._ayah_ref(v_first);
    select * into b from public._ayah_ref(v_last);
    v := jsonb_build_object('page_from', p_page_from, 'page_to', p_page_to, 'pages', p_page_to - p_page_from + 1,
                            'surah_from', a.surah, 'ayah_from', a.ayah, 'surah_to', b.surah, 'ayah_to', b.ayah);
  else
    v := public._suggest_review(p_org, p_student, v_date);
    if v is null then raise exception 'لا محفوظ لهذا الطالب بعد'; end if;
  end if;
  insert into public.student_review_plans (organization_id, student_id, plan_date, page_from, page_to, surah_from, ayah_from, surah_to, ayah_to, pages, approved_by)
  values (p_org, p_student, v_date, (v->>'page_from')::int, (v->>'page_to')::int, (v->>'surah_from')::int, (v->>'ayah_from')::int,
          (v->>'surah_to')::int, (v->>'ayah_to')::int, (v->>'pages')::numeric, auth.uid())
  on conflict (student_id, plan_date) do update set
    page_from = excluded.page_from, page_to = excluded.page_to, surah_from = excluded.surah_from, ayah_from = excluded.ayah_from,
    surah_to = excluded.surah_to, ayah_to = excluded.ayah_to, pages = excluded.pages,
    approved_by = excluded.approved_by, approved_at = now()
    where public.student_review_plans.status <> 'done'
  returning * into v_row;
  return to_jsonb(v_row);
end;
$$;

-- approve every suggestion of a circle (or of all my circles) for the day
create or replace function public.approve_review_plans(p_org uuid, p_circle uuid default null, p_date date default null)
returns integer language plpgsql security definer set search_path = public as $$
declare r jsonb; n integer := 0;
begin
  perform public._assert_can_write(p_org);
  for r in select x from jsonb_array_elements(public.review_plans_today(p_org, p_circle, p_date)) x loop
    continue when (r->'plan'->>'approved')::boolean;
    perform public.approve_review_plan(p_org, (r->>'student_id')::uuid, p_date);
    n := n + 1;
  end loop;
  return n;
end;
$$;

create or replace function public.skip_review_plan(p_org uuid, p_student uuid, p_date date default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_can_write(p_org);
  if not public._can_manage_student(p_org, p_student) then raise exception 'اعتماد المراجعة لمعلم الطالب أو المشرف'; end if;
  delete from public.student_review_plans
   where student_id = p_student and status = 'approved'
     and plan_date = coalesce(p_date, (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date);
end;
$$;

-- what the student / family sees: today's approved portion (and whether it is done)
create or replace function public.my_review_plan(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_circle uuid; v_date date;
begin
  select circle_id into v_circle from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if not (public.is_org_admin(p_org) or public._is_circle_teacher(v_circle) or p_student = any (public.linked_student_ids(p_org))) then
    raise exception 'غير مصرّح';
  end if;
  v_date := (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
  return (select to_jsonb(r) - 'organization_id' from public.student_review_plans r
           where r.student_id = p_student and r.plan_date <= v_date order by r.plan_date desc limit 1);
end;
$$;

-- a review recitation that covers the day's portion marks it done
create or replace function public.trg_review_plan_done()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_tz text; v_day date;
begin
  if new.achievement_type::text not in ('recent_review', 'distant_review') or new.surah_from is null then return new; end if;
  v_tz := coalesce((select timezone from public.organizations where id = new.organization_id), 'UTC');
  v_day := (new.created_at at time zone v_tz)::date;
  update public.student_review_plans p set status = 'done', done_at = now()
   where p.student_id = new.student_id and p.plan_date = v_day and p.status = 'approved'
     -- the recitation overlaps the portion
     and public._ayah_id(new.surah_from, new.ayah_from) <= public._ayah_id(p.surah_to, p.ayah_to)
     and public._ayah_id(coalesce(new.surah_to, new.surah_from), new.ayah_to) >= public._ayah_id(p.surah_from, p.ayah_from);
  return new;
end;
$$;
drop trigger if exists trg_review_plan_done on public.daily_achievements;
create trigger trg_review_plan_done after insert on public.daily_achievements
  for each row execute function public.trg_review_plan_done();

-- the review amount on the goal
drop function if exists public.set_student_goal(uuid, uuid, numeric, integer, date, text);
create or replace function public.set_student_goal(p_org uuid, p_student uuid, p_pages_per_day numeric,
  p_target_pages integer default 604, p_start_date date default null, p_note text default null, p_review_pages numeric default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_can_write(p_org);
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then raise exception 'الطالب غير موجود'; end if;
  if not public._can_manage_student(p_org, p_student) then raise exception 'تحديد الهدف لمعلم الطالب أو المشرف'; end if;
  if p_pages_per_day is null or p_pages_per_day <= 0 or p_pages_per_day > 20 then raise exception 'المقدار اليومي بين 0.1 و20 صفحة'; end if;
  if p_target_pages is not null and (p_target_pages < 1 or p_target_pages > 604) then raise exception 'الهدف بين 1 و604 صفحات'; end if;
  if p_review_pages is not null and (p_review_pages <= 0 or p_review_pages > 40) then raise exception 'المراجعة اليومية بين 1 و40 صفحة'; end if;
  insert into public.student_goals (student_id, organization_id, pages_per_day, target_pages, start_date, note, review_pages_per_day, set_by, updated_at)
  values (p_student, p_org, round(p_pages_per_day, 2), coalesce(p_target_pages, 604), coalesce(p_start_date, current_date),
          nullif(btrim(coalesce(p_note, '')), ''), p_review_pages, auth.uid(), now())
  on conflict (student_id) do update set pages_per_day = excluded.pages_per_day, target_pages = excluded.target_pages,
    start_date = coalesce(p_start_date, public.student_goals.start_date), note = excluded.note,
    review_pages_per_day = excluded.review_pages_per_day, set_by = excluded.set_by, updated_at = now();
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'student_goals', p_student, jsonb_build_object('pages_per_day', p_pages_per_day, 'target_pages', p_target_pages, 'review_pages', p_review_pages));
end;
$$;

-- the goal now carries its review amount (for the edit forms)
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
    'goal_date', v_goal_date,
    'can_edit', public._can_manage_student(p_org, p_student));
end;
$$;

do $$
declare f text;
begin
  foreach f in array array['review_plans_today(uuid, uuid, date)', 'approve_review_plan(uuid, uuid, date, integer, integer)',
                           'approve_review_plans(uuid, uuid, date)', 'skip_review_plan(uuid, uuid, date)', 'my_review_plan(uuid, uuid)',
                           'set_student_goal(uuid, uuid, numeric, integer, date, text, numeric)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  foreach f in array array['_ayah_ref(integer)', '_page_of(integer)', '_suggest_review(uuid, uuid, date)', 'trg_review_plan_done()'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
