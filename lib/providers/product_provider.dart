import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _lowStockProducts = [];
  List<ProductModel> _outOfStockProducts = [];
  Map<String, int> _stockSummary = {};
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _filteredProducts.isEmpty && _searchQuery.isEmpty
      ? _products
      : _filteredProducts;
  List<ProductModel> get lowStockProducts => _lowStockProducts;
  List<ProductModel> get outOfStockProducts => _outOfStockProducts;
  Map<String, int> get stockSummary => _stockSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String _searchQuery = '';
  String _currentBusinessType = 'grocery';

  Future<void> loadProducts(String businessType) async {
    _currentBusinessType = businessType;
    _setLoading(true);
    _clearError();
    try {
      _products = await _repo.getProductsByBusiness(businessType);
      _filteredProducts = [];
      _searchQuery = '';
      notifyListeners();
    } catch (e) {
      _setError('Failed to load products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchProducts(String query, {String? businessType}) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredProducts = [];
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      _filteredProducts = await _repo.searchProducts(
        query,
        businessType: businessType ?? _currentBusinessType,
      );
      notifyListeners();
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLowStock(String businessType) async {
    _setLoading(true);
    try {
      _lowStockProducts = await _repo.getLowStockProducts(businessType);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load low stock: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOutOfStock(String businessType) async {
    _setLoading(true);
    try {
      _outOfStockProducts = await _repo.getOutOfStockProducts(businessType);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load out of stock: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStockSummary(String businessType) async {
    try {
      _stockSummary = await _repo.getStockSummary(businessType);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load stock summary: $e');
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    _setLoading(true);
    try {
      await _repo.insertProduct(product);
      _products.insert(0, product);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    _setLoading(true);
    try {
      await _repo.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStock(String productId, double newQuantity) async {
    try {
      await _repo.updateStock(productId, newQuantity);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(stockQuantity: newQuantity);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update stock: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _repo.softDeleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete product: $e');
      return false;
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredProducts = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
