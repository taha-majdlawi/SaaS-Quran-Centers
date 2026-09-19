/// Serd (سرد) value types and wording. Everything the server decides (score,
/// points, what amount is permitted) comes from SQL; this file only names and
/// previews things - the same split the web uses (lib/serd/format.ts).
library;

const kJuzNames = [
  'آلم', 'سيقول', 'تلك الرسل', 'لن تنالوا', 'والمحصنات', 'لا يحب الله', 'وإذا سمعوا', 'ولو أننا', 'قال الملأ',
  'واعلموا', 'يعتذرون', 'وما من دابة', 'وما أبرئ', 'ربما', 'سبحان الذي', 'قال ألم', 'اقترب للناس', 'قد أفلح',
  'وقال الذين', 'أمّن خلق', 'اتل ما أوحي', 'ومن يقنت', 'وما لي', 'فمن أظلم', 'إليه يرد', 'حم', 'قال فما خطبكم',
  'قد سمع', 'تبارك الذي', 'عمّ',
];

const kSerdDenNames = {1: 'الجزء كاملاً', 2: 'النصف', 4: 'الربع', 8: 'الثُمن'};
const _ordinals = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن'];

const kSerdStatusLabels = {
  'scheduled': 'مجدول',
  'submitted': 'بانتظار الاعتماد',
  'approved': 'معتمد',
  'rejected': 'مرفوض',
};

String serdPortionLabel(int den, int index) => den <= 1 ? '' : '${kSerdDenNames[den] ?? ''} ${_ordinals[index - 1]}';

/// '3.5' - how much Quran an amount of eighths comes to.
String serdJuzEquivalent(int eighths) {
  final v = eighths / 8;
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(v * 10 == (v * 10).roundToDouble() ? 1 : 2);
}

class SerdPart {
  const SerdPart({required this.juz, this.den = 1, this.index = 1, this.juzName = ''});

  final int juz;
  final int den;
  final int index;
  final String juzName;

