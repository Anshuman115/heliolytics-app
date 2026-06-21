import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/utils/error_messages.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/design_system/components/helio_cloud_banner.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/widgets/sync_log_panel.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final apiReady = ref.watch(apiConfiguredProvider);
    final health = ref.watch(liveHealthProvider);
    final busy = _isBusy(snap.state);
    final battery = health.valueOrNull?.batteryPercent;
    final lastSynced = health.valueOrNull?.lastSyncedAt;

    return Column(
      children: [
        HelioTopBar(
          title: 'Settings',
          batteryPercent: battery,
          strapConnected: snap.state == SessionState.connected ||
              snap.state == SessionState.fetching,
          syncActive: busy,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              HelioSpacing.lg,
              HelioSpacing.lg,
              HelioSpacing.lg,
              HelioSpacing.xxl,
            ),
            children: [
              // API warning banner
              apiReady.when(
                data: (ok) =>
                    ok ? const SizedBox.shrink() : const HelioCloudBanner(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // ── Device hero card ──────────────────────────────────────
              _DeviceHeroCard(
                state: snap.state,
                battery: battery,
                lastSynced: lastSynced,
                busy: busy,
                onSync: () => _sync(context, ref),
                onUpload: () => _upload(ref, context),
                onScan: () => context.push('/scan'),
              ),
              const SizedBox(height: HelioSpacing.xl),

              // ── Cloud section ─────────────────────────────────────────
              const _SectionLabel('CLOUD'),
              const SizedBox(height: HelioSpacing.sm),
              HelioSurfaceCard(
                padding: EdgeInsets.zero,
                child: _Tile(
                  icon: Icons.cloud_outlined,
                  iconColor: HelioColors.strainBlue,
                  title: 'API Configuration',
                  subtitle: apiReady.maybeWhen(
                    data: (ok) => ok ? 'Connected' : 'Required before first sync',
                    orElse: () => 'Checking…',
                  ),
                  statusDot: apiReady.maybeWhen(
                    data: (ok) => ok,
                    orElse: () => null,
                  ),
                  onTap: () => context.push('/settings/api'),
                ),
              ),
              const SizedBox(height: HelioSpacing.xl),

              // ── About section ─────────────────────────────────────────
              const _SectionLabel('ABOUT'),
              const SizedBox(height: HelioSpacing.sm),
              HelioSurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: HelioSpacing.lg,
                  vertical: HelioSpacing.md,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: HelioColors.textMuted),
                    const SizedBox(width: HelioSpacing.md),
                    Text('Build', style: HelioTypography.capsLabel),
                    const Spacer(),
                    Text(appBuildMarker, style: HelioTypography.bodyMuted),
                  ],
                ),
              ),
              const SizedBox(height: HelioSpacing.md),

              // ── Sync log (collapsible) ────────────────────────────────
              HelioSurfaceCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: HelioSpacing.lg,
                      vertical: 0,
                    ),
                    leading: const Icon(Icons.article_outlined,
                        size: 18, color: HelioColors.textMuted),
                    title: Text('Sync Log', style: HelioTypography.body),
                    iconColor: HelioColors.textMuted,
                    collapsedIconColor: HelioColors.textMuted,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
                        child: SyncLogPanel(logs: snap.logs),
                      ),
                    ],
                  ),
                ),
              ),
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
                        letterSpacing: 4,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: HelioSpacing.xs),
                    Text(
                      'Version $appBuildMarker',
                      style: HelioTypography.bodyMuted.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isBusy(SessionState state) =>
      state == SessionState.fetching ||
      state == SessionState.connecting ||
      state == SessionState.authenticating;

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    if (!await ref.read(syncOrchestratorProvider.notifier).hasSavedMac()) {
      if (!context.mounted) return;
      await context.push('/scan');
      return;
    }
    await ref.read(syncOrchestratorProvider.notifier).connect();
  }

  Future<void> _upload(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(syncOrchestratorProvider.notifier).retryLastUpload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload complete')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }
}

