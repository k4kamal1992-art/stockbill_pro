import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/bill_model.dart';

class BillRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // CREATE bill with items (transaction)
  Future<String> createBill(BillModel bill) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Insert bill
      await txn.insert(
        DatabaseHelper.tableBills,
        bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Insert bill items
      for (final item in bill.items) {
        await txn.insert(
          DatabaseHelper.tableBillItems,
          {
            ...item.toMap(),
            'billId': bill.id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    return bill.id;
  }

  // READ - Single bill with items
  Future<BillModel?> getBillById(String id) async {
    final db = await _db.database;
    final billResults = await db.query(
      DatabaseHelper.tableBills,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (billResults.isEmpty) return null;

    final itemResults = await db.query(
      DatabaseHelper.tableBillItems,
      where: 'billId = ?',
      whereArgs: [id],
    );

    final billMap = Map<String, dynamic>.from(billResults.first);
    billMap['items'] = itemResults;
    return BillModel.fromMap(billMap);
  }

  // READ - All bills by business type
  Future<List<BillModel>> getBillsByBusiness(String businessType, {int limit = 50}) async {
    final db = await _db.database;
    final billResults = await db.query(
      DatabaseHelper.tableBills,
      where: 'businessType = ?',
      whereArgs: [businessType],
      orderBy: 'billDate DESC',
      limit: limit,
    );

    final bills = <BillModel>[];
    for (final billRow in billResults) {
      final itemResults = await db.query(
        DatabaseHelper.tableBillItems,
        where: 'billId = ?',
        whereArgs: [billRow['id']],
      );
      final billMap = Map<String, dynamic>.from(billRow);
      billMap['items'] = itemResults;
      bills.add(BillModel.fromMap(billMap));
    }
    return bills;
  }

  // READ - Bills by date range
  Future<List<BillModel>> getBillsByDateRange(
    String businessType,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _db.database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final billResults = await db.query(
      DatabaseHelper.tableBills,
      where: 'businessType = ? AND billDate BETWEEN ? AND ?',
      whereArgs: [businessType, startStr, endStr],
      orderBy: 'billDate DESC',
    );

    final bills = <BillModel>[];
    for (final billRow in billResults) {
      final itemResults = await db.query(
        DatabaseHelper.tableBillItems,
        where: 'billId = ?',
        whereArgs: [billRow['id']],
      );
      final billMap = Map<String, dynamic>.from(billRow);
      billMap['items'] = itemResults;
      bills.add(BillModel.fromMap(billMap));
    }
    return bills;
  }

  // READ - Bills by customer
  Future<List<BillModel>> getBillsByCustomer(String customerPhone) async {
    final db = await _db.database;
    final billResults = await db.query(
      DatabaseHelper.tableBills,
      where: 'customerPhone = ?',
      whereArgs: [customerPhone],
      orderBy: 'billDate DESC',
    );

    final bills = <BillModel>[];
    for (final billRow in billResults) {
      final itemResults = await db.query(
        DatabaseHelper.tableBillItems,
        where: 'billId = ?',
        whereArgs: [billRow['id']],
      );
      final billMap = Map<String, dynamic>.from(billRow);
      billMap['items'] = itemResults;
      bills.add(BillModel.fromMap(billMap));
    }
    return bills;
  }

  // READ - Due bills
  Future<List<BillModel>> getDueBills(String businessType) async {
    final db = await _db.database;
    final billResults = await db.query(
      DatabaseHelper.tableBills,
      where: 'businessType = ? AND amountDue > 0',
      whereArgs: [businessType],
      orderBy: 'billDate DESC',
    );

    final bills = <BillModel>[];
    for (final billRow in billResults) {
      final itemResults = await db.query(
        DatabaseHelper.tableBillItems,
        where: 'billId = ?',
        whereArgs: [billRow['id']],
      );
      final billMap = Map<String, dynamic>.from(billRow);
      billMap['items'] = itemResults;
      bills.add(BillModel.fromMap(billMap));
    }
    return bills;
  }

  // UPDATE - Mark as returned
  Future<int> markBillReturned(String billId) async {
    return await _db.update(
      DatabaseHelper.tableBills,
      data: {
        'isReturned': 1,
      },
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  // UPDATE - Update payment
  Future<int> updatePayment(
    String billId,
    double amountPaid,
    double amountDue,
  ) async {
    return await _db.update(
      DatabaseHelper.tableBills,
      data: {
        'amountPaid': amountPaid,
        'amountDue': amountDue,
      },
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  // DELETE
  Future<int> deleteBill(String id) async {
    return await _db.delete(
      DatabaseHelper.tableBills,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ANALYTICS - Daily sales
  Future<Map<String, double>> getDailySales(
    String businessType,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await _db.rawQuery(
      '''
      SELECT date(billDate) as date, SUM(totalAmount) as total
      FROM ${DatabaseHelper.tableBills}
      WHERE businessType = ? AND billDate BETWEEN ? AND ?
      GROUP BY date(billDate)
      ORDER BY date(billDate)
      ''',
      [businessType, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return {
      for (final row in results)
        row['date'] as String: (row['total'] as num).toDouble()
    };
  }

  // ANALYTICS - Total sales summary
  Future<Map<String, dynamic>> getSalesSummary(
    String businessType,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await _db.rawQuery(
      '''
      SELECT
        COUNT(*) as billCount,
        SUM(subtotal) as subtotal,
        SUM(gstAmount) as gstAmount,
        SUM(totalAmount) as totalAmount,
        SUM(amountDue) as totalDue
      FROM ${DatabaseHelper.tableBills}
      WHERE businessType = ? AND billDate BETWEEN ? AND ?
      ''',
      [businessType, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    if (results.isEmpty) return {};
    final row = results.first;
    return {
      'billCount': (row['billCount'] as num?)?.toInt() ?? 0,
      'subtotal': (row['subtotal'] as num?)?.toDouble() ?? 0.0,
      'gstAmount': (row['gstAmount'] as num?)?.toDouble() ?? 0.0,
      'totalAmount': (row['totalAmount'] as num?)?.toDouble() ?? 0.0,
      'totalDue': (row['totalDue'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // Get next bill number
  Future<String> getNextBillNumber(String businessType) async {
    final prefix = businessType.substring(0, 1).toUpperCase();
    final results = await _db.rawQuery(
      '''
      SELECT billNumber FROM ${DatabaseHelper.tableBills}
      WHERE businessType = ?
      ORDER BY createdAt DESC
      LIMIT 1
      ''',
      [businessType],
    );

    if (results.isEmpty) {
      return '${prefix}-0001';
    }

    final lastNumber = results.first['billNumber'] as String;
    final numericPart = int.tryParse(lastNumber.split('-').last) ?? 0;
    final nextNumber = (numericPart + 1).toString().padLeft(4, '0');
    return '$prefix-$nextNumber';
  }
}
