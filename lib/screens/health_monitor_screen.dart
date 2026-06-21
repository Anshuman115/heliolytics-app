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
  ConsumerState<HealthMonitorScreen> createState() =>
      _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends ConsumerState<HealthMonitorScreen> {
  /// Cached so we can call stopMonitoring() safely in dispose()
  /// without touching ref after the widget is unmounted.
  LiveHrNotifier? _liveHrNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _liveHrNotifier = ref.read(liveHrProvider.notifier);
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
    final live = ref.watch(liveHrProvider);

    return Scaffold(
      backgroundColor: HelioColors.canvas,
      body: Column(
        children: [
          HelioTopBar(
            showBack: true,
            onBack: () => context.pop(),
            title: 'Health Monitor',
            actions: [
              _LiveHrButton(live: live, notifier: _liveHrNotifier),
            ],
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

  Widget _body(
    BuildContext context,
    CloudMetricsSnapshot? snap,
    String dayKey,
  ) {
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

class _LiveHrButton extends StatelessWidget {
  final LiveHrState live;
  final LiveHrNotifier? notifier;

  const _LiveHrButton({required this.live, required this.notifier});

  @override
  Widget build(BuildContext context) {
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
        if (isLive) {
          notifier?.stopMonitoring();
        } else {
          notifier?.startMonitoring();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: HelioSpacing.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: HelioSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isLive
                ? HelioColors.recoveryLow.withValues(alpha: 0.18)
                : HelioColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLive ? HelioColors.recoveryLow : HelioColors.border,
              width: 1,
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
                  color: isLive
                      ? HelioColors.recoveryLow
                      : HelioColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
