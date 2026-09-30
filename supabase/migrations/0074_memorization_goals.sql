-- =====================================================================
-- 0074: memorization goals and the khatm forecast
-- ---------------------------------------------------------------------
-- A teacher (or admin) sets a pace for a student, e.g. one page per working
-- day. The system measures what the student has memorized in mushaf pages
-- (the Madani 604-page mushaf, Hafs), their real pace over the last 4 weeks,
-- whether they are ahead / on track / behind since the goal started, and the
-- day they are expected to finish the Quran (or the goal's target) - both at
-- their real pace and at the goal's pace.
--
-- What counts as memorized: every ayah covered by a "new memorization"
-- recitation, plus the juz the student is recorded as having saved
-- (students_profile.saved_parts_numbers; when only total_parts_count is known,
-- the last juz, counting back from juz 30). Partly covered pages count by
-- the share of their ayahs.
--
-- Reference data (surah / page / juz starts as global ayah numbers 1..6236)
-- comes from quran-meta (MIT, https://github.com/quran-center/quran-meta).
-- =====================================================================

create table if not exists public.quran_surahs (
  number        smallint primary key check (number between 1 and 114),
  first_ayah_id integer not null,
  ayah_count    smallint not null
);
create table if not exists public.quran_pages (
  page          smallint primary key check (page between 1 and 604),
  first_ayah_id integer not null unique
);
create table if not exists public.quran_juz_starts (
  juz           smallint primary key check (juz between 1 and 30),
  first_ayah_id integer not null
);
alter table public.quran_surahs enable row level security;
alter table public.quran_pages enable row level security;
alter table public.quran_juz_starts enable row level security;
revoke all on public.quran_surahs, public.quran_pages, public.quran_juz_starts from anon, authenticated;

insert into public.quran_surahs (number, first_ayah_id, ayah_count) values
  (1,1,7),(2,8,286),(3,294,200),(4,494,176),(5,670,120),(6,790,165),(7,955,206),(8,1161,75),
  (9,1236,129),(10,1365,109),(11,1474,123),(12,1597,111),(13,1708,43),(14,1751,52),(15,1803,99),(16,1902,128),
  (17,2030,111),(18,2141,110),(19,2251,98),(20,2349,135),(21,2484,112),(22,2596,78),(23,2674,118),(24,2792,64),
  (25,2856,77),(26,2933,227),(27,3160,93),(28,3253,88),(29,3341,69),(30,3410,60),(31,3470,34),(32,3504,30),
  (33,3534,73),(34,3607,54),(35,3661,45),(36,3706,83),(37,3789,182),(38,3971,88),(39,4059,75),(40,4134,85),
  (41,4219,54),(42,4273,53),(43,4326,89),(44,4415,59),(45,4474,37),(46,4511,35),(47,4546,38),(48,4584,29),
  (49,4613,18),(50,4631,45),(51,4676,60),(52,4736,49),(53,4785,62),(54,4847,55),(55,4902,78),(56,4980,96),
  (57,5076,29),(58,5105,22),(59,5127,24),(60,5151,13),(61,5164,14),(62,5178,11),(63,5189,11),(64,5200,18),
  (65,5218,12),(66,5230,12),(67,5242,30),(68,5272,52),(69,5324,52),(70,5376,44),(71,5420,28),(72,5448,28),
  (73,5476,20),(74,5496,56),(75,5552,40),(76,5592,31),(77,5623,50),(78,5673,40),(79,5713,46),(80,5759,42),
  (81,5801,29),(82,5830,19),(83,5849,36),(84,5885,25),(85,5910,22),(86,5932,17),(87,5949,19),(88,5968,26),
  (89,5994,30),(90,6024,20),(91,6044,15),(92,6059,21),(93,6080,11),(94,6091,8),(95,6099,8),(96,6107,19),
  (97,6126,5),(98,6131,8),(99,6139,8),(100,6147,11),(101,6158,11),(102,6169,8),(103,6177,3),(104,6180,9),
  (105,6189,5),(106,6194,4),(107,6198,7),(108,6205,3),(109,6208,6),(110,6214,3),(111,6217,5),(112,6222,4),
  (113,6226,5),(114,6231,6)
on conflict (number) do nothing;

insert into public.quran_pages (page, first_ayah_id) values
  (1,1),(2,8),(3,13),(4,24),(5,32),(6,37),(7,45),(8,56),(9,65),(10,69),(11,77),(12,84),
  (13,91),(14,96),(15,101),(16,109),(17,113),(18,120),(19,127),(20,134),(21,142),(22,149),(23,153),(24,161),
  (25,171),(26,177),(27,184),(28,189),(29,194),(30,198),(31,204),(32,210),(33,218),(34,223),(35,227),(36,232),
  (37,238),(38,241),(39,245),(40,253),(41,256),(42,260),(43,264),(44,267),(45,272),(46,277),(47,282),(48,289),
  (49,290),(50,294),(51,303),(52,309),(53,316),(54,323),(55,331),(56,339),(57,346),(58,355),(59,364),(60,371),
  (61,377),(62,385),(63,394),(64,402),(65,409),(66,415),(67,426),(68,434),(69,442),(70,447),(71,451),(72,459),
  (73,467),(74,474),(75,480),(76,488),(77,494),(78,500),(79,505),(80,508),(81,513),(82,517),(83,520),(84,527),
  (85,531),(86,538),(87,545),(88,553),(89,559),(90,568),(91,573),(92,580),(93,585),(94,588),(95,595),(96,599),
  (97,607),(98,615),(99,621),(100,628),(101,634),(102,641),(103,648),(104,656),(105,664),(106,669),(107,672),(108,675),
  (109,679),(110,683),(111,687),(112,693),(113,701),(114,706),(115,711),(116,715),(117,720),(118,727),(119,734),(120,740),
  (121,746),(122,752),(123,759),(124,765),(125,773),(126,778),(127,783),(128,790),(129,798),(130,808),(131,817),(132,825),
  (133,834),(134,842),(135,849),(136,858),(137,863),(138,871),(139,880),(140,884),(141,891),(142,900),(143,908),(144,914),
  (145,921),(146,927),(147,932),(148,936),(149,941),(150,947),(151,955),(152,966),(153,977),(154,985),(155,992),(156,998),
  (157,1006),(158,1012),(159,1022),(160,1028),(161,1036),(162,1042),(163,1050),(164,1059),(165,1075),(166,1085),(167,1092),(168,1098),
  (169,1104),(170,1110),(171,1114),(172,1118),(173,1125),(174,1133),(175,1142),(176,1150),(177,1161),(178,1169),(179,1177),(180,1186),
  (181,1194),(182,1201),(183,1206),(184,1213),(185,1222),(186,1230),(187,1236),(188,1242),(189,1249),(190,1256),(191,1262),(192,1267),
  (193,1272),(194,1276),(195,1283),(196,1290),(197,1297),(198,1304),(199,1308),(200,1315),(201,1322),(202,1329),(203,1335),(204,1342),
  (205,1347),(206,1353),(207,1358),(208,1365),(209,1371),(210,1379),(211,1385),(212,1390),(213,1398),(214,1407),(215,1418),(216,1426),
  (217,1435),(218,1443),(219,1453),(220,1462),(221,1471),(222,1479),(223,1486),(224,1493),(225,1502),(226,1511),(227,1519),(228,1527),
  (229,1536),(230,1545),(231,1555),(232,1562),(233,1571),(234,1582),(235,1591),(236,1601),(237,1611),(238,1619),(239,1627),(240,1634),
  (241,1640),(242,1649),(243,1660),(244,1666),(245,1675),(246,1683),(247,1692),(248,1700),(249,1708),(250,1713),(251,1721),(252,1726),
  (253,1736),(254,1742),(255,1750),(256,1756),(257,1761),(258,1769),(259,1775),(260,1784),(261,1793),(262,1803),(263,1818),(264,1834),
  (265,1854),(266,1873),(267,1893),(268,1908),(269,1916),(270,1928),(271,1936),(272,1944),(273,1956),(274,1966),(275,1974),(276,1981),
  (277,1989),(278,1995),(279,2004),(280,2012),(281,2020),(282,2030),(283,2037),(284,2047),(285,2057),(286,2068),(287,2079),(288,2088),
  (289,2096),(290,2105),(291,2116),(292,2126),(293,2134),(294,2145),(295,2156),(296,2161),(297,2168),(298,2175),(299,2186),(300,2194),
  (301,2202),(302,2215),(303,2224),(304,2238),(305,2251),(306,2262),(307,2276),(308,2289),(309,2302),(310,2315),(311,2327),(312,2346),
  (313,2361),(314,2386),(315,2400),(316,2413),(317,2425),(318,2436),(319,2447),(320,2462),(321,2474),(322,2484),(323,2494),(324,2508),
  (325,2519),(326,2528),(327,2541),(328,2556),(329,2565),(330,2574),(331,2585),(332,2596),(333,2601),(334,2611),(335,2619),(336,2626),
  (337,2634),(338,2642),(339,2651),(340,2660),(341,2668),(342,2674),(343,2691),(344,2701),(345,2716),(346,2733),(347,2748),(348,2763),
  (349,2778),(350,2792),(351,2802),(352,2812),(353,2819),(354,2823),(355,2828),(356,2835),(357,2845),(358,2850),(359,2853),(360,2858),
  (361,2867),(362,2876),(363,2888),(364,2899),(365,2911),(366,2923),(367,2933),(368,2952),(369,2972),(370,2993),(371,3016),(372,3044),
  (373,3069),(374,3092),(375,3116),(376,3139),(377,3160),(378,3173),(379,3182),(380,3195),(381,3204),(382,3215),(383,3223),(384,3236),
  (385,3248),(386,3258),(387,3266),(388,3274),(389,3281),(390,3288),(391,3296),(392,3303),(393,3312),(394,3323),(395,3330),(396,3337),
  (397,3347),(398,3355),(399,3364),(400,3371),(401,3379),(402,3386),(403,3393),(404,3404),(405,3415),(406,3425),(407,3434),(408,3442),
  (409,3451),(410,3460),(411,3470),(412,3481),(413,3489),(414,3498),(415,3504),(416,3515),(417,3524),(418,3534),(419,3540),(420,3549),
  (421,3556),(422,3564),(423,3569),(424,3577),(425,3584),(426,3588),(427,3596),(428,3607),(429,3614),(430,3621),(431,3629),(432,3638),
  (433,3646),(434,3655),(435,3664),(436,3672),(437,3679),(438,3691),(439,3699),(440,3705),(441,3718),(442,3733),(443,3746),(444,3760),
  (445,3776),(446,3789),(447,3813),(448,3840),(449,3865),(450,3891),(451,3915),(452,3942),(453,3971),(454,3987),(455,3997),(456,4013),
  (457,4032),(458,4054),(459,4064),(460,4069),(461,4080),(462,4090),(463,4099),(464,4106),(465,4115),(466,4126),(467,4133),(468,4141),
  (469,4150),(470,4159),(471,4167),(472,4174),(473,4183),(474,4192),(475,4200),(476,4211),(477,4219),(478,4230),(479,4239),(480,4248),
  (481,4257),(482,4265),(483,4273),(484,4283),(485,4288),(486,4295),(487,4304),(488,4317),(489,4324),(490,4336),(491,4348),(492,4359),
  (493,4373),(494,4386),(495,4399),(496,4415),(497,4433),(498,4454),(499,4474),(500,4487),(501,4496),(502,4506),(503,4516),(504,4525),
  (505,4531),(506,4539),(507,4546),(508,4557),(509,4565),(510,4575),(511,4584),(512,4593),(513,4599),(514,4607),(515,4612),(516,4617),
  (517,4624),(518,4631),(519,4646),(520,4666),(521,4682),(522,4706),(523,4727),(524,4750),(525,4767),(526,4785),(527,4811),(528,4829),
  (529,4853),(530,4874),(531,4896),(532,4918),(533,4942),(534,4969),(535,4996),(536,5030),(537,5056),(538,5079),(539,5087),(540,5094),
  (541,5100),(542,5105),(543,5111),(544,5116),(545,5126),(546,5130),(547,5136),(548,5143),(549,5151),(550,5156),(551,5162),(552,5169),
  (553,5178),(554,5186),(555,5193),(556,5200),(557,5209),(558,5218),(559,5223),(560,5230),(561,5237),(562,5242),(563,5254),(564,5268),
  (565,5287),(566,5314),(567,5332),(568,5358),(569,5386),(570,5415),(571,5430),(572,5448),(573,5461),(574,5476),(575,5495),(576,5513),
  (577,5543),(578,5571),(579,5597),(580,5617),(581,5642),(582,5673),(583,5703),(584,5728),(585,5759),(586,5801),(587,5830),(588,5855),
  (589,5883),(590,5910),(591,5932),(592,5964),(593,5994),(594,6017),(595,6044),(596,6073),(597,6099),(598,6126),(599,6138),(600,6156),
  (601,6177),(602,6194),(603,6208),(604,6222)
on conflict (page) do nothing;

insert into public.quran_juz_starts (juz, first_ayah_id) values
  (1,1),(2,149),(3,260),(4,386),(5,517),(6,641),(7,751),(8,900),(9,1042),(10,1201),
  (11,1328),(12,1479),(13,1649),(14,1803),(15,2030),(16,2215),(17,2484),(18,2674),(19,2876),(20,3215),
  (21,3386),(22,3564),(23,3733),(24,4090),(25,4265),(26,4511),(27,4706),(28,5105),(29,5242),(30,5673)
on conflict (juz) do nothing;

-- global ayah number (1..6236) of surah:ayah; null when out of range
create or replace function public._ayah_id(p_surah integer, p_ayah integer)
returns integer language sql immutable set search_path = public as $$
  select s.first_ayah_id + p_ayah - 1 from public.quran_surahs s
   where s.number = p_surah and p_ayah between 1 and s.ayah_count;
$$;

-- every ayah (global numbers) this student has memorized
create or replace function public._memorized_ayahs(p_student uuid, p_since timestamptz default null)
returns setof integer language sql stable security definer set search_path = public as $$
  select distinct a from (
    select generate_series(public._ayah_id(d.surah_from, d.ayah_from),
                           public._ayah_id(coalesce(d.surah_to, d.surah_from), d.ayah_to)) as a
      from public.daily_achievements d
     where d.student_id = p_student and d.achievement_type::text = 'new_memorization'
       and d.surah_from is not null and d.ayah_from is not null and d.ayah_to is not null
       and (p_since is null or d.created_at >= p_since)
    union all
    select generate_series(j.first_ayah_id, coalesce((select n.first_ayah_id from public.quran_juz_starts n where n.juz = j.juz + 1), 6237) - 1)
      from public.students_profile sp
      -- the juz recorded as saved; when only their count is known, the last ones (how most centers start: juz 30 backwards)
      cross join lateral unnest(case when coalesce(cardinality(sp.saved_parts_numbers), 0) > 0 then sp.saved_parts_numbers
                                     when coalesce(sp.total_parts_count, 0) > 0 then array(select generate_series(31 - least(sp.total_parts_count, 30), 30))
                                     else '{}'::integer[] end) pj
      join public.quran_juz_starts j on j.juz = pj
     where sp.id = p_student and p_since is null
  ) x where a is not null;
$$;

-- a set of ayahs measured in mushaf pages (a page counts by the share of its ayahs)
create or replace function public._ayahs_as_pages(p_ayahs integer[])
returns numeric language sql immutable set search_path = public as $$
  with pg as (
    select p.page, p.first_ayah_id as a0,
           coalesce(lead(p.first_ayah_id) over (order by p.page), 6237) - p.first_ayah_id as n
      from public.quran_pages p)
  select coalesce(round(sum(cnt::numeric / pg.n), 2), 0)
    from (select (select max(page) from public.quran_pages q where q.first_ayah_id <= a) as page, count(*) as cnt
            from unnest(p_ayahs) a group by 1) c
    join pg on pg.page = c.page;
$$;

create table if not exists public.student_goals (
  student_id      uuid primary key references public.students_profile (id) on delete cascade,
  organization_id uuid not null references public.organizations (id) on delete cascade,
  pages_per_day   numeric(4,2) not null check (pages_per_day > 0 and pages_per_day <= 20),
  target_pages    integer not null default 604 check (target_pages between 1 and 604),
  start_date      date not null default current_date,
  note            text check (note is null or length(note) <= 300),
  set_by          uuid references auth.users (id) on delete set null,
  updated_at      timestamptz not null default now()
);
create index if not exists student_goals_org_idx on public.student_goals (organization_id);
alter table public.student_goals enable row level security;
revoke all on public.student_goals from anon, authenticated;
drop trigger if exists a_deny_readonly_write on public.student_goals;
create trigger a_deny_readonly_write before insert or update or delete on public.student_goals
  for each row execute function public._deny_readonly_write();

create or replace function public._can_manage_student(p_org uuid, p_student uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_org_admin(p_org) or exists (
    select 1 from public.students_profile s where s.id = p_student and s.organization_id = p_org and public._is_circle_teacher(s.circle_id));
$$;

create or replace function public.set_student_goal(p_org uuid, p_student uuid, p_pages_per_day numeric,
  p_target_pages integer default 604, p_start_date date default null, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_can_write(p_org);
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then raise exception 'الطالب غير موجود'; end if;
  if not public._can_manage_student(p_org, p_student) then raise exception 'تحديد الهدف لمعلم الطالب أو المشرف'; end if;
  if p_pages_per_day is null or p_pages_per_day <= 0 or p_pages_per_day > 20 then raise exception 'المقدار اليومي بين 0.1 و20 صفحة'; end if;
  if p_target_pages is not null and (p_target_pages < 1 or p_target_pages > 604) then raise exception 'الهدف بين 1 و604 صفحات'; end if;
  insert into public.student_goals (student_id, organization_id, pages_per_day, target_pages, start_date, note, set_by, updated_at)
  values (p_student, p_org, round(p_pages_per_day, 2), coalesce(p_target_pages, 604), coalesce(p_start_date, current_date),
          nullif(btrim(coalesce(p_note, '')), ''), auth.uid(), now())
  on conflict (student_id) do update set pages_per_day = excluded.pages_per_day, target_pages = excluded.target_pages,
    start_date = coalesce(p_start_date, public.student_goals.start_date), note = excluded.note, set_by = excluded.set_by, updated_at = now();
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'student_goals', p_student, jsonb_build_object('pages_per_day', p_pages_per_day, 'target_pages', p_target_pages));
end;
$$;

create or replace function public.clear_student_goal(p_org uuid, p_student uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._assert_can_write(p_org);
  if not public._can_manage_student(p_org, p_student) then raise exception 'تحديد الهدف لمعلم الطالب أو المشرف'; end if;
  delete from public.student_goals where student_id = p_student and organization_id = p_org;
end;
$$;

-- where the student stands, and when they will finish
create or replace function public.student_goal_progress(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s public.students_profile%rowtype; g public.student_goals%rowtype; v_tz text; v_today date;
  v_all integer[]; v_total numeric; v_recent numeric; v_since_start numeric; v_wd_recent integer; v_wd_since integer;
  v_pace numeric; v_expected numeric; v_target integer; v_remaining numeric; v_ratio numeric; v_status text;
  v_forecast date; v_goal_date date;
begin
  select * into s from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if not (public.is_org_admin(p_org) or public.member_has_module(p_org, 'reports') or public._is_circle_teacher(s.circle_id)
          or p_student = any (public.linked_student_ids(p_org))) then
    raise exception 'غير مصرّح';
  end if;
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

do $$
declare f text;
begin
  foreach f in array array['set_student_goal(uuid, uuid, numeric, integer, date, text)', 'clear_student_goal(uuid, uuid)',
                           'student_goal_progress(uuid, uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  foreach f in array array['_memorized_ayahs(uuid, timestamptz)', '_can_manage_student(uuid, uuid)', '_ayah_id(integer, integer)', '_ayahs_as_pages(integer[])'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
