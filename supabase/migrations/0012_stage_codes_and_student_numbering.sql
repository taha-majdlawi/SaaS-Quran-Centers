-- =========================================================================
-- 0012_stage_codes_and_student_numbering.sql
-- Gives each stage a short admin-defined code (e.g. 'TM', '01') and adds an
-- RPC that suggests the next student code within a stage, formatted as
-- {stage_code}-{zero-padded sequence}. Sequence counts existing students
-- whose CIRCLE belongs to that stage (students_profile has no stage_id of
-- its own - stage is reached via circle_id -> circles.stage_id).
-- =========================================================================

alter table public.stages add column code text;

create unique index stages_org_code_key on public.stages (organization_id, code) where code is not null;

create or replace function public.next_student_code(org_id uuid, target_stage_id uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  stage_code text;
  next_seq int;
begin
  if not public.is_org_staff(org_id) then
    raise exception 'not authorized';
  end if;

  select code into stage_code from public.stages where id = target_stage_id and organization_id = org_id;
  if stage_code is null then
    stage_code := '00';
  end if;

  select count(*) + 1 into next_seq
  from public.students_profile sp
  join public.circles c on c.id = sp.circle_id
  where sp.organization_id = org_id and c.stage_id = target_stage_id;

  return stage_code || '-' || lpad(next_seq::text, 4, '0');
end;
$$;

grant execute on function public.next_student_code(uuid, uuid) to authenticated;
