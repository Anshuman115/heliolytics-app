import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

/// One night's sleep span used by the consistency chart.
class SleepSpan {
  final DateTime bed;
  final DateTime wake;
  const SleepSpan({required this.bed, required this.wake});
}

/// Sleep-consistency chart: one vertical bar per night spanning
/// bedtime → wake on a shared clock axis, so day-to-day drift is visible.
class SleepConsistencyChart extends StatelessWidget {
  final List<SleepSpan> nights; // oldest → newest

  const SleepConsistencyChart({super.key, required this.nights});

  static const _height = 150.0;

  @override
  Widget build(BuildContext context) {
    if (nights.length < 2) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SLEEP CONSISTENCY', style: HelioTypography.sectionTitle),
        const SizedBox(height: HelioSpacing.md),
        SizedBox(
          height: _height,
          child: CustomPaint(
            painter: _ConsistencyPainter(nights: nights),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _ConsistencyPainter extends CustomPainter {
  _ConsistencyPainter({required this.nights});

  final List<SleepSpan> nights;

  @override
  void paint(Canvas canvas, Size size) {
    const padT = 8.0;
    const padB = 22.0; // room for day labels
    const padL = 4.0;
    const padR = 4.0;
    final plotH = size.height - padT - padB;
    final plotW = size.width - padL - padR;
    if (plotH <= 0 || plotW <= 0) return;

    // Shared clock axis: earliest bedtime → latest wake, as minutes-from-bed.
    var minOffset = 0.0;
    var maxOffset = 0.0;
    final beds = <double>[];
    final wakes = <double>[];
    final ref = nights.first.bed;
    for (final n in nights) {
      final b = n.bed.difference(ref).inMinutes.toDouble();
      final w = n.wake.difference(ref).inMinutes.toDouble();
      beds.add(b);
      wakes.add(w);
    }
    // Normalize each night to its own clock-of-day so bars align by time,
    // not by absolute date: use minutes since 18:00 (6 PM) of the bed day.
    final bedClock = <double>[];
    final wakeClock = <double>[];
    for (final n in nights) {
      bedClock.add(_minsSince6pm(n.bed));
      wakeClock.add(_minsSince6pm(n.wake));
    }
    minOffset = bedClock.reduce((a, b) => a < b ? a : b);
    maxOffset = wakeClock.reduce((a, b) => a > b ? a : b);
    final span = (maxOffset - minOffset).clamp(60.0, 24 * 60);

    double yFor(double mins) => padT + plotH * (mins - minOffset) / span;

    final slotW = plotW / nights.length;
    final barW = (slotW * 0.4).clamp(6.0, 26.0);
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 10,
    );

    for (var i = 0; i < nights.length; i++) {
      final cx = padL + slotW * (i + 0.5);
      final top = yFor(bedClock[i]);
      final bot = yFor(wakeClock[i]);
      final isLatest = i == nights.length - 1;
      final color = isLatest ? HelioColors.sleepRem : HelioColors.ringTrack;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - barW / 2, top, cx + barW / 2, bot),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = color);

      _paintText(
        canvas,
        DateFormat.E().format(nights[i].bed).toUpperCase(),
        Offset(cx - barW, size.height - 16),
        labelStyle,
      );
    }
  }

  double _minsSince6pm(DateTime t) {
    // 18:00 of the day the sleep-event belongs to maps to 0; values past
    // midnight stay continuous (e.g. 02:00 → 8h).
    final anchor = DateTime(t.year, t.month, t.day, 18);
    var diff = t.difference(anchor).inMinutes.toDouble();
    if (diff < 0) diff += 24 * 60; // morning wake belongs to prior evening
    return diff;
  }

  void _paintText(Canvas canvas, String text, Offset at, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _ConsistencyPainter old) => old.nights != nights;
}
