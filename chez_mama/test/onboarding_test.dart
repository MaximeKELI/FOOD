import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chez_mama/onboarding/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('onboarding starts incomplete', () async {
    expect(await OnboardingController.instance.isComplete(), isFalse);
  });

  test('markComplete persists', () async {
    await OnboardingController.instance.markComplete();
    expect(await OnboardingController.instance.isComplete(), isTrue);
  });
}
