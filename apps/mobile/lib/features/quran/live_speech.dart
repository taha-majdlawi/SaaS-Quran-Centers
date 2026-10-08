import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Live reciting with a recording (Android 13+, android/.../LiveSpeech.kt): the app takes the
/// microphone itself, records it for the teacher (AAC, .m4a) and hands the same sound to the
/// phone's speech recogniser. Elsewhere, or when the recogniser does not take the sound this
/// way (a "fallback" event), the screen uses speech_to_text without a recording.
///
/// Events: {type: partial | final, text, session}, {type: listening, on}, {type: error, code},
/// {type: fallback}.
class LiveSpeech {
  static const _channel = MethodChannel('bustan/live_speech');
  static const _events = EventChannel('bustan/live_speech/events');

  StreamSubscription<dynamic>? _sub;

  static Future<bool> supported() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('supported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Starts capturing and recording into [path] (recognition starts with [resume]); the
  /// recogniser is biased towards [bias] (the passage's words - biasPhrases).
  Future<bool> start(String path, String language, List<String> bias, void Function(Map<String, dynamic>) onEvent) async {
    await _sub?.cancel();
    _sub = _events.receiveBroadcastStream().listen((e) => onEvent(Map<String, dynamic>.from(e as Map)));
    try {
      final ok = await _channel.invokeMethod<bool>('start', {'path': path, 'language': language, 'bias': bias}) ?? false;
      if (!ok) await _sub?.cancel();
      return ok;
    } catch (_) {
      await _sub?.cancel();
      return false;
    }
  }

  Future<void> resume() => _channel.invokeMethod('resume').catchError((_) {});

  /// Recognition stops; the recording carries on.
  Future<void> pause() => _channel.invokeMethod('pause').catchError((_) {});

  /// Ends everything; the recording, unless [discard] or there is none.
  Future<({File file, int seconds})?> stop({bool discard = false}) async {
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>('stop', {'discard': discard});
      await _sub?.cancel();
      _sub = null;
      if (r == null) return null;
      return (file: File(r['path'] as String), seconds: (r['seconds'] as num).toInt());
    } catch (_) {
      return null;
    }
  }
}
