import 'dart:developer' as dev;

/// Structured log visible in Android Studio / `adb logcat -s Heliolytics`.
void appLog(String message, {String tag = 'Heliolytics', Object? error}) {
  dev.log(message, name: tag, error: error);
}
