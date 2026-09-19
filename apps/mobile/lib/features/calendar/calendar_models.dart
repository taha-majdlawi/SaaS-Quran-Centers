/// Calendar value types. Everything the server decides (who sees an entry,
/// seats, whether registration is open, consent) arrives ready-made from the
/// calendar_* RPCs - the same payload the web pages read.
library;

import 'package:flutter/material.dart';

const kAudienceLabels = {'all': 'الجميع', 'teachers': 'المعلمون', 'students': 'الطلاب', 'guardians': 'أولياء الأمور'};
const kConsentLabels = {'not_required': '—', 'pending': 'بانتظار الموافقة', 'approved': 'موافق', 'declined': 'رفض'};
const kSourceLabels = {'self': 'سجّل بنفسه', 'guardian': 'سجّله ولي الأمر', 'teacher': 'سجّله المعلم', 'admin': 'سجّله المشرف'};
const kStateLabels = {
  'none': 'بلا تسجيل',
  'ended': 'انتهت',
  'closed': 'التسجيل مغلق',
  'full': 'اكتملت المقاعد',
  'open': 'التسجيل مفتوح',
};

const kMonthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

Color parseHexColor(String? hex, [Color fallback = const Color(0xFF64748B)]) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return fallback;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseIsoDate(String s) => DateTime.parse('${s.substring(0, 10)}T00:00:00');

String formatDayRange(String start, String end) {
  String f(String s) {
    final d = parseIsoDate(s);
    return '${d.day} ${kMonthNames[d.month - 1]} ${d.year}';
  }

  return start == end ? f(start) : '${f(start)} — ${f(end)}';
}

class CalType {
  const CalType({
    required this.id,
    required this.key,
    required this.name,
    required this.color,
    required this.defaultIsWorking,
    required this.isActive,
    required this.supportsRegistration,
    required this.requiresConsent,
    required this.sortOrder,
  });

  final String id;
  final String key;
  final String name;
  final String color;
  final bool defaultIsWorking;
  final bool isActive;
  final bool supportsRegistration;
  final bool requiresConsent;
  final int sortOrder;

