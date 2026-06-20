import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:intl/intl.dart';

class HomeStatusRow extends StatelessWidget {
  final DayMetric day;
  final VoidCallback? onHealthTap;
  final VoidCallback? onStressTap;

  const HomeStatusRow({
    super.key,
    required this.day,
    this.onHealthTap,
    this.onStressTap,
  });

  @override
  Widget build(BuildContext context) {
    final inRange = _vitalsInRange(day);
    final total = _vitalsTotal(day);
    final stress = day.stressAvg;
    final stressLabel = _stressLabel(stress);
    final now = DateFormat.jm().format(DateTime.now());

    return Row(
      children: [
        Expanded(
          child: _monitorCard(
            title: 'Health Monitor',
            onTap: onHealthTap,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: HelioColors.optimalGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HelioColors.optimalGreen.withValues(alpha: 0.4)),
                  ),
                  child: Icon(Icons.check, size: 18, color: HelioColors.optimalGreen),
                ),
                const SizedBox(width: HelioSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total > 0 && inRange == total ? 'WITHIN RANGE' : 'CHECK METRICS',
                        style: HelioTypography.capsLabel.copyWith(
                          color: HelioColors.optimalGreen,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        total > 0 ? '$inRange/$total Metrics' : 'No vitals yet',
                        style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: HelioSpacing.sm),
        Expanded(
          child: _monitorCard(
            title: 'Stress Monitor',
            onTap: onStressTap,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HelioColors.stressLow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stress != null ? (stress / 10).toStringAsFixed(1) : '—',
                    style: HelioTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: HelioColors.stressLow,
                    ),
                  ),
                ),
                const SizedBox(width: HelioSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stressLabel,
                        style: HelioTypography.capsLabel.copyWith(
                          color: HelioColors.stressLow,
                          fontSize: 10,
                        ),
                      ),
                      Text(now, style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _monitorCard({
    required String title,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return HelioSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(HelioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: HelioTypography.capsLabel.copyWith(fontSize: 10),
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: HelioColors.textMuted),
            ],
          ),
          const SizedBox(height: HelioSpacing.md),
          child,
        ],
      ),
    );
  }

  String _stressLabel(int? stress) {
    if (stress == null) return 'NO DATA';
    if (stress <= 40) return 'LOW';
    if (stress <= 65) return 'MEDIUM';
    return 'HIGH';
  }

  int _vitalsTotal(DayMetric day) {
    var n = 0;
    if (day.restingHr != null) n++;
    if (day.hrvRmssd != null) n++;
    if (day.spo2Avg != null) n++;
    if (day.stressAvg != null) n++;
    if (day.tempAvgC != null) n++;
    return n;
  }

  int _vitalsInRange(DayMetric day) {
    var n = 0;
    final rhr = day.restingHr;
    if (rhr != null && rhr >= 40 && rhr <= 80) n++;
    final hrv = day.hrvRmssd;
    if (hrv != null && hrv >= 25) n++;
    final spo2 = day.spo2Avg;
    if (spo2 != null && spo2 >= 95) n++;
    final stress = day.stressAvg;
    if (stress != null && stress <= 40) n++;
    final temp = day.tempAvgC;
    if (temp != null && temp >= 32 && temp <= 37) n++;
    return n;
  }
}
