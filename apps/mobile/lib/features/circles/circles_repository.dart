import 'package:supabase_flutter/supabase_flutter.dart';

const kCircleStatusLabels = {'active': 'نشطة', 'archived': 'مؤرشفة'};

class CircleSummary {
  const CircleSummary({
    required this.id,
    required this.name,
    required this.status,
    this.capacity,
    this.stageName,
    this.teacherName,
  });

  final String id;
  final String name;
  final String status;
  final int? capacity;
  final String? stageName;
  final String? teacherName;
}

class StageOption {
  const StageOption({required this.id, required this.name});
  final String id;
  final String name;
}

class TeacherOption {
  const TeacherOption({required this.userId, required this.label});
  final String userId;
  final String label;
}

class CircleDetail {
  const CircleDetail({
    required this.id,
    required this.name,
    required this.status,
    this.capacity,
    this.stageId,
    this.teacherId,
  });

  final String id;
  final String name;
  final String status;
  final int? capacity;
  final String? stageId;
  final String? teacherId;
}

/// Mirrors apps/web's circles/actions.ts - same table/columns, called
/// directly from Dart instead of a Server Action.
class CirclesRepository {
  CirclesRepository(this._client);

  final SupabaseClient _client;

  Future<List<CircleSummary>> fetchCircles(String organizationId) async {
    final rows = await _client
        .from('circles')
        .select('id, name, capacity, status, teacher_id, stages(name)')
        .eq('organization_id', organizationId)
        .order('name');

    final teacherNames = await _teacherNamesByUserId(organizationId);

    return (rows as List).map((r) {
      final stage = r['stages'] as Map<String, dynamic>?;
      final teacherId = r['teacher_id'] as String?;
      return CircleSummary(
        id: r['id'] as String,
        name: r['name'] as String,
        status: r['status'] as String,
        capacity: r['capacity'] as int?,
        stageName: stage?['name'] as String?,
        teacherName: teacherId != null ? teacherNames[teacherId] : null,
      );
    }).toList();
  }

  Future<List<StageOption>> fetchStages(String organizationId) async {
    final rows = await _client
        .from('stages')
        .select('id, name')
        .eq('organization_id', organizationId)
        .order('sort_order');
    return (rows as List).map((r) => StageOption(id: r['id'] as String, name: r['name'] as String)).toList();
  }

  Future<List<TeacherOption>> fetchTeachers(String organizationId) async {
    final rows = await _client.rpc('list_org_members', params: {'org_id': organizationId});
    return (rows as List)
        .where((r) => r['role'] == 'teacher')
        .map((r) => TeacherOption(
              userId: r['user_id'] as String,
              label: (r['full_name'] as String?) ?? (r['email'] as String?) ?? '—',
            ))
        .toList();
  }

  Future<Map<String, String>> _teacherNamesByUserId(String organizationId) async {
    final teachers = await fetchTeachers(organizationId);
    return {for (final t in teachers) t.userId: t.label};
  }

  Future<CircleDetail?> fetchCircle(String id) async {
    final row = await _client
        .from('circles')
        .select('id, name, capacity, status, stage_id, teacher_id')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return CircleDetail(
      id: row['id'] as String,
      name: row['name'] as String,
      status: row['status'] as String,
      capacity: row['capacity'] as int?,
      stageId: row['stage_id'] as String?,
      teacherId: row['teacher_id'] as String?,
    );
  }

  Future<void> createCircle({
    required String organizationId,
    required String name,
    String? stageId,
    String? teacherId,
    int? capacity,
  }) {
    return _client.from('circles').insert({
      'organization_id': organizationId,
      'name': name,
      'stage_id': stageId,
      'teacher_id': teacherId,
      'capacity': capacity,
    });
  }

  Future<void> updateCircle({
    required String id,
    required String name,
    required String status,
    String? stageId,
    String? teacherId,
    int? capacity,
  }) {
    return _client.from('circles').update({
      'name': name,
      'status': status,
      'stage_id': stageId,
      'teacher_id': teacherId,
      'capacity': capacity,
    }).eq('id', id);
  }

  Future<void> deleteCircle(String id) {
    return _client.from('circles').delete().eq('id', id);
  }
}
