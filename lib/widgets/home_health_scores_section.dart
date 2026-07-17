import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/daily_health_scores_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:heliolytics/widgets/health/health_metric_grid.dart';
import 'package:heliolytics/utils/health_monitor_readings.dart';

class HomeHealthScoresSection extends ConsumerWidget {
  final String dayKey;

  const HomeHealthScoresSection({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(dayBundleProvider(dayKey));
    final scores = ref.watch(dailyHealthScoresProvider(dayKey));

    if (bundle.isLoading || scores.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: HelioSpacing.xl),
        child: HelioLoading(message: 'Loading health scores…'),
      );
    }
    if (!bundle.hasValue || !scores.hasValue) return const SizedBox.shrink();

    return FutureBuilder(
      future: ref.read(dailyBundleCacheStorageProvider).readAllCachedDays(),
      builder: (context, snap) {
        final allDays = snap.data ?? const [];
        final readings = buildHomeHealthReadings(
          bundle: bundle.requireValue,
          scores: scores.requireValue,
          allDays: allDays,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('HEALTH SCORES', style: HelioTypography.sectionTitle),
            const SizedBox(height: HelioSpacing.md),
            HealthMetricGrid(readings: readings, dayKey: dayKey),
          ],
        );
      },
    );
  }
}
