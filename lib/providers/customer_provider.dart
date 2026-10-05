import 'package:flutter/material.dart';
import '../data/models/customer_model.dart';
import '../data/repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repo = CustomerRepository();

  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];
  List<CustomerModel> _dueCustomers = [];
  CustomerModel? _selectedCustomer;
  bool _isLoading = false;
  String? _error;
  double _totalDue = 0;

  List<CustomerModel> get customers => _filteredCustomers.isEmpty && _searchQuery.isEmpty
      ? _customers
      : _filteredCustomers;
  List<CustomerModel> get dueCustomers => _dueCustomers;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalDue => _totalDue;

  String _searchQuery = '';

  Future<void> loadCustomers() async {
    _setLoading(true);
    _clearError();
    try {
      _customers = await _repo.getAllCustomers();
      _filteredCustomers = [];
      _searchQuery = '';
      notifyListeners();
    } catch (e) {
      _setError('Failed to load customers: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchCustomers(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredCustomers = [];
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      _filteredCustomers = await _repo.searchCustomers(query);
      notifyListeners();
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDueCustomers() async {
    _setLoading(true);
    try {
      _dueCustomers = await _repo.getCustomersWithDue();
      _totalDue = _dueCustomers.fold(0, (sum, c) => sum + c.totalDue);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load due list: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> calculateTotalDue() async {
    try {
      _totalDue = await _repo.getTotalDueAmount();
      notifyListeners();
    } catch (e) {
      _setError('Failed to calculate due: $e');
    }
  }

  Future<bool> addCustomer(CustomerModel customer) async {
    _setLoading(true);
    try {
      await _repo.insertCustomer(customer);
      _customers.insert(0, customer);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add customer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    _setLoading(true);
    try {
      await _repo.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update customer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> recordPayment(String customerId, double amount, {String? note}) async {
    try {
      await _repo.recordPayment(customerId, amount, note: note);
      // Refresh customer data
      final customer = await _repo.getCustomerById(customerId);
      if (customer != null) {
        final index = _customers.indexWhere((c) => c.id == customerId);
        if (index != -1) {
          _customers[index] = customer;
        }
        final dueIndex = _dueCustomers.indexWhere((c) => c.id == customerId);
        if (dueIndex != -1) {
          if (customer.totalDue <= 0) {
            _dueCustomers.removeAt(dueIndex);
          } else {
            _dueCustomers[dueIndex] = customer;
          }
        }
        _totalDue -= amount;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Payment failed: $e');
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _repo.softDeleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      _dueCustomers.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete customer: $e');
      return false;
    }
  }

  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredCustomers = [];
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
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
