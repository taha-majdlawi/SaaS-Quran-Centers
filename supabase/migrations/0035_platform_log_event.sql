-- Lets the console record owner actions that go through the service role (ban, password, delete user).
create or replace function public.platform_log_event(p_action text, p_target text, p_detail jsonb default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._plat_guard();
  perform public._plat_log(left(p_action, 60), left(p_target, 100), p_detail);
end;
$$;
revoke all on function public.platform_log_event(text, text, jsonb) from public, anon;
grant execute on function public.platform_log_event(text, text, jsonb) to authenticated;
grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
