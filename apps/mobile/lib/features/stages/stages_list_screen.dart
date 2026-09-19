import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/ui.dart';
import 'stages_repository.dart';

class StagesListScreen extends StatelessWidget {
  const StagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = StagesRepository(AppSupabase.client);
    final isAdmin = context.watch<TenantController>().active?.role == OrgRole.admin;
    return EntityListScreen<StageSummary>(
      title: 'المراحل',
      loader: repository.fetchStages,
      addPath: isAdmin ? '/stages/new' : null,
      addLabel: 'إضافة مرحلة',
      emptyIcon: Icons.stairs_outlined,
      emptyTitle: 'لا يوجد مراحل بعد',
      emptySubtitle: 'المراحل تنظّم الحلقات وتُستخدم في ترقيم الطلاب',
      tileBuilder: (context, s) => EntityTile(
        title: s.name,
        subtitle: 'الترتيب ${s.sortOrder}',
        leading: const TileIcon(Icons.stairs_rounded, color: Colors.purple),
        trailing: s.code == null ? null : StatusChip(label: s.code!, color: Colors.purple),
        path: isAdmin ? '/stages/${s.id}' : null,
      ),
    );
  }
}
