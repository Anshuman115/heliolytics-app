import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/components/helio_wizard_step_header.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';

class SetupConnectScreen extends ConsumerStatefulWidget {
  const SetupConnectScreen({super.key});

  @override
  ConsumerState<SetupConnectScreen> createState() => _SetupConnectScreenState();
}

class _SetupConnectScreenState extends ConsumerState<SetupConnectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  Future<void> _connect() => ref.read(syncOrchestratorProvider.notifier).connect();

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(syncOrchestratorProvider);
    ref.listen(syncOrchestratorProvider, (prev, next) {
      if (next.state == SessionState.connected) context.push('/setup/backfill-days');
    });

    return Scaffold(
      appBar: const HelioTopBar(showBack: true),
      body: Padding(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HelioWizardStepHeader(step: 4, totalSteps: 5, title: 'Connecting'),
            const SizedBox(height: HelioSpacing.xl),
            _step('Connecting', snap.state.index >= SessionState.connecting.index),
            _step('Authenticating', snap.state.index >= SessionState.authenticating.index),
            _step('Connected', snap.state == SessionState.connected),
            if (snap.state == SessionState.error) ...[
              const SizedBox(height: HelioSpacing.lg),
              Text(
                snap.lastErrorMessage ?? 'Connection failed',
                style: HelioTypography.bodyMuted,
              ),
              const SizedBox(height: HelioSpacing.md),
              HelioPrimaryButton(label: 'Retry', onPressed: _connect),
            ],
          ],
        ),
      ),
    );
  }

  Widget _step(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? HelioColors.optimalGreen : HelioColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: HelioSpacing.md),
          Text(label, style: HelioTypography.body),
        ],
      ),
    );
  }
}
