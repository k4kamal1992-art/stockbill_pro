import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/supplier_model.dart';

class SupplierRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> createSupplier(SupplierModel supplier) async {
    final db = await _db.database;
    await db.insert(DatabaseHelper.tableSuppliers, supplier.toMap());
    return supplier.id;
  }

  Future<List<SupplierModel>> getAllSuppliers({String? shopId}) async {
    final db = await _db.database;
    String? where;
    List<Object?>? whereArgs;
    if (shopId != null) {
      where = 'shopId = ? AND isActive = 1';
      whereArgs = [shopId];
    } else {
      where = 'isActive = 1';
      whereArgs = [];
    }
    final maps = await db.query(
      DatabaseHelper.tableSuppliers,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name',
    );
    return maps.map((m) => SupplierModel.fromMap(m)).toList();
  }

  Future<SupplierModel?> getSupplierById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableSuppliers,
      where: 'id = ? AND isActive = 1',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SupplierModel.fromMap(maps.first);
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableSuppliers,
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<void> deleteSupplier(String id) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableSuppliers,
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateBalance(String supplierId, double purchaseAmount, double paidAmount) async {
    final db = await _db.database;
    final supplier = await getSupplierById(supplierId);
    if (supplier == null) return;

    final newTotalPurchases = supplier.totalPurchases + purchaseAmount;
    final newTotalPaid = supplier.totalPaid + paidAmount;
    final newBalance = newTotalPurchases - newTotalPaid;

    await db.update(
      DatabaseHelper.tableSuppliers,
      {
        'totalPurchases': newTotalPurchases,
        'totalPaid': newTotalPaid,
        'balanceDue': newBalance,
      },
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }
}
