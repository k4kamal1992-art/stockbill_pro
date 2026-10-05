import 'package:flutter/material.dart';
import '../data/models/supplier_model.dart';
import '../data/repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierRepository _repo = SupplierRepository();

  List<SupplierModel> _suppliers = [];
  SupplierModel? _selectedSupplier;
  bool _isLoading = false;

  List<SupplierModel> get suppliers => _suppliers;
  SupplierModel? get selectedSupplier => _selectedSupplier;
  bool get isLoading => _isLoading;

  Future<void> loadSuppliers({String? shopId}) async {
    _isLoading = true;
    notifyListeners();
    _suppliers = await _repo.getAllSuppliers(shopId: shopId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    await _repo.createSupplier(supplier);
    await loadSuppliers(shopId: supplier.shopId);
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    await _repo.updateSupplier(supplier);
    if (_selectedSupplier?.id == supplier.id) {
      _selectedSupplier = supplier;
    }
    await loadSuppliers(shopId: supplier.shopId);
  }

  Future<void> deleteSupplier(String id, {String? shopId}) async {
    await _repo.deleteSupplier(id);
    await loadSuppliers(shopId: shopId);
  }

  void selectSupplier(SupplierModel? supplier) {
    _selectedSupplier = supplier;
    notifyListeners();
  }

  Future<void> recordPayment(String supplierId, double amount, {String? shopId}) async {
    await _repo.updateBalance(supplierId, 0, amount);
    await loadSuppliers(shopId: shopId);
  }
}
