enum UserRole {
  admin,
  manager,
  cashier,
  waiter,
}

enum UserStatus {
  active,
  inactive,
  suspended,
}

class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final UserRole role;
  UserStatus status;
  final String pin;
  DateTime? lastLoginAt;
  DateTime createdAt;
  String? phoneNumber;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.pin,
    this.status = UserStatus.active,
    this.lastLoginAt,
    DateTime? createdAt,
    this.phoneNumber,
  }) : createdAt = createdAt ?? DateTime.now();

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.waiter:
        return 'Waiter';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
    }
  }

  bool get canManageUsers => role == UserRole.admin || role == UserRole.manager;
  bool get canManageSettings => role == UserRole.admin || role == UserRole.manager;
  bool get canViewReports => role == UserRole.admin || role == UserRole.manager;
  bool get canProcessPayments => role != UserRole.waiter;

  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    UserRole? role,
    UserStatus? status,
    String? pin,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      pin: pin ?? this.pin,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
