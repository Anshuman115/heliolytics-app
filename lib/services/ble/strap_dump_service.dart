import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Progress callback: (currentIndex, totalCodes, codeHex, bytesReceived).
typedef DumpProgress = void Function(int index, int total, String code, int bytes);

/// Result of a full raw dump session.
class DumpResult {
  final String dumpDir;
  final Map<String, int> codeBytes;
  final int totalBytes;
  final Duration elapsed;

  DumpResult({
    required this.dumpDir,
    required this.codeBytes,
    required this.totalBytes,
    required this.elapsed,
  });
}

/// Fetches raw BLE data for ALL type codes (0x01→0xFF) from the strap
/// and saves each to a `0xNN_raw.bin` file in a timestamped dump directory.
class StrapDumpService {
  final void Function(String) log;

  StrapDumpService({required this.log});

  /// All 255 type codes to probe (single-byte Huami protocol).
  static List<int> get allTypeCodes =>
      List.generate(255, (i) => i + 1); // 0x01..0xFF

  /// Connects to the strap, fetches all type codes for the last [windowDays],
  /// and writes raw bytes to disk.
  Future<DumpResult> runDump({
    required String mac,
    required Uint8List authKey,
    int windowDays = 2,
    DumpProgress? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    final since = DateTime.now().subtract(Duration(days: windowDays));

    // Create dump directory
    final appDir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .substring(0, 19);
    final dumpDir = Directory(p.join(appDir.path, appDocsSubdir, 'dump_$ts'));
    await dumpDir.create(recursive: true);
    log('Dump dir: ${dumpDir.path}');

    // Connect
    final client = BandLink(log);
    var authed = await client.connectAndAuth(mac: mac, authKey: authKey);
    if (!authed) {
      log('Auth failed — retrying once');
      await Future<void>.delayed(const Duration(seconds: 1));
      authed = await client.connectAndAuth(mac: mac, authKey: authKey);
    }
    if (!authed) {
      throw Exception('Could not connect/authenticate with strap');
    }

    final codeBytes = <String, int>{};
    int totalBytes = 0;
    final codes = allTypeCodes;

    try {
      for (var i = 0; i < codes.length; i++) {
        final code = codes[i];
        final codeHex =
            '0x${code.toRadixString(16).padLeft(2, '0').toUpperCase()}';
        final label = typeCodeLabels[codeHex] ?? 'unknown';

        log('[$codeHex] Fetching ($label) ...');
        onProgress?.call(i, codes.length, codeHex, 0);

        try {
          // 10 min timeout per code. On timeout, engine sends ACK
          // to tell strap we're done, then moves to next code.
          final result = await client.dumpCode(code, since,
              timeout: const Duration(minutes: 10));
          final raw = result.raw;

          if (raw.isNotEmpty) {
            final file = File(p.join(dumpDir.path, '${codeHex}_raw.bin'));
            await file.writeAsBytes(raw);
            codeBytes[codeHex] = raw.length;
            totalBytes += raw.length;
            log('  ✓ $codeHex: ${raw.length} bytes');
          } else {
            log('  — $codeHex: empty');
          }
          onProgress?.call(i, codes.length, codeHex, raw.length);
        } catch (e) {
          log('  ✗ $codeHex: ERROR — $e');
          onProgress?.call(i, codes.length, codeHex, -1);
          // Continue with next code
        }
      }
    } finally {
      await client.disconnect();
    }

    // Write manifest
    final manifest = {
      'timestamp': DateTime.now().toIso8601String(),
      'mac': mac,
      'windowDays': windowDays,
      'since': since.toIso8601String(),
      'battery': client.batteryPercent,
      'totalBytes': totalBytes,
      'nonEmptyCodes': codeBytes.length,
      'codes': codeBytes,
    };
    final manifestFile = File(p.join(dumpDir.path, 'manifest.json'));
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    sw.stop();
    log('Dump complete: ${codeBytes.length} types, '
        '${(totalBytes / 1024).toStringAsFixed(1)} KB in '
        '${sw.elapsed.inSeconds}s');

    return DumpResult(
      dumpDir: dumpDir.path,
      codeBytes: codeBytes,
      totalBytes: totalBytes,
      elapsed: sw.elapsed,
    );
  }
}
