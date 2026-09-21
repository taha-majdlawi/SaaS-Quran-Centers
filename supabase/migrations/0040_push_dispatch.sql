-- =========================================================================
-- 0040_push_dispatch.sql
-- Push notifications (FCM). Every new inbox notification and every new chat
-- message asks the web app's /api/push endpoint (shared-secret protected) to
-- deliver it to the recipient's registered phones. The URL and the secret live
-- in platform_settings (closed to every API role); until push_url is set this
-- does nothing, and a delivery problem can never block the write itself.
-- =========================================================================
create extension if not exists pg_net;

create or replace function public._push_dispatch(p_kind text, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_url text := public._platform_setting('push_url', ''); v_secret text := public._platform_setting('push_secret', '');
begin
  if v_url = '' or v_secret = '' then return; end if;
  perform net.http_post(
    url := v_url,
    body := jsonb_build_object('kind', p_kind, 'id', p_id),
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', v_secret));
exception when others then
  null; -- never let a push problem block the write
end;
$$;

create or replace function public.trg_push_notification()
returns trigger language plpgsql security definer set search_path = public as $$
begin perform public._push_dispatch('notification', new.id); return new; end;
$$;
create or replace function public.trg_push_chat()
returns trigger language plpgsql security definer set search_path = public as $$
begin perform public._push_dispatch('chat', new.id); return new; end;
$$;

drop trigger if exists z_push_notification on public.notifications;
create trigger z_push_notification after insert on public.notifications for each row execute function public.trg_push_notification();
drop trigger if exists z_push_chat on public.chat_messages;
create trigger z_push_chat after insert on public.chat_messages for each row execute function public.trg_push_chat();

-- sign-out on a phone: stop delivering that account's messages to it
create or replace function public.unregister_device_token(p_token text)
returns void language sql security definer set search_path = public as $$
  delete from public.device_tokens where token = p_token and user_id = auth.uid();
$$;

revoke all on function public._push_dispatch(text, uuid) from public, anon, authenticated;
revoke all on function public.trg_push_notification() from public, anon, authenticated;
revoke all on function public.trg_push_chat() from public, anon, authenticated;
revoke all on function public.unregister_device_token(text) from public, anon;
grant execute on function public.unregister_device_token(text) to authenticated;
grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
