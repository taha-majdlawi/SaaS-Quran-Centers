-- =========================================================================
-- 0090_recitation_audio_retention.sql
-- Recordings of recitations are not kept forever: once the teacher has
-- reviewed a recitation (approved or returned), its recording is deleted
-- after the number of days the center's admin chose (60 by default, or
-- never). The result, the mistakes and the entry in the student's log stay.
--
-- A file in Storage can only be deleted through the Storage API (the
-- protect_objects_delete trigger refuses SQL), so the daily job asks the web
-- app (/api/recitations/cleanup, the same URL base and shared secret as push,
-- 0040) to delete what is due; it reports back with _recitation_audio_deleted.
-- =========================================================================

alter table public.organizations
  add column if not exists recitation_audio_days integer default 60
  check (recitation_audio_days is null or recitation_audio_days between 7 and 3650);
comment on column public.organizations.recitation_audio_days is
  'Days a reviewed recitation''s recording is kept (null = never deleted).';

alter table public.recitation_submissions add column if not exists audio_deleted_at timestamptz;

-- the admin's choice (null = keep the recordings)
create or replace function public.recitation_audio_days(p_org uuid)
returns integer language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه الصفحة لمدير المركز'; end if;
  return (select recitation_audio_days from public.organizations where id = p_org);
end;
$$;

create or replace function public.set_recitation_audio_days(p_org uuid, p_days integer)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذا الإجراء لمدير المركز'; end if;
  perform public._assert_can_write(p_org);
  if p_days is not null and (p_days < 7 or p_days > 3650) then raise exception 'مدة غير صالحة'; end if;
  update public.organizations set recitation_audio_days = p_days where id = p_org;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'organizations', p_org, jsonb_build_object('recitation_audio_days', p_days));
end;
$$;

-- recordings whose time is up (the web app deletes the files)
create or replace function public._recitation_audio_due(p_limit integer default 500)
returns table (id uuid, audio_path text) language sql stable security definer set search_path = public as $$
  select r.id, r.audio_path
    from public.recitation_submissions r
    join public.organizations o on o.id = r.organization_id
   where r.audio_path is not null
     and r.status in ('approved', 'rejected')
     and o.recitation_audio_days is not null
     and coalesce(r.reviewed_at, r.submitted_at, r.created_at) < now() - make_interval(days => o.recitation_audio_days)
   order by r.reviewed_at
   limit least(greatest(coalesce(p_limit, 500), 1), 1000);
$$;

-- the files are gone: the recitations keep everything else
create or replace function public._recitation_audio_deleted(p_ids uuid[])
returns integer language plpgsql security definer set search_path = public as $$
declare v_n integer;
begin
  update public.recitation_submissions
     set audio_path = null, audio_deleted_at = now()
   where id = any (coalesce(p_ids, '{}')) and audio_path is not null and status in ('approved', 'rejected');
  get diagnostics v_n = row_count;
  return v_n;
end;
$$;

-- the daily job: asks the web app to delete what is due (nothing until push is set up)
create or replace function public.dispatch_recitation_audio_cleanup()
returns void language plpgsql security definer set search_path = public as $$
declare v_url text := public._platform_setting('push_url', ''); v_secret text := public._platform_setting('push_secret', '');
begin
  if v_url = '' or v_secret = '' then return; end if;
  if not exists (select 1 from public._recitation_audio_due(1)) then return; end if;
  perform net.http_post(
    url := regexp_replace(v_url, '/api/push/?$', '/api/recitations/cleanup'),
    body := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', v_secret));
exception when others then
  null;
end;
$$;

revoke all on function public.recitation_audio_days(uuid) from public, anon;
grant execute on function public.recitation_audio_days(uuid) to authenticated;
revoke all on function public.set_recitation_audio_days(uuid, integer) from public, anon;
grant execute on function public.set_recitation_audio_days(uuid, integer) to authenticated;
revoke all on function public._recitation_audio_due(integer) from public, anon, authenticated;
revoke all on function public._recitation_audio_deleted(uuid[]) from public, anon, authenticated;
revoke all on function public.dispatch_recitation_audio_cleanup() from public, anon, authenticated;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public._recitation_audio_due(integer) to service_role;
    grant execute on function public._recitation_audio_deleted(uuid[]) to service_role;
  end if;
end $$;

-- the apps say the recording was deleted, and when
create or replace function public._recitation_json(r public.recitation_submissions)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'id', r.id, 'student_id', r.student_id, 'kind', r.kind, 'type', r.achievement_type, 'surah', r.surah,
    'ayah_from', r.ayah_from, 'ayah_to', r.ayah_to, 'audio_path', r.audio_path, 'duration', r.duration_sec,
    'status', r.status, 'auto_score', r.auto_score, 'auto_result', r.auto_result, 'checked_at', r.checked_at,
    'mistakes', r.mistakes, 'grade', r.grade, 'student_note', r.student_note, 'teacher_note', r.teacher_note,
    'submitted_at', r.submitted_at, 'reviewed_at', r.reviewed_at, 'created_at', r.created_at, 'source', r.source,
    'audio_deleted_at', r.audio_deleted_at,
    'student', (select full_name from public.students_profile where id = r.student_id),
    'circle', (select name from public.circles where id = r.circle_id),
    'reviewer', (select full_name from public.profiles where id = r.reviewed_by));
$$;
revoke all on function public._recitation_json(public.recitation_submissions) from public, anon, authenticated;

select cron.schedule('recitation-audio-cleanup', '50 3 * * *', 'select public.dispatch_recitation_audio_cleanup()');

notify pgrst, 'reload schema';
