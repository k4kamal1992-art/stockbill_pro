import 'package:uuid/uuid.dart';

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final double totalDue;
  final double totalPaid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  CustomerModel({
    String? id,
    required this.name,
    this.phone,
    this.address,
    this.totalDue = 0.0,
    this.totalPaid = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      totalDue: (map['totalDue'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: map['isActive'] == 1,
    );
  }

  CustomerModel copyWith({
    String? name,
    String? phone,
    String? address,
    double? totalDue,
    double? totalPaid,
    bool? isActive,
  }) {
    return CustomerModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalDue: totalDue ?? this.totalDue,
      totalPaid: totalPaid ?? this.totalPaid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  /// totalDue is the CURRENT outstanding amount (the UI treats it that way).
  double get balance => totalDue;
}
