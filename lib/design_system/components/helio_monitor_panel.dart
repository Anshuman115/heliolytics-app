import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_section_header.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_vital_tile.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/metric_catalog.dart';

class HelioMonitorPanel extends StatelessWidget {
  final DayMetric day;
  final void Function(String metricId)? onMetricTap;
  final int inRange;
  final int total;

  const HelioMonitorPanel({
    super.key,
    required this.day,
    this.onMetricTap,
    this.inRange = 0,
    this.total = 0,
  });

  factory HelioMonitorPanel.forDay({
    required DayMetric day,
    void Function(String metricId)? onMetricTap,
  }) {
    return HelioMonitorPanel(
      day: day,
      onMetricTap: onMetricTap,
      inRange: _vitalsInRange(day),
      total: _vitalsTotal(day),
    );
  }

  static int _vitalsTotal(DayMetric day) {
    var n = 0;
    if (day.restingHr != null) n++;
    if (day.hrvRmssd != null) n++;
    if (day.spo2Avg != null) n++;
    if (day.stressAvg != null) n++;
    if (day.tempAvgC != null) n++;
    return n;
  }

  static int _vitalsInRange(DayMetric day) {
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

  @override
  Widget build(BuildContext context) {
    void open(String id) => onMetricTap?.call(id);

    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HelioSectionHeader(
            title: 'Health monitor',
            trailingText: total > 0 ? '$inRange/$total in range' : null,
          ),
          const SizedBox(height: HelioSpacing.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: HelioSpacing.sm,
            crossAxisSpacing: HelioSpacing.sm,
            childAspectRatio: 1.4,
            children: [
              _tile('rhr', day.restingHr?.toString() ?? '—', open),
              _tile(
                'hrv',
                day.hrvRmssd != null ? '${day.hrvRmssd}' : '—',
                open,
                unit: 'ms',
              ),
              _tile(
                'spo2',
                day.spo2Avg != null ? '${day.spo2Avg}%' : '—',
                open,
              ),
              _tile(
                'stress',
                day.stressAvg?.toString() ?? '—',
                open,
                status: _stressStatus(day.stressAvg),
              ),
              _respTile(open),
              _tempTile(day, open),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(
    String id,
    String value,
    void Function(String) open, {
    String unit = '',
    String? status,
  }) {
    final def = MetricCatalog.byId(id)!;
    final label = unit.isEmpty ? def.title : '${def.title} ($unit)';
    return HelioVitalTile(
      icon: def.icon,
      label: label,
      value: value,
      status: status,
      statusColor: status != null ? HelioColors.optimalGreen : null,
      onTap: () => open(id),
    );
  }

  Widget _respTile(void Function(String) open) {
    return HelioVitalTile(
      icon: Icons.air,
      label: 'Resp rate',
      value: '—',
      onTap: () => open('resp_rate'),
    );
  }

  Widget _tempTile(DayMetric day, void Function(String) open) {
    return HelioVitalTile(
      icon: Icons.thermostat,
      label: 'Skin temp (°C)',
      value: day.tempAvgC?.toStringAsFixed(1) ?? '—',
      onTap: () => open('temperature'),
    );
  }

  String? _stressStatus(int? stress) {
    if (stress == null) return null;
    if (stress <= 40) return 'low';
    if (stress <= 65) return 'mid';
    return 'high';
  }
}
