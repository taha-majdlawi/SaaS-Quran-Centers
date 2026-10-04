import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/i18n/i18n.dart';

import '../../core/data/quran_data.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'mushaf_page_view.dart';
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
        // hamza forms folded: "الاعراف" finds "الأعراف"
        if (_query.isEmpty || normalizeArabic(surahNameArabic(i)).contains(normalizeArabic(_query)) || surahName(i).toLowerCase().contains(_query.toLowerCase()) || '$i' == _query) i,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: DrawerLeading(),title: Text(tr(context).quran.title)),
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
                      segments: [ButtonSegment(value: 0, label: Text(tr(context).quran.surahs)), ButtonSegment(value: 1, label: Text(tr(context).quran.bookmarks))],
                      selected: {_tab},
                      onSelectionChanged: (s) => setState(() => _tab = s.first),
                    ),
                  ),
                  if (_tab == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: TextField(onChanged: (v) => setState(() => _query = v.trim()), decoration: InputDecoration(hintText: tr(context).quran.search, prefixIcon: Icon(Icons.search_rounded))),
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
                                    title: Text(tr(context).quran.continueReading, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                    subtitle: Text(fmt(tr(context).quran.position, {'surah': surahName(state!.surah!), 'ayah': state.ayah}), style: const TextStyle(color: Colors.white70)),
                                    trailing: Icon(forwardChevron(context), color: Colors.white),
                                  ),
                                ),
                              for (final n in surahs)
                                ListTile(
                                  onTap: () async {
                                    await context.push('/quran/$n');
                                    if (mounted) setState(() => _future = _repository.state(_orgId!));
                                  },
                                  leading: CircleAvatar(radius: 18, child: Text(arabicNumber(n), style: const TextStyle(fontSize: 12))),
                                  title: Text('سورة ${surahNameArabic(n)}', style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20)),
                                  subtitle: Text('${tr(context).isAr ? '' : '${kSurahNamesLatin[n - 1]}  ·  '}${fmt(tr(context).quran.ayahs, {'n': ayahCount(n)})}'),
                                ),
                              Padding(padding: const EdgeInsets.all(16), child: Text(tr(context).quran.credit, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11))),
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
    if (list.isEmpty) return EmptyState(icon: Icons.bookmark_border_rounded, title: tr(context).quran.noBookmarks, subtitle: tr(context).quran.noBookmarksHint);
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final b in list)
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_rounded),
            title: Text(fmt(tr(context).quran.position, {'surah': surahName(b.surah), 'ayah': b.ayah})),
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
// The mushaf: Madinah pages, three ways of listening, self-test
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
  PageController? _pages;

  SurahDetail? _detail;
  List<MushafPage> _pageList = [];
  int _pageIdx = 0;
  bool _loading = true;
  Object? _error;

  List<AyahReciter> _reciters = kBuiltinReciters;
  AyahReciter _reciter = kBuiltinReciters.first;
  int _surahAudio = 0;
  SyncMode _mode = SyncMode.ayah;
  int _size = 1;
  int _repeat = 1;

  bool _playing = false;
  int? _current; // the ayah being followed
  int _word = -1;
  List<int> _queue = []; // playlist index -> ayah
  Map<String, Segments>? _timings;
  bool _timingsMissing = false;

  bool _testMode = false;
  final Set<int> _revealed = {};
  Set<int> _bookmarked = {};

  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _saveTimer;

  // Cached: dispose() runs when the context can no longer be read.
  late final String _orgId = context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _subs.add(_player.playerStateStream.listen((s) {
      final done = s.processingState == ProcessingState.completed;
      if (done && _testMode && _current != null) _revealed.add(_current!);
      if (mounted) setState(() => _playing = s.playing && !done);
    }));
    _subs.add(_player.currentIndexStream.listen((i) {
      if (i == null || _mode == SyncMode.none || i >= _queue.length) return;
      final n = _queue[i];
      if (n == _current) return;
      setState(() {
        _current = n;
        _word = -1;
        _uncover();
      });
      _follow(n);
      _touch(n);
    }));
    _subs.add(_player.positionStream.listen((p) {
      if (_mode != SyncMode.word || _current == null || !_fits(_current!)) return;
      final w = wordIndexAt(_timings?['$_current'], p.inMilliseconds);
      if (w != _word && mounted) {
        setState(() {
          _word = w;
          _uncover();
        });
      }
    }));
    _load();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _saveTimer?.cancel();
    final n = _current ?? (_pageList.isEmpty ? null : _pageList[_pageIdx].ayahs.first.number);
    if (n != null) _repository.savePosition(_orgId, widget.surah, n).catchError((_) {});
    _player.dispose();
    _pages?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait<dynamic>([
        _text.surah(widget.surah),
        _repository.state(_orgId).catchError((_) => const ReadingState(reciters: '', defaultReciter: '', bookmarks: [])),
        QuranAudioData.instance.reciters(),
      ]);
      final detail = results[0] as SurahDetail;
      final state = results[1] as ReadingState;
      final reciters = centerReciters(results[2] as List<AyahReciter>, state.reciters, state.defaultReciter);
      final saved = prefs.getString('quran_reciter');
      final pages = toPages(detail.ayahs);
      final start = widget.startAyah == null ? null : detail.ayahs.where((a) => a.number == widget.startAyah).firstOrNull;
      final startPage = start == null ? 0 : pages.indexWhere((p) => p.page == start.page).clamp(0, pages.length - 1);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _pageList = pages;
        _pageIdx = startPage;
        _pages = PageController(initialPage: startPage);
        _reciters = reciters;
        _reciter = reciters.where((r) => r.id == saved).firstOrNull ?? reciters.first;
        _mode = SyncMode.values.where((m) => m.name == prefs.getString('quran_sync')).firstOrNull ?? SyncMode.ayah;
        _size = (prefs.getInt('quran_size') ?? 1).clamp(0, 2);
        _current = start?.number;
        _bookmarked = {for (final b in state.bookmarks.where((b) => b.surah == widget.surah)) b.ayah};
        _loading = false;
      });
      _loadTimings();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadTimings() async {
    setState(() {
      _timings = null;
      _timingsMissing = false;
    });
    if (_mode != SyncMode.word) return;
    final id = _reciter.id;
    final t = await QuranAudioData.instance.timings(id, widget.surah);
    if (!mounted || id != _reciter.id) return;
    setState(() {
      _timings = t;
      _timingsMissing = t == null;
    });
  }

  String _textOf(int n) => _detail?.ayahs.where((a) => a.number == n).firstOrNull?.text ?? '';
  bool _fits(int n) => _mode == SyncMode.word && timingsFit(_textOf(n), _timings?['$n']);
  bool _isRevealed(int n) => !_testMode || _revealed.contains(n);

  /// Self-test: what the recitation has reached is uncovered (ayah by ayah, or word by word).
  void _uncover() {
    final n = _current;
    if (!_testMode || n == null || _mode == SyncMode.none) return;
    for (var i = 1; i < n; i++) {
      _revealed.add(i);
    }
    final segs = _timings?['$n'];
    if (!_fits(n) || (segs != null && _word >= segs.length - 1)) _revealed.add(n);
  }

  /// The page follows the recitation.
  void _follow(int ayah) {
    final a = _detail?.ayahs.where((x) => x.number == ayah).firstOrNull;
    if (a == null) return;
    final i = _pageList.indexWhere((p) => p.page == a.page);
    if (i >= 0 && i != _pageIdx && _pages?.hasClients == true) {
      _pages!.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  /// Keeps "continue reading" fresh without a request per ayah.
  void _touch(int ayah) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () => _repository.savePosition(_orgId, widget.surah, ayah).catchError((_) {}));
  }

  Future<void> _start(int ayah) async {
    final detail = _detail;
    if (detail == null) return;
    try {
      if (_mode == SyncMode.none) {
        if (detail.audio.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).quran.noSurahAudio)));
          return;
        }
        await _player.setUrl(detail.audio[_surahAudio.clamp(0, detail.audio.length - 1)].link);
      } else {
        // one file per ayah, each repeated as asked: the playlist index says which ayah is being recited
        final sources = <AudioSource>[];
        final queue = <int>[];
        for (var n = ayah; n <= detail.ayahs.length; n++) {
          for (var r = 0; r < _repeat; r++) {
            sources.add(AudioSource.uri(Uri.parse(_reciter.ayahUrl(widget.surah, n))));
            queue.add(n);
          }
        }
        _queue = queue;
        setState(() {
          _current = ayah;
          _word = -1;
          _uncover();
        });
        _follow(ayah);
        await _player.setAudioSources(sources, initialIndex: 0);
      }
      unawaited(_player.play());
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentStrings.quran.playFailed)));
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) return _player.pause();
    final idle = _player.processingState == ProcessingState.idle || _player.processingState == ProcessingState.completed;
    if (!idle) return _player.play();
    await _start(_current ?? _pageList[_pageIdx].ayahs.first.number);
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) {
      setState(() {
        _playing = false;
        _word = -1;
      });
    }
  }

  Future<void> _setMode(SyncMode m) async {
    await _stop();
    setState(() => _mode = m);
    (await SharedPreferences.getInstance()).setString('quran_sync', m.name);
    _loadTimings();
  }

  Future<void> _setSize(int i) async {
    setState(() => _size = i);
    (await SharedPreferences.getInstance()).setInt('quran_size', i);
  }

  void _onPageChanged(int i) {
    setState(() => _pageIdx = i);
    if (!_playing) _touch(_pageList[i].ayahs.first.number);
  }

  Future<void> _ayahSheet(int n) async {
    final marked = _bookmarked.contains(n);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(fmt(tr(context).quran.ayahOf, {'surah': surahName(widget.surah), 'ayah': n}), style: const TextStyle(fontWeight: FontWeight.w800)),
          if (_mode != SyncMode.none)
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: Text(tr(context).quran.playFromHere),
              onTap: () {
                Navigator.pop(context);
                _start(n);
              },
            ),
          ListTile(
            leading: Icon(marked ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined),
            title: Text(marked ? tr(context).quran.unmark : tr(context).quran.mark),
            onTap: () async {
              Navigator.pop(context);
              try {
                final now = await _repository.toggleBookmark(_orgId, widget.surah, n);
                if (mounted) setState(() => now ? _bookmarked.add(n) : _bookmarked.remove(n));
              } catch (_) {}
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: Text(tr(context).quran.copyAyah),
            onTap: () async {
              Navigator.pop(context);
              await Clipboard.setData(ClipboardData(text: '${_textOf(n)} ﴿${arabicNumber(n)}﴾ [${surahName(widget.surah)}]'));
              if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(currentStrings.quran.copied)));
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _pickReciter() async {
    final detail = _detail!;
    final none = _mode == SyncMode.none;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: ListView(shrinkWrap: true, children: [
            if (none)
              for (var i = 0; i < detail.audio.length; i++)
                ListTile(
                  title: Text(detail.audio[i].reciter),
                  subtitle: detail.audio[i].rewaya.isEmpty ? null : Text(detail.audio[i].rewaya),
                  trailing: i == _surahAudio ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(context, i),
                )
            else
              for (var i = 0; i < _reciters.length; i++)
                ListTile(
                  title: Text(_reciters[i].label),
                  trailing: _reciters[i].id == _reciter.id ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(context, i),
                ),
          ]),
        ),
      ),
    );
    if (picked == null) return;
    await _stop();
    if (none) {
      setState(() => _surahAudio = picked);
    } else {
      setState(() => _reciter = _reciters[picked]);
      (await SharedPreferences.getInstance()).setString('quran_reciter', _reciter.id);
      _loadTimings();
    }
  }

  Future<void> _settingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(tr(context).quran.fontSize, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [for (var i = 0; i < kMushafSizes.length; i++) ButtonSegment(value: i, label: Text('أ', style: TextStyle(fontSize: 13.0 + i * 3)))],
                selected: {_size},
                onSelectionChanged: (v) {
                  _setSize(v.first);
                  setSheet(() {});
                },
              ),
              const SizedBox(height: 16),
              Text(tr(context).quran.sync, style: const TextStyle(fontWeight: FontWeight.w800)),
              RadioGroup<SyncMode>(
                groupValue: _mode,
                onChanged: (m) {
                  if (m == null) return;
                  _setMode(m);
                  setSheet(() {});
                },
                child: Column(children: [
                  for (final m in SyncMode.values)
                    RadioListTile<SyncMode>(
                      contentPadding: EdgeInsets.zero,
                      value: m,
                      title: Text(switch (m) { SyncMode.none => tr(context).quran.syncNone, SyncMode.ayah => tr(context).quran.syncAyah, SyncMode.word => tr(context).quran.syncWord }),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).quran;
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${surahNameArabic(widget.surah)}', style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 22)),
        actions: [
          IconButton(
            tooltip: t.testMode,
            isSelected: _testMode,
            icon: const Icon(Icons.visibility_outlined),
            selectedIcon: const Icon(Icons.visibility_off_rounded),
            onPressed: () => setState(() {
              _testMode = !_testMode;
              _revealed.clear();
            }),
          ),
          IconButton(tooltip: t.readingSettings, icon: const Icon(Icons.tune_rounded), onPressed: detail == null ? null : _settingsSheet),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || detail == null
              ? ErrorState(message: t.loadFailed, onRetry: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                })
              : Column(children: [
                  if (_mode == SyncMode.word && _timingsMissing) _notice(t.noTimings, Colors.amber.shade50, Colors.brown),
                  if (_testMode) _notice(t.testHint, Theme.of(context).colorScheme.primary.withValues(alpha: 0.07), Theme.of(context).colorScheme.primary),
                  Expanded(
                    // right-to-left whatever the app language: the next page is on the left, like paper
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: _pageList.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, i) {
                          final page = _pageList[i];
                          return SingleChildScrollView(
                            child: MushafPageView(
                              page: page,
                              surahName: surahNameArabic(widget.surah),
                              isFirst: i == 0,
                              hasBasmala: widget.surah != 1 && widget.surah != 9,
                              place: detail.place,
                              ayahCount: detail.ayahs.length,
                              fontSize: kMushafSizes[_size],
                              current: _mode == SyncMode.none ? null : _current,
                              word: _word,
                              wordFits: _fits,
                              isRevealed: _isRevealed,
                              testMode: _testMode,
                              bookmarks: _bookmarked,
                              onAyahTap: (n) => _testMode ? setState(() => _revealed.contains(n) ? _revealed.remove(n) : _revealed.add(n)) : _ayahSheet(n),
                              onTogglePage: () => setState(() {
                                final all = page.ayahs.every((a) => _revealed.contains(a.number));
                                for (final a in page.ayahs) {
                                  all ? _revealed.remove(a.number) : _revealed.add(a.number);
                                }
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  _playerBar(detail),
                ]),
    );
  }

  Widget _notice(String text, Color background, Color color) => Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(text, style: TextStyle(color: color, fontSize: 13)),
      );

  Widget _playerBar(SurahDetail detail) {
    final t = tr(context).quran;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final followed = _mode != SyncMode.none;
    final reciterLabel = followed ? _reciter.label : (detail.audio.isEmpty ? t.noSurahAudio : detail.audio[_surahAudio.clamp(0, detail.audio.length - 1)].reciter);
    void turn(int delta) {
      final i = (_pageIdx + delta).clamp(0, _pageList.length - 1);
      if (i != _pageIdx) _pages?.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: followed || detail.audio.isNotEmpty ? _pickReciter : null,
                  icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                  label: Text(reciterLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
              if (followed)
                PopupMenuButton<int>(
                  tooltip: t.repeat,
                  initialValue: _repeat,
                  onSelected: (v) async {
                    final at = _current;
                    final wasPlaying = _playing;
                    setState(() => _repeat = v);
                    if (wasPlaying && at != null) await _start(at);
                  },
                  itemBuilder: (context) => [for (final n in [1, 2, 3, 5, 10]) PopupMenuItem(value: n, child: Text(n == 1 ? t.noRepeat : fmt(t.repeatN, {'n': n})))],
                  child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [const Icon(Icons.repeat_rounded, size: 18), const SizedBox(width: 4), Text('×$_repeat')])),
                ),
            ]),
            Row(children: [
              // the page arrows point the way the page moves in an Arabic book
              IconButton(onPressed: _pageIdx < _pageList.length - 1 ? () => turn(1) : null, icon: const Icon(Icons.chevron_left_rounded), tooltip: t.nextPage),
              Text('${arabicNumber(_pageIdx + 1)} / ${arabicNumber(_pageList.length)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const Spacer(),
              if (followed)
                IconButton(
                  onPressed: (_current ?? 1) > 1 ? () => _start((_current ?? 1) - 1) : null,
                  icon: Icon(rtl ? Icons.skip_next_rounded : Icons.skip_previous_rounded),
                  tooltip: t.prevAyah,
                ),
              IconButton.filled(iconSize: 32, tooltip: _playing ? t.pause : t.play, onPressed: _togglePlay, icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
              if (followed)
                IconButton(
                  onPressed: (_current ?? 0) < detail.ayahs.length ? () => _start((_current ?? 0) + 1) : null,
                  icon: Icon(rtl ? Icons.skip_previous_rounded : Icons.skip_next_rounded),
                  tooltip: t.nextAyah,
                ),
              const Spacer(),
              Text('${arabicNumber(_pageList[_pageIdx].page)} ', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              IconButton(onPressed: _pageIdx > 0 ? () => turn(-1) : null, icon: const Icon(Icons.chevron_right_rounded), tooltip: t.prevPage),
            ]),
          ]),
        ),
      ),
    );
  }
}
