-- =========================================================================
-- 0028_viewer_reports_certificates.sql
-- Phase 8:
--   A. Viewer (read-only) accounts, per membership. The role stays true (a
--      viewing teacher IS a teacher, so every screen resolves); one flag sits
--      above it and a row-level trigger under every write path refuses any
--      write by that account in that center.
--   B. Reports: center-wide and per-student, for a period.
--   C. Certificates: issued, numbered, publicly verifiable, per-center wording.
--
-- WHY A TRIGGER AND NOT A CHECK IN EVERY FUNCTION: every write function here is
-- SECURITY DEFINER, which skips row-level security, so a policy cannot stop
-- them, and editing ~100 function bodies to add one line would be error-prone.
-- A BEFORE trigger sits under all of it: direct table writes, writes inside any
-- RPC, and RPCs written next year. Server-side jobs run with auth.uid() null
-- and are never affected.
--
-- THE KEYHOLE RULE: the flag lives in account_access, which has NO write policy
-- and no write grant; it changes only through set_account_access(), which
-- itself refuses a viewing account and refuses changing one's own flag. So a
-- viewing admin cannot lift their own lock.
-- =========================================================================

-- ---------------------------------------------------------------------
-- A. viewer accounts
-- ---------------------------------------------------------------------
alter table public.account_access add column if not exists note text;
alter table public.account_access add column if not exists updated_by uuid references auth.users (id);
alter table public.account_access add column if not exists updated_at timestamptz not null default now();

-- the old policy let any admin write the table directly (including their own row)
drop policy if exists "account_access_write_admin" on public.account_access;
revoke insert, update, delete on public.account_access from authenticated;

create or replace function public._is_read_only(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(
    (select a.is_read_only from public.account_access a where a.user_id = auth.uid() and a.organization_id = p_org),
    false);
$$;

create or replace function public._assert_can_write(p_org uuid)
returns void language plpgsql stable security definer set search_path = public as $$
begin
  -- no signed-in user = a scheduled job / service role: never a viewing account
  if auth.uid() is null then return; end if;
  if public._is_read_only(p_org) then
    raise exception 'هذا حساب عرض — البيانات للاطّلاع فقط' using errcode = 'insufficient_privilege';
  end if;
end;
$$;

-- for tables that carry organization_id
create or replace function public._deny_readonly_write()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_row jsonb; v_org uuid;
begin
  if auth.uid() is null then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  v_row := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  v_org := nullif(v_row ->> 'organization_id', '')::uuid;
  if v_org is not null then perform public._assert_can_write(v_org); end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

-- for child tables without organization_id: TG_ARGV = (parent table, fk column)
create or replace function public._deny_readonly_write_via()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_row jsonb; v_org uuid;
begin
  if auth.uid() is null then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  v_row := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
  execute format('select organization_id from public.%I where id = $1', tg_argv[0])
    into v_org using nullif(v_row ->> tg_argv[1], '')::uuid;
  if v_org is not null then perform public._assert_can_write(v_org); end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

-- Flags of the members of one center (admin only), for the members screen.
create or replace function public.list_account_flags(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('user_id', user_id, 'is_read_only', is_read_only, 'note', note))
                   from public.account_access where organization_id = p_org and is_read_only), '[]'::jsonb);
end;
$$;

