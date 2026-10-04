import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('bn', ''), // Bengali
    Locale('en', ''), // English
    Locale('hi', ''), // Hindi
  ];

  Map<String, String> _localizedStrings = {};

  Future<bool> load() async {
    String jsonString;
    try {
      jsonString = await rootBundle.loadString(
        'assets/lang/${locale.languageCode}.json',
      );
    } catch (_) {
      // Fallback to English if file not found
      jsonString = await rootBundle.loadString('assets/lang/en.json');
    }

    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  String translateWithArgs(String key, Map<String, String> args) {
    String value = _localizedStrings[key] ?? key;
    args.forEach((argKey, argValue) {
      value = value.replaceAll('{$argKey}', argValue);
    });
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['bn', 'en', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
