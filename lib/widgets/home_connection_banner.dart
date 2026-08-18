import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/onboarding_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';

class HomeConnectionBanner extends ConsumerWidget {
  const HomeConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(bandSessionProvider);
    final sync = ref.watch(syncOrchestratorProvider);
    final name = ref.watch(onboardingProvider).profile?.name.trim();
    final busy = {
      SessionState.connecting,
      SessionState.authenticating,
      SessionState.fetching,
      SessionState.scanning,
    }.contains(sync.state);
    final connected =
        session.isConnected || sync.state == SessionState.connected;
    final prefix = name == null || name.isEmpty
        ? 'HELIO STRAP'
        : '${name.toUpperCase()} HELIO STRAP';
    final label = connected ? '$prefix CONNECTED' : '$prefix NOT CONNECTED';
    final color = busy || connected
        ? HelioColors.optimalGreen
        : HelioColors.textMuted;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HelioColors.border),
      ),
      child: Row(
        children: [
          Icon(
            busy ? Icons.sync : Icons.watch_outlined,
            color: HelioColors.textPrimary,
            size: 24,
          ),
          const SizedBox(width: HelioSpacing.md),
          Expanded(
            child: Text(
              label,
              style: HelioTypography.capsLabel.copyWith(
                color: HelioColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (busy)
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(color: color, strokeWidth: 2),
            )
          else
            Icon(Icons.done_all, color: color, size: 28),
        ],
      ),
    );
  }
}
