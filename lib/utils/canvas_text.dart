import 'package:flutter/material.dart';

/// Draws [text] at [at] on a canvas.
///
/// Pass [width] with an [align] to right- or centre-align inside that width —
/// TextPainter needs a bounded width before alignment means anything.
void paintCanvasText(
  Canvas canvas,
  String text,
  Offset at,
  TextStyle style, {
  double? width,
  TextAlign align = TextAlign.left,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: align,
  )..layout(minWidth: width ?? 0, maxWidth: width ?? double.infinity);
  tp.paint(canvas, at);
}
