class SubscriptionSummary {
  final String plan;
  final String endsAt;
  final int daysRemaining;
  final bool shouldRenew;
  final bool isExpired;
  final int outletsAllowed;

  SubscriptionSummary({
    required this.plan,
    required this.endsAt,
    required this.daysRemaining,
    required this.shouldRenew,
    required this.isExpired,
    required this.outletsAllowed,
  });

  factory SubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return SubscriptionSummary(
      plan: json['plan'] ?? 'Active Plan',
      endsAt: json['ends_at'] ?? '',
      daysRemaining: json['days_remaining'] ?? 0,
      shouldRenew: json['should_renew'] ?? false,
      isExpired: json['is_expired'] ?? false,
      outletsAllowed: json['outlets_allowed'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'ends_at': endsAt,
      'days_remaining': daysRemaining,
      'should_renew': shouldRenew,
      'is_expired': isExpired,
      'outlets_allowed': outletsAllowed,
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final List<String> roles;
  final SubscriptionSummary? subscription;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.roles,
    this.subscription,
  });

  bool get isSuperAdmin => roles.contains('saas_super_admin');
  bool get isAdmin => roles.contains('admin');
  bool get isManager => roles.contains('manager');
  bool get isWaiter => roles.contains('waiter');
  bool get isChef => roles.contains('chef');
  bool get isCashier => roles.contains('cashier');
  bool get isCustomer => roles.contains('customer');
  bool get isDeliveryExecutive => roles.contains('delivery_executive');
  bool get isAccountant => roles.contains('accountant');

  bool get isOnlyCustomer {
    return isCustomer &&
        !isSuperAdmin &&
        !isAdmin &&
        !isManager &&
        !isWaiter &&
        !isChef &&
        !isCashier &&
        !isDeliveryExecutive &&
        !isAccountant;
  }

  String get primaryRole {
    if (isSuperAdmin) return 'saas_super_admin';
    if (isAdmin) return 'admin';
    if (isManager) return 'manager';
    if (isChef) return 'chef';
    if (isWaiter) return 'waiter';
    if (isCashier) return 'cashier';
    if (isDeliveryExecutive) return 'delivery_executive';
    if (isAccountant) return 'accountant';
    return 'staff';
  }

  bool get hasMultipleDashboards {
    return !isOnlyCustomer;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> rolesList = [];
    if (json['roles'] != null) {
      rolesList = (json['roles'] as List).map((role) {
        if (role is Map) {
          return role['name'].toString();
        }
        return role.toString();
      }).toList();
    } else if (json['role'] != null) {
      rolesList = [json['role'].toString()];
    }

    return UserModel(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'] ?? '',
      roles: rolesList,
      subscription: json['subscription'] != null
          ? SubscriptionSummary.fromJson(json['subscription'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'roles': roles,
      'subscription': subscription?.toJson(),
    };
  }
}
