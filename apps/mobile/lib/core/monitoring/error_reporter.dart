import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/i18n.dart';

/// Sends every crash the app sees to the error log (DB 0076
/// `report_client_error`) with the screen, the device, the app version and
/// the last steps the person took. A report made without a connection waits
/// on the phone and goes out with the next one.
class ErrorReporter {
  ErrorReporter._();
  static final ErrorReporter instance = ErrorReporter._();

  static const _channel = MethodChannel('bustan/power');
  static const _pendingKey = 'error_reports_pending';

  final List<String> _crumbs = [];
  final Map<String, DateTime> _recent = {};
  String? _screen;
  String? _version;
  String? _device;
  String? _os;
  bool _sending = false;

  /// The active center (set when it changes).
  String? orgId;

  /// The app language (for the report).
  String? locale;

  /// Installs the hooks. Call once, after Supabase is initialised.
  Future<void> install() async {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      // layout overflow warnings in debug are not crashes worth a report
      if (details.silent) return;
      report(details.exception, details.stack, kind: 'flutter', context: details.context?.toDescription());
    };
    // a part of a screen that fails to build: a small note in its place, not a tall blank box (release)
    if (!kDebugMode) {
      ErrorWidget.builder = (details) => Padding(
            padding: const EdgeInsets.all(8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFF9A6B00)),
              const SizedBox(width: 6),
              Flexible(child: Text(currentStrings.common.partFailed, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B6B)))),
            ]),
          );
    }
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, kind: 'platform');
      return true;
    };
    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    _os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'.trim();
    try {
      if (Platform.isAndroid) _device = await _channel.invokeMethod<String>('device');
    } catch (_) {}
    unawaited(_flushPending());
  }

  /// One step of what the person did ("open /students/1/file", "submit attendance").
  void crumb(String text) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return;
    final now = DateTime.now();
    _crumbs.add('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} ${t.length > 120 ? t.substring(0, 120) : t}');
    if (_crumbs.length > 25) _crumbs.removeAt(0);
  }

  /// The screen now showing (from the router).
  void screen(String location) {
    if (location == _screen) return;
    _screen = location;
    crumb('open $location');
  }

  void report(Object error, StackTrace? stack, {String kind = 'caught', String? context}) {
    try {
      final message = error.toString();
      if (message.isEmpty) return;
      // network trouble is expected offline, not a bug
      if (error is SocketException || error is TimeoutException || error is HandshakeException) return;
      final key = '$message|$_screen';
      final now = DateTime.now();
      if ((_recent[key] ?? DateTime(2000)).isAfter(now.subtract(const Duration(seconds: 10)))) return;
      _recent[key] = now;
      final payload = <String, dynamic>{
        'p_source': 'mobile',
        'p_message': message.length > 1000 ? message.substring(0, 1000) : message,
        'p_stack': stack?.toString(),
        'p_screen': _screen,
        'p_org': orgId,
        'p_app_version': _version,
        'p_os': _os,
        'p_device': _device,
        'p_locale': locale,
        'p_breadcrumbs': List<String>.of(_crumbs),
        'p_extra': {'kind': kind, 'context': ?context, 'debug': kDebugMode},
      };
      unawaited(_send(payload));
    } catch (_) {
      // reporting must never crash the app
    }
  }

  Future<void> _send(Map<String, dynamic> payload) async {
    try {
      await Supabase.instance.client.rpc('report_client_error', params: payload).timeout(const Duration(seconds: 10));
      unawaited(_flushPending());
    } catch (_) {
      await _keep(payload);
    }
  }

  Future<void> _keep(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingKey) ?? [];
      list.add(jsonEncode({...payload, 'p_extra': {...(payload['p_extra'] as Map), 'delayed': true}}));
      await prefs.setStringList(_pendingKey, list.length > 20 ? list.sublist(list.length - 20) : list);
    } catch (_) {}
  }

  Future<void> _flushPending() async {
    if (_sending) return;
    _sending = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingKey) ?? [];
      if (list.isEmpty) return;
      final left = <String>[];
      for (final raw in list) {
        try {
          await Supabase.instance.client.rpc('report_client_error', params: jsonDecode(raw) as Map<String, dynamic>).timeout(const Duration(seconds: 10));
        } catch (_) {
          left.add(raw);
        }
      }
      await prefs.setStringList(_pendingKey, left);
    } catch (_) {
    } finally {
      _sending = false;
    }
  }
}
