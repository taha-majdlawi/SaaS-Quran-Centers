-- =====================================================================
-- 0076: error monitoring
-- ---------------------------------------------------------------------
-- The website and the app report every crash they see (message, stack, the
-- screen, the device, and the last few things the user did) through
-- report_client_error. Reports are grouped by a fingerprint so the same bug
-- from a hundred phones is one row with a count. The platform owner sees the
-- groups in the console and gets an instant push the first time a bug shows
-- up, and again when one marked fixed comes back.
--
-- Safety: anyone (even signed out, e.g. the login page) may report, but
-- every field is size-capped, the user / center are taken from the session
-- (never trusted from the client), and storage is rate-limited per bug,
-- per user and overall. Old reports are deleted after 30 days.
-- =====================================================================

create table if not exists public.app_error_groups (
  fingerprint   text primary key,
  source        text not null check (source in ('web', 'mobile', 'server')),
  message       text not null,
  screen        text,
  first_seen    timestamptz not null default now(),
  last_seen     timestamptz not null default now(),
  count         integer not null default 1,
  users         uuid[] not null default '{}',     -- up to 50 distinct users, for the "how many people" figure
  last_version  text,
  resolved_at   timestamptz,
  alerted_at    timestamptz
);
create index if not exists app_error_groups_last_seen_idx on public.app_error_groups (last_seen desc);

create table if not exists public.app_errors (
  id              uuid primary key default gen_random_uuid(),
  fingerprint     text not null references public.app_error_groups (fingerprint) on delete cascade,
  created_at      timestamptz not null default now(),
  source          text not null,
  message         text not null,
  stack           text,
  screen          text,
  url             text,
  user_id         uuid,
  organization_id uuid references public.organizations (id) on delete set null,
  role            text,
  app_version     text,
  os              text,
  device          text,
  locale          text,
  breadcrumbs     jsonb not null default '[]',
  extra           jsonb not null default '{}'
);
create index if not exists app_errors_fp_idx on public.app_errors (fingerprint, created_at desc);
create index if not exists app_errors_created_idx on public.app_errors (created_at);
create index if not exists app_errors_user_idx on public.app_errors (user_id, created_at desc);

alter table public.app_error_groups enable row level security;
alter table public.app_errors enable row level security;
revoke all on public.app_error_groups, public.app_errors from anon, authenticated;

-- "TypeError: x is null at 12:34" and the same at 56:78 are one bug
create or replace function public._error_fingerprint(p_source text, p_message text, p_stack text)
returns text language sql immutable set search_path = public as $$
  select md5(p_source || '|' ||
    regexp_replace(regexp_replace(coalesce(p_message, ''),
      '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', '<id>', 'gi'), '\d+', 'N', 'g') || '|' ||
    regexp_replace(coalesce(
      (select l from regexp_split_to_table(coalesce(p_stack, ''), E'\n') l
        where btrim(l) <> '' and l !~* '(node_modules|dart:async|dart:core|package:flutter/|<anonymous>|webpack-internal)' limit 1), ''),
      '[:(]\d+(:\d+)?\)?', '', 'g'));
$$;

create or replace function public.report_client_error(
  p_source text, p_message text, p_stack text default null, p_screen text default null, p_url text default null,
  p_org uuid default null, p_app_version text default null, p_os text default null, p_device text default null,
  p_locale text default null, p_breadcrumbs jsonb default '[]', p_extra jsonb default '{}')
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid(); v_org uuid; v_role text; v_fp text; v_msg text; v_new boolean := false; v_reopened boolean := false;
  v_id uuid; g public.app_error_groups%rowtype; v_crumbs jsonb;
begin
  if p_source not in ('web', 'mobile', 'server') then return; end if;
  v_msg := left(btrim(coalesce(p_message, '')), 1000);
  if v_msg = '' then return; end if;
  -- the center only when the person really belongs to it
  if p_org is not null and v_uid is not null then
    select m.organization_id, m.role::text into v_org, v_role from public.organization_members m
     where m.organization_id = p_org and m.user_id = v_uid limit 1;
  end if;
  v_fp := public._error_fingerprint(p_source, v_msg, p_stack);
  v_crumbs := coalesce((select jsonb_agg(left(x::text, 300)) from (
                select x from jsonb_array_elements(case when jsonb_typeof(p_breadcrumbs) = 'array' then p_breadcrumbs else '[]' end) x
                limit 30) t), '[]');

  select * into g from public.app_error_groups where fingerprint = v_fp for update;
  if not found then
    insert into public.app_error_groups (fingerprint, source, message, screen, users, last_version)
    values (v_fp, p_source, v_msg, left(p_screen, 300), case when v_uid is null then '{}' else array[v_uid] end, left(p_app_version, 40));
    v_new := true;
  else
    v_reopened := g.resolved_at is not null;
    update public.app_error_groups set
      last_seen = now(), count = count + 1, screen = coalesce(left(p_screen, 300), screen), last_version = coalesce(left(p_app_version, 40), last_version),
      resolved_at = null,
      users = case when v_uid is null or v_uid = any (users) or cardinality(users) >= 50 then users else users || v_uid end
    where fingerprint = v_fp;
  end if;

  -- keep the details, within limits (the count above always goes up)
  if (select count(*) from public.app_errors where fingerprint = v_fp and created_at > now() - interval '1 hour') >= 20 then return; end if;
  if v_uid is not null and (select count(*) from public.app_errors where user_id = v_uid and created_at > now() - interval '1 hour') >= 60 then return; end if;
  if (select count(*) from public.app_errors where created_at > now() - interval '10 minutes') >= 500 then return; end if;

  insert into public.app_errors (fingerprint, source, message, stack, screen, url, user_id, organization_id, role, app_version, os, device, locale, breadcrumbs, extra)
  values (v_fp, p_source, v_msg, left(p_stack, 8000), left(p_screen, 300), left(p_url, 500), v_uid, v_org, v_role,
          left(p_app_version, 40), left(p_os, 80), left(p_device, 120), left(p_locale, 20), v_crumbs,
          case when jsonb_typeof(p_extra) = 'object' and length(p_extra::text) <= 4000 then p_extra else '{}' end)
  returning id into v_id;

  -- a new bug, or one marked fixed that came back: tell the owner now (at most once an hour per bug)
  if (v_new or v_reopened) and (g.alerted_at is null or g.alerted_at < now() - interval '1 hour') then
    update public.app_error_groups set alerted_at = now() where fingerprint = v_fp;
    perform public._push_dispatch('error', v_id);
  end if;
