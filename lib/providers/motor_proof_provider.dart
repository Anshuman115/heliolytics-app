import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/services/ble/find_device_service.dart';
import 'package:heliolytics/utils/app_logger.dart';

enum MotorProofPhase { idle, connecting, buzzing, done, error }

class MotorProofState {
  final MotorProofPhase phase;
  final String? errorMessage;
  final List<String> logs;

  const MotorProofState({
    this.phase = MotorProofPhase.idle,
    this.errorMessage,
    this.logs = const [],
  });

  bool get isBusy =>
      phase == MotorProofPhase.connecting || phase == MotorProofPhase.buzzing;

  MotorProofState copyWith({
    MotorProofPhase? phase,
    String? errorMessage,
    List<String>? logs,
  }) =>
      MotorProofState(
        phase: phase ?? this.phase,
        errorMessage: errorMessage,
        logs: logs ?? this.logs,
      );
}

class MotorProofNotifier extends Notifier<MotorProofState> {
  final _logs = <String>[];

  @override
  MotorProofState build() => const MotorProofState();

  void _log(String msg) {
    _logs.add(msg);
    AppLogger.instance.log(msg, tag: 'motor_proof');
  }

  Future<void> runTestVibration() async {
    if (state.isBusy) return;

    final sync = ref.read(syncOrchestratorProvider);
    if (sync.state == SessionState.fetching ||
        sync.state == SessionState.connecting) {
      state = MotorProofState(
        phase: MotorProofPhase.error,
        errorMessage: 'Wait for sync to finish',
        logs: List.of(_logs),
      );
      return;
    }

    final band = ref.read(bandSessionProvider.notifier);
    final blocked = band.tryAcquire(BandSessionOp.motorProof);
    if (blocked != null) {
      state = MotorProofState(
        phase: MotorProofPhase.error,
        errorMessage: blocked,
        logs: List.of(_logs),
      );
      return;
    }

    _logs.clear();
    final wasConnected = ref.read(bandSessionProvider).isConnected;
    state = const MotorProofState(phase: MotorProofPhase.connecting);

    try {
      if (!await band.ensureConnected()) {
        throw StateError(
          ref.read(bandSessionProvider).errorMessage ?? 'Connect failed',
        );
      }

      final link = band.session.link;
      if (link == null) throw StateError('No strap link');

      await FindDeviceService(log: _log).buzz(
        link,
        onProgress: (step) {
          state = state.copyWith(
            phase: step == MotorProofStep.connecting
                ? MotorProofPhase.connecting
                : MotorProofPhase.buzzing,
            logs: List.of(_logs),
          );
        },
        requestCapabilities: !wasConnected,
      );

      state = MotorProofState(phase: MotorProofPhase.done, logs: List.of(_logs));
    } catch (e) {
      _log('ERROR: $e');
      state = MotorProofState(
        phase: MotorProofPhase.error,
        errorMessage: e.toString(),
        logs: List.of(_logs),
      );
    } finally {
      band.release(BandSessionOp.motorProof);
    }
  }

  void reset() {
    _logs.clear();
    state = const MotorProofState();
  }
}

final motorProofProvider =
    NotifierProvider<MotorProofNotifier, MotorProofState>(MotorProofNotifier.new);
