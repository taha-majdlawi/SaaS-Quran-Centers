import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import 'quran_data.dart';

const kMushafSizes = [24.0, 28.0, 32.0];
const kMushafGold = Color(0xFFA87A12);
const _paper = Color(0xFFFFFDF6);
const _rule = Color(0xFFE7DFC9);
const _tag = Color(0xFFF3EBD3);

/// One page of the mushaf: header (surah, juz, page), the surah banner and
/// basmala on its first page, the ayahs as one justified text, and the sajda
/// note. What is lit or hidden comes from the reader through the callbacks.
class MushafPageView extends StatefulWidget {
  const MushafPageView({
    super.key,
    required this.page,
    required this.surahName,
    required this.isFirst,
    required this.hasBasmala,
    required this.place,
    required this.ayahCount,
    required this.fontSize,
    required this.current,
    required this.word,
    required this.wordFits,
    required this.isRevealed,
    required this.testMode,
    required this.bookmarks,
    required this.onAyahTap,
    required this.onTogglePage,
  });

  final MushafPage page;
  final String surahName;
  final bool isFirst;
  final bool hasBasmala;
  final String? place;
  final int ayahCount;
  final double fontSize;

  /// The ayah being followed (null = none) and, in word mode, the word.
  final int? current;
  final int word;
  final bool Function(int ayah) wordFits;
  final bool Function(int ayah) isRevealed;
  final bool testMode;
  final Set<int> bookmarks;
  final void Function(int ayah) onAyahTap;

  /// Self-test: uncover / hide the whole page.
  final VoidCallback onTogglePage;

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  // one tap area per ayah inside the running text
  final _taps = <int, TapGestureRecognizer>{};

  TapGestureRecognizer _tap(int n) => _taps.putIfAbsent(n, () => TapGestureRecognizer())..onTap = () => widget.onAyahTap(n);

  @override
  void dispose() {
    for (final t in _taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.fontSize;
    final hidden = TextStyle(
      color: Colors.transparent,
      // the line keeps its shape, the words can't be read; same metrics, so uncovering never moves the page
      shadows: [
        Shadow(color: kInk.withValues(alpha: 0.5), blurRadius: size * 0.35),
        Shadow(color: kInk.withValues(alpha: 0.3), blurRadius: size * 0.6),
      ],
    );
    final allShown = widget.page.ayahs.every((a) => widget.isRevealed(a.number));
    final sajdas = widget.page.ayahs.where((a) => a.sajda).toList();

    final spans = <InlineSpan>[];
    for (final a in widget.page.ayahs) {
      final on = widget.current == a.number;
      final shown = widget.isRevealed(a.number);
      final recognizer = _tap(a.number);
      final base = on ? const TextStyle(backgroundColor: Color(0x55F5D78E)) : null;
      if (on && widget.wordFits(a.number)) {
        // the ayah written word by word, each word styled on its own - the text itself is untouched
        var at = 0;
        final ranges = wordRanges(a.text);
        for (var i = 0; i < ranges.length; i++) {
          final (s, e) = ranges[i];
          if (s > at) spans.add(TextSpan(text: a.text.substring(at, s), style: base, recognizer: recognizer));
          final visible = shown || i <= widget.word;
          final style = !visible ? hidden.merge(base) : (i == widget.word ? (base ?? const TextStyle()).copyWith(color: kMushafGold) : base);
          spans.add(TextSpan(text: a.text.substring(s, e), style: style, recognizer: recognizer));
          at = e;
        }
        if (at < a.text.length) spans.add(TextSpan(text: a.text.substring(at), style: base, recognizer: recognizer));
      } else {
        spans.add(TextSpan(text: a.text, style: shown ? base : hidden.merge(base), recognizer: recognizer));
      }
      // The end-of-ayah sign is real text (U+06DD + digits, drawn inside by the font), never a
      // WidgetSpan: widgets made the bidi algorithm swap the numbers of neighbouring ayahs.
      spans.add(TextSpan(text: ' ۝${arabicNumber(a.number)}', style: TextStyle(color: scheme.primary), recognizer: recognizer));
      if (widget.bookmarks.contains(a.number)) spans.add(TextSpan(text: ' 🔖', style: TextStyle(fontSize: size * 0.5)));
      spans.add(const TextSpan(text: ' '));
    }

    final tagStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black54);
    Widget tag(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(color: _tag, borderRadius: BorderRadius.circular(20)),
          child: Text(text, style: tagStyle),
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(color: _paper, border: Border.all(color: _rule), borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text('سورة ${widget.surahName}', style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18, color: kInk))),
                if (widget.testMode)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(allShown ? tr(context).quran.hidePage : tr(context).quran.revealPage, style: const TextStyle(fontSize: 12)),
                      onPressed: widget.onTogglePage,
                    ),
                  ),
                tag('الجزء ${arabicNumber(widget.page.juz)}'),
                const SizedBox(width: 6),
                tag('صفحة ${arabicNumber(widget.page.page)}'),
              ]),
              const Divider(color: _rule, height: 16),
              if (widget.isFirst) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF6EED4), border: Border.all(color: const Color(0xFFD9C78F)), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text('سورة ${widget.surahName}', style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, color: kInk, height: 1.9)),
                    Text([if (widget.place != null) widget.place!, 'آياتها ${arabicNumber(widget.ayahCount)}'].join(' · '), style: tagStyle),
                  ]),
                ),
                if (widget.hasBasmala)
                  Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: size * 1.05, height: 2.0, color: kInk)),
              ],
              Text.rich(
                TextSpan(children: spans),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                // a fixed line height, so the vowel marks of two lines never touch
                strutStyle: StrutStyle(fontFamily: 'AmiriQuran', fontSize: size, height: 2.0, forceStrutHeight: true),
                style: TextStyle(fontFamily: 'AmiriQuran', fontSize: size, height: 2.0, color: kInk),
              ),
              if (sajdas.isNotEmpty) ...[
                const Divider(color: _rule, height: 18),
                Text.rich(
                  TextSpan(children: [
                    // drawn with the mushaf font, which has the sajda sign
                    const TextSpan(text: '۩ ', style: TextStyle(fontFamily: 'AmiriQuran')),
                    TextSpan(text: 'سجدة تلاوة: الآية ${sajdas.map((a) => arabicNumber(a.number)).join('، ')}'),
                  ]),
                  textAlign: TextAlign.center,
                  style: tagStyle,
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
