import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController {
  OnboardingController._();
  static final OnboardingController instance = OnboardingController._();

  static const _key = 'onboarding.done';

  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
