enum BusinessMode {
  retail,
  cafe,
  restaurant,
}

extension BusinessModeExtension on BusinessMode {
  String get displayName {
    switch (this) {
      case BusinessMode.retail:
        return 'Retail';
      case BusinessMode.cafe:
        return 'Cafe';
      case BusinessMode.restaurant:
        return 'Restaurant';
    }
  }

  bool get hasTableManagement {
    return this == BusinessMode.restaurant;
  }

  bool get useCallingNumbers {
    return this == BusinessMode.cafe;
  }

  String get subtitle {
    switch (this) {
      case BusinessMode.retail:
        return 'Direct Sale';
      case BusinessMode.cafe:
        return 'Calling Numbers';
      case BusinessMode.restaurant:
        return 'Table Service';
    }
  }
}
