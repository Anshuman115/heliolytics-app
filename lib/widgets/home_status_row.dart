import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';

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
    final stressColor = _stressColor(stress);

    return Row(
      children: [
        Expanded(
          child: _card(
            title: 'Health',
            onTap: onHealthTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusBadge(
                      total > 0 && inRange == total
                          ? Icons.check
                          : Icons.priority_high,
                      total > 0 && inRange == total
                          ? HelioColors.optimalGreen
                          : HelioColors.recoveryMid,
                    ),
                    const SizedBox(width: HelioSpacing.md),
                    Text(
                      total > 0 && inRange == total
                          ? 'ALL CLEAR'
                          : 'CHECK METRICS',
                      style: HelioTypography.capsLabel.copyWith(
                        fontSize: 10,
                        color: total > 0 && inRange == total
                            ? HelioColors.optimalGreen
                            : HelioColors.recoveryMid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HelioSpacing.xs),
                Text(
                  total > 0 ? '$inRange / $total in range' : 'No vitals yet',
                  style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: HelioSpacing.sm),
        Expanded(
          child: _card(
            title: 'Stress',
            onTap: onStressTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusBadge(Icons.show_chart, stressColor),
                    const SizedBox(width: HelioSpacing.md),
                    Text(
                      stressLabel,
                      style: HelioTypography.capsLabel.copyWith(
                        fontSize: 10,
                        color: stressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HelioSpacing.xs),
                Text(
                  stress != null
                      ? '${(stress / 10).toStringAsFixed(1)} stress level'
                      : 'No data yet',
                  style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({
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
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: HelioColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _statusBadge(IconData icon, Color color) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Icon(icon, size: 17, color: color),
  );

  Color _stressColor(int? stress) {
    if (stress == null) return HelioColors.textMuted;
    if (stress <= 40) return HelioColors.optimalGreen;
    if (stress <= 65) return HelioColors.recoveryMid;
    return HelioColors.recoveryLow;
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
