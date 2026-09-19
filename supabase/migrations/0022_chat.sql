-- =========================================================================
-- 0022_chat.sql
-- محادثات مباشرة (1:1) - rebuilt to match the eqraa design, per center.
--
-- WHO MAY MESSAGE WHOM (checked in ONE function, _can_message, called by every
-- write RPC - RLS alone would only guard reads):
--   * admin      <-> anyone in the center
--   * teacher    <-> other teachers, admins, and the students / guardians of
--                    the circles they teach (teachers need the chat module)
--   * student / guardian <-> the teacher of their own (linked) student's
--                    circle, and admins
--   * never student <-> student, guardian <-> guardian, or family <-> a
--     teacher who does not teach their child.
--
-- Threads are canonical pairs (user_a < user_b), one per pair per center.
-- There is NO insert/update policy on any table: every write goes through an
-- RPC that re-checks the pair, so a sender cannot be forged and a thread
-- cannot be opened with someone the rules forbid. Sends are idempotent on
-- client_ref (a retry after a dropped response never double-sends).
--
-- The earlier group-chat tables (0005) held no production data and are
-- replaced. New messages are pushed to open clients through Supabase Realtime
-- (RLS still applies: a client only receives messages of its own threads).
-- =========================================================================

drop table if exists public.chat_messages cascade;
drop table if exists public.chat_thread_participants cascade;
drop table if exists public.chat_threads cascade;

create table public.chat_threads (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  user_a           uuid not null references auth.users (id) on delete cascade,
  user_b           uuid not null references auth.users (id) on delete cascade,
  last_message_at  timestamptz,
  created_at       timestamptz not null default now(),
  check (user_a < user_b),
  unique (organization_id, user_a, user_b)
);
create index chat_threads_a_idx on public.chat_threads (user_a, last_message_at desc);
create index chat_threads_b_idx on public.chat_threads (user_b, last_message_at desc);

create table public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  thread_id   uuid not null references public.chat_threads (id) on delete cascade,
  sender_id   uuid not null references auth.users (id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 2000),
  client_ref  uuid unique,
  created_at  timestamptz not null default now(),
  edited_at   timestamptz,
  read_at     timestamptz
);
create index chat_messages_thread_idx on public.chat_messages (thread_id, created_at desc);

create table public.chat_thread_prefs (
  thread_id  uuid not null references public.chat_threads (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  muted      boolean not null default false,
  primary key (thread_id, user_id)
);

-- ---------------------------------------------------------------------
-- 1. The rules
-- ---------------------------------------------------------------------
create or replace function public._org_role_of(p_org uuid, p_user uuid)
returns public.user_role language sql stable security definer set search_path = public as $$
  select role from public.organization_members
  where organization_id = p_org and user_id = p_user and status = 'active' limit 1;
$$;

-- Students of a student / guardian account (their own record, or their children).
create or replace function public._students_of_user(p_org uuid, p_user uuid)
returns uuid[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(s.id), array[]::uuid[])
  from public.students_profile s
  where s.organization_id = p_org
    and exists (
      select 1 from public.organization_members m
      where m.organization_id = p_org and m.user_id = p_user and m.status = 'active'
        and (m.id = s.member_id or m.id = s.guardian_member_id));
$$;

create or replace function public._teacher_has_chat(p_org uuid, p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_org and m.user_id = p_user and m.status = 'active'
      and m.role = 'teacher' and 'chat' = any (m.permissions));
$$;

-- Does this teacher teach at least one of these students?
create or replace function public._teacher_teaches_any(p_teacher uuid, p_students uuid[])
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.students_profile sp
    join public.circles c on c.id = sp.circle_id
    where sp.id = any (p_students) and c.teacher_id = p_teacher);
$$;

