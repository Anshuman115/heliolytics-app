import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_wordmark.dart';
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
              const SizedBox(height: HelioSpacing.lg),
              Text(
                'Track sleep, recovery, and strain from your strap — synced\n'
                'straight to your own Heliolytics account.',
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