-- What the signed-in person's own account is like in this center (drives the banner).
create or replace function public.my_access(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('is_read_only', public._is_read_only(p_org));
$$;

create or replace function public.set_account_access(p_org uuid, p_user uuid, p_read_only boolean, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  -- a viewing admin must not be able to lift (or move) any lock
  perform public._assert_can_write(p_org);
  if p_user = auth.uid() then raise exception 'لا يمكنك تغيير حالة حسابك بنفسك'; end if;
  if not exists (select 1 from public.organization_members where organization_id = p_org and user_id = p_user) then
    raise exception 'هذا الشخص ليس عضوًا في المركز';
  end if;

  insert into public.account_access (user_id, organization_id, is_read_only, note, updated_by, updated_at)
  values (p_user, p_org, coalesce(p_read_only, false), nullif(left(btrim(coalesce(p_note, '')), 200), ''), auth.uid(), now())
  on conflict (user_id, organization_id) do update
    set is_read_only = excluded.is_read_only, note = excluded.note, updated_by = excluded.updated_by, updated_at = now();

  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'account_access', p_user, jsonb_build_object('is_read_only', coalesce(p_read_only, false)));
end;
$$;

-- ---------------------------------------------------------------------
-- B. reports
-- ---------------------------------------------------------------------
create or replace function public.center_report(p_org uuid, p_from date default null, p_to date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_from date := coalesce(p_from, date_trunc('month', current_date)::date);
  v_to date := coalesce(p_to, current_date);
  v_a timestamptz; v_b timestamptz; v_out jsonb;
begin
  if not public.member_has_module(p_org, 'reports') then raise exception 'غير مصرّح'; end if;
  if v_to < v_from then raise exception 'تاريخ النهاية قبل البداية'; end if;
  if v_to - v_from > 731 then raise exception 'الفترة أطول من سنتين'; end if;
  v_a := v_from::timestamptz; v_b := (v_to + 1)::timestamptz;

  with ach as (
    select da.student_id, da.circle_id, da.recorded_by, da.achievement_type::text as kind, da.points_awarded, da.created_at
    from public.daily_achievements da
    where da.organization_id = p_org and da.created_at >= v_a and da.created_at < v_b
  ), att as (
    select a.student_id, a.circle_id, a.status::text as status
    from public.attendance a
    where a.organization_id = p_org and a.session_date between v_from and v_to
  ), circle_att as (
    select circle_id,
           count(*) filter (where status in ('present', 'late')) as attended,
           count(*) filter (where status in ('present', 'late', 'absent')) as counted
    from att group by circle_id
  )
  select jsonb_build_object(
    'from', v_from, 'to', v_to,
    'totals', jsonb_build_object(
      'students_active', (select count(*) from public.students_profile where organization_id = p_org and status = 'active'),
      'new_students', (select count(*) from public.students_profile where organization_id = p_org and created_at >= v_a and created_at < v_b),
      'recitations', (select count(*) from ach),
      'points', coalesce((select sum(points_awarded) from ach), 0),
      'reciting_students', (select count(distinct student_id) from ach),
      'attendance_present', (select count(*) from att where status = 'present'),
      'attendance_late', (select count(*) from att where status = 'late'),
      'attendance_absent', (select count(*) from att where status = 'absent'),
      'attendance_excused', (select count(*) from att where status = 'excused'),
      'attendance_rate', (select case when count(*) filter (where status in ('present', 'late', 'absent')) = 0 then null
                                 else round(100.0 * count(*) filter (where status in ('present', 'late')) /
                                            count(*) filter (where status in ('present', 'late', 'absent')), 1) end from att),
      'serd_approved', (select count(*) from public.serd_sessions where organization_id = p_org and status = 'approved' and session_date between v_from and v_to),
      'serd_average', (select round(avg(score_percent), 1) from public.serd_sessions where organization_id = p_org and status = 'approved' and session_date between v_from and v_to),
      'certificates', (select count(*) from public.certificates where organization_id = p_org and revoked_at is null and issued_at >= v_a and issued_at < v_b)
    ),
    'by_type', coalesce((select jsonb_agg(jsonb_build_object('type', kind, 'count', n) order by n desc)
                         from (select kind, count(*) n from ach group by kind) t), '[]'::jsonb),
    'circles', coalesce((select jsonb_agg(jsonb_build_object(
        'id', c.id, 'name', c.name, 'teacher', tp.full_name,
        'students', (select count(*) from public.students_profile s where s.circle_id = c.id and s.status = 'active'),
        'recitations', (select count(*) from ach where ach.circle_id = c.id),
        'points', coalesce((select sum(points_awarded) from ach where ach.circle_id = c.id), 0),
        'attendance_rate', (select case when ca.counted = 0 then null else round(100.0 * ca.attended / ca.counted, 1) end
                            from circle_att ca where ca.circle_id = c.id)
      ) order by c.name)
      from public.circles c left join public.profiles tp on tp.id = c.teacher_id
      where c.organization_id = p_org and c.status = 'active'), '[]'::jsonb),
    'teachers', coalesce((select jsonb_agg(jsonb_build_object('id', t.uid, 'name', t.full_name, 'recitations', t.n, 'points', t.pts) order by t.n desc)
        from (select a.recorded_by as uid, p.full_name, count(*) n, coalesce(sum(a.points_awarded), 0) pts
              from ach a left join public.profiles p on p.id = a.recorded_by group by a.recorded_by, p.full_name) t), '[]'::jsonb),
    'top_students', coalesce((select jsonb_agg(jsonb_build_object('id', t.student_id, 'name', t.full_name, 'code', t.student_code,
                                                                  'circle', t.circle, 'points', t.pts, 'recitations', t.n) order by t.pts desc, t.n desc)
        from (select a.student_id, s.full_name, s.student_code, c.name as circle, coalesce(sum(a.points_awarded), 0) pts, count(*) n
              from ach a join public.students_profile s on s.id = a.student_id left join public.circles c on c.id = s.circle_id
              group by a.student_id, s.full_name, s.student_code, c.name order by 5 desc, 6 desc limit 10) t), '[]'::jsonb),
    'daily', coalesce((select jsonb_agg(jsonb_build_object('date', d, 'recitations', n) order by d)
                       from (select created_at::date d, count(*) n from ach group by 1) t), '[]'::jsonb)
  ) into v_out;
  return v_out;
end;
$$;

create or replace function public.student_report(p_org uuid, p_student uuid, p_from date default null, p_to date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_from date := coalesce(p_from, date_trunc('month', current_date)::date);
  v_to date := coalesce(p_to, current_date);
  v_a timestamptz; v_b timestamptz; s public.students_profile%rowtype; v_out jsonb;
begin
  select * into s from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  if not (public.is_org_admin(p_org) or public.member_has_module(p_org, 'reports')
          or public._teaches_student(p_student) or p_student = any (public.linked_student_ids(p_org))) then
    raise exception 'غير مصرّح';
  end if;
  if v_to < v_from then raise exception 'تاريخ النهاية قبل البداية'; end if;
  if v_to - v_from > 731 then raise exception 'الفترة أطول من سنتين'; end if;
  v_a := v_from::timestamptz; v_b := (v_to + 1)::timestamptz;

  select jsonb_build_object(
    'from', v_from, 'to', v_to,
    'student', jsonb_build_object('id', s.id, 'name', s.full_name, 'code', s.student_code, 'status', s.status,
        'circle', (select c.name from public.circles c where c.id = s.circle_id),
        'teacher', (select p.full_name from public.circles c join public.profiles p on p.id = c.teacher_id where c.id = s.circle_id),
        'total_points', s.total_points, 'parts_count', s.total_parts_count, 'saved_parts', s.saved_parts_numbers,
        'joined', s.created_at),
    'recitations', jsonb_build_object(
        'count', (select count(*) from public.daily_achievements where student_id = p_student and created_at >= v_a and created_at < v_b),
        'points', coalesce((select sum(points_awarded) from public.daily_achievements where student_id = p_student and created_at >= v_a and created_at < v_b), 0),
        'by_type', coalesce((select jsonb_agg(jsonb_build_object('type', k, 'count', n)) from
            (select achievement_type::text k, count(*) n from public.daily_achievements
             where student_id = p_student and created_at >= v_a and created_at < v_b group by 1) t), '[]'::jsonb),
        'rows', coalesce((select jsonb_agg(jsonb_build_object('at', created_at, 'type', achievement_type::text, 'surah_from', surah_from,
                   'ayah_from', ayah_from, 'surah_to', surah_to, 'ayah_to', ayah_to, 'grade', grade, 'points', points_awarded) order by created_at desc)
            from (select * from public.daily_achievements where student_id = p_student and created_at >= v_a and created_at < v_b
                  order by created_at desc limit 200) r), '[]'::jsonb)),
    'attendance', (select jsonb_build_object(
        'present', count(*) filter (where status::text = 'present'), 'late', count(*) filter (where status::text = 'late'),
        'absent', count(*) filter (where status::text = 'absent'), 'excused', count(*) filter (where status::text = 'excused'),
        'rate', case when count(*) filter (where status::text in ('present', 'late', 'absent')) = 0 then null
                     else round(100.0 * count(*) filter (where status::text in ('present', 'late')) /
                                count(*) filter (where status::text in ('present', 'late', 'absent')), 1) end)
        from public.attendance where student_id = p_student and session_date between v_from and v_to),
    'serd', coalesce((select jsonb_agg(jsonb_build_object('date', session_date, 'juz', juz_numbers, 'score', score_percent,
                                                          'pass', pass_percent_applied, 'status', status) order by session_date desc)
        from public.serd_sessions where student_id = p_student and status in ('approved', 'rejected', 'submitted')
          and session_date between v_from and v_to), '[]'::jsonb),
    'badges', coalesce((select jsonb_agg(jsonb_build_object('name', b.name, 'at', sb.awarded_at) order by sb.awarded_at desc)
        from public.student_badges sb join public.badges b on b.id = sb.badge_id where sb.student_id = p_student), '[]'::jsonb),
    'certificates', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'title', title, 'at', issued_at) order by issued_at desc)
        from public.certificates where student_id = p_student and revoked_at is null), '[]'::jsonb)
  ) into v_out;
  return v_out;
