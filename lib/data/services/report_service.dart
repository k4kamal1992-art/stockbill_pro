import 'package:flutter/material.dart';
import '../database/database_helper.dart';

/// ReportService aggregates data from the database for reporting purposes.
class ReportService {
  final DatabaseHelper _db = DatabaseHelper();

  // ── Sales Reports ───────────────────────────────────────────

  /// Get daily sales totals for the last N days.
  Future<Map<String, double>> getDailySales({
    required String businessType,
    int days = 7,
  }) async {
    final db = await _db.database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    final result = await db.rawQuery('''
      SELECT date(billDate) as day, SUM(totalAmount) as total
      FROM bills
      WHERE businessType = ?
        AND date(billDate) BETWEEN date(?) AND date(?)
        AND isDeleted = 0
      GROUP BY date(billDate)
      ORDER BY day ASC
    ''', [
      businessType,
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
    ]);

    final Map<String, double> sales = {};
    for (final row in result) {
      sales[row['day'] as String] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key = date.toIso8601String().split('T')[0];
      sales.putIfAbsent(key, () => 0.0);
    }

    return Map.fromEntries(
      sales.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Get monthly sales totals for the last N months.
  Future<Map<String, double>> getMonthlySales({
    required String businessType,
    int months = 6,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();

    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', billDate) as month, SUM(totalAmount) as total
      FROM bills
      WHERE businessType = ?
        AND strftime('%Y-%m', billDate) >= strftime('%Y-%m', date('now', '-5 months'))
        AND isDeleted = 0
      GROUP BY strftime('%Y-%m', billDate)
      ORDER BY month ASC
    ''', [businessType]);

    final Map<String, double> sales = {};
    for (final row in result) {
      sales[row['month'] as String] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      sales.putIfAbsent(key, () => 0.0);
    }

    return Map.fromEntries(
      sales.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Get top selling products by quantity.
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required String businessType,
    int limit = 10,
  }) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT bi.productName, SUM(bi.quantity) as totalQty, SUM(bi.totalPrice) as totalRevenue
      FROM bill_items bi
      INNER JOIN bills b ON bi.billId = b.id
      WHERE b.businessType = ? AND b.isDeleted = 0
      GROUP BY bi.productId
      ORDER BY totalQty DESC
      LIMIT ?
    ''', [businessType, limit]);
  }

  /// Get payment method breakdown.
  Future<Map<String, double>> getPaymentMethodBreakdown({
    required String businessType,
    String period = 'today',
  }) async {
    final db = await _db.database;
    String dateFilter;
    switch (period) {
      case 'week':
        dateFilter = "date(billDate) >= date('now', '-7 days')";
        break;
      case 'month':
        dateFilter = "strftime('%Y-%m', billDate) = strftime('%Y-%m', 'now')";
        break;
      case 'today':
      default:
        dateFilter = "date(billDate) = date('now')";
    }

    final result = await db.rawQuery('''
      SELECT paymentMethod, SUM(totalAmount) as total
      FROM bills
      WHERE businessType = ? AND isDeleted = 0 AND $dateFilter
      GROUP BY paymentMethod
    ''', [businessType]);

    final Map<String, double> breakdown = {};
    for (final row in result) {
      breakdown[row['paymentMethod'] as String] =
          (row['total'] as num?)?.toDouble() ?? 0.0;
    }
    return breakdown;
  }

  /// Get total sales summary.
  Future<Map<String, dynamic>> getSalesSummary(String businessType) async {
    final db = await _db.database;

    final todayResult = await db.rawQuery('''
      SELECT SUM(totalAmount) as total, COUNT(*) as count
      FROM bills
      WHERE businessType = ? AND date(billDate) = date('now') AND isDeleted = 0
    ''', [businessType]);

    final monthResult = await db.rawQuery('''
      SELECT SUM(totalAmount) as total, COUNT(*) as count
      FROM bills
      WHERE businessType = ? AND strftime('%Y-%m', billDate) = strftime('%Y-%m', 'now') AND isDeleted = 0
    ''', [businessType]);

    final totalResult = await db.rawQuery('''
      SELECT SUM(totalAmount) as total, COUNT(*) as count
      FROM bills
      WHERE businessType = ? AND isDeleted = 0
    ''', [businessType]);

    return {
      'todaySales': (todayResult.first['total'] as num?)?.toDouble() ?? 0.0,
      'todayBills': todayResult.first['count'] as int? ?? 0,
      'monthSales': (monthResult.first['total'] as num?)?.toDouble() ?? 0.0,
      'monthBills': monthResult.first['count'] as int? ?? 0,
      'totalSales': (totalResult.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalBills': totalResult.first['count'] as int? ?? 0,
    };
  }

  // ── Stock Reports ───────────────────────────────────────────

  /// Get stock summary by category.
  Future<List<Map<String, dynamic>>> getStockByCategory({
    required String businessType,
  }) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT category, COUNT(*) as productCount,
        SUM(stockQuantity) as totalStock,
        SUM(stockQuantity * purchasePrice) as stockValue
      FROM products
      WHERE businessType = ? AND isDeleted = 0
      GROUP BY category
      ORDER BY productCount DESC
    ''', [businessType]);
  }

  /// Get stock status summary.
  Future<Map<String, int>> getStockStatusSummary(String businessType) async {
    final db = await _db.database;

    final normalResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM products
      WHERE businessType = ? AND isDeleted = 0
        AND stockQuantity > minStockLevel AND stockQuantity > 0
    ''', [businessType]);

    final lowResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM products
      WHERE businessType = ? AND isDeleted = 0
        AND stockQuantity <= minStockLevel AND stockQuantity > 0
    ''', [businessType]);

    final outResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM products
      WHERE businessType = ? AND isDeleted = 0 AND stockQuantity <= 0
    ''', [businessType]);

    return {
      'normal': (normalResult.first['count'] as num?)?.toInt() ?? 0,
      'low': (lowResult.first['count'] as num?)?.toInt() ?? 0,
      'out': (outResult.first['count'] as num?)?.toInt() ?? 0,
    };
  }

  /// Get expiring products.
  Future<List<Map<String, dynamic>>> getExpiringProducts({
    required String businessType,
    int daysThreshold = 30,
  }) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT name, category, expiryDate, stockQuantity
      FROM products
      WHERE businessType = ? AND isDeleted = 0
        AND expiryDate IS NOT NULL
        AND expiryDate <= date('now', '+$daysThreshold days')
        AND expiryDate >= date('now')
      ORDER BY expiryDate ASC
    ''', [businessType]);
  }

  /// Get stock valuation.
  Future<Map<String, double>> getStockValuation(String businessType) async {
    final db = await _db.database;

    final purchaseValue = await db.rawQuery('''
      SELECT SUM(stockQuantity * purchasePrice) as value
      FROM products
      WHERE businessType = ? AND isDeleted = 0
    ''', [businessType]);

    final sellingValue = await db.rawQuery('''
      SELECT SUM(stockQuantity * sellingPrice) as value
      FROM products
      WHERE businessType = ? AND isDeleted = 0
    ''', [businessType]);

    final pVal = (purchaseValue.first['value'] as num?)?.toDouble() ?? 0.0;
    final sVal = (sellingValue.first['value'] as num?)?.toDouble() ?? 0.0;

    return {
      'purchaseValue': pVal,
      'sellingValue': sVal,
      'potentialProfit': sVal - pVal,
    };
  }
}
