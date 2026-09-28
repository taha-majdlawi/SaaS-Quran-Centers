import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/offline/sync_service.dart';

List<Map<String, dynamic>> _list(dynamic v) => [for (final e in (v as List? ?? const [])) Map<String, dynamic>.from(e as Map)];

/// Shared activities (المجالس) and external recitations (التسميع الخارجي) - 0045.
class GatheringsRepository {
  GatheringsRepository(this._client);
  final SupabaseClient _client;

  // ---- gatherings ----------------------------------------------------------

  Future<List<Map<String, dynamic>>> gatherings(String orgId, {required bool admin}) async =>
      _list((await SyncService.instance.raw('gath.gatherings:$orgId:$admin', () => _client.rpc(admin ? 'admin_list_gatherings' : 'my_gatherings', params: admin ? {'p_org': orgId, 'p_status': null} : {'p_org': orgId}))));

  Future<Map<String, dynamic>> gatheringDetail(String id) async => Map<String, dynamic>.from((await SyncService.instance.raw('gath.gatheringDetail:$id', () => _client.rpc('gathering_detail', params: {'p_gathering': id}))) as Map);

  Future<Map<String, List<Map<String, dynamic>>>> suggestions(String id) async {
    final rows = _list((await SyncService.instance.raw('gath.suggestions:$id', () => _client.rpc('admin_suggest_gathering_matches', params: {'p_gathering': id}))));
    return {for (final r in rows) r['entry_id'] as String: _list(r['suggestions'])};
  }

  Future<List<Map<String, dynamic>>> activityTypes(String orgId) async =>
      _list((await SyncService.instance.raw('gath.activityTypes:$orgId', () => _client.from('activity_types').select('id, name').eq('organization_id', orgId).order('name'))) as List<dynamic>);

  Future<int> submitGathering(String orgId,
      {required String title, String? typeId, required DateTime date, String? location, String? notes, required List<String> names}) async {
    final r = await _client.rpc('submit_gathering', params: {
      'p_org': orgId,
      'p_title': title,
      'p_type': typeId,
      'p_date': date.toIso8601String().substring(0, 10),
      'p_location': location,
      'p_notes': notes,
      'p_names': names,
    }) as Map;
    return (r['names_count'] as num).toInt();
  }

  Future<void> deleteGathering(String id) => _client.rpc('delete_gathering', params: {'p_id': id});
  Future<void> addEntry(String gatheringId, String name) => _client.rpc('gathering_add_entry', params: {'p_gathering': gatheringId, 'p_name': name});
  Future<void> deleteEntry(String entryId) => _client.rpc('gathering_delete_entry', params: {'p_entry': entryId});
  Future<Map<String, dynamic>> matchEntry(String entryId, String studentId) async =>
      Map<String, dynamic>.from(await _client.rpc('admin_match_gathering_entry', params: {'p_entry': entryId, 'p_student': studentId}) as Map);
  Future<void> skipEntry(String entryId) => _client.rpc('admin_skip_gathering_entry', params: {'p_entry': entryId});
  Future<String> unmatchEntry(String entryId) async => '${await _client.rpc('admin_unmatch_gathering_entry', params: {'p_entry': entryId})}';

  // ---- external recitations ----------------------------------------------------

  Future<List<Map<String, dynamic>>> externals(String orgId, {required bool admin}) async => _list((await SyncService.instance.raw('gath.externals:$orgId:$admin', () => _client.rpc(
      admin ? 'admin_list_external_recitations' : 'my_external_recitations',
      params: admin ? {'p_org': orgId, 'p_status': null} : {'p_org': orgId}))));

  Future<void> submitExternal(String orgId,
      {required String name, required String type, required int surah, required int from, required int to, required String grade, String? notes, required String clientRef}) =>
      _client.rpc('submit_external_recitation', params: {
        'p_org': orgId,
        'p_name': name,
        'p_type': type,
        'p_surah': surah,
        'p_from': from,
        'p_to': to,
        'p_grade': grade,
        'p_notes': notes,
        'p_recorded_at': null,
        'p_client_ref': clientRef,
      });

  Future<void> deleteExternal(String id) => _client.rpc('delete_external_recitation', params: {'p_id': id});
  Future<int> matchExternal(String id, String studentId) async =>
      ((await _client.rpc('admin_match_external_recitation', params: {'p_id': id, 'p_student': studentId}) as Map)['points_awarded'] as num).toInt();
  Future<void> rejectExternal(String id, String? reason) => _client.rpc('admin_reject_external_recitation', params: {'p_id': id, 'p_reason': reason});

  Future<Map<String, int>> pendingReviews(String orgId) async {
    final j = Map<String, dynamic>.from((await SyncService.instance.raw('gath.pendingReviews:$orgId', () => _client.rpc('admin_pending_reviews', params: {'p_org': orgId}))) as Map);
    return {'gatherings': (j['gatherings'] as num).toInt(), 'external': (j['external'] as num).toInt()};
  }
}
