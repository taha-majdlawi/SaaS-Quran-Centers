-- =====================================================================
-- 0080: notifications in the recipient's language (i18n phase 4)
-- ---------------------------------------------------------------------
-- Until now every notification the database writes was Arabic. Now:
--   1. profiles.locale - each person's chosen language (ar/en/tr/fr), saved
--      by the language pickers on the site and in the app (set_my_locale).
--   2. Centers may default to Turkish or French too (get_public_site).
--   3. notification_default_texts - the default wording of every type in
--      English, Turkish and French (Arabic stays in notification_defaults;
--      variable names stay the Arabic ones, so one set of vars fills all).
--   4. _notify renders once per language among the recipients: the person's
--      language, else the center's default, else Arabic. A template the
--      center's admin customised is used as written for everyone.
--   5. Texts the database composes itself (dates, the weekly summary, the
--      billing / deletion / review messages) are passed per language in
--      p_vars->'_i18n' -> {lang: {var: value}}, which overrides the shared
--      vars for that language only.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. each person's language
-- ---------------------------------------------------------------------
alter table public.profiles add column if not exists locale text;
alter table public.profiles drop constraint if exists profiles_locale_check;
alter table public.profiles add constraint profiles_locale_check check (locale is null or locale in ('ar', 'en', 'tr', 'fr'));

