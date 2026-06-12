import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/band_link.dart';
import 'package:heliolytics/core/ble/cloud_upload.dart';
import 'package:heliolytics/core/ble/sync_refetch_runner.dart';
import 'package:heliolytics/core/ble/sync_coverage_resolver.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/models.dart';
import 'package:heliolytics/core/utils/logger.dart';
import 'package:heliolytics/features/cloud_sync/domain/models/sync_payload.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
class SyncOrchestrator extends Notifier<SessionSnapshot> {
  late AuthKeyStorage _authStorage;
  SessionStore? _store;
  bool _connecting = false;
  bool _autoConnectScheduled = false;
  final List<String> _logs = [];
  final List<TypeCodeResult> _results = [];
  SyncPayload? _lastPayload;

  @override
  SessionSnapshot build() {
    _authStorage = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    _initAsync();
    return SessionSnapshot.initial;
  }

  // ── logging ──────────────────────────────────────────────────────────────
  // Called from the BLE async chain — only appends, never touches Riverpod state.
  // Riverpod state is updated in bulk at safe checkpoints via _flush().
  void _log(String msg) {
    final ts = DateTime.now();
    final tsStr =
        '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}';
    _logs.add('[$tsStr] $msg');
    appLog(msg);
  }

  void _flush() {
    state = state.copyWith(logs: List.unmodifiable(_logs));
  }

  // ── init ─────────────────────────────────────────────────────────────────
  Future<void> _initAsync() async {
    _store = await ref.read(sessionStoreProvider.future);
    final hasKey = await _authStorage.hasKey();
    state = state.copyWith(
      state: hasKey ? SessionState.idle : SessionState.noAuthKey,
    );
    _log('App initialized. Auth key: ${hasKey ? "present" : "missing"}');
    _flush();
  }

  // ── public API ────────────────────────────────────────────────────────────
  Future<void> saveAuthKey(String key) async {
    await _authStorage.save(key);
    state = state.copyWith(state: SessionState.idle);
    _log('Auth key saved');
    _flush();
  }

  Future<void> clearAuthKey() async {
    await _authStorage.clear();
    _logs.clear();
    _results.clear();
    state = state.copyWith(state: SessionState.noAuthKey, logs: [], typeResults: []);
  }

  Future<void> connect() async {
    if (state.state != SessionState.idle &&
        state.state != SessionState.error) {
      return;
    }
    if (_connecting) return;
    _connecting = true;
    if (state.state == SessionState.error) {
      state = state.copyWith(state: SessionState.idle, error: SessionError.none);
    }

    final mac = await _authStorage.readMac();
    if (mac == null || mac.isEmpty) {
      _log('ERROR: No MAC saved. Please scan first.');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.scanFailed,
        lastErrorMessage: 'No strap MAC saved.',
      );
      _flush();
      _connecting = false;
      return;
    }

    if (!await ref.read(apiConfiguredProvider.future)) {
      _log('Connect skipped: configure Cloud API in Settings first');
      state = state.copyWith(
        state: SessionState.error,
        lastErrorMessage: cloudApiRequiredBeforeSyncMessage,
      );
      _flush();
      _connecting = false;
      return;
    }

