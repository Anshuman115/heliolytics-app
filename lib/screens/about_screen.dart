import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HelioTopBar(
        showBack: true,
        onBack: () => context.pop(),
        title: 'About',
      ),
      body: ListView(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: [
          const SizedBox(height: HelioSpacing.xxl),
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 64,
                    width: 64,
                  ),
                ),
                const SizedBox(height: HelioSpacing.md),
                Text(
                  'HELIOLYTICS',
                  style: HelioTypography.sectionTitle.copyWith(
                    color: HelioColors.textMuted,
                    letterSpacing: 0,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
