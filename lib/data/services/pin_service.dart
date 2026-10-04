import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

/// Stores the app-lock PIN as a salted SHA-256 hash (never the PIN itself).
///
/// Note: a 4-digit PIN only has 10,000 combinations, so this is an app-lock
/// convenience, not strong security. Real protection against someone with
/// physical access to the phone is the phone's own lock screen.
class PinService {
  static const String _saltKey = 'pin_salt';

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefPin) != null;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final rnd = Random.secure();
    final salt = base64UrlEncode(List<int>.generate(16, (_) => rnd.nextInt(256)));
    await prefs.setString(_saltKey, salt);
    await prefs.setString(AppConstants.prefPin, _hash(pin, salt));
  }

  static Future<bool> verify(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_saltKey);
    final stored = prefs.getString(AppConstants.prefPin);
    if (salt == null || stored == null) return false;
    return _hash(pin, salt) == stored;
  }
}
