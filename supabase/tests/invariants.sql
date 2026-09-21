-- Regression checks for the rules that must never silently break. Runs against
-- the live DB inside ONE statement that ends in RAISE EXCEPTION, so nothing is
-- ever committed. Expect the final message to start with "RESULT: OK".
-- Needs a center with one admin, one teacher and one student account (the
-- 'eqraa' demo center). Run:  bash supabase/tests/run.sh
do $$
declare
  v_org uuid; v_adm uuid; v_tch uuid; v_stu uuid; v_sp uuid; v_circle uuid; v_grade text;
  v_fail text[] := '{}'; v_n integer; v_before integer; v_after integer; v_cert uuid; r jsonb;
  v_exempt text[] := array['account_access', 'account_admin_grants', 'audit_log', 'deletion_requests', 'device_tokens',
                           'notification_prefs', 'notifications', 'quran_bookmarks', 'quran_positions', 'calendar_reminders', 'weekly_digests_sent', 'attendance_reminders_sent'];
begin
  select id into v_org from public.organizations where slug = 'eqraa';
  select user_id into v_adm from public.organization_members where organization_id = v_org and role = 'admin' and status = 'active' limit 1;
  select user_id into v_tch from public.organization_members where organization_id = v_org and role = 'teacher' and status = 'active' limit 1;
  select user_id into v_stu from public.organization_members where organization_id = v_org and role = 'student' and status = 'active' limit 1;
  select id, circle_id, total_points into v_sp, v_circle, v_before from public.students_profile where organization_id = v_org and circle_id is not null limit 1;
  select key into v_grade from public.recitation_grades where organization_id = v_org limit 1;
  if v_org is null or v_adm is null or v_tch is null or v_stu is null or v_sp is null then
    raise exception 'RESULT: SKIPPED - needs the eqraa demo center with admin/teacher/student/student profile';
  end if;

  -- ===== admin cannot touch billing / status / slug; points only come from recitations
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin update public.organizations set plan_id = plan_id where id = v_org; v_fail := v_fail || 'org.plan_id writable'; exception when others then null; end;
  begin update public.organizations set status = status where id = v_org; v_fail := v_fail || 'org.status writable'; exception when others then null; end;
  begin update public.organizations set slug = slug where id = v_org; v_fail := v_fail || 'org.slug writable'; exception when others then null; end;
  begin update public.students_profile set total_points = 99999 where id = v_sp; v_fail := v_fail || 'student points writable'; exception when others then null; end;
  begin insert into public.audit_log (organization_id, actor_id, action, entity_table) values (v_org, gen_random_uuid(), 'x', 'y'); v_fail := v_fail || 'audit actor forgeable'; exception when others then null; end;
  perform public.log_recitation(v_org, v_sp, 'new_memorization', 1, 1, 2, v_grade, null, gen_random_uuid(), now(), null);
  reset role;
  select total_points into v_after from public.students_profile where id = v_sp;
  if v_after <= v_before then v_fail := v_fail || 'recitation did not add points'; end if;

  -- ===== viewing accounts
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  perform public.set_account_access(v_org, v_tch, true, 'test');
  begin perform public.set_account_access(v_org, v_adm, true); v_fail := v_fail || 'self flag allowed'; exception when others then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.log_recitation(v_org, v_sp, 'new_memorization', 1, 1, 2, v_grade, null, gen_random_uuid(), now(), null); v_fail := v_fail || 'viewer recitation saved'; exception when others then null; end;
  begin insert into public.attendance (organization_id, student_id, circle_id, session_date, status) values (v_org, v_sp, v_circle, current_date, 'present'); v_fail := v_fail || 'viewer attendance saved'; exception when others then null; end;
  begin
    perform public.get_teacher_today(v_org); perform public.chat_threads_list(v_org);
    perform public.list_announcements(v_org); perform public.get_reading_state(v_org);
  exception when others then v_fail := v_fail || 'viewer READ failed: ' || sqlerrm; end;
  reset role;
  -- a viewing admin can neither lift the lock nor issue things
  insert into public.account_access (user_id, organization_id, is_read_only) values (v_adm, v_org, true)
    on conflict (user_id, organization_id) do update set is_read_only = true;
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.set_account_access(v_org, v_tch, false); v_fail := v_fail || 'viewer admin unlocked'; exception when others then null; end;
  begin
    update public.account_access set is_read_only = false where user_id = v_adm;
    get diagnostics v_n = row_count;
    if v_n > 0 then v_fail := v_fail || 'account_access directly writable'; end if;
  exception when others then null; end;
  begin perform public.issue_certificate(v_org, v_sp, 'custom', 'x y'); v_fail := v_fail || 'viewer admin issued cert'; exception when others then null; end;
  reset role;
  delete from public.account_access where user_id = v_adm and organization_id = v_org;

  -- ===== certificates + public verify
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v_cert := public.issue_certificate(v_org, v_sp, 'excellence', 'شهادة تفوق', 'اختبار');
  r := public.get_certificate(v_org, v_cert);
  if coalesce(public.verify_certificate('eqraa', r ->> 'serial') ->> 'valid', '') <> 'true' then v_fail := v_fail || 'verify failed'; end if;
  if public.verify_certificate('tabean', r ->> 'serial') is not null then v_fail := v_fail || 'verify leaks across centers'; end if;
  begin perform public.issue_certificate(v_org, v_sp, 'serd', 'x y'); v_fail := v_fail || 'generic serd cert allowed'; exception when others then null; end;

  -- ===== the platform console is closed to center admins
  begin perform public.platform_org_detail(v_org); v_fail := v_fail || 'admin can read platform_org_detail'; exception when others then null; end;
  begin perform public.platform_set_feature(v_org, 'chat', false); v_fail := v_fail || 'admin can switch features'; exception when others then null; end;
  begin perform public.platform_users(); v_fail := v_fail || 'admin can list all accounts'; exception when others then null; end;
  begin perform public.platform_save_plan(null, 'zz', 'zz', 0, 'USD', 1, 1, '{}'::jsonb, true); v_fail := v_fail || 'admin can edit plans'; exception when others then null; end;
  begin perform public.platform_save_notice(null, 'zz zz', null, 'info', true, null); v_fail := v_fail || 'admin can publish platform notices'; exception when others then null; end;

  -- ===== reports + dashboard summary work
  r := public.center_report(v_org, current_date - 30, current_date);
  if r -> 'totals' is null then v_fail := v_fail || 'center_report empty'; end if;
  r := public.admin_attention(v_org);
  if r -> 'week' is null then v_fail := v_fail || 'admin_attention empty'; end if;
  reset role;

  -- ===== a student sees only their own center, and cannot run admin reports
  perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_n from public.students_profile where organization_id <> v_org;
  if v_n > 0 then v_fail := v_fail || 'student sees other centers'; end if;
  begin perform public.center_report(v_org); v_fail := v_fail || 'student can run center_report'; exception when others then null; end;
  begin perform public.admin_attention(v_org); v_fail := v_fail || 'student can run admin_attention'; exception when others then null; end;
  begin perform public.platform_overview(); v_fail := v_fail || 'student can run platform_overview'; exception when others then null; end;
  begin perform public.platform_set_org(v_org, 'suspended'); v_fail := v_fail || 'student can run platform_set_org'; exception when others then null; end;
  reset role;

  -- ===== nothing new is left unlocked without a reason
  select count(*) into v_n from public.tables_without_write_lock() t where t <> all (v_exempt);
  if v_n > 0 then
    v_fail := v_fail || ('tables without write lock: ' || (select string_agg(t, ',') from public.tables_without_write_lock() t where t <> all (v_exempt)));
  end if;

  -- ===== notification centre: admin-only management, templates are honoured, muted/disabled types insert nothing
  perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.admin_notification_config(v_org); v_fail := v_fail || 'student can read notification config'; exception when others then null; end;
  begin perform public.admin_send_notification(v_org, 'a', 'b'); v_fail := v_fail || 'student can broadcast'; exception when others then null; end;
  begin perform public.admin_save_notification_settings(v_org, '21:00', '07:00', '07:00', 12, 3, true); v_fail := v_fail || 'student can change notification settings'; exception when others then null; end;
  begin perform public.admin_notification_log(v_org); v_fail := v_fail || 'student can read the delivery log'; exception when others then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  perform public.admin_save_notification_template(v_org, 'announcement', 'مركز: {العنوان}', '{الوصف}', null, 'source', true);
  perform public.save_announcement(v_org, null, 'عنوان اختبار', 'نص', 'all', null, false, true, null);
  reset role;
  select count(*) into v_n from public.notifications where organization_id = v_org and event_key = 'announcement' and title = 'مركز: عنوان اختبار' and created_at > now() - interval '1 minute';
  if v_n = 0 then v_fail := v_fail || 'a saved template is not used for the notification wording'; end if;
  set local role authenticated;
  perform public.admin_save_notification_template(v_org, 'announcement', 'x', 'y', null, 'source', false);
  reset role;
  select count(*) into v_before from public.notifications where organization_id = v_org and event_key = 'announcement';
  set local role authenticated;
  perform public.save_announcement(v_org, null, 'ثانٍ', 'نص', 'all', null, false, true, null);
  reset role;
  select count(*) into v_after from public.notifications where organization_id = v_org and event_key = 'announcement';
  if v_after <> v_before then v_fail := v_fail || 'a disabled notification type still reaches people'; end if;

  -- ===== the anonymous door is exactly three functions
  select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')
      and p.proname not in ('get_invitation', 'get_public_site', 'verify_certificate');
  if v_n > 0 then v_fail := v_fail || ('anon can execute ' || v_n || ' extra functions'); end if;

  raise exception 'RESULT: %', case when array_length(v_fail, 1) is null then 'OK' else 'FAILED - ' || array_to_string(v_fail, '; ') end;
end $$;
