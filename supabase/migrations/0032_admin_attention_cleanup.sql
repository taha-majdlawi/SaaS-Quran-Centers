-- =========================================================================
-- 0032_admin_attention_cleanup.sql
-- 1. admin_attention(): what needs the center admin's attention right now, in
--    one call (web + mobile dashboards): waiting approvals / orders / requests,
--    students who have not recited for 14 days, the next events with their
--    registration counts, and the week in numbers.
-- 2. A nightly job trimming data nobody reads again (old notifications and
--    reminder bookkeeping) so the inbox tables do not grow forever.
-- =========================================================================

create or replace function public.admin_attention(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_tz text; v_today date; v_week_start timestamptz;
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  select coalesce(timezone, 'UTC') into v_tz from public.organizations where id = p_org;
  v_today := (now() at time zone v_tz)::date;
  v_week_start := (v_today - 6)::timestamp at time zone v_tz;

  return jsonb_build_object(
    'serd_submitted', (select count(*) from public.serd_sessions where organization_id = p_org and status = 'submitted'),
    'market_pending', (select count(*) from public.market_purchases where organization_id = p_org and status = 'pending'),
    'deletion_pending', (select count(*) from public.deletion_requests where organization_id = p_org and status = 'pending'),
    'inactive_students', coalesce((
      select jsonb_agg(jsonb_build_object('id', x.id, 'name', x.full_name, 'circle', x.circle, 'last_at', x.last_at) order by x.last_at nulls first, x.full_name)
      from (
        select s.id, s.full_name, c.name as circle,
               (select max(da.created_at) from public.daily_achievements da where da.student_id = s.id) as last_at
        from public.students_profile s left join public.circles c on c.id = s.circle_id
        where s.organization_id = p_org and s.status = 'active' and s.created_at < now() - interval '14 days'
          and not exists (select 1 from public.daily_achievements da where da.student_id = s.id and da.created_at > now() - interval '14 days')
        order by 4 nulls first, 2 limit 8) x), '[]'::jsonb),
    'inactive_total', (
      select count(*) from public.students_profile s
      where s.organization_id = p_org and s.status = 'active' and s.created_at < now() - interval '14 days'
        and not exists (select 1 from public.daily_achievements da where da.student_id = s.id and da.created_at > now() - interval '14 days')),
    'upcoming', coalesce((
      select jsonb_agg(jsonb_build_object('id', e.id, 'title', e.title, 'start_date', e.start_date, 'starts_at', e.starts_at,
             'registered', (select count(*) from public.calendar_registrations r where r.entry_id = e.id),
             'capacity', e.capacity) order by e.start_date, e.starts_at)
      from (select * from public.center_calendar where organization_id = p_org and is_working_day
              and end_date >= v_today and start_date <= v_today + 7 order by start_date, starts_at limit 5) e), '[]'::jsonb),
    'week', jsonb_build_object(
      'recitations', (select count(*) from public.daily_achievements where organization_id = p_org and created_at >= v_week_start),
      'points', coalesce((select sum(points_awarded) from public.daily_achievements where organization_id = p_org and created_at >= v_week_start), 0),
      'reciting_students', (select count(distinct student_id) from public.daily_achievements where organization_id = p_org and created_at >= v_week_start),
      'attendance_rate', (select case when count(*) filter (where status::text in ('present', 'late', 'absent')) = 0 then null
                                 else round(100.0 * count(*) filter (where status::text in ('present', 'late')) /
                                            count(*) filter (where status::text in ('present', 'late', 'absent')), 1) end
                          from public.attendance where organization_id = p_org and session_date >= v_today - 6)));
end;
$$;

create or replace function public.cleanup_old_data()
returns integer language plpgsql security definer set search_path = public as $$
declare v_n integer := 0; v_k integer;
begin
  -- read notifications after 60 days, anything after a year
  delete from public.notifications where (read_at is not null and created_at < now() - interval '60 days') or created_at < now() - interval '365 days';
  get diagnostics v_k = row_count; v_n := v_n + v_k;
  -- reminder bookkeeping of events long past
  delete from public.calendar_reminders r using public.center_calendar c
    where c.id = r.entry_id and c.end_date < current_date - 60;
  get diagnostics v_k = row_count; v_n := v_n + v_k;
  return v_n;
end;
$$;

select cron.schedule('cleanup-old-data', '15 3 * * *', 'select public.cleanup_old_data()');

revoke all on function public.admin_attention(uuid) from public, anon;
grant execute on function public.admin_attention(uuid) to authenticated;
revoke all on function public.cleanup_old_data() from public, anon, authenticated;
grant execute on function public.get_invitation(uuid) to anon;
notify pgrst, 'reload schema';
