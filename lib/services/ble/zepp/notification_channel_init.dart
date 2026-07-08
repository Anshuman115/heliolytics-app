import 'dart:typed_data';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/notification_caps.dart';
import 'package:heliolytics/services/ble/band_link.dart';

const int notificationCapsResponse = 0x02;

/// Initializes the notification/call channel on endpoint 0x001e.
class NotificationChannelInit {
  final void Function(String) log;
  NotificationChannelInit({required this.log});

  Future<NotificationCaps> initialize(BandLink link) async {
    log('→ notification caps');
    final waiter = link.awaitEndpointPayload(notificationEndpoint);
    final ok = await link.sendEndpointPayload(
      notificationEndpoint,
      [notificationCapsRequest],
      encrypt: true,
    );
    if (!ok) return NotificationCaps.v4;

    final reply = await waiter;
    if (reply == null || reply.isEmpty) {
      log('• notification caps timeout — assuming v4');
      return NotificationCaps.v4;
    }

    final caps = _parse(reply);
    log(
      '✓ notification v${caps.version} '
      'pictures=${caps.supportsPictures} key=${caps.supportsNotificationKey}',
    );
    return caps;
  }

  NotificationCaps _parse(Uint8List reply) {
    if (reply.isEmpty || reply[0] != notificationCapsResponse) {
      return NotificationCaps.v4;
    }
    var version = reply.length > 1 ? reply[1] : 4;
    var pictures = false;
    var notifKey = false;
    if (version >= 4 && reply.length >= 6) {
      var off = 2;
      off += 2; // unk u16
      off += 1; // unk byte
      final hasList = reply[off];
      off += 1;
      if (hasList != 0 && off + 2 <= reply.length) {
        final n = ByteData.sublistView(reply).getUint16(off, Endian.little);
        off += 2 + n;
      }
      if (version >= 5 && off + 2 <= reply.length) {
        pictures = reply[off] != 0;
        notifKey = reply[off + 1] != 0;
      }
    }
    return NotificationCaps(
      version: version,
      supportsPictures: pictures,
      supportsNotificationKey: notifKey,
    );
  }
}
