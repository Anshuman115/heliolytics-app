import 'package:flutter/material.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/widgets/sync_log_panel.dart';

/// Build marker, collapsible sync log, and the app wordmark footer.
class SettingsAboutSection extends StatelessWidget {
  final List<String> syncLogs;
  const SettingsAboutSection({super.key, required this.syncLogs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HelioSurfaceCard(
          padding: const EdgeInsets.symmetric(
              horizontal: HelioSpacing.lg, vertical: HelioSpacing.md),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 18, color: HelioColors.textMuted),
            const SizedBox(width: HelioSpacing.md),
            Text('Build', style: HelioTypography.capsLabel),
            const Spacer(),
            Text(appBuildMarker, style: HelioTypography.bodyMuted),
          ]),
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: EdgeInsets.zero,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: HelioSpacing.lg, vertical: 0),
              leading: const Icon(Icons.article_outlined,
                  size: 18, color: HelioColors.textMuted),
              title: Text('Sync Log', style: HelioTypography.body),
              iconColor: HelioColors.textMuted,
              collapsedIconColor: HelioColors.textMuted,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
                  child: SyncLogPanel(logs: syncLogs),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: HelioSpacing.xxl),
        _wordmark(),
      ],
    );
  }

  Widget _wordmark() => Center(
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/images/logo.png', height: 64, width: 64),
          ),
          const SizedBox(height: HelioSpacing.md),
          Text('HELIOLYTICS',
              style: HelioTypography.sectionTitle.copyWith(
                color: HelioColors.textMuted,
                letterSpacing: 4,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: HelioSpacing.xs),
          Text('Version $appBuildMarker',
              style: HelioTypography.bodyMuted.copyWith(fontSize: 9)),
        ]),
      );
}
