-- =========================================================================
-- 0083_serd_certificates_unrestricted.sql
-- Serd certificates without the old limits (center feedback): a session may
-- have more than one certificate (a reprint, a corrected name, ...) and the
-- admin decides whether a score deserves one - the pass mark no longer blocks.
-- What stays: the right to issue certificates, an approved session, and a
-- registered student to put the name on it.
--
-- The automatic certificate on approval still comes once: the trigger only
-- fires when a session BECOMES approved, and now also skips a session that
-- already has a live certificate.
-- =========================================================================

drop index if exists public.certificates_ref_uidx;
create index if not exists certificates_ref_idx on public.certificates (kind, ref_id) where ref_id is not null;

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
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public._auto_serd_certificate()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' and new.student_id is not null
     and public.org_setting(new.organization_id, 'certificate_auto_serd', 'false') = 'true'
     and coalesce(new.score_percent, 0) >= coalesce(new.pass_percent_applied, 0)
     and not exists (select 1 from public.certificates c where c.kind = 'serd' and c.ref_id = new.id and c.revoked_at is null) then
    perform public._insert_serd_certificate(new.id, new.approved_by);
  end if;
  return new;
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
  -- the readonly trigger sees the insert; this guard just gives the clear message first
  perform public._assert_can_write(p_org);
  v_id := public._insert_serd_certificate(p_session, auth.uid());
  insert into public.audit_log (organization_id, actor_id, action, entity_table, entity_id)
  values (p_org, auth.uid(), 'insert', 'certificates', v_id);
  return v_id;
end;
$$;
