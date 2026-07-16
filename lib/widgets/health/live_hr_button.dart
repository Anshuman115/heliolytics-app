import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/live_hr_provider.dart';

/// Top-bar toggle that starts/stops the live heart-rate stream.
class LiveHrButton extends ConsumerWidget {
  final LiveHrState live;

  const LiveHrButton({super.key, required this.live});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (live.isConnecting) {
      return const Padding(
        padding: EdgeInsets.only(right: HelioSpacing.md),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HelioColors.recoveryLow,
          ),
        ),
      );
    }

    final isLive = live.isLive;
    return GestureDetector(
      onTap: () {
        // ref.read, not a cached notifier — the provider may have rebuilt.
        final notifier = ref.read(liveHrProvider.notifier);
        isLive ? notifier.stopMonitoring() : notifier.startMonitoring();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: HelioSpacing.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: HelioSpacing.sm,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: isLive
                ? HelioColors.recoveryLow.withValues(alpha: 0.18)
                : HelioColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLive ? HelioColors.recoveryLow : HelioColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLive ? Icons.favorite : Icons.favorite_border,
                size: 13,
                color: isLive ? HelioColors.recoveryLow : HelioColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                isLive ? 'LIVE' : 'START HR',
                style: HelioTypography.capsLabel.copyWith(
                  fontSize: 10,
                  color:
                      isLive ? HelioColors.recoveryLow : HelioColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
