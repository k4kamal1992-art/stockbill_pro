import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/bill_model.dart';
import '../../core/constants/business_config.dart';
import 'receipt_renderer.dart';

/// PrintService prints bills on Bluetooth ESC/POS thermal printers.
///
/// How it works
/// * The printer must first be PAIRED in the phone's Bluetooth settings.
///   [scanDevices] lists the paired devices, [connectToDevice] opens the link.
/// * Receipts are drawn as an image (see [ReceiptCanvas]) so Bengali/Hindi
///   text and the rupee sign print correctly. If drawing fails, a plain
///   ASCII text receipt is sent instead.
/// * The last used printer is remembered and reconnected automatically.
class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  static const String _prefAddress = 'printer_address';
  static const String _prefName = 'printer_name';
  static const String _prefPaperDots = 'printer_paper_dots';

  bool _isConnected = false;
  bool _isScanning = false;
  String? _connectedDeviceName;
  String? _connectedAddress;

  /// Human readable reason of the last failure (Bengali), for the UI.
  String? lastError;

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedAddress => _connectedAddress;

  // ── Settings ────────────────────────────────────────────────

  /// 384 = 58 mm paper (default), 576 = 80 mm paper.
  Future<int> getPaperWidthDots() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefPaperDots) ?? 384;
  }

  Future<void> setPaperWidthDots(int dots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefPaperDots, dots == 576 ? 576 : 384);
  }

  // ── Permissions ─────────────────────────────────────────────

  Future<bool> _ensurePermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final result = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();
      final connect = result[Permission.bluetoothConnect];
      if (connect == PermissionStatus.granted ||
          connect == PermissionStatus.limited) {
        return true;
      }
      // Android 11 and older have no runtime Bluetooth permission;
      // ask the plugin for its own verdict.
      return await PrintBluetoothThermal.isPermissionBluetoothGranted;
    } catch (e) {
      debugPrint('Bluetooth permission error: $e');
      return false;
    }
  }

  // ── Bluetooth Device Management ─────────────────────────────

  /// Lists the printers already paired with this phone.
  Future<List<Map<String, dynamic>>> scanDevices() async {
    lastError = null;
    _isScanning = true;
    try {
      if (!await _ensurePermissions()) {
        lastError = 'ব্লুটুথ পারমিশন দেওয়া হয়নি। ফোনের Settings থেকে অ্যাপকে "Nearby devices" পারমিশন দিন।';
        return [];
      }
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) {
        lastError = 'ফোনের ব্লুটুথ বন্ধ আছে। চালু করে আবার চেষ্টা করুন।';
        return [];
      }
      final paired = await PrintBluetoothThermal.pairedBluetooths;
      final list = paired
          .map((d) => <String, dynamic>{'name': d.name, 'address': d.macAdress})
          .toList();
      if (list.isEmpty) {
        lastError =
            'কোনো paired প্রিন্টার নেই। আগে ফোনের Bluetooth সেটিংসে প্রিন্টারটি pair করুন (সাধারণত PIN 0000 বা 1234)।';
      }
      return list;
    } catch (e) {
      debugPrint('scanDevices error: $e');
      lastError = 'প্রিন্টার খুঁজতে সমস্যা হয়েছে: $e';
      return [];
    } finally {
      _isScanning = false;
    }
  }

  /// Connect to a paired Bluetooth printer.
  Future<bool> connectToDevice(String address, {String? name}) async {
    lastError = null;
    try {
      if (!await _ensurePermissions()) {
        lastError = 'ব্লুটুথ পারমিশন দেওয়া হয়নি।';
        return false;
      }
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: address);
      if (!ok) {
        _isConnected = false;
        lastError =
            'প্রিন্টারের সাথে সংযোগ হয়নি। প্রিন্টার চালু ও কাছে আছে কিনা দেখুন।';
        return false;
      }
      _isConnected = true;
      _connectedAddress = address;
      _connectedDeviceName = name ?? 'Printer';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAddress, address);
      await prefs.setString(_prefName, _connectedDeviceName!);
      return true;
    } catch (e) {
      debugPrint('connect error: $e');
      lastError = 'সংযোগে সমস্যা: $e';
      _isConnected = false;
      return false;
    }
  }

  /// Disconnect from printer (and forget it, so no auto-reconnect).
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (e) {
      debugPrint('disconnect error: $e');
    }
    _isConnected = false;
    _connectedDeviceName = null;
    _connectedAddress = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefAddress);
    await prefs.remove(_prefName);
  }

  /// True if a printer is connected right now; otherwise tries the printer
  /// that was used last time.
  Future<bool> ensureConnected() async {
    try {
      if (_isConnected && await PrintBluetoothThermal.connectionStatus) {
        return true;
      }
    } catch (_) {}
    _isConnected = false;

    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_prefAddress);
    if (address == null) {
      lastError = 'কোনো প্রিন্টার সংযুক্ত নেই।';
      return false;
    }
    return connectToDevice(address, name: prefs.getString(_prefName));
  }

  // ── Bill Printing ───────────────────────────────────────────

  /// Print a bill receipt
  Future<bool> printBill({
    required BillModel bill,
    required String storeName,
    String? storeAddress,
    String? storePhone,
    String? gstin,
    required BusinessType businessType,
  }) async {
    lastError = null;
    if (!await ensureConnected()) return false;

    List<int> bytes;
    try {
      bytes = await _buildRasterReceipt(
        bill: bill,
        storeName: storeName,
        storeAddress: storeAddress,
        storePhone: storePhone,
        gstin: gstin,
        widthDots: await getPaperWidthDots(),
      );
    } catch (e) {
      // Image drawing failed: fall back to plain text.
      debugPrint('Raster receipt failed ($e), using text mode');
      bytes = textModeBytes(
        _generateReceiptText(
          bill: bill,
          storeName: storeName,
          storeAddress: storeAddress,
          storePhone: storePhone,
          gstin: gstin,
          businessType: businessType,
          forPrint: true,
        ),
      );
    }
    return _write(bytes);
  }

  /// Prints a short test page (also shows whether Bengali text works).
  Future<bool> printTestPage() async {
    lastError = null;
    if (!await ensureConnected()) return false;
    try {
      final r = ReceiptCanvas(widthDots: await getPaperWidthDots());
      r.addText('StockBill Pro', center: true, bold: true, size: 30);
      r.addText('Test print', center: true);
      r.addText('টেস্ট প্রিন্ট ঠিক আছে', center: true);
      r.addDivider();
      r.addKeyValue('Total', '₹ 1,234.50', bold: true);
      r.addDivider();
      r.addText('Printer is working', center: true, size: 20);
      return _write(await r.toEscPos());
    } catch (e) {
      lastError = 'টেস্ট প্রিন্ট ব্যর্থ: $e';
      return false;
    }
  }

  Future<bool> _write(List<int> bytes) async {
    try {
      const chunk = 2048;
      for (var i = 0; i < bytes.length; i += chunk) {
        final end = (i + chunk < bytes.length) ? i + chunk : bytes.length;
        final ok = await PrintBluetoothThermal.writeBytes(bytes.sublist(i, end));
        if (!ok) {
          _isConnected = false;
          lastError = 'প্রিন্টারে ডেটা পাঠানো যায়নি। সংযোগ আবার দিন।';
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 30));
      }
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      lastError = 'প্রিন্ট ব্যর্থ: $e';
      return false;
    }
  }

  // ── Receipt builders ────────────────────────────────────────

  String _qty(double q) =>
      q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

  String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<List<int>> _buildRasterReceipt({
    required BillModel bill,
    required String storeName,
    String? storeAddress,
    String? storePhone,
    String? gstin,
    required int widthDots,
  }) async {
    final r = ReceiptCanvas(widthDots: widthDots);
    r.addText(storeName, center: true, bold: true, size: 30);
    if (storeAddress != null && storeAddress.isNotEmpty) {
      r.addText(storeAddress, center: true, size: 20);
    }
    if (storePhone != null && storePhone.isNotEmpty) {
      r.addText('Ph: $storePhone', center: true, size: 20);
    }
    if (gstin != null && gstin.isNotEmpty) {
      r.addText('GSTIN: $gstin', center: true, size: 20);
    }
    r.addDivider();
    r.addKeyValue('Bill #', bill.billNumber, bold: true);
    r.addKeyValue('Date', _formatDate(bill.billDate));
    r.addKeyValue('Customer', bill.customerName);
    if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty) {
      r.addKeyValue('Phone', bill.customerPhone!);
    }
    r.addDivider();
    r.addItemRow('ITEM', 'QTY', 'PRICE', 'TOTAL', bold: true);
    r.addDivider();
    for (final item in bill.items) {
      r.addItemRow(
        item.productName,
        _qty(item.quantity),
        _num(item.unitPrice),
        _num(item.totalPrice),
      );
    }
    r.addDivider();
    r.addKeyValue('Subtotal', '₹${bill.subtotal.toStringAsFixed(2)}');
    r.addKeyValue('GST', '₹${bill.gstAmount.toStringAsFixed(2)}');
    if (bill.discount > 0) {
      r.addKeyValue('Discount', '-₹${bill.discount.toStringAsFixed(2)}');
    }
    r.addKeyValue('TOTAL', '₹${bill.totalAmount.toStringAsFixed(2)}',
        bold: true, size: 28);
    r.addKeyValue('Paid', '₹${bill.amountPaid.toStringAsFixed(2)}');
    if (bill.amountDue > 0) {
      r.addKeyValue('Due', '₹${bill.amountDue.toStringAsFixed(2)}', bold: true);
    }
    r.addKeyValue('Payment', bill.paymentMethod.toUpperCase());
    r.addDivider();
    r.addText('Thank you! Visit again', center: true);
    r.addText('Powered by StockBill Pro', center: true, size: 18);
    r.addSpace(8);
    return r.toEscPos();
  }

  /// Plain ESC/POS text bytes (ASCII only). Used as a fallback.
  @visibleForTesting
  List<int> textModeBytes(String receipt) {
    final out = <int>[0x1B, 0x40];
    for (final line in receipt.split('\n')) {
      final center = line.startsWith('CENTER');
      final text = _ascii(center ? line.substring(6) : line);
      out.addAll([0x1B, 0x61, center ? 1 : 0]);
      out.addAll(text.codeUnits);
      out.add(0x0A);
    }
    out.addAll([0x1B, 0x61, 0x00, 0x1B, 0x64, 0x04]);
    return out;
  }

  String _ascii(String s) {
    final b = StringBuffer();
    for (final rune in s.runes) {
      if (rune >= 32 && rune < 127) {
        b.writeCharCode(rune);
      } else if (rune == 0x20B9) {
        b.write('Rs');
      } else if (rune == 0x2500) {
        b.write('-');
      } else {
        b.write('?');
      }
    }
    return b.toString();
  }

  /// Generate ESC/POS compatible receipt text
  String _generateReceiptText({
    required BillModel bill,
    required String storeName,
    String? storeAddress,
    String? storePhone,
    String? gstin,
    required BusinessType businessType,
    bool forPrint = false,
  }) {
    // forPrint: plain ASCII layout for text-mode printers (32 columns).
    final cur = forPrint ? '' : '₹';
    final rule = forPrint ? '-' * 32 : '────────────────────────';
    final buffer = StringBuffer();

    // Header
    buffer.writeln('CENTER${storeName.toUpperCase()}');
    if (storeAddress != null && storeAddress.isNotEmpty) {
      buffer.writeln(storeAddress);
    }
    if (storePhone != null && storePhone.isNotEmpty) {
      buffer.writeln('Ph: $storePhone');
    }
    if (gstin != null && gstin.isNotEmpty) {
      buffer.writeln('GSTIN: $gstin');
    }
    buffer.writeln(rule);
    buffer.writeln('BILL #: ${bill.billNumber}');
    buffer.writeln('Date: ${_formatDate(bill.billDate)}');
    buffer.writeln(rule);

    // Customer info
    buffer.writeln('Customer: ${bill.customerName}');
    if (bill.customerPhone != null) {
      buffer.writeln('Phone: ${bill.customerPhone}');
    }
    buffer.writeln(rule);

    // Items header
    buffer.writeln('ITEM          QTY  PRICE  TOTAL');
    buffer.writeln(rule);

    // Items
    for (final item in bill.items) {
      final name = item.productName.length > 12
          ? '${item.productName.substring(0, 12)}..'
          : item.productName.padRight(14);
      final qty = item.quantity.toStringAsFixed(0).padLeft(3);
      final price = '${cur}${item.unitPrice.toStringAsFixed(0)}'.padLeft(6);
      final total = '${cur}${item.totalPrice.toStringAsFixed(0)}'.padLeft(6);
      buffer.writeln('$name $qty $price $total');
    }

    buffer.writeln(rule);

    // Totals
    buffer.writeln('${'Subtotal:'.padLeft(20)} ${'${cur}${bill.subtotal.toStringAsFixed(2)}'.padLeft(8)}');
    buffer.writeln('${'GST:'.padLeft(20)} ${'${cur}${bill.gstAmount.toStringAsFixed(2)}'.padLeft(8)}');
    if (bill.discount > 0) {
      buffer.writeln('${'Discount:'.padLeft(20)} ${'-${cur}${bill.discount.toStringAsFixed(2)}'.padLeft(8)}');
    }
    buffer.writeln('${'GRAND TOTAL:'.padLeft(20)} ${'${cur}${bill.totalAmount.toStringAsFixed(2)}'.padLeft(8)}');
    buffer.writeln('${'Paid:'.padLeft(20)} ${'${cur}${bill.amountPaid.toStringAsFixed(2)}'.padLeft(8)}');
    if (bill.amountDue > 0) {
      buffer.writeln('${'Due:'.padLeft(20)} ${'${cur}${bill.amountDue.toStringAsFixed(2)}'.padLeft(8)}');
    }
    buffer.writeln('${'Payment:'.padLeft(20)} ${bill.paymentMethod.toUpperCase().padLeft(8)}');
    buffer.writeln(rule);
    buffer.writeln('CENTERThank You! Visit Again');
    buffer.writeln('CENTERPowered by StockBill Pro');
    buffer.writeln();
    buffer.writeln();
    buffer.writeln();

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // ── Share as Text ───────────────────────────────────────────

  /// Generate shareable bill text (for WhatsApp/SMS)
  String generateShareText({
    required BillModel bill,
    required String storeName,
    String? storePhone,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('*$storeName*');
    buffer.writeln('Bill #: ${bill.billNumber}');
    buffer.writeln('Date: ${_formatDate(bill.billDate)}');
    buffer.writeln('Customer: ${bill.customerName}');
    buffer.writeln('');
    buffer.writeln('Items:');
    for (final item in bill.items) {
      buffer.writeln('${item.productName} x${item.quantity.toStringAsFixed(0)} = ₹${item.totalPrice.toStringAsFixed(0)}');
    }
    buffer.writeln('');
    buffer.writeln('Subtotal: ₹${bill.subtotal.toStringAsFixed(2)}');
    buffer.writeln('GST: ₹${bill.gstAmount.toStringAsFixed(2)}');
    buffer.writeln('*Total: ₹${bill.totalAmount.toStringAsFixed(2)}*');
    buffer.writeln('Paid: ₹${bill.amountPaid.toStringAsFixed(2)}');
    if (bill.amountDue > 0) {
      buffer.writeln('Due: ₹${bill.amountDue.toStringAsFixed(2)}');
    }
    buffer.writeln('');
    buffer.writeln('Thank you for shopping!');
    if (storePhone != null) {
      buffer.writeln('Contact: $storePhone');
    }
    return buffer.toString();
  }

  // ── Print Preview (for on-screen display) ───────────────────

  List<Map<String, dynamic>> generatePrintPreview({
    required BillModel bill,
    required String storeName,
    String? storeAddress,
    String? storePhone,
    String? gstin,
    required BusinessType businessType,
  }) {
    final receipt = _generateReceiptText(
      bill: bill,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      gstin: gstin,
      businessType: businessType,
    );

    return receipt.split('\n').map((line) {
      final isCenter = line.startsWith('CENTER');
      final isDivider = line.contains('─');
      final cleanLine = line.replaceFirst('CENTER', '');
      return {
        'text': cleanLine,
        'isCenter': isCenter,
        'isDivider': isDivider,
        'isBold': cleanLine.contains('TOTAL') || cleanLine.contains(storeName.toUpperCase()),
      };
    }).toList();
  }
}
