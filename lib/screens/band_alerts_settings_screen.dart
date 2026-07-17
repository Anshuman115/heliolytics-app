import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/providers/band_alerts_provider.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/widgets/settings/band_alerts_readiness_bar.dart';

class BandAlertsSettingsScreen extends ConsumerWidget {
  const BandAlertsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(bandAlertsProvider);
    final band = ref.watch(bandSessionProvider);
    final cfg = alerts.config;
    final checklist = alerts.readiness.checklist(cfg);
    final busy = alerts.isLoading;

    return Scaffold(
      appBar: HelioTopBar(showBack: true, onBack: () => context.pop(), title: 'Band Alerts'),
      body: ListView(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_subtitle(cfg.enabled, alerts.isReady, band),
                    style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
              ),
              Switch.adaptive(
                value: cfg.enabled,
                onChanged: busy
                    ? null
                    : (v) async {
                        final ok = await ref.read(bandAlertsProvider.notifier).setEnabled(v);
                        if (!context.mounted) return;
                        if (!ok && v) {
                          final msg = ref.read(bandAlertsProvider).errorMessage;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg ?? 'Complete setup before enabling')),
                          );
                        }
                      },
              ),
            ],
          ),
          if (alerts.errorMessage != null) ...[
            const SizedBox(height: HelioSpacing.sm),
            Text(alerts.errorMessage!,
                style: HelioTypography.bodyMuted.copyWith(color: HelioColors.syncError, fontSize: 12)),
          ],
          if (cfg.enabled && alerts.lastForwardStatus != null) ...[
            const SizedBox(height: HelioSpacing.sm),
            Text(alerts.lastForwardStatus!, style: HelioTypography.bodyMuted.copyWith(fontSize: 11)),
          ],
          if (!cfg.enabled || !alerts.isReady) ...[
            const SizedBox(height: HelioSpacing.md),
            BandAlertsReadinessBar(
              items: checklist,
              onFixTap: () => ref.read(bandAlertsProvider.notifier).requestPermissions(),
            ),
          ],
          const SizedBox(height: HelioSpacing.md),
          _toggleRow('Forward calls', cfg.forwardCalls,
              busy ? null : (v) => ref.read(bandAlertsProvider.notifier).setForwardCalls(v)),
          if (cfg.forwardCalls) ...[
            const SizedBox(height: HelioSpacing.sm),
            _callPatternRow(context),
          ],
          const SizedBox(height: HelioSpacing.sm),
          _appsRow(context, cfg.allowedPackages.length),
          if (cfg.allowedPackages.isEmpty && cfg.forwardCalls) ...[
            const SizedBox(height: HelioSpacing.sm),
            _callsOnlyChip(ref, cfg.callsOnly, busy),
          ],
        ],
      ),
    );
  }

  String _subtitle(bool enabled, bool ready, BandSessionSnapshot band) {
    if (enabled) {
      if (band.isConnected) return 'Forwarding active — strap connected.';
      if (band.isConnecting) return 'Connecting to strap…';
      return band.errorMessage ?? 'Strap disconnected — toggle off and on to recover.';
    }
    if (ready) return 'Forward calls and app notifications to your strap.';
    return 'Set up permissions and choose what to forward.';
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool>? onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: HelioTypography.body.copyWith(fontSize: 14))),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _callPatternRow(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/settings/band-alerts/call-pattern'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HelioSpacing.xs),
        child: Row(
          children: [
            Expanded(child: Text('Call vibration pattern', style: HelioTypography.body.copyWith(fontSize: 14))),
            const Icon(Icons.waves, size: 18, color: HelioColors.textMuted),
            const SizedBox(width: HelioSpacing.xs),
            const Icon(Icons.chevron_right, size: 18, color: HelioColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _appsRow(BuildContext context, int count) {
    return InkWell(
      onTap: () => context.push('/settings/band-alerts/apps'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HelioSpacing.xs),
        child: Row(
          children: [
            Expanded(child: Text('Allowed apps', style: HelioTypography.body.copyWith(fontSize: 14))),
            Text(count == 0 ? 'None' : '$count selected', style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
            const Icon(Icons.chevron_right, size: 18, color: HelioColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _callsOnlyChip(WidgetRef ref, bool selected, bool busy) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilterChip(
        label: const Text('Calls only'),
        selected: selected,
        onSelected: busy ? null : (v) => ref.read(bandAlertsProvider.notifier).setCallsOnly(v),
      ),
    );
  }
}
