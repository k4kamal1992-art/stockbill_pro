import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/business_config.dart';

class BusinessProvider extends ChangeNotifier {
  BusinessType _currentBusiness = BusinessType.grocery;
  String _storeName = '';
  String _storeAddress = '';
  String _storePhone = '';
  String _gstin = '';
  bool _isLoading = true;

  BusinessType get currentBusiness => _currentBusiness;
  BusinessConfig get config => BusinessConfig.of(_currentBusiness);
  String get storeName => _storeName;
  /// Name to show in headers; falls back to the app name until setup is done.
  String get displayName => _storeName.isEmpty ? 'StockBill Pro' : _storeName;
  String get storeAddress => _storeAddress;
  String get storePhone => _storePhone;
  String get gstin => _gstin;
  bool get isLoading => _isLoading;

  BusinessProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(AppConstants.prefBusinessType);
    if (savedType != null) {
      _currentBusiness = BusinessType.values.byName(savedType);
    }
    _storeName = prefs.getString(AppConstants.prefStoreName) ?? _storeName;
    _storeAddress = prefs.getString(AppConstants.prefStoreAddress) ?? '';
    _storePhone = prefs.getString(AppConstants.prefStorePhone) ?? '';
    _gstin = prefs.getString(AppConstants.prefGstin) ?? '';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBusinessType(BusinessType type) async {
    _currentBusiness = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefBusinessType, type.name);
    notifyListeners();
  }

  Future<void> setStoreInfo({
    String? name,
    String? address,
    String? phone,
    String? gstin,
  }) async {
    if (name != null) _storeName = name;
    if (address != null) _storeAddress = address;
    if (phone != null) _storePhone = phone;
    if (gstin != null) _gstin = gstin;

    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(AppConstants.prefStoreName, name);
    if (address != null) await prefs.setString(AppConstants.prefStoreAddress, address);
    if (phone != null) await prefs.setString(AppConstants.prefStorePhone, phone);
    if (gstin != null) await prefs.setString(AppConstants.prefGstin, gstin);
    notifyListeners();
  }
}
