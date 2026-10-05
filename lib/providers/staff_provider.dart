import 'package:flutter/material.dart';
import '../data/models/staff_model.dart';
import '../data/repositories/staff_repository.dart';

class StaffProvider extends ChangeNotifier {
  final StaffRepository _repo = StaffRepository();

  List<StaffModel> _staff = [];
  StaffModel? _currentStaff;
  bool _isLoading = false;

  List<StaffModel> get staff => _staff;
  StaffModel? get currentStaff => _currentStaff;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentStaff != null;

  StaffPermissions get permissions =>
      _currentStaff?.permissions ?? const StaffPermissions();

  Future<void> loadStaff({String? shopId}) async {
    _isLoading = true;
    notifyListeners();
    _staff = await _repo.getAllStaff(shopId: shopId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithPin(String pin) async {
    final staff = await _repo.validatePin(pin);
    if (staff != null) {
      _currentStaff = staff;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentStaff = null;
    notifyListeners();
  }

  Future<void> addStaff(StaffModel staff) async {
    await _repo.createStaff(staff);
    await loadStaff(shopId: staff.shopId);
  }

  Future<void> updateStaff(StaffModel staff) async {
    await _repo.updateStaff(staff);
    if (_currentStaff?.id == staff.id) {
      _currentStaff = staff;
    }
    await loadStaff(shopId: staff.shopId);
  }

  Future<void> deleteStaff(String id, {String? shopId}) async {
    await _repo.deleteStaff(id);
    if (_currentStaff?.id == id) {
      _currentStaff = null;
    }
    await loadStaff(shopId: shopId);
  }
}
