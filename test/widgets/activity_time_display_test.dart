import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/widgets/home_activity_row.dart';

void main() {
  testWidgets('the activity row prints IST clock times', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeActivityRow(
            icon: Icons.directions_run,
            label: 'Run',
            duration: '30m',
            start: DateTime.utc(2026, 10, 20, 0, 0),
            end: DateTime.utc(2026, 10, 20, 0, 30),
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(_clockText('5:30 AM'), findsOneWidget);
    expect(_clockText('6:00 AM'), findsOneWidget);
  });
}

Finder _clockText(String expected) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      widget.data != null &&
      _squash(widget.data!) == expected,
);

/// Collapses normal, no-break and narrow no-break spaces to one space.
String _squash(String value) =>
    value.replaceAll(RegExp(r'[\s\u00a0\u202f]+'), ' ');
