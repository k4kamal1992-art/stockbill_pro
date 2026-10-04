import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

/// GSTService generates GSTR-1 compatible JSON for filing GST returns.
class GSTService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<Map<String, dynamic>> generateGSTR1({
    required DateTime month,
    required String gstin,
    required String shopName,
    String? shopId,
  }) async {
    final db = await _db.database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final billMaps = await db.query(
      'bills',
      where: "date(billDate) >= date(?) AND date(billDate) <= date(?) AND totalAmount > 0 AND isDeleted = 0",
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    final b2b = <Map<String, dynamic>>[];
    final b2cl = <Map<String, dynamic>>[];
    final b2cs = <Map<String, dynamic>>[];

    for (final billMap in billMaps) {
      final items = await db.query(
        'bill_items',
        where: 'billId = ?',
        whereArgs: [billMap['id']],
      );

      final invoiceValue = (billMap['totalAmount'] as num).toDouble();
      const pos = '19';

      final itemList = items.map((item) {
        final qty = (item['quantity'] as num).toDouble();
        final unitPrice = (item['unitPrice'] as num).toDouble();
        final gstPct = (item['gstPercent'] as num?)?.toDouble() ?? 0;
        final taxable = qty * unitPrice;
        final igst = taxable * gstPct / 100;
        return {
          'itm_det': {
            'txval': double.parse(taxable.toStringAsFixed(2)),
            'rt': gstPct,
            'iamt': double.parse(igst.toStringAsFixed(2)),
          },
        };
      }).toList();

      final invoice = {
        'inum': billMap['billNumber'] as String,
        'idt': DateFormat('dd-MM-yyyy').format(DateTime.parse(billMap['billDate'] as String)),
        'val': double.parse(invoiceValue.toStringAsFixed(2)),
        'pos': pos,
        'itms': itemList,
      };

      if (invoiceValue > 250000) {
        b2cl.add(invoice);
      } else {
        b2cs.add({
          'sply_ty': 'INTER',
          'rt': items.isNotEmpty ? (items.first['gstPercent'] as num?)?.toDouble() ?? 5 : 5,
          'typ': 'OE',
          'pos': pos,
          'txval': double.parse(invoiceValue.toStringAsFixed(2)),
          'iamt': double.parse((invoiceValue * 0.05).toStringAsFixed(2)),
        });
      }
    }

    final gstr1 = {
      'gstin': gstin,
      'fp': DateFormat('MMyyyy').format(month),
      'version': 'GST3.0.4',
      'hash': 'hash',
      'b2b': b2b.isEmpty ? [] : b2b,
      'b2cl': b2cl.isEmpty ? [] : b2cl,
      'b2cs': b2cs.isEmpty ? [] : b2cs,
    };

    debugPrint('GSTR-1 generated for ' + DateFormat('MMM yyyy').format(month));
    return gstr1;
  }

  Future<String> exportGSTR1Json({
    required DateTime month,
    required String gstin,
    required String shopName,
    String? shopId,
  }) async {
    final data = await generateGSTR1(
      month: month,
      gstin: gstin,
      shopName: shopName,
      shopId: shopId,
    );
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<Map<String, dynamic>> getGSTSummary({
    required DateTime month,
    String? shopId,
  }) async {
    final db = await _db.database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      'SELECT SUM(subtotal) as taxable_value, SUM(gstAmount) as total_gst, COUNT(*) as invoice_count, SUM(CASE WHEN totalAmount > 250000 THEN 1 ELSE 0 END) as large_invoices FROM bills WHERE date(billDate) >= date(?) AND date(billDate) <= date(?) AND totalAmount > 0 AND isDeleted = 0',
      [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
    );

    final row = result.first;
    return {
      'taxableValue': (row['taxable_value'] as num?)?.toDouble() ?? 0,
      'totalGst': (row['total_gst'] as num?)?.toDouble() ?? 0,
      'invoiceCount': (row['invoice_count'] as int?) ?? 0,
      'largeInvoices': (row['large_invoices'] as int?) ?? 0,
      'month': DateFormat('MMMM yyyy').format(month),
    };
  }
}