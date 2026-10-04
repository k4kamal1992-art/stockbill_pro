import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/data/models/bill_model.dart';
import 'package:stockbill_pro/data/services/print_service.dart';

void main() {
  test('generateShareText includes bill number, customer and totals', () {
    final bill = BillModel(
      id: '1',
      billNumber: 'GRO-0001',
      customerName: 'Test Customer',
      customerPhone: '9876543210',
      items: [
        BillItemModel(
          productId: 'p1',
          productName: 'Rice',
          quantity: 2,
          unitPrice: 250,
          totalPrice: 500,
        ),
      ],
      subtotal: 500,
      gstAmount: 25,
      totalAmount: 525,
      paymentMethod: 'cash',
      amountPaid: 500,
      amountDue: 25,
      businessType: 'grocery',
    );

    final text = PrintService().generateShareText(
      bill: bill,
      storeName: 'Test Shop',
      storePhone: '9876543210',
    );

    expect(text.contains('GRO-0001'), true);
    expect(text.contains('Test Customer'), true);
    expect(text.contains('525.00'), true);
    expect(text.contains('Due'), true);
    expect(text.contains('Test Shop'), true);
  });

  test('textModeBytes: ESC/POS init, ASCII-safe text, centered lines', () {
    final bytes = PrintService().textModeBytes('CENTERHello \u20B95\nপণ্য');
    expect(bytes.sublist(0, 2), [0x1B, 0x40]); // ESC @
    final text = String.fromCharCodes(bytes);
    expect(text.contains('Hello Rs5'), true); // rupee sign -> "Rs"
    expect(text.contains('?'), true); // Bengali is not printable in text mode
    // every byte must be a single byte
    expect(bytes.every((b) => b >= 0 && b <= 255), true);
  });
}
