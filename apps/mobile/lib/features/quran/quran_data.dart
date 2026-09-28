import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where the text and recitations come from (both are public sources; nothing
/// of either is stored in our database or shipped in the app):
///   * text  - api.alquran.cloud, Uthmani script from the Tanzil project
///             (tanzil.net, used unmodified with attribution);
///   * audio - everyayah.com, one MP3 per ayah.
/// Credit is shown in the reader. The audio base URL lives in [Reciter.ayahUrl]
/// so it can be swapped in one place.

class Reciter {
  const Reciter(this.id, this.name);

  /// The folder on the audio host, which is also the id stored in center settings.
  final String id;
  final String name;

  String ayahUrl(int surah, int ayah) =>
      'https://everyayah.com/data/$id/${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';
}

const kReciters = <Reciter>[
  Reciter('Alafasy_128kbps', 'مشاري العفاسي'),
  Reciter('Abdul_Basit_Murattal_192kbps', 'عبد الباسط عبد الصمد (مرتل)'),
  Reciter('Abdul_Basit_Mujawwad_128kbps', 'عبد الباسط عبد الصمد (مجوّد)'),
  Reciter('Husary_128kbps', 'محمود خليل الحصري'),
  Reciter('Minshawy_Murattal_128kbps', 'محمد صديق المنشاوي (مرتل)'),
  Reciter('Abdurrahmaan_As-Sudais_192kbps', 'عبد الرحمن السديس'),
  Reciter('Saood_ash-Shuraym_128kbps', 'سعود الشريم'),
  Reciter('MaherAlMuaiqly128kbps', 'ماهر المعيقلي'),
  Reciter('Hudhaify_128kbps', 'علي الحذيفي'),
  Reciter('Ghamadi_40kbps', 'سعد الغامدي'),
  Reciter('Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net', 'أحمد العجمي'),
  Reciter('Muhammad_Ayyoub_128kbps', 'محمد أيوب'),
  Reciter('Abu_Bakr_Ash-Shaatree_128kbps', 'أبو بكر الشاطري'),
  Reciter('Nasser_Alqatami_128kbps', 'ناصر القطامي'),
  Reciter('Yasser_Ad-Dussary_128kbps', 'ياسر الدوسري'),
];

/// The reciters a center offers (its `quran_reciters` setting, comma separated;
/// empty = all) with its default first.
List<Reciter> centerReciters(String configured, String defaultId) {
  final allowed = configured.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  final list = kReciters.where((r) => allowed.isEmpty || allowed.contains(r.id)).toList();
  final result = list.isEmpty ? [...kReciters] : list;
  final i = result.indexWhere((r) => r.id == defaultId);
  if (i > 0) result.insert(0, result.removeAt(i));
  return result;
}

class QuranAyah {
  const QuranAyah({required this.number, required this.text, required this.juz, required this.page, required this.sajda});
  final int number;
  final String text;
  final int juz;
  final int page;
  final bool sajda;
}

const kArabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
String arabicNumber(int n) => n.toString().split('').map((d) => kArabicDigits[int.parse(d)]).join();

/// Text of a surah, cached on the device after the first download so it reads offline.
class QuranTextService {
  static final _memory = <int, List<QuranAyah>>{};

  Future<File> _cacheFile(int surah) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/quran');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}/$surah.json');
  }

  Future<List<QuranAyah>> surah(int number) async {
    final cached = _memory[number];
    if (cached != null) return cached;

    final file = await _cacheFile(number);
    String body;
    if (await file.exists()) {
      body = await file.readAsString();
    } else {
      body = await _download(number);
      await file.writeAsString(body);
    }
    final ayahs = _parse(body, number);
    _memory[number] = ayahs;
    return ayahs;
  }

  Future<String> _download(int number) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(Uri.parse('https://api.alquran.cloud/v1/surah/$number/quran-uthmani'));
      final response = await request.close().timeout(const Duration(seconds: 40));
      if (response.statusCode != 200) throw const HttpException('bad status');
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  List<QuranAyah> _parse(String body, int surah) {
    final data = (jsonDecode(body) as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final out = <QuranAyah>[];
    for (final a in data['ayahs'] as List) {
      var text = (a['text'] as String).trim();
      final n = (a['numberInSurah'] as num).toInt();
      // The source glues the basmala onto ayah 1 of every surah except al-Fatiha
      // (where it IS the first ayah) and at-Tawba (which has none): show it apart.
      if (n == 1 && surah != 1 && surah != 9) {
        final words = text.split(' ');
        if (words.length > 4) text = words.sublist(4).join(' ');
      }
      out.add(QuranAyah(number: n, text: text, juz: (a['juz'] as num).toInt(), page: (a['page'] as num).toInt(), sajda: a['sajda'] == true));
    }
    return out;
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
    final j = await _client.rpc('get_reading_state', params: {'p_org': orgId}) as Map<String, dynamic>;
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
