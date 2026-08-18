import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/widgets/heart_rate_bpm_hero.dart';

void main() {
  testWidgets('shows no data instead of inventing a heart rate', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeartRateBpmHero(bpm: null, label: 'NO DATA', isLive: false),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('64'), findsNothing);
  });
}
