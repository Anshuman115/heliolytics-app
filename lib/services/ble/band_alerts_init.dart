import 'package:heliolytics/models/band_alerts_config.dart';
import 'package:heliolytics/models/notification_caps.dart';
import 'package:heliolytics/services/band_alerts/band_alerts_platform.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/zepp/notification_channel_init.dart';
import 'package:heliolytics/services/ble/zepp/phone_pair_service.dart';
import 'package:heliolytics/services/ble/zepp/vibration_pattern_service.dart';
import 'package:heliolytics/services/ble/zepp/zepp_service_registry.dart';

class BandAlertsInitResult {
  final bool success;
  final NotificationCaps notificationCaps;

  const BandAlertsInitResult({
    required this.success,
    this.notificationCaps = NotificationCaps.v4,
  });
}

/// ZeppOS strap setup after BLE auth — service list, pairing, patterns, caps.
class BandAlertsInitService {
  final void Function(String) log;
  BandAlertsInitService({required this.log});

  Future<BandAlertsInitResult> run(
    BandLink link,
    BandAlertsConfig config,
  ) async {
    try {
      if (!await ZeppServiceRegistry(log: log).requestServices(link)) {
        return const BandAlertsInitResult(success: false);
      }
      final caps = await NotificationChannelInit(log: log).initialize(link);
      if (config.forwardCalls) {
        final name = await BandAlertsPlatform.bluetoothAdapterName() ??
            'Heliolytics';
        if (!await PhonePairService(log: log).initialize(
          link,
          bluetoothName: name,
        )) {
          return const BandAlertsInitResult(success: false);
        }
      }
      if (!await VibrationPatternService(log: log).pushDefaults(link)) {
        return const BandAlertsInitResult(success: false);
      }
      log('✓ band alerts strap init complete');
      return BandAlertsInitResult(success: true, notificationCaps: caps);
    } catch (e) {
      log('✗ band alerts init failed: $e');
      return const BandAlertsInitResult(success: false);
    }
  }
}