// ── Device Hero Card ──────────────────────────────────────────────────────────
class _DeviceHeroCard extends StatelessWidget {
  final SessionState state;
  final int? battery;
  final DateTime? lastSynced;
  final bool busy;
  final VoidCallback onSync;
  final VoidCallback onUpload;
  final VoidCallback onScan;

  const _DeviceHeroCard({
    required this.state,
    required this.battery,
    required this.lastSynced,
    required this.busy,
    required this.onSync,
    required this.onUpload,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(state);
    final statusLabel = _statusLabel(state);

    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.watch_outlined, color: statusColor, size: 24),
              ),
              const SizedBox(width: HelioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Helio Strap',
                      style: HelioTypography.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(statusLabel, style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              // Battery
              if (battery != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$battery%',
                      style: HelioTypography.scoreMedium.copyWith(
                        fontSize: 24,
                        color: battery! <= 20
                            ? HelioColors.recoveryLow
                            : battery! <= 50
                                ? HelioColors.recoveryMid
                                : HelioColors.optimalGreen,
                      ),
                    ),
                    Text('BATTERY', style: HelioTypography.capsLabel.copyWith(fontSize: 9)),
                  ],
                ),
            ],
          ),

          if (lastSynced != null) ...[
            const SizedBox(height: HelioSpacing.sm),
            const Divider(height: 1, color: Color(0x14FFFFFF)),
            const SizedBox(height: HelioSpacing.sm),
            Text(
              'Last synced ${formatWorkoutTime(lastSynced!)}',
              style: HelioTypography.bodyMuted.copyWith(fontSize: 11),
            ),
          ],

          const SizedBox(height: HelioSpacing.md),
          const Divider(height: 1, color: Color(0x14FFFFFF)),
          const SizedBox(height: HelioSpacing.md),

          // Action buttons row
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: busy ? null : Icons.sync,
                  label: busy ? 'SYNCING…' : 'SYNC NOW',
                  color: HelioColors.strainBlue,
                  loading: busy,
                  onTap: busy ? null : onSync,
                ),
              ),
              const SizedBox(width: HelioSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.cloud_upload_outlined,
                  label: 'UPLOAD',
                  color: HelioColors.optimalGreen,
                  onTap: busy ? null : onUpload,
                ),
              ),
              const SizedBox(width: HelioSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bluetooth_searching,
                  label: 'SCAN',
                  color: HelioColors.textMuted,
                  onTap: onScan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(SessionState state) => switch (state) {
        SessionState.connected => HelioColors.optimalGreen,
        SessionState.fetching => HelioColors.recoveryMid,
        SessionState.connecting => HelioColors.recoveryMid,
        SessionState.authenticating => HelioColors.recoveryMid,
        SessionState.idle => HelioColors.textMuted,
        SessionState.error => HelioColors.recoveryLow,
        _ => HelioColors.textMuted,
      };

  String _statusLabel(SessionState state) => switch (state) {
        SessionState.idle => 'Ready to sync',
        SessionState.noAuthKey => 'Auth key required',
        SessionState.scanning => 'Scanning…',
        SessionState.connecting => 'Connecting…',
        SessionState.authenticating => 'Pairing…',
        SessionState.connected => 'Connected',
        SessionState.fetching => 'Syncing data…',
        SessionState.listening => 'Listening…',
        SessionState.error => 'Sync error',
      };
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.12)
              : HelioColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null
                ? color.withValues(alpha: 0.3)
                : HelioColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 18, color: onTap != null ? color : HelioColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: HelioTypography.capsLabel.copyWith(
                fontSize: 9,
                color: onTap != null ? color : HelioColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 0),
      child: Text(text, style: HelioTypography.sectionTitle),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────
class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool? statusDot;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.statusDot,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HelioSpacing.lg,
          vertical: HelioSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: HelioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: HelioTypography.body.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            if (statusDot != null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: HelioSpacing.sm),
                decoration: BoxDecoration(
                  color: statusDot! ? HelioColors.optimalGreen : HelioColors.recoveryLow,
                  shape: BoxShape.circle,
                ),
              ),
            const Icon(Icons.chevron_right, size: 18, color: HelioColors.textMuted),
          ],
        ),
      ),
    );
  }
}
