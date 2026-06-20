import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/utils/app_logger.dart';

class LiveHrSample {
  final int bpm;
  final DateTime at;

  const LiveHrSample({required this.bpm, required this.at});
}

class LiveHrState {
  final int? bpm;
  final bool isLive;
  final bool isConnecting;
  final DateTime? sampledAt;
  final List<LiveHrSample> recentSamples;

  const LiveHrState({
    this.bpm,
    this.isLive = false,
    this.isConnecting = false,
    this.sampledAt,
    this.recentSamples = const [],
  });

  LiveHrState copyWith({
    int? bpm,
    bool? isLive,
    bool? isConnecting,
    DateTime? sampledAt,
    List<LiveHrSample>? recentSamples,
    bool clearBpm = false,
  }) =>
      LiveHrState(
        bpm: clearBpm ? null : (bpm ?? this.bpm),
        isLive: isLive ?? this.isLive,
        isConnecting: isConnecting ?? this.isConnecting,
        sampledAt: sampledAt ?? this.sampledAt,
        recentSamples: recentSamples ?? this.recentSamples,
      );
}

final liveHrProvider = NotifierProvider<LiveHrNotifier, LiveHrState>(
  LiveHrNotifier.new,
);

class LiveHrNotifier extends Notifier<LiveHrState> {
  BandLinkPort? _link;
  StreamSubscription<int>? _bpmSub;

  void _log(String message) =>
      AppLogger.instance.log(message, tag: 'live_hr');

  @override
  LiveHrState build() => const LiveHrState();

  Future<void> startMonitoring() async {
    if (state.isLive || state.isConnecting || _link != null) return;

    final sync = ref.read(syncOrchestratorProvider);
    if (sync.state == SessionState.fetching ||
        sync.state == SessionState.connecting) {
      _log('skipped — sync in progress');
      return;
    }

    final auth = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    final mac = await auth.readMac();
    final authKey = await auth.readBytes();
    if (mac == null || mac.isEmpty || authKey == null) {
      _log('skipped — no strap paired');
      return;
    }

    state = state.copyWith(isConnecting: true);
    final link = BandLink(_log);
    _link = link;

    final ok = await link.connectAndAuth(mac: mac, authKey: authKey);
    if (!ok) {
      _log('connect/auth failed');
      await _tearDown();
      state = const LiveHrState();
      return;
    }

    await link.startLiveHeartRate();
    final stream = link.liveBpmStream;
    if (stream == null) {
      await _tearDown();
      state = const LiveHrState();
      return;
    }

    _bpmSub = stream.listen(_onBpm);
    state = state.copyWith(isLive: true, isConnecting: false);
    _log('monitoring started');
  }

  void _onBpm(int bpm) {
    final at = DateTime.now();
    final next = [...state.recentSamples, LiveHrSample(bpm: bpm, at: at)];
    if (next.length > liveHrSampleBufferMax) {
      next.removeRange(0, next.length - liveHrSampleBufferMax);
    }
    state = state.copyWith(bpm: bpm, sampledAt: at, recentSamples: next);
  }

  Future<void> stopMonitoring() async {
    await _tearDown();
    state = const LiveHrState();
    _log('monitoring stopped');
  }

  Future<void> _tearDown() async {
    await _bpmSub?.cancel();
    _bpmSub = null;
    final link = _link;
    _link = null;
    if (link == null) return;
    try {
      await link.stopLiveHeartRate();
    } catch (_) {}
    try {
      await link.disconnect();
    } catch (_) {}
  }
}
