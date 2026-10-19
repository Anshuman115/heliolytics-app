import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/strap_health_constants.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/providers/strap_health_config_provider.dart';

class StrapHealthCard extends ConsumerStatefulWidget {
  const StrapHealthCard({super.key});

  @override
  ConsumerState<StrapHealthCard> createState() => _StrapHealthCardState();
}

class _StrapHealthCardState extends ConsumerState<StrapHealthCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(strapHealthConfigProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(strapHealthConfigProvider);
    final config = state.config;
    final enabled = !state.isBusy && config != null;
    final lowAlert = config?.spo2LowAlert;

    return HelioSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Strap health', style: HelioTypography.sectionTitle),
          Text(
            'The app sends your choice when the strap connects and shows what the strap reports.',
            style: HelioTypography.bodyMuted,
          ),
          const SizedBox(height: HelioSpacing.md),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('All-day blood oxygen'),
            subtitle: Text(_allDaySubtitle(state)),
            value: config?.spo2AllDay ?? false,
            onChanged: enabled
                ? (value) => ref
                      .read(strapHealthConfigProvider.notifier)
                      .setAllDay(value)
                : null,
          ),
          DropdownButtonFormField<int>(
            value:
                lowAlert != null &&
                    strapHealthLowAlertChoices.contains(lowAlert)
                ? lowAlert
                : null,
            decoration: InputDecoration(
              labelText: 'Low blood-oxygen alert',
              helperText: _lowAlertSubtitle(state),
              helperMaxLines: 2,
            ),
            items: strapHealthLowAlertChoices
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(_thresholdLabel(value)),
                  ),
                )
                .toList(),
            onChanged: enabled
                ? (value) {
                    if (value != null) {
                      ref
                          .read(strapHealthConfigProvider.notifier)
                          .setLowAlert(value);
                    }
                  }
                : null,
          ),
          const SizedBox(height: HelioSpacing.md),
          Text(
            'Blood-oxygen checks can use battery. Battery life and measurement cadence vary by strap firmware; this is not a medical measurement or diagnosis.',
            style: HelioTypography.bodyMuted,
          ),
          if (state.error != null) ...[
            const SizedBox(height: HelioSpacing.sm),
            Text(
              state.error!,
              style: const TextStyle(color: HelioColors.syncError),
            ),
          ],
          const SizedBox(height: HelioSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () => ref.read(strapHealthConfigProvider.notifier).load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Read again'),
            ),
          ),
        ],
      ),
    );
  }

  String _allDaySubtitle(StrapHealthConfigState state) {
    final desired = state.desired.allDay;
    final actual = state.config?.spo2AllDay;
    final choice =
        'Your choice: ${desired == null ? 'not set' : (desired ? 'on' : 'off')}';
    if (state.phase == StrapHealthConfigPhase.applying) {
      return '$choice · applying';
    }
    if (actual == null) return '$choice · unknown';
    if (desired != null && desired != actual) {
      return '$choice · mismatch · strap reports ${actual ? 'on' : 'off'}';
    }
    return '$choice · strap reports ${actual ? 'on' : 'off'}';
  }

  String _lowAlertSubtitle(StrapHealthConfigState state) {
    final desired = state.desired.lowAlert;
    final actual = state.config?.spo2LowAlert;
    final choice = 'Your choice: ${_thresholdLabel(desired)}';
    if (state.phase == StrapHealthConfigPhase.applying) {
      return '$choice · applying';
    }
    if (actual == null) return '$choice · unknown';
    if (desired != null && desired != actual) {
      return '$choice · mismatch · strap reports ${_thresholdLabel(actual)}';
    }
    return '$choice · strap reports ${_thresholdLabel(actual)}';
  }

  String _thresholdLabel(int? value) =>
      value == null ? 'not set' : (value == 0 ? 'Off' : '$value%');
}
