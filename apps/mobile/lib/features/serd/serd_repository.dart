import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'serd_models.dart';

class SerdListPage {
  const SerdListPage({required this.total, required this.rows});
  final int total;
  final List<SerdRow> rows;
}

class SerdReport {
  const SerdReport(this.raw);
  final Map<String, dynamic> raw;

  num get total => raw['total'] as num;
  num get approved => raw['approved'] as num;
  num get pending => raw['pending'] as num;
  num get rejected => raw['rejected'] as num;
  num? get averageScore => raw['average_score'] as num?;
  num get students => raw['students'] as num;
  num get points => raw['points'] as num;
  List<Map<String, dynamic>> list(String key) => [for (final e in (raw[key] as List)) e as Map<String, dynamic>];
}

/// Mirrors apps/web's serd/actions.ts - every rule (who may grade, amounts
/// allowed per stage, freeze rule, points) lives in SQL RPCs, so the phone can
/// never disagree with the web.
class SerdRepository {
  SerdRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Map<String, dynamic> _map(dynamic v) => v as Map<String, dynamic>;
  List<SerdRow> _rows(dynamic v) => [for (final r in (v as List? ?? const [])) SerdRow.fromJson(_map(r))];

  Future<SerdSetup> fetchSetup(String orgId) async =>
      SerdSetup.fromJson(_map(await _client.rpc('serd_grading_setup', params: {'p_org': orgId})));

  Future<SerdListPage> adminList(String orgId, {String? status, int page = 1, int pageSize = 30}) async {
    final data = _map(await _client.rpc('admin_serd_list', params: {
      'p_org': orgId,
      'p_status': status,
      'p_limit': pageSize,
      'p_offset': (page - 1) * pageSize,
    }));
    return SerdListPage(total: (data['total'] as num).toInt(), rows: _rows(data['rows']));
  }

  Future<List<SerdRow>> teacherScheduled(String orgId) async =>
      _rows(await _client.rpc('teacher_scheduled_serd', params: {'p_org': orgId}));

  Future<List<SerdRow>> teacherMy(String orgId) async =>
      _rows(await _client.rpc('teacher_my_serd', params: {'p_org': orgId, 'p_limit': 60}));

  Future<SerdSummary> studentSummary(String orgId, String studentId) async =>
      SerdSummary.fromJson(_map(await _client.rpc('serd_student_summary', params: {'p_org': orgId, 'p_student': studentId})));

  /// Returns the server-computed score. A fresh client_ref makes a retry (bad
  /// network) safe: the server ignores a repeated one.
  Future<num?> submit({
    required String orgId,
    String? studentId,
    String? studentName,
    required List<SerdPart> parts,
    required DateTime date,
    String? notes,
    required Map<String, int> errors,
    String? sessionId,
  }) async {
    final result = _map(await _client.rpc('teacher_submit_serd', params: {
      'p_org': orgId,
      'p_student': studentId,
      'p_student_name': studentName,
      'p_parts': [for (final p in parts) p.toJson()],
      'p_date': _dateOnly(date),
      'p_notes': notes,
      'p_errors': [
        for (final e in errors.entries)
          if (e.value > 0) {'type_id': e.key, 'count': e.value},
      ],
      'p_client_ref': _uuid.v4(),
      'p_session_id': sessionId,
    }));
    return result['score_percent'] as num?;
  }

  Future<void> schedule({
    required String orgId,
    required String studentId,
    required List<SerdPart> parts,
    required DateTime date,
    String? notes,
    String? teacherId,
  }) {
    return _client.rpc('admin_schedule_serd', params: {
      'p_org': orgId,
      'p_student': studentId,
      'p_parts': [for (final p in parts) p.toJson()],
      'p_date': _dateOnly(date),
      'p_notes': notes,
      'p_teacher': teacherId,
    });
  }

  Future<void> review(String sessionId, String decision, {String? studentId, String? reason}) {
    return _client.rpc('admin_review_serd', params: {
      'p_session': sessionId,
      'p_decision': decision,
      'p_student': studentId,
      'p_reason': reason,
    });
  }

  Future<void> delete(String sessionId) => _client.rpc('admin_delete_serd', params: {'p_session': sessionId});

  Future<SerdReport> report(String orgId, {DateTime? from, DateTime? to}) async => SerdReport(_map(await _client.rpc(
        'admin_serd_report',
        params: {'p_org': orgId, 'p_from': from == null ? null : _dateOnly(from), 'p_to': to == null ? null : _dateOnly(to)},
      )));

  // ---- settings (admin) ----------------------------------------------------

  Future<void> saveSettings(String orgId, {required num passPercent, required int pointsPerJuz, required List<int> denominators}) {
    return _client.rpc('set_serd_settings', params: {
      'p_org': orgId,
      'p_pass_percent': passPercent,
      'p_points_per_juz': pointsPerJuz,
      'p_denominators': [1, ...denominators.where((d) => d != 1)],
    });
  }

  Future<void> saveErrorType(
    String orgId, {
    String? id,
    required String name,
    required int errorsPerUnit,
    required num percentPerUnit,
    required bool isActive,
    required int sortOrder,
  }) {
    return _client.rpc('save_serd_error_type', params: {
      'p_org': orgId,
      'p_id': id,
      'p_name': name,
      'p_errors_per_unit': errorsPerUnit,
      'p_percent_per_unit': percentPerUnit,
      'p_is_active': isActive,
      'p_sort_order': sortOrder,
    });
  }

  Future<void> deleteErrorType(String orgId, String id) =>
      _client.rpc('delete_serd_error_type', params: {'p_org': orgId, 'p_id': id});

  Future<void> saveStagePolicy(String orgId, String stageId, {required List<int> denominators, num? passPercent}) {
    return _client.rpc('set_serd_stage_policy', params: {
      'p_org': orgId,
      'p_stage': stageId,
      'p_denominators': denominators,
      'p_pass_percent': passPercent,
    });
  }

  Future<List<({String id, String name})>> fetchStages(String orgId) async {
    final rows = await _client.from('stages').select('id, name').eq('organization_id', orgId).order('name');
    return [for (final r in rows as List) (id: r['id'] as String, name: r['name'] as String)];
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