end;
$$;

-- ---------------------------------------------------------------------
-- C. certificates
-- ---------------------------------------------------------------------
create table if not exists public.certificates (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references public.organizations (id) on delete cascade,
  student_id       uuid not null references public.students_profile (id) on delete cascade,
  kind             text not null check (kind in ('serd', 'memorization', 'excellence', 'attendance', 'custom')),
  title            text not null check (char_length(title) between 2 and 120),
  -- FREEZE RULE: the wording, the name and the signer are stamped at issue;
  -- renaming the student or changing the center's template later never edits a
  -- certificate that was already handed out.
  recipient_name   text not null,
  description      text,
  detail           jsonb not null default '{}'::jsonb,
  signer_name      text,
  signer_title     text,
  footer           text,
  serial           text not null unique,
  ref_id           uuid,
  issued_by        uuid references auth.users (id),
  issued_at        timestamptz not null default now(),
  revoked_at       timestamptz,
  revoke_reason    text
);
create index if not exists certificates_org_idx on public.certificates (organization_id, issued_at desc);
create index if not exists certificates_student_idx on public.certificates (student_id);
-- a serd session yields at most one live certificate
create unique index if not exists certificates_ref_uidx on public.certificates (kind, ref_id) where ref_id is not null and revoked_at is null;

