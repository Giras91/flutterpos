enum PaymentMethodStatus {
  active,
  inactive,
}

class PaymentMethod {
  final String id;
  final String name;
  PaymentMethodStatus status;
  bool isDefault;
  DateTime? createdAt;

  PaymentMethod({
    required this.id,
    required this.name,
    this.status = PaymentMethodStatus.active,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get statusDisplayName {
    switch (status) {
      case PaymentMethodStatus.active:
        return 'Active';
      case PaymentMethodStatus.inactive:
        return 'Inactive';
    }
  }

  PaymentMethod copyWith({
    String? id,
    String? name,
    PaymentMethodStatus? status,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}