import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/quran_data.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'quran_data.dart';

bool _isStaff(TenantController t) => t.active?.role == OrgRole.admin || t.active?.role == OrgRole.teacher;

// ---------------------------------------------------------------------------
// Surah index + continue reading + bookmarks
// ---------------------------------------------------------------------------

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _repository = QuranRepository(AppSupabase.client);
  Future<ReadingState>? _future;
  String? _orgId;
  String _query = '';
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _repository.state(orgId);
    }
    final surahs = [
      for (var i = 1; i <= 114; i++)
        if (_query.isEmpty || surahName(i).contains(_query) || '$i' == _query) i,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('المصحف')),
      drawer: _isStaff(tenant) ? const AppDrawer() : null,
      body: _future == null
          ? const SizedBox.shrink()
          : FutureBuilder<ReadingState>(
              future: _future,
              builder: (context, snap) {
                final state = snap.data;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SegmentedButton<int>(
                      segments: const [ButtonSegment(value: 0, label: Text('السور')), ButtonSegment(value: 1, label: Text('العلامات'))],
                      selected: {_tab},
                      onSelectionChanged: (s) => setState(() => _tab = s.first),
                    ),
                  ),
                  if (_tab == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: TextField(onChanged: (v) => setState(() => _query = v.trim()), decoration: const InputDecoration(hintText: 'ابحث باسم السورة أو رقمها', prefixIcon: Icon(Icons.search_rounded))),
                    ),
                  Expanded(
                    child: _tab == 1
                        ? _bookmarks(state)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                            children: [
                              if (state?.surah != null && _query.isEmpty)
                                Card(
                                  color: Theme.of(context).colorScheme.primary,
                                  child: ListTile(
                                    onTap: () async {
                                      await context.push('/quran/${state.surah}?ayah=${state.ayah}');
                                      if (mounted) setState(() => _future = _repository.state(_orgId!));
                                    },
                                    leading: const Icon(Icons.auto_stories_rounded, color: Colors.white),
                                    title: const Text('أكمل القراءة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                    subtitle: Text('سورة ${surahName(state!.surah!)} — الآية ${state.ayah}', style: const TextStyle(color: Colors.white70)),
                                    trailing: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                                  ),
                                ),
                              for (final n in surahs)
                                ListTile(
                                  onTap: () async {
                                    await context.push('/quran/$n');
                                    if (mounted) setState(() => _future = _repository.state(_orgId!));
                                  },
                                  leading: CircleAvatar(radius: 18, child: Text(arabicNumber(n), style: const TextStyle(fontSize: 12))),
                                  title: Text('سورة ${surahName(n)}', style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20)),
                                  subtitle: Text('${ayahCount(n)} آية'),
                                ),
                              const Padding(padding: EdgeInsets.all(16), child: Text(kQuranTextCredit, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11))),
                            ],
                          ),
                  ),
                ]);
              },
            ),
    );
  }

  Widget _bookmarks(ReadingState? state) {
    final list = state?.bookmarks ?? const [];
    if (list.isEmpty) return const EmptyState(icon: Icons.bookmark_border_rounded, title: 'لا توجد علامات', subtitle: 'اضغط على آية في المصحف لإضافة علامة');
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final b in list)
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_rounded),
            title: Text('سورة ${surahName(b.surah)} — الآية ${b.ayah}'),
            onTap: () async {
              await context.push('/quran/${b.surah}?ayah=${b.ayah}');
              if (mounted) setState(() => _future = _repository.state(_orgId!));
            },
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// The reader with audio
// ---------------------------------------------------------------------------

class SurahReaderScreen extends StatefulWidget {
  const SurahReaderScreen({super.key, required this.surah, this.startAyah});

