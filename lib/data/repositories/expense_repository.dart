import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> createExpense(ExpenseModel expense) async {
    final db = await _db.database;
    await db.insert(DatabaseHelper.tableExpenses, expense.toMap());
    return expense.id;
  }

  Future<List<ExpenseModel>> getAllExpenses({
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <Object?>[];

    if (shopId != null) {
      conditions.add('shopId = ?');
      args.add(shopId);
    }
    if (startDate != null) {
      conditions.add("date(expenseDate) >= date(?)");
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add("date(expenseDate) <= date(?)");
      args.add(endDate.toIso8601String());
    }
    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final maps = await db.query(
      DatabaseHelper.tableExpenses,
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'expenseDate DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<Map<String, double>> getExpenseSummary({
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <Object?>[];

    if (shopId != null) {
      conditions.add('shopId = ?');
      args.add(shopId);
    }
    if (startDate != null) {
      conditions.add("date(expenseDate) >= date(?)");
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add("date(expenseDate) <= date(?)");
      args.add(endDate.toIso8601String());
    }

    final where = conditions.isNotEmpty ? 'WHERE ' + conditions.join(' AND ') : '';

    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      ' + where + '
      GROUP BY category
    ''', args.isNotEmpty ? args : null);

    return {
      for (var row in result)
        row['category'] as String: (row['total'] as num).toDouble()
    };
  }

  Future<double> getTotalExpenses({String? shopId, DateTime? month}) async {
    final db = await _db.database;
    String where = '';
    List<Object?>? args;

    if (shopId != null && month != null) {
      where = "WHERE shopId = ? AND strftime('%Y-%m', expenseDate) = ?";
      args = [shopId, month.year.toString().padLeft(4, '0') + '-' + month.month.toString().padLeft(2, '0')];
    } else if (shopId != null) {
      where = 'WHERE shopId = ?';
      args = [shopId];
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses ' + where,
      args,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<void> deleteExpense(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
