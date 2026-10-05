import 'package:flutter/material.dart';
import '../data/models/bill_model.dart';
import '../data/models/product_model.dart';
import '../data/services/billing_service.dart';
import '../data/repositories/bill_repository.dart';

class CartItem {
  final ProductModel product;
  double quantity;
  double unitPrice;
  double get total => quantity * unitPrice;
  double get gstAmount => total * (product.gstPercent / 100);
  double get finalTotal => total + gstAmount;

  CartItem({
    required this.product,
    this.quantity = 1,
    required this.unitPrice,
  });
}

class BillProvider extends ChangeNotifier {
  final BillingService _billingService = BillingService();
  final BillRepository _billRepo = BillRepository();

  final List<CartItem> _cart = [];
  String _customerName = '';
  String _customerPhone = '';
  String _paymentMethod = 'cash';
  double _discount = 0.0;
  double _amountPaid = 0.0;
  bool _isProcessing = false;
  String? _error;

  List<CartItem> get cart => List.unmodifiable(_cart);
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get paymentMethod => _paymentMethod;
  double get discount => _discount;
  double get amountPaid => _amountPaid;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  double get subtotal => _cart.fold(0, (sum, item) => sum + item.total);
  double get gstAmount => _cart.fold(0, (sum, item) => sum + item.gstAmount);
  double get totalAmount => subtotal + gstAmount - _discount;
  double get amountDue => totalAmount - _amountPaid;
  int get itemCount => _cart.length;

  void addToCart(ProductModel product, {double quantity = 1}) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      _cart[existingIndex].quantity += quantity;
    } else {
      _cart.add(CartItem(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
      ));
    }
    _amountPaid = totalAmount;
    notifyListeners();
  }

  void updateQuantity(String productId, double quantity) {
    final index = _cart.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;
    if (quantity <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index].quantity = quantity;
    }
    _amountPaid = totalAmount;
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((item) => item.product.id == productId);
    _amountPaid = totalAmount;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _customerName = '';
    _customerPhone = '';
    _discount = 0.0;
    _amountPaid = 0.0;
    _error = null;
    notifyListeners();
  }

  void setCustomerInfo({String? name, String? phone}) {
    if (name != null) _customerName = name;
    if (phone != null) _customerPhone = phone;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setDiscount(double discount) {
    _discount = discount;
    _amountPaid = totalAmount;
    notifyListeners();
  }

  void setAmountPaid(double amount) {
    _amountPaid = amount;
    notifyListeners();
  }

  Future<bool> checkout(String businessType) async {
    if (_cart.isEmpty) {
      _setError('Cart is empty');
      return false;
    }

    _setProcessing(true);
    try {
      final billNumber = await _billRepo.getNextBillNumber(businessType);
      final bill = BillModel(
        billNumber: billNumber,
        customerName: _customerName.isEmpty ? 'Walk-in Customer' : _customerName,
        customerPhone: _customerPhone.isEmpty ? null : _customerPhone,
        items: _cart.map((item) => BillItemModel(
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          gstPercent: item.product.gstPercent,
          totalPrice: item.finalTotal,
          batchNumber: item.product.batchNumber,
          imei: item.product.imei,
          size: item.product.size,
          color: item.product.color,
        )).toList(),
        subtotal: subtotal,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        discount: _discount,
        paymentMethod: _paymentMethod,
        amountPaid: _amountPaid,
        amountDue: amountDue,
        businessType: businessType,
      );

      await _billingService.processSale(bill);
      clearCart();
      return true;
    } catch (e) {
      _setError('Checkout failed: $e');
      return false;
    } finally {
      _setProcessing(false);
    }
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
