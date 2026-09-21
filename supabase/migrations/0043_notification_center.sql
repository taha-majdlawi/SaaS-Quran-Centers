-- =========================================================================
-- 0043_notification_center.sql
-- The notification centre (modelled on the eqraa admin panel, per center):
--   * a catalogue of notification types with default wording, and per-center
--     overrides (title / body / audience / lead time / on-off) = "templates"
--   * per-center delivery settings: quiet hours, day start, late grace, idle
--     days, pause
--   * delivery log on every inbox row (sent / failed / no device / queued /
--     skipped) and queued-for-morning pushes during quiet hours
--   * student idle reminders, upcoming schedule, manual broadcast, devices
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. template rendering + small helpers
-- ---------------------------------------------------------------------
create or replace function public.notification_render(p_template text, p_vars jsonb)
returns text language plpgsql immutable as $$
declare v_out text := coalesce(p_template, ''); r record;
begin
  for r in select key, coalesce(value, '') as value from jsonb_each_text(coalesce(p_vars, '{}'::jsonb)) loop
    v_out := replace(v_out, '{' || r.key || '}', r.value);
  end loop;
  v_out := regexp_replace(v_out, '\{[^{}]*\}', '', 'g');                       -- unknown / empty variables vanish
  v_out := regexp_replace(v_out, '\s+', ' ', 'g');
  v_out := regexp_replace(v_out, '\s*[—·]\s*(?:[—·]\s*)+', ' — ', 'g');         -- separators left dangling by a missing value
  v_out := btrim(v_out, ' —·،-');
  return v_out;
end;
$$;

