import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_secondary_button.dart';
import 'package:heliolytics/design_system/components/helio_text_field.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/api_config_form_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/utils/error_messages.dart';

class ApiSettingsScreen extends ConsumerStatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  ConsumerState<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends ConsumerState<ApiSettingsScreen> {
  final _url = TextEditingController();
  final _apiKey = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _url.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _bindForm(ApiConfigForm form) {
    if (_loaded) return;
    _url.text = form.url;
    _apiKey.text = form.apiKey;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(apiConfigFormProvider);
    return Scaffold(
      appBar: HelioTopBar(
        showBack: true,
        onBack: () => context.pop(),
        title: 'Cloud API',
      ),
      body: form.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load settings',
            style: HelioTypography.bodyMuted,
          ),
        ),
        data: (cfg) {
          _bindForm(cfg);
          return ListView(
            padding: const EdgeInsets.all(HelioSpacing.lg),
            children: [
              Text(
                'Enter the HTTPS origin of your Heliolytics API and the phone '
                'API key. Required before your first strap sync.',
                style: HelioTypography.bodyMuted,
              ),
              if (cfg.needsKeyReentry) ...[
                const SizedBox(height: HelioSpacing.md),
                const Text(
                  'Re-enter the new phone API key. The old v1 secret is no '
                  'longer accepted.',
                ),
              ],
              if (cfg.keyError != null) ...[
                const SizedBox(height: HelioSpacing.md),
                Text(cfg.keyError!),
              ],
              const SizedBox(height: HelioSpacing.lg),
              HelioTextField(
                controller: _url,
                label: 'API base URL',
                hint: 'https://api.example.com',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: HelioSpacing.md),
              HelioTextField(
                controller: _apiKey,
                label: 'Phone API key',
                hint: 'phone.<64 hex characters>',
                obscureText: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: HelioSpacing.md),
                Text(_error!, style: HelioTypography.bodyMuted),
              ],
              const SizedBox(height: HelioSpacing.lg),
              HelioSecondaryButton(
                label: _testing ? 'Testing…' : 'Test connection',
                loading: _testing,
                icon: Icons.link,
                onPressed: _testing ? null : _test,
              ),
              if (_testResult != null) ...[
                const SizedBox(height: HelioSpacing.sm),
                Text(_testResult!, style: HelioTypography.bodyMuted),
              ],
              const SizedBox(height: HelioSpacing.md),
              HelioPrimaryButton(
                label: _saving ? 'Saving…' : 'Save',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _persist() async {
    setState(() {
      _error = null;
      _testResult = null;
    });
    try {
      await ref
          .read(apiConfigFormProvider.notifier)
          .save(_url.text, _apiKey.text);
      return true;
    } catch (e) {
      setState(() => _error = friendlyError(e));
      return false;
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final saved = await _persist();
    if (!saved) {
      if (mounted) setState(() => _testing = false);
      return;
    }
    try {
      final ok = await ref.read(metricsApiClientProvider).testConnection();
      if (!mounted) return;
      setState(
        () => _testResult = ok
            ? 'Connected'
            : 'The server rejected the test request',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _testResult = friendlyError(e));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await _persist();
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API settings saved')));
    context.pop();
  }
}
