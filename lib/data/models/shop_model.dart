class ShopModel {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? gstin;
  final String businessType;
  final String? ownerName;
  final String? logoPath;
  final bool isActive;
  final DateTime createdAt;

  ShopModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.gstin,
    required this.businessType,
    this.ownerName,
    this.logoPath,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'businessType': businessType,
      'ownerName': ownerName,
      'logoPath': logoPath,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      gstin: map['gstin'] as String?,
      businessType: map['businessType'] as String,
      ownerName: map['ownerName'] as String?,
      logoPath: map['logoPath'] as String?,
      isActive: (map['isActive'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ShopModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? businessType,
    String? ownerName,
    String? logoPath,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      logoPath: logoPath ?? this.logoPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
