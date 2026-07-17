import 'package:heliolytics/models/user_profile.dart';

class OnboardingState {
  final bool onboardingComplete;
  final UserProfile? profile;

  const OnboardingState({required this.onboardingComplete, this.profile});
}
