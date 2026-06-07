import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/ble_devices.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/band_link.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/models.dart';

class SyncOrchestrator extends Notifier<SessionSnapshot> {
  late AuthKeyStorage _authStorage;
  SessionStore? _store;
  BandLink? _client;
  bool _connecting = false;
  final List<String> _logs = [];
  final List<TypeCodeResult> _results = [];

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
    // ignore: avoid_print
    print(msg);
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
        state.state != SessionState.error) return;
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
    _client = client;

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

    const dumpWindowHours = 24 * 30; // 30 days
    final sessionId = await store.createSession(
      deviceMac: mac,
      fetchWindowHours: dumpWindowHours,
      listenDurationSec: 0,
      mode: SessionMode.fetchAndListen,
    );

    final since = DateTime.now().subtract(const Duration(days: 30));
    _log('DUMP: last 30 days since ${since.toIso8601String()}');
    _log('Fetching ${allTypeCodes.length} codes (all 0x01-0x7F)...');
    _flush();

    final entries = <DumpEntry>[];

    for (final codeStr in allTypeCodes) {
      final typeInt = int.parse(
        codeStr.startsWith('0x') ? codeStr.substring(2) : codeStr,
        radix: 16,
      );
      final label = typeCodeLabels[codeStr] ?? codeStr;
      state = state.copyWith(currentTypeCode: codeStr);
      _log('Fetching $codeStr ($label) ...');
      _flush();

      try {
        // Per-code caps and windows
        // 0x06: sports details — 166k pkts, no probe (probe corrupts stream)
        // 0x58: raw PPG — try 6h window (48h window gets status 0x05 rejection)
        final int cap = switch (codeStr) {
          '0x06' => 200000,
          '0x58' => 1000000,
          _ => 50000,
        };
        final int rounds = codeStr == '0x58' ? 1 : 400;
        // 0x58 uses a shorter window — PPG likely only stores last few hours
        final DateTime codeSince = codeStr == '0x58'
            ? DateTime.now().subtract(const Duration(hours: 6))
            : since;
        final result = await client.fetchCode(typeInt, codeSince,
            maxExpected: cap, maxRounds: rounds);
        final raw = result.raw;
        final expected = result.expected;
        final skipped = result.skipped;

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
          await store.appendBytes(sessionId, codeStr, raw);
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

    await store.writeCatalogJson(SessionCatalog(
      sessionId: sessionId,
      chunked: entries,
      unsolicited: const [],
    ));

    final ok  = _results.where((r) => r.status == 'ok').length;
    final emp = _results.where((r) => r.status == 'empty').length;
    final rej = _results.where((r) => r.status == 'rejected').length;
    _log('═══ DONE ═══  $ok ok  $emp empty  $rej rejected');

    state = state.copyWith(
      state: SessionState.idle,
      currentTypeCode: null,
      lastSession: await store.readSessionJson(sessionId),
    );
    _flush();
  }
}

final syncOrchestratorProvider =
    NotifierProvider<SyncOrchestrator, SessionSnapshot>(SyncOrchestrator.new);
