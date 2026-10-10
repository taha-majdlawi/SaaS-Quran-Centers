-- =========================================================================
-- 0091_chat_image_retention_storage_quota.sql
--
-- 1. Chat images are not kept forever either: after the number of days the
--    center's admin chose (90 by default, or never) a picture sent in a
--    conversation is deleted; the message stays and says so. Same daily job
--    as the recordings (0090): the web app deletes the files through the
--    Storage API and reports back.
--
-- 2. Storage space per plan: plans.limits.storage_mb (empty = unlimited),
--    set by the platform owner with the other limits. A center's usage is
--    the size of every file under its id in every bucket (recordings, chat
--    images, logo, market and calendar images). A full center cannot upload
--    more (a restrictive insert policy on storage.objects); the admin sees
--    the meter on the billing page, the owner on the center's page. The
--    marketing site's public_plans() does not include it.
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. chat images
-- ---------------------------------------------------------------------
alter table public.organizations
  add column if not exists chat_image_days integer default 90
  check (chat_image_days is null or chat_image_days between 7 and 3650);
comment on column public.organizations.chat_image_days is 'Days a chat picture is kept (null = never deleted).';

alter table public.chat_messages add column if not exists image_deleted_at timestamptz;
alter table public.chat_messages drop constraint if exists chat_messages_content_check;
alter table public.chat_messages add constraint chat_messages_content_check
  check (char_length(body) <= 2000 and (char_length(body) >= 1 or image_path is not null or deleted_at is not null or image_deleted_at is not null));

-- the admin's two choices at once: {audio_days, chat_days} (null = keep)
create or replace function public.media_retention(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة لمدير المركز'; end if;
  return (select jsonb_build_object('audio_days', recitation_audio_days, 'chat_days', chat_image_days) from public.organizations where id = p_org);
end;
$$;

create or replace function public.set_chat_image_days(p_org uuid, p_days integer)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذا الإجراء لمدير المركز'; end if;
  perform public._assert_can_write(p_org);
  if p_days is not null and (p_days < 7 or p_days > 3650) then raise exception 'مدة غير صالحة'; end if;
  update public.organizations set chat_image_days = p_days where id = p_org;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'organizations', p_org, jsonb_build_object('chat_image_days', p_days));
end;
$$;

create or replace function public._chat_images_due(p_limit integer default 500)
returns table (id uuid, image_path text) language sql stable security definer set search_path = public as $$
  select m.id, m.image_path
    from public.chat_messages m
    join public.chat_threads t on t.id = m.thread_id
    join public.organizations o on o.id = t.organization_id
   where m.image_path is not null
     and o.chat_image_days is not null
     and m.created_at < now() - make_interval(days => o.chat_image_days)
   order by m.created_at
   limit least(greatest(coalesce(p_limit, 500), 1), 1000);
$$;

create or replace function public._chat_images_deleted(p_ids uuid[])
returns integer language plpgsql security definer set search_path = public as $$
declare v_n integer;
begin
  update public.chat_messages set image_path = null, image_deleted_at = now()
   where id = any (coalesce(p_ids, '{}')) and image_path is not null;
  get diagnostics v_n = row_count;
  return v_n;
end;
$$;

-- the daily job now covers both (one call; the web app deletes recordings and pictures)
create or replace function public.dispatch_recitation_audio_cleanup()
returns void language plpgsql security definer set search_path = public as $$
declare v_url text := public._platform_setting('push_url', ''); v_secret text := public._platform_setting('push_secret', '');
begin
  if v_url = '' or v_secret = '' then return; end if;
  if not exists (select 1 from public._recitation_audio_due(1)) and not exists (select 1 from public._chat_images_due(1)) then return; end if;
  perform net.http_post(
    url := regexp_replace(v_url, '/api/push/?$', '/api/recitations/cleanup'),
    body := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', v_secret));
exception when others then
  null;
end;
$$;

-- the conversation says when a picture was deleted
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
      'deleted_at', q.deleted_at, 'image_deleted_at', q.image_deleted_at) order by q.created_at)
    from (
      select * from public.chat_messages m
      where m.thread_id = p_thread and (p_after is null or m.created_at > p_after)
      order by m.created_at desc limit greatest(1, least(coalesce(p_limit, 60), 200))
    ) q), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------
-- 2. storage space per plan
-- ---------------------------------------------------------------------
-- every file of a center: bucket/{org id}/...
create or replace function public._org_storage_bytes(p_org uuid)
returns bigint language sql stable security definer set search_path = public as $$
  select coalesce(sum((o.metadata ->> 'size')::bigint), 0)::bigint
    from storage.objects o
   where o.name like p_org::text || '/%';
$$;

create or replace function public._org_storage_limit_mb(p_org uuid)
returns integer language sql stable security definer set search_path = public as $$
  select nullif(p.limits ->> 'storage_mb', '')::integer
    from public.organizations o join public.plans p on p.id = o.plan_id where o.id = p_org;
$$;

