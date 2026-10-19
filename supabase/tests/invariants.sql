-- Regression checks for the rules that must never silently break. Runs against
-- the live DB inside ONE statement that ends in RAISE EXCEPTION, so nothing is
-- ever committed. Expect the final message to start with "RESULT: OK".
-- Needs a center with one admin, one teacher and one student account (the
-- 'eqraa' demo center). Run:  bash supabase/tests/run.sh
do $$
declare
  v_org uuid; v_adm uuid; v_tch uuid; v_stu uuid; v_sp uuid; v_circle uuid; v_grade text;
  v_adm_is_owner boolean := false;
  v_fail text[] := '{}'; v_n integer; v_before integer; v_after integer; v_cert uuid; r jsonb;
  v_exempt text[] := array['account_access', 'account_admin_grants', 'audit_log', 'deletion_requests', 'device_tokens',
                           'notification_prefs', 'notifications', 'quran_bookmarks', 'quran_positions', 'calendar_reminders', 'weekly_digests_sent', 'attendance_reminders_sent',
                           -- 0066: a center locked for non-payment must still be able to report its payment (RPC-only writes)
                           'billing_requests',
                           -- 0076: crash reports must arrive from view-only accounts too (RPC-only writes)
                           'app_errors'];
begin
  select id into v_org from public.organizations where slug = 'eqraa';
  -- prefer an admin who is NOT also a platform owner: an owner may legitimately use the platform console,
  -- so the "center admins cannot" checks below only mean something for a plain admin
  select m.user_id into v_adm from public.organization_members m where m.organization_id = v_org and m.role = 'admin' and m.status = 'active'
   order by exists (select 1 from public.platform_owners po where po.user_id = m.user_id) limit 1;
  v_adm_is_owner := exists (select 1 from public.platform_owners where user_id = v_adm);
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
  begin update public.organizations set plan_id = plan_id where id = v_org; v_fail := v_fail || text 'org.plan_id writable'; exception when others then null; end;
  begin update public.organizations set status = status where id = v_org; v_fail := v_fail || text 'org.status writable'; exception when others then null; end;
  begin update public.organizations set slug = slug where id = v_org; v_fail := v_fail || text 'org.slug writable'; exception when others then null; end;
  begin update public.students_profile set total_points = 99999 where id = v_sp; v_fail := v_fail || text 'student points writable'; exception when others then null; end;
  begin insert into public.audit_log (organization_id, actor_id, action, entity_table) values (v_org, gen_random_uuid(), 'x', 'y'); v_fail := v_fail || text 'audit actor forgeable'; exception when others then null; end;
  perform public.log_recitation(v_org, v_sp, 'new_memorization', 1, 1, 2, v_grade, null, gen_random_uuid(), now(), null);
  reset role;
  select total_points into v_after from public.students_profile where id = v_sp;
  if v_after <= v_before then v_fail := v_fail || text 'recitation did not add points'; end if;

  -- ===== viewing accounts
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  perform public.set_account_access(v_org, v_tch, true, 'test');
  begin perform public.set_account_access(v_org, v_adm, true); v_fail := v_fail || text 'self flag allowed'; exception when others then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.log_recitation(v_org, v_sp, 'new_memorization', 1, 1, 2, v_grade, null, gen_random_uuid(), now(), null); v_fail := v_fail || text 'viewer recitation saved'; exception when others then null; end;
  begin insert into public.attendance (organization_id, student_id, circle_id, session_date, status) values (v_org, v_sp, v_circle, current_date, 'present'); v_fail := v_fail || text 'viewer attendance saved'; exception when others then null; end;
  begin
    perform public.get_teacher_today(v_org); perform public.chat_threads_list(v_org);
    perform public.list_announcements(v_org); perform public.get_reading_state(v_org);
  exception when others then v_fail := v_fail || text 'viewer READ failed: ' || sqlerrm; end;
  reset role;
  -- a viewing admin can neither lift the lock nor issue things
  insert into public.account_access (user_id, organization_id, is_read_only) values (v_adm, v_org, true)
    on conflict (user_id, organization_id) do update set is_read_only = true;
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.set_account_access(v_org, v_tch, false); v_fail := v_fail || text 'viewer admin unlocked'; exception when others then null; end;
  begin
    update public.account_access set is_read_only = false where user_id = v_adm;
    get diagnostics v_n = row_count;
    if v_n > 0 then v_fail := v_fail || text 'account_access directly writable'; end if;
  exception when others then null; end;
  begin perform public.issue_certificate(v_org, v_sp, 'custom', 'x y'); v_fail := v_fail || text 'viewer admin issued cert'; exception when others then null; end;
  reset role;
  -- the teacher was flagged read-only above too; unflag both, or every later teacher-write
  -- check below would pass only because of the viewer lock
  delete from public.account_access where user_id in (v_adm, v_tch) and organization_id = v_org;

  -- ===== certificates + public verify
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  v_cert := public.issue_certificate(v_org, v_sp, 'excellence', 'شهادة تفوق', 'اختبار');
  r := public.get_certificate(v_org, v_cert);
  if coalesce(public.verify_certificate('eqraa', r ->> 'serial') ->> 'valid', '') <> 'true' then v_fail := v_fail || text 'verify failed'; end if;
  if public.verify_certificate('tabean', r ->> 'serial') is not null then v_fail := v_fail || text 'verify leaks across centers'; end if;
  begin perform public.issue_certificate(v_org, v_sp, 'serd', 'x y'); v_fail := v_fail || text 'generic serd cert allowed'; exception when others then null; end;

  -- ===== the platform console is closed to center admins (only checkable with a plain admin)
  if not v_adm_is_owner then
    begin perform public.platform_org_detail(v_org); v_fail := v_fail || text 'admin can read platform_org_detail'; exception when others then null; end;
    begin perform public.platform_set_feature(v_org, 'chat', false); v_fail := v_fail || text 'admin can switch features'; exception when others then null; end;
    begin perform public.platform_users(); v_fail := v_fail || text 'admin can list all accounts'; exception when others then null; end;
    begin perform public.platform_save_plan(null, 'zz', 'zz', 0, 'USD', 1, 1, '{}'::jsonb, true); v_fail := v_fail || text 'admin can edit plans'; exception when others then null; end;
    begin perform public.platform_save_notice(null, 'zz zz', null, 'info', true, null); v_fail := v_fail || text 'admin can publish platform notices'; exception when others then null; end;
  end if;

  -- ===== reports + dashboard summary work
  r := public.center_report(v_org, current_date - 30, current_date);
  if r -> 'totals' is null then v_fail := v_fail || text 'center_report empty'; end if;
  r := public.admin_attention(v_org);
  if r -> 'week' is null then v_fail := v_fail || text 'admin_attention empty'; end if;
  reset role;

  -- ===== a student sees only their own center, and cannot run admin reports
  perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated')::text, true);
  set local role authenticated;
  select count(*) into v_n from public.students_profile where organization_id <> v_org;
  if v_n > 0 then v_fail := v_fail || text 'student sees other centers'; end if;
  begin perform public.center_report(v_org); v_fail := v_fail || text 'student can run center_report'; exception when others then null; end;
  begin perform public.admin_attention(v_org); v_fail := v_fail || text 'student can run admin_attention'; exception when others then null; end;
  begin perform public.platform_overview(); v_fail := v_fail || text 'student can run platform_overview'; exception when others then null; end;
  begin perform public.platform_set_org(v_org, 'suspended'); v_fail := v_fail || text 'student can run platform_set_org'; exception when others then null; end;
  reset role;

  -- ===== nothing new is left unlocked without a reason
  select count(*) into v_n from public.tables_without_write_lock() t where t <> all (v_exempt);
  if v_n > 0 then
    v_fail := v_fail || ('tables without write lock: ' || (select string_agg(t, ',') from public.tables_without_write_lock() t where t <> all (v_exempt)));
  end if;

  -- ===== notification centre: admin-only management, templates are honoured, muted/disabled types insert nothing
  perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.admin_notification_config(v_org); v_fail := v_fail || text 'student can read notification config'; exception when others then null; end;
  begin perform public.admin_send_notification(v_org, 'a', 'b'); v_fail := v_fail || text 'student can broadcast'; exception when others then null; end;
  begin perform public.admin_save_notification_settings(v_org, '21:00', '07:00', '07:00', 12, 3, true); v_fail := v_fail || text 'student can change notification settings'; exception when others then null; end;
  begin perform public.admin_notification_log(v_org); v_fail := v_fail || text 'student can read the delivery log'; exception when others then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  perform public.admin_save_notification_template(v_org, 'announcement', 'مركز: {العنوان}', '{الوصف}', null, 'source', true);
  perform public.save_announcement(v_org, null, 'عنوان اختبار', 'نص', 'all', null, false, true, null);
  reset role;
  select count(*) into v_n from public.notifications where organization_id = v_org and event_key = 'announcement' and title = 'مركز: عنوان اختبار' and created_at > now() - interval '1 minute';
  if v_n = 0 then v_fail := v_fail || text 'a saved template is not used for the notification wording'; end if;
  set local role authenticated;
  perform public.admin_save_notification_template(v_org, 'announcement', 'x', 'y', null, 'source', false);
  reset role;
  select count(*) into v_before from public.notifications where organization_id = v_org and event_key = 'announcement';
  set local role authenticated;
  perform public.save_announcement(v_org, null, 'ثانٍ', 'نص', 'all', null, false, true, null);
  reset role;
  select count(*) into v_after from public.notifications where organization_id = v_org and event_key = 'announcement';
  if v_after <> v_before then v_fail := v_fail || text 'a disabled notification type still reaches people'; end if;

  -- ===== parity round 2: insight / export / notes functions stay behind their roles
  perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.due_reviews(v_org); v_fail := v_fail || text 'student can read review schedule'; exception when others then null; end;
  begin perform public.search_global(v_org, 'ab'); v_fail := v_fail || text 'student can use global search'; exception when others then null; end;
  begin perform public.list_student_notes(v_org, v_sp); v_fail := v_fail || text 'student can read teacher notes'; exception when others then null; end;
  begin perform public.add_student_note(v_org, v_sp, 'x'); v_fail := v_fail || text 'student can write teacher notes'; exception when others then null; end;
  begin perform public.admin_export_data(v_org); v_fail := v_fail || text 'student can export data'; exception when others then null; end;
  begin perform public.admin_dropout_risk(v_org); v_fail := v_fail || text 'student can read dropout risk'; exception when others then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.admin_export_data(v_org); v_fail := v_fail || text 'teacher can export data'; exception when others then null; end;
  begin perform public.admin_teacher_performance(v_org); v_fail := v_fail || text 'teacher can read teacher performance'; exception when others then null; end;
  begin perform public.admin_set_teacher_attendance(v_org, v_tch, v_circle, current_date, 'present'); v_fail := v_fail || text 'teacher can set attendance as admin'; exception when others then null; end;
  reset role;

  -- ===== gatherings / external recitations: staff-only, admin-only review
  perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.submit_gathering(v_org, 'x', null, null, null, null, array['a']); v_fail := v_fail || text 'student can upload a gathering'; exception when others then null; end;
  begin perform public.submit_external_recitation(v_org, 'x', 'new_memorization', 1, 1, 2, 'x'); v_fail := v_fail || text 'student can upload an external recitation'; exception when others then null; end;
  begin perform public.admin_list_gatherings(v_org); v_fail := v_fail || text 'student can list gatherings'; exception when others then null; end;
  begin perform public.admin_list_external_recitations(v_org); v_fail := v_fail || text 'student can list external recitations'; exception when others then null; end;
  begin perform public.admin_pending_reviews(v_org); v_fail := v_fail || text 'student can read pending reviews'; exception when others then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.admin_list_gatherings(v_org); v_fail := v_fail || text 'teacher can list every gathering'; exception when others then null; end;
  begin perform public.admin_list_external_recitations(v_org); v_fail := v_fail || text 'teacher can list every external recitation'; exception when others then null; end;
  begin perform public.admin_match_external_recitation(gen_random_uuid(), v_sp); v_fail := v_fail || text 'teacher can link external recitations'; exception when others then null; end;
  reset role;

  -- ===== assistant teachers: inherit their circle only, cannot manage assistants, lose access when removed
  begin
    declare v_asst uuid := gen_random_uuid(); v_prim uuid; v_c uuid; v_s uuid;
    begin
      select c.teacher_id, c.id into v_prim, v_c from public.circles c where c.organization_id = v_org and c.teacher_id is not null and exists (select 1 from public.students_profile x where x.circle_id = c.id) limit 1;
      select id into v_s from public.students_profile where circle_id = v_c limit 1;
      -- needs a circle with a teacher and a student (a real center may have none yet): skipped then
      if v_c is not null and v_s is not null then
      perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
      insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
        values (v_asst, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'asst-test-' || v_asst || '@example.test', '{}', '{}', now(), now());
      insert into public.organization_members (organization_id, user_id, role, status) values (v_org, v_asst, 'teacher', 'active');
      perform set_config('request.jwt.claims', json_build_object('sub', v_asst, 'role', 'authenticated')::text, true);
      set local role authenticated;
      if public._teaches_student(v_s) then v_fail := v_fail || text 'unassigned teacher teaches a circle student'; end if;
      reset role;
      perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
      insert into public.circle_assistants (organization_id, circle_id, user_id) values (v_org, v_c, v_asst);
      perform set_config('request.jwt.claims', json_build_object('sub', v_asst, 'role', 'authenticated')::text, true);
      set local role authenticated;
      if not public._teaches_student(v_s) then v_fail := v_fail || text 'assistant does not inherit the circle'; end if;
      begin perform public.set_circle_assistants(v_org, v_c, array[]::uuid[]); v_fail := v_fail || text 'assistant can manage assistants'; exception when others then null; end;
      reset role;
      perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
      delete from public.circle_assistants where user_id = v_asst;
      perform set_config('request.jwt.claims', json_build_object('sub', v_asst, 'role', 'authenticated')::text, true);
      set local role authenticated;
      if public._teaches_student(v_s) then v_fail := v_fail || text 'removed assistant keeps access'; end if;
      reset role;
      end if;
    end;
  end;

  -- ===== chat delete: sender-only, tombstone blocks further edits, due-reviews is staff-only
  -- (skipped when the platform switched chat off for this center - e.g. its plan closes it)
  if public.platform_feature_enabled(v_org, 'chat') then
  begin
    declare v_msg uuid; v_thread uuid; r2 jsonb;
    begin
      perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
      set local role authenticated;
      r2 := public.send_chat_message(v_org, v_tch, 'رسالة فحص الحذف', gen_random_uuid());
      v_msg := (r2 ->> 'message_id')::uuid;
      reset role;
      perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated')::text, true);
      set local role authenticated;
      begin perform public.delete_chat_message(v_msg); v_fail := v_fail || text 'non-sender can delete a chat message'; exception when others then null; end;
      reset role;
      perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
      set local role authenticated;
      perform public.delete_chat_message(v_msg);
      begin perform public.edit_chat_message(v_msg, 'x'); v_fail := v_fail || text 'a deleted chat message can still be edited'; exception when others then null; end;
      reset role;
      perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated')::text, true);
      set local role authenticated;
      begin perform public.student_due_reviews(v_org, v_sp); v_fail := v_fail || text 'student can read the review schedule'; exception when others then null; end;
      reset role;
    end;
  end;
  end if;

  -- ===== teacher circle scoping (0051): a teacher sees/writes only their own circle's data
  begin
    declare v_own_circle uuid; v_other_circle uuid; v_other_sp uuid;
    begin
      select id into v_own_circle from public.circles where organization_id = v_org and teacher_id = v_tch limit 1;
      select id into v_other_circle from public.circles where organization_id = v_org and id is distinct from v_own_circle and teacher_id is distinct from v_tch
        and not exists (select 1 from public.circle_assistants a where a.circle_id = circles.id and a.user_id = v_tch) limit 1;
      select id into v_other_sp from public.students_profile where circle_id = v_other_circle limit 1;
      if v_own_circle is not null and v_other_circle is not null then
        perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated')::text, true);
        set local role authenticated;
        if exists (select 1 from public.circles where id = v_other_circle) then v_fail := v_fail || text 'teacher can read another circle'; end if;
        if v_other_sp is not null and exists (select 1 from public.students_profile where id = v_other_sp) then v_fail := v_fail || text 'teacher can read another circle''s student'; end if;
        begin update public.circles set name = name where id = v_own_circle; get diagnostics v_n = row_count; if v_n > 0 then v_fail := v_fail || text 'teacher can rename their own circle (should be admin-only now)'; end if; exception when others then null; end;
        if v_other_sp is not null then
          begin update public.students_profile set full_name = full_name where id = v_other_sp; get diagnostics v_n = row_count; if v_n > 0 then v_fail := v_fail || text 'teacher can edit another circle''s student'; end if; exception when others then null; end;
          begin insert into public.attendance (organization_id, student_id, circle_id, session_date, status, recorded_by) values (v_org, v_other_sp, v_other_circle, current_date, 'present', v_tch); v_fail := v_fail || text 'teacher can mark another circle''s attendance'; exception when others then null; end;
          -- 0059: the row's circle_id is caller-chosen - labelling it with MY circle must not help
          begin insert into public.attendance (organization_id, student_id, circle_id, session_date, status, recorded_by) values (v_org, v_other_sp, v_own_circle, current_date, 'present', v_tch); v_fail := v_fail || text 'teacher can mark another circle''s attendance via a spoofed circle_id'; exception when others then null; end;
          -- 0060: the SECURITY DEFINER student-portal reads are scoped the same way
          if not public.member_has_module(v_org, 'reports') then
            begin perform public.get_student_dashboard(v_org, v_other_sp); v_fail := v_fail || text 'teacher can read another circle''s dashboard'; exception when others then null; end;
            begin perform public.student_record_detail(v_org, v_other_sp); v_fail := v_fail || text 'teacher can read another circle''s record'; exception when others then null; end;
          end if;
          -- 0058: raw student_notes is scoped like list_student_notes
          if exists (select 1 from public.student_notes where student_id = v_other_sp) then v_fail := v_fail || text 'teacher can read another circle''s notes'; end if;
        end if;
        reset role;
      end if;
    end;
  end;

  -- ===== security audit (0057-0064): RPC-only tables, member e-mails, internal seeders, viewer escapes
  perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin
    insert into public.daily_achievements (organization_id, student_id, circle_id, achievement_type, surah_from, ayah_from, surah_to, ayah_to, grade, points_awarded)
      select v_org, sp.id, sp.circle_id, 'new_memorization', 1, 1, 1, 2, v_grade, 100000
      from public.students_profile sp where sp.organization_id = v_org and public._teaches_student(sp.id) limit 1;
    get diagnostics v_n = row_count;
    if v_n > 0 then v_fail := v_fail || text 'daily_achievements directly writable (forged points)'; end if;
  exception when others then null; end;
  begin insert into public.student_notes (organization_id, student_id, author_id, body) values (v_org, v_sp, v_tch, 'x'); v_fail := v_fail || text 'student_notes directly writable'; exception when others then null; end;
  begin perform public.seed_organization_defaults(v_org); v_fail := v_fail || text 'seed_organization_defaults callable by clients'; exception when others then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.list_org_members(v_org); v_fail := v_fail || text 'student can list member e-mails'; exception when others then null; end;
  reset role;
  insert into public.account_access (user_id, organization_id, is_read_only) values (v_adm, v_org, true)
    on conflict (user_id, organization_id) do update set is_read_only = true;
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin insert into public.account_admin_grants (organization_id, user_id) values (v_org, v_tch); v_fail := v_fail || text 'viewer admin can grant admin'; exception when others then null; end;
  begin update public.organizations set name = name where id = v_org; v_fail := v_fail || text 'viewer admin can edit the center'; exception when others then null; end;
  reset role;
  delete from public.account_access where user_id = v_adm and organization_id = v_org;

  -- ===== 0065: a signed-in account with NO membership in this center gets nothing
  -- (is_org_admin/is_org_staff/member_has_module used to return NULL for it, which
  -- plpgsql `if not ...` guards silently let through)
  begin
    declare v_out uuid := gen_random_uuid();
    begin
      insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
        values (v_out, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'outsider-test-' || v_out || '@example.test', '{}', '{}', now(), now());
      perform set_config('request.jwt.claims', json_build_object('sub', v_out, 'role', 'authenticated')::text, true);
      set local role authenticated;
      if public.is_org_admin(v_org) is null or public.is_org_staff(v_org) is null or public.member_has_module(v_org, 'reports') is null then
        v_fail := v_fail || text 'role helpers return NULL for outsiders';
      end if;
      begin perform public.admin_export_data(v_org); v_fail := v_fail || text 'outsider exported the center'; exception when others then null; end;
      begin perform public.admin_market_wallets(v_org); v_fail := v_fail || text 'outsider read wallets'; exception when others then null; end;
      begin perform public.center_report(v_org); v_fail := v_fail || text 'outsider ran center_report'; exception when others then null; end;
      begin perform public.admin_send_notification(v_org, 'x', 'y'); v_fail := v_fail || text 'outsider broadcast to the center'; exception when others then null; end;
      reset role;
    end;
  end;

  -- ===== 0066 billing: a locked center is read-only for everyone, yet its admin can still report a payment
  insert into public.platform_settings (key, value) values ('billing_enforce', 'true') on conflict (key) do update set value = 'true';
  update public.organizations set status = 'suspended' where id = v_org;
  perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated')::text, true);
  set local role authenticated;
  if not coalesce((public.my_access(v_org) ->> 'is_read_only')::boolean, false) then v_fail := v_fail || text 'locked center not read-only'; end if;
  begin insert into public.attendance (organization_id, student_id, circle_id, session_date, status) values (v_org, v_sp, v_circle, current_date, 'present');
    v_fail := v_fail || text 'locked center accepted a write'; exception when others then null; end;
  begin perform public.billing_overview(v_org); v_fail := v_fail || text 'teacher can read billing'; exception when others then null; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  set local role authenticated;
  begin perform public.billing_overview(v_org); exception when others then v_fail := v_fail || text ('admin cannot open billing while locked: ' || sqlerrm); end;
  begin insert into public.billing_requests (organization_id, plan_id, period, amount_cents, currency, method)
    select v_org, id, 'monthly', 0, 'USD', 'cash' from public.plans limit 1;
    get diagnostics v_n = row_count; if v_n > 0 then v_fail := v_fail || text 'billing_requests directly writable'; end if;
  exception when others then null; end;
  if not v_adm_is_owner then
    begin perform public.platform_record_payment(v_org, (select id from public.plans limit 1), 'yearly', 0, 'cash'); v_fail := v_fail || text 'center admin recorded own payment'; exception when others then null; end;
  end if;
  reset role;
  -- 0072: approving a payment must not lift a suspension the owner imposed (the center is still 'suspended' here)
  begin
    insert into public.billing_requests (organization_id, plan_id, period, amount_cents, currency, method)
      select v_org, id, 'monthly', 0, 'USD', 'cash' from public.plans limit 1 returning id into v_cert;
    perform public._billing_apply(v_cert);
    v_fail := v_fail || text 'approving a payment lifted a suspension';
  exception when others then null; end;

  -- ===== the anonymous door is exactly five functions (public_plans: 0068, the marketing price list;
  --       report_client_error: 0076, crash reports from signed-out pages)
  select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')
      and p.proname not in ('get_invitation', 'get_public_site', 'verify_certificate', 'public_plans', 'report_client_error');
  if v_n > 0 then v_fail := v_fail || ('anon can execute ' || v_n || ' extra functions'); end if;

  -- ===== October 2026 audit (0093): no account can be added to a center by a direct write (an admin
  --       added someone else's account, then reset its password), a membership row cannot be moved to
  --       another account, and only the owner's functions switch a center's features beyond its plan
  if has_table_privilege('authenticated', 'public.organization_members', 'insert') then v_fail := v_fail || text 'organization_members insertable directly'; end if;
  if has_column_privilege('authenticated', 'public.organization_members', 'user_id', 'update')
     or has_column_privilege('authenticated', 'public.organization_members', 'organization_id', 'update') then
    v_fail := v_fail || text 'membership movable to another account'; end if;
  if exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'feature_flags'
             and cmd in ('INSERT', 'UPDATE', 'ALL') and coalesce(with_check, qual) ilike '%is_org_admin%') then
    v_fail := v_fail || text 'center admin can write feature_flags'; end if;

  -- ===== 0094: an owner with a verified second factor is the owner only past it (aal2): a stolen
  --       password alone opens nothing. Tried on the teacher made an owner, then undone.
  begin
    insert into public.platform_owners (user_id) values (v_tch) on conflict do nothing;
    insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at)
      values (gen_random_uuid(), v_tch, 'invariants-' || gen_random_uuid(), 'totp', 'verified', now(), now());
    perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated', 'aal', 'aal1')::text, true);
    if public.is_platform_owner() then v_fail := v_fail || text 'owner passes without the second factor (aal1)'; end if;
    perform set_config('request.jwt.claims', json_build_object('sub', v_tch, 'role', 'authenticated', 'aal', 'aal2')::text, true);
    if not public.is_platform_owner() then v_fail := v_fail || text 'owner refused after the second factor (aal2)'; end if;
    perform set_config('request.jwt.claims', json_build_object('sub', v_stu, 'role', 'authenticated', 'aal', 'aal2')::text, true);
    if public.is_platform_owner() then v_fail := v_fail || text 'aal2 alone makes an owner'; end if;
    raise exception 'mfa-check-undo';
  exception when others then
    if sqlerrm <> 'mfa-check-undo' then v_fail := v_fail || ('owner mfa check could not run: ' || sqlerrm); end if;
  end;

  -- 0095: a member of a center reads its membership rows, never the staff's national ID
  if has_column_privilege('authenticated', 'public.organization_members', 'national_id', 'SELECT') then
    v_fail := v_fail || text 'members can read staff national IDs';
  end if;
  if has_function_privilege('anon', 'public.member_national_id(uuid, uuid)', 'EXECUTE') then
    v_fail := v_fail || text 'visitors can call member_national_id';
  end if;

  raise exception 'RESULT: %', case when array_length(v_fail, 1) is null then 'OK' else 'FAILED - ' || array_to_string(v_fail, '; ') end;
end $$;
