-- =========================================================================
-- 0030_chat_images_event_reminders.sql
-- A. Chat images: a private Storage bucket; a message may carry one image.
--    The file lives at  <org>/<uploader>/<file>  so it can be uploaded BEFORE
--    the thread exists (the first message of a conversation may be a picture).
--    Storage policies: you may upload only into your own folder of a center you
--    belong to (and not as a viewing account); you may read a file if it is
--    yours or is attached to a message of a thread you are in.
-- B. Event reminders: a job (pg_cron, every 15 minutes) puts a reminder in the
--    inbox of every registered student's family N hours before an event starts
--    (N per center, 0 = off). One reminder per entry and start date.
-- =========================================================================

-- ---------------------------------------------------------------------
-- A. chat images
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-images', 'chat-images', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

alter table public.chat_messages add column if not exists image_path text;

do $$
declare c text;
begin
  for c in select conname from pg_constraint
           where conrelid = 'public.chat_messages'::regclass and contype = 'c' and pg_get_constraintdef(oid) ilike '%char_length%'
  loop
    execute format('alter table public.chat_messages drop constraint %I', c);
  end loop;
end $$;
alter table public.chat_messages alter column body set default '';
alter table public.chat_messages add constraint chat_messages_content_check
  check (char_length(body) <= 2000 and (char_length(body) >= 1 or image_path is not null));

-- Storage policies run with the caller's rights, so these two helpers must be
-- executable by authenticated; they only answer about the caller.
create or replace function public._chat_upload_ok(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
     and coalesce(array_length(string_to_array(p_name, '/'), 1), 0) = 3
     and split_part(p_name, '/', 2) = auth.uid()::text
     and split_part(p_name, '/', 1) ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     and public.is_org_member(split_part(p_name, '/', 1)::uuid)
     and not public._is_read_only(split_part(p_name, '/', 1)::uuid);
$$;

create or replace function public._chat_image_visible(p_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (
    split_part(p_name, '/', 2) = auth.uid()::text
    or exists (select 1 from public.chat_messages m join public.chat_threads t on t.id = m.thread_id
               where m.image_path = p_name and auth.uid() in (t.user_a, t.user_b)));
$$;

grant execute on function public._chat_upload_ok(text), public._chat_image_visible(text) to authenticated;

drop policy if exists "chat_images_select" on storage.objects;
drop policy if exists "chat_images_insert" on storage.objects;
create policy "chat_images_select" on storage.objects for select to authenticated
  using (bucket_id = 'chat-images' and public._chat_image_visible(name));
create policy "chat_images_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'chat-images' and public._chat_upload_ok(name));

drop function if exists public.send_chat_message(uuid, uuid, text, uuid);
create or replace function public.send_chat_message(
  p_org uuid, p_other uuid, p_body text, p_client_ref uuid default null, p_image_path text default null
) returns jsonb language plpgsql security definer set search_path = public as $$
declare v_body text := nullif(btrim(coalesce(p_body, '')), ''); v_a uuid; v_b uuid; v_thread uuid; v_msg uuid;
        v_image text := nullif(btrim(coalesce(p_image_path, '')), '');
begin
  if v_body is null and v_image is null then raise exception 'الرسالة فارغة'; end if;
  if char_length(coalesce(v_body, '')) > 2000 then raise exception 'الرسالة طويلة جدًا — 2000 حرف كحد أقصى'; end if;
  if not public._can_message(p_org, p_other) then raise exception 'لا يمكنك مراسلة هذا المستخدم'; end if;
  if v_image is not null then
    if left(v_image, char_length(p_org::text || '/' || auth.uid()::text || '/')) <> p_org::text || '/' || auth.uid()::text || '/'
       or not exists (select 1 from storage.objects o where o.bucket_id = 'chat-images' and o.name = v_image) then
      raise exception 'الصورة غير صالحة';
    end if;
  end if;

  -- a retry of the same send is a success, not a duplicate
  if p_client_ref is not null then
    select m.id, m.thread_id into v_msg, v_thread from public.chat_messages m where m.client_ref = p_client_ref;
    if v_msg is not null then
      return jsonb_build_object('message_id', v_msg, 'thread_id', v_thread, 'duplicate', true);
    end if;
  end if;

  v_a := least(auth.uid(), p_other);
  v_b := greatest(auth.uid(), p_other);
  insert into public.chat_threads (organization_id, user_a, user_b) values (p_org, v_a, v_b)
    on conflict (organization_id, user_a, user_b) do nothing;
  select id into v_thread from public.chat_threads where organization_id = p_org and user_a = v_a and user_b = v_b;

  insert into public.chat_messages (thread_id, sender_id, body, client_ref, image_path)
  values (v_thread, auth.uid(), coalesce(v_body, ''), p_client_ref, v_image) returning id into v_msg;
  update public.chat_threads set last_message_at = now() where id = v_thread;
  return jsonb_build_object('message_id', v_msg, 'thread_id', v_thread, 'duplicate', false);
end;
$$;

create or replace function public.chat_thread_messages(p_org uuid, p_thread uuid, p_after timestamptz default null, p_limit integer default 60)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not exists (select 1 from public.chat_threads where id = p_thread and organization_id = p_org
                 and (user_a = auth.uid() or user_b = auth.uid())) then
    raise exception 'لست طرفاً في هذه المحادثة';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', q.id, 'sender_id', q.sender_id, 'mine', q.sender_id = auth.uid(),
      'body', q.body, 'image_path', q.image_path, 'created_at', q.created_at, 'edited_at', q.edited_at, 'read_at', q.read_at) order by q.created_at)
    from (
      select * from public.chat_messages m
      where m.thread_id = p_thread and (p_after is null or m.created_at > p_after)
      order by m.created_at desc limit greatest(1, least(coalesce(p_limit, 60), 200))
    ) q), '[]'::jsonb);
