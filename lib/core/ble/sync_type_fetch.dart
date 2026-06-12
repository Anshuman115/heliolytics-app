import 'dart:typed_data';

import 'package:heliolytics/core/ble/band_link_port.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_status.dart';

class SyncTypeFetch {
  SyncTypeFetch._();

  static ({DumpEntry entry, TypeCodeResult result, Uint8List? raw}) run({
    required String codeStr,
    required TypeFetchResult fetch,
    required void Function(String) log,
  }) {
    final label = typeCodeLabels[codeStr] ?? codeStr;
    final raw = fetch.raw;
    final expected = fetch.expected;
    final skipped = fetch.skipped;

    String status;
    String? rawHex;
    if (skipped) {
      status = 'skipped';
      log('  ⚡ $codeStr: skipped ($expected pkts too large)');
    } else if (raw.isEmpty) {
      status = expected < 0 ? 'rejected' : 'empty';
      log('  — $codeStr: ${expected < 0 ? "rejected" : "empty"}');
    } else {
      status = 'ok';
      final fullHex = raw.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final previewLen = raw.length > 1000 ? 512 : 128;
      rawHex = fullHex.length > previewLen
          ? fullHex.substring(0, previewLen)
          : fullHex;
      log('  ✓ $codeStr: ${raw.length} bytes');
    }

    final entry = DumpEntry(
      code: codeStr,
      status: status == 'ok'
          ? DumpStatus.ok
          : status == 'empty'
              ? DumpStatus.empty
              : DumpStatus.rejected,
      samples: raw.length ~/ 4,
      bytes: raw.length,
      file: '${codeStr}_raw.bin',
      roundStart: fetch.roundStart,
      roundSegments: fetch.roundSegments,
    );
    final result = TypeCodeResult(
      code: codeStr,
      label: label,
      status: status,
      bytes: raw.length,
      samples: raw.length ~/ 4,
      rawHex: rawHex,
    );
    return (entry: entry, result: result, raw: raw.isNotEmpty ? raw : null);
  }

  static DumpEntry errorEntry(String codeStr, Object error) {
    return DumpEntry(
      code: codeStr,
      status: DumpStatus.unknown,
      samples: 0,
      bytes: 0,
    );
  }

  static TypeCodeResult errorResult(String codeStr, Object error) {
    final label = typeCodeLabels[codeStr] ?? codeStr;
    return TypeCodeResult(
      code: codeStr,
      label: label,
      status: 'error',
      errorMsg: error.toString(),
    );
  }
}
