import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarEventSummary {
  const CalendarEventSummary({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.requiresGuardianConsent,
    this.location,
  });

  final String id;
  final String title;
  final String startsAt;
  final bool requiresGuardianConsent;
  final String? location;
}

class CalendarEventDetail {
  const CalendarEventDetail({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.requiresGuardianConsent,
    this.description,
    this.location,
  });

  final String id;
  final String title;
  final String startsAt;
  final bool requiresGuardianConsent;
  final String? description;
  final String? location;
}

class CalendarRegistration {
  const CalendarRegistration({required this.id, required this.studentName});
  final String id;
  final String studentName;
}

class CalendarStudentOption {
  const CalendarStudentOption({required this.id, required this.fullName});
  final String id;
  final String fullName;
}

/// Mirrors apps/web's calendar/actions.ts - center-wide events, optionally
/// requiring guardian consent (trips etc.), with a student registration list.
class CalendarRepository {
  CalendarRepository(this._client);

  final SupabaseClient _client;

  Future<List<CalendarEventSummary>> fetchEvents(String organizationId) async {
    final rows = await _client
        .from('center_calendar')
        .select('id, title, starts_at, location, requires_guardian_consent')
        .eq('organization_id', organizationId)
        .order('starts_at');
    return (rows as List)
        .map((r) => CalendarEventSummary(
              id: r['id'] as String,
              title: r['title'] as String,
              startsAt: r['starts_at'] as String,
              requiresGuardianConsent: r['requires_guardian_consent'] as bool,
              location: r['location'] as String?,
            ))
        .toList();
  }

  Future<CalendarEventDetail?> fetchEvent(String id) async {
    final row = await _client
        .from('center_calendar')
        .select('id, title, description, starts_at, location, requires_guardian_consent')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return CalendarEventDetail(
      id: row['id'] as String,
      title: row['title'] as String,
      startsAt: row['starts_at'] as String,
      requiresGuardianConsent: row['requires_guardian_consent'] as bool,
      description: row['description'] as String?,
      location: row['location'] as String?,
    );
  }

  Future<void> createEvent({
    required String organizationId,
    required String title,
    required String startsAt,
    String? description,
    String? location,
    required bool requiresConsent,
    required String? createdBy,
  }) {
    return _client.from('center_calendar').insert({
      'organization_id': organizationId,
      'title': title,
      'description': description,
      'starts_at': startsAt,
      'location': location,
      'requires_guardian_consent': requiresConsent,
      'created_by': createdBy,
    });
  }

  Future<void> updateEvent({
    required String id,
    required String title,
    required String startsAt,
    String? description,
    String? location,
    required bool requiresConsent,
  }) {
    return _client.from('center_calendar').update({
      'title': title,
      'description': description,
      'starts_at': startsAt,
      'location': location,
      'requires_guardian_consent': requiresConsent,
    }).eq('id', id);
  }

  Future<void> deleteEvent(String id) {
    return _client.from('center_calendar').delete().eq('id', id);
  }

  Future<List<CalendarRegistration>> fetchRegistrations(String eventId) async {
    final rows = await _client
        .from('calendar_registrations')
        .select('id, students_profile(full_name)')
        .eq('event_id', eventId);
    return (rows as List).map((r) {
      final student = r['students_profile'] as Map<String, dynamic>?;
      return CalendarRegistration(id: r['id'] as String, studentName: (student?['full_name'] as String?) ?? '—');
    }).toList();
  }

  Future<List<CalendarStudentOption>> fetchActiveStudents(String organizationId) async {
    final rows = await _client
        .from('students_profile')
        .select('id, full_name')
        .eq('organization_id', organizationId)
        .eq('status', 'active')
        .order('full_name');
    return (rows as List)
        .map((r) => CalendarStudentOption(id: r['id'] as String, fullName: r['full_name'] as String))
        .toList();
  }

  /// Throws a PostgrestException with code 23505 if already registered.
  Future<void> registerStudent({required String eventId, required String studentId}) {
    return _client.from('calendar_registrations').insert({
      'event_id': eventId,
      'student_id': studentId,
      'status': 'registered',
    });
  }

  Future<void> cancelRegistration(String id) {
    return _client.from('calendar_registrations').delete().eq('id', id);
  }
}
