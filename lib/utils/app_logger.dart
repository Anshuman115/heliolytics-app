import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:heliolytics/utils/log_file_store.dart';

const _hiddenHeaders = {'X-Heliolytics-Token', 'Authorization', 'Cookie'};

/// Process-wide logging: logcat via [log], HTTP via Talker on [createApiDio],
/// persisted to disk (see [LogFileStore]) and replayed into [talker]'s
/// history on startup so the log viewer shows history across app restarts.
class AppLogger {
  AppLogger._() {
    _talker = Talker(
      settings: TalkerSettings(enabled: true, useConsoleLogs: !kReleaseMode),
      observer: _PersistingObserver(_store, () => _replaying),
    );
    _replayPersistedLogs();
    FlutterError.onError = (details) {
      _talker.handle(
        details.exception,
        details.stack ?? StackTrace.current,
        'flutter_error',
      );
      log(details.exceptionAsString(), tag: 'flutter_error');
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _talker.handle(error, stack, 'platform_error');
      log('$error\n$stack', tag: 'platform_error');
      return true;
    };
  }

  static final AppLogger instance = AppLogger._();

  final LogFileStore _store = LogFileStore();
  late final Talker _talker;

  /// Set while replaying persisted logs at startup so [_PersistingObserver]
  /// doesn't write them straight back to disk — otherwise every launch
  /// would re-persist its entire history, multiplying on-disk log volume.
  bool _replaying = false;

  /// Exposed for the App Logs settings screen (TalkerScreen needs it).
  Talker get talker => _talker;

  Future<void> _replayPersistedLogs() async {
    final lines = await _store.readAllLines();
    _replaying = true;
    try {
      for (final line in lines) {
        try {
          final j = jsonDecode(line) as Map<String, dynamic>;
          final ts = DateTime.tryParse(j['ts'] as String? ?? '');
          _talker.logCustom(TalkerLog(j['message'] as String? ?? '', time: ts));
        } catch (_) {
          // Skip malformed lines — best-effort replay.
        }
      }
    } finally {
      _replaying = false;
    }
  }

  /// Visible in Android Studio / `adb logcat -s Heliolytics` and Talker console.
  void log(String message, {String tag = 'Heliolytics', Object? error}) {
    dev.log(message, name: tag, error: error);
    if (error != null) {
      _talker.error('[$tag] $message', error);
    } else {
      _talker.log('[$tag] $message');
    }
  }

  Dio createApiDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (code) => code != null && code < 500,
      ),
    );
    // Response bodies carry parsed health metrics (PHI). Full bodies are
    // shown in the debug console for local development, but never enter
    // the message text that gets persisted to disk in release —
    // printResponseData off means TalkerDioLogger never formats body
    // content into generateTextMessage() at all, so there's nothing for
    // _PersistingObserver to write. Status, URL, timing, and headers
    // (already redacted via hiddenHeaders for the ones that matter) still
    // log either way — only the metric values themselves drop in release.
    dio.interceptors.add(
      TalkerDioLogger(
        talker: _talker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: false,
          printResponseMessage: true,
          printResponseData: !kReleaseMode,
          printErrorHeaders: true,
          hiddenHeaders: _hiddenHeaders,
        ),
      ),
    );
    return dio;
  }
}

/// Writes every Talker event to disk as one JSON-line, best-effort.
/// Skips writes while [isReplaying] is true, so replaying persisted
/// history at startup doesn't re-persist that same history right back.
class _PersistingObserver extends TalkerObserver {
  final LogFileStore store;
  final bool Function() isReplaying;
  _PersistingObserver(this.store, this.isReplaying);

  @override
  void onLog(TalkerData log) {
    if (isReplaying()) return;
    store.append(jsonEncode({
      'ts': log.time.toIso8601String(),
      'level': log.logLevel?.name ?? 'info',
      'message': log.generateTextMessage(),
    }));
  }
}
