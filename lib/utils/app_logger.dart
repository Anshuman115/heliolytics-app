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
      observer: _PersistingObserver(_store),
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

  /// Exposed for the App Logs settings screen (TalkerScreen needs it).
  Talker get talker => _talker;

  Future<void> _replayPersistedLogs() async {
    final lines = await _store.readAllLines();
    for (final line in lines) {
      try {
        final j = jsonDecode(line) as Map<String, dynamic>;
        final ts = DateTime.tryParse(j['ts'] as String? ?? '');
        _talker.logCustom(TalkerLog(j['message'] as String? ?? '', time: ts));
      } catch (_) {
        // Skip malformed lines — best-effort replay.
      }
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
    dio.interceptors.add(
      TalkerDioLogger(
        talker: _talker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: false,
          printResponseMessage: true,
          printResponseData: true,
          printErrorHeaders: true,
          hiddenHeaders: _hiddenHeaders,
        ),
      ),
    );
    return dio;
  }
}

/// Writes every Talker event to disk as one JSON-line, best-effort.
class _PersistingObserver extends TalkerObserver {
  final LogFileStore store;
  _PersistingObserver(this.store);

  @override
  void onLog(TalkerData log) {
    store.append(jsonEncode({
      'ts': log.time.toIso8601String(),
      'level': log.logLevel?.name ?? 'info',
      'message': log.generateTextMessage(),
    }));
  }
}
