-- The 'eqraa' demo center the invariants expect: an admin, a teacher with a
-- circle, and a student with a login and a profile in that circle.
insert into auth.users (id, email) values
  ('c1000000-0000-0000-0000-00000000000a', 'admin@ci'),
  ('c1000000-0000-0000-0000-0000000000a1', 'teacher@ci'),
  ('c1000000-0000-0000-0000-0000000000c1', 'student@ci');
insert into public.organizations (id, name, slug) values ('c2000000-0000-0000-0000-000000000001', 'CI center', 'eqraa');
insert into public.organization_members (id, organization_id, user_id, role, status, permissions) values
  ('c3000000-0000-0000-0000-00000000000a', 'c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-00000000000a', 'admin', 'active', '{}'),
  ('c3000000-0000-0000-0000-0000000000a1', 'c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-0000000000a1', 'teacher', 'active', '{students,serd}'),
  ('c3000000-0000-0000-0000-0000000000c1', 'c2000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-0000000000c1', 'student', 'active', '{}');
insert into public.circles (id, organization_id, name, teacher_id) values
  ('c4000000-0000-0000-0000-0000000000a1', 'c2000000-0000-0000-0000-000000000001', 'CI circle', 'c1000000-0000-0000-0000-0000000000a1');
insert into public.students_profile (id, organization_id, student_code, full_name, circle_id, member_id) values
  ('c5000000-0000-0000-0000-0000000000a1', 'c2000000-0000-0000-0000-000000000001', 'S1', 'CI student', 'c4000000-0000-0000-0000-0000000000a1', 'c3000000-0000-0000-0000-0000000000c1');
