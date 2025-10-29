import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/printer_model.dart';
import 'database_service.dart';
import 'imin_printer_service.dart';

class PrinterService {
  static const MethodChannel _channel = MethodChannel(
    'com.extrotarget.extropos/printer',
  );

  // Singleton pattern
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // Stream for printer status updates
  final StreamController<Printer> _printerStatusController =
      StreamController<Printer>.broadcast();
  Stream<Printer> get printerStatusStream => _printerStatusController.stream;

  // Stream for native plugin log messages (forwarded from platform)
  final StreamController<String> _printerLogController =
      StreamController<String>.broadcast();
  Stream<String> get printerLogStream => _printerLogController.stream;
  bool _printerLogEnabled = true;

  /// Enable or disable adding native plugin logs to [printerLogStream].
  /// This persists the choice to shared preferences.
  Future<void> setPrinterLogEnabled(bool enabled) async {
    _printerLogEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('printer_log_enabled', enabled);
    } catch (e) {
      // ignore persistence errors
    }
  }

  /// Returns whether native plugin logs will be forwarded to listeners.
  bool get isPrinterLogEnabled => _printerLogEnabled;

  // Initialize platform channels
  Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isWindows) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
    // Load persisted printer log enabled flag
    try {
      final prefs = await SharedPreferences.getInstance();
      _printerLogEnabled =
          prefs.getBool('printer_log_enabled') ?? _printerLogEnabled;
    } catch (e) {
      // ignore
    }
  }

  // Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'printerStatusChanged':
        final printerData = call.arguments as Map<dynamic, dynamic>;
        final printer = _parsePrinterFromPlatform(printerData);
        _printerStatusController.add(printer);
        break;
      case 'printerLog':
        try {
          if (!_printerLogEnabled) {
            break;
          }
          final args = call.arguments as Map<dynamic, dynamic>?;
          final message = args != null && args['message'] != null
              ? args['message'].toString()
              : call.arguments.toString();
          _printerLogController.add(message);
        } catch (e) {
          // ignore parse errors
        }
        break;
      default:
        throw MissingPluginException('Method ${call.method} not implemented');
    }
  }

  // Discover available printers
  Future<List<Printer>> discoverPrinters() async {
    try {
      final List<Printer> allPrinters = [];

      // 1. Get saved printers from database (includes network printers!)
      final savedPrinters = await DatabaseService.instance.getPrinters();
      allPrinters.addAll(savedPrinters);

      // 2. Check for IMIN printer (Android only)
      if (Platform.isAndroid) {
        try {
          await IminPrinterService().initialize();
          final isIminAvailable = await IminPrinterService()
              .isIminPrinterAvailable();
          if (isIminAvailable) {
            final iminPrinter = Printer(
              id: 'imin_printer',
              name: 'IMIN Thermal Printer',
              type: PrinterType.receipt,
              connectionType:
                  PrinterConnectionType.usb, // IMIN is typically USB
              paperSize: ThermalPaperSize.mm80,
              ipAddress: null,
              port: null,
              usbDeviceId: null,
              bluetoothAddress: null,
              modelName: 'IMIN',
            );
            allPrinters.add(iminPrinter);
          }
        } catch (e) {
          // IMIN not available or failed to initialize, continue without it
          developer.log('IMIN printer detection failed: $e');
        }
      }

      // 3. Discover USB/Bluetooth printers from native platform
      if (Platform.isAndroid || Platform.isWindows) {
        final result = await _channel.invokeMethod('discoverPrinters');
        final discoveredPrinters = _parsePrintersList(result);

        // Add discovered printers that aren't already saved
        for (final discovered in discoveredPrinters) {
          if (!allPrinters.any((p) => p.id == discovered.id)) {
            allPrinters.add(discovered);
          }
        }
      }

      return allPrinters;
    } catch (e) {
      // On error, try to return at least the saved printers
      try {
        return await DatabaseService.instance.getPrinters();
      } catch (_) {
        return [];
      }
    }
  }

  // Print receipt
  Future<bool> printReceipt(
    Printer printer,
    Map<String, dynamic> receiptData,
  ) async {
    // Check if this is an IMIN printer
    if (printer.id == 'imin_printer' && Platform.isAndroid) {
      try {
        final iminService = IminPrinterService();
        await iminService.initialize();

        final content = receiptData['content'] as String? ?? '';
        final success = await iminService.printReceipt(content);

        if (_printerLogEnabled) {
          _printerLogController.add(
            'IMIN printReceipt: ${success ? 'success' : 'failed'}',
          );
        }

        return success;
      } catch (e) {
        if (_printerLogEnabled) {
          _printerLogController.add('IMIN printReceipt error: $e');
        }
        return false;
      }
    }

    // Use regular printing for non-IMIN printers
    try {
      final printData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': _getConnectionDetails(printer),
        'paperSize': printer.paperSize?.name,
        'receiptData': receiptData,
      };

      final result = await _channel.invokeMethod('printReceipt', printData);
      return result as bool;
    } catch (e) {
      // Error printing receipt - surface details to the printer log stream for debugging
      try {
        final msg = e is PlatformException
            ? '${e.code}: ${e.message}'
            : e.toString();
        if (_printerLogEnabled) {
          _printerLogController.add('printReceipt error: $msg');
        }
      } catch (_) {}
      return false;
    }
  }

  // Print order (kitchen/bar)
  Future<bool> printOrder(
    Printer printer,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final printData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': _getConnectionDetails(printer),
        'paperSize': printer.paperSize?.name,
        'orderData': orderData,
      };

      final result = await _channel.invokeMethod('printOrder', printData);
      return result as bool;
    } catch (e) {
      try {
        final msg = e is PlatformException
            ? '${e.code}: ${e.message}'
            : e.toString();
        if (_printerLogEnabled) {
          _printerLogController.add('printOrder error: $msg');
        }
      } catch (_) {}
      return false;
    }
  }

  // Test print
  Future<bool> testPrint(Printer printer) async {
    try {
      final testData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': _getConnectionDetails(printer),
        'paperSize': printer.paperSize?.name,
      };

      final result = await _channel.invokeMethod('testPrint', testData);
      return result as bool;
    } catch (e) {
      try {
        final msg = e is PlatformException
            ? '${e.code}: ${e.message}'
            : e.toString();
        if (_printerLogEnabled) {
          _printerLogController.add('testPrint error: $msg');
        }
      } catch (_) {}
      return false;
    }
  }

  // Print using an external printer service app via Android share intent
  // This does not require a configured Printer; it shares receipt text and lets user pick the service.
  Future<bool> printViaExternalService(
    Map<String, dynamic> receiptData, {
    ThermalPaperSize? paperSize,
  }) async {
    try {
      if (!Platform.isAndroid) return false;
      final args = {'paperSize': paperSize?.name, 'receiptData': receiptData};
      final result = await _channel.invokeMethod(
        'printViaExternalService',
        args,
      );
      return result == true;
    } catch (e) {
      try {
        final msg = e is PlatformException
            ? '${e.code}: ${e.message}'
            : e.toString();
        if (_printerLogEnabled) {
          _printerLogController.add('printViaExternalService error: $msg');
        }
      } catch (_) {}
      return false;
    }
  }

  // Request USB permission for a USB printer (returns true if granted)
  Future<bool> requestUsbPermission(Printer printer) async {
    try {
      if (printer.connectionType != PrinterConnectionType.usb) {
        return false;
      }
      final args = {
        'usbDeviceId': printer.usbDeviceId,
        'platformSpecificId': printer.platformSpecificId,
      };
      final result = await _channel.invokeMethod('requestUsbPermission', args);
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check printer status
  Future<PrinterStatus> checkPrinterStatus(Printer printer) async {
    try {
      final statusData = {
        'printerId': printer.id,
        'printerType': printer.connectionType.name,
        'connectionDetails': _getConnectionDetails(printer),
      };

      final result = await _channel.invokeMethod(
        'checkPrinterStatus',
        statusData,
      );
      return _parsePrinterStatus(result);
    } catch (e) {
      // Error checking printer status
      return PrinterStatus.error;
    }
  }

  // Helper methods
  Map<String, dynamic> _getConnectionDetails(Printer printer) {
    switch (printer.connectionType) {
      case PrinterConnectionType.network:
        return {'ipAddress': printer.ipAddress, 'port': printer.port};
      case PrinterConnectionType.usb:
        return {
          'usbDeviceId': printer.usbDeviceId,
          'platformSpecificId': printer.platformSpecificId,
        };
      case PrinterConnectionType.bluetooth:
        return {
          'bluetoothAddress': printer.bluetoothAddress,
          'platformSpecificId': printer.platformSpecificId,
        };
    }
  }

  List<Printer> _parsePrintersList(dynamic result) {
    if (result == null) {
      return [];
    }

    final List<dynamic> printersData = result as List<dynamic>;
    return printersData.map((data) => _parsePrinterFromPlatform(data)).toList();
  }

  Printer _parsePrinterFromPlatform(dynamic data) {
    final Map<String, dynamic> printerData = data as Map<String, dynamic>;

    final connectionType = _parseConnectionType(
      printerData['connectionType'] as String,
    );

    switch (connectionType) {
      case PrinterConnectionType.network:
        return Printer.network(
          id: printerData['id'] as String,
          name: printerData['name'] as String,
          type: _parsePrinterType(printerData['printerType'] as String),
          ipAddress: printerData['ipAddress'] as String,
          port: printerData['port'] as int? ?? 9100,
          status: _parsePrinterStatus(printerData['status'] as String),
          modelName: printerData['modelName'] as String?,
          paperSize: _parsePaperSize(printerData['paperSize'] as String?),
        );
      case PrinterConnectionType.usb:
        return Printer.usb(
          id: printerData['id'] as String,
          name: printerData['name'] as String,
          type: _parsePrinterType(printerData['printerType'] as String),
          usbDeviceId: printerData['usbDeviceId'] as String,
          platformSpecificId: printerData['platformSpecificId'] as String?,
          status: _parsePrinterStatus(printerData['status'] as String),
          modelName: printerData['modelName'] as String?,
          paperSize: _parsePaperSize(printerData['paperSize'] as String?),
        );
      case PrinterConnectionType.bluetooth:
        return Printer.bluetooth(
          id: printerData['id'] as String,
          name: printerData['name'] as String,
          type: _parsePrinterType(printerData['printerType'] as String),
          bluetoothAddress: printerData['bluetoothAddress'] as String,
          platformSpecificId: printerData['platformSpecificId'] as String?,
          status: _parsePrinterStatus(printerData['status'] as String),
          modelName: printerData['modelName'] as String?,
          paperSize: _parsePaperSize(printerData['paperSize'] as String?),
        );
    }
  }

  ThermalPaperSize? _parsePaperSize(String? s) {
    if (s == null) {
      return null;
    }
    switch (s.toLowerCase()) {
      case 'mm58':
      case '58':
        return ThermalPaperSize.mm58;
      case 'mm80':
      case '80':
        return ThermalPaperSize.mm80;
      default:
        return null;
    }
  }

  PrinterConnectionType _parseConnectionType(String type) {
    switch (type.toLowerCase()) {
      case 'network':
        return PrinterConnectionType.network;
      case 'usb':
        return PrinterConnectionType.usb;
      case 'bluetooth':
        return PrinterConnectionType.bluetooth;
      default:
        return PrinterConnectionType.network;
    }
  }

  PrinterType _parsePrinterType(String type) {
    switch (type.toLowerCase()) {
      case 'receipt':
        return PrinterType.receipt;
      case 'kitchen':
        return PrinterType.kitchen;
      case 'bar':
        return PrinterType.bar;
      default:
        return PrinterType.receipt;
    }
  }

  PrinterStatus _parsePrinterStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'online':
          return PrinterStatus.online;
        case 'offline':
          return PrinterStatus.offline;
        case 'error':
          return PrinterStatus.error;
        default:
          return PrinterStatus.offline;
      }
    }
    return PrinterStatus.offline;
  }

  // Cleanup
  void dispose() {
    _printerStatusController.close();
    _printerLogController.close();
  }
}
