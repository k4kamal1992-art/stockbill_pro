import 'package:uuid/uuid.dart';

enum TransactionType { sale, purchase, return_in, return_out, adjustment }

class StockTransactionModel {
  final String id;
  final String productId;
  final String productName;
  final TransactionType type;
  final double quantity;
  final double previousStock;
  final double newStock;
  final String? referenceId; // bill id or purchase id
  final String? notes;
  final DateTime createdAt;

  StockTransactionModel({
    String? id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.referenceId,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'referenceId': referenceId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockTransactionModel.fromMap(Map<String, dynamic> map) {
    return StockTransactionModel(
      id: map['id'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      type: TransactionType.values.byName(map['type'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      previousStock: (map['previousStock'] as num).toDouble(),
      newStock: (map['newStock'] as num).toDouble(),
      referenceId: map['referenceId'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