  final int surah;
  final int? startAyah;

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final _text = QuranTextService();
  final _repository = QuranRepository(AppSupabase.client);
  final _player = AudioPlayer();
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};

  List<QuranAyah> _ayahs = [];
  List<Reciter> _reciters = kReciters;
  Reciter _reciter = kReciters.first;
  Set<String> _bookmarked = {};
  bool _loading = true;
  Object? _error;
  int? _current; // the ayah being recited (or last tapped)
  bool _playing = false;
  int _repeat = 1;
  int _repeatDone = 0;
  double _scale = 1.0;
  StreamSubscription<PlayerState>? _sub;
  Timer? _saveTimer;

  // Cached: dispose() runs when the context can no longer be read.
  late final String _orgId = context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _current = widget.startAyah;
    _sub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) _onCompleted();
      if (mounted) setState(() => _playing = s.playing && s.processingState != ProcessingState.completed);
    });
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _saveTimer?.cancel();
    if (_current != null) _repository.savePosition(_orgId, widget.surah, _current!).catchError((_) {});
    _player.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait<dynamic>([_text.surah(widget.surah), _repository.state(_orgId).catchError((_) => const ReadingState(reciters: '', defaultReciter: '', bookmarks: []))]);
      final ayahs = results[0] as List<QuranAyah>;
      final state = results[1] as ReadingState;
      final reciters = centerReciters(state.reciters, state.defaultReciter);
      final savedId = prefs.getString('quran_reciter');
      final chosen = reciters.where((r) => r.id == savedId).firstOrNull ?? reciters.first;
      if (!mounted) return;
      setState(() {
        _ayahs = ayahs;
        _reciters = reciters;
        _reciter = chosen;
        _scale = prefs.getDouble('quran_scale') ?? 1.0;
        _bookmarked = {for (final b in state.bookmarks.where((b) => b.surah == widget.surah)) '${b.ayah}'};
        _loading = false;
      });
      if (widget.startAyah != null) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(widget.startAyah!));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _reveal(int ayah) {
    final ctx = _keys[ayah]?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.3);
  }

  void _touch(int ayah) {
    _current = ayah;
    // keep the "continue reading" position fresh without a request per ayah
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () => _repository.savePosition(_orgId, widget.surah, ayah).catchError((_) {}));
  }

  Future<void> _play(int ayah) async {
    setState(() {
      _repeatDone = 0;
    });
    _touch(ayah);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(ayah));
    try {
      await _player.setUrl(_reciter.ayahUrl(widget.surah, ayah));
      await _player.play();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر تشغيل التلاوة، تأكد من الإنترنت')));
    }
  }

  Future<void> _onCompleted() async {
    final n = _current;
    if (n == null) return;
    _repeatDone++;
    if (_repeatDone < _repeat) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (n < _ayahs.length) {
      await _play(n + 1);
    } else {
      await _player.stop();
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else if (_player.processingState == ProcessingState.idle || _player.processingState == ProcessingState.completed) {
      await _play(_current ?? 1);
    } else {
      await _player.play();
    }
  }

  Future<void> _ayahSheet(QuranAyah a) async {
    final marked = _bookmarked.contains('${a.number}');
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${surahName(widget.surah)} — الآية ${a.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ListTile(
            leading: const Icon(Icons.play_arrow_rounded),
            title: const Text('تشغيل من هنا'),
            onTap: () {
              Navigator.pop(context);
              _play(a.number);
            },
          ),
          ListTile(
            leading: Icon(marked ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined),
            title: Text(marked ? 'إزالة العلامة' : 'إضافة علامة'),
            onTap: () async {
              Navigator.pop(context);
              try {
                final now = await _repository.toggleBookmark(_orgId, widget.surah, a.number);
                if (mounted) setState(() => now ? _bookmarked.add('${a.number}') : _bookmarked.remove('${a.number}'));
              } catch (_) {}
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('نسخ الآية'),
            onTap: () async {
              Navigator.pop(context);
              await Clipboard.setData(ClipboardData(text: '${a.text} ﴿${arabicNumber(a.number)}﴾ [${surahName(widget.surah)}]'));
              if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _pickReciter() async {
    final picked = await showModalBottomSheet<Reciter>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final r in _reciters)
            ListTile(
              title: Text(r.name),
              trailing: r.id == _reciter.id ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(context, r),
            ),
        ]),
      ),
    );
    if (picked == null) return;
    (await SharedPreferences.getInstance()).setString('quran_reciter', picked.id);
    setState(() => _reciter = picked);
    if (_playing && _current != null) await _play(_current!);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${surahName(widget.surah)}', style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 22)),
        actions: [
          IconButton(
            tooltip: 'تصغير الخط',
            icon: const Icon(Icons.text_decrease_rounded),
            onPressed: () async {
              setState(() => _scale = (_scale - 0.1).clamp(0.8, 1.8));
              (await SharedPreferences.getInstance()).setDouble('quran_scale', _scale);
            },
          ),
          IconButton(
            tooltip: 'تكبير الخط',
            icon: const Icon(Icons.text_increase_rounded),
            onPressed: () async {
              setState(() => _scale = (_scale + 0.1).clamp(0.8, 1.8));
              (await SharedPreferences.getInstance()).setDouble('quran_scale', _scale);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: 'تعذّر تحميل السورة، تأكد من الإنترنت', onRetry: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                })
              : Column(children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (widget.surah != 1 && widget.surah != 9)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 26 * _scale)),
                          ),
                        for (final a in _ayahs)
                          InkWell(
                            key: _keys.putIfAbsent(a.number, GlobalKey.new),
                            onTap: () => _ayahSheet(a),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: _current == a.number ? scheme.primary.withValues(alpha: _playing ? 0.16 : 0.08) : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: a.text),
                                  TextSpan(text: ' ﴿${arabicNumber(a.number)}﴾ ', style: TextStyle(color: scheme.primary, fontSize: 20 * _scale)),
                                  if (a.sajda) const TextSpan(text: '۩ '),
                                  if (_bookmarked.contains('${a.number}')) TextSpan(text: '🔖', style: TextStyle(fontSize: 14 * _scale)),
                                ]),
                                textAlign: TextAlign.justify,
                                style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 26 * _scale, height: 2.0),
                              ),
                            ),
                          ),
                        const Padding(padding: EdgeInsets.only(top: 16), child: Text(kQuranTextCredit, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11))),
                      ]),
                    ),
                  ),
                  Material(
                    elevation: 8,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Row(children: [
                            Expanded(
                              child: TextButton.icon(onPressed: _pickReciter, icon: const Icon(Icons.record_voice_over_rounded, size: 18), label: Text(_reciter.name, overflow: TextOverflow.ellipsis)),
                            ),
                            PopupMenuButton<int>(
                              tooltip: 'تكرار الآية',
                              initialValue: _repeat,
                              onSelected: (v) => setState(() => _repeat = v),
                              itemBuilder: (context) => [for (final n in const [1, 2, 3, 5, 10]) PopupMenuItem(value: n, child: Text(n == 1 ? 'بلا تكرار' : 'تكرار الآية $n مرات'))],
                              child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [const Icon(Icons.repeat_rounded, size: 18), const SizedBox(width: 4), Text('×$_repeat')])),
                            ),
                          ]),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            IconButton(onPressed: (_current ?? 1) > 1 ? () => _play((_current ?? 1) - 1) : null, icon: const Icon(Icons.skip_next_rounded), tooltip: 'الآية السابقة'),
                            const SizedBox(width: 8),
                            IconButton.filled(iconSize: 32, onPressed: _togglePlay, icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                            const SizedBox(width: 8),
                            IconButton(onPressed: (_current ?? 0) < _ayahs.length ? () => _play((_current ?? 0) + 1) : null, icon: const Icon(Icons.skip_previous_rounded), tooltip: 'الآية التالية'),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                ]),
    );
  }
}
