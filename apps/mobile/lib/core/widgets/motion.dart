import 'dart:math' as math;

import 'package:flutter/material.dart';

// The garden's motion: things sprout into place (rise a little, open up, fade in),
// leaves sway in a slow breeze, numbers and rings grow to their value, and a good
// moment sends a few leaves up. Short and quiet; everything stands still when the
// device asks for reduced motion.

/// The device asked for reduced motion (or animations are off).
bool motionOff(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

const _sprout = Cubic(0.2, 0.7, 0.2, 1);

/// Sprouts its child into place once, when it first appears: a small rise, a slight
/// opening up and a fade. [delay] staggers a group (see [GrowIn.stagger]).
class GrowIn extends StatefulWidget {
  const GrowIn({super.key, required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 460), this.rise = 14});

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double rise;

  /// The delay of the [index]th item of a group: 45 ms apart, the first eight only
  /// (a long list does not keep the last items waiting).
  static Duration stagger(int index, {int stepMs = 45, int max = 8}) => Duration(milliseconds: math.min(index, max) * stepMs);

  @override
  State<GrowIn> createState() => _GrowInState();
}

class _GrowInState extends State<GrowIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: _sprout);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionOff(context)) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (context, child) {
          final v = _t.value;
          return Opacity(
            opacity: v.clamp(0, 1).toDouble(),
            child: Transform.translate(
              offset: Offset(0, (1 - v) * widget.rise),
              child: Transform.scale(scale: 0.97 + 0.03 * v, alignment: Alignment.bottomCenter, child: child),
            ),
          );
        },
      );
}

/// A leaf in a slow breeze: rocks its child a few degrees back and forth, forever.
class Sway extends StatefulWidget {
  const Sway({super.key, required this.child, this.degrees = 4, this.period = const Duration(milliseconds: 4200), this.alignment = Alignment.bottomCenter});

  final Widget child;
  final double degrees;
  final Duration period;
  final Alignment alignment;

  @override
  State<Sway> createState() => _SwayState();
}

class _SwayState extends State<Sway> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionOff(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final a = Curves.easeInOutSine.transform(_c.value) * 2 - 1; // -1..1
          return Transform.rotate(angle: a * widget.degrees * math.pi / 180, alignment: widget.alignment, child: child);
        },
      );
}

/// A whole number that grows up to its value (and from the old value to a new one).
/// Text that is not a plain number is shown as it is.
class CountUp extends StatelessWidget {
  const CountUp(this.text, {super.key, this.style, this.maxLines, this.overflow});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final n = int.tryParse(text);
    if (n == null || n <= 0 || motionOff(context)) return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: n.toDouble()),
      duration: Duration(milliseconds: 500 + math.min(n, 60) * 12),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style, maxLines: maxLines, overflow: overflow),
    );
  }
}

/// The garden's "please wait": three leaves on a stem that open one after another, again
/// and again - in place of a spinner where a whole page is loading.
class SproutLoader extends StatefulWidget {
  const SproutLoader({super.key, this.size = 44, this.color});

  final double size;
  final Color? color;

  @override
  State<SproutLoader> createState() => _SproutLoaderState();
}

class _SproutLoaderState extends State<SproutLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionOff(context)) {
      _c.value = 0.62; // all three open, still
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(painter: _SproutPainter(_c, widget.color ?? Theme.of(context).colorScheme.primary)),
        ),
      );
}

class _SproutPainter extends CustomPainter {
  _SproutPainter(this.anim, this.color) : super(repaint: anim);

