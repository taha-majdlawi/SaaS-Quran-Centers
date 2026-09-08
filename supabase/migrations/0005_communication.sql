-- =========================================================================
-- 0005_communication.sql
-- Chat, notifications, and announcements. Maps legacy: chat_threads,
-- chat_messages, notification_templates/log/prefs, device_tokens,
-- announcements.
-- =========================================================================

create table public.chat_threads (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  is_group         boolean not null default false,
  title            text,
  created_by       uuid references auth.users (id),
  created_at       timestamptz not null default now()
);

create table public.chat_thread_participants (
  thread_id    uuid not null references public.chat_threads (id) on delete cascade,
  user_id      uuid not null references auth.users (id) on delete cascade,
  joined_at    timestamptz not null default now(),
  muted_until  timestamptz,
  primary key (thread_id, user_id)
);

create table public.chat_messages (
  id              uuid primary key default gen_random_uuid(),
  thread_id       uuid not null references public.chat_threads (id) on delete cascade,
  sender_id       uuid references auth.users (id),
  body            text,
  attachment_url  text,
  created_at      timestamptz not null default now()
);

create index chat_messages_thread_idx on public.chat_messages (thread_id, created_at);

create table public.announcements (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  title            text not null,
  body             text not null,
  audience         text not null default 'all' check (audience in ('all', 'teachers', 'students', 'guardians')),
  published_at     timestamptz,
  created_by       uuid references auth.users (id),
  created_at       timestamptz not null default now()
);

create type public.notification_channel as enum ('push', 'in_app', 'email');

create table public.notification_templates (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  code             text not null,
  title_template   text not null,
  body_template    text not null,
  channel          public.notification_channel not null default 'push',
  unique (organization_id, code)
);

create table public.notification_log (
  id           uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  user_id      uuid not null references auth.users (id) on delete cascade,
  template_id  uuid references public.notification_templates (id),
  channel      public.notification_channel not null default 'push',
  title        text not null,
  body         text not null,
  sent_at      timestamptz not null default now(),
  read_at      timestamptz
);

create index notification_log_user_idx on public.notification_log (user_id, sent_at desc);

create table public.notification_prefs (
  user_id          uuid not null references auth.users (id) on delete cascade,
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  channel          public.notification_channel not null,
  enabled          boolean not null default true,
  primary key (user_id, organization_id, channel)
);

create table public.device_tokens (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  token            text not null unique,
  platform         text not null check (platform in ('ios', 'android', 'web')),
  created_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.chat_threads enable row level security;
alter table public.chat_thread_participants enable row level security;
alter table public.chat_messages enable row level security;
alter table public.announcements enable row level security;
alter table public.notification_templates enable row level security;
alter table public.notification_log enable row level security;
alter table public.notification_prefs enable row level security;
alter table public.device_tokens enable row level security;

create policy "chat_threads_select_participant" on public.chat_threads for select using (
  exists (select 1 from public.chat_thread_participants p where p.thread_id = id and p.user_id = auth.uid())
  or public.is_org_admin(organization_id)
);
create policy "chat_threads_insert_member" on public.chat_threads for insert with check (public.is_org_member(organization_id));

create policy "chat_participants_select_own_thread" on public.chat_thread_participants for select using (
  exists (select 1 from public.chat_thread_participants p2 where p2.thread_id = thread_id and p2.user_id = auth.uid())
);
create policy "chat_participants_manage_self" on public.chat_thread_participants for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "chat_messages_select_participant" on public.chat_messages for select using (
  exists (select 1 from public.chat_thread_participants p where p.thread_id = thread_id and p.user_id = auth.uid())
);
create policy "chat_messages_insert_participant" on public.chat_messages for insert with check (
  sender_id = auth.uid()
  and exists (select 1 from public.chat_thread_participants p where p.thread_id = thread_id and p.user_id = auth.uid())
);

create policy "announcements_select_org" on public.announcements for select using (public.is_org_member(organization_id));
create policy "announcements_write_staff" on public.announcements for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));

create policy "notification_templates_select_org" on public.notification_templates for select using (public.is_org_member(organization_id));
create policy "notification_templates_write_admin" on public.notification_templates for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

create policy "notification_log_select_self" on public.notification_log for select using (
  user_id = auth.uid() or public.is_org_admin(organization_id)
);
create policy "notification_log_insert_staff" on public.notification_log for insert with check (public.is_org_staff(organization_id));
create policy "notification_log_update_self" on public.notification_log for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "notification_prefs_manage_self" on public.notification_prefs for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "device_tokens_manage_self" on public.device_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
