import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/data/services/billing_service.dart';
import 'package:stockbill_pro/data/models/bill_model.dart';
import 'package:stockbill_pro/data/models/product_model.dart';

void main() {
  group('BillingService', () {
    late BillingService billingService;

    setUp(() {
      billingService = BillingService();
    });

    test('calculateBillTotals computes correct values', () {
      final items = [
        BillItemModel(
          id: '1',
          productId: 'p1',
          productName: 'Test Product',
          quantity: 2,
          unitPrice: 100,
          gstPercent: 5,
          totalPrice: 210,
        ),
      ];

      final result = billingService.calculateBillTotals(
        items: items,
        discount: 10,
      );

      expect(result['subtotal'], 200.0);
      expect(result['gstAmount'], 10.0);
      expect(result['total'], 200.0);
    });

    test('generateBillNumber returns correct format', () {
      final billNumber = billingService.generateBillNumber('grocery');
      expect(billNumber.startsWith('B-'), true);
      expect(billNumber.length, greaterThan(10));
    });

    test('calculateChange returns correct value', () {
      final change = billingService.calculateChange(
        totalAmount: 500,
        amountPaid: 600,
      );
      expect(change, 100.0);
    });

    test('calculateChange returns 0 when underpaid', () {
      final change = billingService.calculateChange(
        totalAmount: 500,
        amountPaid: 400,
      );
      expect(change, 0.0);
    });
  });
}
