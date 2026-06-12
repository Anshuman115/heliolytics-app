import 'dart:typed_data';

import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/band_link.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_status.dart';

typedef RefetchResult = ({DumpEntry entry, Uint8List raw});

class SyncRefetchRunner {
  final void Function(String) log;
  SyncRefetchRunner(this.log);

  Future<RefetchResult?> run(
    AuthKeyStorage auth,
    String codeStr, {
    required DateTime since,
  }) async {
    final mac = await auth.readMac();
    final authKey = await auth.readBytes();
    if (mac == null || mac.isEmpty || authKey == null) {
      log('Refetch aborted: missing MAC or auth key');
      return null;
    }

    final client = BandLink(log);
    try {
      final ok = await client.connectAndAuth(mac: mac, authKey: authKey);
      if (!ok) {
        log('Refetch aborted: connect/auth failed');
        return null;
      }
      final typeInt = int.parse(codeStr.substring(2), radix: 16);
      final result = await client.fetchCode(typeInt, since);
      final raw = result.raw;
      final status = raw.isEmpty
          ? (result.expected < 0 ? DumpStatus.rejected : DumpStatus.empty)
          : DumpStatus.ok;
      final entry = DumpEntry(
        code: codeStr,
        status: status,
        samples: raw.length ~/ 4,
        bytes: raw.length,
        file: '${codeStr}_raw.bin',
        roundStart: result.roundStart,
        roundSegments: result.roundSegments,
      );
      return (entry: entry, raw: raw);
    } finally {
      await client.disconnect();
    }
  }
}