end;
$$;

create or replace function public.chat_threads_list(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  return coalesce((
    select jsonb_agg(x order by (x->>'last_message_at') desc nulls last)
    from (
      select jsonb_build_object(
        'thread_id', t.id, 'other_id', o.uid, 'other_name', coalesce(p.full_name, '—'),
        'other_role', public._org_role_of(p_org, o.uid),
        'last_message_at', t.last_message_at,
        'last_body', case when lm.body = '' and lm.image_path is not null then '📷 صورة' else lm.body end,
        'last_mine', lm.sender_id = auth.uid(),
        'unread', (select count(*) from public.chat_messages m where m.thread_id = t.id and m.sender_id <> auth.uid() and m.read_at is null),
        'muted', coalesce(pr.muted, false),
        'can_reply', public._can_message(p_org, o.uid)) as x
      from public.chat_threads t
      cross join lateral (select case when t.user_a = auth.uid() then t.user_b else t.user_a end as uid) o
      left join public.profiles p on p.id = o.uid
      left join public.chat_thread_prefs pr on pr.thread_id = t.id and pr.user_id = auth.uid()
      left join lateral (select body, image_path, sender_id from public.chat_messages m where m.thread_id = t.id order by created_at desc limit 1) lm on true
      where t.organization_id = p_org and (t.user_a = auth.uid() or t.user_b = auth.uid())
    ) q
  ), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- B. event reminders
-- ---------------------------------------------------------------------
create table if not exists public.calendar_reminders (
  entry_id  uuid primary key references public.center_calendar (id) on delete cascade,
  for_date  date not null,           -- the start date it was sent for (a moved event is reminded again)
  sent_at   timestamptz not null default now()
);
alter table public.calendar_reminders enable row level security;
revoke all on public.calendar_reminders from anon, authenticated;

create or replace function public.send_calendar_reminders()
returns integer language plpgsql security definer set search_path = public as $$
declare e record; v_hours integer; v_start timestamptz; v_users uuid[]; v_when text; v_time text; v_count integer := 0; v_tz text; v_days integer;
begin
  for e in
    select c.*, coalesce(o.timezone, 'UTC') as tz
    from public.center_calendar c join public.organizations o on o.id = c.organization_id
    where c.is_working_day and c.start_date between current_date - 1 and current_date + 9
  loop
    v_tz := e.tz;
    v_hours := case when public.org_setting(e.organization_id, 'calendar_reminder_hours', '24') ~ '^[0-9]{1,3}$'
                    then public.org_setting(e.organization_id, 'calendar_reminder_hours', '24')::integer else 24 end;
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
    v_time := case when e.starts_at is not null then ' الساعة ' || to_char(e.starts_at, 'HH24:MI') else '' end;

    if coalesce(array_length(v_users, 1), 0) > 0 then
      perform public._notify(e.organization_id, v_users, 'event_reminder', 'تذكير: ' || e.title,
        v_when || v_time || coalesce(' · ' || nullif(e.location, ''), ''), e.id);
      v_count := v_count + 1;
    end if;
    insert into public.calendar_reminders (entry_id, for_date) values (e.id, e.start_date)
      on conflict (entry_id) do update set for_date = excluded.for_date, sent_at = now();
  end loop;
  return v_count;
end;
$$;

create or replace function public.get_reminder_hours(p_org uuid)
returns integer language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return case when public.org_setting(p_org, 'calendar_reminder_hours', '24') ~ '^[0-9]{1,3}$'
              then public.org_setting(p_org, 'calendar_reminder_hours', '24')::integer else 24 end;
end;
$$;

create or replace function public.set_reminder_hours(p_org uuid, p_hours integer)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  if p_hours is null or p_hours < 0 or p_hours > 168 then raise exception 'المدة من 0 (إيقاف) إلى 168 ساعة'; end if;
  insert into public.organization_settings (organization_id, key, value, updated_at)
  values (p_org, 'calendar_reminder_hours', p_hours::text, now())
  on conflict (organization_id, key) do update set value = excluded.value, updated_at = now();
end;
$$;

create extension if not exists pg_cron;
select cron.schedule('calendar-reminders', '*/15 * * * *', 'select public.send_calendar_reminders()');

-- ---------------------------------------------------------------------
-- privileges
-- ---------------------------------------------------------------------
revoke all on function public.send_chat_message(uuid, uuid, text, uuid, text) from public, anon;
revoke all on function public.chat_thread_messages(uuid, uuid, timestamptz, integer) from public, anon;
revoke all on function public.chat_threads_list(uuid) from public, anon;
revoke all on function public.get_reminder_hours(uuid) from public, anon;
revoke all on function public.set_reminder_hours(uuid, integer) from public, anon;
grant execute on function public.send_chat_message(uuid, uuid, text, uuid, text) to authenticated;
grant execute on function public.chat_thread_messages(uuid, uuid, timestamptz, integer) to authenticated;
grant execute on function public.chat_threads_list(uuid) to authenticated;
grant execute on function public.get_reminder_hours(uuid) to authenticated;
grant execute on function public.set_reminder_hours(uuid, integer) to authenticated;
revoke all on function public.send_calendar_reminders() from public, anon, authenticated;
revoke all on function public._chat_upload_ok(text) from public, anon;
revoke all on function public._chat_image_visible(text) from public, anon;

grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
