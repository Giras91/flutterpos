enum PrinterType {
  receipt,
  kitchen,
  bar,
}

enum PrinterStatus {
  online,
  offline,
  error,
}

enum PrinterConnectionType {
  network,
  usb,
  bluetooth,
}

enum ThermalPaperSize {
  mm58,
  mm80,
}

class Printer {
  final String id;
  final String name;
  final PrinterType type;
  final PrinterConnectionType connectionType;
  final String? ipAddress;
  final int? port;
  final String? usbDeviceId;
  final String? bluetoothAddress;
  final String? platformSpecificId; // For Windows printer names, Android device IDs, etc.
  PrinterStatus status;
  bool isDefault;
  String? modelName;
  final ThermalPaperSize? paperSize;
  DateTime? lastPrintedAt;

  Printer({
    required this.id,
    required this.name,
    required this.type,
    required this.connectionType,
    this.ipAddress,
    this.port = 9100,
    this.usbDeviceId,
    this.bluetoothAddress,
    this.platformSpecificId,
    this.status = PrinterStatus.offline,
    this.isDefault = false,
    this.modelName,
    this.paperSize,
    this.lastPrintedAt,
  });

  String get typeDisplayName {
    switch (type) {
      case PrinterType.receipt:
        return 'Receipt Printer';
      case PrinterType.kitchen:
        return 'Kitchen Printer';
      case PrinterType.bar:
        return 'Bar Printer';
    }
  }

  String get connectionTypeDisplayName {
    switch (connectionType) {
      case PrinterConnectionType.network:
        return 'Network';
      case PrinterConnectionType.usb:
        return 'USB';
      case PrinterConnectionType.bluetooth:
        return 'Bluetooth';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case PrinterStatus.online:
        return 'Online';
      case PrinterStatus.offline:
        return 'Offline';
      case PrinterStatus.error:
        return 'Error';
    }
  }

  String get connectionDetails {
    switch (connectionType) {
      case PrinterConnectionType.network:
        return '${ipAddress ?? 'Unknown'}:${port ?? 9100}';
      case PrinterConnectionType.usb:
        return usbDeviceId ?? 'Unknown USB Device';
      case PrinterConnectionType.bluetooth:
        return bluetoothAddress ?? 'Unknown Bluetooth Device';
    }
  }

  Printer copyWith({
    String? id,
    String? name,
    PrinterType? type,
    PrinterConnectionType? connectionType,
    String? ipAddress,
    int? port,
    String? usbDeviceId,
    String? bluetoothAddress,
    String? platformSpecificId,
    PrinterStatus? status,
    bool? isDefault,
    String? modelName,
    ThermalPaperSize? paperSize,
    DateTime? lastPrintedAt,
  }) {
    return Printer(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      usbDeviceId: usbDeviceId ?? this.usbDeviceId,
      bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
      platformSpecificId: platformSpecificId ?? this.platformSpecificId,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      modelName: modelName ?? this.modelName,
      paperSize: paperSize ?? this.paperSize,
      lastPrintedAt: lastPrintedAt ?? this.lastPrintedAt,
    );
  }

  // Factory constructor for network printers (backward compatibility)
  factory Printer.network({
    required String id,
    required String name,
    required PrinterType type,
    required String ipAddress,
    int port = 9100,
    PrinterStatus status = PrinterStatus.offline,
    bool isDefault = false,
    String? modelName,
    DateTime? lastPrintedAt,
    ThermalPaperSize? paperSize,
  }) {
    return Printer(
      id: id,
      name: name,
      type: type,
      connectionType: PrinterConnectionType.network,
      ipAddress: ipAddress,
      port: port,
      status: status,
      isDefault: isDefault,
      modelName: modelName,
      lastPrintedAt: lastPrintedAt,
      paperSize: paperSize,
    );
  }

  // Factory constructor for USB printers
  factory Printer.usb({
    required String id,
    required String name,
    required PrinterType type,
    required String usbDeviceId,
    String? platformSpecificId,
    PrinterStatus status = PrinterStatus.offline,
    bool isDefault = false,
    String? modelName,
    DateTime? lastPrintedAt,
    ThermalPaperSize? paperSize,
  }) {
    return Printer(
      id: id,
      name: name,
      type: type,
      connectionType: PrinterConnectionType.usb,
      usbDeviceId: usbDeviceId,
      platformSpecificId: platformSpecificId,
      status: status,
      isDefault: isDefault,
      modelName: modelName,
      lastPrintedAt: lastPrintedAt,
      paperSize: paperSize,
    );
  }

  // Factory constructor for Bluetooth printers
  factory Printer.bluetooth({
    required String id,
    required String name,
    required PrinterType type,
    required String bluetoothAddress,
    String? platformSpecificId,
    PrinterStatus status = PrinterStatus.offline,
    bool isDefault = false,
    String? modelName,
    DateTime? lastPrintedAt,
    ThermalPaperSize? paperSize,
  }) {
    return Printer(
      id: id,
      name: name,
      type: type,
      connectionType: PrinterConnectionType.bluetooth,
      bluetoothAddress: bluetoothAddress,
      platformSpecificId: platformSpecificId,
      status: status,
      isDefault: isDefault,
      modelName: modelName,
      lastPrintedAt: lastPrintedAt,
      paperSize: paperSize,
    );
  }
}
