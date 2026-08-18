import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_wordmark.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/onboarding_provider.dart';

class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(onboardingProvider).onboardingComplete) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HelioSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: HelioWordmark()),
              const SizedBox(height: HelioSpacing.xl),
              const _StrapPreview(),
              const SizedBox(height: HelioSpacing.xl),
              Text(
                'Your baseline starts here.',
                textAlign: TextAlign.center,
                style: HelioTypography.scoreMedium.copyWith(fontSize: 24),
              ),
              const SizedBox(height: HelioSpacing.sm),
              Text(
                'Sync sleep, recovery, and strain from your strap to your own account.',
                textAlign: TextAlign.center,
                style: HelioTypography.bodyMuted,
              ),
              const Spacer(),
              HelioPrimaryButton(
                label: 'Get started',
                onPressed: () => context.push('/profile'),
              ),
              const SizedBox(height: HelioSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrapPreview extends StatelessWidget {
  const _StrapPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: HelioColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(HelioRadii.card),
        border: Border.all(color: HelioColors.border),
      ),
      child: Image.asset('assets/images/helio_strap.png', fit: BoxFit.contain),
    );
  }
}
