import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/i18n.dart';
import '../../core/supabase/supabase_client.dart';

/// A word the check or the teacher flagged: ayah, word index (same split as
/// wordRanges), and 'missing' / 'wrong' / 'mistake'.
typedef WordMarks = Map<String, String>;

String markKey(int ayah, int word) => '$ayah:$word';

class ReciteStudent {
  const ReciteStudent(this.id, this.name, this.circle);
  final String id;
  final String name;
  final String? circle;
}

class RecitePeople {
  const RecitePeople(this.mode, this.students);

  /// 'staff' (tests students), 'family' (recites) or 'none'
  final String mode;
  final List<ReciteStudent> students;
}

/// The result of the site's check (apps/web/src/lib/quran/recite.ts).
class ReciteCheck {
  const ReciteCheck({required this.available, this.score = 0, this.ok = 0, this.missing = 0, this.wrong = 0, this.extra = 0, this.marks = const {}});

  factory ReciteCheck.fromJson(Map<String, dynamic>? r) {
    final words = r?['words'];
    if (r == null || r['unavailable'] == true || words is! List) return const ReciteCheck(available: false);
    return ReciteCheck(
      available: true,
      score: (r['score'] as num?)?.toDouble() ?? 0,
      ok: (r['ok'] as num?)?.toInt() ?? 0,
      missing: (r['missing'] as num?)?.toInt() ?? 0,
      wrong: (r['wrong'] as num?)?.toInt() ?? 0,
      extra: (r['extra'] as num?)?.toInt() ?? 0,
      marks: {
        for (final w in words.cast<Map<String, dynamic>>())
          if (w['s'] != 'ok') markKey((w['a'] as num).toInt(), (w['i'] as num).toInt()): w['s'] as String,
      },
    );
  }

  final bool available;
  final double score;
  final int ok, missing, wrong, extra;
  final WordMarks marks;
}

/// One recorded recitation or teacher test (public._recitation_json, 0085).
class RecitationItem {
  RecitationItem(this.raw);
  final Map<String, dynamic> raw;

  String get id => raw['id'] as String;
  String get kind => raw['kind'] as String? ?? 'self';
  String get type => raw['type'] as String? ?? 'new_memorization';
  int get surah => (raw['surah'] as num).toInt();
  int get from => (raw['ayah_from'] as num).toInt();
  int get to => (raw['ayah_to'] as num).toInt();
  String? get audioPath => raw['audio_path'] as String?;
  String get status => raw['status'] as String? ?? 'draft';
  double? get autoScore => (raw['auto_score'] as num?)?.toDouble();
  ReciteCheck get check => ReciteCheck.fromJson(raw['auto_result'] as Map<String, dynamic>?);
  List<Map<String, dynamic>> get mistakes => ((raw['mistakes'] as List?) ?? const []).cast<Map<String, dynamic>>();
  String? get grade => raw['grade'] as String?;
  String? get studentNote => raw['student_note'] as String?;
  String? get teacherNote => raw['teacher_note'] as String?;
  String? get student => raw['student'] as String?;
  String? get circle => raw['circle'] as String?;
  String? get reviewer => raw['reviewer'] as String?;
  DateTime? get at => DateTime.tryParse((raw['submitted_at'] ?? raw['created_at']) as String? ?? '')?.toLocal();
}

class RecitationApi {
  RecitationApi([SupabaseClient? client]) : _client = client ?? AppSupabase.client;

  final SupabaseClient _client;
  static const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://bustan-alquran.com');
  static const _uuid = Uuid();

  Future<RecitePeople> people(String orgId) async {
    final r = (await _client.rpc('recitation_people', params: {'p_org': orgId})) as Map<String, dynamic>;
    return RecitePeople(r['mode'] as String? ?? 'none', [
      for (final s in (r['students'] as List? ?? const []).cast<Map<String, dynamic>>()) ReciteStudent(s['id'] as String, s['name'] as String? ?? '', s['circle'] as String?),
    ]);
  }

