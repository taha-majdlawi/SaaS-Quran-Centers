import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/offline/sync_service.dart';

class GradeRow {
  GradeRow({
    required this.key,
    required this.label,
    required this.points,
    required this.sortOrder,
    required this.isActive,
    this.isNew = false,
  });

  final String key;
  String label;
  int points;
  final int sortOrder;
  bool isActive;
  final bool isNew;
}

/// The center's recitation grades (name + points). Mirrors apps/web's /points
/// page: eqraa hard-codes these; here each center owns them, and points are
/// frozen on every recitation when it is logged.
class PointsRepository {
  PointsRepository(this._client);

  final SupabaseClient _client;

  Future<List<GradeRow>> fetchGrades(String organizationId) async {
    final rows = (await SyncService.instance.raw('pts.fetchGrades:$organizationId', () => _client
        .from('recitation_grades')
        .select('key, label, points, sort_order, is_active')
        .eq('organization_id', organizationId)
        .order('sort_order'))) as List<dynamic>;
    return (rows)
        .map((r) => GradeRow(
              key: r['key'] as String,
              label: r['label'] as String,
              points: r['points'] as int,
              sortOrder: r['sort_order'] as int,
              isActive: r['is_active'] as bool,
            ))
        .toList();
  }

  Future<void> saveGrades(String organizationId, List<GradeRow> grades) {
    final rows = [
      for (final g in grades)
        {
          'organization_id': organizationId,
          'key': g.key,
          'label': g.label.trim(),
          'points': g.points,
          'sort_order': g.sortOrder,
          'is_active': g.isActive,
        },
    ];
    return _client.from('recitation_grades').upsert(rows, onConflict: 'organization_id,key');
  }
}
