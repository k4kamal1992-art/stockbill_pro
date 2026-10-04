import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/data/services/barcode_service.dart';

void main() {
  group('BarcodeService.isValidBarcode', () {
    final service = BarcodeService();

    test('accepts 13-digit and 12-digit numeric codes', () {
      expect(service.isValidBarcode('8901234567890'), true);
      expect(service.isValidBarcode('123456789012'), true);
    });

    test('accepts uppercase alphanumeric custom codes', () {
      expect(service.isValidBarcode('GRO12345678'), true);
    });

    test('rejects empty, too short and lowercase/symbol codes', () {
      expect(service.isValidBarcode(''), false);
      expect(service.isValidBarcode('1234567'), false);
      expect(service.isValidBarcode('abc-12345678'), false);
    });
  });
}
