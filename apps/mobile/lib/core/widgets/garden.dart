import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../offline/sync_service.dart';
import '../theme/app_theme.dart';

// The "garden" design language shared by the home screens, the hub and the
// lists: one hero header in the center's colour, soft white cards on a warm
// page, round icon bubbles and a small connection pill that is always in sight.

/// A soft white card (shadow instead of a hard border).
class GardenCard extends StatelessWidget {
  const GardenCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color, this.margin});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: kSoftShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(kCardRadius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A round tinted bubble around an icon.
class IconBubble extends StatelessWidget {
  const IconBubble(this.icon, {super.key, this.color, this.size = 42});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(size * 0.36)),
      child: Icon(icon, color: c, size: size * 0.52),
    );
  }
}

/// Online / offline / waiting-to-upload, always visible in the headers; opens the sync center.
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({super.key, this.onDark = true});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final t = tr(context).garden;
    final waiting = sync.pendingCount;
    final (IconData icon, String label, Color color) = sync.failedCount > 0
        ? (Icons.error_outline_rounded, fmt(t.failedN, {'n': sync.failedCount}), const Color(0xFFE5484D))
        : sync.unreachable && waiting == 0
            ? (Icons.wifi_off_rounded, t.noInternet, const Color(0xFFF2A93B))
            : !sync.online
            ? (Icons.cloud_off_rounded, waiting > 0 ? fmt(t.offlineWaiting, {'n': waiting}) : t.offline, const Color(0xFFF2A93B))
            : sync.flushing
                ? (Icons.sync_rounded, t.syncing, const Color(0xFF4CC38A))
                : waiting > 0
                    ? (Icons.cloud_upload_rounded, fmt(t.waitingN, {'n': waiting}), const Color(0xFFF2A93B))
                    : (Icons.cloud_done_rounded, t.online, const Color(0xFF4CC38A));
    final fg = onDark ? Colors.white : kInk;
    return Material(
      color: onDark ? Colors.white.withValues(alpha: 0.16) : Colors.white,
      shape: StadiumBorder(side: onDark ? BorderSide.none : const BorderSide(color: kHairline)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => context.push('/sync'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

/// The header's round sync button: a cloud that says the state at a glance
/// (done / uploading / offline / something failed) with a count of what is
/// still on the phone. Opens the sync center.
class SyncButton extends StatelessWidget {
  const SyncButton({super.key, this.onDark = true});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final waiting = sync.pendingCount + sync.failedCount;
    final icon = sync.failedCount > 0
        ? Icons.sync_problem_rounded
        : !sync.online
            ? Icons.cloud_off_rounded
            : sync.flushing
                ? Icons.cloud_sync_rounded
                : waiting > 0
                    ? Icons.cloud_upload_rounded
                    : Icons.cloud_done_rounded;
    final badge = sync.failedCount > 0 ? const Color(0xFFE5484D) : const Color(0xFFF2A93B);
    return IconButton(
      tooltip: tr(context).garden.syncCenter,
      onPressed: () => context.push('/sync'),
      icon: Badge(
        isLabelVisible: waiting > 0,
        backgroundColor: badge,
        label: Text('$waiting'),
        child: Icon(icon, color: onDark ? Colors.white : kInk),
      ),
    );
  }
}

/// The ☰ button that opens the screen's drawer (white, for the coloured headers).
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: () => Scaffold.of(context).openDrawer(),
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
      );
}

/// Today's date in the reader's language ("الأحد، ٢٨ سبتمبر").
String longToday(BuildContext context) {
  final lang = tr(context).lang;
  try {
    return DateFormat.MMMMEEEEd(lang).format(DateTime.now());
  } catch (_) {
    return DateFormat('yyyy/MM/dd').format(DateTime.now());
  }
}

/// The big coloured header of a home screen: greeting, title, the date, the
/// connection pill and a row of glassy stats; leaves drawn behind it.
class GardenHeader extends StatelessWidget {
  const GardenHeader({
    super.key,
    required this.title,
    this.greeting,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.stats = const [],
    this.bottom,
  });

