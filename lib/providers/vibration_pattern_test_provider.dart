import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/services/ble/zepp/vibration_pattern_service.dart';
import 'package:heliolytics/utils/app_logger.dart';

enum VibrationPatternTestPhase { idle, connecting, buzzing, done, error }

class VibrationPatternTestState {
  final VibrationPatternTestPhase phase;
  final String? errorMessage;

  const VibrationPatternTestState({
    this.phase = VibrationPatternTestPhase.idle,
    this.errorMessage,
  });

  bool get isBusy =>
      phase == VibrationPatternTestPhase.connecting ||
      phase == VibrationPatternTestPhase.buzzing;
}

class VibrationPatternTestNotifier extends Notifier<VibrationPatternTestState> {
  @override
  VibrationPatternTestState build() => const VibrationPatternTestState();

  void _log(String msg) =>
      AppLogger.instance.log(msg, tag: 'vibration_pattern_test');

  Future<void> runTest() async {
    if (state.isBusy) return;

    final sync = ref.read(syncOrchestratorProvider);
    if (sync.state == SessionState.fetching ||
        sync.state == SessionState.connecting) {
      state = const VibrationPatternTestState(
        phase: VibrationPatternTestPhase.error,
        errorMessage: 'Wait for sync to finish',
      );
      return;
    }

    final band = ref.read(bandSessionProvider.notifier);
    final alertsOn =
        ref.read(bandSessionProvider).activeOp == BandSessionOp.bandAlerts;
    if (!alertsOn) {
      final blocked = band.tryAcquire(BandSessionOp.motorProof);
      if (blocked != null) {
        state = VibrationPatternTestState(
          phase: VibrationPatternTestPhase.error,
          errorMessage: blocked,
        );
        return;
      }
    }

    state = const VibrationPatternTestState(
      phase: VibrationPatternTestPhase.connecting,
    );

    try {
      if (!await band.ensureConnected()) {
        throw StateError(
          ref.read(bandSessionProvider).errorMessage ?? 'Connect failed',
        );
      }

      final link = band.session.link;
      if (link == null) throw StateError('No strap link');

      state = const VibrationPatternTestState(
        phase: VibrationPatternTestPhase.buzzing,
      );
      final ok = await VibrationPatternService(log: _log).testBuzz(
        link,
        type: vibrationTypeAppAlerts,
        onOffMs: const [300, 600],
      );
      if (!ok) throw StateError('Pattern test send failed');

      state = const VibrationPatternTestState(
        phase: VibrationPatternTestPhase.done,
      );
    } catch (e) {
      _log('ERROR: $e');
      state = VibrationPatternTestState(
        phase: VibrationPatternTestPhase.error,
        errorMessage: e.toString(),
      );
    } finally {
      if (!alertsOn) band.release(BandSessionOp.motorProof);
    }
  }
}

final vibrationPatternTestProvider = NotifierProvider<
    VibrationPatternTestNotifier, VibrationPatternTestState>(
  VibrationPatternTestNotifier.new,
);
