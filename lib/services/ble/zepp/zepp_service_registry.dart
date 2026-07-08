import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/band_link.dart';

/// Requests the ZeppOS service list on endpoint 0x0000.
class ZeppServiceRegistry {
  final void Function(String) log;
  ZeppServiceRegistry({required this.log});

  Future<bool> requestServices(BandLink link) async {
    log('→ zepp service list');
    final waiter = link.awaitEndpointPayload(zeppServicesEndpoint);
    final ok = await link.sendEndpointPayload(
      zeppServicesEndpoint,
      [zeppServicesGetListCmd],
      encrypt: false,
    );
    if (!ok) return false;
    final reply = await waiter;
    if (reply == null || reply.isEmpty) {
      log('• service list timeout (continuing)');
      return true;
    }
    log('✓ service list received (${reply.length}B)');
    return true;
  }
}
