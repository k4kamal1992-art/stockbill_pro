import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/data/services/barcode_service.dart';

void main() {
  group('BarcodeService', () {
    late BarcodeService barcodeService;

    setUp(() {
      barcodeService = BarcodeService();
    });

    test('validateEAN13 returns true for valid barcode', () {
      expect(barcodeService.validateEAN13('8901234567890'), true);
    });

    test('validateEAN13 returns false for invalid barcode', () {
      expect(barcodeService.validateEAN13('1234567890123'), false);
    });

    test('generateBarcode returns 13 digit string', () {
      final barcode = barcodeService.generateBarcode();
      expect(barcode.length, 13);
      expect(int.tryParse(barcode), isNotNull);
    });

    test('generateBarcode returns unique values', () {
      final barcode1 = barcodeService.generateBarcode();
      final barcode2 = barcodeService.generateBarcode();
      expect(barcode1, isNot(equals(barcode2)));
    });
  });
}
