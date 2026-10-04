// Integration test of the real SQLite schema + sale/return flow.
// Uses sqflite_common_ffi so it runs on the desktop with `flutter test`.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stockbill_pro/data/database/database_helper.dart';
import 'package:stockbill_pro/data/models/bill_model.dart';
import 'package:stockbill_pro/data/models/product_model.dart';
import 'package:stockbill_pro/data/repositories/customer_repository.dart';
import 'package:stockbill_pro/data/repositories/product_repository.dart';
import 'package:stockbill_pro/data/services/billing_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    await DatabaseHelper().close();
    final path = '${await getDatabasesPath()}/stockbill_pro.db';
    await deleteDatabase(path);
  });

  tearDownAll(() async => DatabaseHelper().close());

  Future<ProductModel> addProduct({double stock = 10}) async {
    final p = ProductModel(
      name: 'Rice 1kg',
      category: 'Grocery',
      purchasePrice: 40,
      sellingPrice: 50,
      mrp: 55,
      stockQuantity: stock,
      businessType: 'grocery',
    );
    final db = await DatabaseHelper().database;
    await db.insert('products', p.toMap());
    return p;
  }

  BillModel billFor(ProductModel p, {double qty = 2, double paid = 100, String? phone}) {
    final total = p.sellingPrice * qty;
    return BillModel(
      billNumber: 'GRO-${DateTime.now().microsecondsSinceEpoch}',
      customerName: 'Ravi',
      customerPhone: phone,
      items: [
        BillItemModel(
          productId: p.id,
          productName: p.name,
          quantity: qty,
          unitPrice: p.sellingPrice,
          totalPrice: total,
        ),
      ],
      subtotal: total,
      gstAmount: 0,
      totalAmount: total,
      paymentMethod: paid >= total ? 'cash' : 'credit',
      amountPaid: paid,
      amountDue: total - paid,
      businessType: 'grocery',
    );
  }

  test('schema creates all tables', () async {
    final db = await DatabaseHelper().database;
    final rows = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final names = rows.map((r) => r['name']).toSet();
    for (final t in ['products', 'bills', 'bill_items', 'customers', 'stock_transactions',
        'shops', 'staff', 'expenses', 'suppliers', 'supplier_products']) {
      expect(names.contains(t), true, reason: 'missing table $t');
    }
  });

  test('sale reduces stock and cannot oversell', () async {
    final p = await addProduct(stock: 3);
    await BillingService().processSale(billFor(p, qty: 2, paid: 100));
    final after = await ProductRepository().getProductById(p.id);
    expect(after!.stockQuantity, 1.0);

    expect(
      () => BillingService().processSale(billFor(p, qty: 5, paid: 250)),
      throwsException,
    );
  });

  test('credit sale creates customer due; return restores stock and due; no double return', () async {
    final p = await addProduct(stock: 10);
    final bill = billFor(p, qty: 2, paid: 40, phone: '9000000001'); // total 100, due 60
    await BillingService().processSale(bill);

    final cust = await CustomerRepository().getCustomerByPhone('9000000001');
    expect(cust!.totalDue, 60.0);

    await BillingService().processReturn(bill.id);
    expect((await ProductRepository().getProductById(p.id))!.stockQuantity, 10.0);
    expect((await CustomerRepository().getCustomerByPhone('9000000001'))!.totalDue, 0.0);

    expect(() => BillingService().processReturn(bill.id), throwsException);
  });

  test('recordPayment lowers due and rejects overpayment', () async {
    final p = await addProduct();
    await BillingService().processSale(billFor(p, qty: 2, paid: 0, phone: '9000000002'));
    final repo = CustomerRepository();
    final c = (await repo.getCustomerByPhone('9000000002'))!;
    await repo.recordPayment(c.id, 30);
    final updated = (await repo.getCustomerByPhone('9000000002'))!;
    expect(updated.totalDue, 70.0);
    expect(updated.totalPaid, 30.0);
    expect(() => repo.recordPayment(c.id, 500), throwsException);
  });
}