  final String title;
  final String? greeting;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final List<HeaderStat> stats;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).colorScheme.primary;
    final top = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [Color.lerp(brand, Colors.black, 0.42)!, brand, Color.lerp(brand, const Color(0xFFD4A24C), 0.22)!],
            stops: const [0, 0.62, 1],
          ),
        ),
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _LeavesPainter())),
          Padding(
            padding: EdgeInsets.fromLTRB(18, top + 10, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                const ConnectionPill(),
                const Spacer(),
                ...actions,
              ]),
              const SizedBox(height: 16),
              if (greeting != null)
                Text(greeting!, style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 14, fontWeight: FontWeight.w500)),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
              ],
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _GlassStat(stats[i])),
                  ],
                ]),
              ],
              if (bottom != null) ...[const SizedBox(height: 14), bottom!],
            ]),
          ),
        ]),
      ),
    );
  }
}

class HeaderStat {
  const HeaderStat(this.value, this.label, {this.icon});
  final String value;
  final String label;
  final IconData? icon;
}

class _GlassStat extends StatelessWidget {
  const _GlassStat(this.stat);
  final HeaderStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (stat.icon != null) ...[Icon(stat.icon, size: 15, color: Colors.white.withValues(alpha: 0.85)), const SizedBox(width: 4)],
          Flexible(child: Text(stat.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 2),
        Text(stat.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 11.5)),
      ]),
    );
  }
}

/// Soft leaves and circles behind the header (drawn, so any brand colour works).
class _LeavesPainter extends CustomPainter {
  const _LeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), size.width * 0.32, soft);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.95), size.width * 0.22, soft);
    final leaf = Paint()..color = Colors.white.withValues(alpha: 0.09);
    void drawLeaf(Offset c, double len, double angle) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.38, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.38, 0, 0);
      canvas.drawPath(path, leaf);
      canvas.restore();
    }

    drawLeaf(Offset(size.width * 0.70, size.height * 0.30), 70, -0.6);
    drawLeaf(Offset(size.width * 0.80, size.height * 0.52), 54, 0.4);
    drawLeaf(Offset(size.width * 0.18, size.height * 0.18), 40, math.pi * 0.85);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A titled block on a page, with an optional "see all" action.
class GardenSection extends StatelessWidget {
  const GardenSection({super.key, required this.title, required this.child, this.action, this.onAction, this.icon});

  final String title;
  final IconData? icon;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 6)],
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: kInk))),
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text(action!),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }
}

/// A square shortcut: icon bubble over a label (hub grid, quick actions).
class GardenTile extends StatelessWidget {
  const GardenTile({super.key, required this.icon, required this.label, this.onTap, this.color, this.badge});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GardenCard(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Badge(
          isLabelVisible: (badge ?? 0) > 0,
          label: Text('${badge ?? 0}'),
          child: IconBubble(icon, color: color, size: 46),
        ),
        const SizedBox(height: 8),
        Text(label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk, height: 1.25)),
      ]),
    );
  }
}

/// A grid of [GardenTile]s (3 per row on a phone, more on a tablet).
class GardenGrid extends StatelessWidget {
  const GardenGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final perRow = math.max(3, (c.maxWidth / 130).floor());
      return GridView.count(
        crossAxisCount: perRow,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.98,
        children: children,
      );
    });
  }
}

/// A ring that fills with [value] (0..1), with [center] inside.
class GardenRing extends StatelessWidget {
  const GardenRing({super.key, required this.value, required this.center, this.size = 56, this.color, this.stroke = 6});

  final double value;
  final Widget center;
  final double size;
  final double stroke;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: value.clamp(0, 1).toDouble(),
            strokeWidth: stroke,
            strokeCap: StrokeCap.round,
            color: c,
            backgroundColor: c.withValues(alpha: 0.12),
          ),
        ),
        center,
      ]),
    );
  }
}

/// A small coloured label ("حاضر ٥").
class GardenChip extends StatelessWidget {
  const GardenChip(this.label, {super.key, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? kInkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: c), const SizedBox(width: 3)],
        Text(label, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
