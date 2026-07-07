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

  static const _height = 172.0;

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

  static const _tick = 180.0; // gridline every 3 hours

  @override
  void paint(Canvas canvas, Size size) {
    const padT = 10.0;
    const padB = 22.0; // room for day labels
    const padL = 40.0; // room for clock-time axis labels
    const padR = 8.0;
    final plotH = size.height - padT - padB;
    final plotW = size.width - padL - padR;
    if (plotH <= 0 || plotW <= 0) return;

    // Normalize each night to a clock-of-day axis so bars align by time,
    // not by absolute date: minutes since 18:00 (6 PM), continuous past
    // midnight (e.g. 02:00 → 8h).
    final bedClock = [for (final n in nights) _minsSince6pm(n.bed)];
    final wakeClock = [for (final n in nights) _minsSince6pm(n.wake)];

    // Axis domain snapped to whole 3-hour ticks around the data range.
    final dataMin = bedClock.reduce((a, b) => a < b ? a : b);
    final dataMax = wakeClock.reduce((a, b) => a > b ? a : b);
    final start = (dataMin / _tick).floorToDouble() * _tick;
    final end = (dataMax / _tick).ceilToDouble() * _tick;
    final span = (end - start).clamp(_tick, 24 * 60);

    double yFor(double mins) => padT + plotH * (mins - start) / span;

    final axisStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 9,
    );
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    // Gridlines + clock-time labels down the left edge.
    for (var t = start; t <= end + 1; t += _tick) {
      final y = yFor(t);
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);
      _paintText(canvas, _clockLabel(t), Offset(2, y - 6), axisStyle,
          width: padL - 6, align: TextAlign.right);
    }

    final slotW = plotW / nights.length;
    final barW = (slotW * 0.45).clamp(8.0, 28.0);
    final dayStyle = TextStyle(
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

      // Day label centered under the bar.
      _paintText(canvas, DateFormat.E().format(nights[i].bed).toUpperCase(),
          Offset(cx - slotW / 2, size.height - 14), dayStyle,
          width: slotW, align: TextAlign.center);
    }
  }

  double _minsSince6pm(DateTime t) {
    final anchor = DateTime(t.year, t.month, t.day, 18);
    var diff = t.difference(anchor).inMinutes.toDouble();
    if (diff < 0) diff += 24 * 60; // morning wake belongs to prior evening
    return diff;
  }

  /// Minutes-since-6PM → short clock label, e.g. 360 → "12AM".
  String _clockLabel(double minsSince6pm) {
    final total = (18 * 60 + minsSince6pm).round() % (24 * 60);
    final h = total ~/ 60;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12$period';
  }

  void _paintText(Canvas canvas, String text, Offset at, TextStyle style,
      {double? width, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(minWidth: width ?? 0, maxWidth: width ?? double.infinity);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _ConsistencyPainter old) => old.nights != nights;
}
