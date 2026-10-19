import 'dart:typed_data';

import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/constants/strap_health_constants.dart';

/// Minimal transaction seam for HEALTH protocol tests and hardware access.
abstract interface class HealthConfigPort {
  Future<Uint8List?> awaitEndpointPayload(int endpoint, {Duration timeout});

  Future<bool> sendEndpointPayload(
    int endpoint,
    Uint8List payload, {
    required bool encrypt,
  });

  void cancelEndpointPayload(int endpoint);

  /// Retire the channel after a malformed, timed-out or failed transaction.
  /// Late frames must not satisfy the next operation.
  Future<void> retireConfigChannel();
}

class BandLinkHealthConfigPort implements HealthConfigPort {
  final BandLink link;

  const BandLinkHealthConfigPort(this.link);

  @override
  Future<Uint8List?> awaitEndpointPayload(
    int endpoint, {
    Duration timeout = const Duration(seconds: 4),
  }) => link.awaitEndpointPayload(endpoint, timeout: timeout);

  @override
  Future<bool> sendEndpointPayload(
    int endpoint,
    Uint8List payload, {
    required bool encrypt,
  }) => link.sendEndpointPayload(endpoint, payload, encrypt: encrypt);

  @override
  void cancelEndpointPayload(int endpoint) =>
      link.cancelEndpointPayload(endpoint);

  @override
  Future<void> retireConfigChannel() =>
      link.retireEndpoint(strapHealthConfigEndpoint);
}
