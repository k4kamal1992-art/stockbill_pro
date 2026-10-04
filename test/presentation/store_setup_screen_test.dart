import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockbill_pro/core/constants/business_config.dart';
import 'package:stockbill_pro/presentation/screens/onboarding/store_setup_screen.dart';
import 'package:stockbill_pro/providers/business_provider.dart';
import 'package:stockbill_pro/providers/shop_provider.dart';

Widget _wrap() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BusinessProvider()),
      ChangeNotifierProvider(create: (_) => ShopProvider()),
    ],
    child: const MaterialApp(
      home: StoreSetupScreen(businessType: BusinessType.grocery),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('fields start empty (no sample data)', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('মা ভাবানী স্টোর'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('empty form shows validation errors and does not continue',
      (tester) async {
    await tester.pumpWidget(_wrap());
    final button = find.text('সেটআপ সম্পূর্ণ করুন');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(find.text('দোকানের নাম দিন'), findsOneWidget);
    expect(find.text('ঠিকানা দিন'), findsOneWidget);
    expect(find.text('১০ digit এর ফোন নম্বর দিন'), findsOneWidget);
    // still on the setup screen
    expect(find.byType(StoreSetupScreen), findsOneWidget);
  });
}
