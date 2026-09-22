-- =========================================================================
-- 0048_chat_delete_and_review_prefill.sql
--   * chat: the sender can delete their own message (text and/or picture);
--     it becomes a tombstone for both sides, the picture is actually removed
--     from storage (closes the "orphaned chat images" gap)
--   * recitation: what a specific student owes the spaced-review schedule
--     today, so the recording screens can offer it as a one-tap prefill
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. chat: delete own message
-- ---------------------------------------------------------------------
alter table public.chat_messages add column if not exists deleted_at timestamptz;
-- the content-check constraint (a tombstone has neither text nor a picture) is fixed in 0049 -
-- this file was already applied with the old constraint before the gap was noticed.

-- superseded by 0050 (Supabase refuses a direct DELETE on storage.objects; that
-- migration replaces this function to return the image path for the client to
-- remove through the Storage API instead)
create or replace function public.delete_chat_message(p_message uuid)
returns void language plpgsql security definer set search_path = public as $$
declare m public.chat_messages%rowtype;
begin
  select * into m from public.chat_messages where id = p_message;
  if not found or m.sender_id <> auth.uid() then raise exception 'غير مصرّح'; end if;
  if m.deleted_at is not null then return; end if; -- already gone: quietly succeed
  update public.chat_messages set body = '', image_path = null, deleted_at = now() where id = p_message;
end;
$$;
revoke all on function public.delete_chat_message(uuid) from public, anon;
grant execute on function public.delete_chat_message(uuid) to authenticated;

-- editing a message that was deleted makes no sense
create or replace function public.edit_chat_message(p_message uuid, p_body text)
returns void language plpgsql security definer set search_path = public as $$
declare v_body text := nullif(btrim(coalesce(p_body, '')), ''); m public.chat_messages%rowtype; t public.chat_threads%rowtype;
begin
  if v_body is null or char_length(v_body) > 2000 then raise exception 'نص الرسالة غير صالح'; end if;
  select * into m from public.chat_messages where id = p_message;
  if not found or m.sender_id <> auth.uid() then raise exception 'غير مصرّح'; end if;
  if m.deleted_at is not null then raise exception 'حُذفت هذه الرسالة'; end if;
  if m.created_at < now() - interval '30 minutes' then raise exception 'انتهت مهلة تعديل الرسالة'; end if;
  select * into t from public.chat_threads where id = m.thread_id;
  if not public._can_message(t.organization_id, case when t.user_a = auth.uid() then t.user_b else t.user_a end) then
    raise exception 'لا يمكنك مراسلة هذا المستخدم'; end if;
  update public.chat_messages set body = v_body, edited_at = now() where id = p_message;
end;
$$;

-- carry deleted_at through the read paths
create or replace function public.chat_thread_messages(p_org uuid, p_thread uuid, p_after timestamptz default null, p_limit integer default 60)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not exists (select 1 from public.chat_threads where id = p_thread and organization_id = p_org
                 and (user_a = auth.uid() or user_b = auth.uid())) then
    raise exception 'لست طرفاً في هذه المحادثة';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('id', q.id, 'sender_id', q.sender_id, 'mine', q.sender_id = auth.uid(),
      'body', q.body, 'image_path', q.image_path, 'created_at', q.created_at, 'edited_at', q.edited_at, 'read_at', q.read_at,
      'deleted_at', q.deleted_at) order by q.created_at)
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
        'last_body', case when lm.deleted_at is not null then null when lm.image_path is not null and (lm.body is null or lm.body = '') then '📷 صورة' else lm.body end,
        'last_deleted', lm.deleted_at is not null,
        'last_mine', lm.sender_id = auth.uid(),
        'unread', (select count(*) from public.chat_messages m where m.thread_id = t.id and m.sender_id <> auth.uid() and m.read_at is null and m.deleted_at is null),
        'muted', coalesce(pr.muted, false),
        'can_reply', public._can_message(p_org, o.uid)) as x
      from public.chat_threads t
      cross join lateral (select case when t.user_a = auth.uid() then t.user_b else t.user_a end as uid) o
      left join public.profiles p on p.id = o.uid
      left join public.chat_thread_prefs pr on pr.thread_id = t.id and pr.user_id = auth.uid()
      left join lateral (select body, sender_id, image_path, deleted_at from public.chat_messages m where m.thread_id = t.id order by created_at desc limit 1) lm on true
      where t.organization_id = p_org and (t.user_a = auth.uid() or t.user_b = auth.uid())
    ) q
  ), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- 2. recitation: what THIS student owes the review schedule today
-- ---------------------------------------------------------------------
create or replace function public.student_due_reviews(p_org uuid, p_student uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_today date;
begin
  if not exists (select 1 from public.students_profile where id = p_student and organization_id = p_org) then
    raise exception 'الطالب غير موجود';
  end if;
  if not (public.is_org_admin(p_org) or (public.is_org_staff(p_org) and public._teaches_student(p_student))) then
    raise exception 'غير مصرّح';
  end if;
  v_today := (now() at time zone coalesce((select timezone from public.organizations where id = p_org), 'UTC'))::date;
  return coalesce((
    select jsonb_agg(jsonb_build_object('surah', m.surah_number, 'due', m.next_due_at, 'days_overdue', greatest(0, v_today - m.next_due_at)) order by m.next_due_at)
    from public.memorization_review_state m where m.organization_id = p_org and m.student_id = p_student and m.next_due_at <= v_today), '[]'::jsonb);
end;
$$;
revoke all on function public.student_due_reviews(uuid, uuid) from public, anon;
grant execute on function public.student_due_reviews(uuid, uuid) to authenticated;

notify pgrst, 'reload schema';