alter table public.certificates enable row level security;
create policy "certificates_select" on public.certificates for select using (
  public.is_org_admin(organization_id) or public.member_has_module(organization_id, 'certificates')
  or exists (select 1 from public.students_profile sp join public.circles ci on ci.id = sp.circle_id
             where sp.id = certificates.student_id and ci.teacher_id = auth.uid())
  or (revoked_at is null and student_id = any (public.linked_student_ids(organization_id)))
);
revoke insert, update, delete on public.certificates from authenticated, anon;

create or replace function public._cert_serial()
returns text language sql volatile as $$
  select 'BQ-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
$$;

create or replace function public._cert_template(p_org uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'signer_name',  nullif(public.org_setting(p_org, 'certificate_signer_name', ''), ''),
    'signer_title', nullif(public.org_setting(p_org, 'certificate_signer_title', ''), ''),
    'footer',       nullif(public.org_setting(p_org, 'certificate_footer', ''), ''),
    'serd_title',   coalesce(nullif(public.org_setting(p_org, 'certificate_serd_title', ''), ''), 'شهادة اجتياز السرد القرآني'),
    'auto_serd',    public.org_setting(p_org, 'certificate_auto_serd', 'false') = 'true'
  );
$$;

-- internal: issue the certificate of one approved, passed serd session (no permission check)
create or replace function public._insert_serd_certificate(p_session uuid, p_by uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare q public.serd_sessions%rowtype; st public.students_profile%rowtype; t jsonb; v_id uuid; v_juz text;
begin
  select * into q from public.serd_sessions where id = p_session;
  if not found or q.student_id is null then raise exception 'لا يمكن إصدار شهادة لهذه الجلسة'; end if;
  select * into st from public.students_profile where id = q.student_id;
  t := public._cert_template(q.organization_id);
  select string_agg(j::text, '، ' order by j) into v_juz from unnest(q.juz_numbers) j;
  insert into public.certificates (organization_id, student_id, kind, title, recipient_name, description, detail,
                                   signer_name, signer_title, footer, serial, ref_id, issued_by)
  values (q.organization_id, q.student_id, 'serd', t ->> 'serd_title', st.full_name,
          'اجتاز اختبار السرد القرآني في ' || case when array_length(q.juz_numbers, 1) = 1 then 'الجزء ' else 'الأجزاء ' end
            || coalesce(v_juz, '') || ' بدرجة ' || trim(trailing '.' from trim(trailing '0' from round(q.score_percent, 1)::text)) || '٪',
          jsonb_build_object('juz', to_jsonb(q.juz_numbers), 'score_percent', q.score_percent, 'session_date', q.session_date),
          t ->> 'signer_name', t ->> 'signer_title', t ->> 'footer', public._cert_serial(), q.id, p_by)
  on conflict (kind, ref_id) where ref_id is not null and revoked_at is null do nothing
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public._auto_serd_certificate()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' and new.student_id is not null
     and public.org_setting(new.organization_id, 'certificate_auto_serd', 'false') = 'true'
     and coalesce(new.score_percent, 0) >= coalesce(new.pass_percent_applied, 0) then
    perform public._insert_serd_certificate(new.id, new.approved_by);
  end if;
  return new;
end;
$$;
drop trigger if exists serd_auto_certificate on public.serd_sessions;
create trigger serd_auto_certificate after update of status on public.serd_sessions
  for each row execute function public._auto_serd_certificate();

create or replace function public._can_issue_certificates(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.member_has_module(p_org, 'certificates');
$$;

create or replace function public.issue_certificate(
  p_org uuid, p_student uuid, p_kind text, p_title text, p_description text default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare st public.students_profile%rowtype; t jsonb; v_id uuid;
begin
  if not public._can_issue_certificates(p_org) then raise exception 'غير مصرّح'; end if;
  if p_kind not in ('memorization', 'excellence', 'attendance', 'custom') then raise exception 'نوع الشهادة غير صحيح'; end if;
  if char_length(btrim(coalesce(p_title, ''))) < 2 then raise exception 'عنوان الشهادة مطلوب'; end if;
  select * into st from public.students_profile where id = p_student and organization_id = p_org;
  if not found then raise exception 'الطالب غير موجود'; end if;
  t := public._cert_template(p_org);
  insert into public.certificates (organization_id, student_id, kind, title, recipient_name, description,
                                   signer_name, signer_title, footer, serial, issued_by)
  values (p_org, p_student, p_kind, left(btrim(p_title), 120), st.full_name, nullif(left(btrim(coalesce(p_description, '')), 500), ''),
          t ->> 'signer_name', t ->> 'signer_title', t ->> 'footer', public._cert_serial(), auth.uid())
  returning id into v_id;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), 'insert', 'certificates', v_id);
  return v_id;
end;
$$;

create or replace function public.issue_serd_certificate(p_org uuid, p_session uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare q public.serd_sessions%rowtype; v_id uuid;
begin
  if not public._can_issue_certificates(p_org) then raise exception 'غير مصرّح'; end if;
  select * into q from public.serd_sessions where id = p_session and organization_id = p_org;
  if not found then raise exception 'الجلسة غير موجودة'; end if;
  if q.status <> 'approved' then raise exception 'الشهادة تُصدر بعد اعتماد السرد'; end if;
  if q.student_id is null then raise exception 'هذه الجلسة غير مرتبطة بطالب مسجّل'; end if;
  if coalesce(q.score_percent, 0) < coalesce(q.pass_percent_applied, 0) then raise exception 'لم يبلغ الطالب حدّ النجاح'; end if;
  -- the readonly trigger sees the insert; this guard just gives the clear message first
  perform public._assert_can_write(p_org);
  v_id := public._insert_serd_certificate(p_session, auth.uid());
  if v_id is null then raise exception 'صدرت شهادة لهذه الجلسة من قبل'; end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), 'insert', 'certificates', v_id);
  return v_id;
