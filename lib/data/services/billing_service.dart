import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
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
        bill.toDbMap(),
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

      // 4. Credit sale: add the unpaid amount to the customer's due
      if (bill.amountDue > 0 && (bill.customerPhone?.isNotEmpty ?? false)) {
        final now = DateTime.now().toIso8601String();
        final existing = await txn.query(
          DatabaseHelper.tableCustomers,
          where: 'phone = ? AND isActive = 1',
          whereArgs: [bill.customerPhone],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final currentDue = (existing.first['totalDue'] as num?)?.toDouble() ?? 0.0;
          await txn.update(
            DatabaseHelper.tableCustomers,
            {'totalDue': currentDue + bill.amountDue, 'updatedAt': now},
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          await txn.insert(DatabaseHelper.tableCustomers, {
            'id': const Uuid().v4(),
            'name': bill.customerName,
            'phone': bill.customerPhone,
            'address': null,
            'totalDue': bill.amountDue,
            'totalPaid': 0.0,
            'createdAt': now,
            'updatedAt': now,
            'isActive': 1,
          });
        }
      }

      return bill.id;
    });
  }

  // ── Pure helpers (no database) ──────────────────────────────

  /// subtotal = sum(unitPrice * qty); gst = sum(line * gst%); total = subtotal + gst - discount
  Map<String, double> calculateBillTotals({
    required List<BillItemModel> items,
    double discount = 0,
  }) {
    double subtotal = 0;
    double gst = 0;
    for (final item in items) {
      final line = item.unitPrice * item.quantity;
      subtotal += line;
      gst += line * item.gstPercent / 100;
    }
    final total = (subtotal + gst - discount).clamp(0.0, double.infinity).toDouble();
    return {
      'subtotal': subtotal,
      'gstAmount': gst,
      'discount': discount,
      'total': total,
    };
  }

  /// Change to give back; 0 when the customer paid less than the total.
  double calculateChange({required double totalAmount, required double amountPaid}) {
    final change = amountPaid - totalAmount;
    return change > 0 ? change : 0.0;
  }

  /// Return process: bill update + stock restore
  Future<void> processReturn(String billId) async {
    final db = await DatabaseHelper().database;

    await db.transaction((txn) async {
      final billRows = await txn.query(
        DatabaseHelper.tableBills,
        where: 'id = ?',
        whereArgs: [billId],
        limit: 1,
      );
      if (billRows.isEmpty) {
        throw Exception('Bill not found');
      }
      if ((billRows.first['isReturned'] as int?) == 1) {
        throw Exception('This bill has already been returned');
      }

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
        if (productResults.isEmpty) continue; // product was removed; skip restock
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

      // Reverse the unpaid part of the bill from the customer's due
      final billDue = (billRows.first['amountDue'] as num?)?.toDouble() ?? 0.0;
      final phone = billRows.first['customerPhone'] as String?;
      if (billDue > 0 && phone != null && phone.isNotEmpty) {
        final cust = await txn.query(
          DatabaseHelper.tableCustomers,
          where: 'phone = ? AND isActive = 1',
          whereArgs: [phone],
          limit: 1,
        );
        if (cust.isNotEmpty) {
          final currentDue = (cust.first['totalDue'] as num?)?.toDouble() ?? 0.0;
          final newDue = (currentDue - billDue).clamp(0.0, double.infinity);
          await txn.update(
            DatabaseHelper.tableCustomers,
            {'totalDue': newDue, 'updatedAt': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [cust.first['id']],
          );
        }
      }
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
