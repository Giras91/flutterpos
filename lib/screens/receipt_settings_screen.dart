// Receipt settings screen
import 'package:flutter/material.dart';
import '../models/receipt_settings_model.dart';
import '../models/business_info_model.dart';
import '../services/formatting_service.dart';
import '../services/database_service.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  late ReceiptSettings _settings;
  bool _isLoading = true;

  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  final _thankYouController = TextEditingController();
  final _termsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    _thankYouController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseService.instance.getReceiptSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _headerController.text = _settings.headerText;
        _footerController.text = _settings.footerText;
        _thankYouController.text = _settings.thankYouMessage;
        _termsController.text = _settings.termsAndConditions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _settings = ReceiptSettings();
        _headerController.text = _settings.headerText;
        _footerController.text = _settings.footerText;
        _thankYouController.text = _settings.thankYouMessage;
        _termsController.text = _settings.termsAndConditions;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading settings: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    final updatedSettings = _settings.copyWith(
      headerText: _headerController.text,
      footerText: _footerController.text,
      thankYouMessage: _thankYouController.text,
      termsAndConditions: _termsController.text,
    );

    try {
      await DatabaseService.instance.saveReceiptSettings(updatedSettings);
      if (!mounted) return;
      setState(() {
        _settings = updatedSettings;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previewReceipt() {
    showDialog(
      context: context,
      builder: (context) => _ReceiptPreviewDialog(settings: _settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Receipt Settings'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _previewReceipt,
            tooltip: 'Preview Receipt',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Paper Size'),
          _buildPaperSizeCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Font Size'),
          _buildFontSizeCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Display Options'),
          _buildDisplayOptionsCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Header Text'),
          _buildTextFieldCard(
            _headerController,
            'Header Text',
            'Enter business name or header',
            Icons.business,
            2,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Footer Text'),
          _buildTextFieldCard(
            _footerController,
            'Footer Text',
            'Enter footer message',
            Icons.text_fields,
            2,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Thank You Message'),
          _buildTextFieldCard(
            _thankYouController,
            'Thank You Message',
            'Enter thank you message',
            Icons.favorite,
            3,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Terms & Conditions'),
          _buildTextFieldCard(
            _termsController,
            'Terms & Conditions',
            'Enter terms and conditions (optional)',
            Icons.description,
            4,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Print Options'),
          _buildPrintOptionsCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildPaperSizeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _PaperSizeTile(
              title: ReceiptPaperSize.mm58.displayName,
              subtitle: '${ReceiptPaperSize.mm58.widthInMm}mm width',
              selected: _settings.paperSize == ReceiptPaperSize.mm58,
              onTap: () {
                setState(() {
                  _settings = _settings.copyWith(
                    paperSize: ReceiptPaperSize.mm58,
                    paperWidth: ReceiptPaperSize.mm58.widthInMm,
                  );
                });
              },
            ),
            _PaperSizeTile(
              title: ReceiptPaperSize.mm80.displayName,
              subtitle: '${ReceiptPaperSize.mm80.widthInMm}mm width',
              selected: _settings.paperSize == ReceiptPaperSize.mm80,
              onTap: () {
                setState(() {
                  _settings = _settings.copyWith(
                    paperSize: ReceiptPaperSize.mm80,
                    paperWidth: ReceiptPaperSize.mm80.widthInMm,
                  );
                });
              },
            ),
            _PaperSizeTile(
              title: ReceiptPaperSize.a4.displayName,
              subtitle: '${ReceiptPaperSize.a4.widthInMm}mm width',
              selected: _settings.paperSize == ReceiptPaperSize.a4,
              onTap: () {
                setState(() {
                  _settings = _settings.copyWith(
                    paperSize: ReceiptPaperSize.a4,
                    paperWidth: ReceiptPaperSize.a4.widthInMm,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _settings.fontSize.toDouble(),
                    min: 8,
                    max: 20,
                    divisions: 12,
                    label: _settings.fontSize.toString(),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(fontSize: value.round());
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${_settings.fontSize}pt',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sample text at ${_settings.fontSize}pt',
              style: TextStyle(fontSize: _settings.fontSize.toDouble()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayOptionsCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Show Logo'),
            subtitle: const Text('Display business logo on receipt'),
            value: _settings.showLogo,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showLogo: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Date & Time'),
            subtitle: const Text('Display transaction timestamp'),
            value: _settings.showDateTime,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showDateTime: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Order Number'),
            subtitle: const Text('Display unique order ID'),
            value: _settings.showOrderNumber,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showOrderNumber: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Cashier Name'),
            subtitle: const Text('Display staff member name'),
            value: _settings.showCashierName,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showCashierName: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Tax Breakdown'),
            subtitle: const Text('Display detailed tax information'),
            value: _settings.showTaxBreakdown,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showTaxBreakdown: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Service Charge Breakdown'),
            subtitle: const Text('Display detailed service charge information'),
            value: _settings.showServiceChargeBreakdown,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showServiceChargeBreakdown: value);
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Show Thank You Message'),
            subtitle: const Text('Display customized thank you text'),
            value: _settings.showThankYouMessage,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showThankYouMessage: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldCard(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    int maxLines,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
          ),
          maxLines: maxLines,
        ),
      ),
    );
  }

  Widget _buildPrintOptionsCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Auto Print'),
            subtitle: const Text('Automatically print receipt after transaction'),
            value: _settings.autoPrint,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(autoPrint: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _previewReceipt,
              icon: const Icon(Icons.preview),
              label: const Text('Preview Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperSizeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaperSizeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : Colors.grey[600];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptPreviewDialog extends StatelessWidget {
  final ReceiptSettings settings;

  const _ReceiptPreviewDialog({required this.settings});

  @override
  Widget build(BuildContext context) {
    final info = BusinessInfo.instance;
    // Sample cart values for preview
    const double sampleSubtotal = 33.50; // 10.00 + 15.00 + 8.50
    final double taxAmount = info.isTaxEnabled ? sampleSubtotal * info.taxRate : 0.0;
    final double serviceChargeAmount = info.isServiceChargeEnabled ? sampleSubtotal * info.serviceChargeRate : 0.0;
    final double totalAmount = sampleSubtotal + taxAmount + serviceChargeAmount;

  String fmt(double v) => FormattingService.currency(v);

    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF2563EB),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Receipt Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    width: settings.paperWidth.toDouble() * 2.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Currency symbol for preview
                          Builder(builder: (context) {
                            return const SizedBox.shrink();
                          }),
                          if (settings.showLogo) ...[
                            Icon(Icons.store, size: settings.fontSize.toDouble() * 3),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            settings.headerText,
                            style: TextStyle(
                              fontSize: settings.fontSize.toDouble() + 4,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (settings.showDateTime)
                            Text(
                              DateTime.now().toString().substring(0, 19),
                              style: TextStyle(fontSize: settings.fontSize.toDouble() - 2),
                            ),
                          if (settings.showOrderNumber) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Order #12345',
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          if (settings.showCashierName) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Cashier: John Doe',
                              style: TextStyle(fontSize: settings.fontSize.toDouble() - 2),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildReceiptLine('Item 1', FormattingService.currency(10.00), settings.fontSize),
                          _buildReceiptLine('Item 2', FormattingService.currency(15.00), settings.fontSize),
                          _buildReceiptLine('Item 3', FormattingService.currency(8.50), settings.fontSize),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildReceiptLine('Subtotal', fmt(sampleSubtotal), settings.fontSize),
                          if (settings.showTaxBreakdown && info.isTaxEnabled)
                            _buildReceiptLine(
                              'Tax (${info.taxRatePercentage})',
                              fmt(taxAmount),
                              settings.fontSize - 2,
                            ),
                          if (settings.showServiceChargeBreakdown && info.isServiceChargeEnabled)
                            _buildReceiptLine(
                              'Service Charge (${info.serviceChargeRatePercentage})',
                              fmt(serviceChargeAmount),
                              settings.fontSize - 2,
                            ),
                          const SizedBox(height: 4),
                          _buildReceiptLine(
                            'Total',
                            fmt(totalAmount),
                            settings.fontSize,
                            bold: true,
                          ),
                          const SizedBox(height: 16),
                          if (settings.showThankYouMessage) ...[
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              settings.thankYouMessage,
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble() - 1,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (settings.footerText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              settings.footerText,
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble() - 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (settings.termsAndConditions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              settings.termsAndConditions,
                              style: TextStyle(
                                fontSize: settings.fontSize.toDouble() - 3,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptLine(String label, String value, int fontSize, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize.toDouble() - 1,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize.toDouble() - 1,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
