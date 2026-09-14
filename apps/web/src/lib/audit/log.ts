import type { SupabaseClient } from '@supabase/supabase-js';

/** Best-effort audit entry for a destructive action - never blocks the
 * caller's own action if it fails (audit_log_insert_staff already allows
 * any staff member to write). */
export async function logAudit(
  supabase: SupabaseClient,
  params: { organizationId: string; actorId: string; action: string; entityTable: string; entityId: string },
) {
  await supabase.from('audit_log').insert({
    organization_id: params.organizationId,
    actor_id: params.actorId,
    action: params.action,
    entity_table: params.entityTable,
    entity_id: params.entityId,
  });
}
