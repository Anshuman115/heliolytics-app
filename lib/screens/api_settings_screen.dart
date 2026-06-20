import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/utils/error_messages.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_secondary_button.dart';
import 'package:heliolytics/design_system/components/helio_text_field.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/providers/api_config_form_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';

class ApiSettingsScreen extends ConsumerStatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  ConsumerState<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends ConsumerState<ApiSettingsScreen> {
  final _url = TextEditingController();
  final _secret = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;
  bool _loaded = false;

  @override
  void dispose() {
    _url.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _bindForm(ApiConfigForm form) {
    if (_loaded) return;
    _url.text = form.url;
    _secret.text = form.signingSecret;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(apiConfigFormProvider);
    return Scaffold(
      appBar: HelioTopBar(showBack: true, onBack: () => context.pop(), title: 'Cloud API'),
      body: form.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load settings', style: HelioTypography.bodyMuted)),
        data: (cfg) {
          _bindForm(cfg);
          return ListView(
            padding: const EdgeInsets.all(HelioSpacing.lg),
            children: [
              Text(
                'Enter your Heliolytics API URL and API key. Required before your first strap sync.',
                style: HelioTypography.bodyMuted,
              ),
              const SizedBox(height: HelioSpacing.lg),
              HelioTextField(
                controller: _url,
                label: 'API base URL',
                hint: 'https://api.example.com',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: HelioSpacing.md),
              HelioTextField(
                controller: _secret,
                label: 'API key',
                obscureText: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: HelioSpacing.lg),
              HelioSecondaryButton(
                label: _testing ? 'Testing…' : 'Test connection',
                loading: _testing,
                icon: Icons.link,
                onPressed: _testing ? null : () => _test(ref),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: HelioSpacing.sm),
                Text(_testResult!, style: HelioTypography.bodyMuted),
              ],
              const SizedBox(height: HelioSpacing.md),
              HelioPrimaryButton(
                label: _saving ? 'Saving…' : 'Save',
                loading: _saving,
                onPressed: _saving ? null : () => _save(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _test(WidgetRef ref) async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      await ref.read(apiConfigFormProvider.notifier).save(_url.text, _secret.text);
      final ok = await ref.read(metricsApiClientProvider).testConnection();
      setState(() => _testResult = ok ? 'Connected ✓' : 'Server returned an error');
    } catch (e) {
      setState(() => _testResult = friendlyError(e));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final uri = Uri.tryParse(_url.text.trim());
    if (uri == null || !uri.hasScheme) {
      _urlError();
      return;
    }
    final httpsOk = uri.scheme == 'https';
    final httpDevOk = kDebugMode && uri.scheme == 'http';
    if (!httpsOk && !httpDevOk) {
      _urlError();
      return;
    }
    setState(() => _saving = true);
    await ref.read(apiConfigFormProvider.notifier).save(_url.text, _secret.text);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API settings saved')),
      );
      context.pop();
    }
  }

  void _urlError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(kDebugMode
            ? 'Enter a valid http:// or https:// URL'
            : 'Enter a valid HTTPS URL'),
      ),
    );
  }
}
