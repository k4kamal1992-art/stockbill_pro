import 'package:flutter/material.dart';
import 'app_localizations.dart';

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get tr {
    final localizations = AppLocalizations.of(this);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  String t(String key) => tr.translate(key);
}
