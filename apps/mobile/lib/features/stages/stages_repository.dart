import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/offline/sync_service.dart';

class StageSummary {
  const StageSummary({required this.id, required this.name, required this.sortOrder, this.code});
  final String id;
  final String name;
  final int sortOrder;
  final String? code;
}

/// Mirrors apps/web's stages/actions.ts - write access is admin-only
/// (stages_write_admin RLS policy), `code` feeds the suggested student-code
/// numbering on the students form.
class StagesRepository {
  StagesRepository(this._client);

  final SupabaseClient _client;

  Future<List<StageSummary>> fetchStages(String organizationId) async {
    final rows = (await SyncService.instance.raw('stg.fetchStages:$organizationId', () => _client
        .from('stages')
        .select('id, name, code, sort_order')
        .eq('organization_id', organizationId)
        .order('sort_order'))) as List<dynamic>;
    return (rows)
        .map((r) => StageSummary(
              id: r['id'] as String,
              name: r['name'] as String,
              sortOrder: r['sort_order'] as int,
              code: r['code'] as String?,
            ))
        .toList();
  }

  Future<StageSummary?> fetchStage(String id) async {
    final row = (await SyncService.instance.raw('stg.fetchStage:$id', () => _client.from('stages').select('id, name, code, sort_order').eq('id', id).maybeSingle())) as Map<String, dynamic>?;
    if (row == null) return null;
    return StageSummary(
      id: row['id'] as String,
      name: row['name'] as String,
      sortOrder: row['sort_order'] as int,
      code: row['code'] as String?,
    );
  }

  Future<void> createStage({required String organizationId, required String name, String? code, required int sortOrder}) {
    return _client.from('stages').insert({
      'organization_id': organizationId,
      'name': name,
      'code': code,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateStage({required String id, required String name, String? code, required int sortOrder}) {
    return _client.from('stages').update({'name': name, 'code': code, 'sort_order': sortOrder}).eq('id', id);
  }

  Future<void> deleteStage(String id) {
    return _client.from('stages').delete().eq('id', id);
  }
}
