import 'package:flutter/material.dart';
import '../data/models/shop_model.dart';
import '../data/repositories/shop_repository.dart';

class ShopProvider extends ChangeNotifier {
  final ShopRepository _repo = ShopRepository();

  List<ShopModel> _shops = [];
  ShopModel? _currentShop;
  bool _isLoading = false;

  List<ShopModel> get shops => _shops;
  ShopModel? get currentShop => _currentShop;
  bool get isLoading => _isLoading;

  Future<void> loadShops() async {
    _isLoading = true;
    notifyListeners();
    _shops = await _repo.getAllShops();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createShop(ShopModel shop) async {
    await _repo.createShop(shop);
    await loadShops();
  }

  Future<void> updateShop(ShopModel shop) async {
    await _repo.updateShop(shop);
    if (_currentShop?.id == shop.id) {
      _currentShop = shop;
    }
    await loadShops();
  }

  Future<void> deleteShop(String id) async {
    await _repo.deleteShop(id);
    if (_currentShop?.id == id) {
      _currentShop = null;
    }
    await loadShops();
  }

  void selectShop(ShopModel? shop) {
    _currentShop = shop;
    notifyListeners();
  }

  Future<void> switchShop(String shopId) async {
    final shop = await _repo.getShopById(shopId);
    if (shop != null) {
      _currentShop = shop;
      notifyListeners();
    }
  }

  Future<int> getShopBillCount(String shopId) async {
    return await _repo.getShopBillCount(shopId);
  }

  Future<double> getShopTotalSales(String shopId) async {
    return await _repo.getShopTotalSales(shopId);
  }
}
