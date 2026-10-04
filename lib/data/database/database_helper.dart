import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _dbName = 'stockbill_pro.db';
  static const int _dbVersion = 3;

  static const String tableProducts = 'products';
  static const String tableBills = 'bills';
  static const String tableBillItems = 'bill_items';
  static const String tableCustomers = 'customers';
  static const String tableStockTransactions = 'stock_transactions';
  static const String tableShops = 'shops';
  static const String tableStaff = 'staff';
  static const String tableExpenses = 'expenses';
  static const String tableSuppliers = 'suppliers';
  static const String tableSupplierProducts = 'supplier_products';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // Needed so ON DELETE CASCADE on bill_items actually works.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProducts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nameBn TEXT,
        category TEXT NOT NULL,
        brand TEXT,
        barcode TEXT,
        purchasePrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        mrp REAL NOT NULL,
        gstPercent REAL DEFAULT 0,
        stockQuantity REAL NOT NULL,
        minStockLevel REAL DEFAULT 0,
        expiryDate TEXT,
        batchNumber TEXT,
        businessType TEXT NOT NULL,
        shopId TEXT,
        unit TEXT,
        unitConversion REAL,
        size TEXT,
        color TEXT,
        imei TEXT,
        serialNumber TEXT,
        vehicleBrand TEXT,
        vehicleModel TEXT,
        vehicleYear TEXT,
        partNumber TEXT,
        genericName TEXT,
        company TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableBills (
        id TEXT PRIMARY KEY,
        billNumber TEXT NOT NULL UNIQUE,
        customerName TEXT NOT NULL,
        customerPhone TEXT,
        subtotal REAL NOT NULL,
        gstAmount REAL NOT NULL,
        totalAmount REAL NOT NULL,
        discount REAL DEFAULT 0,
        paymentMethod TEXT NOT NULL,
        amountPaid REAL NOT NULL,
        amountDue REAL NOT NULL,
        businessType TEXT NOT NULL,
        billDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isReturned INTEGER DEFAULT 0,
        notes TEXT,
        shopId TEXT,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableBillItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        gstPercent REAL DEFAULT 0,
        totalPrice REAL NOT NULL,
        batchNumber TEXT,
        imei TEXT,
        size TEXT,
        color TEXT,
        shopId TEXT,
        FOREIGN KEY (billId) REFERENCES $tableBills(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCustomers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        totalDue REAL DEFAULT 0,
        totalPaid REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableStockTransactions (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        previousStock REAL NOT NULL,
        newStock REAL NOT NULL,
        referenceId TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        shopId TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_products_business ON $tableProducts(businessType)',
    );
    await db.execute(
      'CREATE INDEX idx_products_category ON $tableProducts(category)',
    );
    await db.execute(
      'CREATE INDEX idx_products_barcode ON $tableProducts(barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_bills_date ON $tableBills(billDate)',
    );
    await db.execute(
      'CREATE INDEX idx_bills_business ON $tableBills(businessType)',
    );
    await db.execute(
      'CREATE INDEX idx_stock_product ON $tableStockTransactions(productId)',
    );
    await db.execute(
      'CREATE INDEX idx_customers_phone ON $tableCustomers(phone)',
    );

    await _createExtraTables(db);
  }

  /// shops, staff, expenses, suppliers, supplier_products.
  /// Uses IF NOT EXISTS so it is safe to call from both onCreate and onUpgrade.
  Future<void> _createExtraTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableShops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        gstin TEXT,
        businessType TEXT NOT NULL,
        ownerName TEXT,
        logoPath TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableStaff (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        role TEXT NOT NULL,
        pin TEXT,
        shopId TEXT,
        permissions TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableExpenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        shopId TEXT,
        staffId TEXT,
        expenseDate TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSuppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        company TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        gstin TEXT,
        shopId TEXT,
        totalPurchases REAL DEFAULT 0,
        totalPaid REAL DEFAULT 0,
        balanceDue REAL DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSupplierProducts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId TEXT NOT NULL,
        productId TEXT NOT NULL,
        purchasePrice REAL,
        createdAt TEXT,
        FOREIGN KEY (supplierId) REFERENCES $tableSuppliers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_date ON $tableExpenses(expenseDate)',
    );
  }

  Future<void> _addColumnIfMissing(
      Database db, String table, String column, String definition) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createExtraTables(db);
    }
    if (oldVersion < 3) {
      await _addColumnIfMissing(db, tableProducts, 'isDeleted', 'INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, tableBills, 'isDeleted', 'INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, tableCustomers, 'isDeleted', 'INTEGER DEFAULT 0');
      await _createExtraTables(db);
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table, {String? orderBy}) async {
    final db = await database;
    return await db.query(table, orderBy: orderBy);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> update(
    String table, {
    required Map<String, dynamic> data,
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }
}
