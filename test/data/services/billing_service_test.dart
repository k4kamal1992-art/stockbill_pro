import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/data/models/bill_model.dart';
import 'package:stockbill_pro/data/services/billing_service.dart';

void main() {
  group('BillingService (pure helpers)', () {
    final service = BillingService();

    test('calculateBillTotals: subtotal, GST and discount', () {
      final items = [
        BillItemModel(
          productId: 'p1',
          productName: 'Test Product',
          quantity: 2,
          unitPrice: 100,
          gstPercent: 5,
          totalPrice: 210,
        ),
      ];
      final r = service.calculateBillTotals(items: items, discount: 10);
      expect(r['subtotal'], 200.0);
      expect(r['gstAmount'], 10.0);
      expect(r['total'], 200.0); // 200 + 10 - 10
    });

    test('calculateBillTotals never goes below zero', () {
      final r = service.calculateBillTotals(items: [], discount: 50);
      expect(r['total'], 0.0);
    });

    test('calculateChange', () {
      expect(service.calculateChange(totalAmount: 500, amountPaid: 600), 100.0);
      expect(service.calculateChange(totalAmount: 500, amountPaid: 400), 0.0);
    });
  });

  group('BillModel', () {
    test('toDbMap has no nested items list (sqflite cannot store it)', () {
      final bill = BillModel(
        billNumber: 'GRO-0001',
        customerName: 'Test',
        items: [
          BillItemModel(
            productId: 'p1',
            productName: 'X',
            quantity: 1,
            unitPrice: 10,
            totalPrice: 10,
          ),
        ],
        subtotal: 10,
        gstAmount: 0,
        totalAmount: 10,
        paymentMethod: 'cash',
        amountPaid: 10,
        amountDue: 0,
        businessType: 'grocery',
      );
      expect(bill.toMap().containsKey('items'), true);
      expect(bill.toDbMap().containsKey('items'), false);
    });
  });
}
