import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/shop_model.dart';

class ShopRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> createShop(ShopModel shop) async {
    final db = await _db.database;
    await db.insert(DatabaseHelper.tableShops, shop.toMap());
    return shop.id;
  }

  Future<List<ShopModel>> getAllShops() async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableShops,
      where: 'isActive = 1',
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => ShopModel.fromMap(m)).toList();
  }

  Future<ShopModel?> getShopById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableShops,
      where: 'id = ? AND isActive = 1',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ShopModel.fromMap(maps.first);
  }

  Future<void> updateShop(ShopModel shop) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableShops,
      shop.toMap(),
      where: 'id = ?',
      whereArgs: [shop.id],
    );
  }

  Future<void> deleteShop(String id) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableShops,
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getShopBillCount(String shopId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM bills WHERE shopId = ? AND isDeleted = 0',
      [shopId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<double> getShopTotalSales(String shopId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT SUM(totalAmount) as total FROM bills WHERE shopId = ? AND totalAmount > 0',
      [shopId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