  final Animation<double> anim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = anim.value;
    // the stem grows in the first part of the cycle, everything fades out at its end
    final fade = t > 0.86 ? 1 - (t - 0.86) / 0.14 : 1.0;
    final stem = Curves.easeOut.transform((t / 0.3).clamp(0.0, 1.0));
    final base = Offset(w / 2, h * 0.94);
    final top = Offset(w / 2, h * 0.94 - h * 0.78 * stem);
    canvas.drawLine(base, top, Paint()
      ..color = color.withValues(alpha: 0.85 * fade)
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round);
    // three leaves: left low, right in the middle, one on top
    const spots = [(0.72, -1.0, 0.18), (0.48, 1.0, 0.32), (0.16, 0.0, 0.46)];
    for (final (y, side, start) in spots) {
      final open = Curves.easeOutBack.transform(((t - start) / 0.22).clamp(0.0, 1.0));
      if (open <= 0) continue;
      final at = Offset(w / 2, h * 0.94 - h * 0.78 * (1 - y) / 0.84 * 0.84);
      final len = w * 0.32 * open;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(side == 0 ? -math.pi / 2 : (side < 0 ? math.pi + 0.5 : -0.5));
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.42, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.42, 0, 0);
      canvas.drawPath(leaf, Paint()..color = (side == 0 ? const Color(0xFFD4A24C) : color).withValues(alpha: 0.9 * fade));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SproutPainter old) => old.color != color;
}

/// A short burst of leaves rising from [origin] (or the middle of the screen) and
/// fading: for a good moment - a recitation sent, a test recorded, a serd approved.
void celebrateWithLeaves(BuildContext context, {Offset? origin, Color? color}) {
  if (motionOff(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final size = MediaQuery.sizeOf(context);
  final from = origin ?? Offset(size.width / 2, size.height * 0.62);
  final tint = color ?? Theme.of(context).colorScheme.primary;
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => IgnorePointer(child: _LeafBurst(origin: from, color: tint, onDone: () => entry.remove())));
  overlay.insert(entry);
}

class _LeafBurst extends StatefulWidget {
  const _LeafBurst({required this.origin, required this.color, required this.onDone});

  final Offset origin;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_LeafBurst> createState() => _LeafBurstState();
}

class _LeafBurstState extends State<_LeafBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  // each leaf: direction, distance, spin, size, colour mix (fixed seed: the same pleasant spread every time)
  late final List<_Leaf> _leaves = () {
    final r = math.Random(7);
    return [
      for (var i = 0; i < 14; i++)
        _Leaf(
          angle: -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1,
          distance: 90 + r.nextDouble() * 120,
          spin: (r.nextDouble() - 0.5) * 5,
          size: 9 + r.nextDouble() * 9,
          gold: i % 4 == 0,
          delay: r.nextDouble() * 0.18,
        ),
    ];
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.infinite,
        painter: _LeafBurstPainter(_c, _leaves, widget.origin, widget.color),
      );
}

class _Leaf {
  const _Leaf({required this.angle, required this.distance, required this.spin, required this.size, required this.gold, required this.delay});
  final double angle, distance, spin, size, delay;
  final bool gold;
}

class _LeafBurstPainter extends CustomPainter {
  _LeafBurstPainter(this.anim, this.leaves, this.origin, this.color) : super(repaint: anim);

  final Animation<double> anim;
  final List<_Leaf> leaves;
  final Offset origin;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in leaves) {
      final t = ((anim.value - l.delay) / (1 - l.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final out = Curves.easeOutCubic.transform(t);
      // out along its direction, then drifting down a little as it settles
      final p = origin + Offset(math.cos(l.angle), math.sin(l.angle)) * (l.distance * out) + Offset(math.sin(t * 6 + l.spin) * 8, t * t * 40);
      final opacity = t < 0.15 ? t / 0.15 : (1 - (t - 0.55) / 0.45).clamp(0.0, 1.0);
      final paint = Paint()..color = (l.gold ? const Color(0xFFD4A24C) : color).withValues(alpha: 0.85 * opacity);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(l.angle + l.spin * t);
      final s = l.size * (0.6 + 0.4 * out);
      final leaf = Path()
        ..moveTo(-s, 0)
        ..quadraticBezierTo(0, -s * 0.62, s, 0)
        ..quadraticBezierTo(0, s * 0.62, -s, 0);
      canvas.drawPath(leaf, paint);
      canvas.drawLine(Offset(-s, 0), Offset(s * 0.8, 0), Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * opacity)
        ..strokeWidth = 0.8);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeafBurstPainter old) => false;
}
