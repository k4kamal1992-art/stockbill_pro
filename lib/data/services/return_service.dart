import 'dart:math';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/bill_model.dart';
import '../models/product_model.dart';
import '../repositories/bill_repository.dart';
import '../repositories/product_repository.dart';

/// ReturnService handles product returns, refund calculations,
/// and stock adjustments with atomic transactions.
class ReturnService {
  final DatabaseHelper _db = DatabaseHelper();
  final BillRepository _billRepo = BillRepository();
  final ProductRepository _productRepo = ProductRepository();

  /// Find a bill by its bill number.
  Future<BillModel?> findBillByNumber(String billNumber) async {
    return await _billRepo.getBillByNumber(billNumber);
  }

  /// Get all bills for a customer (for return lookup).
  Future<List<BillModel>> getBillsByCustomerPhone(String phone) async {
    final db = await _db.database;
    final maps = await db.query(
      'bills',
      where: 'customerPhone = ? AND isDeleted = 0',
      whereArgs: [phone],
      orderBy: 'billDate DESC',
    );
    return maps.map((m) => BillModel.fromMap(m)).toList();
  }

  /// Get recent bills for return (last 30 days).
  Future<List<BillModel>> getRecentBills({
    required String businessType,
    int days = 30,
  }) async {
    final db = await _db.database;
    final maps = await db.query(
      'bills',
      where: "businessType = ? AND date(billDate) >= date('now', '-$days days') AND isDeleted = 0 AND totalAmount > 0",
      whereArgs: [businessType],
      orderBy: 'billDate DESC',
    );
    return maps.map((m) => BillModel.fromMap(m)).toList();
  }

  /// Get bill items for a specific bill.
  Future<List<BillItemModel>> getBillItems(String billId) async {
    final db = await _db.database;
    final maps = await db.query(
      'bill_items',
      where: 'billId = ?',
      whereArgs: [billId],
    );
    return maps.map((m) => BillItemModel.fromMap(m)).toList();
  }

  /// Process a return for selected items from a bill.
  /// [billId] original bill ID
  /// [returnItems] map of billItemId -> returnQuantity
  /// [refundMethod] cash/upi/card/credit
  /// [note] optional note
  /// Returns the return bill number or null on failure.
  Future<String?> processReturn({
    required String billId,
    required Map<String, double> returnItems,
    required String refundMethod,
    String? note,
  }) async {
    if (returnItems.isEmpty) return null;

    final db = await _db.database;

    try {
      return await db.transaction((txn) async {
        // Get original bill
        final billMaps = await txn.query(
          'bills',
          where: 'id = ?',
          whereArgs: [billId],
        );
        if (billMaps.isEmpty) return null;
        final originalBill = BillModel.fromMap(billMaps.first);

        // Get all bill items
        final itemMaps = await txn.query(
          'bill_items',
          where: 'billId = ?',
          whereArgs: [billId],
        );

        double refundSubtotal = 0;
        double refundGst = 0;
        List<Map<String, dynamic>> returnRecords = [];

        for (final itemMap in itemMaps) {
          final item = BillItemModel.fromMap(itemMap);
          if (!returnItems.containsKey(item.id)) continue;

          final returnQty = returnItems[item.id]!;
          if (returnQty <= 0) continue;

          // Validate: cannot return more than purchased
          if (returnQty > item.quantity) {
            throw Exception('Return quantity exceeds purchased quantity for ${item.productName}');
          }

          // Calculate refund for this item (proportional)
          final unitPrice = item.unitPrice;
          final itemSubtotal = unitPrice * returnQty;
          final itemGst = itemSubtotal * (item.gstPercent / 100);

          refundSubtotal += itemSubtotal;
          refundGst += itemGst;

          // Update product stock (add back)
          final productMaps = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [item.productId],
          );
          if (productMaps.isNotEmpty) {
            final currentStock = (productMaps.first['stockQuantity'] as num?)?.toDouble() ?? 0;
            await txn.update(
              'products',
              {'stockQuantity': currentStock + returnQty},
              where: 'id = ?',
              whereArgs: [item.productId],
            );
          }

          // Log stock transaction (return)
          final previousStock = (productMaps.first['stockQuantity'] as num?)?.toDouble() ?? 0;
          await txn.insert('stock_transactions', {
            'productId': item.productId,
            'productName': item.productName,
            'type': 'return',
            'quantity': returnQty,
            'previousStock': previousStock,
            'newStock': previousStock + returnQty,
            'referenceId': billId,
            'referenceType': 'bill_return',
            'notes': note ?? 'Return from bill ${originalBill.billNumber}',
            'businessType': originalBill.businessType,
            'createdAt': DateTime.now().toIso8601String(),
          });

          returnRecords.add({
            'productId': item.productId,
            'productName': item.productName,
            'quantity': returnQty,
            'unitPrice': unitPrice,
            'gstPercent': item.gstPercent,
            'total': itemSubtotal + itemGst,
          });
        }

        if (returnRecords.isEmpty) return null;

        // Generate return bill number
        final returnBillNumber = 'R-${originalBill.billNumber}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12)}';

        // Create return record (stored as a bill with negative amount)
        final totalRefund = refundSubtotal + refundGst;
        await txn.insert('bills', {
          'billNumber': returnBillNumber,
          'customerName': originalBill.customerName,
          'customerPhone': originalBill.customerPhone,
          'subtotal': -refundSubtotal,
          'gstAmount': -refundGst,
          'totalAmount': -totalRefund,
          'discount': 0,
          'paymentMethod': refundMethod,
          'amountPaid': -totalRefund,
          'amountDue': 0,
          'businessType': originalBill.businessType,
          'billDate': DateTime.now().toIso8601String(),
          'isDeleted': 0,
        });

        debugPrint('Return processed: $returnBillNumber, Refund: INR $totalRefund');
        return returnBillNumber;
      });
    } catch (e) {
      debugPrint('Return processing error: $e');
      return null;
    }
  }

  /// Calculate refund amount for selected items without processing.
  Future<Map<String, double>> calculateRefund({
    required String billId,
    required Map<String, double> returnItems,
  }) async {
    final items = await getBillItems(billId);
    double subtotal = 0;
    double gst = 0;

    for (final item in items) {
      if (!returnItems.containsKey(item.id)) continue;
      final qty = returnItems[item.id]!;
      if (qty <= 0) continue;

      final itemSubtotal = item.unitPrice * qty;
      final itemGst = itemSubtotal * (item.gstPercent / 100);
      subtotal += itemSubtotal;
      gst += itemGst;
    }

    return {
      'subtotal': subtotal,
      'gst': gst,
      'total': subtotal + gst,
    };
  }

  /// Get return history for a bill.
  Future<List<Map<String, dynamic>>> getReturnHistory(String billId) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT * FROM stock_transactions
      WHERE referenceId = ? AND type = 'return'
      ORDER BY createdAt DESC
    ''', [billId]);
    return result;
  }
}
