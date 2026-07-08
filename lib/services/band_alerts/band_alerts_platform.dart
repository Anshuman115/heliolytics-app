import 'package:flutter/services.dart';
import 'package:heliolytics/constants/constants.dart';

/// Android foreground service + platform events for band alerts.
class BandAlertsPlatform {
  static const _channel = MethodChannel(bandAlertsMethodChannel);
  static const _events = EventChannel(bandAlertsEventChannel);

  static Stream<dynamic> eventStream() =>
      _events.receiveBroadcastStream();

  static Future<void> startForeground() async {
    try {
      await _channel.invokeMethod<void>('startForegroundService');
    } on PlatformException {
      // Non-Android or unsupported — ignore.
    }
  }

  static Future<void> stopForeground() async {
    try {
      await _channel.invokeMethod<void>('stopForegroundService');
    } on PlatformException {
      // Non-Android or unsupported — ignore.
    }
  }

  static Future<String?> bluetoothAdapterName() async {
    try {
      return await _channel.invokeMethod<String>('getBluetoothAdapterName');
    } on PlatformException {
      return null;
    }
  }
}
