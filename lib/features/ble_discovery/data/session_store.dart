import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/constants.dart' show appDocsSubdir;
import 'package:heliolytics/core/ble/sync_session_port.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final sessionStoreProvider = FutureProvider<SessionStore>((ref) async {
  final root = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(root.path, appDocsSubdir));
  if (!dir.existsSync()) await dir.create(recursive: true);
  return SessionStore(rootDir: dir);
});

class SessionStore implements SyncSessionPort {
  final Directory rootDir;
  SessionStore({required this.rootDir});

  Directory _sessionDir(String id) =>
      Directory(p.join(rootDir.path, 'sessions', id));

  /// Matches catalog `DumpEntry.file` (e.g. `0x01_raw.bin`).
  String _binFileName(String code) => '${code}_raw.bin';

  Future<String> createSession({
    required String? deviceMac,
    required int fetchWindowHours,
    required int listenDurationSec,
    required SessionMode mode,
  }) async {
    final id = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
    final dir = _sessionDir(id);
    await dir.create(recursive: true);
    final s = Session(
      sessionId: id,
      startedAt: DateTime.now().toUtc(),
      deviceMac: deviceMac,
      fetchWindowHours: fetchWindowHours,
      listenDurationSec: listenDurationSec,
      mode: mode,
      entries: const [],
      unsolicited: const [],
    );
    await writeSessionJson(s);
    return id;
  }

  Future<void> appendBytes(
    String sessionId,
    String typeCode,
    List<int> bytes,
  ) async {
    final f = File(p.join(_sessionDir(sessionId).path, _binFileName(typeCode)));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, mode: FileMode.append, flush: true);
  }

  Future<void> writeTypeBytes(
    String sessionId,
    String typeCode,
    List<int> bytes,
  ) async {
    final f = File(p.join(_sessionDir(sessionId).path, _binFileName(typeCode)));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
  }

  Future<String?> latestSessionId() async {
    final ids = await listSessions();
    return ids.isEmpty ? null : ids.first;
  }

  Future<void> writeSessionJson(Session s) async {
    final f = File(p.join(_sessionDir(s.sessionId).path, 'session.json'));
    await f.writeAsString(jsonEncode(s.toJson()), flush: true);
  }

  Future<Session> readSessionJson(String sessionId) async {
    final f = File(p.join(_sessionDir(sessionId).path, 'session.json'));
    final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final c = await _readCatalogIfPresent(sessionId);
    return Session(
      sessionId: m['sessionId'] as String,
      startedAt: DateTime.parse(m['startedAt'] as String),
      endedAt:
          m['endedAt'] != null ? DateTime.parse(m['endedAt'] as String) : null,
      deviceMac: m['deviceMac'] as String?,
      fetchWindowHours: (m['fetchWindowHours'] as num).toInt(),
      listenDurationSec: (m['listenDurationSec'] as num).toInt(),
      mode: SessionModeX.parse(m['mode'] as String),
      entries: c?.chunked ?? const [],
      unsolicited: c?.unsolicited ?? const [],
      batteryPercent: (m['batteryPercent'] as num?)?.toInt(),
    );
  }

  Future<SessionCatalog?> _readCatalogIfPresent(String sessionId) async {
    final f = File(p.join(_sessionDir(sessionId).path, 'types.json'));
    if (!f.existsSync()) return null;
    return SessionCatalog.fromJson(
        jsonDecode(await f.readAsString()) as Map<String, dynamic>);
  }

  Future<void> writeCatalogJson(SessionCatalog c) async {
    final f = File(p.join(_sessionDir(c.sessionId).path, 'types.json'));
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(c.toJson()), flush: true);
    await tmp.rename(f.path);
  }

  Future<SessionCatalog> readCatalogJson(String sessionId) async {
    final c = await _readCatalogIfPresent(sessionId);
    if (c == null) {
      throw StateError('No types.json for session $sessionId');
    }
    return c;
  }

  Future<Uint8List?> readTypeBytes(String sessionId, String typeCode) async {
    final f = File(p.join(_sessionDir(sessionId).path, _binFileName(typeCode)));
    if (!f.existsSync()) return null;
    return f.readAsBytes();
  }

  Future<List<String>> listSessions() async {
    final dir = Directory(p.join(rootDir.path, 'sessions'));
    if (!dir.existsSync()) return [];
    final ids = dir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList();
    ids.sort((a, b) => b.compareTo(a));
    return ids;
  }
}