  Future<List<({String key, String label})>> grades(String orgId) async {
    final rows = await _client.from('recitation_grades').select('key, label').eq('organization_id', orgId).eq('is_active', true).order('sort_order');
    return [for (final r in rows) (key: r['key'] as String, label: r['label'] as String)];
  }

  /// Uploads the recording and creates the (unsent) recitation; returns its id and file path.
  Future<({String id, String path})> create({
    required String orgId,
    required String studentId,
    required String type,
    required int surah,
    required int from,
    required int to,
    required File file,
    required int seconds,
  }) async {
    final path = '$orgId/$studentId/${_uuid.v4()}.wav';
    await _client.storage.from('recitations').upload(path, file, fileOptions: const FileOptions(contentType: 'audio/wav'));
    final id = await _client.rpc('create_recitation', params: {
      'p_org': orgId,
      'p_student': studentId,
      'p_type': type,
      'p_surah': surah,
      'p_ayah_from': from,
      'p_ayah_to': to,
      'p_audio_path': path,
      'p_duration': seconds,
      'p_client_ref': _uuid.v4(),
    });
    return (id: id as String, path: path);
  }

  /// The site transcribes the recording and compares it with the ayahs.
  Future<ReciteCheck> check(String id) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) return const ReciteCheck(available: false);
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await http.postUrl(Uri.parse('$_baseUrl/api/recitations/check'));
      request.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.add(utf8.encode(jsonEncode({'id': id})));
      final response = await request.close().timeout(const Duration(seconds: 90));
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400 || text.isEmpty) return const ReciteCheck(available: false);
      return ReciteCheck.fromJson((jsonDecode(text) as Map<String, dynamic>)['result'] as Map<String, dynamic>?);
    } catch (_) {
      return const ReciteCheck(available: false);
    } finally {
      http.close();
    }
  }

  Future<void> submit(String id, String? note) => _client.rpc('submit_recitation', params: {'p_id': id, 'p_note': note});

  Future<void> discard(String id, String path) async {
    await _client.rpc('discard_recitation', params: {'p_id': id});
    await _client.storage.from('recitations').remove([path]);
  }

  Future<Map<String, dynamic>> recordTest({
    required String orgId,
    required String studentId,
    required String type,
    required int surah,
    required int from,
    required int to,
    required String grade,
    required List<Map<String, dynamic>> mistakes,
    String? note,
  }) async {
    final r = await _client.rpc('record_teacher_test', params: {
      'p_org': orgId,
      'p_student': studentId,
      'p_type': type,
      'p_surah': surah,
      'p_ayah_from': from,
      'p_ayah_to': to,
      'p_grade': grade,
      'p_mistakes': mistakes,
      'p_note': note,
      'p_client_ref': _uuid.v4(),
    });
    return (r as Map).cast<String, dynamic>();
  }

  Future<List<RecitationItem>> inbox(String orgId, {required bool reviewed}) async {
    final r = await _client.rpc('recitation_inbox', params: {'p_org': orgId, 'p_status': reviewed ? '' : 'submitted', 'p_limit': 100});
    return [for (final x in (r as List).cast<Map<String, dynamic>>()) if (!reviewed || x['status'] != 'submitted') RecitationItem(x)];
  }

  Future<List<RecitationItem>> ofStudent(String orgId, String studentId) async {
    final r = await _client.rpc('student_recitations', params: {'p_org': orgId, 'p_student': studentId, 'p_limit': 50});
    return [for (final x in (r as List).cast<Map<String, dynamic>>()) RecitationItem(x)];
  }

  Future<void> review(String id, {required bool approve, String? grade, String? type, String? note}) =>
      _client.rpc('review_recitation', params: {'p_id': id, 'p_approve': approve, 'p_grade': grade, 'p_type': type, 'p_note': note});

  Future<String?> audioUrl(String path) async {
    try {
      return await _client.storage.from('recitations').createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }
}

/// "Surah 2 · 1–5" in the viewer's language.
String passageLabel(String surahName, int from, int to) => fmt(currentStrings.recite.ayahRange, {'surah': surahName, 'from': from, 'to': to});
