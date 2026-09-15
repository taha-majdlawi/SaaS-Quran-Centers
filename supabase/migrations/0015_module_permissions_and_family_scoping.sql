-- =========================================================================
-- 0015_module_permissions_and_family_scoping.sql
--
-- Two related fixes to a real over-exposure problem: any authenticated org
-- member (including a 'student' or 'guardian' role) could previously read
-- every OTHER student's attendance, serd grades, wallet balance, and market
-- purchases in the org, because those tables' SELECT policies only checked
-- org membership (is_org_member), not staff status or family linkage.
--
--   1. Family scoping: student/guardian accounts can now only see rows for
--      their OWN linked student (students_profile.member_id / .guardian_
--      member_id) on the tables that carry per-student personal data.
--   2. Module permissions: admins can grant/revoke a TEACHER's access to
--      specific dashboard modules (organization_members.permissions).
--      Existing teachers default to every module so nothing already
--      granted silently breaks; admins are never restricted by this.
-- =========================================================================

alter table public.organization_members
  add column if not exists permissions text[] not null default array[
    'students', 'circles', 'attendance', 'serd', 'points', 'badges',
    'market', 'circle-challenges', 'activities', 'calendar',
    'announcements', 'chat', 'notifications'
  ]::text[];

-- ---------------------------------------------------------------------
-- Helper functions
-- ---------------------------------------------------------------------