end;
$$;

create or replace function public.revoke_certificate(p_org uuid, p_id uuid, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public._can_issue_certificates(p_org) then raise exception 'غير مصرّح'; end if;
  update public.certificates set revoked_at = now(), revoke_reason = nullif(left(btrim(coalesce(p_reason, '')), 200), '')
  where id = p_id and organization_id = p_org and revoked_at is null;
  if not found then raise exception 'الشهادة غير موجودة أو مسحوبة سابقًا'; end if;
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id, diff)
  values (p_org, auth.uid(), 'update', 'certificates', p_id, jsonb_build_object('revoked', true));
end;
$$;

-- List (newest first). Family members get their own (non-revoked) ones only.
create or replace function public.list_certificates(p_org uuid, p_student uuid default null, p_limit integer default 50, p_offset integer default 0)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_staff boolean;
begin
  if not public.is_org_member(p_org) then raise exception 'غير مصرّح'; end if;
  v_staff := public.member_has_module(p_org, 'certificates');
  return jsonb_build_object(
    'can_issue', v_staff,
    'total', (select count(*) from public.certificates c where c.organization_id = p_org
              and (p_student is null or c.student_id = p_student)
              and (v_staff or (c.revoked_at is null and c.student_id = any (public.linked_student_ids(p_org))))),
    'rows', coalesce((select jsonb_agg(row_to_json(t)) from (
        select c.id, c.serial, c.kind, c.title, c.recipient_name, c.issued_at, c.revoked_at, c.student_id, s.student_code
        from public.certificates c join public.students_profile s on s.id = c.student_id
        where c.organization_id = p_org and (p_student is null or c.student_id = p_student)
          and (v_staff or (c.revoked_at is null and c.student_id = any (public.linked_student_ids(p_org))))
        order by c.issued_at desc limit least(greatest(p_limit, 1), 100) offset greatest(p_offset, 0)) t), '[]'::jsonb));
