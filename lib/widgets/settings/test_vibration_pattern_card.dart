import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/vibration_pattern_test_provider.dart';
import 'package:heliolytics/widgets/settings/settings_action_button.dart';

/// Motor proof via vibration-pattern endpoint 0x0018 (test buzz flag).
class TestVibrationPatternCard extends ConsumerWidget {
  const TestVibrationPatternCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final test = ref.watch(vibrationPatternTestProvider);
    final band = ref.watch(bandSessionProvider);
    final busy = test.isBusy;
    final err = test.errorMessage;

    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test pattern (0x0018)',
            style: HelioTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: HelioSpacing.xs),
          Text(
            _subtitle(test.phase, band.isConnected),
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
            icon: Icons.waves,
            label: _buttonLabel(test.phase),
            color: const Color(0xFF7E57C2),
            loading: busy,
            onTap: busy
                ? null
                : () =>
                    ref.read(vibrationPatternTestProvider.notifier).runTest(),
          ),
        ],
      ),
    );
  }

  String _subtitle(VibrationPatternTestPhase phase, bool bandConnected) {
    if (bandConnected && phase != VibrationPatternTestPhase.connecting) {
      return 'App-alert pattern: 300ms on, 600ms off.';
    }
    return switch (phase) {
      VibrationPatternTestPhase.connecting => 'Connecting to strap…',
      VibrationPatternTestPhase.buzzing => 'Sending pattern test buzz…',
      VibrationPatternTestPhase.done => 'If no buzz, Helio may not support 0x0018.',
      VibrationPatternTestPhase.error => 'Encrypted pattern test on endpoint 0x0018.',
      VibrationPatternTestPhase.idle =>
        'Try-vibration flag — separate from find-device 0x001a.',
    };
  }

  String _buttonLabel(VibrationPatternTestPhase phase) => switch (phase) {
        VibrationPatternTestPhase.connecting => 'CONNECTING…',
        VibrationPatternTestPhase.buzzing => 'TESTING…',
        VibrationPatternTestPhase.done => 'TEST AGAIN',
        _ => 'TEST PATTERN',
      };
}