  factory CalType.fromJson(Map<String, dynamic> j) => CalType(
        id: j['id'] as String,
        key: j['key'] as String,
        name: j['name'] as String,
        color: (j['color'] as String?) ?? '#64748b',
        defaultIsWorking: j['default_is_working'] as bool,
        isActive: j['is_active'] as bool,
        supportsRegistration: j['supports_registration'] as bool,
        requiresConsent: j['requires_guardian_consent'] as bool,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class MineRow {
  const MineRow({
    required this.studentId,
    required this.studentName,
    required this.waiting,
    this.registrationId,
    this.source,
    this.consentStatus,
    this.consentToken,
    this.resultRank,
    this.resultNote,
  });

  final String studentId;
  final String studentName;
  final bool waiting;
  final String? registrationId;
  final String? source;
  final String? consentStatus;
  final String? consentToken;
  final int? resultRank;
  final String? resultNote;

  factory MineRow.fromJson(Map<String, dynamic> j) => MineRow(
        studentId: j['student_id'] as String,
        studentName: j['student_name'] as String,
        waiting: j['waiting'] as bool? ?? false,
        registrationId: j['registration_id'] as String?,
        source: j['source'] as String?,
        consentStatus: j['consent_status'] as String?,
        consentToken: j['consent_token'] as String?,
        resultRank: (j['result_rank'] as num?)?.toInt(),
        resultNote: j['result_note'] as String?,
      );
}

class Participant {
  const Participant({
    required this.registrationId,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.source,
    required this.consentStatus,
    required this.consentToken,
    this.circleName,
    this.consentMethod,
    this.resultRank,
    this.resultNote,
  });

  final String registrationId;
  final String studentId;
  final String studentName;
  final String studentCode;
  final String? circleName;
  final String source;
  final String consentStatus;
  final String? consentMethod;
  final String consentToken;
  final int? resultRank;
  final String? resultNote;

  factory Participant.fromJson(Map<String, dynamic> j) => Participant(
        registrationId: j['registration_id'] as String,
        studentId: j['student_id'] as String,
        studentName: j['student_name'] as String,
        studentCode: (j['student_code'] as String?) ?? '',
        circleName: j['circle_name'] as String?,
        source: j['source'] as String,
        consentStatus: j['consent_status'] as String,
        consentMethod: j['consent_method'] as String?,
        consentToken: j['consent_token'] as String,
        resultRank: (j['result_rank'] as num?)?.toInt(),
        resultNote: j['result_note'] as String?,
      );
}

class CalEntry {
  const CalEntry({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.kind,
    required this.typeName,
    required this.typeColor,
    required this.isWorkingDay,
    required this.audience,
    required this.registrationOpen,
    required this.supportsRegistration,
    required this.requiresConsent,
    required this.taken,
    required this.waiting,
    required this.myRegistered,
    required this.registrationState,
    this.description,
    this.startsAt,
    this.location,
    this.typeId,
    this.circleId,
    this.circleName,
    this.stageId,
    this.stageName,
    this.capacity,
    this.registrationDeadline,
    this.mine = const [],
    this.participants = const [],
    this.waitlist = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String startDate;
  final String endDate;
  final String? startsAt;
  final String? location;
  final String kind;
  final String? typeId;
  final String typeName;
  final Color typeColor;
  final bool isWorkingDay;
  final String audience;
  final String? circleId;
  final String? circleName;
  final String? stageId;
  final String? stageName;
  final int? capacity;
  final bool registrationOpen;
  final String? registrationDeadline;
  final bool supportsRegistration;
  final bool requiresConsent;
  final int taken;
  final int waiting;
  final bool myRegistered;
  final String registrationState;

  // details only
  final List<MineRow> mine;
  final List<Participant> participants;
  final List<({String studentId, String name})> waitlist;

  bool covers(String iso) => startDate.compareTo(iso) <= 0 && endDate.compareTo(iso) >= 0;

  factory CalEntry.fromJson(Map<String, dynamic> j) => CalEntry(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        startDate: j['start_date'] as String,
        endDate: j['end_date'] as String,
        startsAt: j['starts_at'] as String?,
        location: j['location'] as String?,
        kind: j['kind'] as String,
        typeId: j['type_id'] as String?,
        typeName: (j['type_name'] as String?) ?? '',
        typeColor: parseHexColor(j['type_color'] as String?),
        isWorkingDay: j['is_working_day'] as bool,
        audience: j['audience'] as String,
        circleId: j['circle_id'] as String?,
        circleName: j['circle_name'] as String?,
        stageId: j['stage_id'] as String?,
        stageName: j['stage_name'] as String?,
        capacity: (j['capacity'] as num?)?.toInt(),
        registrationOpen: j['registration_open'] as bool,
        registrationDeadline: j['registration_deadline'] as String?,
        supportsRegistration: j['supports_registration'] as bool? ?? false,
        requiresConsent: j['requires_guardian_consent'] as bool? ?? false,
        taken: (j['taken'] as num?)?.toInt() ?? 0,
        waiting: (j['waiting'] as num?)?.toInt() ?? 0,
        myRegistered: j['my_registered'] as bool? ?? false,
        registrationState: (j['registration_state'] as String?) ?? 'none',
        mine: [for (final m in (j['mine'] as List? ?? const [])) MineRow.fromJson(m as Map<String, dynamic>)],
        participants: [for (final p in (j['participants'] as List? ?? const [])) Participant.fromJson(p as Map<String, dynamic>)],
        waitlist: [
          for (final w in (j['waitlist'] as List? ?? const []))
            (studentId: w['student_id'] as String, name: w['student_name'] as String),
        ],
      );
}

class Weekday {
  const Weekday({required this.dow, required this.label, required this.isWorking, required this.isSerdDay});
  final int dow;
  final String label;
  final bool isWorking;
  final bool isSerdDay;
}

class SerdMark {
  const SerdMark({required this.id, required this.studentName, required this.date});
  final String id;
  final String studentName;
  final String date;
}

class CalRange {
  const CalRange({
    required this.workingDays,
    required this.totalDays,
    required this.weekdays,
    required this.types,
    required this.entries,
    required this.serd,
  });

  final int workingDays;
  final int totalDays;
  final List<Weekday> weekdays;
  final List<CalType> types;
  final List<CalEntry> entries;
  final List<SerdMark> serd;

  Weekday? weekday(int dow) => weekdays.where((w) => w.dow == dow).firstOrNull;

  factory CalRange.fromJson(Map<String, dynamic> j) => CalRange(
        workingDays: (j['working_days'] as num).toInt(),
        totalDays: (j['total_days'] as num).toInt(),
        weekdays: [
          for (final w in (j['weekdays'] as List))
            Weekday(
              dow: (w['dow'] as num).toInt(),
              label: w['label'] as String,
              isWorking: w['is_working'] as bool,
              isSerdDay: w['is_serd_day'] as bool? ?? false,
            ),
        ],
        types: [for (final t in (j['types'] as List)) CalType.fromJson(t as Map<String, dynamic>)],
        entries: [for (final e in (j['entries'] as List)) CalEntry.fromJson(e as Map<String, dynamic>)],
        serd: [
          for (final s in (j['serd'] as List))
            SerdMark(id: s['id'] as String, studentName: s['student_name'] as String, date: s['session_date'] as String),
        ],
      );
}

class Candidate {
  const Candidate({required this.studentId, required this.name, required this.code, this.circleName});
  final String studentId;
  final String name;
  final String code;
  final String? circleName;
}