-- Admins always pass. A teacher passes only if the module is in their
-- granted list. Students/guardians never pass (they aren't 'teacher').
create or replace function public.member_has_module(org_id uuid, module text)
returns boolean language sql security definer stable set search_path = public as $$
  select public.is_org_admin(org_id) or exists (
    select 1 from public.organization_members m
    where m.organization_id = org_id
      and m.user_id = auth.uid()
      and m.status = 'active'
      and m.role = 'teacher'
      and module = any(m.permissions)
  );
$$;

-- The caller's own student record (role='student') and/or their children's
-- (role='guardian'), scoped to one org. Empty for staff - they don't need
-- this, is_org_staff/member_has_module already covers them.
create or replace function public.linked_student_ids(org_id uuid)
returns uuid[] language sql security definer stable set search_path = public as $$
  select coalesce(array_agg(s.id), array[]::uuid[])
  from public.students_profile s
  where s.organization_id = org_id
    and exists (
      select 1 from public.organization_members m
      where m.organization_id = org_id
        and m.user_id = auth.uid()
        and m.status = 'active'
        and (m.id = s.member_id or m.id = s.guardian_member_id)
    );
$$;

-- ---------------------------------------------------------------------
-- list_org_members: surface `permissions` so the teacher-edit UI can show
-- and edit it (mirrors the ::text cast fix from 0014 for the same reason).
-- ---------------------------------------------------------------------
-- Adding `permissions` to the OUT columns changes the function's row type,
-- which `create or replace` cannot do for a `returns table` function - the
-- old signature has to be dropped first.
drop function if exists public.list_org_members(uuid);

create function public.list_org_members(org_id uuid)
returns table (
  id uuid, user_id uuid, role public.user_role, status text, full_name text,
  email text, permissions text[], created_at timestamptz
)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_member(org_id) then
    raise exception 'not authorized';
  end if;
  return query
  select m.id, m.user_id, m.role, m.status, p.full_name, u.email::text, m.permissions, m.created_at
  from public.organization_members m
  left join public.profiles p on p.id = m.user_id
  left join auth.users u on u.id = m.user_id
  where m.organization_id = org_id
  order by m.created_at;
end;
$$;

-- ---------------------------------------------------------------------
-- students_profile: gate staff access by the 'students' module too, on
-- top of the existing family-linkage branch.
-- ---------------------------------------------------------------------
drop policy "students_profile_select_staff_or_family" on public.students_profile;
create policy "students_profile_select_staff_or_family" on public.students_profile
  for select using (
    public.member_has_module(organization_id, 'students')
    or guardian_member_id in (select id from public.organization_members where user_id = auth.uid())
    or member_id in (select id from public.organization_members where user_id = auth.uid())
  );

drop policy "students_profile_write_staff" on public.students_profile;
create policy "students_profile_write_staff" on public.students_profile for all
  using (public.member_has_module(organization_id, 'students'))
  with check (public.member_has_module(organization_id, 'students'));

drop policy "circles_write_staff" on public.circles;
create policy "circles_write_staff" on public.circles for all
  using (public.member_has_module(organization_id, 'circles'))
  with check (public.member_has_module(organization_id, 'circles'));

-- ---------------------------------------------------------------------
-- attendance - per-student, family-scoped
-- ---------------------------------------------------------------------
drop policy "attendance_select_org" on public.attendance;
create policy "attendance_select_scoped" on public.attendance for select using (
  public.member_has_module(organization_id, 'attendance')
  or student_id = any(public.linked_student_ids(organization_id))
);

drop policy "attendance_write_staff" on public.attendance;
create policy "attendance_write_staff" on public.attendance for all
  using (public.member_has_module(organization_id, 'attendance'))
  with check (public.member_has_module(organization_id, 'attendance'));

drop policy "gatherings_write_staff" on public.attendance_gatherings;
create policy "gatherings_write_staff" on public.attendance_gatherings for all
  using (public.member_has_module(organization_id, 'attendance'))
  with check (public.member_has_module(organization_id, 'attendance'));

drop policy "gathering_entries_select" on public.attendance_gathering_entries;
create policy "gathering_entries_select_scoped" on public.attendance_gathering_entries for select using (
  exists (
    select 1 from public.attendance_gatherings g where g.id = gathering_id
    and (
      public.member_has_module(g.organization_id, 'attendance')
      or student_id = any(public.linked_student_ids(g.organization_id))
    )
  )
);

drop policy "gathering_entries_write" on public.attendance_gathering_entries;
create policy "gathering_entries_write" on public.attendance_gathering_entries for all using (
  exists (select 1 from public.attendance_gatherings g where g.id = gathering_id and public.member_has_module(g.organization_id, 'attendance'))
) with check (
  exists (select 1 from public.attendance_gatherings g where g.id = gathering_id and public.member_has_module(g.organization_id, 'attendance'))
);

-- Memorization log shown on a student's profile page - tied to the
-- 'students' module rather than a dedicated one of its own.
drop policy "daily_achievements_select_org" on public.daily_achievements;
create policy "daily_achievements_select_scoped" on public.daily_achievements for select using (
  public.member_has_module(organization_id, 'students')
  or student_id = any(public.linked_student_ids(organization_id))
);

drop policy "daily_achievements_write_staff" on public.daily_achievements;
create policy "daily_achievements_write_staff" on public.daily_achievements for all
  using (public.member_has_module(organization_id, 'students'))
  with check (public.member_has_module(organization_id, 'students'));

-- ---------------------------------------------------------------------
-- serd - sessions + parts/errors joined through them. recitation-requests
-- (the "pending" view of serd_sessions) shares this same module key.
-- ---------------------------------------------------------------------
drop policy "serd_sessions_select_org" on public.serd_sessions;
create policy "serd_sessions_select_scoped" on public.serd_sessions for select using (
  public.member_has_module(organization_id, 'serd')
  or student_id = any(public.linked_student_ids(organization_id))
);

drop policy "serd_sessions_write_staff" on public.serd_sessions;
create policy "serd_sessions_write_staff" on public.serd_sessions for all
  using (public.member_has_module(organization_id, 'serd'))
  with check (public.member_has_module(organization_id, 'serd'));

drop policy "serd_session_parts_select" on public.serd_session_parts;
create policy "serd_session_parts_select_scoped" on public.serd_session_parts for select using (
  exists (
    select 1 from public.serd_sessions s where s.id = session_id
    and (
      public.member_has_module(s.organization_id, 'serd')
      or s.student_id = any(public.linked_student_ids(s.organization_id))
    )
  )
);

drop policy "serd_session_parts_write" on public.serd_session_parts;
create policy "serd_session_parts_write" on public.serd_session_parts for all using (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.member_has_module(s.organization_id, 'serd'))
) with check (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.member_has_module(s.organization_id, 'serd'))
);

drop policy "serd_session_errors_select" on public.serd_session_errors;
create policy "serd_session_errors_select_scoped" on public.serd_session_errors for select using (
  exists (
    select 1 from public.serd_sessions s where s.id = session_id
    and (
      public.member_has_module(s.organization_id, 'serd')
      or s.student_id = any(public.linked_student_ids(s.organization_id))
    )
  )
);

drop policy "serd_session_errors_write" on public.serd_session_errors;
create policy "serd_session_errors_write" on public.serd_session_errors for all using (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.member_has_module(s.organization_id, 'serd'))
) with check (
  exists (select 1 from public.serd_sessions s where s.id = session_id and public.member_has_module(s.organization_id, 'serd'))
);

