import '../database/database_helper.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<String> insertCustomer(CustomerModel customer) async {
    await _db.insert(DatabaseHelper.tableCustomers, customer.toMap());
    return customer.id;
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableCustomers,
      where: 'id = ? AND isActive = 1',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return CustomerModel.fromMap(results.first);
  }

  Future<CustomerModel?> getCustomerByPhone(String phone) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableCustomers,
      where: 'phone = ? AND isActive = 1',
      whereArgs: [phone],
    );
    if (results.isEmpty) return null;
    return CustomerModel.fromMap(results.first);
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final results = await _db.queryAll(
      DatabaseHelper.tableCustomers,
      orderBy: 'name ASC',
    );
    return results.map((e) => CustomerModel.fromMap(e)).toList();
  }

  Future<List<CustomerModel>> searchCustomers(String query) async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableCustomers,
      where: '(name LIKE ? OR phone LIKE ?) AND isActive = 1',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return results.map((e) => CustomerModel.fromMap(e)).toList();
  }

  Future<List<CustomerModel>> getCustomersWithDue() async {
    final results = await _db.queryWhere(
      DatabaseHelper.tableCustomers,
      where: 'totalDue > 0 AND isActive = 1',
      whereArgs: [],
      orderBy: 'totalDue DESC',
    );
    return results.map((e) => CustomerModel.fromMap(e)).toList();
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    return await _db.update(
      DatabaseHelper.tableCustomers,
      data: customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> updateBalance(String customerId, double due, double paid) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return 0;
    return await _db.update(
      DatabaseHelper.tableCustomers,
      data: customer.copyWith(
        totalDue: customer.totalDue + due,
        totalPaid: customer.totalPaid + paid,
      ).toMap(),
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  /// Sum of all outstanding customer dues.
  Future<double> getTotalDueAmount() async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(totalDue), 0) AS total FROM ${DatabaseHelper.tableCustomers} WHERE isActive = 1',
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Customer pays part/all of their due: totalDue goes down, totalPaid up.
  Future<void> recordPayment(String customerId, double amount, {String? note}) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) {
      throw Exception('Customer not found');
    }
    if (amount <= 0) {
      throw Exception('Payment amount must be positive');
    }
    if (amount > customer.totalDue + 0.005) {
      throw Exception('Payment exceeds outstanding due');
    }
    final newDue = (customer.totalDue - amount).clamp(0.0, double.infinity).toDouble();
    await _db.update(
      DatabaseHelper.tableCustomers,
      data: customer
          .copyWith(totalDue: newDue, totalPaid: customer.totalPaid + amount)
          .toMap(),
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<int> softDeleteCustomer(String id) async {
    return await _db.update(
      DatabaseHelper.tableCustomers,
      data: {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
