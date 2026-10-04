import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../../core/constants/app_constants.dart';

/// BackupService handles export/import of all SQLite data to JSON files.
/// 
/// Backup files are saved to:
///   Android: <app external files dir>/StockBillPro/
///   iOS: App Documents/StockBillPro/
///
/// File format: stockbill_backup_YYYYMMDD_HHMMSS.json
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  static const String _backupFolder = 'StockBillPro';
  static const String _lastBackupKey = AppConstants.prefLastBackupDate;

  // ── Backup (Export) ─────────────────────────────────────────

  /// Export all database tables to a single JSON backup file.
  /// Returns the path of the created backup file, or null on failure.
  Future<String?> backupAll() async {
    try {
      final db = await _db.database;

      // Fetch all tables
      final products = await db.query('products', where: 'isDeleted = 0');
      final bills = await db.query('bills');
      final billItems = await db.query('bill_items');
      final customers = await db.query('customers', where: 'isDeleted = 0');
      final stockTransactions = await db.query('stock_transactions');

      final backupData = {
        'appName': 'StockBill Pro',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tables': {
          'products': products,
          'bills': bills,
          'bill_items': billItems,
          'customers': customers,
          'stock_transactions': stockTransactions,
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = _generateBackupFileName();
      final filePath = await _getBackupFilePath(fileName);

      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Save last backup date
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());

      debugPrint('Backup saved: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Backup error: $e');
      return null;
    }
  }

  /// Export only products table (for inventory sharing)
  Future<String?> backupProducts() async {
    try {
      final db = await _db.database;
      final products = await db.query('products', where: 'isDeleted = 0');

      final backupData = {
        'appName': 'StockBill Pro',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'type': 'products_only',
        'tables': {
          'products': products,
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = 'stockbill_products_${_timestamp()}.json';
      final filePath = await _getBackupFilePath(fileName);

      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      debugPrint('Product backup error: $e');
      return null;
    }
  }

  // ─ Restore (Import) ──────────────────────────────────────

  /// Restore database from a JSON backup file.
  /// [filePath] must be a valid backup JSON file.
  /// Returns true on success.
  Future<bool> restoreFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      final tables = backupData['tables'] as Map<String, dynamic>?;
      if (tables == null) return false;

      final db = await _db.database;

      await db.transaction((txn) async {
        // Clear existing data (optional: can be made configurable)
        await txn.delete('stock_transactions');
        await txn.delete('bill_items');
        await txn.delete('bills');
        await txn.delete('customers');
        await txn.delete('products');

        // Restore each table
        if (tables.containsKey('products')) {
          for (final row in tables['products'] as List) {
            await txn.insert('products', Map<String, dynamic>.from(row as Map));
          }
        }
        if (tables.containsKey('bills')) {
          for (final row in tables['bills'] as List) {
            await txn.insert('bills', Map<String, dynamic>.from(row as Map));
          }
        }
        if (tables.containsKey('bill_items')) {
          for (final row in tables['bill_items'] as List) {
            await txn.insert('bill_items', Map<String, dynamic>.from(row as Map));
          }
        }
        if (tables.containsKey('customers')) {
          for (final row in tables['customers'] as List) {
            await txn.insert('customers', Map<String, dynamic>.from(row as Map));
          }
        }
        if (tables.containsKey('stock_transactions')) {
          for (final row in tables['stock_transactions'] as List) {
            await txn.insert('stock_transactions', Map<String, dynamic>.from(row as Map));
          }
        }
      });

      debugPrint('Restore completed from: $filePath');
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  // ── Backup File Management ────────────────────────────────

  /// List all backup files sorted by newest first.
  Future<List<BackupFileInfo>> listBackups() async {
    try {
      final dirPath = await _getBackupDirectory();
      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];

      final files = await dir
          .list()
          .where((f) => f is File && f.path.endsWith('.json'))
          .toList();

      final infos = <BackupFileInfo>[];
      for (final file in files) {
        final stat = await file.stat();
        infos.add(BackupFileInfo(
          path: file.path,
          name: file.path.split('/').last,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
        ));
      }

      infos.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return infos;
    } catch (e) {
      debugPrint('List backups error: $e');
      return [];
    }
  }

  /// Delete a specific backup file.
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete backup error: $e');
      return false;
    }
  }

  /// Get the last backup date from SharedPreferences.
  Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastBackupKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Get database statistics (row counts per table).
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await _db.database;
    final stats = <String, int>{};

    final tables = ['products', 'bills', 'bill_items', 'customers', 'stock_transactions'];
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = result.first['count'] as int? ?? 0;
    }
    return stats;
  }

  // ── Helpers ────────────────────────────────────────────────

  String _generateBackupFileName() {
    return 'stockbill_backup_${_timestamp()}.json';
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${_two(now.month)}${_two(now.day)}_'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<String> _getBackupDirectory() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      // App-specific external folder: needs no storage permission.
      // (Android/data/<package>/files). Use "Share" to copy a backup elsewhere.
      baseDir = (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final backupDir = Directory('${baseDir.path}/$_backupFolder');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  Future<String> _getBackupFilePath(String fileName) async {
    final dirPath = await _getBackupDirectory();
    return '$dirPath/$fileName';
  }
}

class BackupFileInfo {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;

  BackupFileInfo({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    return '${modifiedAt.day.toString().padLeft(2, '0')}/'
        '${modifiedAt.month.toString().padLeft(2, '0')}/${modifiedAt.year} '
        '${modifiedAt.hour.toString().padLeft(2, '0')}:'
        '${modifiedAt.minute.toString().padLeft(2, '0')}';
  }
}
