import 'package:flutter/material.dart';
import '../models/printer_model.dart';
import '../services/printer_service.dart';
import '../services/database_service.dart';
import 'printer_debug_console.dart';

/// Simple printers management screen.
///
/// Allows adding/editing/deleting printers and includes a "Grant USB Permission"
/// action which calls into [PrinterService.requestUsbPermission].
class PrintersManagementScreen extends StatefulWidget {
  const PrintersManagementScreen({super.key});

  @override
  State<PrintersManagementScreen> createState() =>
      _PrintersManagementScreenState();
}

class _PrintersManagementScreenState extends State<PrintersManagementScreen> {
  List<Printer> printers = [];
  final PrinterService _printerService = PrinterService();

  @override
  void initState() {
    super.initState();
    _initializePrinterService();
    _loadPrinters();
  }

  Future<void> _initializePrinterService() async {
    await _printerService.initialize();
  }

  Future<void> _printViaExternalServiceTest() async {
    final now = DateTime.now();
    final receipt = {
      'title': 'TEST PRINT',
      'content':
          'This is a test receipt from FlutterPOS.\n\nItems:\nSample Item x 1 RM 1.00\n\nSubtotal: RM 1.00\nTotal: RM 1.00',
      'timestamp': now.toString(),
    };
    final ok = await _printerService.printViaExternalService(
      receipt,
      paperSize: ThermalPaperSize.mm80,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Opened ESCPrint Service (or chooser) for external print'
              : 'Failed to open external print service',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _loadPrinters() async {
    try {
      // Load saved printers from database first
      final savedPrinters = await DatabaseService.instance.getPrinters();
      printers = savedPrinters;

      // Then discover additional USB/Bluetooth printers
      final discoveredPrinters = await _printerService.discoverPrinters();
      if (!mounted) return;
      setState(() {
        for (final discovered in discoveredPrinters) {
          if (!printers.any(
            (p) => p.platformSpecificId == discovered.platformSpecificId,
          )) {
            printers.add(discovered);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error discovering printers: $e')));
    }
  }

  void _addPrinter() {
    showDialog(
      context: context,
      builder: (context) => _PrinterFormDialog(
        onSave: (printer) async {
          // Save to database
          await DatabaseService.instance.savePrinter(printer);
          if (!mounted) return;
          setState(() => printers.add(printer));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Printer saved')));
          }
        },
      ),
    );
  }

  void _editPrinter(Printer printer) {
    showDialog(
      context: context,
      builder: (context) => _PrinterFormDialog(
        printer: printer,
        onSave: (updatedPrinter) async {
          // Save to database
          await DatabaseService.instance.savePrinter(updatedPrinter);
          if (!mounted) return;
          setState(() {
            final index = printers.indexWhere((p) => p.id == updatedPrinter.id);
            if (index != -1) printers[index] = updatedPrinter;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Printer updated')));
          }
        },
      ),
    );
  }

  void _deletePrinter(Printer printer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Printer'),
        content: Text('Are you sure you want to delete "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete from database
              await DatabaseService.instance.deletePrinter(printer.id);
              if (!mounted) return;
              setState(() => printers.removeWhere((p) => p.id == printer.id));
              if (!context.mounted) return;
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Printer deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _testPrint(Printer printer) async {
    try {
      final success = await _printerService.testPrint(printer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Test print sent to ${printer.name}'
                : 'Failed to print test to ${printer.name}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error testing printer: $e')));
    }
  }

  Future<void> _grantUsbPermission(Printer printer) async {
    // Show a blocking progress dialog while we wait for the native permission flow.
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        // Suppress deprecation warning for WillPopScope until PopScope adoption across the app.
        // ignore: deprecated_member_use
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: const [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Requesting USB permission...')),
              ],
            ),
          ),
        ),
      );

      final ok = await _printerService.requestUsbPermission(printer);

      if (mounted) Navigator.of(context).pop(); // close progress dialog

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'USB permission granted for ${printer.name}'
                : 'USB permission not granted',
          ),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting USB permission: $e')),
      );
    }
  }

  void _toggleDefault(Printer printer) {
    setState(() {
      for (var p in printers) {
        if (p.type == printer.type && p.id != printer.id) p.isDefault = false;
      }
      printer.isDefault = !printer.isDefault;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printers Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Print via ESCPrint Service',
            icon: const Icon(Icons.outgoing_mail),
            onPressed: _printViaExternalServiceTest,
          ),
          IconButton(
            tooltip: 'Open debug console',
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrinterDebugConsole()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: printers.length,
        itemBuilder: (context, index) {
          final printer = printers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: printer.status == PrinterStatus.online
                      ? Colors.green.withAlpha(26)
                      : printer.status == PrinterStatus.offline
                      ? Colors.grey.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.print,
                  color: printer.status == PrinterStatus.online
                      ? Colors.green
                      : printer.status == PrinterStatus.offline
                      ? Colors.grey
                      : Colors.red,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    printer.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (printer.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(printer.typeDisplayName),
                  if (printer.connectionType == PrinterConnectionType.network)
                    Text('${printer.ipAddress}:${printer.port}'),
                  if (printer.modelName != null) Text(printer.modelName!),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: printer.status == PrinterStatus.online
                              ? Colors.green
                              : printer.status == PrinterStatus.offline
                              ? Colors.grey
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(printer.statusDisplayName),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editPrinter(printer);
                      break;
                    case 'test':
                      _testPrint(printer);
                      break;
                    case 'grant':
                      _grantUsbPermission(printer);
                      break;
                    case 'default':
                      _toggleDefault(printer);
                      break;
                    case 'delete':
                      _deletePrinter(printer);
                      break;
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'test',
                    child: Row(
                      children: [
                        Icon(Icons.print, size: 20),
                        SizedBox(width: 8),
                        Text('Test Print'),
                      ],
                    ),
                  ),
                  if (printer.connectionType == PrinterConnectionType.usb)
                    PopupMenuItem(
                      value: 'grant',
                      child: Row(
                        children: const [
                          Icon(Icons.usb, size: 20),
                          SizedBox(width: 8),
                          Text('Grant USB Permission'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(
                          printer.isDefault ? Icons.star : Icons.star_border,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          printer.isDefault
                              ? 'Remove Default'
                              : 'Set as Default',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPrinter,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add),
        label: const Text('Add Printer'),
      ),
    );
  }
}

class _PrinterFormDialog extends StatefulWidget {
  final Printer? printer;
  final Function(Printer) onSave;

  const _PrinterFormDialog({this.printer, required this.onSave});

  @override
  State<_PrinterFormDialog> createState() => _PrinterFormDialogState();
}

class _PrinterFormDialogState extends State<_PrinterFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _usbDeviceIdController;
  late TextEditingController _bluetoothAddressController;
  late TextEditingController _modelController;
  late PrinterType _selectedType;
  late PrinterConnectionType _selectedConnectionType;
  ThermalPaperSize? _selectedPaperSize;
  final PrinterService _printerService = PrinterService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.printer?.name ?? '');
    _ipController = TextEditingController(
      text: widget.printer?.ipAddress ?? '192.168.1.',
    );
    _portController = TextEditingController(
      text: widget.printer?.port?.toString() ?? '9100',
    );
    _usbDeviceIdController = TextEditingController(
      text: widget.printer?.usbDeviceId ?? '',
    );
    _bluetoothAddressController = TextEditingController(
      text: widget.printer?.bluetoothAddress ?? '',
    );
    _modelController = TextEditingController(
      text: widget.printer?.modelName ?? '',
    );
    _selectedType = widget.printer?.type ?? PrinterType.receipt;
    _selectedConnectionType =
        widget.printer?.connectionType ?? PrinterConnectionType.network;
    _selectedPaperSize = widget.printer?.paperSize ?? ThermalPaperSize.mm80;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _usbDeviceIdController.dispose();
    _bluetoothAddressController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _scanUsbDevices() async {
    try {
      // Enable printer logging to see what's happening
      await _printerService.setPrinterLogEnabled(true);

      final printers = await _printerService.discoverPrinters();
      final usbPrinters = printers
          .where((p) => p.connectionType == PrinterConnectionType.usb)
          .toList();

      if (!mounted) return;

      if (usbPrinters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No USB printers found. Check Printer Debug Console for details. Make sure:\n• Printer is connected via USB\n• USB debugging is enabled\n• App has USB permissions',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // Show dialog to select from found USB devices
      final selected = await showDialog<Printer>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select USB Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: usbPrinters.length,
              itemBuilder: (context, index) {
                final printer = usbPrinters[index];
                return ListTile(
                  title: Text(printer.name),
                  subtitle: Text(
                    'Device ID: ${printer.usbDeviceId}\nModel: ${printer.modelName ?? 'Unknown'}',
                  ),
                  onTap: () => Navigator.pop(context, printer),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selected != null && mounted) {
        setState(() {
          _usbDeviceIdController.text = selected.usbDeviceId ?? '';
          _nameController.text = selected.name;
          if (selected.modelName != null) {
            _modelController.text = selected.modelName!;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning USB devices: $e')));
    }
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a printer name')),
      );
      return;
    }

    // Validate connection-specific fields
    switch (_selectedConnectionType) {
      case PrinterConnectionType.network:
        if (_ipController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter an IP address')),
          );
          return;
        }
        break;
      case PrinterConnectionType.usb:
        if (_usbDeviceIdController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a USB device ID')),
          );
          return;
        }
        break;
      case PrinterConnectionType.bluetooth:
        if (_bluetoothAddressController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a Bluetooth address')),
          );
          return;
        }
        break;
    }

    final Printer printer;
    switch (_selectedConnectionType) {
      case PrinterConnectionType.network:
        printer = Printer.network(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          ipAddress: _ipController.text,
          port: int.tryParse(_portController.text) ?? 9100,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
        );
        break;
      case PrinterConnectionType.usb:
        printer = Printer.usb(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          usbDeviceId: _usbDeviceIdController.text,
          platformSpecificId: widget.printer?.platformSpecificId,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
        );
        break;
      case PrinterConnectionType.bluetooth:
        printer = Printer.bluetooth(
          id:
              widget.printer?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          type: _selectedType,
          bluetoothAddress: _bluetoothAddressController.text,
          platformSpecificId: widget.printer?.platformSpecificId,
          status: widget.printer?.status ?? PrinterStatus.offline,
          isDefault: widget.printer?.isDefault ?? false,
          modelName: _modelController.text.isEmpty
              ? null
              : _modelController.text,
          paperSize: _selectedPaperSize,
        );
        break;
    }

    widget.onSave(printer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.printer == null ? 'Add Printer' : 'Edit Printer'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Printer Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrinterType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Printer Type *',
                  border: OutlineInputBorder(),
                ),
                items: PrinterType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrinterConnectionType>(
                initialValue: _selectedConnectionType,
                decoration: const InputDecoration(
                  labelText: 'Connection Type *',
                  border: OutlineInputBorder(),
                ),
                items: PrinterConnectionType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedConnectionType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Connection-specific fields
              if (_selectedConnectionType == PrinterConnectionType.network) ...[
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address *',
                    border: OutlineInputBorder(),
                    hintText: '192.168.1.100',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                    hintText: '9100',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ] else if (_selectedConnectionType ==
                  PrinterConnectionType.usb) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _usbDeviceIdController,
                        decoration: const InputDecoration(
                          labelText: 'USB Device ID *',
                          border: OutlineInputBorder(),
                          hintText: 'VID:PID or device path',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _scanUsbDevices,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedConnectionType ==
                  PrinterConnectionType.bluetooth) ...[
                TextField(
                  controller: _bluetoothAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Bluetooth Address *',
                    border: OutlineInputBorder(),
                    hintText: 'AA:BB:CC:DD:EE:FF',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model Name',
                  border: OutlineInputBorder(),
                  hintText: 'Epson TM-T88VI',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ThermalPaperSize>(
                initialValue: _selectedPaperSize,
                decoration: const InputDecoration(
                  labelText: 'Paper Size',
                  border: OutlineInputBorder(),
                ),
                items: ThermalPaperSize.values
                    .map(
                      (ps) => DropdownMenuItem(
                        value: ps,
                        child: Text(
                          ps == ThermalPaperSize.mm58 ? '58 mm' : '80 mm',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedPaperSize = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
