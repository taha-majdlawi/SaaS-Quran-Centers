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
-- Fixes two real pre-existing bugs found while actually running this
-- migration against a real Postgres instance (not just reading the SQL -
-- neither was obvious on paper):
--
--   1. chat_participants_manage_self (0005) only ever allowed
--      user_id = auth.uid(), so ChatRepository.createThread's second insert
--      (adding the OTHER participant) could never have passed RLS for a
--      non-admin - split below into self-only update/delete policies plus a
--      proper insert policy that also allows adding someone else when a
--      contact (or admin) relationship justifies it.
--
--   2. chat_participants_select_own_thread's (0005) subquery was
--      "p2.thread_id = thread_id" - since p2 IS chat_thread_participants
--      (self-referencing) and that alias already has a thread_id column,
--      the bare `thread_id` resolves to p2's OWN column, not the outer
--      row's, making the condition p2.thread_id = p2.thread_id: always
--      true. In practice: any authenticated user who is a participant in
--      even one thread could read EVERY participant row of EVERY thread in
--      the database, across every organization - a real cross-tenant data
--      leak, not just a permissions gap. And simply correlating it properly
--      (chat_thread_participants.thread_id) turned out NOT to be enough on
--      its own: Postgres's RLS recursion guard rejects a policy that
--      queries its own table via a plain correlated subquery at all,
--      correct or not (confirmed by testing both versions against a real
--      instance) - "infinite recursion detected in policy for relation
--      chat_thread_participants". ChatRepository.fetchMyThreads' very first
--      query (.from('chat_thread_participants')...) would have hit this
--      the moment there was more than trivial data in the real app.
--      Recreated below through a SECURITY DEFINER function instead, same
--      fix shape as chat_thread_org_id below and the same reason
--      is_org_admin/is_org_member already need it for organization_members.
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

-- A direct correlated subquery against chat_threads from within this policy
-- would trip Postgres's RLS recursion guard: chat_threads_select_participant
-- (0005) itself queries chat_thread_participants, so evaluating it from
-- inside a chat_thread_participants policy is a circular A->B->A dependency
-- ("infinite recursion detected in policy for relation
-- chat_thread_participants" - caught by actually running this migration
-- against a real Postgres instance, not just reading it). SECURITY DEFINER
-- sidesteps it the same way is_org_admin/is_org_member already do for
-- organization_members: the function owner bypasses RLS on the table it
-- reads (these tables were never put under FORCE ROW LEVEL SECURITY - see
-- 0010's comment), so this never re-enters chat_threads' own policy.
create or replace function public.chat_thread_org_id(p_thread_id uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select organization_id from public.chat_threads where id = p_thread_id;
$$;

-- Bug 2's fix: same idea as chat_thread_org_id above, but reading
-- chat_thread_participants itself rather than chat_threads, so its own
-- select policy (below) can check "am I one of this thread's participants"
-- without ever re-entering its own RLS.
create or replace function public.chat_thread_participant_ids(p_thread_id uuid)
returns setof uuid language sql stable security definer set search_path = public as $$
  select user_id from public.chat_thread_participants where thread_id = p_thread_id;
$$;

-- ---------------------------------------------------------------------
-- chat_thread_participants: replace the self-only "manage_self" policy
-- (see bug 1 above) with self-only update/delete plus an insert policy that
-- covers both "add myself" and "add someone I may contact"; recreate the
-- select policy through chat_thread_participant_ids (bug 2 above).
-- ---------------------------------------------------------------------
drop policy "chat_participants_manage_self" on public.chat_thread_participants;

drop policy "chat_participants_select_own_thread" on public.chat_thread_participants;
create policy "chat_participants_select_own_thread" on public.chat_thread_participants for select using (
  auth.uid() in (select public.chat_thread_participant_ids(thread_id))
);

create policy "chat_participants_update_self" on public.chat_thread_participants for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "chat_participants_delete_self" on public.chat_thread_participants for delete
  using (user_id = auth.uid());

create policy "chat_participants_insert" on public.chat_thread_participants for insert with check (
  user_id = auth.uid()
  or public.is_org_admin(public.chat_thread_org_id(thread_id))
  or exists (
    select 1 from public.chat_contacts c
    where c.organization_id = public.chat_thread_org_id(thread_id)
      and c.user_id = auth.uid()
      and c.contact_user_id = chat_thread_participants.user_id
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
