import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

const _hiddenHeaders = {'X-Heliolytics-Token', 'Authorization', 'Cookie'};

/// Process-wide logging: logcat via [log], HTTP via Talker on [createApiDio].
class AppLogger {
  AppLogger._() {
    _talker = Talker(
      settings: TalkerSettings(
        enabled: !kReleaseMode,
        useConsoleLogs: !kReleaseMode,
      ),
    );
    if (kReleaseMode) return;
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

  late final Talker _talker;

  /// Visible in Android Studio / `adb logcat -s Heliolytics` and Talker console.
  void log(String message, {String tag = 'Heliolytics', Object? error}) {
    dev.log(message, name: tag, error: error);
    if (kReleaseMode) return;
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
    if (!kReleaseMode) {
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
    }
    return dio;
  }
}
