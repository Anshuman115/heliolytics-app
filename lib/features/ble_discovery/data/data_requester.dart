import 'dart:async';
import 'dart:typed_data';

import 'package:heliolytics/core/ble/connector.dart';
import 'package:heliolytics/core/utils/huami_time.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_status.dart';

/// Result returned by [DataRequester.fetchType].
class FetchResult {
  final DumpEntry entry;
  final List<int> rawBytes;
  const FetchResult({required this.entry, required this.rawBytes});
}

/// Fetches one data type from the strap via the legacy plaintext path:
/// commands on char 0x0004 (control), data on char 0x0005 (data notify).
class DataRequester {
  static const int _cmdStart = 0x01;
  static const int _cmdFetch = 0x02;
  static const int _cmdAck = 0x03;
  static const int _ackKeep = 0x09; // keep data on device after reading
  static const int _response = 0x10;

  final StrapGattConnection _gatt;
  DataRequester(this._gatt);

  /// Fetch [typeCode] since [since]. Returns a [FetchResult] with entry metadata
  /// and raw bytes for storage.
  Future<FetchResult> fetchType(int typeCode, DateTime since) async {
    final data = BytesBuilder();
    int lastCounter = -1;
    String status = 'rejected';
    String? errorByte;

    final controlCompleter = Completer<void>();

    final controlSub = _gatt.controlStream.listen((p) {
      if (p.length < 3 || p[0] != _response) return;
      final cmd = p[1];
      final st = p[2];
      if (cmd == _cmdStart) {
        if (st != 0x01) {
          status = 'rejected';
          errorByte = '0x${st.toRadixString(16).padLeft(2, '0')}';
          if (!controlCompleter.isCompleted) controlCompleter.complete();
          return;
        }
        final expectedPackets = p.length >= 6
            ? (p[4] | (p[5] << 8))
            : 0;
        if (expectedPackets == 0) {
          status = 'empty';
          _gatt.writeControl([_cmdAck, _ackKeep]);
          if (!controlCompleter.isCompleted) controlCompleter.complete();
          return;
        }
        status = 'ok';
        _gatt.writeControl([_cmdFetch]);
      } else if (cmd == _cmdFetch) {
        if (st != 0x01) {
          if (!controlCompleter.isCompleted) controlCompleter.complete();
          return;
        }
        _gatt.writeControl([_cmdAck, _ackKeep]);
        if (!controlCompleter.isCompleted) controlCompleter.complete();
      }
    });

    final dataSub = _gatt.dataStream.listen((p) {
      if (p.isEmpty) return;
      final counter = p[0];
      // Counter gap is logged but we continue collecting.
      if (lastCounter >= 0 && counter != ((lastCounter + 1) & 0xFF)) {
        // Gap detected — data may be incomplete.
      }
      lastCounter = counter;
      if (p.length > 1) data.add(p.sublist(1));
    });

    // Send the start command: [0x01, typeCode, timestamp(4 bytes big-endian)]
    final startCmd = [
      _cmdStart,
      typeCode,
      ...HuamiTime.fromDateTime(since.toUtc()),
    ];
    await _gatt.writeControl(startCmd);

    // Wait for control acknowledgment (5 sec timeout)
    await controlCompleter.future
        .timeout(const Duration(seconds: 5), onTimeout: () {});

    if (status == 'ok') {
      // Allow data notifications to arrive (10 sec)
      await Future<void>.delayed(const Duration(seconds: 10));
    }

    await controlSub.cancel();
    await dataSub.cancel();

    final raw = data.toBytes();
    final hexCode =
        '0x${typeCode.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    return FetchResult(
      entry: DumpEntry(
        code: hexCode,
        status: _parseDumpStatus(status),
        samples: raw.length ~/ 4,
        bytes: raw.length,
        file: '${hexCode}_raw.bin',
        errorByte: errorByte,
      ),
      rawBytes: raw,
    );
  }

  DumpStatus _parseDumpStatus(String s) {
    switch (s) {
      case 'ok':
        return DumpStatus.ok;
      case 'empty':
        return DumpStatus.empty;
      default:
        return DumpStatus.rejected;
    }
  }
}
