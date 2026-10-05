import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/localization.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = AppConstants.defaultLanguage;
  bool _isLoading = true;

  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;

  Locale get locale {
    switch (_currentLanguage) {
      case 'বাংলা':
        return const Locale('bn', '');
      case 'English':
        return const Locale('en', '');
      case 'हिंदी':
        return const Locale('hi', '');
      default:
        return const Locale('bn', '');
    }
  }

  String get localeCode {
    switch (_currentLanguage) {
      case 'বাংলা':
        return 'bn';
      case 'English':
        return 'en';
      case 'हिंदी':
        return 'hi';
      default:
        return 'bn';
    }
  }

  LanguageProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(AppConstants.prefLanguage) ?? AppConstants.defaultLanguage;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    if (!AppConstants.languages.contains(language)) return;
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLanguage, language);
    notifyListeners();
  }

  /// Use context.t('key') or AppLocalizations.of(context).translate('key')
  /// for full Flutter localization support with JSON files.
  /// This method is kept for backward compatibility.
  String translate(String key) {
    // Note: For proper localization, use context.t('key') instead
    // which reads from the JSON files in assets/lang/
    return key;
  }
}
