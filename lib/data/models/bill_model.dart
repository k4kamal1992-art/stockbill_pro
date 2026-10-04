import 'package:uuid/uuid.dart';

class BillItemModel {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double gstPercent;
  final double totalPrice;
  final String? batchNumber;
  final String? imei;
  final String? size;
  final String? color;

  BillItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.gstPercent = 0.0,
    required this.totalPrice,
    this.batchNumber,
    this.imei,
    this.size,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'gstPercent': gstPercent,
      'totalPrice': totalPrice,
      'batchNumber': batchNumber,
      'imei': imei,
      'size': size,
      'color': color,
    };
  }

  factory BillItemModel.fromMap(Map<String, dynamic> map) {
    return BillItemModel(
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      gstPercent: (map['gstPercent'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      batchNumber: map['batchNumber'] as String?,
      imei: map['imei'] as String?,
      size: map['size'] as String?,
      color: map['color'] as String?,
    );
  }
}

class BillModel {
  final String id;
  final String billNumber;
  final String customerName;
  final String? customerPhone;
  final List<BillItemModel> items;
  final double subtotal;
  final double gstAmount;
  final double totalAmount;
  final double discount;
  final String paymentMethod; // cash, upi, credit
  final double amountPaid;
  final double amountDue;
  final String businessType;
  final DateTime billDate;
  final DateTime createdAt;
  final bool isReturned;
  final String? notes;

  BillModel({
    String? id,
    required this.billNumber,
    required this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.gstAmount,
    required this.totalAmount,
    this.discount = 0.0,
    required this.paymentMethod,
    required this.amountPaid,
    required this.amountDue,
    required this.businessType,
    DateTime? billDate,
    DateTime? createdAt,
    this.isReturned = false,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        billDate = billDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'discount': discount,
      'paymentMethod': paymentMethod,
      'amountPaid': amountPaid,
      'amountDue': amountDue,
      'businessType': businessType,
      'billDate': billDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isReturned': isReturned ? 1 : 0,
      'notes': notes,
    };
  }

  /// Map for the `bills` table only (no nested `items` list, which would
  /// make sqflite throw). Items are stored separately in `bill_items`.
  Map<String, dynamic> toDbMap() {
    final map = toMap();
    map.remove('items');
    return map;
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as String,
      billNumber: map['billNumber'] as String,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String?,
      items: (map['items'] as List<dynamic>)
          .map((e) => BillItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      gstAmount: (map['gstAmount'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String,
      amountPaid: (map['amountPaid'] as num).toDouble(),
      amountDue: (map['amountDue'] as num).toDouble(),
      businessType: map['businessType'] as String,
      billDate: DateTime.parse(map['billDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isReturned: map['isReturned'] == 1,
      notes: map['notes'] as String?,
    );
  }
}
