import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_alerts_call_pattern_provider.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/zepp/vibration_pattern_service.dart';
import 'package:heliolytics/utils/app_logger.dart';
import 'package:heliolytics/widgets/settings/vibration_pattern_form.dart';

class BandAlertsCallPatternScreen extends ConsumerStatefulWidget {
  const BandAlertsCallPatternScreen({super.key});

  @override
  ConsumerState<BandAlertsCallPatternScreen> createState() =>
      _BandAlertsCallPatternScreenState();
}

class _BandAlertsCallPatternScreenState
    extends ConsumerState<BandAlertsCallPatternScreen> {
  bool _busy = false;
  String? _error;

  void _log(String msg) =>
      AppLogger.instance.log(msg, tag: 'band_alerts_call_pattern_ui');

  Future<void> _withLink(Future<void> Function(BandLink link) run) async {
    final sync = ref.read(syncOrchestratorProvider);
    if (sync.state == SessionState.fetching ||
        sync.state == SessionState.connecting) {
      setState(() => _error = 'Wait for sync to finish');
      return;
    }
    final band = ref.read(bandSessionProvider.notifier);
    final alertsOn =
        ref.read(bandSessionProvider).activeOp == BandSessionOp.bandAlerts;
    if (!alertsOn) {
      final blocked = band.tryAcquire(BandSessionOp.motorProof);
      if (blocked != null) {
        setState(() => _error = blocked);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await band.ensureConnected()) {
        throw StateError(
          ref.read(bandSessionProvider).errorMessage ?? 'Connect failed',
        );
      }
      final link = band.session.link;
      if (link is! BandLink) throw StateError('No strap link');
      await run(link);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (!alertsOn) band.release(BandSessionOp.motorProof);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pattern = ref.watch(bandAlertsCallPatternProvider);

    return Scaffold(
      backgroundColor: HelioColors.canvas,
      appBar: AppBar(
        title: const Text('Call pattern'),
        backgroundColor: HelioColors.canvas,
      ),
      body: VibrationPatternForm(
        key: ValueKey(pattern.join(',')),
        initialMs: pattern,
        defaultMs: bandAlertsDefaultCallPatternMs,
        hint: 'Repeats while the phone is ringing.',
        busy: _busy,
        error: _error,
        onTest: (parsed) => _withLink((link) async {
          final ok = await VibrationPatternService(log: _log).testBuzz(
            link,
            type: vibrationTypeIncomingCall,
            onOffMs: parsed,
          );
          if (!ok) throw StateError('Pattern test send failed');
        }),
        onSave: (parsed) async {
          await ref.read(bandAlertsCallPatternProvider.notifier).setPattern(parsed);
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}
