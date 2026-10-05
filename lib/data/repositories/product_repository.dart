import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // CREATE
  Future<String> insertProduct(ProductModel product) async {
    await _db.insert(DatabaseHelper.tableProducts, product.toMap());
    return product.id;
  }

  Future<void> insertProducts(List<ProductModel> products) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final product in products) {
        await txn.insert(DatabaseHelper.tableProducts, product.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // READ - Single
  Future<ProductModel?> getProductById(String id) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'id = ? AND isActive = 1',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return ProductModel.fromMap(results.first);
  }

  // READ - All by business type
  Future<List<ProductModel>> getProductsByBusiness(String businessType) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'businessType = ? AND isActive = 1',
      whereArgs: [businessType],
      orderBy: 'name ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // READ - All
  Future<List<ProductModel>> getAllProducts() async {
    final results = await _db.queryAll(
      DatabaseHelper.tableProducts,
      orderBy: 'updatedAt DESC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // SEARCH - by name, barcode, category
  Future<List<ProductModel>> searchProducts(
    String query, {
    String? businessType,
  }) async {
    String whereClause = '(name LIKE ? OR nameBn LIKE ? OR barcode LIKE ? OR category LIKE ?) AND isActive = 1';
    List<dynamic> args = ['%$query%', '%$query%', '%$query%', '%$query%'];

    if (businessType != null) {
      whereClause += ' AND businessType = ?';
      args.add(businessType);
    }

    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: whereClause,
      whereArgs: args,
      orderBy: 'name ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // FILTER - by category
  Future<List<ProductModel>> getProductsByCategory(
    String category,
    String businessType,
  ) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'category = ? AND businessType = ? AND isActive = 1',
      whereArgs: [category, businessType],
      orderBy: 'name ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // FILTER - Low stock
  Future<List<ProductModel>> getLowStockProducts(String businessType) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'businessType = ? AND stockQuantity <= minStockLevel AND isActive = 1',
      whereArgs: [businessType],
      orderBy: 'stockQuantity ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // FILTER - Out of stock
  Future<List<ProductModel>> getOutOfStockProducts(String businessType) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'businessType = ? AND stockQuantity <= 0 AND isActive = 1',
      whereArgs: [businessType],
      orderBy: 'name ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // FILTER - Expiring soon (next 30 days)
  Future<List<ProductModel>> getExpiringProducts(String businessType) async {
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    final expiryStr = thirtyDaysFromNow.toIso8601String().split('T').first;

    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'businessType = ? AND expiryDate IS NOT NULL AND expiryDate <= ? AND isActive = 1',
      whereArgs: [businessType, expiryStr],
      orderBy: 'expiryDate ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // FILTER - by barcode
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'barcode = ? AND isActive = 1',
      whereArgs: [barcode],
    );
    if (results.isEmpty) return null;
    return ProductModel.fromMap(results.first);
  }

  // Pharmacy specific - by generic name
  Future<List<ProductModel>> getProductsByGenericName(
    String genericName,
    String businessType,
  ) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'genericName = ? AND businessType = ? AND isActive = 1',
      whereArgs: [genericName, businessType],
      orderBy: 'name ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // Pharmacy specific - by company
  Future<List<ProductModel>> getProductsByCompany(
    String company,
    String businessType,
  ) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'company = ? AND businessType = ? AND isActive = 1',
      whereArgs: [company, businessType],
      orderBy: 'name ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // Auto parts specific - by vehicle compatibility
  Future<List<ProductModel>> getProductsByVehicle(
    String brand,
    String model,
    String businessType,
  ) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'vehicleBrand = ? AND vehicleModel = ? AND businessType = ? AND isActive = 1',
      whereArgs: [brand, model, businessType],
      orderBy: 'name ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // Garments specific - by size/color
  Future<List<ProductModel>> getProductsBySizeColor(
    String size,
    String color,
    String businessType,
  ) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableProducts,
      where: 'size = ? AND color = ? AND businessType = ? AND isActive = 1',
      whereArgs: [size, color, businessType],
      orderBy: 'name ASC',
    );
    return results.map((e) => ProductModel.fromMap(e)).toList();
  }

  // UPDATE
  Future<int> updateProduct(ProductModel product) async {
    return await _db.update(
      DatabaseHelper.tableProducts,
      data: product.toMap()..['updatedAt'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Update stock quantity
  Future<int> updateStock(String productId, double newQuantity) async {
    return await _db.update(
      DatabaseHelper.tableProducts,
      data: {
        'stockQuantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Soft delete
  Future<int> softDeleteProduct(String id) async {
    return await _db.update(
      DatabaseHelper.tableProducts,
      data: {
        'isActive': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Hard delete
  Future<int> deleteProduct(String id) async {
    return await _db.delete(
      DatabaseHelper.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // COUNT
  Future<int> getProductCount(String businessType) async {
    final results = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableProducts} WHERE businessType = ? AND isActive = 1',
      [businessType],
    );
    return (results.first['count'] as num).toInt();
  }

  // Stock summary
  Future<Map<String, int>> getStockSummary(String businessType) async {
    final db = await _db.database;

    final normalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableProducts} WHERE businessType = ? AND stockQuantity > minStockLevel AND isActive = 1',
      [businessType],
    );

    final lowResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableProducts} WHERE businessType = ? AND stockQuantity <= minStockLevel AND stockQuantity > 0 AND isActive = 1',
      [businessType],
    );

    final outResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableProducts} WHERE businessType = ? AND stockQuantity <= 0 AND isActive = 1',
      [businessType],
    );

    return {
      'normal': (normalResult.first['count'] as num).toInt(),
      'low': (lowResult.first['count'] as num).toInt(),
      'out': (outResult.first['count'] as num).toInt(),
    };
  }
}
