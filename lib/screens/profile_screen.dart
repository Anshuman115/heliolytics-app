import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_text_field.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/providers/onboarding_provider.dart';
import 'package:heliolytics/services/network/profile_api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    if (name.isEmpty) return setState(() => _error = 'Enter your name');
    if (age == null || age < 1 || age > 120) {
      return setState(() => _error = 'Enter a valid age');
    }
    if (height == null || height < 50 || height > 250) {
      return setState(() => _error = 'Enter height in cm (50–250)');
    }
    if (weight == null || weight < 20 || weight > 300) {
      return setState(() => _error = 'Enter weight in kg (20–300)');
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final profile = UserProfile(name: name, age: age, heightCm: height, weightKg: weight);
    await ref.read(onboardingProvider.notifier).completeOnboarding(profile);
    unawaited(ref.read(profileApiClientProvider).submitProfile(profile));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(onboardingProvider).onboardingComplete && !_saving) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: const HelioTopBar(title: 'About you'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: HelioTypography.bodyMuted),
              const SizedBox(height: HelioSpacing.md),
            ],
            HelioTextField(controller: _name, label: 'Name', hint: 'Jane Doe'),
            const SizedBox(height: HelioSpacing.md),
            HelioTextField(
              controller: _age,
              label: 'Age',
              hint: '28',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: HelioSpacing.md),
            HelioTextField(
              controller: _height,
              label: 'Height (cm)',
              hint: '170',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: HelioSpacing.md),
            HelioTextField(
              controller: _weight,
              label: 'Weight (kg)',
              hint: '65',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: HelioSpacing.xl),
            HelioPrimaryButton(label: 'Continue', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
