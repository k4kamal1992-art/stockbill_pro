import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockbill_pro/presentation/screens/settings/settings_screen.dart';
import 'package:stockbill_pro/providers/business_provider.dart';
import 'package:stockbill_pro/providers/language_provider.dart';
import 'package:stockbill_pro/providers/theme_provider.dart';

Widget _wrap() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => BusinessProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shop profile row opens the edit dialog', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.tap(find.text('দোকানের প্রোফাইল'));
    await tester.pumpAndSettle();
    expect(find.text('দোকানের নাম *'), findsOneWidget);
    expect(find.text('সেভ'), findsOneWidget);
  });

  testWidgets('language row opens the language picker', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.ensureVisible(find.text('ভাষা'));
    await tester.tap(find.text('ভাষা'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('dark mode row toggles the real theme', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    final context = tester.element(find.byType(SettingsScreen));
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    expect(theme.isDarkMode, false);
    await tester.ensureVisible(find.text('ডার্ক মোড'));
    await tester.tap(find.text('ডার্ক মোড'));
    await tester.pumpAndSettle();
    expect(theme.isDarkMode, true);
  });
}
