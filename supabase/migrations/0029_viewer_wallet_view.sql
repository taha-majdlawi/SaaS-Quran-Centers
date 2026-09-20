-- =========================================================================
-- 0029_viewer_wallet_view.sql
-- A viewing account (0028) may open the market: _sync_wallet used to convert
-- earned points into currency (a write) on every read. For a read-only account
-- it now computes what the wallet WOULD be without writing anything; the real
-- conversion happens the next time someone who can write opens it.
-- =========================================================================
create or replace function public._sync_wallet(p_org uuid, p_student uuid)
returns jsonb language plpgsql volatile security definer set search_path = public as $$
declare v_earned bigint; v_conv bigint; v_total numeric(12,2); v_bp bigint; v_bu bigint; v_blocks bigint;
begin
  select coalesce(total_points, 0) into v_earned from public.students_profile
   where id = p_student and organization_id = p_org;
  if not found then return null; end if;

  if public._is_read_only(p_org) then
    select coalesce(converted_points, 0), coalesce(total_converted, 0) into v_conv, v_total
      from public.student_wallets where student_id = p_student;
    v_conv := coalesce(v_conv, 0); v_total := coalesce(v_total, 0);
    if v_earned - v_conv > 0 then
      select block_points, block_units into v_bp, v_bu from public._currency_block(p_org);
      if v_bp > 0 then
        v_blocks := (v_earned - v_conv) / v_bp;
        v_conv := v_conv + v_blocks * v_bp;
        v_total := v_total + (v_blocks * v_bu)::numeric / 100;
      end if;
    end if;
  else
    insert into public.student_wallets (student_id, organization_id) values (p_student, p_org)
      on conflict (student_id) do nothing;
    select converted_points, total_converted into v_conv, v_total
      from public.student_wallets where student_id = p_student for update;
    if v_earned - v_conv > 0 then
      select block_points, block_units into v_bp, v_bu from public._currency_block(p_org);
      if v_bp > 0 then
        v_blocks := (v_earned - v_conv) / v_bp;
        if v_blocks > 0 then
          update public.student_wallets
             set converted_points = converted_points + v_blocks * v_bp,
                 total_converted = total_converted + (v_blocks * v_bu)::numeric / 100, updated_at = now()
           where student_id = p_student
          returning converted_points, total_converted into v_conv, v_total;
        end if;
      end if;
    end if;
  end if;

  return jsonb_build_object('earned_points', v_earned, 'converted_points', v_conv, 'total_converted', v_total,
    'pending_points', greatest(v_earned - v_conv, 0), 'spent', public._currency_spent(p_student),
    'balance', v_total - public._currency_spent(p_student));
end;
$$;

revoke all on function public._sync_wallet(uuid, uuid) from public, anon, authenticated;
notify pgrst, 'reload schema';
