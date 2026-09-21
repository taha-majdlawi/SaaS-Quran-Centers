-- Center admin: see WHO has a registered phone and send the test to any of them.
drop function if exists public.send_test_push(uuid);
drop function if exists public.push_status(uuid);

create or replace function public.push_status(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return jsonb_build_object(
    'configured', public._platform_setting('push_url', '') <> '',
    'my_id', auth.uid(),
    'members', (select count(*) from public.organization_members where organization_id = p_org and status = 'active'),
    'registered', coalesce((
      select jsonb_agg(jsonb_build_object('user_id', x.user_id, 'name', x.full_name, 'role', x.role, 'devices', x.n) order by x.role, x.full_name)
      from (select m.user_id, p.full_name, m.role::text as role, count(d.id) as n
            from public.organization_members m
            join public.device_tokens d on d.user_id = m.user_id
            left join public.profiles p on p.id = m.user_id
            where m.organization_id = p_org and m.status = 'active'
            group by m.user_id, p.full_name, m.role) x), '[]'::jsonb));
end;
$$;

-- p_user null = my own phones; otherwise any registered member of the center
create or replace function public.send_test_push(p_org uuid, p_user uuid default null)
returns integer language plpgsql security definer set search_path = public as $$
declare v_target uuid := coalesce(p_user, auth.uid()); v_n integer;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  if not exists (select 1 from public.organization_members where organization_id = p_org and user_id = v_target and status = 'active') then
    raise exception 'هذا الشخص ليس عضوًا نشطًا في المركز';
  end if;
  select count(*) into v_n from public.device_tokens where user_id = v_target;
  if v_n = 0 then
    raise exception 'لا يوجد هاتف مسجّل لهذا الحساب: يجب أن يفتح صاحبه التطبيق على هاتفه ويسجّل الدخول ويوافق على الإشعارات';
  end if;
  insert into public.notifications (organization_id, user_id, event_key, title, body)
  values (p_org, v_target, 'test', 'إشعار تجريبي ✓', 'الإشعارات الفورية تعمل على هاتفك');
  return v_n;
end;
$$;

revoke all on function public.push_status(uuid) from public, anon;
revoke all on function public.send_test_push(uuid, uuid) from public, anon;
grant execute on function public.push_status(uuid) to authenticated;
grant execute on function public.send_test_push(uuid, uuid) to authenticated;
grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
