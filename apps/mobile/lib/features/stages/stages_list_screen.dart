import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/ui.dart';
import 'stages_repository.dart';
import '../../core/i18n/i18n.dart';

class StagesListScreen extends StatelessWidget {
  const StagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = StagesRepository(AppSupabase.client);
    final isAdmin = context.watch<TenantController>().active?.role == OrgRole.admin;
    return EntityListScreen<StageSummary>(
      title: tr(context).nav.items['/stages']!,
      loader: repository.fetchStages,
      addPath: isAdmin ? '/stages/new' : null,
      addLabel: tr(context).org.addStage,
      emptyIcon: Icons.stairs_outlined,
      emptyTitle: tr(context).org.noStages,
      emptySubtitle: tr(context).org.noStagesHint,
      tileBuilder: (context, s) => EntityTile(
        title: s.name,
        subtitle: fmt(tr(context).org.orderN, {'sortOrder': s.sortOrder}),
        leading: const TileIcon(Icons.stairs_rounded, color: Colors.purple),
        trailing: s.code == null ? null : StatusChip(label: s.code!, color: Colors.purple),
        path: isAdmin ? '/stages/${s.id}' : null,
      ),
    );
  }
}
