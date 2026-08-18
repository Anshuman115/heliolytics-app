import 'package:flutter/material.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class MetricTrendPeriodControl extends StatelessWidget {
  const MetricTrendPeriodControl({
    super.key,
    required this.days,
    required this.onChanged,
  });

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: HelioColors.canvasBottom,
      borderRadius: BorderRadius.circular(HelioRadii.sm),
    ),
    child: Row(
      children: [
        _option('W', metricTrendWeekDays),
        _option('M', metricTrendMonthDays),
        _option('6M', metricTrendSixMonthsDays),
      ],
    ),
  );

  Widget _option(String label, int value) => InkWell(
    onTap: () => onChanged(value),
    borderRadius: BorderRadius.circular(HelioRadii.sm),
    child: Container(
      width: 48,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: days == value ? HelioColors.surfaceElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(HelioRadii.sm),
      ),
      child: Text(
        label,
        style: HelioTypography.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class MetricTrendDateNav extends StatelessWidget {
  const MetricTrendDateNav({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left),
      ),
      SizedBox(
        width: 132,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: HelioTypography.capsLabel,
        ),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}