-- ---------------------------------------------------------------------
-- badges / student_badges - the catalog stays org-visible, awards are
-- family-scoped.
-- ---------------------------------------------------------------------
drop policy "badges_write_staff" on public.badges;
create policy "badges_write_staff" on public.badges for all
  using (public.member_has_module(organization_id, 'badges'))
  with check (public.member_has_module(organization_id, 'badges'));

drop policy "student_badges_select_org" on public.student_badges;
create policy "student_badges_select_scoped" on public.student_badges for select using (
  exists (
    select 1 from public.badges b where b.id = badge_id
    and (
      public.member_has_module(b.organization_id, 'badges')
      or student_id = any(public.linked_student_ids(b.organization_id))
    )
  )
);

drop policy "student_badges_write_staff" on public.student_badges;
create policy "student_badges_write_staff" on public.student_badges for all using (
  exists (select 1 from public.badges b where b.id = badge_id and public.member_has_module(b.organization_id, 'badges'))
) with check (
  exists (select 1 from public.badges b where b.id = badge_id and public.member_has_module(b.organization_id, 'badges'))
);

-- ---------------------------------------------------------------------
-- points: wallets are per-student personal data (balance), family-scoped.
-- ---------------------------------------------------------------------
drop policy "student_wallets_select_org" on public.student_wallets;
create policy "student_wallets_select_scoped" on public.student_wallets for select using (
  public.member_has_module(organization_id, 'points')
  or student_id = any(public.linked_student_ids(organization_id))
);

drop policy "student_wallets_write_staff" on public.student_wallets;
create policy "student_wallets_write_staff" on public.student_wallets for all
  using (public.member_has_module(organization_id, 'points'))
  with check (public.member_has_module(organization_id, 'points'));

-- ---------------------------------------------------------------------
-- market: catalog stays org-visible, purchase history is family-scoped.
-- ---------------------------------------------------------------------
drop policy "market_items_write_staff" on public.market_items;
create policy "market_items_write_staff" on public.market_items for all
  using (public.member_has_module(organization_id, 'market'))
  with check (public.member_has_module(organization_id, 'market'));

drop policy "market_purchases_select_org" on public.market_purchases;
create policy "market_purchases_select_scoped" on public.market_purchases for select using (
  public.member_has_module(organization_id, 'market')
  or student_id = any(public.linked_student_ids(organization_id))
);

drop policy "market_purchases_write_staff" on public.market_purchases;
create policy "market_purchases_write_staff" on public.market_purchases for all
  using (public.member_has_module(organization_id, 'market'))
  with check (public.member_has_module(organization_id, 'market'));

-- ---------------------------------------------------------------------
-- circle-challenges / activities / calendar / announcements / notifications
-- - circle- and org-level, not personal data, so SELECT stays org-wide;
-- only staff WRITE access is gated by the matching module.
-- ---------------------------------------------------------------------
drop policy "circle_challenges_write_staff" on public.circle_challenges;
create policy "circle_challenges_write_staff" on public.circle_challenges for all
  using (public.member_has_module(organization_id, 'circle-challenges'))
  with check (public.member_has_module(organization_id, 'circle-challenges'));

drop policy "circle_challenge_entries_write" on public.circle_challenge_entries;
create policy "circle_challenge_entries_write" on public.circle_challenge_entries for all using (
  exists (select 1 from public.circle_challenges c where c.id = challenge_id and public.member_has_module(c.organization_id, 'circle-challenges'))
) with check (
  exists (select 1 from public.circle_challenges c where c.id = challenge_id and public.member_has_module(c.organization_id, 'circle-challenges'))
);

drop policy "activities_write_staff" on public.activities;
create policy "activities_write_staff" on public.activities for all
  using (public.member_has_module(organization_id, 'activities'))
  with check (public.member_has_module(organization_id, 'activities'));

drop policy "center_calendar_write_staff" on public.center_calendar;
create policy "center_calendar_write_staff" on public.center_calendar for all
  using (public.member_has_module(organization_id, 'calendar'))
  with check (public.member_has_module(organization_id, 'calendar'));

drop policy "announcements_write_staff" on public.announcements;
create policy "announcements_write_staff" on public.announcements for all
  using (public.member_has_module(organization_id, 'announcements'))
  with check (public.member_has_module(organization_id, 'announcements'));

drop policy "notification_log_insert_staff" on public.notification_log;
create policy "notification_log_insert_staff" on public.notification_log for insert with check (
  public.member_has_module(organization_id, 'notifications')
);
