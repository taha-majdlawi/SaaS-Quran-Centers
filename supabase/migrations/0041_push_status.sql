-- Center admin's view of push notifications: how many phones are registered (per role) and a
-- test message to the admin's own phones.
create or replace function public.push_status(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return jsonb_build_object(
    'configured', public._platform_setting('push_url', '') <> '',
    'my_devices', (select count(*) from public.device_tokens where user_id = auth.uid()),
    'devices', coalesce((
      select jsonb_object_agg(role, n) from (
        select m.role::text as role, count(distinct d.id) as n
        from public.device_tokens d
        join public.organization_members m on m.user_id = d.user_id and m.organization_id = p_org and m.status = 'active'
        group by m.role) t), '{}'::jsonb),
    'people', coalesce((
      select jsonb_object_agg(role, n) from (
        select m.role::text as role, count(distinct d.user_id) as n
        from public.device_tokens d
        join public.organization_members m on m.user_id = d.user_id and m.organization_id = p_org and m.status = 'active'
        group by m.role) t), '{}'::jsonb));
end;
$$;

create or replace function public.send_test_push(p_org uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare v_n integer;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  select count(*) into v_n from public.device_tokens where user_id = auth.uid();
  if v_n = 0 then raise exception 'لا يوجد هاتف مسجّل لحسابك: افتح التطبيق على هاتفك وسجّل الدخول ووافق على الإشعارات'; end if;
  insert into public.notifications (organization_id, user_id, event_key, title, body)
  values (p_org, auth.uid(), 'test', 'إشعار تجريبي ✓', 'الإشعارات الفورية تعمل على هاتفك');
  return v_n;
end;
$$;

revoke all on function public.push_status(uuid) from public, anon;
revoke all on function public.send_test_push(uuid) from public, anon;
grant execute on function public.push_status(uuid) to authenticated;
grant execute on function public.send_test_push(uuid) to authenticated;
grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
