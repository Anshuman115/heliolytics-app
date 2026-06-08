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
  static const int _response = 0x10;
  static const int _cmdStartDate = 0x01;
  static const int _cmdFetchData = 0x02;
  static const int _cmdAck = 0x03;
  static const int _ackKeep = 0x09; // keep data on device after reading

  final StrapGattConnection _gatt;
  DataRequester(this._gatt);

  /// Fetch [typeCode] since [since]. Returns a [FetchResult] with entry metadata
  /// and raw bytes for storage.
  Future<FetchResult> fetchType(int typeCode, DateTime since) async {
    final data = BytesBuilder();
    final allRaw = BytesBuilder();
    int lastCounter = -1;
    int rounds = 0;
    int expectedPackets = -1;
    String status = 'rejected';

    final controlCompleter = Completer<void>();

    final controlSub = _gatt.controlStream.listen((p) {
      // ignore: avoid_print
      print('[FETCH] control notify: ${p.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      if (p.length < 3 || p[0] != _response) {
        // ignore: avoid_print
        print('[FETCH]   not a response (first byte: ${p.isNotEmpty ? p[0].toRadixString(16) : "empty"})');
        return;
      }
      final cmd = p[1];
      final st = p[2];
      // ignore: avoid_print
      print('[FETCH]   cmd=0x${cmd.toRadixString(16)} status=0x${st.toRadixString(16)}');

      if (cmd == _cmdStartDate) {
        if (st != 0x01) {
          status = 'rejected';
          // ignore: avoid_print
          print('[FETCH]   start rejected (status=0x${st.toRadixString(16)})');
          if (!controlCompleter.isCompleted) controlCompleter.complete();
          return;
        }
        // Parse expected packet count from bytes 3-6 (u32 LE)
        if (p.length >= 7) {
          expectedPackets = ByteData.sublistView(Uint8List.fromList(p), 3, 7)
              .getUint32(0, Endian.little);
        } else if (p.length >= 6) {
          expectedPackets = p[3] | (p[4] << 8) | (p[5] << 16) | (p.length > 6 ? (p[6] << 24) : 0);
        }
        // ignore: avoid_print
        print('[FETCH]   expected packets: $expectedPackets');

        if (expectedPackets == 0) {
          status = 'empty';
          _gatt.writeControl([_cmdAck, _ackKeep]);
          if (!controlCompleter.isCompleted) controlCompleter.complete();
          return;
        }
        status = 'ok';
        _gatt.writeControl([_cmdFetchData]);
        // ignore: avoid_print
        print('[FETCH]   sent fetch command');
      } else if (cmd == _cmdFetchData) {
        if (st != 0x01) {
          status = 'rejected';
          // ignore: avoid_print
          print('[FETCH]   fetch failed (status=0x${st.toRadixString(16)})');
          if (!controlCompleter.isCompleted) controlCompleter.complete();
          return;
        }
        _gatt.writeControl([_cmdAck, _ackKeep]);
        if (!controlCompleter.isCompleted) controlCompleter.complete();
      } else if (cmd == _cmdAck) {
        // Device reply to our ack — ignore
      }
    });

    final dataSub = _gatt.dataStream.listen((p) {
      if (p.isEmpty) return;
      final counter = p[0];
      if (lastCounter >= 0 && counter != ((lastCounter + 1) & 0xFF)) {
        // ignore: avoid_print
        print('[FETCH]   counter gap: got=$counter expected=${(lastCounter + 1) & 0xFF}');
      }
      lastCounter = counter;
      final payload = p.sublist(1);
      if (payload.isNotEmpty) data.add(payload);
      rounds++;
      // ignore: avoid_print
      print('[FETCH]   data pkt #$rounds: counter=$counter ${payload.length}B');
    });

    // Send the start command: [0x01, typeCode, ...HuamiTime(8 bytes)]
    final startCmd = [
      _cmdStartDate,
      typeCode,
      ...HuamiTime.fromDateTime(since),
    ];
    // ignore: avoid_print
    print('[FETCH] sending start: ${startCmd.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    await _gatt.writeControl(startCmd);

    // Wait for control acknowledgment (5 sec timeout)
    await controlCompleter.future
        .timeout(const Duration(seconds: 5), onTimeout: () {
      // ignore: avoid_print
      print('[FETCH]   control timeout — no response from strap');
    });

    // If data is coming, wait for it to finish (up to 15 sec)
    if (status == 'ok') {
      // ignore: avoid_print
      print('[FETCH] waiting for data packets (up to 15s)...');
      await Future<void>.delayed(const Duration(seconds: 15));
    }

    await controlSub.cancel();
    await dataSub.cancel();

    final raw = data.toBytes();
    if (raw.isNotEmpty) allRaw.add(raw);

    final hexCode =
        '0x${typeCode.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    return FetchResult(
      entry: DumpEntry(
        code: hexCode,
        status: _parseDumpStatus(status),
        samples: raw.length ~/ 4,
        bytes: raw.length,
        file: '${hexCode}_raw.bin',
      ),
      rawBytes: allRaw.toBytes(),
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
