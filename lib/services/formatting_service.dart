import '../models/business_info_model.dart';

class FormattingService {
  FormattingService._();

  static String currency(num value) {
    final info = BusinessInfo.instance;
    return '${info.currencySymbol} ${value.toStringAsFixed(2)}';
  }
}
