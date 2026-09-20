import 'package:supabase_flutter/supabase_flutter.dart';

const kReportTypeLabels = {
  'new_memorization': 'حفظ جديد',
  'recent_review': 'مراجعة قريبة',
  'distant_review': 'مراجعة بعيدة',
};

const kReportAttendanceLabels = {'present': 'حاضر', 'late': 'متأخر', 'absent': 'غائب', 'excused': 'مستأذن'};

String reportDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String reportDay(dynamic iso) {
  if (iso == null) return '—';
  final d = DateTime.tryParse(iso.toString());
  return d == null ? iso.toString() : '${d.toLocal().day}/${d.toLocal().month}/${d.toLocal().year}';
}

String reportPct(dynamic v) => v == null ? '—' : '$v%';

/// Reports are computed in SQL (`center_report`, `student_report`), so the phone
/// and the web always show the same numbers.
class ReportsRepository {
  ReportsRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> center(String orgId, DateTime from, DateTime to) async =>
      (await _client.rpc('center_report', params: {'p_org': orgId, 'p_from': reportDate(from), 'p_to': reportDate(to)})) as Map<String, dynamic>;

  Future<Map<String, dynamic>> student(String orgId, String studentId, DateTime from, DateTime to) async =>
      (await _client.rpc('student_report', params: {'p_org': orgId, 'p_student': studentId, 'p_from': reportDate(from), 'p_to': reportDate(to)}))
          as Map<String, dynamic>;

  /// The students this account may see (a student: itself; a guardian: its children).
  Future<List<({String id, String name})>> myStudents(String orgId) async {
    final rows = await _client.from('students_profile').select('id, full_name').eq('organization_id', orgId).order('full_name');
    return [for (final r in rows as List) (id: r['id'] as String, name: r['full_name'] as String)];
  }
}
