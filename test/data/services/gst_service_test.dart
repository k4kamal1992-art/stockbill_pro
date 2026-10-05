import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/data/services/gst_service.dart';

void main() {
  group('GSTService', () {
    late GSTService gstService;

    setUp(() {
      gstService = GSTService();
    });

    test('exportGSTR1Json returns valid JSON string', () async {
      final json = await gstService.exportGSTR1Json(
        month: DateTime(2024, 1),
        gstin: '19AAAAA0000A1Z5',
        shopName: 'Test Shop',
      );

      expect(json, isNotEmpty);
      expect(json.contains('gstin'), true);
      expect(json.contains('GSTR'), true);
    });

    test('getGSTSummary returns correct keys', () async {
      final summary = await gstService.getGSTSummary(
        month: DateTime(2024, 1),
      );

      expect(summary.containsKey('taxableValue'), true);
      expect(summary.containsKey('totalGst'), true);
      expect(summary.containsKey('invoiceCount'), true);
      expect(summary.containsKey('largeInvoices'), true);
      expect(summary.containsKey('month'), true);
    });
  });
}
