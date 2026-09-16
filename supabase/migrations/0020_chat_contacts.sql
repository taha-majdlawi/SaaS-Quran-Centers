-- =========================================================================
-- 0020_chat_contacts.sql
--
-- Chat has been staff-only (admin+teacher) on both platforms so far, with
-- zero restriction on who could message whom within that group - any
-- teacher could start a thread with any other staff member. This adds:
--
--   1. Student/guardian access to chat, restricted to a manually curated
--      contact list per member (chat_contacts) rather than automatic
--      role-derived rules - an admin decides, pair by pair, who can reach
--      whom, and can revoke or add contacts any time from the app.
--   2. A one-time seed of that list for EXISTING members, matching the
--      requested default: student <-> their circle's teacher, guardian <->
--      their child's circle's teacher, teacher <-> every other teacher and
--      every admin, admin <-> everyone. This is a STARTING POINT the admin
--      edits from there - nothing keeps recalculating it automatically as
--      circles/roles change later (that would just be automatic rules
--      again under a different name), so a newly added member's contacts
--      need to be set up by the admin the same way.
--
-- Fixes a real pre-existing bug along the way: chat_participants_manage_self
-- (0005) only ever allowed user_id = auth.uid(), so ChatRepository.
-- createThread's second insert (adding the OTHER participant) could never
-- have passed RLS for a non-admin - split below into self-only update/
-- delete policies plus a proper insert policy that also allows adding
-- someone else when a contact (or admin) relationship justifies it.
-- =========================================================================

create table public.chat_contacts (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references public.organizations (id) on delete cascade,
  user_id           uuid not null references auth.users (id) on delete cascade,
  contact_user_id   uuid not null references auth.users (id) on delete cascade,
  created_by        uuid references auth.users (id),
  created_at        timestamptz not null default now(),
  unique (organization_id, user_id, contact_user_id),
  check (user_id <> contact_user_id)
);

alter table public.chat_contacts enable row level security;

create policy "chat_contacts_select" on public.chat_contacts for select using (
  user_id = auth.uid() or public.is_org_admin(organization_id)
);
create policy "chat_contacts_write_admin" on public.chat_contacts for all
  using (public.is_org_admin(organization_id)) with check (public.is_org_admin(organization_id));

-- chat_threads had no delete policy at all - needed so ChatRepository.
-- createThread can clean up the empty thread it just created when adding
-- the other participant is rejected (not a contact, and not an admin).
-- Scoped to the creator AND to threads with no messages yet, so this can
-- never delete a real conversation's history.
create policy "chat_threads_delete_own_empty" on public.chat_threads for delete using (
  created_by = auth.uid()
  and not exists (select 1 from public.chat_messages m where m.thread_id = id)
);

-- ---------------------------------------------------------------------
-- chat_thread_participants: replace the self-only "manage_self" policy
-- (see the bug note above) with self-only update/delete plus an insert
-- policy that covers both "add myself" and "add someone I may contact".
-- ---------------------------------------------------------------------
drop policy "chat_participants_manage_self" on public.chat_thread_participants;

create policy "chat_participants_update_self" on public.chat_thread_participants for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "chat_participants_delete_self" on public.chat_thread_participants for delete
  using (user_id = auth.uid());

create policy "chat_participants_insert" on public.chat_thread_participants for insert with check (
  user_id = auth.uid()
  or exists (
    select 1 from public.chat_threads t
    where t.id = thread_id
      and (
        public.is_org_admin(t.organization_id)
        or exists (
          select 1 from public.chat_contacts c
          where c.organization_id = t.organization_id
            and c.user_id = auth.uid()
            and c.contact_user_id = chat_thread_participants.user_id
        )
      )
  )
);

-- ---------------------------------------------------------------------
-- Seed defaults for existing data.
-- ---------------------------------------------------------------------

-- admin <-> everyone (single self-join over all ordered pairs where either
-- side is an admin already covers both directions).
insert into public.chat_contacts (organization_id, user_id, contact_user_id)
select m1.organization_id, m1.user_id, m2.user_id
from public.organization_members m1
join public.organization_members m2
  on m2.organization_id = m1.organization_id and m2.user_id <> m1.user_id and m2.status = 'active'
where m1.status = 'active' and (m1.role = 'admin' or m2.role = 'admin')
on conflict do nothing;

-- teacher <-> teacher (same reasoning: one self-join covers both directions).
insert into public.chat_contacts (organization_id, user_id, contact_user_id)
select t1.organization_id, t1.user_id, t2.user_id
from public.organization_members t1
join public.organization_members t2
  on t2.organization_id = t1.organization_id and t2.user_id <> t1.user_id and t2.role = 'teacher' and t2.status = 'active'
where t1.role = 'teacher' and t1.status = 'active'
on conflict do nothing;

-- teacher <-> student, scoped to the student's own circle's teacher. Only
-- students with their own login (member_id set) can use chat at all.
insert into public.chat_contacts (organization_id, user_id, contact_user_id)
select c.organization_id, c.teacher_id, om.user_id
from public.circles c
join public.students_profile sp on sp.circle_id = c.id and sp.organization_id = c.organization_id
join public.organization_members om on om.id = sp.member_id and om.status = 'active'
where c.teacher_id is not null
on conflict do nothing;

insert into public.chat_contacts (organization_id, user_id, contact_user_id)
select c.organization_id, om.user_id, c.teacher_id
from public.circles c
join public.students_profile sp on sp.circle_id = c.id and sp.organization_id = c.organization_id
join public.organization_members om on om.id = sp.member_id and om.status = 'active'
where c.teacher_id is not null
on conflict do nothing;

-- teacher <-> guardian, same scoping via the guardian's linked student(s).
insert into public.chat_contacts (organization_id, user_id, contact_user_id)
select c.organization_id, c.teacher_id, om.user_id
from public.circles c
join public.students_profile sp on sp.circle_id = c.id and sp.organization_id = c.organization_id
join public.organization_members om on om.id = sp.guardian_member_id and om.status = 'active'
where c.teacher_id is not null
on conflict do nothing;

insert into public.chat_contacts (organization_id, user_id, contact_user_id)
select c.organization_id, om.user_id, c.teacher_id
from public.circles c
join public.students_profile sp on sp.circle_id = c.id and sp.organization_id = c.organization_id
join public.organization_members om on om.id = sp.guardian_member_id and om.status = 'active'
where c.teacher_id is not null
on conflict do nothing;
