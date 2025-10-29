import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:imin_printer/imin_printer.dart';
import 'package:imin_printer/enums.dart' as imin;
import 'package:imin_vice_screen/imin_vice_screen.dart';
import '../models/printer_model.dart' as app;

/// IMIN-specific printer service that isolates IMIN functionality
/// from the generic Android printer implementation
class IminPrinterService {
  static final IminPrinterService _instance = IminPrinterService._internal();
  factory IminPrinterService() => _instance;
  IminPrinterService._internal();

  IminPrinter? _iminPrinter;
  IminViceScreen? _iminViceScreen;
  bool _isInitialized = false;

  /// Initialize IMIN printer service
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      _iminPrinter = IminPrinter();
      _iminViceScreen = IminViceScreen();

      // Add timeout to prevent hanging on non-IMIN devices
      await _iminPrinter!.initPrinter().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('IMIN printer initialization timeout');
        },
      );
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  /// Check if IMIN printer is available
  Future<bool> isIminPrinterAvailable() async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.getPrinterStatus();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get IMIN printer status
  Future<app.PrinterStatus?> getPrinterStatus() async {
    if (!Platform.isAndroid || !_isInitialized) return null;
    try {
      final status = await _iminPrinter!.getPrinterStatus();
      return _mapIminStatusToPrinterStatus(status);
    } catch (_) {
      return null;
    }
  }

  /// Print receipt using IMIN printer
  Future<bool> printReceipt(String content) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      final lines = content.split('\n');
      for (final line in lines) {
        await _iminPrinter!.printText(line);
        await _iminPrinter!.printAndLineFeed();
      }
      await _iminPrinter!.partialCut();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> printAndFeed() async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.printAndLineFeed();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cutPaper() async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.partialCut();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Print text with formatting options
  Future<bool> printTextWithFormat(
    String text, {
    imin.IminPrintAlign alignment = imin.IminPrintAlign.left,
    imin.IminFontStyle style = imin.IminFontStyle.normal,
    int size = 1,
  }) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      debugPrint('IMIN: Setting alignment to $alignment');
      await setAlignment(alignment);
      debugPrint('IMIN: Setting style to $style');
      await setTextStyle(style);
      debugPrint('IMIN: Setting size to $size');
      await setTextSize(size);
      debugPrint('IMIN: Printing text: "$text"');
      await _iminPrinter!.printText(text);
      await _iminPrinter!.printAndLineFeed();
      return true;
    } catch (e) {
      debugPrint('IMIN: Error printing text: $e');
      return false;
    }
  }

  Future<bool> setAlignment(imin.IminPrintAlign alignment) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.setAlignment(alignment);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setTextSize(int size) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.setTextSize(size);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setTextStyle(imin.IminFontStyle style) async {
    if (!Platform.isAndroid || !_isInitialized) return false;
    try {
      await _iminPrinter!.setTextStyle(style);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDualDisplaySupported() async {
    if (!Platform.isAndroid) return false;
    try {
      _iminViceScreen ??= IminViceScreen();
      return await _iminViceScreen!.isSupportMultipleScreen() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendTextToCustomerDisplay(String text) async {
    if (!Platform.isAndroid) return false;
    try {
      _iminViceScreen ??= IminViceScreen();
      await _iminViceScreen!.doubleScreenOpen();
      await _iminViceScreen!.sendMsgToViceScreen(
        'text',
        params: {'data': text},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearCustomerDisplay() async {
    if (!Platform.isAndroid) return false;
    try {
      _iminViceScreen ??= IminViceScreen();
      // Fallback clear: send empty text payload to overwrite screen
      await _iminViceScreen!.doubleScreenOpen();
      await _iminViceScreen!.sendMsgToViceScreen('text', params: {'data': ''});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> showWelcomeOnCustomerDisplay(String businessName) async {
    if (!Platform.isAndroid) return false;
    try {
      final text = 'Welcome to\n$businessName';
      return await sendTextToCustomerDisplay(text);
    } catch (_) {
      return false;
    }
  }

  Future<bool> showOrderTotalOnCustomerDisplay(
    double total,
    String currency,
  ) async {
    if (!Platform.isAndroid) return false;
    try {
      final text = 'Total:\n$currency ${total.toStringAsFixed(2)}';
      return await sendTextToCustomerDisplay(text);
    } catch (_) {
      return false;
    }
  }

  Future<bool> showPaymentAmountOnCustomerDisplay(
    double amount,
    String currency,
  ) async {
    if (!Platform.isAndroid) return false;
    try {
      final text = 'Payment:\n$currency ${amount.toStringAsFixed(2)}';
      return await sendTextToCustomerDisplay(text);
    } catch (_) {
      return false;
    }
  }

  Future<bool> showChangeOnCustomerDisplay(
    double change,
    String currency,
  ) async {
    if (!Platform.isAndroid) return false;
    try {
      final text = 'Change:\n$currency ${change.toStringAsFixed(2)}';
      return await sendTextToCustomerDisplay(text);
    } catch (_) {
      return false;
    }
  }

  Future<bool> showThankYouOnCustomerDisplay() async {
    if (!Platform.isAndroid) return false;
    try {
      const text = 'Thank You!\nPlease Come Again';
      return await sendTextToCustomerDisplay(text);
    } catch (_) {
      return false;
    }
  }

  app.PrinterStatus _mapIminStatusToPrinterStatus(dynamic _) {
    // Basic mapping fallback
    return app.PrinterStatus.online;
  }

  void dispose() {
    _isInitialized = false;
  }
}

/*
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:imin_printer/imin_printer.dart';
import 'package:imin_printer/enums.dart' as imin;
import 'package:imin_vice_screen/imin_vice_screen.dart';
import '../models/printer_model.dart';

/// IMIN-specific printer service that isolates IMIN functionality
/// from the generic Android printer implementation
class IminPrinterService {
  static final IminPrinterService _instance = IminPrinterService._internal();
  factory IminPrinterService() => _instance;
  IminPrinterService._internal();

  IminPrinter? _iminPrinter;
  IminViceScreen? _iminViceScreen;
  bool _isInitialized = false;

  /// Initialize IMIN printer service
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      _iminPrinter = IminPrinter();
      _iminViceScreen = IminViceScreen();
      await _iminPrinter!.initPrinter();
      _isInitialized = true;
      debugPrint('IMIN Printer initialized successfully');
    } catch (e) {
      debugPrint('IMIN Printer initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Check if IMIN printer is available
  Future<bool> isIminPrinterAvailable() async {
    if (!Platform.isAndroid || !_isInitialized) return false;

    try {
      final result = await _iminPrinter.getPrinterStatus();
      final result = await _iminPrinter!.getPrinterStatus();
    } catch (e) {
      debugPrint('Error checking IMIN printer status: $e');
      return false;
    }
  }

  /// Get IMIN printer status
  Future<PrinterStatus?> getPrinterStatus() async {
    if (!Platform.isAndroid || !_isInitialized) return null;

    import 'dart:io';
    import 'package:imin_printer/imin_printer.dart';
    import 'package:imin_printer/enums.dart' as imin;
    import 'package:imin_vice_screen/imin_vice_screen.dart';
    import '../models/printer_model.dart' as app;

    /// IMIN-specific printer service that isolates IMIN functionality
    /// from the generic Android printer implementation
    class IminPrinterService {
      static final IminPrinterService _instance = IminPrinterService._internal();
      factory IminPrinterService() => _instance;
      IminPrinterService._internal();

      IminPrinter? _iminPrinter;
      IminViceScreen? _iminViceScreen;
      bool _isInitialized = false;

      /// Initialize IMIN printer service
      Future<void> initialize() async {
        if (!Platform.isAndroid) return;

        try {
          _iminPrinter = IminPrinter();
          _iminViceScreen = IminViceScreen();
          await _iminPrinter!.initPrinter();
          _isInitialized = true;
        } catch (e) {
          _isInitialized = false;
        }
      }

      /// Check if IMIN printer is available
      Future<bool> isIminPrinterAvailable() async {
        if (!Platform.isAndroid || !_isInitialized) return false;

        try {
          await _iminPrinter!.getPrinterStatus();
          return true;
        } catch (_) {
          return false;
        }
      }

      /// Get IMIN printer status
      Future<app.PrinterStatus?> getPrinterStatus() async {
        if (!Platform.isAndroid || !_isInitialized) return null;

        try {
          final status = await _iminPrinter!.getPrinterStatus();
          return _mapIminStatusToPrinterStatus(status);
        } catch (_) {
          return null;
        }
      }

      /// Print receipt using IMIN printer
      Future<bool> printReceipt(String content) async {
        if (!Platform.isAndroid || !_isInitialized) return false;

        try {
          final lines = content.split('\n');
          for (final line in lines) {
            await _iminPrinter!.printText(line);
            await _iminPrinter!.printAndLineFeed();
          }
          await _iminPrinter!.partialCut();
          return true;
        } catch (_) {
          return false;
        }
      }

      Future<bool> printAndFeed() async {
        if (!Platform.isAndroid || !_isInitialized) return false;
        try {
          await _iminPrinter!.printAndLineFeed();
          return true;
        } catch (_) {
          return false;
        }
      }

      Future<bool> cutPaper() async {
        if (!Platform.isAndroid || !_isInitialized) return false;
        try {
          await _iminPrinter!.partialCut();
          return true;
        } catch (_) {
          return false;
        }
      }

      Future<bool> setAlignment(imin.IminPrintAlign alignment) async {
        if (!Platform.isAndroid || !_isInitialized) return false;
        try {
          await _iminPrinter!.setAlignment(alignment);
          return true;
        } catch (_) {
          return false;
        }
      }

      Future<bool> setTextSize(int size) async {
        if (!Platform.isAndroid || !_isInitialized) return false;
        try {
          await _iminPrinter!.setTextSize(size);
          return true;
        } catch (_) {
          return false;
        }
      }

      Future<bool> setTextStyle(imin.IminFontStyle style) async {
        if (!Platform.isAndroid || !_isInitialized) return false;
        try {
          await _iminPrinter!.setTextStyle(style);
          return true;
        } catch (_) {
          return false;
        }
      }

      Future<bool> isDualDisplaySupported() async {
        if (!Platform.isAndroid) return false;
        try {
          _iminViceScreen ??= IminViceScreen();
          return await _iminViceScreen!.isSupportMultipleScreen() ?? false;
        } catch (_) {
          return false;
        }
      }

      Future<bool> sendTextToCustomerDisplay(String text) async {
        if (!Platform.isAndroid) return false;
        try {
          _iminViceScreen ??= IminViceScreen();
          await _iminViceScreen!.doubleScreenOpen();
          await _iminViceScreen!.sendMsgToViceScreen('text', params: {'data': text});
          return true;
        } catch (_) {
          return false;
        }
      }

      Future<bool> clearCustomerDisplay() async {
        if (!Platform.isAndroid) return false;
        try {
          _iminViceScreen ??= IminViceScreen();
          await _iminViceScreen!.sendLCDCommand(LCDCommand.cleanScreenLCD);
          return true;
        } catch (_) {
          return false;
        }
      }

      Future<bool> showWelcomeOnCustomerDisplay(String businessName) async {
        if (!Platform.isAndroid) return false;
        try {
          final text = 'Welcome to\n$businessName';
          return await sendTextToCustomerDisplay(text);
        } catch (_) {
          return false;
        }
      }

      Future<bool> showOrderTotalOnCustomerDisplay(double total, String currency) async {
        if (!Platform.isAndroid) return false;
        try {
          final text = 'Total:\n$currency${total.toStringAsFixed(2)}';
          return await sendTextToCustomerDisplay(text);
        } catch (_) {
          return false;
        }
      }

      Future<bool> showPaymentAmountOnCustomerDisplay(double amount, String currency) async {
        if (!Platform.isAndroid) return false;
        try {
          final text = 'Payment:\n$currency${amount.toStringAsFixed(2)}';
          return await sendTextToCustomerDisplay(text);
        } catch (_) {
          return false;
        }
      }

      Future<bool> showChangeOnCustomerDisplay(double change, String currency) async {
        if (!Platform.isAndroid) return false;
        try {
          final text = 'Change:\n$currency${change.toStringAsFixed(2)}';
          return await sendTextToCustomerDisplay(text);
        } catch (_) {
          return false;
        }
      }

      Future<bool> showThankYouOnCustomerDisplay() async {
        if (!Platform.isAndroid) return false;
        try {
          const text = 'Thank You!\nPlease Come Again';
          return await sendTextToCustomerDisplay(text);
        } catch (_) {
          return false;
        }
      }

      app.PrinterStatus _mapIminStatusToPrinterStatus(dynamic _) {
        // Basic mapping fallback
        return app.PrinterStatus.online;
      }

      void dispose() {
        _isInitialized = false;
      }
  }
  // This would need to be implemented based on IMIN SDK status codes
*/
