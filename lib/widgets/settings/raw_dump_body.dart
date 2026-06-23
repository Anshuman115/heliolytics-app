import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/strap_dump_provider.dart';
import 'package:heliolytics/widgets/settings/settings_action_button.dart';

const _dumpAccent = Color(0xFFE040FB);

/// Expanded body of the Raw Strap Dump card: progress, result, logs, actions.
class RawDumpBody extends ConsumerWidget {
  const RawDumpBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dump = ref.watch(strapDumpProvider);
    final fetching =
        dump.phase == DumpPhase.fetching || dump.phase == DumpPhase.connecting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          HelioSpacing.lg, 0, HelioSpacing.lg, HelioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Fetches all 255 type codes (0x01→0xFF) for the last 2 days from the '
            'strap and saves raw bytes for analysis.',
            style: HelioTypography.bodyMuted.copyWith(fontSize: 11),
          ),
          const SizedBox(height: HelioSpacing.md),
          if (fetching) ...[_progress(dump), const SizedBox(height: HelioSpacing.sm)],
          if (dump.phase == DumpPhase.done) ...[_doneSummary(dump), const SizedBox(height: HelioSpacing.sm)],
          if (dump.phase == DumpPhase.error) ...[_errorBox(dump), const SizedBox(height: HelioSpacing.sm)],
          if (dump.logs.isNotEmpty) ...[_logs(dump), const SizedBox(height: HelioSpacing.sm)],
          _actions(ref, dump, fetching),
        ],
      ),
    );
  }

  Widget _progress(DumpState dump) => Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: dump.phase == DumpPhase.connecting ? null : dump.progress,
                backgroundColor: HelioColors.surfaceElevated,
                color: _dumpAccent,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: HelioSpacing.sm),
          Text(
            dump.phase == DumpPhase.connecting
                ? 'Connecting…'
                : '${dump.currentCode} (${dump.currentIndex + 1}/${dump.totalCodes})',
            style: HelioTypography.capsLabel.copyWith(fontSize: 10),
          ),
        ],
      );

  Widget _doneSummary(DumpState dump) {
    final kb = dump.codeBytes.values.fold<int>(0, (a, b) => a + b) ~/ 1024;
    return _box(HelioColors.optimalGreen, withBorder: true, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('✓ Dump complete',
            style: HelioTypography.body.copyWith(
                color: HelioColors.optimalGreen, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Text('${dump.codeBytes.length} types with data  •  $kb KB total',
            style: HelioTypography.bodyMuted.copyWith(fontSize: 11)),
      ],
    ));
  }

  Widget _errorBox(DumpState dump) => _box(HelioColors.recoveryLow, child: Text(
        dump.errorMessage ?? 'Unknown error',
        style: HelioTypography.bodyMuted.copyWith(color: HelioColors.recoveryLow, fontSize: 11),
      ));

  Widget _logs(DumpState dump) => Container(
        constraints: const BoxConstraints(maxHeight: 200),
        padding: const EdgeInsets.all(HelioSpacing.sm),
        decoration: BoxDecoration(
          color: HelioColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          reverse: true,
          child: Text(dump.logs.join('\n'),
              style: HelioTypography.bodyMuted.copyWith(
                  fontSize: 9, fontFamily: 'monospace', height: 1.5)),
        ),
      );

  Widget _actions(WidgetRef ref, DumpState dump, bool fetching) {
    final notifier = ref.read(strapDumpProvider.notifier);
    return Row(children: [
      Expanded(
        child: SettingsActionButton(
          icon: fetching ? null : Icons.download_outlined,
          label: fetching ? 'DUMPING…' : 'START DUMP',
          color: _dumpAccent,
          loading: fetching,
          onTap: fetching ? null : notifier.startDump,
        ),
      ),
      if (dump.phase == DumpPhase.done) ...[
        const SizedBox(width: HelioSpacing.sm),
        Expanded(
          child: SettingsActionButton(
            icon: Icons.share_outlined,
            label: 'SHARE',
            color: HelioColors.strainBlue,
            onTap: notifier.shareDump,
          ),
        ),
      ],
      if (dump.logs.isNotEmpty && dump.phase != DumpPhase.idle) ...[
        const SizedBox(width: HelioSpacing.sm),
        Expanded(
          child: SettingsActionButton(
            icon: Icons.description_outlined,
            label: 'SHARE LOGS',
            color: const Color(0xFFFF9800),
            onTap: notifier.shareLogs,
          ),
        ),
      ],
    ]);
  }

  Widget _box(Color c, {required Widget child, bool withBorder = false}) => Container(
        padding: const EdgeInsets.all(HelioSpacing.sm),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: withBorder ? Border.all(color: c.withValues(alpha: 0.3)) : null,
        ),
        child: child,
      );
}
