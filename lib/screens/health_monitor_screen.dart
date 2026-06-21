import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_monitor_panel.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/providers/live_hr_provider.dart';
import 'package:heliolytics/widgets/heart_rate_day_section.dart';

class HealthMonitorScreen extends ConsumerStatefulWidget {
  final String dayKey;

  const HealthMonitorScreen({super.key, required this.dayKey});

  @override
  ConsumerState<HealthMonitorScreen> createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends ConsumerState<HealthMonitorScreen> {
  LiveHrNotifier? _liveHrNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _liveHrNotifier = ref.read(liveHrProvider.notifier);
      _liveHrNotifier!.startMonitoring();
    });
  }

  @override
  void dispose() {
    _liveHrNotifier?.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(liveHealthProvider);
    return Scaffold(
      backgroundColor: HelioColors.canvas,
      body: Column(
        children: [
          HelioTopBar(
            showBack: true,
            onBack: () => context.pop(),
            title: 'Health Monitor',
          ),
          Expanded(
            child: health.when(
              loading: () => const HelioLoading(),
              error: (_, __) => const Center(child: Text('Failed to load')),
              data: (snap) => _body(context, snap, widget.dayKey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, CloudMetricsSnapshot? snap, String dayKey) {
    DayMetric? day;
    for (final d in snap?.days ?? const <DayMetric>[]) {
      if (d.dayKey == dayKey) {
        day = d;
        break;
      }
    }
    if (snap == null || day == null) {
      return const Center(child: Text('No data for this day'));
    }

    return ListView(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      children: [
        HeartRateDaySection(snap: snap, day: day, dayKey: dayKey),
        const SizedBox(height: HelioSpacing.xl),
        Row(
          children: [
            Text("LAST NIGHT'S READINGS", style: HelioTypography.sectionTitle),
            const SizedBox(width: HelioSpacing.sm),
            const Icon(Icons.info_outline, size: 14, color: HelioColors.textMuted),
          ],
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioMonitorPanel.forDay(
          day: day,
          onMetricTap: (id) => context.push('/metric/$dayKey/$id'),
        ),
      ],
    );
  }
}