end;
$$;
revoke all on function public.report_client_error(text, text, text, text, text, uuid, text, text, text, text, jsonb, jsonb) from public;
grant execute on function public.report_client_error(text, text, text, text, text, uuid, text, text, text, text, jsonb, jsonb) to anon, authenticated;
revoke all on function public._error_fingerprint(text, text, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- the console
-- ---------------------------------------------------------------------
create or replace function public.platform_error_groups(p_status text default 'open', p_days integer default 14)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_platform_owner() then raise exception 'للمالك فقط'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
      'fingerprint', g.fingerprint, 'source', g.source, 'message', g.message, 'screen', g.screen,
      'first_seen', g.first_seen, 'last_seen', g.last_seen, 'count', g.count, 'users', cardinality(g.users),
      'last_version', g.last_version, 'resolved_at', g.resolved_at,
      'last_24h', (select count(*) from public.app_errors e where e.fingerprint = g.fingerprint and e.created_at > now() - interval '24 hours'),
      'centers', (select count(distinct e.organization_id) from public.app_errors e where e.fingerprint = g.fingerprint))
      order by (g.resolved_at is null) desc, g.last_seen desc)
    from public.app_error_groups g
    where g.last_seen > now() - make_interval(days => least(greatest(coalesce(p_days, 14), 1), 90))
      and (p_status = 'all' or (p_status = 'open' and g.resolved_at is null) or (p_status = 'resolved' and g.resolved_at is not null))), '[]'::jsonb);
end;
$$;

create or replace function public.platform_error_detail(p_fingerprint text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_platform_owner() then raise exception 'للمالك فقط'; end if;
  return jsonb_build_object(
    'group', (select to_jsonb(g) - 'users' || jsonb_build_object('users', cardinality(g.users)) from public.app_error_groups g where g.fingerprint = p_fingerprint),
    'events', coalesce((select jsonb_agg(jsonb_build_object(
        'id', e.id, 'at', e.created_at, 'message', e.message, 'stack', e.stack, 'screen', e.screen, 'url', e.url,
        'user', (select coalesce(p.full_name, u.email) from auth.users u left join public.profiles p on p.id = u.id where u.id = e.user_id),
        'center', (select o.name from public.organizations o where o.id = e.organization_id), 'role', e.role,
        'app_version', e.app_version, 'os', e.os, 'device', e.device, 'locale', e.locale, 'breadcrumbs', e.breadcrumbs, 'extra', e.extra)
        order by e.created_at desc)
      from (select * from public.app_errors where fingerprint = p_fingerprint order by created_at desc limit 25) e), '[]'::jsonb));
end;
$$;

create or replace function public.platform_resolve_error(p_fingerprint text, p_resolved boolean default true)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_platform_owner() then raise exception 'للمالك فقط'; end if;
  update public.app_error_groups set resolved_at = case when p_resolved then now() else null end where fingerprint = p_fingerprint;
end;
$$;

create or replace function public.platform_open_error_count()
returns integer language sql stable security definer set search_path = public as $$
  select case when public.is_platform_owner() then
    (select count(*)::integer from public.app_error_groups where resolved_at is null and last_seen > now() - interval '7 days') else 0 end;
$$;

do $$
declare f text;
begin
  foreach f in array array['platform_error_groups(text, integer)', 'platform_error_detail(text)', 'platform_resolve_error(text, boolean)', 'platform_open_error_count()'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- 30 days of details is plenty; a group with no event left goes too
create or replace function public.cleanup_error_reports()
returns void language sql security definer set search_path = public as $$
  delete from public.app_errors where created_at < now() - interval '30 days';
  delete from public.app_error_groups where last_seen < now() - interval '30 days';
$$;
revoke all on function public.cleanup_error_reports() from public, anon, authenticated;
select cron.schedule('error-reports-cleanup', '35 3 * * *', 'select public.cleanup_error_reports()');

notify pgrst, 'reload schema';
