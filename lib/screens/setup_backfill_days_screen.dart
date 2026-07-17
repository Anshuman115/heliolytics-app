// lib/screens/setup_backfill_days_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_text_field.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/components/helio_wizard_step_header.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/backfill_days_provider.dart';

const _presetDays = [7, 14, 30, 60];

class SetupBackfillDaysScreen extends ConsumerStatefulWidget {
  const SetupBackfillDaysScreen({super.key});

  @override
  ConsumerState<SetupBackfillDaysScreen> createState() => _SetupBackfillDaysScreenState();
}

class _SetupBackfillDaysScreenState extends ConsumerState<SetupBackfillDaysScreen> {
  int? _selected;
  bool _custom = false;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  int? get _chosen => _custom ? int.tryParse(_customCtrl.text.trim()) : _selected;

  void _finish() {
    final days = _chosen;
    if (days == null || days <= 0) return;
    ref.read(backfillDaysProvider.notifier).state = days;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HelioTopBar(showBack: true, onBack: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HelioWizardStepHeader(step: 5, totalSteps: 5, title: 'First sync range'),
            const SizedBox(height: HelioSpacing.lg),
            Text(
              'How many days of past data should we pull from your strap?',
              style: HelioTypography.bodyMuted,
            ),
            const SizedBox(height: HelioSpacing.lg),
            Wrap(
              spacing: HelioSpacing.sm,
              runSpacing: HelioSpacing.sm,
              children: [
                for (final d in _presetDays) _chip('$d days', selected: !_custom && _selected == d, onTap: () {
                  setState(() {
                    _custom = false;
                    _selected = d;
                  });
                }),
                _chip('Custom', selected: _custom, onTap: () => setState(() => _custom = true)),
              ],
            ),
            if (_custom) ...[
              const SizedBox(height: HelioSpacing.md),
              HelioTextField(
                controller: _customCtrl,
                hint: 'Number of days',
                keyboardType: TextInputType.number,
              ),
            ],
            const Spacer(),
            HelioPrimaryButton(
              label: 'Start syncing',
              onPressed: _chosen != null && _chosen! > 0 ? _finish : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.md, vertical: HelioSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? HelioColors.sleepBlue.withValues(alpha: 0.2) : HelioColors.surfaceElevated,
          borderRadius: BorderRadius.circular(HelioRadii.pill),
          border: Border.all(color: selected ? HelioColors.sleepBlue : HelioColors.border),
        ),
        child: Text(label, style: HelioTypography.body),
      ),
    );
  }
}
