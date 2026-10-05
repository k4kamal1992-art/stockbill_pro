import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/data/services/print_service.dart';
import 'package:stockbill_pro/data/models/bill_model.dart';

void main() {
  group('PrintService', () {
    late PrintService printService;

    setUp(() {
      printService = PrintService();
    });

    test('generateShareText includes bill number and total', () {
      final bill = BillModel(
        id: '1',
        billNumber: 'B-123456',
        customerName: 'Test Customer',
        customerPhone: '9876543210',
        subtotal: 500,
        gstAmount: 25,
        totalAmount: 525,
        discount: 0,
        paymentMethod: 'cash',
        amountPaid: 525,
        amountDue: 0,
        businessType: 'grocery',
        billDate: DateTime.now().toIso8601String(),
        items: [],
      );

      final text = printService.generateShareText(bill);

      expect(text.contains('B-123456'), true);
      expect(text.contains('525'), true);
      expect(text.contains('Test Customer'), true);
    });

    test('generateWhatsAppMessage includes shop name', () {
      final bill = BillModel(
        id: '1',
        billNumber: 'B-123456',
        customerName: 'Test Customer',
        subtotal: 500,
        gstAmount: 25,
        totalAmount: 525,
        discount: 0,
        paymentMethod: 'cash',
        amountPaid: 525,
        amountDue: 0,
        businessType: 'grocery',
        billDate: DateTime.now().toIso8601String(),
        items: [],
      );

      final message = printService.generateWhatsAppMessage(
        bill,
        shopName: 'Test Shop',
        shopPhone: '9876543210',
      );

      expect(message.contains('Test Shop'), true);
      expect(message.contains('B-123456'), true);
      expect(message.contains('525'), true);
    });

    test('getWhatsAppUri formats correctly', () {
      final uri = printService.getWhatsAppUri(
        '9876543210',
        'Hello World',
      );
      expect(uri.contains('wa.me/9876543210'), true);
      expect(uri.contains('text='), true);
    });
  });
}
