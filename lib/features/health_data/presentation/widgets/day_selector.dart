import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/presentation/providers/selected_day_provider.dart';

class DaySelector extends ConsumerWidget {
  const DaySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final keys = ref.watch(availableDayKeysProvider);
    if (day == null) return const SizedBox.shrink();

    final idx = keys.indexOf(day.dayKey);
    final canPrev = idx < keys.length - 1;
    final canNext = idx > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _navBtn(context, Icons.chevron_left, canPrev, () => shiftSelectedDay(ref, -1)),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(context, ref, keys, day.dayKey),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    Text(
                      formatDayLabel(day.dayKey),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      day.dayKey,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _navBtn(context, Icons.chevron_right, canNext, () => shiftSelectedDay(ref, 1)),
        ],
      ),
    );
  }

  Widget _navBtn(BuildContext ctx, IconData icon, bool enabled, VoidCallback onTap) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        disabledBackgroundColor: Theme.of(ctx).colorScheme.surface.withValues(alpha: 0.4),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    List<String> keys,
    String current,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: keys.length,
          itemBuilder: (_, i) {
            final k = keys[i];
            return ListTile(
              selected: k == current,
              title: Text(formatDayLabel(k)),
              subtitle: Text(k),
              onTap: () => Navigator.pop(ctx, k),
            );
          },
        ),
      ),
    );
    if (picked != null) selectDay(ref, picked);
  }
}
