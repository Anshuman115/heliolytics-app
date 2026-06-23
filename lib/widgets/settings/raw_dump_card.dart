import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/strap_dump_provider.dart';
import 'package:heliolytics/widgets/settings/raw_dump_body.dart';

/// Collapsible diagnostic card that runs a full raw strap dump.
class RawDumpCard extends ConsumerWidget {
  const RawDumpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dump = ref.watch(strapDumpProvider);
    return HelioSurfaceCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: HelioSpacing.lg, vertical: 0),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE040FB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.science_outlined, size: 17, color: Color(0xFFE040FB)),
          ),
          title: Text('Raw Strap Dump',
              style: HelioTypography.body.copyWith(fontWeight: FontWeight.w500)),
          subtitle: Text(_subtitle(dump),
              style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
          iconColor: HelioColors.textMuted,
          collapsedIconColor: HelioColors.textMuted,
          children: const [RawDumpBody()],
        ),
      ),
    );
  }

  String _subtitle(DumpState dump) => switch (dump.phase) {
        DumpPhase.idle => 'Fetch all type codes (2 days)',
        DumpPhase.connecting => 'Connecting to strap…',
        DumpPhase.fetching =>
          'Fetching ${dump.currentCode} (${dump.currentIndex + 1}/${dump.totalCodes})',
        DumpPhase.done => '${dump.codeBytes.length} types dumped',
        DumpPhase.error => 'Error — tap to retry',
      };
}
