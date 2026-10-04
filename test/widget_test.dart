// Placeholder so `flutter create` does not generate its default counter-app
// test (which refers to a `MyApp` class this project does not have).
import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/core/constants/app_constants.dart';

void main() {
  test('app constants are defined', () {
    expect(AppConstants.prefPin, isNotEmpty);
    expect(AppConstants.prefOnboardingComplete, isNotEmpty);
  });
}