create or replace function public._notif_date_label(p_org uuid, p_date date)
returns text language sql stable security definer set search_path = public as $$
  select case
    when p_date = (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date then 'اليوم'
    when p_date = (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date + 1 then 'غدًا'
    else (array['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'])[extract(dow from p_date)::integer + 1] || ' ' || to_char(p_date, 'DD/MM')
  end;
$$;

-- ---------------------------------------------------------------------
-- 2. catalogue (defaults) + per-center templates + per-center settings
-- ---------------------------------------------------------------------
create table if not exists public.notification_defaults (
  event_key        text primary key,
  name             text not null,
  title_template   text not null,
  body_template    text not null,
  available_vars   text[] not null default '{}',
  lead_hours       integer,                       -- only for types that fire ahead of an event
  default_audience text not null default 'source',
  roles            text[] not null default array['admin', 'teacher', 'guardian', 'student'],   -- who can receive it (drives the person's own switches)
  sort             integer not null default 0
);
alter table public.notification_defaults enable row level security;
revoke all on public.notification_defaults from anon, authenticated;

insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, lead_hours, roles, sort) values
  ('announcement',       'إعلان جديد',                 '{العنوان}',                          '{الوصف}',                            array['العنوان','الوصف'], null, array['admin','teacher','guardian','student'], 10),
  ('calendar_entry',     'فعالية جديدة في التقويم',   'جديد في التقويم: {العنوان}',         '{التاريخ} {الوقت} · {الموقع}',        array['العنوان','التاريخ','الوقت','الموقع','الوصف'], null, array['admin','teacher','guardian','student'], 20),
  ('center_closed',      'إجازة أو إغلاق',             'إجازة / إغلاق: {العنوان}',           '{التاريخ}',                          array['العنوان','التاريخ','الوصف'], null, array['admin','teacher','guardian','student'], 30),
  ('event_reminder',     'تذكير بالفعاليات',           'تذكير: {العنوان}',                   '{التاريخ} {الوقت} · {الموقع}',        array['العنوان','التاريخ','الوقت','الموقع'], 24, array['guardian','student'], 40),
  ('waitlist_promoted',  'الترقية من قائمة الانتظار', 'تم تسجيلك بعد الانتظار',              '{العنوان}',                          array['العنوان'], null, array['guardian','student'], 50),
  ('serd_assigned',      'سرد مطلوب مني',              'سرد مطلوب منك',                       '{اسم_الطالب}',                       array['اسم_الطالب'], null, array['admin','teacher'], 60),
  ('serd_approved',      'اعتماد السرد',               'تم اعتماد سردك',                      '{الدرجة}',                           array['اسم_الطالب','الدرجة'], null, array['guardian','student'], 70),
  ('serd_rejected',      'عدم اعتماد السرد',           'لم يُعتمد السرد',                     '{السبب}',                            array['اسم_الطالب','السبب'], null, array['guardian','student'], 80),
  ('market_fulfilled',   'تسليم طلب السوق',            'تم تسليم طلبك',                       '{المنتج}',                           array['المنتج'], null, array['guardian','student'], 90),
  ('market_cancelled',   'إلغاء طلب السوق',            'أُلغي طلبك',                          '{المنتج}',                           array['المنتج'], null, array['guardian','student'], 100),
  ('badge_awarded',      'الشارات',                    'شارة جديدة: {الشارة}',                '{الوصف}',                            array['الشارة','الوصف'], null, array['guardian','student'], 110),
  ('weekly_digest',      'ملخص الأسبوع',               'ملخص أسبوع {اسم_الطالب}',            '{الملخص}',                           array['اسم_الطالب','الملخص'], null, array['guardian','student'], 120),
  ('attendance_reminder','تذكير تسجيل الحضور',         'لم يُسجَّل حضور حلقتك اليوم',        '{الحلقة}',                           array['الحلقة'], null, array['teacher'], 130),
  ('student_idle',       'تذكير الطالب المتأخر عن التسميع', 'اشتقنا لسماعك',              'لم تسمّع منذ {الأيام} أيام — نراك في حلقتك {الحلقة}', array['اسم_الطالب','الأيام','الحلقة'], null, array['guardian','student'], 140),
  ('deletion_request',   'طلبات حذف البيانات',         '{العنوان}',                          '{الوصف}',                            array['العنوان','الوصف'], null, array['admin'], 150),
  ('deletion_reviewed',  'نتيجة طلب حذف بياناتي',      '{العنوان}',                          '{الوصف}',                            array['العنوان','الوصف'], null, array['guardian','student','teacher'], 160)
on conflict (event_key) do update set name = excluded.name, available_vars = excluded.available_vars, roles = excluded.roles, sort = excluded.sort;

create table if not exists public.notification_templates (
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  event_key        text not null references public.notification_defaults (event_key) on update cascade on delete cascade,
  title_template   text not null,
  body_template    text not null,
  lead_hours       integer check (lead_hours is null or lead_hours between 0 and 336),
  audience         text not null default 'source' check (audience in ('source', 'admins', 'teachers', 'students', 'guardians')),
  is_enabled       boolean not null default true,
  updated_at       timestamptz not null default now(),
  updated_by       uuid references auth.users (id) on delete set null,
  primary key (organization_id, event_key)
);
alter table public.notification_templates enable row level security;
revoke all on public.notification_templates from anon, authenticated;

create table if not exists public.notification_settings (
  organization_id  uuid primary key references public.organizations (id) on delete cascade,
  quiet_from       time not null default '21:00',
  quiet_to         time not null default '07:00',
  day_start_time   time not null default '07:00',
  late_grace_hours integer not null default 12 check (late_grace_hours between 0 and 72),
  idle_days        integer not null default 3 check (idle_days between 1 and 30),
  is_paused        boolean not null default false,
  updated_at       timestamptz not null default now()
);
alter table public.notification_settings enable row level security;
revoke all on public.notification_settings from anon, authenticated;

-- viewing accounts never write these (same rule as every other per-center table)
drop trigger if exists a_deny_readonly_write on public.notification_templates;
create trigger a_deny_readonly_write before insert or update or delete on public.notification_templates
  for each row execute function public._deny_readonly_write();
drop trigger if exists a_deny_readonly_write on public.notification_settings;
create trigger a_deny_readonly_write before insert or update or delete on public.notification_settings
  for each row execute function public._deny_readonly_write();

-- people who muted the old combined types keep them muted after the split
insert into public.notification_prefs (user_id, organization_id, event_key, enabled)
  select user_id, organization_id, k, false from public.notification_prefs, unnest(array['serd_approved', 'serd_rejected']) k
  where event_key = 'serd_reviewed' and not enabled
on conflict do nothing;
insert into public.notification_prefs (user_id, organization_id, event_key, enabled)
  select user_id, organization_id, k, false from public.notification_prefs, unnest(array['market_fulfilled', 'market_cancelled']) k
  where event_key = 'market_order' and not enabled
on conflict do nothing;
insert into public.notification_prefs (user_id, organization_id, event_key, enabled)
  select user_id, organization_id, 'center_closed', false from public.notification_prefs where event_key = 'calendar_entry' and not enabled
on conflict do nothing;

-- ---------------------------------------------------------------------
-- 3. settings access, quiet hours
-- ---------------------------------------------------------------------
create or replace function public._notif_settings(p_org uuid)
returns public.notification_settings language plpgsql stable security definer set search_path = public as $$
declare r public.notification_settings;
begin
  select * into r from public.notification_settings where organization_id = p_org;
  if not found then
    r.organization_id := p_org; r.quiet_from := '21:00'; r.quiet_to := '07:00'; r.day_start_time := '07:00';
    r.late_grace_hours := 12; r.idle_days := 3; r.is_paused := false; r.updated_at := now();
  end if;
  return r;
end;
$$;

create or replace function public._notif_quiet(p_org uuid)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare s public.notification_settings; v_t time;
begin
  s := public._notif_settings(p_org);
  v_t := (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::time;
  return case
    when s.quiet_from = s.quiet_to then false
    when s.quiet_from < s.quiet_to then v_t >= s.quiet_from and v_t < s.quiet_to
    else v_t >= s.quiet_from or v_t < s.quiet_to end;
end;
$$;

-- ---------------------------------------------------------------------
-- 4. delivery log columns on the inbox rows
-- ---------------------------------------------------------------------
alter table public.notifications add column if not exists push_status   text;
alter table public.notifications add column if not exists devices_total integer not null default 0;
alter table public.notifications add column if not exists devices_ok    integer not null default 0;
alter table public.notifications add column if not exists push_error    text;
alter table public.notifications add column if not exists pushed_at     timestamptz;
alter table public.notifications add column if not exists dedupe_key    text;
alter table public.notifications add column if not exists deep_link     text;
alter table public.notifications alter column push_status set default 'pending';
alter table public.notifications drop constraint if exists notifications_push_status_check;
alter table public.notifications add constraint notifications_push_status_check
  check (push_status is null or push_status in ('pending', 'queued', 'sent', 'failed', 'no_device', 'skipped'));
create unique index if not exists notifications_dedupe_key on public.notifications (dedupe_key) where dedupe_key is not null;
create index if not exists notifications_org_created on public.notifications (organization_id, created_at desc);
create index if not exists notifications_queued on public.notifications (created_at) where push_status = 'queued';

alter table public.device_tokens add column if not exists app_version  text;
alter table public.device_tokens add column if not exists device_label text;
alter table public.device_tokens add column if not exists last_seen_at timestamptz not null default now();

drop function if exists public.register_device_token(uuid, text, text);
create or replace function public.register_device_token(p_org uuid, p_token text, p_platform text, p_app_version text default null, p_device_label text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  if p_platform not in ('ios', 'android', 'web') or nullif(btrim(coalesce(p_token, '')), '') is null then
    raise exception 'بيانات غير صالحة'; end if;
  insert into public.device_tokens (user_id, organization_id, token, platform, app_version, device_label, last_seen_at)
  values (auth.uid(), p_org, p_token, p_platform, nullif(btrim(coalesce(p_app_version, '')), ''), nullif(btrim(coalesce(p_device_label, '')), ''), now())
  on conflict (token) do update set user_id = auth.uid(), organization_id = p_org, platform = p_platform,
    app_version = coalesce(excluded.app_version, public.device_tokens.app_version),
    device_label = coalesce(excluded.device_label, public.device_tokens.device_label), last_seen_at = now();
end;
$$;

-- ---------------------------------------------------------------------
-- 5. _notify: templates, audience limit, pause-free inbox insert, dedupe
-- ---------------------------------------------------------------------
drop function if exists public._notify(uuid, uuid[], text, text, text, uuid);
create or replace function public._notify(
  p_org uuid, p_users uuid[], p_event text, p_title text, p_body text, p_ref uuid,
  p_vars jsonb default null, p_include_actor boolean default false, p_dedupe text default null)
returns void language plpgsql security definer set search_path = public as $$
declare d public.notification_defaults; t public.notification_templates; v_vars jsonb; v_title text; v_body text; v_aud text := 'source';
begin
  select * into d from public.notification_defaults where event_key = p_event;
  select * into t from public.notification_templates where organization_id = p_org and event_key = p_event;
  v_vars := jsonb_build_object('العنوان', coalesce(p_title, ''), 'الوصف', coalesce(p_body, '')) || coalesce(p_vars, '{}'::jsonb);
  if d.event_key is not null then
    if t.event_key is not null and not t.is_enabled then return; end if;
    v_title := public.notification_render(coalesce(t.title_template, d.title_template), v_vars);
    v_body  := public.notification_render(coalesce(t.body_template, d.body_template), v_vars);
    v_aud   := coalesce(t.audience, d.default_audience);
  else
    v_title := p_title; v_body := p_body;
  end if;
  v_title := coalesce(nullif(btrim(v_title), ''), nullif(btrim(coalesce(p_title, '')), ''), 'إشعار');

  insert into public.notifications (organization_id, user_id, event_key, title, body, ref_id, dedupe_key)
  select p_org, u, p_event, v_title, nullif(v_body, ''), p_ref, case when p_dedupe is null then null else p_dedupe || '|' || u::text end
  from unnest(coalesce(p_users, array[]::uuid[])) u
  where (p_include_actor or u is distinct from auth.uid())
    and (v_aud = 'source' or exists (
          select 1 from public.organization_members m
          where m.organization_id = p_org and m.user_id = u and m.status = 'active'
            and m.role::text = case v_aud when 'admins' then 'admin' when 'teachers' then 'teacher' when 'students' then 'student' else 'guardian' end))
    and not exists (select 1 from public.notification_prefs pr
                    where pr.user_id = u and pr.organization_id = p_org and pr.event_key = p_event and not pr.enabled)
  on conflict do nothing;
end;
$$;

-- ---------------------------------------------------------------------
-- 6. event triggers re-issued with template variables
-- ---------------------------------------------------------------------
create or replace function public.trg_notify_serd()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' and new.status = 'scheduled' and new.assigned_teacher_id is not null then
    perform public._notify(new.organization_id, array[new.assigned_teacher_id], 'serd_assigned',
      'سرد مطلوب منك', new.student_name, new.id, jsonb_build_object('اسم_الطالب', coalesce(new.student_name, '')));
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status and new.student_id is not null then
    if new.status = 'approved' then
      perform public._notify(new.organization_id, public._student_family_users(new.student_id), 'serd_approved',
        'تم اعتماد سردك', coalesce(new.score_percent::text || '%', ''), new.id,
        jsonb_build_object('اسم_الطالب', coalesce(new.student_name, ''), 'الدرجة', coalesce(new.score_percent::text || '%', '')));
    elsif new.status = 'rejected' then
      perform public._notify(new.organization_id, public._student_family_users(new.student_id), 'serd_rejected',
        'لم يُعتمد السرد', coalesce(new.reject_reason, ''), new.id,
        jsonb_build_object('اسم_الطالب', coalesce(new.student_name, ''), 'السبب', coalesce(new.reject_reason, '')));
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.trg_notify_purchase()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status and new.status in ('fulfilled', 'cancelled') then
    perform public._notify(new.organization_id, public._student_family_users(new.student_id),
      case new.status when 'fulfilled' then 'market_fulfilled' else 'market_cancelled' end,
      case new.status when 'fulfilled' then 'تم تسليم طلبك' else 'أُلغي طلبك' end, new.item_name, new.id,
      jsonb_build_object('المنتج', coalesce(new.item_name, '')));
  end if;
  return new;
end;
$$;

create or replace function public.trg_notify_waitlist()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_title text; v_org uuid;
begin
  if new.status = 'promoted' and old.status is distinct from 'promoted' then
    select title, organization_id into v_title, v_org from public.center_calendar where id = new.entry_id;
    perform public._notify(v_org, public._student_family_users(new.student_id), 'waitlist_promoted',
      'تم تسجيلك بعد الانتظار', v_title, new.entry_id, jsonb_build_object('العنوان', coalesce(v_title, '')));
  end if;
  return new;
end;
$$;

create or replace function public.trg_notify_calendar()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public._notify(new.organization_id, public._audience_users(new.organization_id, new.audience, new.circle_id, new.stage_id),
    case when new.is_working_day then 'calendar_entry' else 'center_closed' end,
    case when not new.is_working_day then 'إجازة / إغلاق: ' || new.title else 'جديد في التقويم: ' || new.title end,
    new.start_date::text, new.id,
    jsonb_build_object('العنوان', new.title, 'التاريخ', public._notif_date_label(new.organization_id, new.start_date),
      'الوقت', case when new.starts_at is null then '' else 'الساعة ' || to_char(new.starts_at, 'HH24:MI') end,
      'الموقع', coalesce(new.location, ''), 'الوصف', coalesce(new.description, '')));
  return new;
end;
$$;

create or replace function public.trg_notify_badge()
returns trigger language plpgsql security definer set search_path = public as $$
declare b public.badges%rowtype;
begin
  select * into b from public.badges where id = new.badge_id;
  perform public._notify(b.organization_id, public._student_family_users(new.student_id), 'badge_awarded',
    'شارة جديدة: ' || b.name, b.description, new.badge_id,
    jsonb_build_object('الشارة', b.name, 'الوصف', coalesce(b.description, '')));
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 7. scheduled jobs: pause switch + variables (+ the new idle reminder)
-- ---------------------------------------------------------------------
create or replace function public._event_lead_hours(p_org uuid)
returns integer language sql stable security definer set search_path = public as $$
  select case
    when public.org_setting(p_org, 'calendar_reminder_hours', '') ~ '^[0-9]{1,3}$' then public.org_setting(p_org, 'calendar_reminder_hours', '')::integer
    else coalesce((select lead_hours from public.notification_templates where organization_id = p_org and event_key = 'event_reminder'), 24) end;
$$;

create or replace function public.send_calendar_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; v_hours integer; v_start timestamptz; v_users uuid[]; v_when text; v_time text; v_count integer := 0; v_tz text; v_days integer;
begin
  for e in
    select c.*, coalesce(o.timezone, 'UTC') as tz
    from public.center_calendar c join public.organizations o on o.id = c.organization_id
    where c.is_working_day and c.start_date between current_date - 1 and current_date + 9
  loop
    continue when (public._notif_settings(e.organization_id)).is_paused;
    v_tz := e.tz;
    v_hours := public._event_lead_hours(e.organization_id);
    continue when v_hours <= 0;
    v_start := (e.start_date + coalesce(e.starts_at, time '08:00')) at time zone v_tz;
    continue when now() < v_start - make_interval(hours => v_hours) or now() >= v_start;
    continue when exists (select 1 from public.calendar_reminders r where r.entry_id = e.id and r.for_date = e.start_date);

    select array_agg(distinct u) into v_users
    from public.calendar_registrations r
    cross join lateral unnest(public._student_family_users(r.student_id)) u
    where r.entry_id = e.id and r.consent_status <> 'declined';

    v_days := e.start_date - (now() at time zone v_tz)::date;
    v_when := case when v_days <= 0 then 'اليوم' when v_days = 1 then 'غدًا' else 'بعد ' || v_days || ' أيام' end;
    v_time := case when e.starts_at is not null then 'الساعة ' || to_char(e.starts_at, 'HH24:MI') else '' end;

    if coalesce(array_length(v_users, 1), 0) > 0 then
      perform public._notify(e.organization_id, v_users, 'event_reminder', 'تذكير: ' || e.title,
        v_when || ' ' || v_time || coalesce(' · ' || nullif(e.location, ''), ''), e.id,
        jsonb_build_object('العنوان', e.title, 'التاريخ', v_when, 'الوقت', v_time, 'الموقع', coalesce(e.location, '')));
      v_count := v_count + 1;
    end if;
    insert into public.calendar_reminders (entry_id, for_date) values (e.id, e.start_date)
      on conflict (entry_id) do update set for_date = excluded.for_date, sent_at = now();
  end loop;
  return v_count;
end;
$$;

create or replace function public.send_attendance_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; c record; v_local timestamp; v_hour integer; v_n integer := 0;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    continue when public.org_setting(e.id, 'attendance_reminder_enabled', 'true') <> 'true';
    continue when (public._notif_settings(e.id)).is_paused;
    v_local := now() at time zone e.tz;
    v_hour := public._digest_setting(e.id, 'attendance_reminder_hour', 11);
    continue when extract(hour from v_local)::integer < v_hour or extract(hour from v_local)::integer >= 21;

    for c in
      select ci.id, ci.name, ci.teacher_id from public.circles ci
      where ci.organization_id = e.id and ci.status = 'active' and ci.teacher_id is not null
        and public.center_working_days(e.id, v_local::date, v_local::date, ci.id) > 0
        and exists (select 1 from public.students_profile s where s.circle_id = ci.id and s.status = 'active')
        and not exists (select 1 from public.attendance a where a.circle_id = ci.id and a.session_date = v_local::date)
        and not exists (select 1 from public.attendance_reminders_sent r where r.circle_id = ci.id and r.for_date = v_local::date)
    loop
      insert into public.attendance_reminders_sent (circle_id, for_date) values (c.id, v_local::date) on conflict do nothing;
      perform public._notify(e.id, array[c.teacher_id], 'attendance_reminder', 'لم يُسجَّل حضور حلقتك اليوم', c.name, c.id,
        jsonb_build_object('الحلقة', c.name));
      v_n := v_n + 1;
    end loop;
  end loop;
  return v_n;
end;
$$;

create or replace function public.send_weekly_digests(p_force_org uuid default null)
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; v_local timestamp; v_users uuid[]; v_from timestamptz; v_n integer; v_pts integer;
        v_att_ok integer; v_att_all integer; v_body text; v_sent integer := 0;
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

    v_from := ((v_local::date - 6)::timestamp) at time zone e.tz;
    for s in select id, full_name from public.students_profile where organization_id = e.id and status = 'active' loop
      v_users := public._student_family_users(s.id);
      continue when coalesce(array_length(v_users, 1), 0) = 0;

      select count(*), coalesce(sum(points_awarded), 0) into v_n, v_pts
        from public.daily_achievements where student_id = s.id and created_at >= v_from;
      select count(*) filter (where status::text in ('present', 'late')), count(*) filter (where status::text in ('present', 'late', 'absent'))
        into v_att_ok, v_att_all from public.attendance where student_id = s.id and session_date >= v_local::date - 6;

      v_body := case when v_n > 0 then 'سمّع ' || v_n || ' مرة · +' || v_pts || ' نقطة' else 'لم يُسجَّل تسميع هذا الأسبوع' end
             || case when v_att_all > 0 then ' · حضر ' || v_att_ok || ' من ' || v_att_all || ' أيام' else '' end;
      perform public._notify(e.id, v_users, 'weekly_digest', 'ملخص أسبوع ' || s.full_name, v_body, s.id,
        jsonb_build_object('اسم_الطالب', s.full_name, 'الملخص', v_body), true);
      v_sent := v_sent + 1;
    end loop;
  end loop;
  return v_sent;
end;
$$;

-- A student (and guardian) who has not recited for `idle_days` working days gets one nudge per idle stretch.
create or replace function public.send_idle_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; s record; st public.notification_settings; v_local timestamp; v_today date; v_since date; v_idle integer; v_n integer := 0;
begin
  for e in select o.id, coalesce(o.timezone, 'UTC') as tz from public.organizations o where o.status in ('trial', 'active') loop
    st := public._notif_settings(e.id);
    continue when st.is_paused;
    if not exists (select 1 from public.notification_defaults d where d.event_key = 'student_idle') then continue; end if;
    if exists (select 1 from public.notification_templates t where t.organization_id = e.id and t.event_key = 'student_idle' and not t.is_enabled) then continue; end if;
    v_local := now() at time zone e.tz;
    v_today := v_local::date;
    -- only in the morning window: from the day start until the late-grace limit
    continue when v_local::time < st.day_start_time or v_local >= (v_today + st.day_start_time) + make_interval(hours => st.late_grace_hours);
    continue when public.center_working_days(e.id, v_today, v_today, null) = 0;

    for s in
      select sp.id, sp.full_name, sp.circle_id, ci.name as circle_name, la.last_day, sp.created_at
      from public.students_profile sp
      left join public.circles ci on ci.id = sp.circle_id
      cross join lateral (select max((da.created_at at time zone e.tz)::date) as last_day from public.daily_achievements da where da.student_id = sp.id) la
      where sp.organization_id = e.id and sp.status = 'active' and sp.circle_id is not null
    loop
      v_since := greatest(coalesce(s.last_day, (s.created_at at time zone e.tz)::date), v_today - 60);
      v_idle := public.center_working_days(e.id, v_since + 1, v_today, s.circle_id);
      continue when v_idle < st.idle_days;
      perform public._notify(e.id, public._student_family_users(s.id), 'student_idle', 'اشتقنا لسماعك',
        'لم تسمّع منذ ' || v_idle || ' أيام', s.id,
        jsonb_build_object('اسم_الطالب', s.full_name, 'الأيام', v_idle::text, 'الحلقة', coalesce(s.circle_name, '')), true,
        'student_idle|' || s.id::text || '|' || coalesce(s.last_day::text, 'never'));
      v_n := v_n + 1;
    end loop;
  end loop;
  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
-- 8. push delivery states: paused / quiet hours / not configured
-- ---------------------------------------------------------------------
create or replace function public.trg_push_notification()
returns trigger language plpgsql security definer set search_path = public as $$
declare st public.notification_settings;
begin
  st := public._notif_settings(new.organization_id);
  if new.event_key <> 'test' and st.is_paused then
    update public.notifications set push_status = 'skipped', push_error = 'الإرسال موقوف مؤقتًا من إعدادات الإشعارات' where id = new.id;
  elsif public._platform_setting('push_url', '') = '' then
    update public.notifications set push_status = 'skipped', push_error = 'خدمة الإشعارات غير مفعّلة على المنصة' where id = new.id;
  elsif new.event_key not in ('test', 'manual') and public._notif_quiet(new.organization_id) then
    update public.notifications set push_status = 'queued' where id = new.id;     -- goes out when the quiet hours end
  else
    perform public._push_dispatch('notification', new.id);
  end if;
  return new;
end;
$$;

-- every few minutes: send what waited for the morning, drop what waited too long, fail what never got an answer
create or replace function public.flush_deferred_push()
returns integer language plpgsql security definer set search_path = public as $$
declare r record; st public.notification_settings; v_n integer := 0;
begin
  for r in select n.id, n.organization_id, n.created_at from public.notifications n
           where n.push_status = 'queued' order by n.created_at limit 400
  loop
    st := public._notif_settings(r.organization_id);
    if st.is_paused then
      update public.notifications set push_status = 'skipped', push_error = 'الإرسال موقوف مؤقتًا من إعدادات الإشعارات' where id = r.id;
    elsif r.created_at < now() - make_interval(hours => st.late_grace_hours) then
      update public.notifications set push_status = 'skipped', push_error = 'انتهت مهلة التأخير قبل انتهاء ساعات الصمت' where id = r.id;
    elsif not public._notif_quiet(r.organization_id) then
      update public.notifications set push_status = 'pending' where id = r.id;
      perform public._push_dispatch('notification', r.id);
      v_n := v_n + 1;
    end if;
  end loop;
  update public.notifications set push_status = 'failed', push_error = 'لم يصل رد من خدمة الإشعارات'
    where push_status = 'pending' and created_at < now() - interval '30 minutes';
  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
-- 9. admin RPCs
-- ---------------------------------------------------------------------
create or replace function public.admin_notification_config(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare st public.notification_settings;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة للمشرف فقط'; end if;
  st := public._notif_settings(p_org);
  return jsonb_build_object(
    'settings', jsonb_build_object('timezone', coalesce((select timezone from public.organizations where id = p_org), 'UTC'),
      'quiet_from', to_char(st.quiet_from, 'HH24:MI'), 'quiet_to', to_char(st.quiet_to, 'HH24:MI'),
      'day_start_time', to_char(st.day_start_time, 'HH24:MI'), 'late_grace_hours', st.late_grace_hours,
      'idle_days', st.idle_days, 'is_paused', st.is_paused),
    'templates', coalesce((
      select jsonb_agg(jsonb_build_object(
        'event_key', d.event_key, 'name', d.name, 'roles', to_jsonb(d.roles), 'available_vars', to_jsonb(d.available_vars),
        'title_template', coalesce(t.title_template, d.title_template), 'body_template', coalesce(t.body_template, d.body_template),
        'default_title', d.title_template, 'default_body', d.body_template,
        'has_lead', d.lead_hours is not null,
        'lead_hours', case when d.event_key = 'event_reminder' then public._event_lead_hours(p_org) else coalesce(t.lead_hours, d.lead_hours) end,
        'audience', coalesce(t.audience, d.default_audience), 'is_enabled', coalesce(t.is_enabled, true),
        'customized', t.event_key is not null, 'updated_at', t.updated_at,
        'updated_by_name', (select full_name from public.profiles where id = t.updated_by),
        'sent_count', (select count(*) from public.notifications n where n.organization_id = p_org and n.event_key = d.event_key))
        order by d.sort)
      from public.notification_defaults d
      left join public.notification_templates t on t.organization_id = p_org and t.event_key = d.event_key), '[]'::jsonb));
end;
$$;

create or replace function public.admin_save_notification_template(
  p_org uuid, p_event text, p_title text, p_body text, p_lead integer, p_audience text, p_enabled boolean)
returns void language plpgsql security definer set search_path = public as $$
declare d public.notification_defaults; v_title text := nullif(btrim(coalesce(p_title, '')), ''); v_body text := nullif(btrim(coalesce(p_body, '')), '');
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  select * into d from public.notification_defaults where event_key = p_event;
  if d.event_key is null then raise exception 'نوع إشعار غير معروف'; end if;
  if v_title is null then raise exception 'اكتب عنوان الإشعار — هو السطر الذي يُقرأ على الشاشة المقفلة'; end if;
  if v_body is null then raise exception 'اكتب نص الإشعار'; end if;
  if length(v_title) > 120 or length(v_body) > 300 then raise exception 'العنوان حتى 120 حرفًا والنص حتى 300'; end if;
  if p_audience not in ('source', 'admins', 'teachers', 'students', 'guardians') then raise exception 'جمهور غير معروف'; end if;
  if p_lead is not null and (p_lead < 0 or p_lead > 336) then raise exception 'المهلة بين 0 و336 ساعة'; end if;

  insert into public.notification_templates (organization_id, event_key, title_template, body_template, lead_hours, audience, is_enabled, updated_at, updated_by)
  values (p_org, p_event, v_title, v_body, case when d.lead_hours is null then null else p_lead end, p_audience, coalesce(p_enabled, true), now(), auth.uid())
  on conflict (organization_id, event_key) do update set title_template = excluded.title_template, body_template = excluded.body_template,
    lead_hours = excluded.lead_hours, audience = excluded.audience, is_enabled = excluded.is_enabled, updated_at = now(), updated_by = auth.uid();

  -- the event reminder's lead time is also the calendar setting the reminder job reads
  if p_event = 'event_reminder' and p_lead is not null then
    insert into public.organization_settings (organization_id, key, value, updated_at)
    values (p_org, 'calendar_reminder_hours', p_lead::text, now())
    on conflict (organization_id, key) do update set value = excluded.value, updated_at = now();
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, diff)
  values (p_org, auth.uid(), 'update', 'notification_templates', jsonb_build_object('event_key', p_event, 'title', v_title, 'audience', p_audience, 'enabled', coalesce(p_enabled, true)));
end;
$$;

create or replace function public.admin_reset_notification_template(p_org uuid, p_event text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  delete from public.notification_templates where organization_id = p_org and event_key = p_event;
  if p_event = 'event_reminder' then
    delete from public.organization_settings where organization_id = p_org and key = 'calendar_reminder_hours';
  end if;
end;
$$;

create or replace function public.admin_save_notification_settings(
  p_org uuid, p_quiet_from time, p_quiet_to time, p_day_start time, p_grace integer, p_idle integer, p_paused boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if p_quiet_from is null or p_quiet_to is null or p_day_start is null then raise exception 'أكمل الأوقات'; end if;
  if p_grace is null or p_grace < 0 or p_grace > 72 then raise exception 'مهلة التأخير بين 0 و72 ساعة'; end if;
  if p_idle is null or p_idle < 1 or p_idle > 30 then raise exception 'أيام التأخر عن التسميع بين 1 و30'; end if;
  insert into public.notification_settings (organization_id, quiet_from, quiet_to, day_start_time, late_grace_hours, idle_days, is_paused, updated_at)
  values (p_org, p_quiet_from, p_quiet_to, p_day_start, p_grace, p_idle, coalesce(p_paused, false), now())
  on conflict (organization_id) do update set quiet_from = excluded.quiet_from, quiet_to = excluded.quiet_to, day_start_time = excluded.day_start_time,
    late_grace_hours = excluded.late_grace_hours, idle_days = excluded.idle_days, is_paused = excluded.is_paused, updated_at = now();
  insert into public.audit_log (organization_id, actor_id, action, entity_table, diff)
  values (p_org, auth.uid(), 'update', 'notification_settings', jsonb_build_object('quiet_from', p_quiet_from, 'quiet_to', p_quiet_to, 'idle_days', p_idle, 'paused', coalesce(p_paused, false)));
end;
$$;

-- immediate broadcast written by the admin: everyone / a role / a circle / chosen people
create or replace function public.admin_send_notification(
  p_org uuid, p_title text, p_body text, p_audience text default 'all', p_circle uuid default null,
  p_user_ids uuid[] default null, p_deep_link text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_title text := nullif(btrim(coalesce(p_title, '')), ''); v_body text := nullif(btrim(coalesce(p_body, '')), '');
        v_users uuid[]; v_n integer; v_dark integer; v_link text := nullif(btrim(coalesce(p_deep_link, '')), '');
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if v_title is null or v_body is null then raise exception 'اكتب العنوان والنص قبل الإرسال'; end if;
  if length(v_title) > 120 or length(v_body) > 400 then raise exception 'العنوان حتى 120 حرفًا والنص حتى 400'; end if;
  if v_link is not null and v_link not in ('announcements', 'calendar', 'market', 'chat', 'badges') then raise exception 'وجهة غير معروفة'; end if;

  if p_user_ids is not null then
    select coalesce(array_agg(distinct m.user_id), array[]::uuid[]) into v_users
      from public.organization_members m where m.organization_id = p_org and m.status = 'active' and m.user_id = any (p_user_ids);
  elsif p_audience = 'admins' then
    select coalesce(array_agg(distinct m.user_id), array[]::uuid[]) into v_users
      from public.organization_members m where m.organization_id = p_org and m.status = 'active' and m.role::text = 'admin';
  elsif p_audience = 'teachers' then
    select coalesce(array_agg(distinct m.user_id), array[]::uuid[]) into v_users
      from public.organization_members m where m.organization_id = p_org and m.status = 'active' and m.role::text = 'teacher'
        and (p_circle is null or exists (select 1 from public.circles c where c.id = p_circle and c.teacher_id = m.user_id));
  elsif p_audience in ('students', 'guardians') then
    v_users := public._family_users(p_org, case p_audience when 'students' then 'student' else 'guardian' end, p_circle, null);
  elsif p_audience = 'all' then
    v_users := public._audience_users(p_org, 'all', p_circle, null);
  else
    raise exception 'اختر الجمهور';
  end if;
  v_users := coalesce(v_users, array[]::uuid[]);
  if coalesce(array_length(v_users, 1), 0) = 0 then raise exception 'لا يوجد مستلمون في هذا الجمهور'; end if;

  insert into public.notifications (organization_id, user_id, event_key, title, body, deep_link)
  select p_org, u, 'manual', v_title, v_body, v_link from unnest(v_users) u;
  get diagnostics v_n = row_count;
  select count(*) into v_dark from unnest(v_users) u where not exists (select 1 from public.device_tokens d where d.user_id = u);
  insert into public.audit_log (organization_id, actor_id, action, entity_table, diff)
  values (p_org, auth.uid(), 'insert', 'notifications', jsonb_build_object('manual', true, 'title', v_title, 'audience', p_audience, 'count', v_n));
  return jsonb_build_object('sent', v_n, 'no_device', v_dark);
end;
$$;

create or replace function public.admin_notification_log(
  p_org uuid, p_from date default null, p_to date default null, p_event text default null, p_status text default null,
  p_limit integer default 100, p_offset integer default 0)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_tz text; v_from timestamptz; v_to timestamptz;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة للمشرف فقط'; end if;
  v_tz := coalesce((select timezone from public.organizations where id = p_org), 'UTC');
  v_from := (coalesce(p_from, (now() at time zone v_tz)::date - 30)::timestamp) at time zone v_tz;
  v_to := ((coalesce(p_to, (now() at time zone v_tz)::date) + 1)::timestamp) at time zone v_tz;
  return jsonb_build_object(
    'stats', (select jsonb_build_object('total', count(*),
        'sent', count(*) filter (where n.push_status = 'sent'), 'failed', count(*) filter (where n.push_status = 'failed'),
        'no_device', count(*) filter (where n.push_status = 'no_device'),
        'pending', count(*) filter (where n.push_status in ('pending', 'queued')), 'skipped', count(*) filter (where n.push_status = 'skipped'))
      from public.notifications n where n.organization_id = p_org and n.created_at >= v_from and n.created_at < v_to
        and (p_event is null or p_event = '' or n.event_key = p_event)),
    'rows', coalesce((select jsonb_agg(x order by x.created_at desc) from (
        select n.id, n.event_key, n.title, n.body, n.push_status, n.devices_total, n.devices_ok, n.push_error, n.created_at,
               pr.full_name as user_name, (select m.role::text from public.organization_members m where m.organization_id = p_org and m.user_id = n.user_id limit 1) as role
        from public.notifications n left join public.profiles pr on pr.id = n.user_id
        where n.organization_id = p_org and n.created_at >= v_from and n.created_at < v_to
          and (p_event is null or p_event = '' or n.event_key = p_event)
          and (p_status is null or p_status = '' or n.push_status = p_status or (p_status = 'pending' and n.push_status = 'queued'))
        order by n.created_at desc limit least(greatest(coalesce(p_limit, 100), 1), 300) offset greatest(coalesce(p_offset, 0), 0)) x), '[]'::jsonb));
end;
$$;

create or replace function public.admin_notification_devices(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة للمشرف فقط'; end if;
  return jsonb_build_object(
    'configured', public._platform_setting('push_url', '') <> '',
    'my_id', auth.uid(),
    'members', coalesce((
      select jsonb_agg(x order by x.devices desc, x.name) from (
        select m.user_id, pr.full_name as name, m.role::text as role,
               (select count(*) from public.device_tokens d where d.user_id = m.user_id) as devices,
               (select max(d.last_seen_at) from public.device_tokens d where d.user_id = m.user_id) as last_seen,
               (select string_agg(distinct d.platform, '، ') from public.device_tokens d where d.user_id = m.user_id) as platforms,
               (select d.device_label from public.device_tokens d where d.user_id = m.user_id order by d.last_seen_at desc limit 1) as label,
               (select d.app_version from public.device_tokens d where d.user_id = m.user_id order by d.last_seen_at desc limit 1) as app_version
        from public.organization_members m join public.profiles pr on pr.id = m.user_id
        where m.organization_id = p_org and m.status = 'active') x), '[]'::jsonb));
end;
$$;

-- what is scheduled to go out soon: event reminders (from their lead time) and the next weekly digest
create or replace function public.admin_notifications_upcoming(p_org uuid, p_days integer default 14)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_tz text; v_days integer := least(greatest(coalesce(p_days, 14), 1), 120); v_lead integer; v_items jsonb; v_local timestamp;
        v_dow integer; v_hour integer; v_next timestamp; v_digest jsonb := null; v_enabled boolean;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة للمشرف فقط'; end if;
  v_tz := coalesce((select timezone from public.organizations where id = p_org), 'UTC');
  v_lead := public._event_lead_hours(p_org);
  v_local := now() at time zone v_tz;

  select coalesce(jsonb_agg(x order by x.send_at), '[]'::jsonb) into v_items from (
    select c.id, c.title, c.start_date, c.starts_at,
      (((c.start_date + coalesce(c.starts_at, time '08:00')) at time zone v_tz) - make_interval(hours => v_lead)) as send_at,
      (select count(distinct u) from public.calendar_registrations r cross join lateral unnest(public._student_family_users(r.student_id)) u
        where r.entry_id = c.id and r.consent_status <> 'declined') as recipients,
      exists (select 1 from public.calendar_reminders cr where cr.entry_id = c.id and cr.for_date = c.start_date) as already_sent
    from public.center_calendar c
    where c.organization_id = p_org and c.is_working_day and v_lead > 0
      and c.start_date between v_local::date and v_local::date + v_days
      and (((c.start_date + coalesce(c.starts_at, time '08:00')) at time zone v_tz)) > now()) x;

  v_enabled := public.org_setting(p_org, 'weekly_digest_enabled', 'true') = 'true';
  if v_enabled then
    v_dow := public._digest_setting(p_org, 'weekly_digest_dow', 4);
    v_hour := public._digest_setting(p_org, 'weekly_digest_hour', 17);
    v_next := (v_local::date + ((v_dow - extract(dow from v_local)::integer + 7) % 7)) + make_interval(hours => v_hour);
    if v_next <= v_local then v_next := v_next + interval '7 days'; end if;
    if v_next::date <= v_local::date + v_days then
      v_digest := jsonb_build_object('send_at', (v_next at time zone v_tz),
        'recipients', (select count(distinct u) from public.students_profile sp cross join lateral unnest(public._student_family_users(sp.id)) u
                       where sp.organization_id = p_org and sp.status = 'active'));
    end if;
  end if;
  return jsonb_build_object('lead_hours', v_lead, 'items', v_items, 'digest', v_digest, 'paused', (public._notif_settings(p_org)).is_paused);
end;
$$;

-- ---------------------------------------------------------------------
-- 10. everyone's own view
-- ---------------------------------------------------------------------
create or replace function public.my_notifications(p_org uuid, p_limit integer default 60)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', n.id, 'event_key', n.event_key, 'title', n.title, 'body', n.body,
           'ref_id', n.ref_id, 'deep_link', n.deep_link, 'created_at', n.created_at, 'read', n.read_at is not null) order by n.created_at desc), '[]'::jsonb)
  from (select * from public.notifications where user_id = auth.uid() and organization_id = p_org
        order by created_at desc limit greatest(1, least(coalesce(p_limit, 60), 200))) n;
$$;

-- the switches a person sees: the types that can reach their role and that the center has not turned off
create or replace function public.my_notification_types(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_role text; v_prefs jsonb;
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  select m.role::text into v_role from public.organization_members m where m.organization_id = p_org and m.user_id = auth.uid() and m.status = 'active' limit 1;
  select coalesce(jsonb_object_agg(event_key, enabled), '{}'::jsonb) into v_prefs from public.notification_prefs where user_id = auth.uid() and organization_id = p_org;
  return jsonb_build_object(
    'quiet_from', to_char((public._notif_settings(p_org)).quiet_from, 'HH24:MI'),
    'quiet_to', to_char((public._notif_settings(p_org)).quiet_to, 'HH24:MI'),
    'paused', (public._notif_settings(p_org)).is_paused,
    'types', coalesce((
      select jsonb_agg(jsonb_build_object('event_key', d.event_key, 'name', d.name, 'enabled', coalesce((v_prefs ->> d.event_key)::boolean, true)) order by d.sort)
      from public.notification_defaults d
      left join public.notification_templates t on t.organization_id = p_org and t.event_key = d.event_key
      where v_role = any (d.roles) and coalesce(t.is_enabled, true)), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------
-- 11. schedule + privileges
-- ---------------------------------------------------------------------
select cron.schedule('push-deferred', '*/10 * * * *', 'select public.flush_deferred_push()');
select cron.schedule('idle-reminders', '40 * * * *', 'select public.send_idle_reminders()');

do $$
declare f text;
begin
  foreach f in array array[
    'notification_render(text, jsonb)', '_notif_date_label(uuid, date)', '_notif_settings(uuid)', '_notif_quiet(uuid)',
    '_notify(uuid, uuid[], text, text, text, uuid, jsonb, boolean, text)', '_event_lead_hours(uuid)',
    'send_calendar_reminders()', 'send_attendance_reminders()', 'send_weekly_digests(uuid)', 'send_idle_reminders()',
    'flush_deferred_push()', 'trg_push_notification()',
    'trg_notify_serd()', 'trg_notify_purchase()', 'trg_notify_waitlist()', 'trg_notify_calendar()', 'trg_notify_badge()'
  ] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
  foreach f in array array[
    'admin_notification_config(uuid)', 'admin_save_notification_template(uuid, text, text, text, integer, text, boolean)',
    'admin_reset_notification_template(uuid, text)', 'admin_save_notification_settings(uuid, time, time, time, integer, integer, boolean)',
    'admin_send_notification(uuid, text, text, text, uuid, uuid[], text)', 'admin_notification_log(uuid, date, date, text, text, integer, integer)',
    'admin_notification_devices(uuid)', 'admin_notifications_upcoming(uuid, integer)', 'my_notifications(uuid, integer)',
    'my_notification_types(uuid)', 'register_device_token(uuid, text, text, text, text)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
