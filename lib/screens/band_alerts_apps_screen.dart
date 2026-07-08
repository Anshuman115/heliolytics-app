import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/providers/band_alerts_provider.dart';
import 'package:heliolytics/screens/band_alerts_app_pattern_screen.dart';

class BandAlertsAppsScreen extends ConsumerWidget {
  const BandAlertsAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(bandAlertsProvider);
    final selected = alerts.config.allowedPackages;

    return Scaffold(
      backgroundColor: HelioColors.canvas,
      appBar: AppBar(
        title: const Text('Allowed apps'),
        backgroundColor: HelioColors.canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: [
          Text(
            'Only notifications from selected apps will buzz your strap.',
            style: HelioTypography.bodyMuted.copyWith(fontSize: 13),
          ),
          const SizedBox(height: HelioSpacing.lg),
          Text('SUGGESTED', style: _sectionStyle),
          const SizedBox(height: HelioSpacing.sm),
          HelioSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final app in bandAlertsSuggestedApps)
                  _AppRow(
                      label: app.value,
                      packageId: app.key,
                      selected: selected.contains(app.key),
                      onChanged: (v) => ref
                          .read(bandAlertsProvider.notifier)
                          .togglePackage(app.key, v),
                      onEditPattern: () => context.push(
                            '/settings/band-alerts/pattern',
                            extra: BandAlertsAppPatternArgs(
                              packageId: app.key,
                              label: app.value,
                            ),
                          )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final _sectionStyle = HelioTypography.sectionTitle.copyWith(
    fontSize: 12,
    letterSpacing: 1.2,
    color: HelioColors.textMuted,
  );
}

class _AppRow extends StatelessWidget {
  final String label;
  final String packageId;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEditPattern;

  const _AppRow({
    required this.label,
    required this.packageId,
    required this.selected,
    required this.onChanged,
    required this.onEditPattern,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: selected,
        onChanged: (v) => onChanged(v ?? false),
      ),
      title: Text(label, style: HelioTypography.body),
      subtitle: Text(
        packageId,
        style: HelioTypography.bodyMuted.copyWith(fontSize: 11),
      ),
      trailing: IconButton(
        onPressed: onEditPattern,
        icon: const Icon(Icons.waves),
        tooltip: 'Edit vibration pattern',
      ),
    );
  }
}
