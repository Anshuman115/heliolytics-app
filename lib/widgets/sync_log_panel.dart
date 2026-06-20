import 'package:flutter/material.dart';

class SyncLogPanel extends StatefulWidget {
  final List<String> logs;
  const SyncLogPanel({super.key, required this.logs});

  @override
  State<SyncLogPanel> createState() => _SyncLogPanelState();
}

class _SyncLogPanelState extends State<SyncLogPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.logs.isEmpty) return const SizedBox.shrink();
    final tail = widget.logs.length > 8
        ? widget.logs.sublist(widget.logs.length - 8)
        : widget.logs;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.terminal, size: 18),
                  const SizedBox(width: 8),
                  Text('Sync log (${widget.logs.length})'),
                  const Spacer(),
                  Icon(_open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SingleChildScrollView(
                child: SelectableText(
                  tail.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
