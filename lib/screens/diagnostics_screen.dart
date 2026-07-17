import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/widgets/settings/raw_dump_card.dart';
import 'package:heliolytics/widgets/settings/test_vibration_card.dart';
import 'package:heliolytics/widgets/settings/test_vibration_pattern_card.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HelioTopBar(showBack: true, onBack: () => context.pop(), title: 'Diagnostics'),
      body: ListView(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: const [
          TestVibrationCard(),
          SizedBox(height: HelioSpacing.md),
          TestVibrationPatternCard(),
          SizedBox(height: HelioSpacing.md),
          RawDumpCard(),
        ],
      ),
    );
  }
}
