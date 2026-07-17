import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:heliolytics/constants/constants.dart';

/// Persists log events as JSON-lines across [logFileCount] rotating files,
/// each capped at [logFileMaxBytes]. Every method is best-effort: disk I/O
/// failures are swallowed, never thrown, since logging must never crash
/// the app or block a caller.
class LogFileStore {
  Directory? _dir;

  Future<Directory> _logDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$logFileDirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  File _fileFor(Directory dir, int index) =>
      File('${dir.path}/$logFilePrefix$index$logFileExtension');

  Future<void> append(String jsonLine) async {
    try {
      final dir = await _logDir();
      final active = _fileFor(dir, 0);
      if (await active.exists() && await active.length() >= logFileMaxBytes) {
        await _rotate(dir);
      }
      await active.writeAsString('$jsonLine\n', mode: FileMode.append, flush: false);
    } catch (_) {
      // Best-effort — a disk failure must never crash the app.
    }
  }

  Future<void> _rotate(Directory dir) async {
    for (var i = logFileCount - 1; i > 0; i--) {
      final from = _fileFor(dir, i - 1);
      final to = _fileFor(dir, i);
      if (await from.exists()) {
        if (await to.exists()) await to.delete();
        await from.rename(to.path);
      }
    }
  }

  Future<List<String>> readAllLines() async {
    try {
      final dir = await _logDir();
      final lines = <String>[];
      for (var i = logFileCount - 1; i >= 0; i--) {
        final file = _fileFor(dir, i);
        if (await file.exists()) {
          lines.addAll(await file.readAsLines());
        }
      }
      return lines;
    } catch (_) {
      return const [];
    }
  }
}
