-- =========================================================================
-- 0046_assistant_teachers.sql
-- Assistant teachers (المعلم المساعد), ported from eqraa: an ordinary teacher
-- account linked to a circle owned by a primary teacher; on THAT circle they
-- inherit everything the teacher can do (record, attend, notes, reviews,
-- announcements, certificates...). The circle keeps one primary teacher in
-- circles.teacher_id; assistants live in circle_assistants (a circle can have
-- several, a teacher can assist in several circles).
-- =========================================================================
create table if not exists public.circle_assistants (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  circle_id       uuid not null references public.circles (id) on delete cascade,
  user_id         uuid not null references auth.users (id) on delete cascade,
  created_at      timestamptz not null default now(),
  primary key (circle_id, user_id)
);
create index if not exists circle_assistants_user_idx on public.circle_assistants (user_id);
alter table public.circle_assistants enable row level security;
revoke all on public.circle_assistants from anon, authenticated;
drop trigger if exists a_deny_readonly_write on public.circle_assistants;
create trigger a_deny_readonly_write before insert or update or delete on public.circle_assistants
  for each row execute function public._deny_readonly_write();

-- "is this person a teacher of this circle" - primary or assistant
create or replace function public._is_circle_teacher(p_circle uuid, p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select p_user is not null and exists (
    select 1 from public.circles c
    where c.id = p_circle
      and (c.teacher_id = p_user or exists (select 1 from public.circle_assistants a where a.circle_id = c.id and a.user_id = p_user)));
$$;

-- a teacher promoted to primary stops being an assistant of that circle
create or replace function public.trg_circle_primary_changed()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.teacher_id is not null and new.teacher_id is distinct from old.teacher_id then
    delete from public.circle_assistants where circle_id = new.id and user_id = new.teacher_id;
  end if;
  return new;
end;
$$;
drop trigger if exists z_circle_primary_changed on public.circles;
create trigger z_circle_primary_changed after update of teacher_id on public.circles for each row execute function public.trg_circle_primary_changed();

-- ---------------------------------------------------------------------
-- Every place that meant "the circle's teacher" now means "primary or assistant".
-- The existing definitions are rewritten in place (pg_get_functiondef) so nothing else about them changes.
-- ---------------------------------------------------------------------
do $$
declare
  r record; v_def text; v_new text; v_n integer := 0;
  v_alias text := '\m(c|ci)\.teacher_id\s*=\s*(auth\.uid\(\)|p_teacher|m\.user_id)';
  v_bare  text := '(?<![\w.])teacher_id\s*=\s*(auth\.uid\(\)|p_teacher)';
begin
  -- functions whose "teacher_id = ..." refers to the circles table
  for r in
    select p.oid, p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = any (array[
      '_audience_users', '_calendar_visible', '_teacher_teaches_any', '_teaches_student', 'admin_send_notification', 'due_reviews',
      'get_teacher_today', 'list_announcements', 'save_announcement', 'search_global', 'teacher_check_in', 'admin_set_teacher_attendance'])
  loop
    v_def := pg_get_functiondef(r.oid);
    v_new := regexp_replace(v_def, v_alias, 'public._is_circle_teacher(\1.id, \2)', 'g');
    v_new := regexp_replace(v_new, v_bare, 'public._is_circle_teacher(id, \1)', 'g');
    if v_new = v_def then raise exception 'assistant patch: nothing to change in %', r.proname; end if;
    execute v_new;
    v_n := v_n + 1;
  end loop;

  -- the recording guard ("this student is not in your circle")
  select p.oid into r from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = '_assert_can_record_for_student';
  v_def := pg_get_functiondef(r.oid);
  v_new := replace(v_def, 'v_teacher is distinct from auth.uid()', 'not public._is_circle_teacher(v_circle, auth.uid())');
  if v_new = v_def then raise exception 'assistant patch: _assert_can_record_for_student unchanged'; end if;
  execute v_new;

  -- the certificates read policy
  for r in select policyname, tablename, qual from pg_policies where schemaname = 'public' and tablename = 'certificates' and policyname = 'certificates_select' loop
    v_new := regexp_replace(r.qual, v_alias, 'public._is_circle_teacher(\1.id, \2)', 'g');
    if v_new = r.qual then raise exception 'assistant patch: certificates policy unchanged'; end if;
    execute format('alter policy %I on public.%I using (%s)', r.policyname, r.tablename, v_new);
  end loop;

  raise notice 'assistant patch applied to % functions', v_n;
end $$;

-- ---------------------------------------------------------------------
-- notification type
-- ---------------------------------------------------------------------
insert into public.notification_defaults (event_key, name, title_template, body_template, available_vars, lead_hours, roles, sort) values
  ('assistant_assigned', 'تعيين معلم مساعد', 'عُيّنت معلمًا مساعدًا', 'في حلقة {الحلقة}', array['الحلقة'], null, array['teacher'], 200)
on conflict (event_key) do update set name = excluded.name, available_vars = excluded.available_vars, roles = excluded.roles, sort = excluded.sort;

-- ---------------------------------------------------------------------
-- admin: manage assistants; everyone: which circles are mine
-- ---------------------------------------------------------------------
create or replace function public.set_circle_assistants(p_org uuid, p_circle uuid, p_users uuid[])
returns void language plpgsql security definer set search_path = public as $$
declare c public.circles; u uuid; v_new uuid[];
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  select * into c from public.circles where id = p_circle and organization_id = p_org;
  if c.id is null then raise exception 'الحلقة غير موجودة'; end if;
  p_users := coalesce(p_users, array[]::uuid[]);
  if exists (select 1 from unnest(p_users) x where x is not distinct from c.teacher_id) then
    raise exception 'المعلم الأساسي للحلقة لا يُضاف مساعدًا';
  end if;
  if exists (select 1 from unnest(p_users) x where not exists (
      select 1 from public.organization_members m where m.organization_id = p_org and m.user_id = x and m.role::text = 'teacher' and m.status = 'active')) then
    raise exception 'المساعد يجب أن يكون معلمًا نشطًا في المركز';
  end if;
  select coalesce(array_agg(x), array[]::uuid[]) into v_new from unnest(p_users) x where not exists (select 1 from public.circle_assistants a where a.circle_id = p_circle and a.user_id = x);
  delete from public.circle_assistants where circle_id = p_circle and not (user_id = any (p_users));
  foreach u in array v_new loop
    insert into public.circle_assistants (organization_id, circle_id, user_id) values (p_org, p_circle, u) on conflict do nothing;
  end loop;
  if coalesce(array_length(v_new, 1), 0) > 0 then
    perform public._notify(p_org, v_new, 'assistant_assigned', 'عُيّنت معلمًا مساعدًا', c.name, p_circle, jsonb_build_object('الحلقة', c.name));
  end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'circle_assistants', p_circle, jsonb_build_object('assistants', p_users));
