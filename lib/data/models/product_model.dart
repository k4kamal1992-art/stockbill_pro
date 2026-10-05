import 'package:uuid/uuid.dart';

class ProductModel {
  final String id;
  final String name;
  final String? nameBn;
  final String category;
  final String? brand;
  final String? barcode;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double gstPercent;
  final double stockQuantity;
  final double minStockLevel;
  final String? expiryDate; // YYYY-MM-DD
  final String? batchNumber;
  final String businessType;
  final String? unit; // piece, kg, liter, box, meter
  final double? unitConversion; // 1 box = 12 pieces
  final String? size;
  final String? color;
  final String? imei;
  final String? serialNumber;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? partNumber;
  final String? genericName;
  final String? company;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ProductModel({
    String? id,
    required this.name,
    this.nameBn,
    required this.category,
    this.brand,
    this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.mrp,
    this.gstPercent = 0.0,
    required this.stockQuantity,
    this.minStockLevel = 0.0,
    this.expiryDate,
    this.batchNumber,
    required this.businessType,
    this.unit,
    this.unitConversion,
    this.size,
    this.color,
    this.imei,
    this.serialNumber,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.partNumber,
    this.genericName,
    this.company,
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
      'nameBn': nameBn,
      'category': category,
      'brand': brand,
      'barcode': barcode,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'mrp': mrp,
      'gstPercent': gstPercent,
      'stockQuantity': stockQuantity,
      'minStockLevel': minStockLevel,
      'expiryDate': expiryDate,
      'batchNumber': batchNumber,
      'businessType': businessType,
      'unit': unit,
      'unitConversion': unitConversion,
      'size': size,
      'color': color,
      'imei': imei,
      'serialNumber': serialNumber,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'partNumber': partNumber,
      'genericName': genericName,
      'company': company,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      nameBn: map['nameBn'] as String?,
      category: map['category'] as String,
      brand: map['brand'] as String?,
      barcode: map['barcode'] as String?,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      mrp: (map['mrp'] as num).toDouble(),
      gstPercent: (map['gstPercent'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num).toDouble(),
      minStockLevel: (map['minStockLevel'] as num?)?.toDouble() ?? 0.0,
      expiryDate: map['expiryDate'] as String?,
      batchNumber: map['batchNumber'] as String?,
      businessType: map['businessType'] as String,
      unit: map['unit'] as String?,
      unitConversion: map['unitConversion'] != null
          ? (map['unitConversion'] as num).toDouble()
          : null,
      size: map['size'] as String?,
      color: map['color'] as String?,
      imei: map['imei'] as String?,
      serialNumber: map['serialNumber'] as String?,
      vehicleBrand: map['vehicleBrand'] as String?,
      vehicleModel: map['vehicleModel'] as String?,
      vehicleYear: map['vehicleYear'] as String?,
      partNumber: map['partNumber'] as String?,
      genericName: map['genericName'] as String?,
      company: map['company'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: map['isActive'] == 1,
    );
  }

  ProductModel copyWith({
    String? name,
    String? nameBn,
    String? category,
    String? brand,
    String? barcode,
    double? purchasePrice,
    double? sellingPrice,
    double? mrp,
    double? gstPercent,
    double? stockQuantity,
    double? minStockLevel,
    String? expiryDate,
    String? batchNumber,
    String? unit,
    double? unitConversion,
    String? size,
    String? color,
    String? imei,
    String? serialNumber,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleYear,
    String? partNumber,
    String? genericName,
    String? company,
    bool? isActive,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      nameBn: nameBn ?? this.nameBn,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      gstPercent: gstPercent ?? this.gstPercent,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      businessType: businessType,
      unit: unit ?? this.unit,
      unitConversion: unitConversion ?? this.unitConversion,
      size: size ?? this.size,
      color: color ?? this.color,
      imei: imei ?? this.imei,
      serialNumber: serialNumber ?? this.serialNumber,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      partNumber: partNumber ?? this.partNumber,
      genericName: genericName ?? this.genericName,
      company: company ?? this.company,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isLowStock => stockQuantity <= minStockLevel;
  bool get isOutOfStock => stockQuantity <= 0;

  double get gstAmount => sellingPrice * (gstPercent / 100);
  double get finalPrice => sellingPrice + gstAmount;
}
