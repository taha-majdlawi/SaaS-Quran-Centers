-- =========================================================================
-- 0084_student_numbers_by_year_stage.sql
-- New student numbers: YY + SS + NNN, digits only (easy to type as a login):
--   YY  the year the student is added (the center's own time zone)
--   SS  the stage: its admin-set code when that is 1-2 digits, otherwise its
--       place in the center's stage order (01, 02, ...); 00 without a stage
--   NNN the next number in that year and stage (grows past 999 if needed)
-- e.g. 2602015 = joined 2026, stage 2, 15th student.
--
-- The sequence continues from the highest number already given (not from a
-- count of current students as before, which handed out a used or near-used
-- number again once a student was deleted or moved), and skips any number
-- already taken as a student code or as a login of this center.
-- Existing students keep their numbers - they are their login IDs.
-- =========================================================================

create or replace function public.next_student_code(org_id uuid, target_stage_id uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_tz text;
  v_slug text;
  v_code text;
  v_rank int;
  v_prefix text;
  v_seq int;
  v_out text;
begin
  if not public.is_org_staff(org_id) then
    raise exception 'not authorized';
  end if;

  select coalesce(timezone, 'UTC'), slug into v_tz, v_slug from public.organizations where id = org_id;

  if target_stage_id is null then
    v_code := '00';
  else
    select code into v_code from public.stages where id = target_stage_id and organization_id = org_id;
    if v_code is not null and btrim(v_code) ~ '^[0-9]{1,2}$' then
      v_code := lpad(btrim(v_code), 2, '0');
    else
      select r into v_rank from (
        select id, row_number() over (order by sort_order, created_at, id) as r
        from public.stages where organization_id = org_id
      ) s where s.id = target_stage_id;
      v_code := lpad(coalesce(v_rank, 0)::text, 2, '0');
    end if;
  end if;

  v_prefix := to_char(now() at time zone v_tz, 'YY') || right(v_code, 2);

  select coalesce(max(substr(student_code, 5)::int), 0) + 1 into v_seq
  from public.students_profile
  where organization_id = org_id and student_code ~ ('^' || v_prefix || '[0-9]{3,6}$');

  loop
    v_out := v_prefix || lpad(v_seq::text, 3, '0');
    exit when not exists (select 1 from public.students_profile where organization_id = org_id and student_code = v_out)
          and not exists (select 1 from auth.users where email = v_out || '@' || lower(v_slug) || '.id.bustan-alquran.com');
    v_seq := v_seq + 1;
  end loop;
  return v_out;
end;
$$;

revoke all on function public.next_student_code(uuid, uuid) from public, anon;
grant execute on function public.next_student_code(uuid, uuid) to authenticated;
