import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/providers/onboarding_provider_state.dart';
import 'package:heliolytics/services/config/user_profile_storage.dart';

class OnboardingNotifier extends Notifier<OnboardingState> {
  late UserProfileStorage _storage;

  @override
  OnboardingState build() {
    _storage = ref.read(userProfileStorageProvider);
    _initAsync();
    return const OnboardingState(onboardingComplete: true, profile: null);
  }

  Future<void> _initAsync() async {
    final complete = await _storage.isOnboardingComplete();
    final profile = complete ? await _storage.readProfile() : null;
    state = OnboardingState(onboardingComplete: complete, profile: profile);
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    await _storage.saveProfile(profile);
    await _storage.markOnboardingComplete();
    state = OnboardingState(onboardingComplete: true, profile: profile);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
