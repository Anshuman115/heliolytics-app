import 'dart:convert';
import 'dart:typed_data';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/notification_caps.dart';
import 'package:heliolytics/services/ble/band_link.dart';

/// Encrypted alert payloads on endpoint 0x001e.
class BandNotificationService {
  final void Function(String) log;
  BandNotificationService({required this.log});

  Future<bool> sendIncomingCall(
    BandLink link, {
    String? name,
    String? number,
  }) =>
      _send(link, _callPayload(incoming: true, name: name, number: number));

  Future<bool> sendCallEnd(BandLink link) =>
      _send(link, _callPayload(incoming: false));

  Future<bool> sendAppNotification(
    BandLink link, {
    required int id,
    required String packageId,
    String? title,
    String? body,
    String? appName,
    NotificationCaps caps = NotificationCaps.v4,
  }) {
    return _send(
      link,
      _appPayload(
        id: id,
        packageId: packageId,
        title: title,
        body: body,
        appName: appName,
        caps: caps,
      ),
    );
  }

  Future<bool> _send(BandLink link, List<int> payload) async {
    final ok = await link.sendEndpointPayload(
      notificationEndpoint,
      payload,
      encrypt: true,
    );
    if (ok) {
      final hex = payload
          .take(20)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      log('→ alert sent (${payload.length}B) $hex…');
    } else {
      log('✗ alert send failed');
    }
    return ok;
  }

  List<int> _callPayload({
    required bool incoming,
    String? name,
    String? number,
  }) {
    return [
      notificationCmdSend,
      ..._u32(0),
      notificationTypeCall,
      incoming ? notificationCallStateStart : notificationCallStateEnd,
      0x00,
      ..._cstr(name),
      0x00,
      0x00,
      ..._cstr(number),
      number != null && number.isNotEmpty ? 0x01 : 0x00,
    ];
  }

  List<int> _appPayload({
    required int id,
    required String packageId,
    String? title,
    String? body,
    String? appName,
    required NotificationCaps caps,
  }) {
    final displayTitle = (title != null && title.isNotEmpty)
        ? title
        : (body != null && body.isNotEmpty ? body : packageId);
    return [
      notificationCmdSend,
      ..._u32(id),
      notificationTypeApp,
      notificationSubcmdShow,
      ..._cstr(packageId),
      ..._cstr(displayTitle),
      ..._cstr(_truncate(body)),
      ..._cstr(appName ?? packageId),
      ..._tail(caps),
    ];
  }

  List<int> _tail(NotificationCaps caps) {
    final out = <int>[0x00]; // hasReply
    if (caps.version >= 5) {
      out.add(0x00); // not silent
      if (caps.supportsPictures) out.add(0x00);
      if (caps.supportsNotificationKey) out.add(0x00);
    }
    return out;
  }

  List<int> _u32(int v) {
    final b = ByteData(4);
    b.setUint32(0, v & 0xFFFFFFFF, Endian.little);
    return b.buffer.asUint8List();
  }

  List<int> _cstr(String? value) {
    if (value == null || value.isEmpty) return const [0x00];
    return [...utf8.encode(value), 0x00];
  }

  String? _truncate(String? body) {
    if (body == null || body.isEmpty) return body;
    if (body.length <= bandAlertsMaxNotificationBodyLen) return body;
    return body.substring(0, bandAlertsMaxNotificationBodyLen);
  }
}