create or replace function public._can_message(p_org uuid, p_other uuid)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_me public.user_role; v_other public.user_role;
begin
  if auth.uid() is null or p_other is null or p_other = auth.uid() then return false; end if;
  v_me := public._org_role_of(p_org, auth.uid());
  v_other := public._org_role_of(p_org, p_other);
  if v_me is null or v_other is null then return false; end if;

  if v_me = 'admin' or v_other = 'admin' then return true; end if;
  if v_me = 'teacher' and not public._teacher_has_chat(p_org, auth.uid()) then return false; end if;
  if v_other = 'teacher' and not public._teacher_has_chat(p_org, p_other) then return false; end if;

  if v_me = 'teacher' and v_other = 'teacher' then return true; end if;
  if v_me = 'teacher' and v_other in ('student', 'guardian') then
    return public._teacher_teaches_any(auth.uid(), public._students_of_user(p_org, p_other));
  end if;
  if v_me in ('student', 'guardian') and v_other = 'teacher' then
    return public._teacher_teaches_any(p_other, public._students_of_user(p_org, auth.uid()));
  end if;
  return false;
end;
$$;

-- ---------------------------------------------------------------------
-- 2. RLS: reads for the two participants only; no write policies
-- ---------------------------------------------------------------------
alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_thread_prefs enable row level security;

create policy "chat_threads_select" on public.chat_threads for select
  using (user_a = auth.uid() or user_b = auth.uid());
create policy "chat_messages_select" on public.chat_messages for select using (
  exists (select 1 from public.chat_threads t
          where t.id = thread_id and (t.user_a = auth.uid() or t.user_b = auth.uid())));
create policy "chat_thread_prefs_select" on public.chat_thread_prefs for select using (user_id = auth.uid());

revoke insert, update, delete on public.chat_threads, public.chat_messages, public.chat_thread_prefs from authenticated;

-- Live delivery to open clients (RLS still filters what each client receives).
do $$
begin
  alter publication supabase_realtime add table public.chat_messages;
exception when others then null;
end $$;

-- ---------------------------------------------------------------------
-- 3. Contacts, threads, messages
-- ---------------------------------------------------------------------
create or replace function public.chat_contacts(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_me public.user_role;
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  v_me := public._org_role_of(p_org, auth.uid());
  if v_me = 'teacher' and not public._teacher_has_chat(p_org, auth.uid()) then raise exception 'غير مصرّح'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('user_id', m.user_id, 'name', coalesce(p.full_name, '—'), 'role', m.role,
      'detail', case
        when m.role in ('student', 'guardian') then
          (select string_agg(distinct sp.full_name, '، ') from public.students_profile sp
            where sp.id = any (public._students_of_user(p_org, m.user_id)))
        else null end) order by m.role, p.full_name)
    from public.organization_members m
    left join public.profiles p on p.id = m.user_id
    where m.organization_id = p_org and m.status = 'active' and m.user_id <> auth.uid()
      and public._can_message(p_org, m.user_id)
  ), '[]'::jsonb);
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
        'last_body', lm.body, 'last_mine', lm.sender_id = auth.uid(),
        'unread', (select count(*) from public.chat_messages m where m.thread_id = t.id and m.sender_id <> auth.uid() and m.read_at is null),
        'muted', coalesce(pr.muted, false),
        'can_reply', public._can_message(p_org, o.uid)) as x
      from public.chat_threads t
      cross join lateral (select case when t.user_a = auth.uid() then t.user_b else t.user_a end as uid) o
      left join public.profiles p on p.id = o.uid
      left join public.chat_thread_prefs pr on pr.thread_id = t.id and pr.user_id = auth.uid()
      left join lateral (select body, sender_id from public.chat_messages m where m.thread_id = t.id order by created_at desc limit 1) lm on true
      where t.organization_id = p_org and (t.user_a = auth.uid() or t.user_b = auth.uid())
    ) q
  ), '[]'::jsonb);
end;
$$;

-- Total unread across the center (for the badge on the menu).
create or replace function public.chat_unread_count(p_org uuid)
returns integer language sql stable security definer set search_path = public as $$
  select count(*)::integer from public.chat_messages m
  join public.chat_threads t on t.id = m.thread_id
  where t.organization_id = p_org and (t.user_a = auth.uid() or t.user_b = auth.uid())
    and m.sender_id <> auth.uid() and m.read_at is null;
$$;

