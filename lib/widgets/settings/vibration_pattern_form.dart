import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class VibrationPatternForm extends StatefulWidget {
  final List<int> initialMs;
  final List<int> defaultMs;
  final String hint;
  final bool busy;
  final String? error;
  final Future<void> Function(List<int> onOffMs) onTest;
  final Future<void> Function(List<int> onOffMs) onSave;

  const VibrationPatternForm({
    super.key,
    required this.initialMs,
    required this.defaultMs,
    required this.hint,
    required this.onTest,
    required this.onSave,
    this.busy = false,
    this.error,
  });

  @override
  State<VibrationPatternForm> createState() => _VibrationPatternFormState();
}

class _VibrationPatternFormState extends State<VibrationPatternForm> {
  final _fields = <TextEditingController>[];
  var _dirty = false;

  @override
  void initState() {
    super.initState();
    _seed(widget.initialMs);
  }

  @override
  void didUpdateWidget(VibrationPatternForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && oldWidget.initialMs != widget.initialMs) {
      _seed(widget.initialMs);
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(List<int> ms) {
    for (final c in _fields) {
      c.dispose();
    }
    _fields
      ..clear()
      ..addAll(ms.map((v) => TextEditingController(text: v.toString())));
  }

  List<int>? _parse() {
    final out = <int>[];
    for (final c in _fields) {
      final v = int.tryParse(c.text.trim());
      if (v == null || v < 10 || v > 10_000) return null;
      out.add(v);
    }
    if (out.isEmpty || out.length.isOdd) return null;
    return out;
  }

  Future<void> _run(Future<void> Function(List<int>) action) async {
    final parsed = _parse();
    if (parsed == null) return;
    await action(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final pairs = _fields.length ~/ 2;
    final parseError = _parse() == null && _fields.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      children: [
        Text(widget.hint, style: HelioTypography.bodyMuted.copyWith(fontSize: 13)),
        const SizedBox(height: HelioSpacing.md),
        for (var i = 0; i < pairs; i++) _pairRow(i),
        const SizedBox(height: HelioSpacing.md),
        Row(
          children: [
            OutlinedButton(
              onPressed: widget.busy
                  ? null
                  : () => setState(() {
                        _dirty = true;
                        _fields
                          ..add(TextEditingController(text: '100'))
                          ..add(TextEditingController(text: '200'));
                      }),
              child: const Text('Add pair'),
            ),
            const SizedBox(width: HelioSpacing.sm),
            OutlinedButton(
              onPressed: widget.busy
                  ? null
                  : () => setState(() {
                        _dirty = false;
                        _seed(widget.defaultMs);
                      }),
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: HelioSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.busy ? null : () => _run(widget.onTest),
                child: Text(widget.busy ? 'Testing…' : 'Test now'),
              ),
            ),
            const SizedBox(width: HelioSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: widget.busy ? null : () => _run(widget.onSave),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        if (parseError || widget.error != null) ...[
          const SizedBox(height: HelioSpacing.md),
          Text(
            widget.error ?? 'Enter valid ON/OFF ms pairs (10–10000)',
            style: HelioTypography.bodyMuted.copyWith(color: HelioColors.syncError),
          ),
        ],
      ],
    );
  }

  Widget _pairRow(int pairIdx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
      child: Row(
        children: [
          Expanded(child: _msField(_fields[pairIdx * 2], 'ON (ms)')),
          const SizedBox(width: HelioSpacing.sm),
          Expanded(child: _msField(_fields[pairIdx * 2 + 1], 'OFF (ms)')),
          IconButton(
            onPressed: widget.busy
                ? null
                : () => setState(() {
                      _dirty = true;
                      final start = pairIdx * 2;
                      if (start + 1 >= _fields.length) return;
                      _fields[start].dispose();
                      _fields[start + 1].dispose();
                      _fields.removeAt(start + 1);
                      _fields.removeAt(start);
                    }),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _msField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: HelioTypography.body,
      onChanged: (_) => _dirty = true,
      decoration: InputDecoration(labelText: label),
    );
  }
}
