import 'package:flutter/material.dart';

import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sleep_stage_bounds.dart';
import 'package:heliolytics/models/sleep_stage.dart';
import 'package:heliolytics/widgets/sleep_hypnogram_painter.dart';

/// Timeline hypnogram: time on X, stage on Y.
class SleepHypnogramChart extends StatelessWidget {
  const SleepHypnogramChart({super.key, required this.stages});

  final List<SleepStagePoint> stages;

  static const _height = 140.0;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return const SizedBox(
        height: _height,
        child: Center(child: Text('No stage timeline')),
      );
    }
    final sorted = List<SleepStagePoint>.from(stages)
      ..sort((a, b) => a.start.compareTo(b.start));
    final bounds = sleepStageBounds(sorted)!;
    final t0 = bounds.start;
    final t1 = bounds.end;
    final spanMs = t1.difference(t0).inMilliseconds.clamp(1, 1 << 31);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _height,
          child: CustomPaint(
            painter: SleepHypnogramPainter(
              stages: sorted,
              t0: t0,
              spanMs: spanMs,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: HelioSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                formatChartTime(t0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            for (final fraction in [0.33, 0.66])
              Expanded(
                child: Text(
                  formatChartTime(
                    t0.add(Duration(milliseconds: (spanMs * fraction).round())),
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            Expanded(
              child: Text(
                formatChartTime(t1),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: HelioSpacing.sm),
      ],
    );
  }
}