-- Open (or preview) the conversation with someone: thread id if it exists.
create or replace function public.chat_thread_with(p_org uuid, p_other uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select id from public.chat_threads
  where organization_id = p_org
    and user_a = least(auth.uid(), p_other) and user_b = greatest(auth.uid(), p_other);
$$;

-- Latest p_limit messages (ascending), or only those after p_after (polling).
create or replace function public.chat_thread_messages(p_org uuid, p_thread uuid, p_after timestamptz default null, p_limit integer default 60)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not exists (select 1 from public.chat_threads where id = p_thread and organization_id = p_org
                 and (user_a = auth.uid() or user_b = auth.uid())) then
    raise exception 'لست طرفاً في هذه المحادثة';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', q.id, 'sender_id', q.sender_id, 'mine', q.sender_id = auth.uid(),
      'body', q.body, 'created_at', q.created_at, 'edited_at', q.edited_at, 'read_at', q.read_at) order by q.created_at)
    from (
      select * from public.chat_messages m
      where m.thread_id = p_thread and (p_after is null or m.created_at > p_after)
      order by m.created_at desc limit greatest(1, least(coalesce(p_limit, 60), 200))
    ) q), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- 4. Writes
-- ---------------------------------------------------------------------
create or replace function public.send_chat_message(p_org uuid, p_other uuid, p_body text, p_client_ref uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_body text := nullif(btrim(coalesce(p_body, '')), ''); v_a uuid; v_b uuid; v_thread uuid; v_msg uuid;
begin
  if v_body is null then raise exception 'الرسالة فارغة'; end if;
  if char_length(v_body) > 2000 then raise exception 'الرسالة طويلة جدًا — 2000 حرف كحد أقصى'; end if;
  if not public._can_message(p_org, p_other) then raise exception 'لا يمكنك مراسلة هذا المستخدم'; end if;

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

  insert into public.chat_messages (thread_id, sender_id, body, client_ref)
  values (v_thread, auth.uid(), v_body, p_client_ref) returning id into v_msg;
  update public.chat_threads set last_message_at = now() where id = v_thread;
  return jsonb_build_object('message_id', v_msg, 'thread_id', v_thread, 'duplicate', false);
end;
$$;

-- The sender may correct a message for 30 minutes (and only while the pair may still talk).
create or replace function public.edit_chat_message(p_message uuid, p_body text)
returns void language plpgsql security definer set search_path = public as $$
declare v_body text := nullif(btrim(coalesce(p_body, '')), ''); m public.chat_messages%rowtype; t public.chat_threads%rowtype;
begin
  if v_body is null or char_length(v_body) > 2000 then raise exception 'نص الرسالة غير صالح'; end if;
  select * into m from public.chat_messages where id = p_message;
  if not found or m.sender_id <> auth.uid() then raise exception 'غير مصرّح'; end if;
  if m.created_at < now() - interval '30 minutes' then raise exception 'انتهت مهلة تعديل الرسالة'; end if;
  select * into t from public.chat_threads where id = m.thread_id;
  if not public._can_message(t.organization_id, case when t.user_a = auth.uid() then t.user_b else t.user_a end) then
    raise exception 'لا يمكنك مراسلة هذا المستخدم'; end if;
  update public.chat_messages set body = v_body, edited_at = now() where id = p_message;
end;
$$;

create or replace function public.mark_thread_read(p_thread uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.chat_threads where id = p_thread and (user_a = auth.uid() or user_b = auth.uid())) then
    raise exception 'لست طرفاً في هذه المحادثة'; end if;
  update public.chat_messages set read_at = now()
   where thread_id = p_thread and sender_id <> auth.uid() and read_at is null;
end;
$$;

create or replace function public.set_thread_muted(p_thread uuid, p_muted boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.chat_threads where id = p_thread and (user_a = auth.uid() or user_b = auth.uid())) then
    raise exception 'لست طرفاً في هذه المحادثة'; end if;
  insert into public.chat_thread_prefs (thread_id, user_id, muted) values (p_thread, auth.uid(), coalesce(p_muted, false))
  on conflict (thread_id, user_id) do update set muted = excluded.muted;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. Grants (0018 policy)
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
-- chat internals
revoke execute on function public._org_role_of(uuid, uuid) from authenticated;
revoke execute on function public._students_of_user(uuid, uuid) from authenticated;
revoke execute on function public._teacher_has_chat(uuid, uuid) from authenticated;
revoke execute on function public._teacher_teaches_any(uuid, uuid[]) from authenticated;
