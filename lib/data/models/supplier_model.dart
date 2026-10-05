class SupplierModel {
  final String id;
  final String name;
  final String? company;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstin;
  final String? shopId;
  final double totalPurchases;
  final double totalPaid;
  final double balanceDue;
  final bool isActive;
  final DateTime createdAt;

  SupplierModel({
    required this.id,
    required this.name,
    this.company,
    this.phone,
    this.email,
    this.address,
    this.gstin,
    this.shopId,
    this.totalPurchases = 0,
    this.totalPaid = 0,
    this.balanceDue = 0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'shopId': shopId,
      'totalPurchases': totalPurchases,
      'totalPaid': totalPaid,
      'balanceDue': balanceDue,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'] as String,
      name: map['name'] as String,
      company: map['company'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      gstin: map['gstin'] as String?,
      shopId: map['shopId'] as String?,
      totalPurchases: (map['totalPurchases'] as num?)?.toDouble() ?? 0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0,
      balanceDue: (map['balanceDue'] as num?)?.toDouble() ?? 0,
      isActive: (map['isActive'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? company,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    String? shopId,
    double? totalPurchases,
    double? totalPaid,
    double? balanceDue,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      shopId: shopId ?? this.shopId,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPaid: totalPaid ?? this.totalPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
