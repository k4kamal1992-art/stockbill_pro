import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Draws a receipt into a bitmap and converts it to ESC/POS raster commands.
///
/// Why a bitmap? Thermal printers only know a few built-in code pages, so
/// Bengali / Hindi text and the rupee sign would print as "????" in text
/// mode. Drawing the text with Flutter (which has the phone's fonts) and
/// sending it as an image prints every language correctly.
class ReceiptCanvas {
  /// 384 dots = 58 mm paper, 576 dots = 80 mm paper. Must be a multiple of 8.
  final int widthDots;
  final double margin;

  ReceiptCanvas({this.widthDots = 384, this.margin = 8})
      : assert(widthDots % 8 == 0);

  final List<_Painted> _painted = [];
  final List<double> _lineYs = [];
  double _y = 4;

  static const Color _ink = Color(0xFF000000);

  TextPainter _painter(
    String text, {
    required double size,
    bool bold = false,
    TextAlign align = TextAlign.left,
    required double maxWidth,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _ink,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          height: 1.25,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    );
    tp.layout(minWidth: 0, maxWidth: maxWidth);
    return tp;
  }

  double get _contentWidth => widthDots - 2 * margin;

  void addSpace(double height) => _y += height;

  /// A (possibly wrapped) line of text.
  void addText(
    String text, {
    bool center = false,
    bool bold = false,
    double size = 22,
  }) {
    if (text.isEmpty) return;
    final tp = _painter(
      text,
      size: size,
      bold: bold,
      align: center ? TextAlign.center : TextAlign.left,
      maxWidth: _contentWidth,
    );
    final dx = center ? (widthDots - tp.width) / 2 : margin;
    _painted.add(_Painted(tp, dx, _y));
    _y += tp.height + 2;
  }

  void addDivider() {
    _y += 3;
    _lineYs.add(_y);
    _y += 6;
  }

  /// "label ........ value" on one row (value right aligned).
  void addKeyValue(
    String label,
    String value, {
    bool bold = false,
    double size = 22,
  }) {
    final right = _painter(value, size: size, bold: bold, maxWidth: _contentWidth * 0.6);
    final left = _painter(
      label,
      size: size,
      bold: bold,
      maxWidth: _contentWidth - right.width - 8,
    );
    _painted.add(_Painted(left, margin, _y));
    _painted.add(_Painted(right, widthDots - margin - right.width, _y));
    _y += (left.height > right.height ? left.height : right.height) + 2;
  }

  /// Item table row: name | qty | price | total.
  void addItemRow(
    String name,
    String qty,
    String price,
    String total, {
    bool bold = false,
    double size = 21,
  }) {
    final usable = _contentWidth;
    final totalW = usable * 0.22;
    final priceW = usable * 0.20;
    final qtyW = usable * 0.14;
    final nameW = usable - totalW - priceW - qtyW - 6;

    final nameTp = _painter(name, size: size, bold: bold, maxWidth: nameW);
    final qtyTp = _painter(qty, size: size, bold: bold, maxWidth: qtyW);
    final priceTp = _painter(price, size: size, bold: bold, maxWidth: priceW);
    final totalTp = _painter(total, size: size, bold: bold, maxWidth: totalW);

    final qtyRight = margin + nameW + 2 + qtyW;
    final priceRight = qtyRight + priceW;
    final totalRight = widthDots - margin;

    _painted.add(_Painted(nameTp, margin, _y));
    _painted.add(_Painted(qtyTp, qtyRight - qtyTp.width, _y));
    _painted.add(_Painted(priceTp, priceRight - priceTp.width, _y));
    _painted.add(_Painted(totalTp, totalRight - totalTp.width, _y));

    var h = nameTp.height;
    for (final t in [qtyTp, priceTp, totalTp]) {
      if (t.height > h) h = t.height;
    }
    _y += h + 3;
  }

  /// Renders everything to a monochrome bitmap.
  /// Returns (bytesPerRow, rows, packedBits) where bit 1 = black dot.
  Future<({int bytesPerRow, int rows, Uint8List bits})> toBitmap() async {
    final height = (_y + 8).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, widthDots.toDouble(), height.toDouble()),
    );
    // White background (otherwise transparent pixels would print black)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, widthDots.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    for (final p in _painted) {
      p.painter.paint(canvas, Offset(p.dx, p.dy));
    }
    final linePaint = Paint()
      ..color = _ink
      ..strokeWidth = 1.5;
    for (final y in _lineYs) {
      canvas.drawLine(
        Offset(margin, y),
        Offset(widthDots - margin, y),
        linePaint,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(widthDots, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) {
      throw StateError('Could not render receipt image');
    }

    final bytesPerRow = widthDots ~/ 8;
    final bits = Uint8List(bytesPerRow * height);
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < widthDots; col++) {
        final i = (row * widthDots + col) * 4;
        final r = data.getUint8(i);
        final g = data.getUint8(i + 1);
        final b = data.getUint8(i + 2);
        final luminance = (r * 299 + g * 587 + b * 114) ~/ 1000;
        if (luminance < 150) {
          bits[row * bytesPerRow + (col >> 3)] |= (0x80 >> (col & 7));
        }
      }
    }
    return (bytesPerRow: bytesPerRow, rows: height, bits: bits);
  }

  /// Full ESC/POS byte stream: init, raster image in bands, feed.
  Future<List<int>> toEscPos() async {
    final bmp = await toBitmap();
    return rasterToEscPos(bmp.bits, bmp.bytesPerRow, bmp.rows);
  }

  /// Wraps packed 1-bit rows in `GS v 0` raster commands.
  static List<int> rasterToEscPos(Uint8List bits, int bytesPerRow, int rows) {
    final out = <int>[
      0x1B, 0x40, // ESC @  initialize
      0x1B, 0x61, 0x00, // left align
    ];
    const band = 96; // rows per command (keeps each write small)
    for (var start = 0; start < rows; start += band) {
      final n = (rows - start) < band ? (rows - start) : band;
      out.addAll([
        0x1D, 0x76, 0x30, 0x00, // GS v 0, normal density
        bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF,
        n & 0xFF, (n >> 8) & 0xFF,
      ]);
      out.addAll(bits.sublist(start * bytesPerRow, (start + n) * bytesPerRow));
    }
    out.addAll([0x1B, 0x64, 0x04]); // ESC d 4  feed 4 lines
    return out;
  }
}

class _Painted {
  final TextPainter painter;
  final double dx;
  final double dy;
  _Painted(this.painter, this.dx, this.dy);
}
