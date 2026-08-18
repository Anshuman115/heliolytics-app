import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_bottom_nav.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/providers/live_hr_provider.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:heliolytics/utils/health_monitor_readings.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/widgets/health/health_metric_grid.dart';
import 'package:heliolytics/widgets/health/live_hr_button.dart';
import 'package:heliolytics/widgets/heart_rate_day_section.dart';
import 'package:heliolytics/widgets/heart_rate_summary.dart';

class HealthMonitorScreen extends ConsumerStatefulWidget {
  final String dayKey;

  const HealthMonitorScreen({super.key, required this.dayKey});

  @override
  ConsumerState<HealthMonitorScreen> createState() =>
      _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends ConsumerState<HealthMonitorScreen> {
  @override
  void deactivate() {
    // Leaving the screen must drop the BLE stream — it holds the band session.
    final live = ref.read(liveHrProvider);
    if (live.isLive || live.isConnecting) {
      ref.read(liveHrProvider.notifier).stopMonitoring();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(dayBundleProvider(widget.dayKey));
    final live = ref.watch(liveHrProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          HelioTopBar(
            showBack: true,
            onBack: () => context.pop(),
            title: 'Health Monitor',
            actions: [LiveHrButton(live: live)],
          ),
          Expanded(
            child: bundleAsync.when(
              loading: () => const HelioLoading(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref
                    .read(healthDataRefreshCoordinatorProvider)
                    .retryDay(widget.dayKey, details: true),
              ),
              data: (bundle) => _body(ref, bundle),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HelioBottomNav(
        index: 1,
        showTabs: false,
        onChanged: (_) {},
        onOrbTap: () => context.push('/profile/view'),
      ),
    );
  }

  Widget _body(WidgetRef ref, DayBundle bundle) {
    return FutureBuilder(
      future: ref.read(dailyBundleCacheStorageProvider).readAllCachedDays(),
      builder: (context, snap) {
        final allDays = snap.data ?? const [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            HelioSpacing.lg,
            HelioSpacing.lg,
            HelioSpacing.lg,
            shellContentBottomPadding,
          ),
          children: [
            HeartRateSummary(day: bundle.day, dayKey: widget.dayKey),
            const SizedBox(height: HelioSpacing.md),
            HealthMetricGrid(
              readings: buildHealthReadings(day: bundle.day, allDays: allDays),
              dayKey: widget.dayKey,
            ),
            const SizedBox(height: HelioSpacing.xl),
            HeartRateDaySection(dayKey: widget.dayKey),
            const SizedBox(height: HelioSpacing.xl),
          ],
        );
      },
    );
  }
}
