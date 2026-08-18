import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/components/helio_bottom_nav.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/onboarding_provider.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/widgets/profile/profile_overview_content.dart';
import 'package:heliolytics/widgets/profile/profile_history_section.dart';

class ProfileOverviewScreen extends ConsumerWidget {
  const ProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProvider).profile;
    final bundle = ref.watch(dayBundleProvider(todayDayKey()));
    return Scaffold(
      appBar: HelioTopBar(
        showBack: true,
        onBack: () => context.pop(),
        title: 'Profile',
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined, size: 24),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          HelioSpacing.lg,
          HelioSpacing.lg,
          HelioSpacing.lg,
          shellContentBottomPadding,
        ),
        children: [
          ProfileIdentity(profile: profile),
          const SizedBox(height: HelioSpacing.lg),
          bundle.when(
            loading: () => const SizedBox(height: 180),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) => ProfileTodaySummary(day: data.day),
          ),
          const SizedBox(height: HelioSpacing.xl),
          const ProfileHistorySection(),
          const SizedBox(height: HelioSpacing.xl),
          ProfileDataSection(profile: profile),
        ],
      ),
      bottomNavigationBar: HelioBottomNav(
        index: 3,
        showTabs: false,
        onChanged: (_) {},
        onOrbTap: () {},
      ),
    );
  }
}
