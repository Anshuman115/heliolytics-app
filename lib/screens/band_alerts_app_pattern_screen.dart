import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/providers/band_alerts_app_patterns_provider.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/zepp/vibration_pattern_service.dart';
import 'package:heliolytics/utils/app_logger.dart';

class BandAlertsAppPatternArgs {
  final String packageId;
  final String label;
  const BandAlertsAppPatternArgs({required this.packageId, required this.label});
}

class BandAlertsAppPatternScreen extends ConsumerStatefulWidget {
  final BandAlertsAppPatternArgs args;
  const BandAlertsAppPatternScreen({super.key, required this.args});

  @override
  ConsumerState<BandAlertsAppPatternScreen> createState() =>
      _BandAlertsAppPatternScreenState();
}

class _BandAlertsAppPatternScreenState
    extends ConsumerState<BandAlertsAppPatternScreen> {
  final _fields = <TextEditingController>[];
  bool _busy = false;
  String? _error;

  void _log(String msg) =>
      AppLogger.instance.log(msg, tag: 'band_alerts_pattern_ui');

  @override
  void initState() {
    super.initState();
    final existing =
        ref.read(bandAlertsAppPatternsProvider)[widget.args.packageId];
    final ms = existing ?? bandAlertsDefaultAppPatternMs;
    for (final v in ms) {
      _fields.add(TextEditingController(text: v.toString()));
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPair() {
    setState(() {
      _fields.add(TextEditingController(text: '100'));
      _fields.add(TextEditingController(text: '200'));
    });
  }

  void _removePair(int pairIdx) {
    final start = pairIdx * 2;
    if (start + 1 >= _fields.length) return;
    setState(() {
      _fields[start].dispose();
      _fields[start + 1].dispose();
      _fields.removeAt(start + 1);
      _fields.removeAt(start);
    });
  }

  List<int>? _parse() {
    final out = <int>[];
    for (final c in _fields) {
      final raw = c.text.trim();
      final v = int.tryParse(raw);
      if (v == null) return null;
      if (v < 10 || v > 10_000) return null;
      out.add(v);
    }
    if (out.isEmpty || out.length.isOdd) return null;
    return out;
  }

  Future<void> _save() async {
    final parsed = _parse();
    if (parsed == null) {
      setState(() => _error = 'Enter valid ms values (10–10000), in ON/OFF pairs');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(bandAlertsAppPatternsProvider.notifier)
          .setPattern(widget.args.packageId, parsed);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _error = null);
    final def = bandAlertsDefaultAppPatternMs;
    setState(() {
      for (final c in _fields) {
        c.dispose();
      }
      _fields
        ..clear()
        ..addAll(def.map((v) => TextEditingController(text: v.toString())));
    });
  }

  Future<void> _testNow() async {
    final parsed = _parse();
    if (parsed == null) {
      setState(() => _error = 'Enter valid ms values (10–10000), in ON/OFF pairs');
      return;
    }

    final sync = ref.read(syncOrchestratorProvider);
    if (sync.state == SessionState.fetching ||
        sync.state == SessionState.connecting) {
      setState(() => _error = 'Wait for sync to finish');
      return;
    }

    final band = ref.read(bandSessionProvider.notifier);
    final alertsOn =
        ref.read(bandSessionProvider).activeOp == BandSessionOp.bandAlerts;
    if (!alertsOn) {
      final blocked = band.tryAcquire(BandSessionOp.motorProof);
      if (blocked != null) {
        setState(() => _error = blocked);
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await band.ensureConnected()) {
        throw StateError(
          ref.read(bandSessionProvider).errorMessage ?? 'Connect failed',
        );
      }
      final link = band.session.link;
      if (link is! BandLink) throw StateError('No strap link');
      _log('testing pattern ${widget.args.packageId}: $parsed');
      final ok = await VibrationPatternService(log: _log).testBuzz(
        link,
        type: vibrationTypeAppAlerts,
        onOffMs: parsed,
      );
      if (!ok) throw StateError('Pattern test send failed');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (!alertsOn) band.release(BandSessionOp.motorProof);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairs = _fields.length ~/ 2;

    return Scaffold(
      backgroundColor: HelioColors.canvas,
      appBar: AppBar(
        title: Text('${widget.args.label} pattern'),
        backgroundColor: HelioColors.canvas,
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: [
          Text(widget.args.packageId,
              style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
          const SizedBox(height: HelioSpacing.md),
          Text(
            'Enter ON/OFF durations in milliseconds.',
            style: HelioTypography.bodyMuted.copyWith(fontSize: 13),
          ),
          const SizedBox(height: HelioSpacing.md),
          for (var i = 0; i < pairs; i++) _pairRow(i),
          const SizedBox(height: HelioSpacing.md),
          Row(
            children: [
              OutlinedButton(
                onPressed: _busy ? null : _addPair,
                child: const Text('Add pair'),
              ),
              const SizedBox(width: HelioSpacing.sm),
              OutlinedButton(
                onPressed: _busy ? null : _resetToDefault,
                child: const Text('Reset'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _testNow,
                child: Text(_busy ? 'Testing…' : 'Test now'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: HelioSpacing.md),
            Text(
              _error!,
              style: HelioTypography.bodyMuted
                  .copyWith(color: HelioColors.syncError),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pairRow(int pairIdx) {
    final onCtrl = _fields[pairIdx * 2];
    final offCtrl = _fields[pairIdx * 2 + 1];
    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: onCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ON (ms)'),
            ),
          ),
          const SizedBox(width: HelioSpacing.sm),
          Expanded(
            child: TextField(
              controller: offCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OFF (ms)'),
            ),
          ),
          IconButton(
            onPressed: _busy ? null : () => _removePair(pairIdx),
            icon: const Icon(Icons.close),
            tooltip: 'Remove pair',
          ),
        ],
      ),
    );
  }
}

