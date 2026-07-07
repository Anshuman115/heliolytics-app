import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/services/ble/band_link.dart';
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
  StreamSubscription<int>? _bpmSub;

  void _log(String message) =>
      AppLogger.instance.log(message, tag: 'live_hr');

  @override
  LiveHrState build() => const LiveHrState();

  Future<void> startMonitoring() async {
    if (state.isLive || state.isConnecting) return;

    final sync = ref.read(syncOrchestratorProvider);
    if (sync.state == SessionState.fetching ||
        sync.state == SessionState.connecting) {
      _log('skipped — sync in progress');
      return;
    }

    final band = ref.read(bandSessionProvider.notifier);
    final blocked = band.tryAcquire(BandSessionOp.liveHr);
    if (blocked != null) {
      _log('skipped — $blocked');
      return;
    }

    state = state.copyWith(isConnecting: true);

    try {
      if (!await band.ensureConnected()) {
        _log('connect failed');
        return;
      }

      final link = band.session.link;
      if (link is! BandLink) {
        _log('invalid link type');
        return;
      }

      await link.startLiveHeartRate();
      final stream = link.liveBpmStream;
      if (stream == null) return;

      _bpmSub = stream.listen(_onBpm);
      state = state.copyWith(isLive: true, isConnecting: false);
      _log('monitoring started');
    } catch (e) {
      _log('start failed: $e');
    } finally {
      if (!state.isLive) {
        state = const LiveHrState();
        band.release(BandSessionOp.liveHr);
      }
    }
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
    final band = ref.read(bandSessionProvider.notifier);
    final link = band.session.link;
    if (link is BandLink) {
      try {
        await link.stopLiveHeartRate();
      } catch (_) {}
    }
    band.release(BandSessionOp.liveHr);
  }
}
