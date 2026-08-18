import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/providers/live_hr_provider.dart';
import 'package:heliolytics/providers/selected_day_provider.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/widgets/error_view.dart';
import 'package:heliolytics/widgets/health_baseline_card.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/day_picker.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/widgets/health_signals_card.dart';
import 'package:heliolytics/widgets/health/live_hr_button.dart';
import 'package:heliolytics/widgets/home_health_scores_section.dart';

class HealthHubScreen extends ConsumerStatefulWidget {
  const HealthHubScreen({super.key});

  @override
  ConsumerState<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends ConsumerState<HealthHubScreen> {
  @override
  void deactivate() {
    final live = ref.read(liveHrProvider);
    if (live.isLive || live.isConnecting) {
      ref.read(liveHrProvider.notifier).stopMonitoring();
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = ref.watch(selectedDayKeyProvider) ?? todayDayKey();
    final bundle = ref.watch(dayBundleProvider(dayKey));
    final live = ref.watch(liveHrProvider);
    return Column(
      children: [
        HelioTopBar(
          safeTop: false,
          dayLabel: formatNavDayLabel(dayKey),
          onPrevDay: () => shiftSelectedDay(ref, -1),
          onNextDay: () => shiftSelectedDay(ref, 1),
          canGoNext: dayKey != todayDayKey(),
          onDateTap: () async {
            final selected = await pickDay(context, dayKey: dayKey);
            if (selected != null) selectDay(ref, selected);
          },
          actions: [LiveHrButton(live: live)],
        ),
        Expanded(
          child: bundle.when(
            loading: () => const HelioLoading(),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref
                  .read(healthDataRefreshCoordinatorProvider)
                  .retryDay(dayKey, healthScores: true),
            ),
            data: (data) => ListView(
              padding: const EdgeInsets.fromLTRB(
                HelioSpacing.lg,
                HelioSpacing.md,
                HelioSpacing.lg,
                shellContentBottomPadding,
              ),
              children: [
                if (_hasBaseline(data.day))
                  HealthBaselineCard(
                    hrv: data.day.hrvRmssd,
                    restingHr: data.day.restingHr,
                    onTap: () => context.push('/health/$dayKey'),
                  )
                else
                  _emptyHealthCard(context, dayKey),
                const SizedBox(height: HelioSpacing.xl),
                _recoverySection(data.day),
                const SizedBox(height: HelioSpacing.xl),
                HealthMonitorRow(
                  title: 'Stress monitor',
                  subtitle: data.day.stressAvg == null
                      ? 'No stress reading yet'
                      : 'Average ${data.day.stressAvg!.toStringAsFixed(1)} today',
                  icon: Icons.psychology_outlined,
                  color: HelioColors.strainBlue,
                  onTap: () => context.push('/stress/$dayKey'),
                ),
                const SizedBox(height: HelioSpacing.xl),
                Text('TODAY\'S SIGNALS', style: HelioTypography.sectionTitle),
                const SizedBox(height: HelioSpacing.sm),
                HelioSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      HealthSignalRow(
                        dayKey: dayKey,
                        label: 'HRV',
                        value: data.day.hrvRmssd,
                        unit: 'ms',
                        metricId: 'hrv',
                      ),
                      HealthSignalRow(
                        dayKey: dayKey,
                        label: 'Resting heart rate',
                        value: data.day.restingHr,
                        unit: 'bpm',
                        metricId: 'rhr',
                      ),
                      HealthSignalRow(
                        dayKey: dayKey,
                        label: 'Respiratory rate',
                        value: data.day.respRateAvg,
                        unit: 'br/min',
                        metricId: 'resp_rate',
                      ),
                      HealthSignalRow(
                        dayKey: dayKey,
                        label: 'Blood oxygen',
                        value: data.day.spo2Avg,
                        unit: '%',
                        metricId: 'spo2',
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HelioSpacing.xl),
                HomeHealthScoresSection(dayKey: dayKey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _recoverySection(DayMetric day) {
    final hrv = day.hrvRmssd;
    final restingHr = day.restingHr;
    final spo2 = day.spo2Avg;
    return HelioSurfaceCard(
      color: HelioColors.surfaceElevated,
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.autorenew, color: HelioColors.recoveryMid),
              const SizedBox(width: HelioSpacing.md),
              Text('Recovery', style: HelioTypography.sectionTitle),
              const Spacer(),
              _recoveryStatus(day),
            ],
          ),
          const SizedBox(height: HelioSpacing.lg),
          Row(
            children: [
              _recoveryValue(
                hrv,
                'HRV',
                'ms',
                Icons.favorite_outline,
                hrv != null && hrv >= 67
                    ? HelioColors.recoveryHigh
                    : HelioColors.textMuted,
              ),
              const Spacer(),
              _recoveryValue(
                restingHr,
                'RHR',
                'bpm',
                Icons.accessibility,
                restingHr != null && restingHr <= 80
                    ? HelioColors.optimalGreen
                    : HelioColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.md),
          Row(
            children: [
              _recoveryValue(
                day.respRateAvg,
                'RR',
                'br/min',
                Icons.remove,
                HelioColors.textMuted,
              ),
              const Spacer(),
              _recoveryValue(
                spo2,
                'SpO2',
                '%',
                Icons.air,
                spo2 != null && spo2 >= 95
                    ? HelioColors.optimalGreen
                    : HelioColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.md),
          _recoveryExplanation(day),
        ],
      ),
    );
  }

  bool _hasBaseline(DayMetric day) =>
      day.hrvRmssd != null || day.restingHr != null;

  Widget _emptyHealthCard(BuildContext context, String dayKey) {
    return HelioSurfaceCard(
      onTap: () => context.push('/health/$dayKey'),
      color: HelioColors.surfaceElevated,
      child: Row(
        children: [
          const Icon(
            Icons.monitor_heart_outlined,
            color: HelioColors.textMuted,
            size: 28,
          ),
          const SizedBox(width: HelioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HEALTH MONITOR', style: HelioTypography.sectionTitle),
                const SizedBox(height: HelioSpacing.xs),
                Text(
                  'No overnight baseline yet',
                  style: HelioTypography.scoreMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: HelioSpacing.xs),
                Text(
                  'Sync your strap to load HRV and resting heart rate.',
                  style: HelioTypography.bodyMuted,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: HelioColors.textMuted),
        ],
      ),
    );
  }

  Widget _recoveryStatus(DayMetric day) {
    final recovery = day.readiness;
    if (recovery == null) return Text('—', style: HelioTypography.bodyMuted);
    if (recovery >= 67) {
      return Text(
        'HIGH',
        style: HelioTypography.capsLabel.copyWith(
          color: HelioColors.recoveryHigh,
        ),
      );
    }
    if (recovery >= 34) {
      return Text(
        'MODERATE',
        style: HelioTypography.capsLabel.copyWith(
          color: HelioColors.recoveryMid,
        ),
      );
    }
    return Text(
      'LOW',
      style: HelioTypography.capsLabel.copyWith(color: HelioColors.recoveryLow),
    );
  }

  Widget _recoveryValue(
    num? value,
    String label,
    String unit,
    IconData icon,
    Color color,
  ) => Expanded(
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: HelioSpacing.sm),
        Expanded(
          child: Text(
            value != null ? value.toStringAsFixed(0) : '—',
            style: HelioTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: HelioSpacing.sm),
        Text(
          label,
          style: HelioTypography.capsLabel.copyWith(fontSize: 10, color: color),
        ),
        const SizedBox(width: HelioSpacing.xs),
        Text(
          unit,
          style: HelioTypography.capsLabel.copyWith(
            fontSize: 10,
            color: HelioColors.textMuted,
          ),
        ),
      ],
    ),
  );

  Widget _recoveryExplanation(DayMetric day) {
    final recovery = day.readiness;
    if (recovery == null) {
      return const Text(
        'Sync your strap to see recovery insights.',
        style: TextStyle(color: HelioColors.textMuted, fontSize: 13),
      );
    }
    if (recovery >= 67) {
      return const Text(
        'Strong overnight baseline – ideal for a hard training session today.',
        style: TextStyle(color: HelioColors.recoveryHigh, fontSize: 13),
      );
    }
    if (recovery >= 34) {
      return const Text(
        'Recovery is moderate – keep training intensity steady and prioritize sleep tonight.',
        style: TextStyle(color: HelioColors.recoveryMid, fontSize: 13),
      );
    }
    return const Text(
      'Recovery is low – keep training easy and make sleep the main focus tonight.',
      style: TextStyle(color: HelioColors.recoveryLow, fontSize: 13),
    );
  }
}
