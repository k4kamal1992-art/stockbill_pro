import 'package:flutter/material.dart';
import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repo = ExpenseRepository();

  List<ExpenseModel> _expenses = [];
  Map<String, double> _summary = {};
  double _total = 0;
  bool _isLoading = false;

  List<ExpenseModel> get expenses => _expenses;
  Map<String, double> get summary => _summary;
  double get total => _total;
  bool get isLoading => _isLoading;

  Future<void> loadExpenses({String? shopId}) async {
    _isLoading = true;
    notifyListeners();
    _expenses = await _repo.getAllExpenses(shopId: shopId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSummary({String? shopId, DateTime? startDate, DateTime? endDate}) async {
    _summary = await _repo.getExpenseSummary(
      shopId: shopId,
      startDate: startDate,
      endDate: endDate,
    );
    _total = _summary.values.fold(0, (a, b) => a + b);
    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _repo.createExpense(expense);
    await loadExpenses(shopId: expense.shopId);
    await loadSummary(shopId: expense.shopId);
  }

  Future<void> deleteExpense(String id, {String? shopId}) async {
    await _repo.deleteExpense(id);
    await loadExpenses(shopId: shopId);
    await loadSummary(shopId: shopId);
  }
}
