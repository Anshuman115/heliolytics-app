import 'package:heliolytics/models/band_alerts_config.dart';

/// OS permission + setup gates before band alerts can turn on.
class BandAlertsReadiness {
  final bool notificationListenerGranted;
  final bool phoneStateGranted;
  final bool postNotificationsGranted;

  const BandAlertsReadiness({
    this.notificationListenerGranted = false,
    this.phoneStateGranted = false,
    this.postNotificationsGranted = false,
  });

  bool isReadyFor(BandAlertsConfig config) =>
      hasPermissionsFor(config) && config.hasForwardingTarget;

  bool hasPermissionsFor(BandAlertsConfig config) {
    if (config.needsNotificationListener() && !notificationListenerGranted) {
      return false;
    }
    if (config.needsPhonePermission() && !phoneStateGranted) return false;
    if (!postNotificationsGranted) return false;
    return true;
  }

  List<BandAlertsReadinessItem> checklist(BandAlertsConfig config) {
    final items = <BandAlertsReadinessItem>[
      if (config.needsNotificationListener())
        BandAlertsReadinessItem(
          id: 'notification_listener',
          label: 'Notification access',
          granted: notificationListenerGranted,
        ),
      if (config.needsPhonePermission())
        BandAlertsReadinessItem(
          id: 'phone_state',
          label: 'Phone permission',
          granted: phoneStateGranted,
        ),
      BandAlertsReadinessItem(
        id: 'post_notifications',
        label: 'Notification permission',
        granted: postNotificationsGranted,
      ),
      BandAlertsReadinessItem(
        id: 'forwarding_target',
        label: config.callsOnly && config.forwardCalls
            ? 'Calls only selected'
            : 'At least one app or calls only',
        granted: config.hasForwardingTarget,
      ),
    ];
    return items;
  }
}

class BandAlertsReadinessItem {
  final String id;
  final String label;
  final bool granted;

  const BandAlertsReadinessItem({
    required this.id,
    required this.label,
    required this.granted,
  });
}
