import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_secondary_button.dart';
import 'package:heliolytics/design_system/components/helio_text_field.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/providers/onboarding_provider.dart';
import 'package:heliolytics/services/network/profile_api_client.dart';
import 'package:heliolytics/utils/error_messages.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  String? _sex;
  String? _error;
  String? _cloudError;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _birthDate.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _bind(UserProfile? profile) {
    if (_loaded) return;
    _loaded = true;
    _name.text = profile?.name ?? '';
    final birth = profile?.birthDate;
    _birthDate.text = birth == null ? '' : formatDateOnly(birth);
    _sex = profile?.sex;
    _height.text = profile?.heightCm?.toStringAsFixed(1) ?? '';
    _weight.text = profile?.weightKg?.toStringAsFixed(1) ?? '';
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.codeUnits.length > 100) {
      return setState(() => _error = 'Keep the name under 100 characters.');
    }
    if (name.contains(RegExp(r'[\u0000-\u001F\u007F]'))) {
      return setState(
        () => _error = 'Remove control characters from the name.',
      );
    }
    final birthRaw = _birthDate.text.trim();
    final birthError = birthDateError(birthRaw);
    if (birthError != null) return setState(() => _error = birthError);

    final heightText = _height.text.trim();
    final height = heightText.isEmpty ? null : double.tryParse(heightText);
    if (heightText.isNotEmpty &&
        (height == null || height < 50 || height > 250)) {
      return setState(() => _error = 'Enter height in cm between 50 and 250.');
    }
    final weightText = _weight.text.trim();
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    if (weightText.isNotEmpty &&
        (weight == null || weight < 20 || weight > 300)) {
      return setState(() => _error = 'Enter weight in kg between 20 and 300.');
    }

    final profile = UserProfile(
      name: name.isEmpty ? null : name,
      birthDate: birthRaw.isEmpty ? null : parseDateOnly(birthRaw),
      sex: _sex,
      heightCm: height,
      weightKg: weight,
    );
    setState(() {
      _error = null;
      _cloudError = null;
      _saving = true;
    });
    await ref.read(onboardingProvider.notifier).completeOnboarding(profile);
    var savedToCloud = false;
    try {
      await ref.read(profileApiClientProvider).submitProfile(profile);
      await ref.read(healthDataRefreshCoordinatorProvider).afterSync();
      savedToCloud = true;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _cloudError = friendlyError(error);
      });
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (savedToCloud) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      context.go('/');
    }
  }

  List<Widget> _formFields() {
    return [
      HelioTextField(
        controller: _name,
        label: 'Name (optional)',
        hint: 'Jane Doe',
      ),
      const SizedBox(height: HelioSpacing.md),
      HelioTextField(
        controller: _birthDate,
        label: 'Birth date (optional)',
        hint: 'YYYY-MM-DD',
        keyboardType: TextInputType.datetime,
      ),
      const SizedBox(height: HelioSpacing.md),
      Text(
        'Sex for the training-load formula',
        style: HelioTypography.capsLabel,
      ),
      const SizedBox(height: HelioSpacing.xs),
      Wrap(
        spacing: HelioSpacing.sm,
        children: [
          for (final option in const [
            (label: 'Not set', value: null),
            (label: 'Male', value: UserProfile.male),
            (label: 'Female', value: UserProfile.female),
          ])
            ChoiceChip(
              label: Text(option.label),
              selected: _sex == option.value,
              onSelected: (_) => setState(() => _sex = option.value),
            ),
        ],
      ),
      const SizedBox(height: HelioSpacing.md),
      HelioTextField(
        controller: _height,
        label: 'Height in cm (optional)',
        hint: '170',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: HelioSpacing.md),
      HelioTextField(
        controller: _weight,
        label: 'Weight in kg (optional)',
        hint: '65',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _bind(ref.watch(onboardingProvider).profile);
    return Scaffold(
      appBar: const HelioTopBar(title: 'About you'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'All fields are optional. Without a birth date and sex, the '
              'Banister training-load estimate stays unavailable instead of '
              'being guessed.',
              style: HelioTypography.bodyMuted,
            ),
            const SizedBox(height: HelioSpacing.lg),
            if (_error != null) ...[
              Text(_error!, style: HelioTypography.bodyMuted),
              const SizedBox(height: HelioSpacing.md),
            ],
            ..._formFields(),
            const SizedBox(height: HelioSpacing.xl),
            HelioPrimaryButton(
              label: 'Save',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
            if (_cloudError != null) ...[
              const SizedBox(height: HelioSpacing.md),
              Text(
                'Saved on this device, but the cloud save failed: $_cloudError',
                style: HelioTypography.bodyMuted,
              ),
              const SizedBox(height: HelioSpacing.md),
              HelioSecondaryButton(
                label: 'Retry cloud save',
                icon: Icons.refresh,
                onPressed: _saving ? null : _save,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
