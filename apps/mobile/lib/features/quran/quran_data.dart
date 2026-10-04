import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/offline/sync_service.dart';

/// Where the mushaf comes from. The site serves our own copy (eqraa file layout,
/// see docs/QURAN.md):
///   `surah_N.json`                         text, juz, Madinah page, sajda, whole-surah recitations
///   `audio/reciters.json`                  reciters recorded ayah by ayah (url = base + SSSAAA.mp3)
///   `audio/timings/RECITER/surah_N.json`   word timings, relative to each ayah's own file
/// Until it is uploaded the text comes from api.alquran.cloud (Tanzil) and the
/// reciters from the built-in list. Everything read is kept on the device, so a
/// surah opened once reads (and follows word by word) offline.
const kQuranDataBase = 'https://bustan-alquran.com/quran-data';

class Ayah {
  const Ayah({required this.number, required this.text, required this.juz, required this.page, this.sajda = false, this.sajdaObligatory = false});
  final int number;
  final String text;
  final int juz;

  /// Page of the Madinah mushaf (1-604).
  final int page;
  final bool sajda;
  final bool sajdaObligatory;
}

class SurahAudio {
  const SurahAudio(this.reciter, this.rewaya, this.link);
  final String reciter;
  final String rewaya;
  final String link;
}

class SurahDetail {
  const SurahDetail({required this.number, required this.ayahs, this.place, this.audio = const []});
  final int number;
  final List<Ayah> ayahs;

  /// مكية / مدنية when known.
  final String? place;

  /// One MP3 for the whole surah per reciter (empty with the fallback text).
  final List<SurahAudio> audio;
}

class MushafPage {
  MushafPage(this.page, this.juz, this.ayahs);
  final int page;
  final int juz;
  final List<Ayah> ayahs;
}

/// A reciter with one file per ayah.
class AyahReciter {
  const AyahReciter({required this.id, required this.name, this.style = '', required this.base});
  final String id;
  final String name;
  final String style;
  final String base;

  String get label => style.isEmpty ? name : '$name ($style)';

  String ayahUrl(int surah, int ayah) =>
      '${base.endsWith('/') ? base : '$base/'}${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';
}

enum SyncMode { none, ayah, word }

/// Per spoken word: [firstWord, afterLastWord, fromMs, toMs], relative to the ayah's file.
typedef Segments = List<List<int>>;

const kArabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
String arabicNumber(int n) => n.toString().split('').map((d) => kArabicDigits[int.parse(d)]).join();

final _basmalaStart = RegExp(r'^بِسْمِ\s+\S*ٱللَّهِ\s+\S*ٱلرَّحْمَٰنِ\s+\S*ٱلرَّحِيمِ\s*');

/// Some sources glue the basmala onto ayah 1 (not al-Fatiha, where it is the ayah, nor at-Tawba): it is shown apart.
String stripBasmala(int surah, int n, String text) {
  if (n != 1 || surah == 1 || surah == 9) return text;
  if (_basmalaStart.hasMatch(text)) return text.replaceFirst(_basmalaStart, '');
  final words = text.split(' ');
  final first = words.first.replaceAll(RegExp(r'[^ء-ي]'), '');
  return first == 'بسم' && words.length > 4 ? words.sublist(4).join(' ') : text;
}

/// Ayahs grouped by Madinah page: a new page whenever the number changes.
List<MushafPage> toPages(List<Ayah> ayahs) {
  final pages = <MushafPage>[];
  for (final a in ayahs) {
    if (pages.isNotEmpty && pages.last.page == a.page) {
      pages.last.ayahs.add(a);
    } else {
      pages.add(MushafPage(a.page, a.juz, [a]));
    }
  }
  return pages;
}

/// Words of an ayah as (start, end) character ranges - the text itself is never rewritten.
List<(int, int)> wordRanges(String text) => [for (final m in RegExp(r'\S+').allMatches(text)) (m.start, m.end)];

