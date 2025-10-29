import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_info_model.dart';
import 'imin_printer_service.dart';

/// Service for managing dual display (customer display) functionality
class DualDisplayService {
  static final DualDisplayService _instance = DualDisplayService._internal();
  factory DualDisplayService() => _instance;
  DualDisplayService._internal();

  IminPrinterService? _iminService;
  bool _isSupported = false;
  bool _isEnabled = false;
  bool _showWelcomeMessage = true;
  bool _showOrderTotal = true;
  bool _showPaymentAmount = true;
  bool _showChangeAmount = true;
  bool _showThankYouMessage = true;

  /// Initialize the dual display service
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      _iminService = IminPrinterService();
      await _iminService!.initialize();
      _isSupported = await _iminService!.isDualDisplaySupported();
      if (_isSupported) await _loadSettings();
    } catch (e) {
      // Silent fail to avoid noisy logs in production
    }
  }

  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('dual_display_enabled') ?? false;
      _showWelcomeMessage = prefs.getBool('dual_display_show_welcome') ?? true;
      _showOrderTotal = prefs.getBool('dual_display_show_total') ?? true;
      _showPaymentAmount = prefs.getBool('dual_display_show_payment') ?? true;
      _showChangeAmount = prefs.getBool('dual_display_show_change') ?? true;
      _showThankYouMessage =
          prefs.getBool('dual_display_show_thank_you') ?? true;
    } catch (e) {
      // Use defaults
    }
  }

  /// Check if dual display is available and enabled
  bool get isAvailable => _iminService != null && _isSupported && _isEnabled;

  /// Show welcome message on customer display
  Future<void> showWelcome() async {
    if (!isAvailable || !_showWelcomeMessage) return;

    final businessName = BusinessInfo.instance.businessName;
    await _iminService!.showWelcomeOnCustomerDisplay(businessName);
  }

  /// Show order total on customer display
  Future<void> showOrderTotal(double total, String currency) async {
    if (!isAvailable || !_showOrderTotal) return;
    await _iminService!.showOrderTotalOnCustomerDisplay(
      total,
      (currency.isEmpty) ? BusinessInfo.instance.currencySymbol : currency,
    );
  }

  /// Show payment amount on customer display
  Future<void> showPaymentAmount(double amount, String currency) async {
    if (!isAvailable || !_showPaymentAmount) return;
    await _iminService!.showPaymentAmountOnCustomerDisplay(
      amount,
      (currency.isEmpty) ? BusinessInfo.instance.currencySymbol : currency,
    );
  }

  /// Show change amount on customer display
  Future<void> showChange(double change, String currency) async {
    if (!isAvailable || !_showChangeAmount) return;
    if (change <= 0) return;
    await _iminService!.showChangeOnCustomerDisplay(
      change,
      (currency.isEmpty) ? BusinessInfo.instance.currencySymbol : currency,
    );
  }

  /// Show thank you message on customer display
  Future<void> showThankYou() async {
    if (!isAvailable || !_showThankYouMessage) return;

    await _iminService!.showThankYouOnCustomerDisplay();
  }

  /// Clear the customer display
  Future<void> clear() async {
    if (!isAvailable) return;

    await _iminService!.clearCustomerDisplay();
  }

  /// Show custom text on customer display
  Future<void> showText(String text) async {
    if (!isAvailable) return;

    await _iminService!.sendTextToCustomerDisplay(text);
  }
}
