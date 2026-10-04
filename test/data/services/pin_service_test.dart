import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockbill_pro/core/constants/app_constants.dart';
import 'package:stockbill_pro/data/services/pin_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('no PIN by default', () async {
    expect(await PinService.hasPin(), false);
    expect(await PinService.verify('1234'), false);
  });

  test('set then verify; stored value is not the plain PIN', () async {
    await PinService.setPin('4821');
    expect(await PinService.hasPin(), true);
    expect(await PinService.verify('4821'), true);
    expect(await PinService.verify('1234'), false);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefPin), isNot('4821'));
  });
}
