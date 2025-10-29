class ReceiptSettings {
  final String headerText;
  final String footerText;
  final bool showLogo;
  final bool showDateTime;
  final bool showOrderNumber;
  final bool showCashierName;
  final bool showTaxBreakdown;
  final bool showServiceChargeBreakdown;
  final bool showThankYouMessage;
  final bool autoPrint;
  final ReceiptPaperSize paperSize;
  final int paperWidth; // in mm
  final int fontSize;
  final String thankYouMessage;
  final String termsAndConditions;

  ReceiptSettings({
    this.headerText = 'ExtroPOS',
    this.footerText = 'Thank you for your business!',
    this.showLogo = true,
    this.showDateTime = true,
    this.showOrderNumber = true,
    this.showCashierName = true,
    this.showTaxBreakdown = true,
  this.showServiceChargeBreakdown = true,
    this.showThankYouMessage = true,
    this.autoPrint = false,
    this.paperSize = ReceiptPaperSize.mm80,
    this.paperWidth = 80,
    this.fontSize = 12,
    this.thankYouMessage = 'Thank you! Please come again.',
    this.termsAndConditions = '',
  });

  ReceiptSettings copyWith({
    String? headerText,
    String? footerText,
    bool? showLogo,
    bool? showDateTime,
    bool? showOrderNumber,
    bool? showCashierName,
    bool? showTaxBreakdown,
  bool? showServiceChargeBreakdown,
    bool? showThankYouMessage,
    bool? autoPrint,
    ReceiptPaperSize? paperSize,
    int? paperWidth,
    int? fontSize,
    String? thankYouMessage,
    String? termsAndConditions,
  }) {
    return ReceiptSettings(
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
      showLogo: showLogo ?? this.showLogo,
      showDateTime: showDateTime ?? this.showDateTime,
      showOrderNumber: showOrderNumber ?? this.showOrderNumber,
      showCashierName: showCashierName ?? this.showCashierName,
      showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
  showServiceChargeBreakdown: showServiceChargeBreakdown ?? this.showServiceChargeBreakdown,
      showThankYouMessage: showThankYouMessage ?? this.showThankYouMessage,
      autoPrint: autoPrint ?? this.autoPrint,
      paperSize: paperSize ?? this.paperSize,
      paperWidth: paperWidth ?? this.paperWidth,
      fontSize: fontSize ?? this.fontSize,
      thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headerText': headerText,
      'footerText': footerText,
      'showLogo': showLogo,
      'showDateTime': showDateTime,
      'showOrderNumber': showOrderNumber,
      'showCashierName': showCashierName,
      'showTaxBreakdown': showTaxBreakdown,
  'showServiceChargeBreakdown': showServiceChargeBreakdown,
      'showThankYouMessage': showThankYouMessage,
      'autoPrint': autoPrint,
      'paperSize': paperSize.name,
      'paperWidth': paperWidth,
      'fontSize': fontSize,
      'thankYouMessage': thankYouMessage,
      'termsAndConditions': termsAndConditions,
    };
  }

  factory ReceiptSettings.fromJson(Map<String, dynamic> json) {
    return ReceiptSettings(
      headerText: json['headerText'] as String? ?? 'ExtroPOS',
      footerText: json['footerText'] as String? ?? 'Thank you for your business!',
      showLogo: json['showLogo'] as bool? ?? true,
      showDateTime: json['showDateTime'] as bool? ?? true,
      showOrderNumber: json['showOrderNumber'] as bool? ?? true,
      showCashierName: json['showCashierName'] as bool? ?? true,
      showTaxBreakdown: json['showTaxBreakdown'] as bool? ?? true,
      showServiceChargeBreakdown: json['showServiceChargeBreakdown'] as bool? ?? true,
      showThankYouMessage: json['showThankYouMessage'] as bool? ?? true,
      autoPrint: json['autoPrint'] as bool? ?? false,
      paperSize: ReceiptPaperSize.values.firstWhere(
        (e) => e.name == json['paperSize'],
        orElse: () => ReceiptPaperSize.mm80,
      ),
      paperWidth: json['paperWidth'] as int? ?? 80,
      fontSize: json['fontSize'] as int? ?? 12,
      thankYouMessage: json['thankYouMessage'] as String? ?? 'Thank you! Please come again.',
      termsAndConditions: json['termsAndConditions'] as String? ?? '',
    );
  }
}

enum ReceiptPaperSize {
  mm58,
  mm80,
  a4,
}

extension ReceiptPaperSizeExtension on ReceiptPaperSize {
  String get displayName {
    switch (this) {
      case ReceiptPaperSize.mm58:
        return '58mm (Small)';
      case ReceiptPaperSize.mm80:
        return '80mm (Standard)';
      case ReceiptPaperSize.a4:
        return 'A4 (Letter)';
    }
  }

  int get widthInMm {
    switch (this) {
      case ReceiptPaperSize.mm58:
        return 58;
      case ReceiptPaperSize.mm80:
        return 80;
      case ReceiptPaperSize.a4:
        return 210;
    }
  }
}
