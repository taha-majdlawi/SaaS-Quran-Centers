import 'dart:async';
import 'package:provider/provider.dart';

import '../tenant/tenant_controller.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The garden's tree - the same drawing as the website's (apps/web/src/components/growing-tree.tsx):
/// it grows while the app is open (a sprout, the trunk, the branches one after another, the
/// leaves, then the fruit) and then sways gently.
///
/// Kept out of the way: small, half transparent, in the bottom corner opposite the floating
/// buttons, above the bottom bar, never takes a touch, hidden while the keyboard is open.
/// Light on the battery: 15 frames a second, paused in the background, and drawn once,
/// fully grown and still, when the device asks for reduced motion.
class GrowingTreeOverlay extends StatefulWidget {
  const GrowingTreeOverlay({super.key});

  @override
  State<GrowingTreeOverlay> createState() => _GrowingTreeOverlayState();
}

/// When the app was opened: the growth carries on across screens.
final DateTime _appStart = DateTime.now();

class _GrowingTreeOverlayState extends State<GrowingTreeOverlay> with WidgetsBindingObserver {
  final _seconds = ValueNotifier<double>(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _timer?.cancel();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 66), (_) => _tick());
  }

  void _tick() => _seconds.value = DateTime.now().difference(_appStart).inMilliseconds / 1000;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.viewInsets.bottom > 0) return const SizedBox.shrink(); // typing: out of the way
    // the center switched the tree off (0088)
    if (context.watch<TenantController>().isDisabled('garden_tree')) return const SizedBox.shrink();
    final still = mq.disableAnimations;
    if (still) _timer?.cancel();
    // the floating buttons sit at the end (left in Arabic): the tree takes the start corner
    return PositionedDirectional(
      start: 4,
      bottom: mq.padding.bottom + 66,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.45,
          child: RepaintBoundary(
            child: SizedBox(
              width: 54,
              height: 60,
              child: CustomPaint(painter: TreePainter(still ? null : _seconds)),
            ),
          ),
        ),
      ),
    );
  }
}

const _ink = Color(0xFF1F3A2E);
const _bark = Color(0xFF8B5A3C);
const _leaves = [Color(0xFF5FA77A), Color(0xFF4A9367), Color(0xFF7BBF92)];
const _fruit = Color(0xFFE2A93B);

// seconds into the growth at which each part starts (same as the website)
const _tTop = 9.0, _tBranches = 14.0, _tStep = 16.0, _tLeaves = 22.0, _tFruit = 125.0, _tFruitStep = 4.5, _tSway = 185.0;

// branches: from the trunk at (100, y0) to the tip - in the drawing's 200 x 222 space
const _branches = [
  (160.0, 152.0, 132.0),
  (146.0, 47.0, 120.0),
  (124.0, 148.0, 100.0),
  (110.0, 53.0, 88.0),
  (90.0, 139.0, 70.0),
  (80.0, 62.0, 62.0),
];

/// Draws the tree as it is [seconds] after the app opened (null = fully grown, still).
class TreePainter extends CustomPainter {
  TreePainter(this.seconds) : super(repaint: seconds);

  final ValueNotifier<double>? seconds;

  double _p(double t, double start, double duration) => ((t - start) / duration).clamp(0.0, 1.0);

  /// a pop with a little overshoot (easeOutBack)
  double _pop(double t, double start) {
    final x = _p(t, start, 1.1);
    if (x <= 0) return 0;
    const c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2);
  }

  double _ease(double x) => 1 - math.pow(1 - x, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds?.value ?? 1e9;
    final scale = math.min(size.width / 200, size.height / 222);
    canvas.save();
    canvas.translate((size.width - 200 * scale) / 2, size.height - 222 * scale);
    canvas.scale(scale);

    final outline = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final bark = Paint()
      ..color = _bark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void limb(Offset a, Offset b, double width, double p) {
      if (p <= 0) return;
      final end = Offset.lerp(a, b, _ease(p))!;
      canvas.drawLine(a, end, outline..strokeWidth = width + 4);
      canvas.drawLine(a, end, bark..strokeWidth = width);
    }

    void leaf(Offset at, double angleDeg, Color color, double s) {
      if (s <= 0) return;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angleDeg * math.pi / 180);
      canvas.scale(s);
      final path = Path()
        ..moveTo(0, 0)
        ..cubicTo(6, -7, 17, -8, 24, 0)
        ..cubicTo(17, 8, 6, 7, 0, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
      canvas.drawLine(const Offset(2, 0), const Offset(20, 0), Paint()
        ..color = _ink.withValues(alpha: 0.55)
        ..strokeWidth = 0.8);
      canvas.restore();
    }

    void fruit(Offset at, double s) {
      if (s <= 0) return;
      canvas.drawCircle(at, 5.2 * s, Paint()..color = _fruit);
      canvas.drawCircle(at, 5.2 * s, Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
    }

    // the crown sways gently once grown
    canvas.save();
    if (t > _tSway && seconds != null) {
      final a = math.sin((t - _tSway) / 7 * 2 * math.pi) * 1.3 * math.pi / 180;
      canvas.translate(100, 205);
      canvas.rotate(a);
      canvas.translate(-100, -205);
    }
    limb(const Offset(100, 208), const Offset(100, 50), 11, _p(t, 0, 9));
    for (var i = 0; i < _branches.length; i++) {
      final (y0, x, y) = _branches[i];
      limb(Offset(100, y0), Offset(x, y), 8, _p(t, _tBranches + i * _tStep, 6));
    }
    leaf(const Offset(100, 50), -150, _leaves[0], _pop(t, _tTop));
    leaf(const Offset(100, 50), -30, _leaves[1], _pop(t, _tTop + 0.8));
    for (var i = 0; i < _branches.length; i++) {
      final (_, x, y) = _branches[i];
      final right = x > 100;
      final base = right ? -20.0 : 200.0;
      const fan = [-70.0, -38.0, -8.0, 22.0, 52.0, 82.0];
      for (var j = 0; j < fan.length; j++) {
        leaf(Offset(x, y), base + (right ? fan[j] : -fan[j]), _leaves[j % 3], _pop(t, _tLeaves + i * _tStep + j * 0.9));
      }
    }
    for (var i = 0; i < _branches.length; i++) {
      final (y0, x, y) = _branches[i];
      final dx = x > 100 ? -7.0 : 7.0;
      fruit(Offset(x + dx, y + 9), _pop(t, _tFruit + (i * 2) * _tFruitStep));
      fruit(Offset((x + 100) / 2 + dx, (y + y0) / 2 - 8), _pop(t, _tFruit + (i * 2 + 1) * _tFruitStep));
    }
    canvas.restore();

    // the hill it stands on
    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final back = Path()
      ..moveTo(-6, 223)
      ..cubicTo(18, 200, 60, 190, 100, 191)
      ..cubicTo(140, 192, 182, 200, 206, 223)
      ..close();
    final front = Path()
      ..moveTo(-16, 223)
      ..cubicTo(18, 211, 70, 204, 110, 206)
      ..cubicTo(150, 208, 188, 212, 216, 223)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFF9CC9A6));
    canvas.drawPath(back, stroke);
    canvas.drawPath(front, Paint()..color = const Color(0xFF5E9C6E));
    canvas.drawPath(front, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(TreePainter old) => old.seconds != seconds;
}