    await _run(mac);
    _connecting = false;
  }

  Future<void> saveAuthKeyAndMac(String key, String mac) async {
    await _authStorage.save(key);
    await _authStorage.saveMac(mac);
    state = state.copyWith(state: SessionState.idle);
  }

  Future<void> saveMacAndConnect(String mac) async {
    await _authStorage.saveMac(mac);
    await connect();
  }

  Future<bool> hasSavedMac() => _authStorage.hasMac();

  /// Called once when the main shell opens — connects and syncs incrementally.
  Future<void> scheduleAutoConnect() async {
    if (_autoConnectScheduled) return;
    _autoConnectScheduled = true;
    if (!await _authStorage.hasKey()) return;
    if (!await hasSavedMac()) return;
    if (state.state != SessionState.idle) return;
    if (_connecting) return;
    if (!await ref.read(apiConfiguredProvider.future)) {
      _log('Auto-sync skipped: configure Cloud API in Settings first');
      _flush();
      return;
    }
    _log('Auto-sync: connecting to saved strap');
    _flush();
    await connect();
  }

  SyncPayload? get lastPayload => _lastPayload;

  Future<void> retryLastUpload() async {
    final p = _lastPayload;
    if (p == null) throw StateError('No session in memory — sync first');
    try {
      await tryCloudUpload(ref, p, _log);
    } catch (e) {
      state = state.copyWith(
        state: SessionState.error,
        lastErrorMessage: 'Cloud upload failed: $e',
      );
      _flush();
      rethrow;
    }
    _flush();
  }

  Future<void> refetchType(String codeStr) async {
    if (_connecting ||
        state.state == SessionState.fetching ||
        state.state == SessionState.connecting) {
      return;
    }
    final store = _store;
    if (store == null) return;

    if (!await ref.read(apiConfiguredProvider.future)) {
      _log('Refetch skipped: configure Cloud API in Settings first');
      state = state.copyWith(
        state: SessionState.error,
        lastErrorMessage: cloudApiRequiredBeforeSyncMessage,
      );
      _flush();
      return;
    }

    _connecting = true;
    state = state.copyWith(
      state: SessionState.connecting,
      currentTypeCode: codeStr,
      error: SessionError.none,
    );
    _log('→ refetch $codeStr only (per-type coverage)');
    _flush();

    state = state.copyWith(state: SessionState.fetching);
    _flush();

    try {
      final plan = await resolveSyncFetchSince(ref);
      final since = plan.since;
      final result = await SyncRefetchRunner(_log).run(
        _authStorage,
        codeStr,
        since: since,
      );
      if (result != null) {
        final entry = result.entry;
        _log('✓ refetch $codeStr: ${entry.bytes} bytes (${entry.status.name})');
        final base = _lastPayload ??
            await _payloadFromLastMeta(store, await store.latestSessionId());
        if (base != null && result.raw.isNotEmpty) {
          final payload = SyncPayload(
            session: base.session,
            catalog: SessionCatalog(
              sessionId: base.session.sessionId,
              chunked: [entry],
              unsolicited: const [],
            ),
            rawByCode: {codeStr: result.raw},
          );
          _lastPayload = payload;
          try {
            await tryCloudUpload(ref, payload, _log);
          } catch (e) {
            state = state.copyWith(
              state: SessionState.error,
              lastErrorMessage: 'Cloud upload failed: $e',
            );
          }
        }
        final sid = await store.latestSessionId();
        if (sid != null) {
          state = state.copyWith(lastSession: await store.readSessionJson(sid));
        }
      } else {
        _log('✗ refetch $codeStr failed');
        state = state.copyWith(
          state: SessionState.error,
          error: SessionError.scanFailed,
          lastErrorMessage: 'Refetch $codeStr failed',
        );
      }
    } catch (e) {
      _log('✗ refetch $codeStr: $e');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.scanFailed,
        lastErrorMessage: e.toString(),
      );
    } finally {
      state = state.copyWith(state: SessionState.idle, currentTypeCode: null);
      _flush();
      _connecting = false;
    }
  }

  // ── main run loop ─────────────────────────────────────────────────────────
  Future<void> _run(String mac) async {
    final authKey = await _authStorage.readBytes();
    if (authKey == null) {
      _log('No auth key stored');
      _flush();
      return;
    }

    // ── BandLink: pure Dart, no Riverpod state inside ──────────────────
    final client = BandLink(_log);

    state = state.copyWith(state: SessionState.connecting);
    _log('→ connecting to $mac');
    _flush();

    final ok = await client.connectAndAuth(mac: mac, authKey: authKey);
    if (!ok) {
      _log('✗ connect/auth failed');
      state = state.copyWith(
        state: SessionState.error,
        error: SessionError.authRejected,
        lastErrorMessage: 'Connect or auth failed',
      );
      _flush();
      return;
    }

    // ── auth succeeded, fetcher is ready ──────────────────────────────────
    state = state.copyWith(state: SessionState.connected);
    _log('✓ auth done, fetcher ready');
    _flush();

    await _fetchAll(client, mac);
  }

  Future<void> _fetchAll(BandLink client, String mac) async {
    final store = _store;
    if (store == null) return;

    state = state.copyWith(state: SessionState.fetching);
    _results.clear();

    final plan = await resolveSyncFetchSince(ref);
    final since = plan.since;
    final dumpWindowHours = DateTime.now().difference(since).inHours.clamp(
      1,
      24 * initialSyncBackfillDays,
    );
    final sessionId = await store.createSession(
      deviceMac: mac,
      fetchWindowHours: dumpWindowHours,
      listenDurationSec: 0,
      mode: SessionMode.fetchAndListen,
    );

    _log(plan.logLine);
    if (plan.backendDataThrough != null) {
      final gap = DateTime.now().difference(plan.backendDataThrough!);
      _log('Gap to fill: ${gap.inHours}h ${gap.inMinutes.remainder(60)}m');
    }
    _log('Fetching ${fetchTypeCodes.length} types → upload to API');
    _flush();

    final entries = <DumpEntry>[];
    final rawByCode = <String, Uint8List>{};

    for (final codeStr in fetchTypeCodes) {
      final typeInt = int.parse(
        codeStr.startsWith('0x') ? codeStr.substring(2) : codeStr,
        radix: 16,
      );
      final label = typeCodeLabels[codeStr] ?? codeStr;
      state = state.copyWith(currentTypeCode: codeStr);
      _log('Fetching $codeStr ($label) ...');
      _flush();

      try {
        final fetchSince = resolveTypeFetchSince(
          typeCode: codeStr,
          defaultSince: since,
          types: plan.typeCoverage,
        );
        final typeLog = typeFetchLogLine(codeStr, fetchSince, since);
        if (typeLog.isNotEmpty) _log(typeLog);
        final result = await client.fetchCode(typeInt, fetchSince);
        final raw = result.raw;
        final expected = result.expected;
        final skipped = result.skipped;
        final roundStart = result.roundStart;
        final roundSegments = result.roundSegments;

        String status;
        String? rawHex;
        if (skipped) {
          status = 'skipped';
          _log('  ⚡ $codeStr: skipped ($expected pkts too large)');
        } else if (raw.isEmpty) {
          status = expected < 0 ? 'rejected' : 'empty';
          _log('  — $codeStr: ${expected < 0 ? "rejected" : "empty"}');
        } else {
          status = 'ok';
          final fullHex = raw.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          // Large types: keep first 512 hex chars (256 bytes) for format identification
          final previewLen = (raw.length > 1000) ? 512 : 128;
          rawHex = fullHex.length > previewLen
              ? fullHex.substring(0, previewLen)
              : fullHex;
          _log('  ✓ $codeStr: ${raw.length} bytes');
          _log('  hex[0]: ${rawHex.substring(0, rawHex.length.clamp(0, 64))}');
          if (rawHex.length > 64) _log('  hex[1]: ${rawHex.substring(64)}');
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
          roundStart: roundStart,
          roundSegments: roundSegments,
        );
        _results.add(TypeCodeResult(
          code: codeStr,
          label: label,
          status: status,
          bytes: raw.length,
          samples: raw.length ~/ 4,
          rawHex: rawHex,
        ));
        state = state.copyWith(typeResults: List.unmodifiable(_results));
        _flush();

        if (raw.isNotEmpty) {
          rawByCode[codeStr] = raw;
        }
        entries.add(entry);
      } catch (e) {
        _log('  ✗ $codeStr: ERROR — $e');
        _results.add(TypeCodeResult(
          code: codeStr, label: label, status: 'error', errorMsg: e.toString(),
        ));
        state = state.copyWith(typeResults: List.unmodifiable(_results));
        _flush();
        entries.add(DumpEntry(code: codeStr, status: DumpStatus.unknown, samples: 0, bytes: 0));
      }
    }

    final catalog = SessionCatalog(
      sessionId: sessionId,
      chunked: entries,
      unsolicited: const [],
    );
    await store.writeCatalogJson(catalog);

    final ok  = _results.where((r) => r.status == 'ok').length;
    final emp = _results.where((r) => r.status == 'empty').length;
    final rej = _results.where((r) => r.status == 'rejected').length;
    _log('═══ DONE ═══  $ok ok  $emp empty  $rej rejected');

    final ended = DateTime.now().toUtc();
    final base = await store.readSessionJson(sessionId);
    await store.writeSessionJson(Session(
      sessionId: base.sessionId,
      startedAt: base.startedAt,
      endedAt: ended,
      deviceMac: base.deviceMac,
      fetchWindowHours: base.fetchWindowHours,
      listenDurationSec: base.listenDurationSec,
      mode: base.mode,
      entries: base.entries,
      unsolicited: base.unsolicited,
      batteryPercent: client.batteryPercent,
    ));

    final session = await store.readSessionJson(sessionId);
    _lastPayload = SyncPayload(
      session: session,
      catalog: catalog,
      rawByCode: rawByCode,
    );

    state = state.copyWith(
      state: SessionState.idle,
      currentTypeCode: null,
      lastSession: session,
    );
    _flush();
    try {
      await tryCloudUpload(ref, _lastPayload!, _log);
      ref.invalidate(liveHealthProvider);
    } catch (e) {
      state = state.copyWith(
        state: SessionState.error,
        lastErrorMessage: 'Cloud upload failed: $e',
      );
    }
    _flush();
  }

  Future<SyncPayload?> _payloadFromLastMeta(
    SessionStore store,
    String? sessionId,
  ) async {
    if (sessionId == null) return null;
    final session = await store.readSessionJson(sessionId);
    return SyncPayload(
      session: session,
      catalog: SessionCatalog(
        sessionId: sessionId,
        chunked: const [],
        unsolicited: const [],
      ),
      rawByCode: const {},
    );
  }
}

final syncOrchestratorProvider =
    NotifierProvider<SyncOrchestrator, SessionSnapshot>(SyncOrchestrator.new);
