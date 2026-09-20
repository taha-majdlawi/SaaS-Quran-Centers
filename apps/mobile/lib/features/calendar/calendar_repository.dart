import 'package:supabase_flutter/supabase_flutter.dart';

import 'calendar_models.dart';

/// Mirrors apps/web's calendar/actions.ts. Every rule (audience, seats,
/// deadline, waiting list, consent, permissions) lives in SQL RPCs, so the
/// phone can never disagree with the web.
class CalendarRepository {
  CalendarRepository(this._client);

  final SupabaseClient _client;

  Map<String, dynamic> _map(dynamic v) => v as Map<String, dynamic>;

  Future<CalRange> fetchRange(String orgId, DateTime from, DateTime to) async => CalRange.fromJson(_map(await _client.rpc(
        'calendar_range',
        params: {'p_org': orgId, 'p_from': isoDate(from), 'p_to': isoDate(to), 'p_circle': null},
      )));

  Future<int> reminderHours(String orgId) async => (await _client.rpc('get_reminder_hours', params: {'p_org': orgId})) as int;

  Future<void> setReminderHours(String orgId, int hours) => _client.rpc('set_reminder_hours', params: {'p_org': orgId, 'p_hours': hours});

  Future<CalEntry> fetchDetails(String orgId, String entryId) async =>
      CalEntry.fromJson(_map(await _client.rpc('calendar_entry_details', params: {'p_org': orgId, 'p_entry': entryId})));

  Future<List<Candidate>> fetchCandidates(String orgId, String entryId) async {
    final rows = await _client.rpc('entry_candidates', params: {'p_org': orgId, 'p_entry': entryId}) as List;
    return [
      for (final r in rows)
        if (r['registered'] != true)
          Candidate(
            studentId: r['student_id'] as String,
            name: r['student_name'] as String,
            code: (r['student_code'] as String?) ?? '',
            circleName: r['circle_name'] as String?,
          ),
    ];
  }

  Future<List<({String id, String name})>> fetchCircles(String orgId) async {
    final rows = await _client.from('circles').select('id, name').eq('organization_id', orgId).order('name');
    return [for (final r in rows as List) (id: r['id'] as String, name: r['name'] as String)];
  }

  Future<List<({String id, String name})>> fetchStages(String orgId) async {
    final rows = await _client.from('stages').select('id, name').eq('organization_id', orgId).order('name');
    return [for (final r in rows as List) (id: r['id'] as String, name: r['name'] as String)];
  }

  // ---- admin: entries & types ----------------------------------------------

  Future<String> saveEntry(
    String orgId, {
    String? id,
    required String typeId,
    required String title,
    String? description,
    required DateTime start,
    DateTime? end,
    bool? isWorkingDay,
    required String audience,
    String? circleId,
    String? stageId,
    String? startsAt,
    String? location,
    int? capacity,
    required bool registrationOpen,
    DateTime? deadline,
  }) async {
    final result = await _client.rpc('admin_save_calendar_entry', params: {
      'p_org': orgId,
      'p_id': id,
      'p_type': typeId,
      'p_title': title,
      'p_description': description,
      'p_start': isoDate(start),
      'p_end': end == null ? null : isoDate(end),
      'p_is_working_day': isWorkingDay,
      'p_audience': audience,
      'p_circle': circleId,
      'p_stage': stageId,
      'p_starts_at': startsAt,
      'p_location': location,
      'p_capacity': capacity,
      'p_registration_open': registrationOpen,
      'p_deadline': deadline == null ? null : isoDate(deadline),
    });
    return result as String;
  }

  Future<void> deleteEntry(String orgId, String id) =>
      _client.rpc('admin_delete_calendar_entry', params: {'p_org': orgId, 'p_id': id});

  Future<void> saveType(
    String orgId, {
    String? id,
    required String name,
    required bool defaultIsWorking,
    required String color,
    required int sortOrder,
    required bool isActive,
    required bool supportsRegistration,
    required bool requiresConsent,
  }) {
    return _client.rpc('admin_save_calendar_type', params: {
      'p_org': orgId,
      'p_id': id,
      'p_name': name,
      'p_default_is_working': defaultIsWorking,
      'p_color': color,
      'p_sort_order': sortOrder,
      'p_is_active': isActive,
      'p_supports_registration': supportsRegistration,
      'p_requires_consent': requiresConsent,
    });
  }

  Future<void> deleteType(String orgId, String id) =>
      _client.rpc('admin_delete_calendar_type', params: {'p_org': orgId, 'p_id': id});

  // ---- registration ----------------------------------------------------------

  Future<void> register(String orgId, String entryId, String studentId) =>
      _client.rpc('register_for_entry', params: {'p_org': orgId, 'p_entry': entryId, 'p_student': studentId, 'p_note': null});

  Future<void> unregister(String registrationId) =>
      _client.rpc('unregister_from_entry', params: {'p_registration': registrationId});

  Future<void> joinWaitlist(String orgId, String entryId, String studentId) =>
      _client.rpc('join_waitlist', params: {'p_org': orgId, 'p_entry': entryId, 'p_student': studentId});

  Future<void> leaveWaitlist(String orgId, String entryId, String studentId) =>
      _client.rpc('leave_waitlist', params: {'p_org': orgId, 'p_entry': entryId, 'p_student': studentId});

  Future<void> recordConsent(String registrationId, String decision) =>
      _client.rpc('staff_record_consent', params: {'p_registration': registrationId, 'p_decision': decision});

  Future<void> setResult(String registrationId, int? rank, String? note) =>
      _client.rpc('set_registration_result', params: {'p_registration': registrationId, 'p_rank': rank, 'p_note': note});
}
