import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/onboarding_controller.dart';

/// Handles splash timing and onboarding flag before leaving `/`.
class BootstrapNotifier extends ChangeNotifier {
  bool done = false;
  bool onboardingComplete = false;

  BootstrapNotifier() {
    _init();
  }

  Future<void> _init() async {
    try {
      onboardingComplete = await OnboardingController.instance
          .isComplete()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (_) {
      onboardingComplete = false;
    }
    await Future.delayed(const Duration(milliseconds: 800));
    done = true;
    notifyListeners();
  }
}

final bootstrapProvider =
    ChangeNotifierProvider<BootstrapNotifier>((ref) => BootstrapNotifier());
