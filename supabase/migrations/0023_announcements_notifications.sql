-- =========================================================================
-- 0023_announcements_notifications.sql
-- الإعلانات وصندوق الإشعارات - rebuilt to match the eqraa design, per center.
--
-- ANNOUNCEMENTS. Audience is role (+ optionally one circle). Reads go through
-- list_announcements, which applies the audience rules on the server (a
-- student must never read a teachers-only announcement). Admins publish for
-- anyone; a teacher with the announcements module may publish only to the
-- families of a circle they teach. Publishing notifies the audience once.
--
-- NOTIFICATIONS. A per-user in-app inbox fed by events (announcement,
-- serd assigned/reviewed, market order decided, waiting-list promotion, new
-- calendar entry, badge awarded). Each person can switch an event type off.
-- Delivery to a phone (push) needs a Firebase project and is layered on top
-- later: device tokens are already stored, and the inbox row is the source of
-- truth either way.
--
-- The earlier simplified tables (0005) held no production data and are
-- replaced.
-- =========================================================================

drop table if exists public.notification_log cascade;
drop table if exists public.notification_prefs cascade;
drop table if exists public.notification_templates cascade;
drop table if exists public.announcements cascade;
drop type if exists public.notification_channel;

-- ---------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------
create table public.announcements (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  title            text not null,
  body             text not null,
  audience         text not null default 'all' check (audience in ('all', 'teachers', 'students', 'guardians')),
  circle_id        uuid references public.circles (id) on delete cascade,
  pinned           boolean not null default false,
  published_at     timestamptz,            -- null = draft
  expires_on       date,
  created_by       uuid references auth.users (id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index announcements_org_idx on public.announcements (organization_id, published_at desc);

create table public.notifications (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  user_id          uuid not null references auth.users (id) on delete cascade,
  event_key        text not null,
  title            text not null,
  body             text,
  ref_id           uuid,                    -- the entity it is about (client maps it to a screen)
  created_at       timestamptz not null default now(),
  read_at          timestamptz
);
create index notifications_user_idx on public.notifications (user_id, organization_id, created_at desc);

create table public.notification_prefs (
  user_id          uuid not null references auth.users (id) on delete cascade,
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  event_key        text not null,
  enabled          boolean not null default true,
  primary key (user_id, organization_id, event_key)
);

alter table public.announcements enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_prefs enable row level security;

-- Announcements are read through list_announcements only (audience is enforced
-- there); the notifications table is a person's own inbox.
create policy "notifications_select_own" on public.notifications for select using (user_id = auth.uid());
create policy "notification_prefs_select_own" on public.notification_prefs for select using (user_id = auth.uid());
revoke all on public.announcements from authenticated;
revoke insert, update, delete on public.notifications, public.notification_prefs from authenticated;

-- device_tokens (0005) stays as is: it is what push delivery will read.

-- ---------------------------------------------------------------------
-- 2. Recipients + delivery primitives
-- ---------------------------------------------------------------------
-- Users of the students of a circle / stage / everyone (student + guardian accounts).
create or replace function public._family_users(p_org uuid, p_role text, p_circle uuid, p_stage uuid)
returns uuid[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(distinct m.user_id), array[]::uuid[])
  from public.students_profile s
  left join public.circles c on c.id = s.circle_id
  join public.organization_members m on m.organization_id = p_org and m.status = 'active'
    and ((p_role in ('student', 'both') and m.id = s.member_id) or (p_role in ('guardian', 'both') and m.id = s.guardian_member_id))
  where s.organization_id = p_org and s.status = 'active'
    and (p_circle is null or s.circle_id = p_circle)
    and (p_stage is null or c.stage_id = p_stage);
$$;

create or replace function public._audience_users(p_org uuid, p_audience text, p_circle uuid, p_stage uuid)
returns uuid[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(distinct u), array[]::uuid[]) from (
    -- staff
    select m.user_id as u from public.organization_members m
     where m.organization_id = p_org and m.status = 'active'
       and ((m.role = 'admin')
         or (m.role = 'teacher' and p_audience in ('all', 'teachers')
             and (p_circle is null or exists (select 1 from public.circles c where c.id = p_circle and c.teacher_id = m.user_id))))
    union
    select unnest(public._family_users(p_org,
      case p_audience when 'students' then 'student' when 'guardians' then 'guardian' when 'all' then 'both' else 'none' end,
      p_circle, p_stage))
  ) q;
$$;

-- Users of one student's account + their guardian.
create or replace function public._student_family_users(p_student uuid)
returns uuid[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(distinct m.user_id), array[]::uuid[])
  from public.students_profile s
  join public.organization_members m on m.status = 'active' and (m.id = s.member_id or m.id = s.guardian_member_id)
  where s.id = p_student;
$$;

-- Insert one inbox row per user (skipping the actor and anyone who muted this event).
create or replace function public._notify(p_org uuid, p_users uuid[], p_event text, p_title text, p_body text, p_ref uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (organization_id, user_id, event_key, title, body, ref_id)
  select p_org, u, p_event, p_title, p_body, p_ref
  from unnest(coalesce(p_users, array[]::uuid[])) u
  where u is distinct from auth.uid()
    and not exists (select 1 from public.notification_prefs pr
                    where pr.user_id = u and pr.organization_id = p_org and pr.event_key = p_event and not pr.enabled);
end;
$$;

-- ---------------------------------------------------------------------
-- 3. Announcements
-- ---------------------------------------------------------------------
create or replace function public.save_announcement(
  p_org uuid, p_id uuid, p_title text, p_body text, p_audience text, p_circle uuid,
  p_pinned boolean, p_publish boolean, p_expires date
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id; v_admin boolean := public.is_org_admin(p_org); v_prev timestamptz; v_creator uuid; v_published timestamptz;
begin
  if nullif(btrim(coalesce(p_title, '')), '') is null or nullif(btrim(coalesce(p_body, '')), '') is null then
    raise exception 'العنوان والنص مطلوبان'; end if;
  if p_audience not in ('all', 'teachers', 'students', 'guardians') then raise exception 'جمهور غير معروف'; end if;
  if p_circle is not null and not exists (select 1 from public.circles where id = p_circle and organization_id = p_org) then
    raise exception 'الحلقة غير موجودة'; end if;

  if not v_admin then
    -- a teacher (announcements module) may address only the families of a circle they teach
    if not (public.is_org_staff(p_org) and public.member_has_module(p_org, 'announcements')) then raise exception 'غير مصرّح'; end if;
    if p_circle is null or not exists (select 1 from public.circles where id = p_circle and teacher_id = auth.uid()) then
      raise exception 'اختر إحدى حلقاتك'; end if;
    if p_audience = 'teachers' then raise exception 'غير مصرّح'; end if;
  end if;

  if v_id is not null then
    select published_at, created_by into v_prev, v_creator from public.announcements where id = v_id and organization_id = p_org;
    if not found then raise exception 'الإعلان غير موجود'; end if;
    if not v_admin and v_creator is distinct from auth.uid() then raise exception 'غير مصرّح'; end if;
  end if;

  v_published := case when p_publish then coalesce(v_prev, now()) else null end;
  if v_id is null then
    insert into public.announcements (organization_id, title, body, audience, circle_id, pinned, published_at, expires_on, created_by)
    values (p_org, btrim(p_title), btrim(p_body), p_audience, p_circle, coalesce(p_pinned, false), v_published, p_expires, auth.uid())
    returning id into v_id;
  else
    update public.announcements set title = btrim(p_title), body = btrim(p_body), audience = p_audience, circle_id = p_circle,
      pinned = coalesce(p_pinned, false), published_at = v_published, expires_on = p_expires, updated_at = now()
    where id = v_id;
  end if;

  -- notify once, on the first publish
  if p_publish and v_prev is null then
    perform public._notify(p_org, public._audience_users(p_org, p_audience, p_circle, null), 'announcement',
                           btrim(p_title), left(btrim(p_body), 140), v_id);
  end if;
  return v_id;
end;
$$;

create or replace function public.delete_announcement(p_org uuid, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_creator uuid;
begin
  select created_by into v_creator from public.announcements where id = p_id and organization_id = p_org;
  if not found then return; end if;
  if not (public.is_org_admin(p_org) or v_creator = auth.uid()) then raise exception 'غير مصرّح'; end if;
  delete from public.announcements where id = p_id;
end;
$$;

create or replace function public.list_announcements(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_role public.user_role; v_admin boolean; v_linked uuid[];
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  v_admin := public.is_org_admin(p_org);
  v_role := public._org_role_of(p_org, auth.uid());
  v_linked := public.linked_student_ids(p_org);
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', a.id, 'title', a.title, 'body', a.body, 'audience', a.audience,
        'circle_id', a.circle_id, 'circle_name', c.name, 'pinned', a.pinned, 'published_at', a.published_at,
        'expires_on', a.expires_on, 'draft', a.published_at is null,
        'author', pr.full_name, 'mine', a.created_by = auth.uid(),
        'can_edit', v_admin or a.created_by = auth.uid())
      order by a.pinned desc, coalesce(a.published_at, a.created_at) desc)
    from public.announcements a
    left join public.circles c on c.id = a.circle_id
    left join public.profiles pr on pr.id = a.created_by
    where a.organization_id = p_org
      and (
        v_admin
        or a.created_by = auth.uid()
        or (a.published_at is not null and (a.expires_on is null or a.expires_on >= current_date) and (
              (v_role = 'teacher' and a.audience in ('all', 'teachers')
                 and (a.circle_id is null or exists (select 1 from public.circles ci where ci.id = a.circle_id and ci.teacher_id = auth.uid())))
              or (v_role in ('student', 'guardian')
                 and (a.audience = 'all' or (a.audience = 'students' and v_role = 'student') or (a.audience = 'guardians' and v_role = 'guardian'))
                 and (a.circle_id is null or exists (select 1 from public.students_profile sp where sp.id = any (v_linked) and sp.circle_id = a.circle_id)))
        ))
      )
  ), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- 4. Inbox RPCs
-- ---------------------------------------------------------------------
create or replace function public.my_notifications(p_org uuid, p_limit integer default 60)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', n.id, 'event_key', n.event_key, 'title', n.title, 'body', n.body,
           'ref_id', n.ref_id, 'created_at', n.created_at, 'read', n.read_at is not null) order by n.created_at desc), '[]'::jsonb)
  from (select * from public.notifications where user_id = auth.uid() and organization_id = p_org
        order by created_at desc limit greatest(1, least(coalesce(p_limit, 60), 200))) n;
