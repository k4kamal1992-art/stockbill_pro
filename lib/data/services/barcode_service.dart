import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product_model.dart';

/// BarcodeService handles barcode-related operations
/// including lookup by barcode and scanning simulation.
class BarcodeService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Look up a product by its barcode string
  Future<ProductModel?> findProductByBarcode(String barcode) async {
    final db = await _db.database;
    final maps = await db.query(
      'products',
      where: 'barcode = ? AND isDeleted = 0',
      whereArgs: [barcode],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProductModel.fromMap(maps.first);
    }
    return null;
  }

  /// Check if a barcode already exists in the database
  Future<bool> barcodeExists(String barcode) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE barcode = ?',
      [barcode],
    );
    return (result.first['count'] as int) > 0;
  }

  /// Generate a barcode from product data (for unlabeled products)
  String generateBarcode({
    required String businessType,
    required String category,
    required String productId,
  }) {
    final prefix = businessType.substring(0, 1).toUpperCase();
    final catCode = category.substring(0, 2).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    return '$prefix$catCode$timestamp$productId';
  }

  /// Validate barcode format (basic EAN-13 or custom check)
  bool isValidBarcode(String barcode) {
    if (barcode.isEmpty) return false;
    if (barcode.length < 8) return false;
    // EAN-13: 13 digits
    // UPC-A: 12 digits
    // Custom: alphanumeric, min 8 chars
    final numericOnly = RegExp(r'^[0-9]+$');
    final alphanumeric = RegExp(r'^[A-Z0-9]+$');
    return numericOnly.hasMatch(barcode) || alphanumeric.hasMatch(barcode);
  }
}

/// ScanResult represents the outcome of a barcode scan
class ScanResult {
  final String barcode;
  final ProductModel? product;
  final bool found;
  final String? error;

  ScanResult({
    required this.barcode,
    this.product,
    this.found = false,
    this.error,
  });
}
