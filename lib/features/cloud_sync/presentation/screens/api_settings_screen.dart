import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/utils/error_messages.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/api_config_form_provider.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';

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
      appBar: AppBar(title: const Text('Cloud API')),
      body: form.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load settings')),
        data: (cfg) {
          _bindForm(cfg);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Enter your Heliolytics API URL and API key.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _url,
                decoration: const InputDecoration(
                  labelText: 'API base URL',
                  hintText: 'https://api.example.com',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _secret,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'API key',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: _testing ? null : () => _test(ref),
                child: Text(_testing ? 'Testing…' : 'Test connection'),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_testResult!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: _saving ? null : () => _save(),
                child: Text(_saving ? 'Saving…' : 'Save'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kDebugMode
              ? 'Enter a valid http:// or https:// URL'
              : 'Enter a valid HTTPS URL'),
        ),
      );
      return;
    }
    final httpsOk = uri.scheme == 'https';
    final httpDevOk = kDebugMode && uri.scheme == 'http';
    if (!httpsOk && !httpDevOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kDebugMode
              ? 'Enter a valid http:// or https:// URL'
              : 'Enter a valid HTTPS URL'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await ref.read(apiConfigFormProvider.notifier).save(_url.text, _secret.text);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API settings saved')),
      );
      Navigator.pop(context);
    }
  }
}
