import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
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
  @override
  void deactivate() {
    // Only stop if currently live
    final liveState = ref.read(liveHrProvider);
    if (liveState.isLive || liveState.isConnecting) {
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
            actions: [_LiveHrButton(live: live)],
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
        // Live HR + chart section
        HeartRateDaySection(day: day, dayKey: dayKey),
        const SizedBox(height: HelioSpacing.xl),

        // Metric grid
        Text("LAST NIGHT'S READINGS", style: HelioTypography.sectionTitle),
        const SizedBox(height: HelioSpacing.sm),
        Text(
          'From most recent sync',
          style: HelioTypography.bodyMuted.copyWith(fontSize: 11),
        ),
        const SizedBox(height: HelioSpacing.md),
        _metricsGrid(context, day, dayKey),
      ],
    );
  }

  Widget _metricsGrid(BuildContext context, DayMetric day, String dayKey) {
    final metrics = [
      _MetricCardData(
        label: 'RESTING HR',
        value: day.restingHr != null ? '${day.restingHr}' : '—',
        unit: day.restingHr != null ? 'bpm' : '',
        color: HelioColors.recoveryLow,
        icon: Icons.favorite_outline,
        inRange: day.restingHr != null && day.restingHr! >= 40 && day.restingHr! <= 80,
        hasData: day.restingHr != null,
        onTap: () => context.push('/metric/$dayKey/rhr'),
      ),
      _MetricCardData(
        label: 'HRV',
        value: day.hrvRmssd != null ? '${day.hrvRmssd!.round()}' : '—',
        unit: day.hrvRmssd != null ? 'ms' : '',
        color: HelioColors.sleepBlue,
        icon: Icons.show_chart,
        inRange: day.hrvRmssd != null && day.hrvRmssd! >= 25,
        hasData: day.hrvRmssd != null,
        onTap: () => context.push('/metric/$dayKey/hrv'),
      ),
      _MetricCardData(
        label: 'SPO₂',
        value: day.spo2Avg != null ? '${day.spo2Avg!.round()}' : '—',
        unit: day.spo2Avg != null ? '%' : '',
        color: HelioColors.optimalGreen,
        icon: Icons.air,
        inRange: day.spo2Avg != null && day.spo2Avg! >= 95,
        hasData: day.spo2Avg != null,
        // Overnight SpO₂ (0x26) is the populated series; spot (0x25) is usually empty.
        onTap: () => context.push('/metric/$dayKey/spo2_sleep'),
      ),
      _MetricCardData(
        label: 'RESP RATE',
        value: day.respRateAvg != null ? '${day.respRateAvg}' : '—',
        unit: day.respRateAvg != null ? 'br/min' : '',
        color: HelioColors.strainBlue,
        icon: Icons.air_outlined,
        inRange: day.respRateAvg != null && day.respRateAvg! >= 10 && day.respRateAvg! <= 24,
        hasData: day.respRateAvg != null,
        onTap: () => context.push('/metric/$dayKey/resp_rate'),
      ),
      _MetricCardData(
        label: 'SKIN TEMP',
        value: day.tempAvgC != null ? day.tempAvgC!.toStringAsFixed(1) : '—',
        unit: day.tempAvgC != null ? '°C' : '',
        color: HelioColors.recoveryMid,
        icon: Icons.thermostat_outlined,
        inRange: day.tempAvgC != null && day.tempAvgC! >= 32 && day.tempAvgC! <= 37,
        hasData: day.tempAvgC != null,
        onTap: () => context.push('/metric/$dayKey/temperature'),
      ),
      _MetricCardData(
        label: 'STRESS',
        value: day.stressAvg != null ? (day.stressAvg! / 10).toStringAsFixed(1) : '—',
        unit: day.stressAvg != null ? '/10' : '',
        color: day.stressAvg != null && day.stressAvg! > 65
            ? HelioColors.recoveryLow
            : HelioColors.optimalGreen,
        icon: Icons.psychology_outlined,
        inRange: day.stressAvg != null && day.stressAvg! <= 40,
        hasData: day.stressAvg != null,
        onTap: () => context.push('/metric/$dayKey/stress'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: HelioSpacing.sm,
        mainAxisSpacing: HelioSpacing.sm,
        childAspectRatio: 1.25,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, i) => _MetricCard(data: metrics[i]),
    );
  }
}

class _MetricCardData {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final bool inRange;
  final bool hasData;
  final VoidCallback onTap;

  const _MetricCardData({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.inRange,
    required this.hasData,
    required this.onTap,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return HelioSurfaceCard(
      onTap: data.onTap,
      padding: const EdgeInsets.all(HelioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 16, color: data.color),
              const Spacer(),
              if (data.hasData)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: data.inRange ? HelioColors.optimalGreen : HelioColors.recoveryMid,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.value,
                style: HelioTypography.scoreLarge.copyWith(
                  fontSize: 30,
                  color: data.hasData ? HelioColors.textPrimary : HelioColors.textMuted,
                ),
              ),
              if (data.unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    data.unit,
                    style: HelioTypography.bodyMuted.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(data.label, style: HelioTypography.capsLabel.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Live HR button ────────────────────────────────────────────────────────────
class _LiveHrButton extends ConsumerWidget {
  final LiveHrState live;

  const _LiveHrButton({required this.live});

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
        // Use ref.read directly — no stale cached notifier
        final notifier = ref.read(liveHrProvider.notifier);
        if (isLive) {
          notifier.stopMonitoring();
        } else {
          notifier.startMonitoring();
        }
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