-- {used_bytes, limit_mb, by_bucket {bucket: bytes}, full}
create or replace function public._org_storage(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  with b as (
    select o.bucket_id, sum((o.metadata ->> 'size')::bigint)::bigint as bytes
      from storage.objects o where o.name like p_org::text || '/%' group by o.bucket_id
  ), t as (select coalesce(sum(bytes), 0)::bigint as used from b), l as (select public._org_storage_limit_mb(p_org) as mb)
  select jsonb_build_object(
    'used_bytes', t.used, 'limit_mb', l.mb,
    'by_bucket', coalesce((select jsonb_object_agg(bucket_id, bytes) from b), '{}'::jsonb),
    'full', l.mb is not null and t.used >= l.mb::bigint * 1048576)
  from t, l;
$$;

-- the center's admin (billing page) and any member asking whether an upload failed for lack of space
create or replace function public.org_storage(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if public.is_org_admin(p_org) then return public._org_storage(p_org); end if;
  if public.is_org_member(p_org) then return jsonb_build_object('full', (public._org_storage(p_org) ->> 'full')::boolean); end if;
  raise exception 'غير مصرّح';
end;
$$;

-- the platform owner: one center, or all of them
create or replace function public.platform_org_storage(p_org uuid default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  perform public._plat_guard();
  if p_org is not null then return public._org_storage(p_org); end if;
  return coalesce((select jsonb_object_agg(o.id, public._org_storage(o.id)) from public.organizations o), '{}'::jsonb);
end;
$$;

-- an upload is refused once the center's space is used up (files of no center are not counted)
create or replace function public._storage_quota_ok(p_name text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_org uuid; v_mb integer;
begin
  if split_part(p_name, '/', 1) !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then return true; end if;
  v_org := split_part(p_name, '/', 1)::uuid;
  v_mb := public._org_storage_limit_mb(v_org);
  if v_mb is null then return true; end if;
  return public._org_storage_bytes(v_org) < v_mb::bigint * 1048576;
end;
$$;

drop policy if exists "storage_quota" on storage.objects;
create policy "storage_quota" on storage.objects as restrictive for insert to authenticated
  with check (public._storage_quota_ok(name));

-- the plan form saves the storage limit with the other two
drop function if exists public.platform_save_plan(uuid, text, text, integer, text, integer, integer, jsonb, boolean, integer);
create or replace function public.platform_save_plan(
  p_id uuid, p_code text, p_name text, p_price_cents integer, p_currency text,
  p_max_students integer, p_max_teachers integer, p_features jsonb, p_active boolean,
  p_yearly_cents integer default null, p_storage_mb integer default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid := p_id;
        v_limits jsonb := jsonb_build_object('max_students', p_max_students, 'max_teachers', p_max_teachers, 'storage_mb', p_storage_mb);
begin
  perform public._plat_guard();
  if p_code !~ '^[a-z0-9_-]{2,30}$' then raise exception 'رمز الخطة: حروف إنجليزية صغيرة وأرقام'; end if;
  if char_length(btrim(coalesce(p_name, ''))) < 2 then raise exception 'اسم الخطة مطلوب'; end if;
  if coalesce(p_price_cents, 0) < 0 or coalesce(p_yearly_cents, 0) < 0 then raise exception 'السعر لا يكون سالبًا'; end if;
  if p_max_students is not null and p_max_students < 0 or p_max_teachers is not null and p_max_teachers < 0
     or p_storage_mb is not null and p_storage_mb < 0 then raise exception 'الحدود لا تكون سالبة'; end if;
  if v_id is null then
    insert into public.plans (code, name, price_cents, yearly_price_cents, currency, limits, features, is_active)
    values (p_code, btrim(p_name), coalesce(p_price_cents, 0), p_yearly_cents, upper(coalesce(nullif(p_currency, ''), 'USD')), v_limits, coalesce(p_features, '{}'::jsonb), coalesce(p_active, true))
    returning id into v_id;
  else
    update public.plans set code = p_code, name = btrim(p_name), price_cents = coalesce(p_price_cents, 0), yearly_price_cents = p_yearly_cents,
           currency = upper(coalesce(nullif(p_currency, ''), 'USD')), limits = v_limits, features = coalesce(p_features, '{}'::jsonb), is_active = coalesce(p_active, true)
     where id = v_id;
    if not found then raise exception 'الخطة غير موجودة'; end if;
  end if;
  perform public._plat_log('save_plan', v_id::text, jsonb_build_object('code', p_code));
  return v_id;
end;
$$;

revoke all on function public.media_retention(uuid) from public, anon;
grant execute on function public.media_retention(uuid) to authenticated;
revoke all on function public.set_chat_image_days(uuid, integer) from public, anon;
grant execute on function public.set_chat_image_days(uuid, integer) to authenticated;
revoke all on function public._chat_images_due(integer) from public, anon, authenticated;
revoke all on function public._chat_images_deleted(uuid[]) from public, anon, authenticated;
revoke all on function public._org_storage_bytes(uuid) from public, anon, authenticated;
revoke all on function public._org_storage_limit_mb(uuid) from public, anon, authenticated;
revoke all on function public._org_storage(uuid) from public, anon, authenticated;
revoke all on function public.org_storage(uuid) from public, anon;
grant execute on function public.org_storage(uuid) to authenticated;
revoke all on function public.platform_org_storage(uuid) from public, anon;
grant execute on function public.platform_org_storage(uuid) to authenticated;
-- storage policies run with the caller's rights (it only answers whether the center has space left)
revoke all on function public._storage_quota_ok(text) from public, anon;
grant execute on function public._storage_quota_ok(text) to authenticated;
revoke all on function public.platform_save_plan(uuid, text, text, integer, text, integer, integer, jsonb, boolean, integer, integer) from public, anon;
grant execute on function public.platform_save_plan(uuid, text, text, integer, text, integer, integer, jsonb, boolean, integer, integer) to authenticated;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public._chat_images_due(integer) to service_role;
    grant execute on function public._chat_images_deleted(uuid[]) to service_role;
  end if;
end $$;

notify pgrst, 'reload schema';
