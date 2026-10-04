import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> createStaff(StaffModel staff) async {
    final db = await _db.database;
    await db.insert(DatabaseHelper.tableStaff, staff.toMap());
    return staff.id;
  }

  Future<List<StaffModel>> getAllStaff({String? shopId}) async {
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
      DatabaseHelper.tableStaff,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'role, name',
    );
    return maps.map((m) => StaffModel.fromMap(m)).toList();
  }

  Future<StaffModel?> getStaffById(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableStaff,
      where: 'id = ? AND isActive = 1',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return StaffModel.fromMap(maps.first);
  }

  Future<StaffModel?> validatePin(String pin) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.tableStaff,
      where: 'pin = ? AND isActive = 1',
      whereArgs: [pin],
    );
    if (maps.isEmpty) return null;
    return StaffModel.fromMap(maps.first);
  }

  Future<void> updateStaff(StaffModel staff) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableStaff,
      staff.toMap(),
      where: 'id = ?',
      whereArgs: [staff.id],
    );
  }

  Future<void> deleteStaff(String id) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableStaff,
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