  factory SerdPart.fromJson(Map<String, dynamic> j) => SerdPart(
        juz: (j['juz'] as num).toInt(),
        den: (j['den'] as num?)?.toInt() ?? 1,
        index: (j['index'] as num?)?.toInt() ?? 1,
        juzName: (j['juz_name'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'juz': juz, 'den': den, 'index': index};

  String get label {
    final base = 'جزء $juz${juzName.isEmpty ? '' : ' — $juzName'}';
    final portion = serdPortionLabel(den, index);
    return portion.isEmpty ? base : '$base ($portion)';
  }
}

String serdPartsLabel(List<SerdPart> parts) => parts.map((p) => p.label).join('، ');

class SerdError {
  const SerdError({required this.name, required this.count, required this.deducted});
  final String name;
  final int count;
  final num deducted;
}

class SerdRow {
  const SerdRow({
    required this.id,
    required this.studentName,
    required this.sessionDate,
    required this.status,
    required this.parts,
    required this.totalEighths,
    required this.errors,
    required this.pointsAwarded,
    this.studentId,
    this.studentCode,
    this.circleName,
    this.circleTeacherName,
    this.examinerName,
    this.assignedTeacherName,
    this.assignedToMe = false,
    this.overdue = false,
    this.scorePercent,
    this.passPercentApplied,
    this.notes,
    this.rejectReason,
  });

  final String id;
  final String? studentId;
  final String studentName;
  final String? studentCode;
  final String? circleName;
  final String? circleTeacherName;
  final String? examinerName;
  final String? assignedTeacherName;
  final bool assignedToMe;
  final bool overdue;
  final String sessionDate;
  final String status;
  final num? scorePercent;
  final int pointsAwarded;
  final num? passPercentApplied;
  final String? notes;
  final String? rejectReason;
  final List<SerdPart> parts;
  final int totalEighths;
  final List<SerdError> errors;

  bool get passed => scorePercent != null && passPercentApplied != null && scorePercent! >= passPercentApplied!;

  factory SerdRow.fromJson(Map<String, dynamic> j) => SerdRow(
        id: j['id'] as String,
        studentId: j['student_id'] as String?,
        studentName: j['student_name'] as String,
        studentCode: j['student_code'] as String?,
        circleName: j['circle_name'] as String?,
        circleTeacherName: j['circle_teacher_name'] as String?,
        examinerName: j['examiner_name'] as String?,
        assignedTeacherName: j['assigned_teacher_name'] as String?,
        assignedToMe: j['assigned_to_me'] as bool? ?? false,
        overdue: j['overdue'] as bool? ?? false,
        sessionDate: j['session_date'] as String,
        status: j['status'] as String,
        scorePercent: j['score_percent'] as num?,
        pointsAwarded: (j['points_awarded'] as num?)?.toInt() ?? 0,
        passPercentApplied: j['pass_percent_applied'] as num?,
        notes: j['notes'] as String?,
        rejectReason: j['reject_reason'] as String?,
        totalEighths: (j['total_eighths'] as num?)?.toInt() ?? 0,
        parts: [for (final p in (j['parts'] as List? ?? const [])) SerdPart.fromJson(p as Map<String, dynamic>)],
        errors: [
          for (final e in (j['errors'] as List? ?? const []))
            SerdError(
              name: e['name'] as String,
              count: (e['count'] as num).toInt(),
              deducted: e['deducted'] as num,
            ),
        ],
      );
}

class SerdErrorType {
  const SerdErrorType({
    required this.id,
    required this.name,
    required this.errorsPerUnit,
    required this.percentPerUnit,
    required this.isActive,
  });

  final String id;
  final String name;
  final int errorsPerUnit;
  final num percentPerUnit;
  final bool isActive;
}

class SerdStagePolicy {
  const SerdStagePolicy({required this.stageId, required this.denominators, this.passPercent});
  final String stageId;
  final List<int> denominators;
  final num? passPercent;
}

class SerdSetup {
  const SerdSetup({
    required this.passPercent,
    required this.pointsPerJuz,
    required this.defaultDenominators,
    required this.errorTypes,
    required this.stages,
  });

  final num passPercent;
  final int pointsPerJuz;
  final List<int> defaultDenominators;
  final List<SerdErrorType> errorTypes;
  final List<SerdStagePolicy> stages;

  /// Every amount any stage may use (the server re-checks the student's own).
  List<int> get pickerDenominators => {1, ...defaultDenominators, for (final s in stages) ...s.denominators}.toList()..sort();

  factory SerdSetup.fromJson(Map<String, dynamic> j) => SerdSetup(
        passPercent: j['pass_percent'] as num? ?? 80,
        pointsPerJuz: (j['points_per_juz'] as num?)?.toInt() ?? 50,
        defaultDenominators: [for (final d in (j['default_denominators'] as List? ?? const [1])) (d as num).toInt()],
        errorTypes: [
          for (final e in (j['error_types'] as List? ?? const []))
            SerdErrorType(
              id: e['id'] as String,
              name: e['name'] as String,
              errorsPerUnit: (e['errors_per_unit'] as num).toInt(),
              percentPerUnit: e['percent_per_unit'] as num,
              isActive: e['is_active'] as bool,
            ),
        ],
        stages: [
          for (final s in (j['stages'] as List? ?? const []))
            SerdStagePolicy(
              stageId: s['stage_id'] as String,
              denominators: [for (final d in (s['denominators'] as List)) (d as num).toInt()],
              passPercent: s['pass_percent'] as num?,
            ),
        ],
      );
}

class SerdSummary {
  const SerdSummary({
    required this.sessionsCount,
    required this.eighthsTotal,
    required this.juzDone,
    required this.juzProgress,
    required this.sessions,
    this.averageScore,
    this.bestScore,
    this.lastDate,
    this.totalPoints = 0,
  });

  final int sessionsCount;
  final num? averageScore;
  final num? bestScore;
  final String? lastDate;
  final int totalPoints;
  final int eighthsTotal;
  final List<int> juzDone;
  final List<({int juz, String name, int eighths})> juzProgress;
  final List<SerdRow> sessions;

  factory SerdSummary.fromJson(Map<String, dynamic> j) => SerdSummary(
        sessionsCount: (j['sessions_count'] as num?)?.toInt() ?? 0,
        averageScore: j['average_score'] as num?,
        bestScore: j['best_score'] as num?,
        lastDate: j['last_date'] as String?,
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
        eighthsTotal: (j['eighths_total'] as num?)?.toInt() ?? 0,
        juzDone: [for (final d in (j['juz_done'] as List? ?? const [])) (d as num).toInt()],
        juzProgress: [
          for (final p in (j['juz_progress'] as List? ?? const []))
            (juz: (p['juz'] as num).toInt(), name: (p['juz_name'] as String?) ?? '', eighths: (p['eighths'] as num).toInt()),
        ],
        sessions: [for (final s in (j['sessions'] as List? ?? const [])) SerdRow.fromJson(s as Map<String, dynamic>)],
      );
}