$$;

create or replace function public.unread_notifications_count(p_org uuid)
returns integer language sql stable security definer set search_path = public as $$
  select count(*)::integer from public.notifications where user_id = auth.uid() and organization_id = p_org and read_at is null;
$$;

create or replace function public.mark_notifications_read(p_org uuid, p_ids uuid[] default null)
returns void language sql security definer set search_path = public as $$
  update public.notifications set read_at = now()
  where user_id = auth.uid() and organization_id = p_org and read_at is null and (p_ids is null or id = any (p_ids));
$$;

create or replace function public.my_notification_prefs(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_object_agg(event_key, enabled), '{}'::jsonb)
  from public.notification_prefs where user_id = auth.uid() and organization_id = p_org;
$$;

create or replace function public.set_notification_pref(p_org uuid, p_event text, p_enabled boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  insert into public.notification_prefs (user_id, organization_id, event_key, enabled)
  values (auth.uid(), p_org, p_event, coalesce(p_enabled, true))
  on conflict (user_id, organization_id, event_key) do update set enabled = excluded.enabled;
end;
$$;

-- The phone registers its push token here (delivery is layered on later).
create or replace function public.register_device_token(p_org uuid, p_token text, p_platform text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  if p_platform not in ('ios', 'android', 'web') or nullif(btrim(coalesce(p_token, '')), '') is null then
    raise exception 'بيانات غير صالحة'; end if;
  insert into public.device_tokens (user_id, organization_id, token, platform) values (auth.uid(), p_org, p_token, p_platform)
  on conflict (token) do update set user_id = auth.uid(), organization_id = p_org, platform = p_platform;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. Event triggers -> inbox rows
-- ---------------------------------------------------------------------
-- A serd task assigned to a teacher.
create or replace function public.trg_notify_serd()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' and new.status = 'scheduled' and new.assigned_teacher_id is not null then
    perform public._notify(new.organization_id, array[new.assigned_teacher_id], 'serd_assigned',
      'سرد مطلوب منك', new.student_name, new.id);
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status and new.student_id is not null then
    if new.status = 'approved' then
      perform public._notify(new.organization_id, public._student_family_users(new.student_id), 'serd_reviewed',
        'تم اعتماد سردك', coalesce(new.score_percent::text || '%', ''), new.id);
    elsif new.status = 'rejected' then
      perform public._notify(new.organization_id, public._student_family_users(new.student_id), 'serd_reviewed',
        'لم يُعتمد السرد', coalesce(new.reject_reason, ''), new.id);
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_notify_serd on public.serd_sessions;
create trigger trg_notify_serd after insert or update of status on public.serd_sessions
  for each row execute function public.trg_notify_serd();

-- A market order decided by staff.
create or replace function public.trg_notify_purchase()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status and new.status in ('fulfilled', 'cancelled') then
    perform public._notify(new.organization_id, public._student_family_users(new.student_id), 'market_order',
      case new.status when 'fulfilled' then 'تم تسليم طلبك' else 'أُلغي طلبك' end, new.item_name, new.id);
  end if;
  return new;
end;
$$;
drop trigger if exists trg_notify_purchase on public.market_purchases;
create trigger trg_notify_purchase after update of status on public.market_purchases
  for each row execute function public.trg_notify_purchase();

-- Promoted from the waiting list.
create or replace function public.trg_notify_waitlist()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_title text; v_org uuid;
begin
  if new.status = 'promoted' and old.status is distinct from 'promoted' then
    select title, organization_id into v_title, v_org from public.center_calendar where id = new.entry_id;
    perform public._notify(v_org, public._student_family_users(new.student_id), 'waitlist_promoted',
      'تم تسجيلك بعد الانتظار', v_title, new.entry_id);
  end if;
  return new;
end;
$$;
drop trigger if exists trg_notify_waitlist on public.calendar_waitlist;
create trigger trg_notify_waitlist after update of status on public.calendar_waitlist
  for each row execute function public.trg_notify_waitlist();

-- A new calendar entry reaches its audience.
create or replace function public.trg_notify_calendar()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_supports boolean;
begin
  perform public._notify(new.organization_id, public._audience_users(new.organization_id, new.audience, new.circle_id, new.stage_id),
    'calendar_entry',
    case when not new.is_working_day then 'إجازة / إغلاق: ' || new.title else 'جديد في التقويم: ' || new.title end,
    new.start_date::text, new.id);
  return new;
end;
$$;
drop trigger if exists trg_notify_calendar on public.center_calendar;
create trigger trg_notify_calendar after insert on public.center_calendar
  for each row execute function public.trg_notify_calendar();

-- A badge awarded (automatic or by hand).
create or replace function public.trg_notify_badge()
returns trigger language plpgsql security definer set search_path = public as $$
declare b public.badges%rowtype; v_org uuid;
begin
  select * into b from public.badges where id = new.badge_id;
  perform public._notify(b.organization_id, public._student_family_users(new.student_id), 'badge_awarded',
    'شارة جديدة: ' || b.name, b.description, new.badge_id);
  return new;
end;
$$;
drop trigger if exists trg_notify_badge on public.student_badges;
create trigger trg_notify_badge after insert on public.student_badges
  for each row execute function public.trg_notify_badge();

-- ---------------------------------------------------------------------
-- 6. Grants (0018 policy)
-- ---------------------------------------------------------------------
revoke all on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated, service_role;
grant execute on function public.get_invitation(uuid) to anon;
revoke execute on function public.consent_info(uuid) from authenticated;
revoke execute on function public.consent_answer(uuid, text) from authenticated;
revoke execute on function public._insert_registration(uuid, uuid, text, uuid, text) from authenticated;
revoke execute on function public._promote_waitlist(uuid) from authenticated;
revoke execute on function public._calendar_entry_json(uuid) from authenticated;
revoke execute on function public._serd_write_parts(uuid, uuid, uuid, jsonb) from authenticated;
revoke execute on function public._serd_write_errors(uuid, uuid, jsonb) from authenticated;
revoke execute on function public._assert_serd_grader(uuid) from authenticated;
revoke execute on function public._serd_parts_json(uuid) from authenticated;
revoke execute on function public._serd_row_json(uuid) from authenticated;
revoke execute on function public._sync_wallet(uuid, uuid) from authenticated;
revoke execute on function public._currency_block(uuid) from authenticated;
revoke execute on function public._currency_spent(uuid) from authenticated;
revoke execute on function public._set_purchase_status(uuid, text) from authenticated;
revoke execute on function public._evaluate_badges(uuid) from authenticated;
revoke execute on function public._badge_progress(public.badges, uuid) from authenticated;
revoke execute on function public._recitation_streak(uuid, text) from authenticated;
revoke execute on function public._org_role_of(uuid, uuid) from authenticated;
revoke execute on function public._students_of_user(uuid, uuid) from authenticated;
revoke execute on function public._teacher_has_chat(uuid, uuid) from authenticated;
revoke execute on function public._teacher_teaches_any(uuid, uuid[]) from authenticated;
-- notification internals
revoke execute on function public._family_users(uuid, text, uuid, uuid) from authenticated;
revoke execute on function public._audience_users(uuid, text, uuid, uuid) from authenticated;
revoke execute on function public._student_family_users(uuid) from authenticated;
revoke execute on function public._notify(uuid, uuid[], text, text, text, uuid) from authenticated;
