import 'package:flutter/material.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/metric_progress.dart';
import 'package:heliolytics/design_system/components/helio_score_ring.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/widgets/home_vital_row.dart';

class HomePrimaryRings extends StatelessWidget {
  final DayMetric day;
  final void Function(String metricId) onRingTap;

  const HomePrimaryRings({super.key, required this.day, required this.onRingTap});

  @override
  Widget build(BuildContext context) {
    final strain = day.paiScore ?? _strainFromSteps(day.steps);
    final recoveryColor = recoveryColorFor(day.readiness);

    return Column(
      children: [
        // ── Hero recovery ring ──────────────────────────────
        const SizedBox(height: HelioSpacing.xl),
        GestureDetector(
          onTap: () => onRingTap('readiness'),
          child: HelioScoreRing(
            size: HelioRingSize.whoopHero,
            progress: metricProgress(MetricKind.readiness, day.readiness),
            label: 'Recovery',
            value: day.readiness != null ? '${day.readiness}%' : '—',
            color: recoveryColor,
            showChevron: false,
          ),
        ),
        const SizedBox(height: HelioSpacing.xxxl),

        // ── Three equal sub-rings ───────────────────────────
        Row(
          children: [
            Expanded(
              child: _ring(
                progress: metricProgress(MetricKind.sleep, day.sleepScore),
                label: 'Sleep',
                value: day.sleepScore != null ? '${day.sleepScore}%' : '—',
                color: HelioColors.sleepBlue,
                onTap: () => onRingTap('sleep'),
              ),
            ),
            Expanded(
              child: _ring(
                progress: metricProgress(MetricKind.pai, strain),
                label: 'Strain',
                value: formatStrainDecimal(strain),
                color: HelioColors.strainBlue,
                onTap: () => onRingTap('pai'),
              ),
            ),
            Expanded(
              child: _ring(
                progress: metricProgress(MetricKind.hrv, day.hrvRmssd),
                label: 'HRV',
                value: day.hrvRmssd != null ? '${day.hrvRmssd}' : '—',
                color: recoveryColor,
                onTap: () => onRingTap('hrv'),
              ),
            ),
          ],
        ),
        const SizedBox(height: HelioSpacing.xl),

        // ── Vital rows ──────────────────────────────────────
        _divider(),
        HomeVitalRow(
          icon: Icons.favorite_outline,
          label: 'Resting HR',
          value: day.restingHr != null ? '${day.restingHr}' : '—',
          unit: day.restingHr != null ? 'bpm' : '',
          valueColor: HelioColors.recoveryLow,
          onTap: () => onRingTap('rhr'),
        ),
        _divider(),
        HomeVitalRow(
          icon: Icons.show_chart,
          label: 'HRV',
          value: day.hrvRmssd != null ? '${day.hrvRmssd}' : '—',
          unit: day.hrvRmssd != null ? 'ms' : '',
          valueColor: recoveryColor,
          onTap: () => onRingTap('hrv'),
        ),
        _divider(),
        HomeVitalRow(
          icon: Icons.thermostat_outlined,
          label: 'Skin Temp',
          value: day.tempAvgC != null ? day.tempAvgC!.toStringAsFixed(1) : '—',
          unit: day.tempAvgC != null ? '°C' : '',
          onTap: () => onRingTap('temperature'),
        ),
        _divider(),
      ],
    );
  }

  Widget _ring({
    required double? progress,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Center(
      child: HelioScoreRing(
        size: HelioRingSize.triple,
        progress: progress,
        label: label,
        value: value,
        color: color,
        onTap: onTap,
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        color: Color(0x14FFFFFF),
      );

  int? _strainFromSteps(int steps) {
    if (steps <= 0) return null;
    return (steps / 150).clamp(0, 100).round();
  }
}