end;
$$;

create or replace function public.circle_assistants_list(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object('circle_id', a.circle_id, 'circle_name', c.name, 'user_id', a.user_id, 'name', pr.full_name) order by c.name, pr.full_name)
    from public.circle_assistants a join public.circles c on c.id = a.circle_id left join public.profiles pr on pr.id = a.user_id
    where a.organization_id = p_org), '[]'::jsonb);
end;
$$;

-- the circles this person teaches (primary or assistant), for the "my circles" screens
create or replace function public.my_circle_ids(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', c.id, 'assistant', c.teacher_id is distinct from auth.uid()) order by c.name), '[]'::jsonb)
  from public.circles c
  where c.organization_id = p_org and public._is_circle_teacher(c.id, auth.uid());
$$;

do $$
declare f text;
begin
  foreach f in array array['_is_circle_teacher(uuid, uuid)', 'trg_circle_primary_changed()'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
  foreach f in array array['set_circle_assistants(uuid, uuid, uuid[])', 'circle_assistants_list(uuid)', 'my_circle_ids(uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  -- rewritten functions keep their original privileges (create or replace preserves them), but make sure nothing widened
  foreach f in array array['_audience_users(uuid, text, uuid, uuid)', '_calendar_visible(uuid)', '_teaches_student(uuid)', '_teacher_teaches_any(uuid, uuid[])', '_assert_can_record_for_student(uuid, uuid)'] loop
    begin execute format('revoke all on function public.%s from public, anon', f); exception when undefined_function then null; end;
  end loop;
end $$;

notify pgrst, 'reload schema';
