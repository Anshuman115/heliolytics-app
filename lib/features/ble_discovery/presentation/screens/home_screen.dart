import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/features/ble_discovery/presentation/screens/device_scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    final canConnect =
        snap.state == SessionState.idle || snap.state == SessionState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heliolytics'),
        actions: [
          if (snap.state == SessionState.fetching && snap.currentTypeCode != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  snap.currentTypeCode!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          _StatusBar(snap: snap),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canConnect
                        ? () async {
                            final hasMac = await ref
                                .read(syncOrchestratorProvider.notifier)
                                .hasSavedMac();
                            if (!context.mounted) return;
                            if (hasMac) {
                              ref
                                  .read(syncOrchestratorProvider.notifier)
                                  .connect();
                            } else {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const DeviceScanScreen(),
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.bluetooth_searching, size: 18),
                    label: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 8),
                if (snap.state == SessionState.idle)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DeviceScanScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.radar, size: 18),
                    label: const Text('Scan'),
                  ),
                if (snap.typeResults.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      _copyResults(context, snap);
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ],
              ],
            ),
          ),

          // Type code results grid
          if (snap.typeResults.isNotEmpty) _TypeCodeGrid(results: snap.typeResults),

          const Divider(height: 1),

          // Live log panel
          Expanded(child: _LogPanel(logs: snap.logs)),
        ],
      ),
    );
  }

  void _copyResults(BuildContext context, SessionSnapshot snap) {
    final buf = StringBuffer();
    buf.writeln('=== Heliolytics Fetch Results ===');
    buf.writeln();
    for (final r in snap.typeResults) {
      final icon = r.status == 'ok' ? '✓' : r.status == 'empty' ? '—' : '✗';
      buf.writeln('$icon ${r.code} (${r.label}): ${r.status} — ${r.bytes} bytes');
      if (r.rawHex != null && r.rawHex!.isNotEmpty) {
        // First 2 lines = 32 bytes each = 64 hex chars per line
        final hex = r.rawHex!;
        final line1 = hex.length > 64 ? hex.substring(0, 64) : hex;
        final line2 = hex.length > 64
            ? (hex.length > 128 ? hex.substring(64, 128) : hex.substring(64))
            : null;
        buf.writeln('  hex[0]: $line1');
        if (line2 != null) buf.writeln('  hex[1]: $line2');
        if (hex.length > 128) buf.writeln('  ... (${r.bytes} bytes total)');
      }
    }
    buf.writeln();
    buf.writeln('=== Logs ===');
    for (final l in snap.logs) {
      buf.writeln(l);
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final SessionSnapshot snap;
  const _StatusBar({required this.snap});

  @override
  Widget build(BuildContext context) {
    final color = switch (snap.state) {
      SessionState.connected => Colors.green,
      SessionState.fetching => Colors.orange,
      SessionState.authenticating || SessionState.connecting => Colors.blue,
      SessionState.error => Colors.red,
      _ => Colors.grey,
    };
    final label = switch (snap.state) {
      SessionState.noAuthKey => 'No auth key',
      SessionState.idle => 'Idle',
      SessionState.scanning => 'Scanning…',
      SessionState.connecting => 'Connecting…',
      SessionState.authenticating => 'Authenticating…',
      SessionState.connected => 'Connected — ready',
      SessionState.fetching => snap.currentTypeCode != null
          ? 'Fetching ${snap.currentTypeCode}…'
          : 'Fetching…',
      SessionState.listening => 'Listening…',
      SessionState.error => 'Error: ${snap.lastErrorMessage ?? "unknown"}',
    };

    return Container(
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _TypeCodeGrid extends StatelessWidget {
  final List<TypeCodeResult> results;
  const _TypeCodeGrid({required this.results});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: results.length,
        itemBuilder: (_, i) {
          final r = results[i];
          final color = switch (r.status) {
            'ok' => Colors.green,
            'empty' => Colors.grey,
            'rejected' => Colors.orange,
            'error' => Colors.red,
            _ => Colors.blueGrey,
          };
          final icon = switch (r.status) {
            'ok' => Icons.check_circle,
            'empty' => Icons.remove_circle_outline,
            'rejected' => Icons.cancel,
            'error' => Icons.error,
            _ => Icons.help_outline,
          };

          return GestureDetector(
            onTap: r.rawHex != null ? () => _showHex(context, r) : null,
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    r.code,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.label,
                    style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (r.bytes > 0)
                    Text(
                      '${r.bytes}B',
                      style: TextStyle(fontSize: 9, color: color.withOpacity(0.6)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHex(BuildContext context, TypeCodeResult r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${r.code} — ${r.label}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text('${r.bytes} bytes', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: r.rawHex ?? ''));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  if (r.rawHex != null) ...[
                    const Text('Raw hex:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _formatHex(r.rawHex!),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ] else
                    const Text('No data', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHex(String hex) {
    final buf = StringBuffer();
    for (var i = 0; i < hex.length; i += 32) {
      final end = (i + 32).clamp(0, hex.length);
      final chunk = hex.substring(i, end);
      // Format as groups of 2
      final formatted = chunk.splitMapJoin(
        RegExp(r'..'),
        onMatch: (m) => '${m.group(0)} ',
        onNonMatch: (n) => n,
      );
      buf.writeln(formatted.trimRight());
    }
    return buf.toString();
  }
}

class _LogPanel extends StatelessWidget {
  final List<String> logs;
  const _LogPanel({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'Logs will appear here...\nConnect to your Helio strap to start.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E1E1E),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        reverse: false,
        itemBuilder: (_, i) {
          final line = logs[i];
          final color = line.contains('ERROR') || line.contains('FAILED')
              ? const Color(0xFFEF5350)
              : line.contains('SUCCESS') || line.contains('✓') || line.contains('COMPLETE')
                  ? const Color(0xFF66BB6A)
                  : line.contains('Fetching') || line.contains('Connecting')
                      ? const Color(0xFF42A5F5)
                      : const Color(0xFFBDBDBD);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              line,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: color,
                height: 1.4,
              ),
            ),
          );
        },
      ),
    );
  }
}