/// The word being recited at [ms] into the ayah's file: the last segment that has
/// started (between words the previous one stays lit), -1 before the first.
int wordIndexAt(Segments? segments, int ms) {
  if (segments == null || segments.isEmpty) return -1;
  var found = -1;
  for (var i = 0; i < segments.length; i++) {
    if (segments[i][2] <= ms) {
      found = i;
    } else {
      break;
    }
  }
  return found;
}

/// Word sync is only trusted when the text and the timings agree on the number
/// of words; otherwise that ayah follows at ayah level instead of lighting the
/// wrong word (a stray space inside a word in the source text, for example).
bool timingsFit(String text, Segments? segments) => segments != null && segments.isNotEmpty && segments.length == wordRanges(text).length;

/// Arabic letters with the hamza forms folded, so "الاعراف" finds "الأعراف".
String normalizeArabic(String s) => s
    .replaceAll(RegExp(r'[ً-ٰٟۖ-ۭ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .trim();

String _ar(Object? v) => v is String ? v : (v is Map ? (v['ar'] as String? ?? '') : '');

/// Our own file (eqraa format).
SurahDetail parseSurahFile(int surah, Map<String, dynamic> raw) {
  final ayahs = <Ayah>[
    for (final v in (raw['verses'] as List? ?? const []))
      Ayah(
        number: (v['number'] as num).toInt(),
        text: stripBasmala(surah, (v['number'] as num).toInt(), _ar(v['text']).trim()),
        juz: (v['juz'] as num).toInt(),
        page: (v['page'] as num).toInt(),
        sajda: v['sajda'] is Map || v['sajda'] == true,
        sajdaObligatory: v['sajda'] is Map && v['sajda']['obligatory'] == true,
      ),
  ];
  final place = _ar(raw['revelation_place']);
  return SurahDetail(
    number: surah,
    ayahs: ayahs,
    place: place.isEmpty ? null : place,
    audio: [
      for (final a in (raw['audio'] as List? ?? const []))
        if (a['link'] is String) SurahAudio(_ar(a['reciter']), _ar(a['rewaya']), a['link'] as String),
    ],
  );
}

/// api.alquran.cloud (Tanzil) - used until our files are uploaded.
SurahDetail? parseAlquranCloud(int surah, Map<String, dynamic> json) {
  final data = json['data'] as Map<String, dynamic>?;
  final list = data?['ayahs'] as List?;
  if (list == null || list.isEmpty) return null;
  final type = data?['revelationType'];
  return SurahDetail(
    number: surah,
    ayahs: [
      for (final a in list)
        Ayah(
          number: (a['numberInSurah'] as num).toInt(),
          text: stripBasmala(surah, (a['numberInSurah'] as num).toInt(), (a['text'] as String).trim()),
          juz: (a['juz'] as num).toInt(),
          page: (a['page'] as num).toInt(),
          sajda: a['sajda'] is Map || a['sajda'] == true,
          sajdaObligatory: a['sajda'] is Map && a['sajda']['obligatory'] == true,
        ),
    ],
    place: type == 'Meccan' ? 'مكية' : (type == 'Medinan' ? 'مدنية' : null),
  );
}

List<AyahReciter> parseReciters(Object? raw) {
  final list = raw is Map ? raw['reciters'] : raw;
  if (list is! List) return const [];
  return [
    for (final r in list)
      if (r is Map && r['id'] != null && r['base'] is String && (r['base'] as String).startsWith('https://'))
        AyahReciter(id: '${r['id']}', name: (r['name_ar'] ?? '${r['id']}') as String, style: (r['style_ar'] ?? '') as String, base: r['base'] as String),
  ];
}

/// Built in, so ayah sync works before audio/reciters.json is uploaded (everyayah.com, one MP3 per ayah).
final kBuiltinReciters = <AyahReciter>[
  for (final r in const [
    ['Alafasy_128kbps', 'مشاري العفاسي', 'مرتل'],
    ['Abdul_Basit_Murattal_192kbps', 'عبد الباسط عبد الصمد', 'مرتل'],
    ['Abdul_Basit_Mujawwad_128kbps', 'عبد الباسط عبد الصمد', 'مجوّد'],
    ['Husary_128kbps', 'محمود خليل الحصري', 'مرتل'],
    ['Minshawy_Murattal_128kbps', 'محمد صديق المنشاوي', 'مرتل'],
    ['Abdurrahmaan_As-Sudais_192kbps', 'عبد الرحمن السديس', 'مرتل'],
    ['Saood_ash-Shuraym_128kbps', 'سعود الشريم', 'مرتل'],
    ['MaherAlMuaiqly128kbps', 'ماهر المعيقلي', 'مرتل'],
    ['Hudhaify_128kbps', 'علي الحذيفي', 'مرتل'],
    ['Ghamadi_40kbps', 'سعد الغامدي', 'مرتل'],
    ['Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net', 'أحمد العجمي', 'مرتل'],
    ['Muhammad_Ayyoub_128kbps', 'محمد أيوب', 'مرتل'],
    ['Abu_Bakr_Ash-Shaatree_128kbps', 'أبو بكر الشاطري', 'مرتل'],
    ['Nasser_Alqatami_128kbps', 'ناصر القطامي', 'مرتل'],
    ['Yasser_Ad-Dussary_128kbps', 'ياسر الدوسري', 'مرتل'],
  ])
    AyahReciter(id: r[0], name: r[1], style: r[2], base: 'https://everyayah.com/data/${r[0]}/'),
];

/// The reciters a center offers (its `quran_reciters` setting, comma separated;
/// empty = all) with its default first.
List<AyahReciter> centerReciters(List<AyahReciter> all, String configured, String defaultId) {
  final allowed = configured.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  final list = all.where((r) => allowed.isEmpty || allowed.contains(r.id)).toList();
  final result = list.isEmpty ? [...all] : list;
  final i = result.indexWhere((r) => r.id == defaultId);
  if (i > 0) result.insert(0, result.removeAt(i));
  return result;
}

/// Downloads with an on-device copy: the copy is used when there is no
/// connection (or the file is missing upstream), and refreshed when online.
class _Store {
  static Future<File> _file(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/mushaf/$key');
    await file.parent.create(recursive: true);
    return file;
  }

  /// The body of [url] (or null when it does not exist there). Throws on no connection.
  static Future<String?> _download(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final response = await (await client.getUrl(Uri.parse(url))).close().timeout(const Duration(seconds: 40));
      if (response.statusCode == 404 || response.statusCode == 400) {
        await response.drain<void>();
        return null;
      }
      if (response.statusCode != 200) throw HttpException('status ${response.statusCode}');
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  /// Copy first when [preferCopy] (text never changes), else network first.
  static Future<String?> get(String key, String url, {bool preferCopy = true}) async {
    final file = await _file(key);
    if (preferCopy && await file.exists()) return file.readAsString();
    try {
      final body = await _download(url);
      if (body != null) await file.writeAsString(body);
      return body ?? (await file.exists() ? await file.readAsString() : null);
    } catch (_) {
      if (await file.exists()) return file.readAsString();
      rethrow;
    }
  }
}

/// Text of a surah: our own file, else the public API; kept on the device.
class QuranTextService {
  static final _memory = <int, SurahDetail>{};

  Future<SurahDetail> surah(int number) async {
    final hit = _memory[number];
    if (hit != null) return hit;
    SurahDetail? detail;
    Object? lastError;
    try {
      final body = await _Store.get('surah_$number.json', '$kQuranDataBase/surah_$number.json');
      if (body != null) detail = parseSurahFile(number, jsonDecode(body) as Map<String, dynamic>);
    } catch (e) {
      lastError = e;
    }
    if (detail == null || detail.ayahs.isEmpty) {
      try {
        final body = await _Store.get('fallback_$number.json', 'https://api.alquran.cloud/v1/surah/$number/quran-uthmani');
        if (body != null) detail = parseAlquranCloud(number, jsonDecode(body) as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
      }
    }
    if (detail == null || detail.ayahs.isEmpty) throw lastError ?? const HttpException('no text');
    return _memory[number] = detail;
  }
}

/// The ayah-by-ayah reciters (uploaded list, else built in) and their word timings.
class QuranAudioData {
  QuranAudioData._();
  static final instance = QuranAudioData._();

  List<AyahReciter> _reciters = kBuiltinReciters;
  bool _loaded = false;
  final _timings = <String, Map<String, Segments>?>{};

  /// The last known list (the built-in one until [reciters] has loaded once).
  List<AyahReciter> get current => _reciters;

  Future<List<AyahReciter>> reciters() async {
    if (_loaded) return _reciters;
    try {
      final body = await _Store.get('reciters.json', '$kQuranDataBase/audio/reciters.json', preferCopy: false);
      final list = body == null ? const <AyahReciter>[] : parseReciters(jsonDecode(body));
      if (list.isNotEmpty) _reciters = list;
      _loaded = true;
    } catch (_) {
      // offline and never downloaded: the built-in list
    }
    return _reciters;
  }

  /// Word timings of one surah for one reciter, or null when there are none.
  Future<Map<String, Segments>?> timings(String reciterId, int surah) async {
    final key = '$reciterId/$surah';
    if (_timings.containsKey(key)) return _timings[key];
    Map<String, Segments>? result;
    try {
      final body = await _Store.get('timings/${Uri.encodeComponent(reciterId)}/surah_$surah.json',
          '$kQuranDataBase/audio/timings/${Uri.encodeComponent(reciterId)}/surah_$surah.json');
      if (body != null) {
        final raw = jsonDecode(body) as Map<String, dynamic>;
        result = {
          for (final e in raw.entries) e.key: [for (final s in e.value as List) (s as List).map((x) => (x as num).toInt()).toList()],
        };
      }
      _timings[key] = result;
    } catch (_) {
      return null; // offline: try again next time
    }
    return result;
  }
}

class ReadingState {
  const ReadingState({required this.reciters, required this.defaultReciter, required this.bookmarks, this.surah, this.ayah});
  final int? surah;
  final int? ayah;
  final String reciters;
  final String defaultReciter;
  final List<({String id, int surah, int ayah, String? note})> bookmarks;
}

/// Reading position, bookmarks and the center's reciter settings.
class QuranRepository {
  QuranRepository(this._client);

  final SupabaseClient _client;

  Future<ReadingState> state(String orgId) async {
    final j = (await SyncService.instance.raw('quran.state:$orgId', () => _client.rpc('get_reading_state', params: {'p_org': orgId}))) as Map<String, dynamic>;
    final pos = j['position'] as Map<String, dynamic>?;
    return ReadingState(
      surah: (pos?['surah'] as num?)?.toInt(),
      ayah: (pos?['ayah'] as num?)?.toInt(),
      reciters: (j['reciters'] as String?) ?? '',
      defaultReciter: (j['default_reciter'] as String?) ?? '',
      bookmarks: [
        for (final b in (j['bookmarks'] as List))
          (id: b['id'] as String, surah: (b['surah'] as num).toInt(), ayah: (b['ayah'] as num).toInt(), note: b['note'] as String?),
      ],
    );
  }

  Future<void> savePosition(String orgId, int surah, int ayah) =>
      _client.rpc('save_reading_position', params: {'p_org': orgId, 'p_surah': surah, 'p_ayah': ayah});

  /// Returns whether the bookmark exists after the call.
  Future<bool> toggleBookmark(String orgId, int surah, int ayah) async =>
      await _client.rpc('toggle_bookmark', params: {'p_org': orgId, 'p_surah': surah, 'p_ayah': ayah, 'p_note': null}) as bool;
}
