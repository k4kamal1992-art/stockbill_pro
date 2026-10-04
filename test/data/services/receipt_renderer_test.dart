import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockbill_pro/data/services/receipt_renderer.dart';

void main() {
  test('rasterToEscPos builds GS v 0 commands with correct sizes', () {
    const bytesPerRow = 48; // 384 dots
    const rows = 100; // > 96 -> two bands (96 + 4)
    final bits = Uint8List(bytesPerRow * rows);
    final out = ReceiptCanvas.rasterToEscPos(bits, bytesPerRow, rows);

    expect(out.sublist(0, 2), [0x1B, 0x40]); // ESC @
    // first band header: GS v 0 m xL xH yL yH
    final first = out.indexOf(0x1D);
    expect(out.sublist(first, first + 8),
        [0x1D, 0x76, 0x30, 0x00, 48, 0, 96, 0]);
    // total = init(5) + 2 headers(16) + data + feed(3)
    expect(out.length, 5 + 16 + bytesPerRow * rows + 3);
    expect(out.sublist(out.length - 3), [0x1B, 0x64, 0x04]);
  });

  testWidgets('ReceiptCanvas renders text into black dots', (tester) async {
    await tester.runAsync(() async {
      final r = ReceiptCanvas(widthDots: 384);
      r.addText('StockBill Pro', center: true, bold: true, size: 30);
      r.addDivider();
      r.addKeyValue('TOTAL', '100.00', bold: true);
      final bmp = await r.toBitmap();

      expect(bmp.bytesPerRow, 48);
      expect(bmp.rows, greaterThan(40));
      expect(bmp.bits.length, bmp.bytesPerRow * bmp.rows);
      expect(bmp.bits.any((b) => b != 0), true); // something was drawn
      expect(bmp.bits.any((b) => b == 0), true); // white background exists
    });
  });
}
