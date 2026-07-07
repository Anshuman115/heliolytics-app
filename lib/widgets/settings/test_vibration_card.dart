import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/motor_proof_provider.dart';
import 'package:heliolytics/widgets/settings/settings_action_button.dart';

/// Motor proof via shared band session + find-device endpoint 0x001a.
class TestVibrationCard extends ConsumerWidget {
  const TestVibrationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proof = ref.watch(motorProofProvider);
    final band = ref.watch(bandSessionProvider);
    final busy = proof.isBusy;
    final err = proof.errorMessage;

    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test vibration',
            style: HelioTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: HelioSpacing.xs),
          Text(
            _subtitle(proof.phase, band.isConnected),
            style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
          ),
          if (err != null) ...[
            const SizedBox(height: HelioSpacing.sm),
            Text(
              err,
              style: HelioTypography.bodyMuted.copyWith(color: HelioColors.syncError),
            ),
          ],
          const SizedBox(height: HelioSpacing.md),
          SettingsActionButton(
            icon: Icons.vibration,
            label: _buttonLabel(proof.phase),
            color: const Color(0xFFFFB300),
            loading: busy,
            onTap: busy
                ? null
                : () => ref.read(motorProofProvider.notifier).runTestVibration(),
          ),
        ],
      ),
    );
  }

  String _subtitle(MotorProofPhase phase, bool bandConnected) {
    if (bandConnected && phase != MotorProofPhase.connecting) {
      return 'Strap connected — test should buzz right away.';
    }
    return switch (phase) {
      MotorProofPhase.connecting => 'Connecting to strap…',
      MotorProofPhase.buzzing => 'Strap should be buzzing now.',
      MotorProofPhase.done => 'Strap stays connected after sync.',
      MotorProofPhase.error => 'Buzzes the strap via find-device.',
      MotorProofPhase.idle =>
        'Uses the shared strap connection. Sync first for instant buzz.',
    };
  }

  String _buttonLabel(MotorProofPhase phase) => switch (phase) {
        MotorProofPhase.connecting => 'CONNECTING…',
        MotorProofPhase.buzzing => 'BUZZING…',
        MotorProofPhase.done => 'TEST AGAIN',
        _ => 'TEST',
      };
}
