import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/bill_model.dart';
import '../../core/constants/business_config.dart';

/// PrintService handles bill printing operations.
/// 
/// In production, integrate with bluetooth_print package:
/// 1. Uncomment bluetooth_print in pubspec.yaml
/// 2. Replace _printWithBluetooth() with actual bluetooth_print calls
/// 3. Call scanAndConnect() before printing
class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  bool _isConnected = false;
  bool _isScanning = false;
  String? _connectedDeviceName;

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  String? get connectedDeviceName => _connectedDeviceName;

  // ── Bluetooth Device Management ─────────────────────────────

  /// Scan for available Bluetooth printers
  Future<List<Map<String, dynamic>>> scanDevices() async {
    _isScanning = true;

    // TODO: Replace with actual bluetooth_print scan
    // final bluetoothPrint = BluetoothPrint.instance;
    // await bluetoothPrint.startScan(timeout: Duration(seconds: 4));
    // return bluetoothPrint.scanResults.map((d) => {
    //   'name': d.name,
    //   'address': d.address,
    // }).toList();

    // Demo: simulate scan delay and return mock devices
    await Future.delayed(const Duration(seconds: 2));
    _isScanning = false;
    return [
      {'name': 'XP-58IIH', 'address': '00:11:22:33:44:55'},
      {'name': 'EPSON TM-T82', 'address': '66:77:88:99:AA:BB'},
      {'name': 'Rongta RP58', 'address': 'CC:DD:EE:FF:00:11'},
    ];
  }

  /// Connect to a Bluetooth printer
  Future<bool> connectToDevice(String address, {String? name}) async {
    // TODO: Replace with actual bluetooth_print connect
    // final bluetoothPrint = BluetoothPrint.instance;
    // final device = BluetoothDevice();
    // device.address = address;
    // await bluetoothPrint.connect(device);

    await Future.delayed(const Duration(milliseconds: 800));
    _isConnected = true;
    _connectedDeviceName = name ?? 'Printer';
    return true;
  }

  /// Disconnect from printer
  Future<void> disconnect() async {
    // TODO: Replace with actual bluetooth_print disconnect
    // await BluetoothPrint.instance.disconnect();

    _isConnected = false;
    _connectedDeviceName = null;
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
    if (!_isConnected) {
      // Auto-connect attempt or return error
      return false;
    }

    try {
      final receipt = _generateReceiptText(
        bill: bill,
        storeName: storeName,
        storeAddress: storeAddress,
        storePhone: storePhone,
        gstin: gstin,
        businessType: businessType,
      );

      // TODO: Replace with actual bluetooth_print print
      // final bluetoothPrint = BluetoothPrint.instance;
      // final lines = receipt.split('\n');
      // for (final line in lines) {
      //   final ticket = LineText(
      //     type: LineText.TYPE_TEXT,
      //     content: line,
      //     align: line.contains('CENTER') ? LineText.ALIGN_CENTER : LineText.ALIGN_LEFT,
      //   );
      //   await bluetoothPrint.printTest();
      // }

      // Demo: print to console for verification
      debugPrint('========== BILL PRINT ==========');
      debugPrint(receipt);
      debugPrint('================================');

      await Future.delayed(const Duration(milliseconds: 1500));
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  /// Generate ESC/POS compatible receipt text
  String _generateReceiptText({
    required BillModel bill,
    required String storeName,
    String? storeAddress,
    String? storePhone,
    String? gstin,
    required BusinessType businessType,
  }) {
    final config = BusinessConfig.of(businessType);
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
    buffer.writeln('────────────────────────');
    buffer.writeln('BILL #: ${bill.billNumber}');
    buffer.writeln('Date: ${_formatDate(bill.billDate)}');
    buffer.writeln('────────────────────────');

    // Customer info
    buffer.writeln('Customer: ${bill.customerName}');
    if (bill.customerPhone != null) {
      buffer.writeln('Phone: ${bill.customerPhone}');
    }
    buffer.writeln('────────────────────────');

    // Items header
    buffer.writeln('ITEM          QTY  PRICE  TOTAL');
    buffer.writeln('────────────────────────');

    // Items
    for (final item in bill.items) {
      final name = item.productName.length > 12
          ? '${item.productName.substring(0, 12)}..'
          : item.productName.padRight(14);
      final qty = item.quantity.toStringAsFixed(0).padLeft(3);
      final price = '₹${item.unitPrice.toStringAsFixed(0)}'.padLeft(6);
      final total = '₹${item.totalPrice.toStringAsFixed(0)}'.padLeft(6);
      buffer.writeln('$name $qty $price $total');
    }

    buffer.writeln('────────────────────────');

    // Totals
    buffer.writeln('${'Subtotal:'.padLeft(20)} ${'₹${bill.subtotal.toStringAsFixed(2)}'.padLeft(8)}');
    buffer.writeln('${'GST:'.padLeft(20)} ${'₹${bill.gstAmount.toStringAsFixed(2)}'.padLeft(8)}');
    if (bill.discount > 0) {
      buffer.writeln('${'Discount:'.padLeft(20)} ${'-₹${bill.discount.toStringAsFixed(2)}'.padLeft(8)}');
    }
    buffer.writeln('${'GRAND TOTAL:'.padLeft(20)} ${'₹${bill.totalAmount.toStringAsFixed(2)}'.padLeft(8)}');
    buffer.writeln('${'Paid:'.padLeft(20)} ${'₹${bill.amountPaid.toStringAsFixed(2)}'.padLeft(8)}');
    if (bill.amountDue > 0) {
      buffer.writeln('${'Due:'.padLeft(20)} ${'₹${bill.amountDue.toStringAsFixed(2)}'.padLeft(8)}');
    }
    buffer.writeln('${'Payment:'.padLeft(20)} ${bill.paymentMethod.toUpperCase().padLeft(8)}');
    buffer.writeln('────────────────────────');
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
