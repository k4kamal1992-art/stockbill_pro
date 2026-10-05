import '../database/database_helper.dart';
import '../models/bill_model.dart';
import '../models/product_model.dart';
import '../models/stock_transaction_model.dart';
import '../repositories/product_repository.dart';
import '../repositories/bill_repository.dart';
import '../repositories/stock_transaction_repository.dart';

class BillingService {
  final ProductRepository _productRepo = ProductRepository();
  final BillRepository _billRepo = BillRepository();
  final StockTransactionRepository _stockTransRepo = StockTransactionRepository();

  /// Sale complete: bill create + stock update + transaction log
  Future<String> processSale(BillModel bill) async {
    final db = await DatabaseHelper().database;

    return await db.transaction((txn) async {
      // 1. Stock validation
      for (final item in bill.items) {
        final productResults = await txn.query(
          DatabaseHelper.tableProducts,
          where: 'id = ? AND isActive = 1',
          whereArgs: [item.productId],
        );
        if (productResults.isEmpty) {
          throw Exception('Product not found: ${item.productName}');
        }
        final product = ProductModel.fromMap(productResults.first);
        if (product.stockQuantity < item.quantity) {
          throw Exception(
            'Insufficient stock for ${item.productName}. Available: ${product.stockQuantity}, Requested: ${item.quantity}',
          );
        }
      }

      // 2. Insert bill
      await txn.insert(
        DatabaseHelper.tableBills,
        bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Bill items + stock update + transaction log
      for (final item in bill.items) {
        await txn.insert(
          DatabaseHelper.tableBillItems,
          {...item.toMap(), 'billId': bill.id},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final productResults = await txn.query(
          DatabaseHelper.tableProducts,
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        final product = ProductModel.fromMap(productResults.first);
        final previousStock = product.stockQuantity;
        final newStock = previousStock - item.quantity;

        await txn.update(
          DatabaseHelper.tableProducts,
          {
            'stockQuantity': newStock,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        await txn.insert(
          DatabaseHelper.tableStockTransactions,
          StockTransactionModel(
            productId: item.productId,
            productName: item.productName,
            type: TransactionType.sale,
            quantity: item.quantity,
            previousStock: previousStock,
            newStock: newStock,
            referenceId: bill.id,
            notes: 'Sold in bill ${bill.billNumber}',
          ).toMap(),
        );
      }

      return bill.id;
    });
  }

  /// Return process: bill update + stock restore
  Future<void> processReturn(String billId) async {
    final db = await DatabaseHelper().database;

    await db.transaction((txn) async {
      final itemResults = await txn.query(
        DatabaseHelper.tableBillItems,
        where: 'billId = ?',
        whereArgs: [billId],
      );

      for (final itemRow in itemResults) {
        final productId = itemRow['productId'] as String;
        final quantity = (itemRow['quantity'] as num).toDouble();
        final productName = itemRow['productName'] as String;

        final productResults = await txn.query(
          DatabaseHelper.tableProducts,
          where: 'id = ?',
          whereArgs: [productId],
        );
        final product = ProductModel.fromMap(productResults.first);
        final previousStock = product.stockQuantity;
        final newStock = previousStock + quantity;

        await txn.update(
          DatabaseHelper.tableProducts,
          {
            'stockQuantity': newStock,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [productId],
        );

        await txn.insert(
          DatabaseHelper.tableStockTransactions,
          StockTransactionModel(
            productId: productId,
            productName: productName,
            type: TransactionType.return_in,
            quantity: quantity,
            previousStock: previousStock,
            newStock: newStock,
            referenceId: billId,
            notes: 'Returned from bill',
          ).toMap(),
        );
      }

      await txn.update(
        DatabaseHelper.tableBills,
        {'isReturned': 1},
        where: 'id = ?',
        whereArgs: [billId],
      );
    });
  }

  /// Today's total sales
  Future<double> getTodaySales(String businessType) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await DatabaseHelper().rawQuery('''
      SELECT COALESCE(SUM(totalAmount), 0) as total
      FROM ${DatabaseHelper.tableBills}
      WHERE businessType = ? AND billDate >= ? AND billDate < ? AND isReturned = 0
    ''', [businessType, startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return (results.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Monthly total sales
  Future<double> getMonthlySales(String businessType) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    final results = await DatabaseHelper().rawQuery('''
      SELECT COALESCE(SUM(totalAmount), 0) as total
      FROM ${DatabaseHelper.tableBills}
      WHERE businessType = ? AND billDate >= ? AND billDate < ? AND isReturned = 0
    ''', [
      businessType,
      startOfMonth.toIso8601String(),
      startOfNextMonth.toIso8601String()
    ]);

    return (results.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
