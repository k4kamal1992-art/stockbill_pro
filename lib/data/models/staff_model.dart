class StaffModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final StaffRole role;
  final String? pin;
  final String? shopId;
  final StaffPermissions permissions;
  final bool isActive;
  final DateTime createdAt;

  StaffModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.role,
    this.pin,
    this.shopId,
    required this.permissions,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.name,
      'pin': pin,
      'shopId': shopId,
      'permissions': permissions.toJson(),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StaffModel.fromMap(Map<String, dynamic> map) {
    return StaffModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      role: StaffRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => StaffRole.staff,
      ),
      pin: map['pin'] as String?,
      shopId: map['shopId'] as String?,
      permissions: StaffPermissions.fromJson(map['permissions'] as String? ?? '{}'),
      isActive: (map['isActive'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

enum StaffRole { owner, manager, salesman, staff }

class StaffPermissions {
  final bool canSell;
  final bool canEditProduct;
  final bool canDeleteProduct;
  final bool canViewReports;
  final bool canManageCustomers;
  final bool canManageSuppliers;
  final bool canAddExpense;
  final bool canManageStaff;
  final bool canBackup;
  final bool canReturn;

  const StaffPermissions({
    this.canSell = true,
    this.canEditProduct = false,
    this.canDeleteProduct = false,
    this.canViewReports = false,
    this.canManageCustomers = true,
    this.canManageSuppliers = false,
    this.canAddExpense = false,
    this.canManageStaff = false,
    this.canBackup = false,
    this.canReturn = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'canSell': canSell,
      'canEditProduct': canEditProduct,
      'canDeleteProduct': canDeleteProduct,
      'canViewReports': canViewReports,
      'canManageCustomers': canManageCustomers,
      'canManageSuppliers': canManageSuppliers,
      'canAddExpense': canAddExpense,
      'canManageStaff': canManageStaff,
      'canBackup': canBackup,
      'canReturn': canReturn,
    };
  }

  String toJson() => toMap().toString();

  factory StaffPermissions.fromJson(String json) {
    try {
      // Simple parsing for demo
      return const StaffPermissions();
    } catch (_) {
      return const StaffPermissions();
    }
  }

  static StaffPermissions forRole(StaffRole role) {
    switch (role) {
      case StaffRole.owner:
        return const StaffPermissions(
          canSell: true,
          canEditProduct: true,
          canDeleteProduct: true,
          canViewReports: true,
          canManageCustomers: true,
          canManageSuppliers: true,
          canAddExpense: true,
          canManageStaff: true,
          canBackup: true,
          canReturn: true,
        );
      case StaffRole.manager:
        return const StaffPermissions(
          canSell: true,
          canEditProduct: true,
          canDeleteProduct: false,
          canViewReports: true,
          canManageCustomers: true,
          canManageSuppliers: true,
          canAddExpense: true,
          canManageStaff: false,
          canBackup: true,
          canReturn: true,
        );
      case StaffRole.salesman:
        return const StaffPermissions(
          canSell: true,
          canEditProduct: false,
          canDeleteProduct: false,
          canViewReports: false,
          canManageCustomers: true,
          canManageSuppliers: false,
          canAddExpense: false,
          canManageStaff: false,
          canBackup: false,
          canReturn: true,
        );
      case StaffRole.staff:
        return const StaffPermissions(
          canSell: true,
          canEditProduct: false,
          canDeleteProduct: false,
          canViewReports: false,
          canManageCustomers: false,
          canManageSuppliers: false,
          canAddExpense: false,
          canManageStaff: false,
          canBackup: false,
          canReturn: false,
        );
    }
  }
}
