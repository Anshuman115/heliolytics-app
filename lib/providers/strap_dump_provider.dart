import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/strap_dump_service.dart';
import 'package:share_plus/share_plus.dart';

/// State for the raw strap dump feature.
enum DumpPhase { idle, connecting, fetching, done, error }

class DumpState {
  final DumpPhase phase;
  final int currentIndex;
  final int totalCodes;
  final String currentCode;
  final int currentBytes;
  final String? dumpDir;
  final String? errorMessage;
  final List<String> logs;
  final Map<String, int> codeBytes;

  const DumpState({
    this.phase = DumpPhase.idle,
    this.currentIndex = 0,
    this.totalCodes = 255,
    this.currentCode = '',
    this.currentBytes = 0,
    this.dumpDir,
    this.errorMessage,
    this.logs = const [],
    this.codeBytes = const {},
  });

  double get progress =>
      totalCodes > 0 ? (currentIndex + 1) / totalCodes : 0.0;

  DumpState copyWith({
    DumpPhase? phase,
    int? currentIndex,
    int? totalCodes,
    String? currentCode,
    int? currentBytes,
    String? dumpDir,
    String? errorMessage,
    List<String>? logs,
    Map<String, int>? codeBytes,
  }) =>
      DumpState(
        phase: phase ?? this.phase,
        currentIndex: currentIndex ?? this.currentIndex,
        totalCodes: totalCodes ?? this.totalCodes,
        currentCode: currentCode ?? this.currentCode,
        currentBytes: currentBytes ?? this.currentBytes,
        dumpDir: dumpDir ?? this.dumpDir,
        errorMessage: errorMessage ?? this.errorMessage,
        logs: logs ?? this.logs,
        codeBytes: codeBytes ?? this.codeBytes,
      );
}

class StrapDumpNotifier extends Notifier<DumpState> {
  final _logs = <String>[];

  @override
  DumpState build() => const DumpState();

  void _log(String msg) {
    _logs.add(msg);
    // No trim — keep ALL logs for diagnostics
  }

  Future<void> startDump() async {
    if (state.phase == DumpPhase.fetching) return;

    _logs.clear();
    state = const DumpState(phase: DumpPhase.connecting);

    try {
      final auth = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
      final mac = await auth.readMac();
      final key = await auth.readBytes();

      if (mac == null || key == null) {
        state = state.copyWith(
          phase: DumpPhase.error,
          errorMessage: 'No strap paired. Sync first.',
        );
        return;
      }

      state = state.copyWith(phase: DumpPhase.fetching);

      final service = StrapDumpService(log: _log);
      final result = await service.runDump(
        mac: mac,
        authKey: key,
        windowDays: 2,
        onProgress: (index, total, code, bytes) {
          state = state.copyWith(
            currentIndex: index,
            totalCodes: total,
            currentCode: code,
            currentBytes: bytes,
            logs: List.of(_logs),
          );
        },
      );

      // Save full log to file in the dump directory
      await _saveLogFile(result.dumpDir);

      state = state.copyWith(
        phase: DumpPhase.done,
        dumpDir: result.dumpDir,
        codeBytes: result.codeBytes,
        logs: List.of(_logs),
      );
    } catch (e) {
      _log('ERROR: $e');
      state = state.copyWith(
        phase: DumpPhase.error,
        errorMessage: e.toString(),
        logs: List.of(_logs),
      );
    }
  }

  /// Write full log to dump_log.txt in the dump directory.
  Future<void> _saveLogFile(String dumpDir) async {
    try {
      final logFile = File('$dumpDir/dump_log.txt');
      await logFile.writeAsString(_logs.join('\n'));
      _log('Logs saved to dump_log.txt');
    } catch (e) {
      _log('Failed to save log file: $e');
    }
  }

  Future<void> shareDump() async {
    final dir = state.dumpDir;
    if (dir == null) return;

    final files = Directory(dir)
        .listSync()
        .whereType<File>()
        .map((f) => XFile(f.path))
        .toList();

    if (files.isEmpty) return;

    await Share.shareXFiles(
      files,
      text: 'Heliolytics raw strap dump',
    );
  }

  /// Share ONLY the log (works even if dump failed/partial).
  Future<void> shareLogs() async {
    final dir = state.dumpDir;

    // If we have a dump dir, save and share from there
    if (dir != null) {
      await _saveLogFile(dir);
      final logFile = File('$dir/dump_log.txt');
      if (await logFile.exists()) {
        await Share.shareXFiles(
          [XFile(logFile.path)],
          text: 'Heliolytics dump log',
        );
        return;
      }
    }

    // Fallback: share logs as text if no dump dir yet
    if (_logs.isNotEmpty) {
      await Share.share(_logs.join('\n'), subject: 'Heliolytics dump log');
    }
  }

  void reset() {
    _logs.clear();
    state = const DumpState();
  }
}

final strapDumpProvider =
    NotifierProvider<StrapDumpNotifier, DumpState>(StrapDumpNotifier.new);