-- a personal preference, not center data: allowed for view-only accounts too
create or replace function public.set_my_locale(p_locale text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'غير مصرّح'; end if;
  if p_locale is not null and p_locale not in ('ar', 'en', 'tr', 'fr') then raise exception 'لغة غير مدعومة'; end if;
  update public.profiles set locale = p_locale where id = auth.uid();
end;
$$;
revoke all on function public.set_my_locale(text) from public, anon;
grant execute on function public.set_my_locale(text) to authenticated;

create or replace function public._center_lang(p_org uuid)
returns text language sql stable security definer set search_path = public as $$
  select coalesce((select value from public.organization_settings
                    where organization_id = p_org and key = 'default_language' and value in ('ar', 'en', 'tr', 'fr')), 'ar');
$$;

create or replace function public._notif_lang(p_org uuid, p_user uuid)
returns text language sql stable security definer set search_path = public as $$
  select coalesce((select locale from public.profiles where id = p_user), public._center_lang(p_org));
$$;
revoke all on function public._center_lang(uuid) from public, anon, authenticated;
revoke all on function public._notif_lang(uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 2. a center may work in Turkish or French
-- ---------------------------------------------------------------------
create or replace function public.get_public_site(p_slug text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare o public.organizations%rowtype; s public.site_settings%rowtype;
begin
  select * into o from public.organizations where slug = lower(btrim(coalesce(p_slug, '')));
  if not found then return null; end if;
  select * into s from public.site_settings where organization_id = o.id;
  return jsonb_build_object(
    'name', o.name, 'slug', o.slug, 'logo_url', o.logo_url,
    'primary_color', o.primary_color, 'secondary_color', o.secondary_color,
    'enabled', coalesce(s.public_site_enabled, false),
    'default_language', public._center_lang(o.id),
    -- contact details are shown only when the admin published the page
    'hero_title', case when coalesce(s.public_site_enabled, false) then s.hero_title end,
    'hero_body', case when coalesce(s.public_site_enabled, false) then s.hero_body end,
    'contact_email', case when coalesce(s.public_site_enabled, false) then s.contact_email end
  );
end;
$$;
revoke all on function public.get_public_site(text) from public;
grant execute on function public.get_public_site(text) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------
-- 3. default wording per language
-- ---------------------------------------------------------------------
create table if not exists public.notification_default_texts (
  event_key      text not null references public.notification_defaults (event_key) on update cascade on delete cascade,
  lang           text not null check (lang in ('en', 'tr', 'fr')),
  title_template text not null,
  body_template  text not null,
  primary key (event_key, lang)
);
alter table public.notification_default_texts enable row level security;
revoke all on public.notification_default_texts from anon, authenticated;

insert into public.notification_default_texts (event_key, lang, title_template, body_template) values
  ('announcement', 'en', '{العنوان}', '{الوصف}'),
  ('announcement', 'tr', '{العنوان}', '{الوصف}'),
  ('announcement', 'fr', '{العنوان}', '{الوصف}'),
  ('calendar_entry', 'en', 'New in the calendar: {العنوان}', '{التاريخ} {الوقت} · {الموقع}'),
  ('calendar_entry', 'tr', 'Takvimde yeni: {العنوان}', '{التاريخ} {الوقت} · {الموقع}'),
  ('calendar_entry', 'fr', 'Nouveau dans le calendrier : {العنوان}', '{التاريخ} {الوقت} · {الموقع}'),
  ('center_closed', 'en', 'Holiday / closure: {العنوان}', '{التاريخ}'),
  ('center_closed', 'tr', 'Tatil / kapalı: {العنوان}', '{التاريخ}'),
  ('center_closed', 'fr', 'Congé / fermeture : {العنوان}', '{التاريخ}'),
  ('event_reminder', 'en', 'Reminder: {العنوان}', '{التاريخ} {الوقت} · {الموقع}'),
  ('event_reminder', 'tr', 'Hatırlatma: {العنوان}', '{التاريخ} {الوقت} · {الموقع}'),
  ('event_reminder', 'fr', 'Rappel : {العنوان}', '{التاريخ} {الوقت} · {الموقع}'),
  ('waitlist_promoted', 'en', 'You’re registered after waiting', '{العنوان}'),
  ('waitlist_promoted', 'tr', 'Bekledikten sonra kaydınız yapıldı', '{العنوان}'),
  ('waitlist_promoted', 'fr', 'Vous êtes inscrit après l’attente', '{العنوان}'),
  ('serd_assigned', 'en', 'A serd is assigned to you', '{اسم_الطالب}'),
  ('serd_assigned', 'tr', 'Size bir serd atandı', '{اسم_الطالب}'),
  ('serd_assigned', 'fr', 'Un serd vous est assigné', '{اسم_الطالب}'),
  ('serd_approved', 'en', 'Your serd is approved', '{الدرجة}'),
  ('serd_approved', 'tr', 'Serdiniz onaylandı', '{الدرجة}'),
  ('serd_approved', 'fr', 'Votre serd est validé', '{الدرجة}'),
  ('serd_rejected', 'en', 'The serd was not approved', '{السبب}'),
  ('serd_rejected', 'tr', 'Serd onaylanmadı', '{السبب}'),
  ('serd_rejected', 'fr', 'Le serd n’a pas été validé', '{السبب}'),
  ('market_fulfilled', 'en', 'Your order was delivered', '{المنتج}'),
  ('market_fulfilled', 'tr', 'Siparişiniz teslim edildi', '{المنتج}'),
  ('market_fulfilled', 'fr', 'Votre commande a été remise', '{المنتج}'),
  ('market_cancelled', 'en', 'Your order was cancelled', '{المنتج}'),
  ('market_cancelled', 'tr', 'Siparişiniz iptal edildi', '{المنتج}'),
  ('market_cancelled', 'fr', 'Votre commande a été annulée', '{المنتج}'),
  ('badge_awarded', 'en', 'New badge: {الشارة}', '{الوصف}'),
  ('badge_awarded', 'tr', 'Yeni rozet: {الشارة}', '{الوصف}'),
  ('badge_awarded', 'fr', 'Nouveau badge : {الشارة}', '{الوصف}'),
  ('weekly_digest', 'en', '{اسم_الطالب}’s week', '{الملخص}'),
  ('weekly_digest', 'tr', '{اسم_الطالب} haftalık özeti', '{الملخص}'),
  ('weekly_digest', 'fr', 'La semaine de {اسم_الطالب}', '{الملخص}'),
  ('attendance_reminder', 'en', 'Your circle’s attendance isn’t taken yet today', '{الحلقة}'),
  ('attendance_reminder', 'tr', 'Halkanızın bugünkü yoklaması henüz alınmadı', '{الحلقة}'),
  ('attendance_reminder', 'fr', 'L’appel de votre cercle n’est pas encore fait aujourd’hui', '{الحلقة}'),
  ('teacher_checkin_reminder', 'en', 'You haven’t checked in today', '{الحلقة} circle — check in from the app'),
  ('teacher_checkin_reminder', 'tr', 'Bugün girişinizi yapmadınız', '{الحلقة} halkası — girişinizi uygulamadan yapın'),
  ('teacher_checkin_reminder', 'fr', 'Vous n’avez pas pointé aujourd’hui', 'Cercle {الحلقة} — pointez depuis l’application'),
  ('student_idle_teacher', 'en', '{اسم_الطالب} hasn’t recited for {الأيام} days', '{الحلقة}'),
  ('student_idle_teacher', 'tr', '{اسم_الطالب} {الأيام} gündür dinletme yapmadı', '{الحلقة}'),
  ('student_idle_teacher', 'fr', '{اسم_الطالب} n’a pas récité depuis {الأيام} jours', '{الحلقة}'),
  ('student_idle', 'en', 'We miss hearing you', 'No recitation for {الأيام} days — see you in your {الحلقة} circle'),
  ('student_idle', 'tr', 'Sizi dinlemeyi özledik', '{الأيام} gündür dinletme yok — {الحلقة} halkanızda görüşmek üzere'),
  ('student_idle', 'fr', 'Vous entendre nous manque', 'Pas de récitation depuis {الأيام} jours — à bientôt dans votre cercle {الحلقة}'),
  ('student_absences', 'en', 'Repeated absence: {اسم_الطالب}', 'Absent {العدد} times in the last {المدة} days · {الحلقة}'),
  ('student_absences', 'tr', 'Tekrarlanan devamsızlık: {اسم_الطالب}', 'Son {المدة} günde {العدد} kez gelmedi · {الحلقة}'),
  ('student_absences', 'fr', 'Absences répétées : {اسم_الطالب}', 'Absent {العدد} fois sur les {المدة} derniers jours · {الحلقة}'),
  ('deletion_request', 'en', '{العنوان}', '{الوصف}'),
  ('deletion_request', 'tr', '{العنوان}', '{الوصف}'),
  ('deletion_request', 'fr', '{العنوان}', '{الوصف}'),
  ('deletion_reviewed', 'en', '{العنوان}', '{الوصف}'),
  ('deletion_reviewed', 'tr', '{العنوان}', '{الوصف}'),
  ('deletion_reviewed', 'fr', '{العنوان}', '{الوصف}'),
  ('gathering_submitted', 'en', 'A new gathering awaits matching', '{العنوان} — {عدد} names from {المعلم}'),
  ('gathering_submitted', 'tr', 'Eşleştirme bekleyen yeni bir toplantı', '{العنوان} — {المعلم} tarafından {عدد} isim'),
  ('gathering_submitted', 'fr', 'Un nouveau rassemblement attend d’être rattaché', '{العنوان} — {عدد} noms de {المعلم}'),
  ('external_submitted', 'en', 'An external recitation awaits matching', '{الطالب} — from {المعلم}'),
  ('external_submitted', 'tr', 'Eşleştirme bekleyen dış dinletme', '{الطالب} — {المعلم} tarafından'),
  ('external_submitted', 'fr', 'Une récitation externe attend d’être rattachée', '{الطالب} — de {المعلم}'),
  ('external_reviewed', 'en', '{الحالة}', '{الطالب}'),
  ('external_reviewed', 'tr', '{الحالة}', '{الطالب}'),
  ('external_reviewed', 'fr', '{الحالة}', '{الطالب}'),
  ('assistant_assigned', 'en', 'You were made an assistant teacher', 'In the {الحلقة} circle'),
  ('assistant_assigned', 'tr', 'Yardımcı öğretmen olarak atandınız', '{الحلقة} halkasında'),
  ('assistant_assigned', 'fr', 'Vous avez été nommé enseignant assistant', 'Dans le cercle {الحلقة}'),
  ('billing_reminder', 'en', '{العنوان}', '{الوصف}'),
  ('billing_reminder', 'tr', '{العنوان}', '{الوصف}'),
  ('billing_reminder', 'fr', '{العنوان}', '{الوصف}'),
  ('billing_reviewed', 'en', '{الحالة}', '{الخطة} · until {حتى}'),
  ('billing_reviewed', 'tr', '{الحالة}', '{الخطة} · {حتى} tarihine kadar'),
  ('billing_reviewed', 'fr', '{الحالة}', '{الخطة} · jusqu’au {حتى}'),
  ('capacity_warning', 'en', '{العنوان}', '{الوصف}'),
  ('capacity_warning', 'tr', '{العنوان}', '{الوصف}'),
  ('capacity_warning', 'fr', '{العنوان}', '{الوصف}'),
  ('billing_downgraded', 'en', '{العنوان}', '{الوصف}'),
  ('billing_downgraded', 'tr', '{العنوان}', '{الوصف}'),
  ('billing_downgraded', 'fr', '{العنوان}', '{الوصف}')
on conflict (event_key, lang) do update set title_template = excluded.title_template, body_template = excluded.body_template;

-- {"en": {k: en}, "tr": {k: tr}, "fr": {k: fr}} - one composed var in every language
create or replace function public._i18n_var(p_key text, p_en text, p_tr text, p_fr text)
returns jsonb language sql immutable as $$
  select jsonb_build_object('en', jsonb_build_object(p_key, coalesce(p_en, '')),
                            'tr', jsonb_build_object(p_key, coalesce(p_tr, '')),
                            'fr', jsonb_build_object(p_key, coalesce(p_fr, '')));
$$;

-- the same for a title + text pair ({العنوان} / {الوصف}); a null text keeps the shared one
create or replace function public._i18n_tb(p_en_t text, p_en_b text, p_tr_t text, p_tr_b text, p_fr_t text, p_fr_b text)
returns jsonb language sql immutable as $$
  select jsonb_build_object('en', jsonb_strip_nulls(jsonb_build_object('العنوان', p_en_t, 'الوصف', p_en_b)),
                            'tr', jsonb_strip_nulls(jsonb_build_object('العنوان', p_tr_t, 'الوصف', p_tr_b)),
                            'fr', jsonb_strip_nulls(jsonb_build_object('العنوان', p_fr_t, 'الوصف', p_fr_b)));
$$;
revoke all on function public._i18n_var(text, text, text, text) from public, anon, authenticated;
revoke all on function public._i18n_tb(text, text, text, text, text, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. _notify: one rendering per language among the recipients
-- ---------------------------------------------------------------------
create or replace function public._notify(
  p_org uuid, p_users uuid[], p_event text, p_title text, p_body text, p_ref uuid,
  p_vars jsonb default null, p_include_actor boolean default false, p_dedupe text default null)
returns void language plpgsql security definer set search_path = public as $$
declare d public.notification_defaults; t public.notification_templates; x public.notification_default_texts;
        v_base jsonb; v_vars jsonb; v_title text; v_body text; v_aud text := 'source'; l record;
begin
  select * into d from public.notification_defaults where event_key = p_event;
  select * into t from public.notification_templates where organization_id = p_org and event_key = p_event;
  if d.event_key is not null then
    if t.event_key is not null and not t.is_enabled then return; end if;
    v_aud := coalesce(t.audience, d.default_audience);
  end if;
  v_base := jsonb_build_object('العنوان', coalesce(p_title, ''), 'الوصف', coalesce(p_body, '')) || (coalesce(p_vars, '{}'::jsonb) - '_i18n');

  for l in
    select public._notif_lang(p_org, u) as lang, array_agg(u) as users
      from unnest(coalesce(p_users, array[]::uuid[])) u
     where u is not null and (p_include_actor or u is distinct from auth.uid())
     group by 1
  loop
    v_vars := v_base || coalesce(p_vars -> '_i18n' -> l.lang, '{}'::jsonb);
    x := null;
    if l.lang <> 'ar' then
      select * into x from public.notification_default_texts where event_key = p_event and lang = l.lang;
    end if;
    if d.event_key is not null then
      -- the center's own wording wins, as written; else this language's default; else Arabic
      v_title := public.notification_render(coalesce(t.title_template, x.title_template, d.title_template), v_vars);
      v_body  := public.notification_render(coalesce(t.body_template, x.body_template, d.body_template), v_vars);
    else
      v_title := v_vars ->> 'العنوان'; v_body := v_vars ->> 'الوصف';
    end if;
    v_title := coalesce(nullif(btrim(v_title), ''), nullif(btrim(v_vars ->> 'العنوان'), ''),
                        case l.lang when 'en' then 'Notification' when 'tr' then 'Bildirim' when 'fr' then 'Notification' else 'إشعار' end);

    insert into public.notifications (organization_id, user_id, event_key, title, body, ref_id, dedupe_key)
    select p_org, u, p_event, v_title, nullif(v_body, ''), p_ref, case when p_dedupe is null then null else p_dedupe || '|' || u::text end
    from unnest(l.users) u
    where (v_aud = 'source' or exists (
            select 1 from public.organization_members m
            where m.organization_id = p_org and m.user_id = u and m.status = 'active'
              and m.role::text = case v_aud when 'admins' then 'admin' when 'teachers' then 'teacher' when 'students' then 'student' else 'guardian' end))
      and not exists (select 1 from public.notification_prefs pr
                      where pr.user_id = u and pr.organization_id = p_org and pr.event_key = p_event and not pr.enabled)
    on conflict do nothing;
  end loop;
end;
$$;
revoke all on function public._notify(uuid, uuid[], text, text, text, uuid, jsonb, boolean, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. the texts the database composes, per language
-- ---------------------------------------------------------------------
-- "today" / "tomorrow" / "Thursday 12/03" for a calendar date, and "at 17:30"
create or replace function public._notif_date_i18n(p_org uuid, p_date date, p_time time default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_today date := (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
        v_dow integer := extract(dow from p_date)::integer + 1; v_dm text := to_char(p_date, 'DD/MM'); v_hm text := to_char(p_time, 'HH24:MI');
begin
  return jsonb_build_object(
    'en', jsonb_build_object('التاريخ', case when p_date = v_today then 'Today' when p_date = v_today + 1 then 'Tomorrow'
                                             else (array['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'])[v_dow] || ' ' || v_dm end,
                             'الوقت', case when p_time is null then '' else 'at ' || v_hm end),
    'tr', jsonb_build_object('التاريخ', case when p_date = v_today then 'Bugün' when p_date = v_today + 1 then 'Yarın'
                                             else (array['Pazar','Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi'])[v_dow] || ' ' || v_dm end,
                             'الوقت', case when p_time is null then '' else 'saat ' || v_hm end),
    'fr', jsonb_build_object('التاريخ', case when p_date = v_today then 'Aujourd’hui' when p_date = v_today + 1 then 'Demain'
                                             else (array['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi'])[v_dow] || ' ' || v_dm end,
                             'الوقت', case when p_time is null then '' else 'à ' || v_hm end));
end;
$$;

-- "today" / "tomorrow" / "in 3 days" ahead of an event
create or replace function public._notif_when_i18n(p_days integer, p_time time default null)
returns jsonb language sql immutable as $$
  select jsonb_build_object(
    'en', jsonb_build_object('التاريخ', case when p_days <= 0 then 'Today' when p_days = 1 then 'Tomorrow' else 'In ' || p_days || ' days' end,
                             'الوقت', case when p_time is null then '' else 'at ' || to_char(p_time, 'HH24:MI') end),
    'tr', jsonb_build_object('التاريخ', case when p_days <= 0 then 'Bugün' when p_days = 1 then 'Yarın' else p_days || ' gün sonra' end,
                             'الوقت', case when p_time is null then '' else 'saat ' || to_char(p_time, 'HH24:MI') end),
    'fr', jsonb_build_object('التاريخ', case when p_days <= 0 then 'Aujourd’hui' when p_days = 1 then 'Demain' else 'Dans ' || p_days || ' jours' end,
                             'الوقت', case when p_time is null then '' else 'à ' || to_char(p_time, 'HH24:MI') end));
$$;
revoke all on function public._notif_date_i18n(uuid, date, time) from public, anon, authenticated;
revoke all on function public._notif_when_i18n(integer, time) from public, anon, authenticated;

-- the weekly summary line in one language (r = _weekly_report; null r = the plain digest from the counts)
create or replace function public._digest_text(p_lang text, r jsonb, p_n integer default 0, p_pts integer default 0, p_att_ok integer default 0, p_att_all integer default 0)
returns text language plpgsql immutable as $$
declare w jsonb := r -> 'week'; p jsonb := r -> 'previous'; g jsonb := r -> 'goal'; v_rec integer; v_pages text; v_note text; v_trend text;
begin
  if r is null then
    return case p_lang
      when 'en' then case when p_n > 0 then 'Recited ' || p_n || case when p_n = 1 then ' time' else ' times' end || ' · +' || p_pts || ' points' else 'No recitation recorded this week' end
                  || case when p_att_all > 0 then ' · present ' || p_att_ok || ' of ' || p_att_all || ' days' else '' end
      when 'tr' then case when p_n > 0 then p_n || ' kez dinletti · +' || p_pts || ' puan' else 'Bu hafta dinletme kaydedilmedi' end
                  || case when p_att_all > 0 then ' · ' || p_att_all || ' günden ' || p_att_ok || ' gün geldi' else '' end
      when 'fr' then case when p_n > 0 then 'A récité ' || p_n || ' fois · +' || p_pts || ' points' else 'Aucune récitation cette semaine' end
                  || case when p_att_all > 0 then ' · présent ' || p_att_ok || ' jours sur ' || p_att_all else '' end
      else case when p_n > 0 then 'سمّع ' || p_n || ' مرة · +' || p_pts || ' نقطة' else 'لم يُسجَّل تسميع هذا الأسبوع' end
        || case when p_att_all > 0 then ' · حضر ' || p_att_ok || ' من ' || p_att_all || ' أيام' else '' end
    end;
  end if;

  v_rec := (w ->> 'recitations')::integer;
  v_trend := public._trend((w ->> 'recitations')::numeric, (p ->> 'recitations')::numeric);
  v_pages := rtrim(to_char((w ->> 'pages')::numeric, 'FM9990.9'), '.');
  v_note := case when r -> 'note' is not null and r -> 'note' <> 'null'::jsonb then left(r -> 'note' ->> 'body', 120) end;
  return case p_lang
    when 'en' then case when v_rec > 0 then 'Recited ' || v_rec || case when v_rec = 1 then ' time' else ' times' end || v_trend else 'No recitation recorded this week' end
      || case when (w ->> 'pages')::numeric > 0 then ' · memorised ' || v_pages || case when v_pages = '1' then ' page' else ' pages' end else '' end
      || case g ->> 'status' when 'ahead' then ' · ahead of plan' when 'on_track' then ' · on plan' when 'behind' then ' · behind plan' when 'done' then ' · goal reached 🎉' else '' end
      || case when (w ->> 'days')::integer > 0 then ' · present ' || (w ->> 'present') || ' of ' || (w ->> 'days') else '' end
      || case when v_note is not null then ' · teacher’s note: ' || v_note else '' end
    when 'tr' then case when v_rec > 0 then v_rec || ' kez dinletti' || v_trend else 'Bu hafta dinletme kaydedilmedi' end
      || case when (w ->> 'pages')::numeric > 0 then ' · ' || replace(v_pages, '.', ',') || ' sayfa ezberledi' else '' end
      || case g ->> 'status' when 'ahead' then ' · planının önünde' when 'on_track' then ' · planında' when 'behind' then ' · planının gerisinde' when 'done' then ' · hedefine ulaştı 🎉' else '' end
      || case when (w ->> 'days')::integer > 0 then ' · ' || (w ->> 'days') || ' günden ' || (w ->> 'present') || ' gün geldi' else '' end
      || case when v_note is not null then ' · öğretmenin notu: ' || v_note else '' end
    when 'fr' then case when v_rec > 0 then 'A récité ' || v_rec || ' fois' || v_trend else 'Aucune récitation cette semaine' end
      || case when (w ->> 'pages')::numeric > 0 then ' · a mémorisé ' || replace(v_pages, '.', ',') || case when (w ->> 'pages')::numeric < 2 then ' page' else ' pages' end else '' end
      || case g ->> 'status' when 'ahead' then ' · en avance sur son plan' when 'on_track' then ' · dans les temps' when 'behind' then ' · en retard sur son plan' when 'done' then ' · objectif atteint 🎉' else '' end
      || case when (w ->> 'days')::integer > 0 then ' · présent ' || (w ->> 'present') || ' sur ' || (w ->> 'days') else '' end
      || case when v_note is not null then ' · remarque de l’enseignant : ' || v_note else '' end
    else case when v_rec > 0
              then 'سمّع ' || case v_rec when 1 then 'مرة واحدة' when 2 then 'مرتين'
                                 else v_rec || case when v_rec <= 10 then ' مرات' else ' مرة' end end || v_trend
              else 'لم يُسجَّل تسميع هذا الأسبوع' end
      || case when (w ->> 'pages')::numeric > 0 then ' · حفظ ' || v_pages || ' صفحة' else '' end
      || case g ->> 'status' when 'ahead' then ' · متقدّم على خطته' when 'on_track' then ' · على خطته' when 'behind' then ' · متأخر عن خطته'
                             when 'done' then ' · أتمّ هدفه 🎉' else '' end
      || case when (w ->> 'days')::integer > 0 then ' · حضر ' || (w ->> 'present') || ' من ' || (w ->> 'days') else '' end
      || case when v_note is not null then ' · ملاحظة المعلم: ' || v_note else '' end
  end;
end;
$$;
revoke all on function public._digest_text(text, jsonb, integer, integer, integer, integer) from public, anon, authenticated;

-- composed texts in the callers (bodies as before, plus their per-language vars)
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
        jsonb_build_object('العنوان', e.title, 'التاريخ', v_when, 'الوقت', v_time, 'الموقع', coalesce(e.location, ''),
          '_i18n', public._notif_when_i18n(v_days, e.starts_at)));
      v_count := v_count + 1;
    end if;
    insert into public.calendar_reminders (entry_id, for_date) values (e.id, e.start_date)
      on conflict (entry_id) do update set for_date = excluded.for_date, sent_at = now();
  end loop;
  return v_count;
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
      'الموقع', coalesce(new.location, ''), 'الوصف', coalesce(new.description, ''),
      '_i18n', public._notif_date_i18n(new.organization_id, new.start_date, new.starts_at)));
  return new;
end;
$$;

create or replace function public.request_account_deletion(p_org uuid, p_reason text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_role public.user_role; v_id uuid; v_admins uuid[]; v_name text;
begin
  v_role := public._org_role_of(p_org, auth.uid());
  if v_role is null then raise exception 'غير مصرّح'; end if;
  if exists (select 1 from public.deletion_requests where organization_id = p_org and requester_id = auth.uid() and status = 'pending') then
    raise exception 'لديك طلب قيد المراجعة بالفعل';
  end if;
  insert into public.deletion_requests (organization_id, requester_type, requester_id, target_user_id, reason)
  values (p_org, v_role::text::public.deletion_requester_type, auth.uid(), auth.uid(), nullif(left(btrim(coalesce(p_reason, '')), 500), ''))
  returning id into v_id;

  select array_agg(user_id) into v_admins from public.organization_members where organization_id = p_org and role = 'admin' and status = 'active';
  select full_name into v_name from public.profiles where id = auth.uid();
  perform public._notify(p_org, v_admins, 'deletion_request', 'طلب حذف بيانات', coalesce(v_name, 'عضو') || ' يطلب حذف حسابه وبياناته', v_id,
    jsonb_build_object('_i18n', public._i18n_tb(
      'Data deletion request', coalesce(v_name, 'A member') || ' asks to delete their account and data',
      'Veri silme talebi', coalesce(v_name, 'Bir üye') || ' hesabının ve verilerinin silinmesini istiyor',
      'Demande de suppression de données', coalesce(v_name, 'Un membre') || ' demande la suppression de son compte et de ses données')));
  return v_id;
end;
$$;

create or replace function public.review_deletion_request(p_org uuid, p_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare r public.deletion_requests%rowtype;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if p_status not in ('approved', 'rejected', 'completed') then raise exception 'حالة غير صحيحة'; end if;
  select * into r from public.deletion_requests where id = p_id and organization_id = p_org;
  if not found then raise exception 'الطلب غير موجود'; end if;
  update public.deletion_requests set status = p_status::public.deletion_status, reviewed_by = auth.uid(), reviewed_at = now() where id = p_id;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'deletion_requests', p_id, jsonb_build_object('status', p_status));
  perform public._notify(p_org, array[r.requester_id], 'deletion_reviewed',
    case p_status when 'rejected' then 'رُفض طلب حذف بياناتك' when 'approved' then 'وُوفق على طلب حذف بياناتك' else 'اكتمل حذف بياناتك' end,
    null, p_id,
    jsonb_build_object('_i18n', public._i18n_tb(
      case p_status when 'rejected' then 'Your data deletion request was declined' when 'approved' then 'Your data deletion request was approved' else 'Your data has been deleted' end, null,
      case p_status when 'rejected' then 'Veri silme talebiniz reddedildi' when 'approved' then 'Veri silme talebiniz onaylandı' else 'Verileriniz silindi' end, null,
      case p_status when 'rejected' then 'Votre demande de suppression a été refusée' when 'approved' then 'Votre demande de suppression a été acceptée' else 'Vos données ont été supprimées' end, null)));
end;
$$;

create or replace function public.admin_match_external_recitation(p_id uuid, p_student uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare r public.external_recitation_requests; v_circle uuid; v_name text; v_ach uuid; v_points integer; v_tz text;
begin
  select * into r from public.external_recitation_requests where id = p_id;
  if r.id is null then raise exception 'الطلب غير موجود'; end if;
  if not public.is_org_admin(r.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(r.organization_id);
  if r.status = 'matched' then raise exception 'رُبط هذا الطلب من قبل'; end if;
  select circle_id, full_name into v_circle, v_name from public.students_profile where id = p_student and organization_id = r.organization_id;
  if not found then raise exception 'الطالب غير موجود'; end if;
  insert into public.daily_achievements (organization_id, student_id, circle_id, achievement_type, surah_from, ayah_from, surah_to, ayah_to, grade, notes, client_ref, recorded_by, created_at)
  values (r.organization_id, p_student, v_circle, r.type::public.achievement_type, r.surah_number, r.ayah_from, r.surah_number, r.ayah_to, r.grade,
          coalesce(r.notes, 'تسميع خارجي'), r.client_ref, r.teacher_id, r.recorded_at)
  returning id, points_awarded into v_ach, v_points;
  select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = r.organization_id;
  if v_circle is not null then
    insert into public.attendance (organization_id, student_id, circle_id, session_date, status, recorded_by)
    values (r.organization_id, p_student, v_circle, (r.recorded_at at time zone v_tz)::date, 'present', r.teacher_id)
    on conflict (student_id, session_date) do nothing;
  end if;
  update public.external_recitation_requests set status = 'matched', matched_student_id = p_student, achievement_id = v_ach, reviewed_by = auth.uid(), reviewed_at = now() where id = p_id;
  perform public._notify(r.organization_id, array[r.teacher_id], 'external_reviewed', 'رُبط تسميعك الخارجي', v_name, p_id,
    jsonb_build_object('الحالة', 'رُبط تسميعك الخارجي', 'الطالب', v_name,
      '_i18n', public._i18n_var('الحالة', 'Your external recitation was matched', 'Dış dinletmeniz eşleştirildi', 'Votre récitation externe a été rattachée')));
  return jsonb_build_object('achievement_id', v_ach, 'points_awarded', coalesce(v_points, 0));
end;
$$;

create or replace function public.admin_reject_external_recitation(p_id uuid, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r public.external_recitation_requests;
begin
  select * into r from public.external_recitation_requests where id = p_id;
  if r.id is null then raise exception 'الطلب غير موجود'; end if;
  if not public.is_org_admin(r.organization_id) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(r.organization_id);
  if r.status <> 'pending' then raise exception 'رُوجع هذا الطلب من قبل'; end if;
  update public.external_recitation_requests set status = 'rejected', reject_reason = nullif(btrim(coalesce(p_reason, '')), ''), reviewed_by = auth.uid(), reviewed_at = now() where id = p_id;
  perform public._notify(r.organization_id, array[r.teacher_id], 'external_reviewed', 'رُفض تسميعك الخارجي', r.raw_student_name, p_id,
    jsonb_build_object('الحالة', 'رُفض تسميعك الخارجي', 'الطالب', r.raw_student_name,
      '_i18n', public._i18n_var('الحالة', 'Your external recitation was rejected', 'Dış dinletmeniz reddedildi', 'Votre récitation externe a été refusée')));
end;
$$;

create or replace function public.platform_review_billing_request(p_id uuid, p_decision text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r public.billing_requests; v_plan text;
begin
  perform public._plat_guard();
  select * into r from public.billing_requests where id = p_id;
  if not found then raise exception 'الطلب غير موجود'; end if;
  if r.status <> 'pending' then raise exception 'تمت مراجعة هذا الطلب مسبقًا'; end if;
  select name into v_plan from public.plans where id = r.plan_id;
  if p_decision = 'approve' then
    perform public._billing_apply(p_id);
    update public.billing_requests set review_note = nullif(btrim(coalesce(p_note, '')), '') where id = p_id;
    select * into r from public.billing_requests where id = p_id;
    perform public._notify(r.organization_id, public._org_admins(r.organization_id), 'billing_reviewed',
      'تم تأكيد الدفع ✓', 'خطة ' || v_plan || ' مفعّلة حتى ' || to_char(r.period_end, 'YYYY-MM-DD'), p_id,
      jsonb_build_object('الحالة', 'تم تأكيد الدفع', 'الخطة', v_plan, 'حتى', to_char(r.period_end, 'YYYY-MM-DD'),
        '_i18n', public._i18n_var('الحالة', 'Payment confirmed', 'Ödeme onaylandı', 'Paiement confirmé')), true);
  elsif p_decision = 'reject' then
    if nullif(btrim(coalesce(p_note, '')), '') is null then raise exception 'اكتب سبب الرفض ليظهر للمركز'; end if;
    update public.billing_requests set status = 'rejected', reviewed_by = auth.uid(), reviewed_at = now(), review_note = btrim(p_note) where id = p_id;
    perform public._notify(r.organization_id, public._org_admins(r.organization_id), 'billing_reviewed',
      'لم يُؤكَّد الدفع', btrim(p_note), p_id, jsonb_build_object('الحالة', 'لم يُؤكَّد الدفع', 'الخطة', v_plan, 'حتى', '',
        '_i18n', public._i18n_var('الحالة', 'Payment not confirmed', 'Ödeme onaylanmadı', 'Paiement non confirmé')), true);
  else
    raise exception 'قرار غير معروف';
  end if;
  perform public._plat_log('review_billing', r.organization_id::text, jsonb_build_object('request', p_id, 'decision', p_decision));
end;
$$;

-- the weekly digest: the same facts, one sentence per language
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

-- subscription and capacity alerts (0068's garden voice), in every language
create or replace function public.send_billing_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare o record; b jsonb; u jsonb; v_days integer; v_n integer := 0; v_what text; v_staff uuid[]; v_admins uuid[];
        v_free uuid := public._free_plan_id(); v_free_name text; v_left integer; v_key text; v_trial boolean; v_max text;
        v_free_en text; v_free_tr text; v_free_fr text; v_until text;
begin
  if public._platform_setting('billing_enforce', 'false') <> 'true' then return 0; end if;
  select name into v_free_name from public.plans where id = v_free;
  -- the ladder's own name in each language, unless the owner renamed the plan
  v_free_en := case when coalesce(v_free_name, 'بذرة') = 'بذرة' then 'Seed' else v_free_name end;
  v_free_tr := case when coalesce(v_free_name, 'بذرة') = 'بذرة' then 'Tohum' else v_free_name end;
  v_free_fr := case when coalesce(v_free_name, 'بذرة') = 'بذرة' then 'Graine' else v_free_name end;
  for o in select id from public.organizations where status in ('trial', 'active') loop
    b := public._billing_state(o.id);
    u := public._org_usage(o.id);
    v_staff := public._org_staff_users(o.id);
    v_admins := public._org_admins(o.id);
    v_days := (b ->> 'days_left')::integer;
    v_trial := b ->> 'kind' = 'trial';
    v_what := case b ->> 'kind' when 'trial' then 'الفترة التجريبية' else 'اشتراك المركز' end;

    -- a) expiry ahead: 60 / 30 / 7 / 3 / 1 day(s)
    if b ->> 'state' in ('trial', 'active') and v_days in (60, 30, 7, 3, 1) then
      perform public._notify(o.id, v_staff, 'billing_reminder',
        '🌿 ' || case b ->> 'kind' when 'trial' then 'تنتهي ' else 'ينتهي ' end || v_what || ' خلال '
          || case v_days when 60 then 'شهرين' when 30 then 'شهر' when 1 then 'يوم واحد' else v_days || ' أيام' end,
        case when b ->> 'kind' = 'trial' then 'اسقِ غرستك لتكبر: اختر خطتك من «الاشتراك والدفع». '
             else 'اسقِ بستانك قبل أن يعطش: جدّد من «الاشتراك والدفع». ' end
          || case when v_free is not null then 'وإلا عاد المركز إلى خطة «' || coalesce(v_free_name, 'بذرة') || '» المجانية إن كان حجمه يناسبها، أو صار للقراءة فقط'
                  else 'وإلا صار المركز للقراءة فقط' end,
        null, jsonb_build_object('_i18n', public._i18n_tb(
          '🌿 ' || case when v_trial then 'The trial ends' else 'The center’s subscription ends' end || ' in '
            || case v_days when 60 then 'two months' when 30 then 'a month' when 1 then 'one day' else v_days || ' days' end,
          case when v_trial then 'Water your sapling so it grows: choose your plan in “Subscription & payment”. '
               else 'Water your orchard before it goes thirsty: renew in “Subscription & payment”. ' end
            || case when v_free is not null then 'Otherwise the center returns to the free “' || v_free_en || '” plan if its size fits, or becomes read-only'
                    else 'Otherwise the center becomes read-only' end,
          '🌿 ' || case when v_trial then 'Deneme süresi ' else 'Merkez aboneliği ' end
            || case v_days when 60 then 'iki ay' when 30 then 'bir ay' when 1 then 'bir gün' else v_days || ' gün' end || ' içinde bitiyor',
          case when v_trial then 'Fidanınızı büyümesi için sulayın: planınızı “Abonelik ve ödeme” bölümünden seçin. '
               else 'Bahçeniz susuz kalmadan sulayın: “Abonelik ve ödeme” bölümünden yenileyin. ' end
            || case when v_free is not null then 'Aksi halde merkez, boyutu uygunsa ücretsiz “' || v_free_tr || '” planına döner ya da salt okunur olur'
                    else 'Aksi halde merkez salt okunur olur' end,
          '🌿 ' || case when v_trial then 'L’essai se termine' else 'L’abonnement du centre se termine' end || ' dans '
            || case v_days when 60 then 'deux mois' when 30 then 'un mois' when 1 then 'un jour' else v_days || ' jours' end,
          case when v_trial then 'Arrosez votre pousse pour qu’elle grandisse : choisissez votre formule dans « Abonnement et paiement ». '
               else 'Arrosez votre verger avant qu’il n’ait soif : renouvelez dans « Abonnement et paiement ». ' end
            || case when v_free is not null then 'Sinon le centre revient à la formule gratuite « ' || v_free_fr || ' » si sa taille le permet, ou passe en lecture seule'
                    else 'Sinon le centre passe en lecture seule' end)),
        true, 'billing|' || o.id || '|' || (b ->> 'until') || '|' || v_days);
      v_n := v_n + 1;
    -- b) ended, grace running
    elsif b ->> 'state' = 'grace' then
      v_until := to_char((b ->> 'grace_ends')::timestamptz, 'YYYY-MM-DD');
      perform public._notify(o.id, v_staff, 'billing_reminder',
        '🍂 ' || case b ->> 'kind' when 'trial' then 'انتهت ' else 'انتهى ' end || v_what || ' — بستانك ينتظر السقاية',
        'مهلة حتى ' || v_until || ' — جدّد من «الاشتراك والدفع» ليبقى كل شيء كما هو', null,
        jsonb_build_object('_i18n', public._i18n_tb(
          '🍂 ' || case when v_trial then 'The trial has ended' else 'The center’s subscription has ended' end || ' — your orchard is waiting to be watered',
          'Grace period until ' || v_until || ' — renew in “Subscription & payment” to keep everything as it is',
          '🍂 ' || case when v_trial then 'Deneme süresi bitti' else 'Merkez aboneliği bitti' end || ' — bahçeniz sulanmayı bekliyor',
          v_until || ' tarihine kadar ek süre — her şeyin olduğu gibi kalması için “Abonelik ve ödeme” bölümünden yenileyin',
          '🍂 ' || case when v_trial then 'L’essai est terminé' else 'L’abonnement du centre est terminé' end || ' — votre verger attend d’être arrosé',
          'Délai de grâce jusqu’au ' || v_until || ' — renouvelez dans « Abonnement et paiement » pour tout garder tel quel')),
        true, 'billing|' || o.id || '|' || (b ->> 'until') || '|grace');
      v_n := v_n + 1;
    -- c) grace over: fall back to the free plan when the center fits it
    elsif b ->> 'state' = 'expired' and v_free is not null and public._fits_plan(o.id, v_free) then
      update public.organizations set plan_id = v_free, status = 'active', updated_at = now() where id = o.id;
      perform public._notify(o.id, v_staff, 'billing_downgraded', '🌱 عاد المركز إلى خطة «' || coalesce(v_free_name, 'بذرة') || '» المجانية',
        'انتهى ' || v_what || ' — بياناتك محفوظة كلها والمركز يعمل بحدود الخطة المجانية. اسقِ بذرتك من «الاشتراك والدفع» لتكبر من جديد', null,
        jsonb_build_object('_i18n', public._i18n_tb(
          '🌱 The center is back on the free “' || v_free_en || '” plan',
          case when v_trial then 'The trial' else 'The subscription' end || ' has ended — all your data is kept and the center runs within the free plan’s limits. Water your seed in “Subscription & payment” to grow again',
          '🌱 Merkez ücretsiz “' || v_free_tr || '” planına döndü',
          case when v_trial then 'Deneme süresi' else 'Abonelik' end || ' bitti — tüm verileriniz korunuyor ve merkez ücretsiz planın sınırları içinde çalışıyor. Yeniden büyümek için “Abonelik ve ödeme” bölümünden tohumunuzu sulayın',
          '🌱 Le centre est revenu à la formule gratuite « ' || v_free_fr || ' »',
          case when v_trial then 'L’essai' else 'L’abonnement' end || ' est terminé — toutes vos données sont conservées et le centre fonctionne dans les limites de la formule gratuite. Arrosez votre graine dans « Abonnement et paiement » pour grandir à nouveau')),
        true, 'downgrade|' || o.id || '|' || (b ->> 'until'));
      insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
      values (o.id, null, 'update', 'organizations', o.id, jsonb_build_object('billing', 'downgraded_to_free'));
      v_n := v_n + 1;
      u := public._org_usage(o.id); -- the limits just changed
    end if;

    -- d) capacity: <= 5 students left, <= 1 teacher left, full
    v_left := (u ->> 'students_left')::integer;
    if v_left is not null and v_left <= 5 then
      v_max := u ->> 'max_students';
      v_key := 'cap|' || o.id || '|s|' || (u ->> 'plan_id') || '|' || v_max || '|' || case when v_left = 0 then 'full' else 'low' end;
      perform public._notify(o.id, v_staff, 'capacity_warning',
        case when v_left = 0 then '🌳 امتلأ بستانك — وصل المركز للحد الأقصى من الطلاب (' || v_max || ')'
             else '🌿 تبقى ' || public._left_text(v_left, 'طالب', 'طلاب') || ' يمكن إضافتهم ضمن خطة المركز' end,
        case when v_left = 0 then 'وسّع بستانك لطلاب جدد: انتقل لخطة أكبر من «الاشتراك والدفع»'
             else 'بستانك يكبر، ما شاء الله! اسقِه بخطة أكبر من «الاشتراك والدفع» متى احتجت' end,
        null, jsonb_build_object('_i18n', public._i18n_tb(
          case when v_left = 0 then '🌳 Your orchard is full — the center reached its student limit (' || v_max || ')'
               else '🌿 ' || v_left || case when v_left = 1 then ' more student' else ' more students' end || ' can be added on the center’s plan' end,
          case when v_left = 0 then 'Grow your orchard for new students: move to a bigger plan in “Subscription & payment”'
               else 'Your orchard is growing, ma sha Allah! Water it with a bigger plan in “Subscription & payment” whenever you need' end,
          case when v_left = 0 then '🌳 Bahçeniz doldu — merkez öğrenci sınırına ulaştı (' || v_max || ')'
               else '🌿 Merkezin planına ' || v_left || ' öğrenci daha eklenebilir' end,
          case when v_left = 0 then 'Yeni öğrenciler için bahçenizi genişletin: “Abonelik ve ödeme” bölümünden daha büyük bir plana geçin'
               else 'Bahçeniz büyüyor, maşallah! Gerektiğinde “Abonelik ve ödeme” bölümünden daha büyük bir planla sulayın' end,
          case when v_left = 0 then '🌳 Votre verger est plein — le centre a atteint sa limite d’élèves (' || v_max || ')'
               when v_left = 1 then '🌿 Encore 1 élève peut être ajouté dans la formule du centre'
               else '🌿 Encore ' || v_left || ' élèves peuvent être ajoutés dans la formule du centre' end,
          case when v_left = 0 then 'Agrandissez votre verger pour de nouveaux élèves : passez à une formule supérieure dans « Abonnement et paiement »'
               else 'Votre verger grandit, ma sha Allah ! Arrosez-le d’une formule supérieure dans « Abonnement et paiement » quand vous le souhaitez' end)),
        true, v_key);
      v_n := v_n + 1;
    end if;
    v_left := (u ->> 'teachers_left')::integer;
    if v_left is not null and v_left <= 1 then
      v_max := u ->> 'max_teachers';
      v_key := 'cap|' || o.id || '|t|' || (u ->> 'plan_id') || '|' || v_max || '|' || case when v_left = 0 then 'full' else 'low' end;
      perform public._notify(o.id, v_admins, 'capacity_warning',
        case when v_left = 0 then '🌳 وصل المركز للحد الأقصى من المعلمين (' || v_max || ')'
             else '🌿 تبقى إضافة معلم واحد فقط ضمن خطة المركز' end,
        'لتزرع حلقات جديدة: انتقل لخطة أكبر من «الاشتراك والدفع»', null,
        jsonb_build_object('_i18n', public._i18n_tb(
          case when v_left = 0 then '🌳 The center reached its teacher limit (' || v_max || ')' else '🌿 Only one more teacher can be added on the center’s plan' end,
          'To plant new circles: move to a bigger plan in “Subscription & payment”',
          case when v_left = 0 then '🌳 Merkez öğretmen sınırına ulaştı (' || v_max || ')' else '🌿 Merkezin planına yalnızca bir öğretmen daha eklenebilir' end,
          'Yeni halkalar kurmak için: “Abonelik ve ödeme” bölümünden daha büyük bir plana geçin',
          case when v_left = 0 then '🌳 Le centre a atteint sa limite d’enseignants (' || v_max || ')' else '🌿 Un seul enseignant peut encore être ajouté dans la formule du centre' end,
          'Pour planter de nouveaux cercles : passez à une formule supérieure dans « Abonnement et paiement »')),
        true, v_key);
      v_n := v_n + 1;
    end if;
  end loop;
  return v_n;
end;
$$;
revoke all on function public.send_billing_reminders() from public, anon, authenticated;

notify pgrst, 'reload schema';
