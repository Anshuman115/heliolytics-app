import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/band_alerts_call_pattern_provider.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/zepp/vibration_pattern_service.dart';
import 'package:heliolytics/utils/app_logger.dart';

class BandAlertsCallPatternScreen extends ConsumerStatefulWidget {
  const BandAlertsCallPatternScreen({super.key});

  @override
  ConsumerState<BandAlertsCallPatternScreen> createState() =>
      _BandAlertsCallPatternScreenState();
}

class _BandAlertsCallPatternScreenState
    extends ConsumerState<BandAlertsCallPatternScreen> {
  final _fields = <TextEditingController>[];
  bool _busy = false;
  String? _error;

  void _log(String msg) =>
      AppLogger.instance.log(msg, tag: 'band_alerts_call_pattern_ui');

  @override
  void initState() {
    super.initState();
    _loadFields(ref.read(bandAlertsCallPatternProvider));
  }

  void _loadFields(List<int> ms) {
    for (final c in _fields) {
      c.dispose();
    }
    _fields
      ..clear()
      ..addAll(ms.map((v) => TextEditingController(text: v.toString())));
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
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

  Future<void> _save() async {
    final parsed = _parse();
    if (parsed == null) {
      setState(() => _error = 'Enter valid ON/OFF ms pairs (10–10000)');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(bandAlertsCallPatternProvider.notifier).setPattern(parsed);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testOnce() async {
    final parsed = _parse();
    if (parsed == null) {
      setState(() => _error = 'Enter valid ON/OFF ms pairs (10–10000)');
      return;
    }
    await _withLink((link) async {
      final ok = await VibrationPatternService(log: _log).testBuzz(
        link,
        type: vibrationTypeIncomingCall,
        onOffMs: parsed,
      );
      if (!ok) throw StateError('Pattern test send failed');
    });
  }

  Future<void> _withLink(Future<void> Function(BandLink link) run) async {
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
      await run(link);
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
        title: const Text('Call pattern'),
        backgroundColor: HelioColors.canvas,
        actions: [
          TextButton(onPressed: _busy ? null : _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: [
          Text(
            'Repeats while the phone is ringing.',
            style: HelioTypography.bodyMuted.copyWith(fontSize: 13),
          ),
          const SizedBox(height: HelioSpacing.md),
          for (var i = 0; i < pairs; i++) _pairRow(i),
          const SizedBox(height: HelioSpacing.md),
          Row(
            children: [
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _fields
                            ..add(TextEditingController(text: '100'))
                            ..add(TextEditingController(text: '200'));
                        }),
                child: const Text('Add pair'),
              ),
              const SizedBox(width: HelioSpacing.sm),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => setState(
                          () => _loadFields(bandAlertsDefaultCallPatternMs),
                        ),
                child: const Text('Reset'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _testOnce,
                child: Text(_busy ? 'Testing…' : 'Test once'),
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
            onPressed: _busy
                ? null
                : () => setState(() {
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
}
