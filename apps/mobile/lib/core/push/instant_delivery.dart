import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/i18n.dart';
import '../theme/app_theme.dart';

/// Whether Android lets this app's notifications through right away.
///
/// The server sends every notification the moment it happens, as a
/// high-priority FCM message (the same channel WhatsApp's notifications use).
/// What delays them is the phone: battery saving ("Doze" / app standby) and,
/// on Xiaomi, Huawei, Oppo, Vivo…, the maker's own "auto-start" killer. Only
/// the user can lift those, so this finds out and opens the right screen.
class InstantDelivery {
  InstantDelivery._();

  static const _channel = MethodChannel('bustan/power');

  /// Makers that also stop apps unless "auto-start" is allowed.
  static const _strictMakers = {'xiaomi', 'redmi', 'poco', 'huawei', 'honor', 'oppo', 'realme', 'oneplus', 'vivo', 'iqoo', 'letv', 'asus', 'tecno', 'infinix', 'itel'};

  /// null when not on Android (or the check is not available).
  static Future<({bool restricted, String maker})?> status() async {
    if (!Platform.isAndroid) return null;
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>('status');
      if (r == null) return null;
      return (restricted: r['ignoring'] != true, maker: (r['maker'] as String?) ?? '');
    } catch (_) {
      return null;
    }
  }

  static bool needsAutostart(String maker) => _strictMakers.contains(maker);

  static Future<void> openBatterySettings() => _call('openBattery');
  static Future<void> openAutostart() => _call('openAutostart');

  static Future<void> _call(String method) async {
    try {
      await _channel.invokeMethod<bool>(method);
    } catch (_) {}
  }
}

/// A card that appears only when the phone is holding notifications back,
/// with one button per thing to switch on. Re-checks when the user comes back
/// from the settings screen.
class InstantDeliveryCard extends StatefulWidget {
  const InstantDeliveryCard({super.key, this.showWhenOk = false, this.margin = const EdgeInsets.only(bottom: 12)});

  /// Also say so when all is well (the notification settings screen).
  final bool showWhenOk;
  final EdgeInsets margin;

  @override
  State<InstantDeliveryCard> createState() => _InstantDeliveryCardState();
}

class _InstantDeliveryCardState extends State<InstantDeliveryCard> {
  ({bool restricted, String maker})? _status;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _check();
    _lifecycle = AppLifecycleListener(onResume: _check);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final s = await InstantDelivery.status();
    if (mounted) setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (s == null) return const SizedBox.shrink();
    final t = tr(context).notif;
    final autostart = InstantDelivery.needsAutostart(s.maker);
    if (!s.restricted) {
      if (!widget.showWhenOk) return const SizedBox.shrink();
      return Container(
        margin: widget.margin,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF16835A).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFF16835A)),
            const SizedBox(width: 8),
            Expanded(child: Text(t.instantOk, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk))),
          ]),
          if (autostart) ...[
            const SizedBox(height: 6),
            Text(fmt(t.instantAutostartHint, {'maker': _makerName(s.maker)}), style: const TextStyle(fontSize: 12.5, color: kInkMuted)),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(onPressed: InstantDelivery.openAutostart, icon: const Icon(Icons.rocket_launch_rounded, size: 18), label: Text(t.instantAutostart)),
            ),
          ],
        ]),
      );
    }
    const amber = Color(0xFFB26A00);
    return Container(
      margin: widget.margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: amber.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.notifications_paused_rounded, color: amber),
          const SizedBox(width: 8),
          Expanded(child: Text(t.instantTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kInk))),
        ]),
        const SizedBox(height: 6),
        Text(t.instantBody, style: const TextStyle(fontSize: 13, color: kInk, height: 1.4)),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: InstantDelivery.openBatterySettings,
          style: FilledButton.styleFrom(backgroundColor: amber),
          icon: const Icon(Icons.battery_charging_full_rounded),
          label: Text(t.instantBattery),
        ),
        const SizedBox(height: 4),
        Text(t.instantBatteryHint, style: const TextStyle(fontSize: 11.5, color: kInkMuted)),
        if (autostart) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: InstantDelivery.openAutostart,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: Text(t.instantAutostart),
          ),
          const SizedBox(height: 4),
          Text(fmt(t.instantAutostartHint, {'maker': _makerName(s.maker)}), style: const TextStyle(fontSize: 11.5, color: kInkMuted)),
        ],
      ]),
    );
  }

  static String _makerName(String maker) => maker.isEmpty ? maker : maker[0].toUpperCase() + maker.substring(1);
}
