import '../database/database_helper.dart';
import '../models/stock_transaction_model.dart';

class StockTransactionRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> insertTransaction(StockTransactionModel transaction) async {
    await _db.insert(DatabaseHelper.tableStockTransactions, transaction.toMap());
    return transaction.id;
  }

  Future<List<StockTransactionModel>> getTransactionsByProduct(String productId) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableStockTransactions,
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'createdAt DESC',
    );
    return results.map((e) => StockTransactionModel.fromMap(e)).toList();
  }

  Future<List<StockTransactionModel>> getTransactionsByType(TransactionType type) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableStockTransactions,
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'createdAt DESC',
    );
    return results.map((e) => StockTransactionModel.fromMap(e)).toList();
  }

  Future<List<StockTransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableStockTransactions,
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return results.map((e) => StockTransactionModel.fromMap(e)).toList();
  }

  Future<List<StockTransactionModel>> getRecentTransactions({int limit = 50}) async {
    final db = await _db.database;
    final results = await db.query(
      DatabaseHelper.tableStockTransactions,
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return results.map((e) => StockTransactionModel.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> getTransactionSummary(DateTime start, DateTime end) async {
    final results = await _db.rawQuery('''
      SELECT
        type,
        COUNT(*) as count,
        SUM(quantity) as totalQuantity
      FROM ${DatabaseHelper.tableStockTransactions}
      WHERE createdAt BETWEEN ? AND ?
      GROUP BY type
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return {
      for (final row in results)
        row['type'] as String: {
          'count': (row['count'] as num).toInt(),
          'totalQuantity': (row['totalQuantity'] as num).toDouble(),
        }
    };
  }
}
