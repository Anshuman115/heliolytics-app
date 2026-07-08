import 'package:flutter/services.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/band_alerts_config.dart';
import 'package:heliolytics/models/band_alerts_readiness.dart';
import 'package:permission_handler/permission_handler.dart';

/// Checks and requests OS permissions needed for band alerts.
class BandAlertsPermissions {
  static const _channel = MethodChannel(bandAlertsMethodChannel);

  Future<BandAlertsReadiness> check(BandAlertsConfig config) async {
    final listener = config.needsNotificationListener()
        ? await _isNotificationListenerEnabled()
        : true;
    final phone = config.needsPhonePermission()
        ? await Permission.phone.status.isGranted
        : true;
    final post = await Permission.notification.status.isGranted;
    return BandAlertsReadiness(
      notificationListenerGranted: listener,
      phoneStateGranted: phone,
      postNotificationsGranted: post,
    );
  }

  Future<void> requestFor(BandAlertsConfig config) async {
    if (!await Permission.notification.status.isGranted) {
      await Permission.notification.request();
    }
    if (config.needsPhonePermission() &&
        !await Permission.phone.status.isGranted) {
      await Permission.phone.request();
    }
    if (config.needsNotificationListener() &&
        !await _isNotificationListenerEnabled()) {
      await openNotificationListenerSettings();
    }
  }

  Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod<void>('openNotificationListenerSettings');
    } on PlatformException {
      await openAppSettings();
    }
  }

  Future<bool> _isNotificationListenerEnabled() async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'isNotificationListenerEnabled',
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }
}
