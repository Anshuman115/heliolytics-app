import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/providers/live_hr_provider.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/widgets/health/health_metric_grid.dart';
import 'package:heliolytics/widgets/health/live_hr_button.dart';
import 'package:heliolytics/widgets/heart_rate_day_section.dart';

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
    final health = ref.watch(liveHealthProvider);
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
            child: health.when(
              loading: () => const HelioLoading(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(liveHealthProvider),
              ),
              data: (snap) => _body(snap),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(CloudMetricsSnapshot? snap) {
    final days = snap?.days ?? const <DayMetric>[];
    final day = _dayFor(days, widget.dayKey);
    if (day == null) {
      return const Center(child: Text('No data for this day'));
    }

    return ListView(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      children: [
        HeartRateDaySection(day: day, dayKey: widget.dayKey),
        const SizedBox(height: HelioSpacing.xl),
        HealthMetricGrid(
          day: day,
          allDays: days,
          dayKey: widget.dayKey,
        ),
        const SizedBox(height: HelioSpacing.lg),
      ],
    );
  }

  DayMetric? _dayFor(List<DayMetric> days, String dayKey) {
    for (final d in days) {
      if (d.dayKey == dayKey) return d;
    }
    return null;
  }
}
