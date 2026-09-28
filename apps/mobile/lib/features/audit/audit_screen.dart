import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'audit_repository.dart';
import '../../core/i18n/i18n.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AuditRepository(AppSupabase.client);
    return EntityListScreen<AuditEntry>(
      title: tr(context).nav.items['/audit']!,
      loader: repository.fetchLog,
      emptyIcon: Icons.history_rounded,
      emptyTitle: tr(context).ins.noAudit,
      emptySubtitle: tr(context).ins.auditHint,
      tileBuilder: (context, e) {
        final isDelete = e.action == 'delete';
        return EntityTile(
          title: '${kAuditActionLabels[e.action] ?? e.action} ${kAuditTableLabels[e.entityTable] ?? e.entityTable}',
          subtitle: '${e.actorName}  ·  ${formatDateTime(e.createdAt)}',
          leading: TileIcon(isDelete ? Icons.delete_outline_rounded : Icons.edit_note_rounded,
              color: isDelete ? Colors.red : Colors.blue),
          trailing: StatusChip(
            label: kAuditActionLabels[e.action] ?? e.action,
            color: isDelete ? Colors.red : Colors.blue,
          ),
        );
      },
    );
  }
}