end;
$$;

create or replace function public.get_certificate(p_org uuid, p_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c public.certificates%rowtype; o public.organizations%rowtype;
begin
  select * into c from public.certificates where id = p_id and organization_id = p_org;
  if not found then return null; end if;
  if not (public.member_has_module(p_org, 'certificates') or public._teaches_student(c.student_id)
          or (c.revoked_at is null and c.student_id = any (public.linked_student_ids(p_org)))) then
    raise exception 'غير مصرّح';
  end if;
  select * into o from public.organizations where id = p_org;
  return jsonb_build_object(
    'id', c.id, 'serial', c.serial, 'kind', c.kind, 'title', c.title, 'recipient_name', c.recipient_name,
    'description', c.description, 'detail', c.detail, 'issued_at', c.issued_at, 'revoked_at', c.revoked_at,
    'signer_name', c.signer_name, 'signer_title', c.signer_title, 'footer', c.footer, 'student_id', c.student_id,
    'center', jsonb_build_object('name', o.name, 'slug', o.slug, 'logo_url', o.logo_url, 'primary_color', o.primary_color));
end;
$$;

-- PUBLIC: anyone holding the serial can check a certificate is genuine. Returns
-- only what is printed on it; an unknown serial and a serial of another center
-- are indistinguishable (null).
create or replace function public.verify_certificate(p_slug text, p_serial text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c public.certificates%rowtype; o public.organizations%rowtype;
begin
  select * into o from public.organizations where slug = lower(btrim(coalesce(p_slug, '')));
  if not found then return null; end if;
  select * into c from public.certificates where organization_id = o.id and serial = upper(btrim(coalesce(p_serial, '')));
  if not found then return null; end if;
  return jsonb_build_object('valid', c.revoked_at is null, 'title', c.title, 'recipient_name', c.recipient_name,
    'issued_at', c.issued_at, 'center', jsonb_build_object('name', o.name, 'logo_url', o.logo_url, 'primary_color', o.primary_color));
end;
$$;

create or replace function public.get_certificate_settings(p_org uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  return public._cert_template(p_org);
end;
$$;

create or replace function public.set_certificate_settings(
  p_org uuid, p_signer_name text, p_signer_title text, p_footer text, p_serd_title text, p_auto_serd boolean
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_org_admin(p_org) then raise exception 'هذه العملية للمشرف فقط'; end if;
  perform public._assert_can_write(p_org);
  insert into public.organization_settings (organization_id, key, value, updated_at) values
    (p_org, 'certificate_signer_name',  left(btrim(coalesce(p_signer_name, '')), 80), now()),
    (p_org, 'certificate_signer_title', left(btrim(coalesce(p_signer_title, '')), 80), now()),
    (p_org, 'certificate_footer',       left(btrim(coalesce(p_footer, '')), 200), now()),
    (p_org, 'certificate_serd_title',   left(btrim(coalesce(p_serd_title, '')), 120), now()),
    (p_org, 'certificate_auto_serd',    case when coalesce(p_auto_serd, false) then 'true' else 'false' end, now())
  on conflict (organization_id, key) do update set value = excluded.value, updated_at = now();
end;
$$;

-- ---------------------------------------------------------------------
-- The lock itself: every table that carries organization_id, except the ones
-- that are the person's own state or the control tables. Tables created later
-- must be added here (see tables_without_write_lock()).
-- ---------------------------------------------------------------------
do $$
declare t record;
  -- exempt: personal state (a viewing account may still read-mark, bookmark,
  -- mute, register a device, request its own deletion) and the control tables
  v_exempt text[] := array['account_access', 'account_admin_grants', 'audit_log', 'device_tokens',
    'notification_prefs', 'notifications', 'quran_bookmarks', 'quran_positions', 'deletion_requests'];
begin
  for t in
    select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
      and exists (select 1 from pg_attribute a where a.attrelid = c.oid and a.attname = 'organization_id' and not a.attisdropped)
      and c.relname <> all (v_exempt)
  loop
    execute format('drop trigger if exists a_deny_readonly_write on public.%I', t.relname);
    execute format('create trigger a_deny_readonly_write before insert or update or delete on public.%I
                    for each row execute function public._deny_readonly_write()', t.relname);
  end loop;
end $$;

-- child tables: resolve the center through the parent row
do $$
declare x record;
begin
  for x in select * from (values
    ('calendar_registrations', 'center_calendar', 'entry_id'),
    ('calendar_waitlist', 'center_calendar', 'entry_id'),
    ('serd_session_parts', 'serd_sessions', 'session_id'),
    ('serd_session_errors', 'serd_sessions', 'session_id'),
    ('student_badges', 'students_profile', 'student_id'),
    ('attendance_gathering_entries', 'attendance_gatherings', 'gathering_id')
  ) as v (child, parent, fk)
  loop
    if to_regclass('public.' || x.child) is not null then
      execute format('drop trigger if exists a_deny_readonly_write on public.%I', x.child);
      execute format('create trigger a_deny_readonly_write before insert or update or delete on public.%I
                      for each row execute function public._deny_readonly_write_via(%L, %L)', x.child, x.parent, x.fk);
    end if;
  end loop;
end $$;

-- chat: sending / deleting is a write; marking messages read (an UPDATE that
-- does not touch the text) is not, so a viewer can open a conversation
drop trigger if exists a_deny_readonly_write on public.chat_messages;
create trigger a_deny_readonly_write_ins before insert or delete on public.chat_messages
  for each row execute function public._deny_readonly_write_via('chat_threads', 'thread_id');
create trigger a_deny_readonly_write_upd before update on public.chat_messages
  for each row when (old.body is distinct from new.body)
  execute function public._deny_readonly_write_via('chat_threads', 'thread_id');

-- a maintenance check: which tables carry organization_id but no lock (should be only the exempt ones)
create or replace function public.tables_without_write_lock()
returns setof text language sql stable security definer set search_path = public as $$
  select c.relname::text from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r'
    and exists (select 1 from pg_attribute a where a.attrelid = c.oid and a.attname = 'organization_id' and not a.attisdropped)
    and not exists (select 1 from pg_trigger g where g.tgrelid = c.oid and g.tgname like 'a_deny_readonly_write%')
  order by 1;
$$;

-- ---------------------------------------------------------------------
-- privileges (default grants are PUBLIC; re-list everything new)
-- ---------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'list_account_flags(uuid)', 'my_access(uuid)', 'set_account_access(uuid, uuid, boolean, text)',
    'center_report(uuid, date, date)', 'student_report(uuid, uuid, date, date)',
    'issue_certificate(uuid, uuid, text, text, text)', 'issue_serd_certificate(uuid, uuid)',
    'revoke_certificate(uuid, uuid, text)', 'list_certificates(uuid, uuid, integer, integer)',
    'get_certificate(uuid, uuid)', 'get_certificate_settings(uuid)',
    'set_certificate_settings(uuid, text, text, text, text, boolean)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  -- the only new anonymous door
  revoke all on function public.verify_certificate(text, text) from public;
  grant execute on function public.verify_certificate(text, text) to anon, authenticated, service_role;
  -- internals: nobody calls these directly
  foreach f in array array[
    '_is_read_only(uuid)', '_assert_can_write(uuid)', '_deny_readonly_write()', '_deny_readonly_write_via()',
    '_cert_serial()', '_cert_template(uuid)', '_insert_serd_certificate(uuid, uuid)', '_auto_serd_certificate()',
    '_can_issue_certificates(uuid)', 'tables_without_write_lock()'
  ] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;

-- 0018 rule: anon only reaches get_invitation, get_public_site and (now) verify_certificate
grant execute on function public.get_invitation(uuid) to anon;

notify pgrst, 'reload schema';
