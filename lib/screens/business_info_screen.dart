import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/business_info_model.dart';

class BusinessInfoScreen extends StatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  late BusinessInfo businessInfo;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    businessInfo = BusinessInfo.instance;
  }

  void _editBusinessDetails() {
    showDialog(
      context: context,
      builder: (context) => _BusinessDetailsDialog(
        businessInfo: businessInfo,
        onSave: (updated) {
          setState(() {
            businessInfo = updated;
            BusinessInfo.updateInstance(updated);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business details updated')),
          );
        },
      ),
    );
  }

  void _editTaxSettings() {
    showDialog(
      context: context,
      builder: (context) => _TaxSettingsDialog(
        businessInfo: businessInfo,
        onSave: (updated) {
          setState(() {
            businessInfo = updated;
            BusinessInfo.updateInstance(updated);
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tax settings updated')));
        },
      ),
    );
  }

  void _editBusinessHours() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BusinessHoursScreen(
          businessHours: businessInfo.businessHours,
          onSave: (updated) {
            final newInfo = businessInfo.copyWith(businessHours: updated);
            setState(() {
              businessInfo = newInfo;
              BusinessInfo.updateInstance(newInfo);
            });
          },
        ),
      ),
    );
  }

  void _editReceiptSettings() {
    showDialog(
      context: context,
      builder: (context) => _ReceiptSettingsDialog(
        businessInfo: businessInfo,
        onSave: (updated) {
          setState(() {
            businessInfo = updated;
            BusinessInfo.updateInstance(updated);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt settings updated')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Information'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store,
                      size: 40,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    businessInfo.businessName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    businessInfo.fullAddress,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoChip(icon: Icons.phone, label: businessInfo.phone),
                      _InfoChip(icon: Icons.email, label: businessInfo.email),
                      if (businessInfo.website != null)
                        _InfoChip(
                          icon: Icons.language,
                          label: businessInfo.website!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Business Details Section
          _SectionHeader(
            title: 'Business Details',
            onEdit: _editBusinessDetails,
          ),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.person,
                  label: 'Owner Name',
                  value: businessInfo.ownerName,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.business,
                  label: 'Registration Number',
                  value: businessInfo.registrationNumber ?? 'Not set',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.location_on,
                  label: 'City',
                  value: businessInfo.city,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.map,
                  label: 'State',
                  value: businessInfo.state,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.mail,
                  label: 'Postcode',
                  value: businessInfo.postcode,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.flag,
                  label: 'Country',
                  value: businessInfo.country,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tax & Currency Section
          _SectionHeader(title: 'Tax & Currency', onEdit: _editTaxSettings),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.receipt,
                  label: 'Tax Number',
                  value: businessInfo.taxNumber ?? 'Not set',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.percent,
                  label: 'Tax Rate',
                  value: businessInfo.isTaxEnabled
                      ? businessInfo.taxRatePercentage
                      : 'Disabled',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.room_service,
                  label: 'Service Charge',
                  value: businessInfo.isServiceChargeEnabled
                      ? businessInfo.serviceChargeRatePercentage
                      : 'Disabled',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.attach_money,
                  label: 'Currency',
                  value:
                      '${businessInfo.currency} (${businessInfo.currencySymbol})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business Hours Section
          _SectionHeader(title: 'Business Hours', onEdit: _editBusinessHours),
          Card(
            child: Column(
              children: [
                _BusinessHoursTile(
                  day: 'Monday',
                  hours: businessInfo.businessHours.monday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Tuesday',
                  hours: businessInfo.businessHours.tuesday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Wednesday',
                  hours: businessInfo.businessHours.wednesday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Thursday',
                  hours: businessInfo.businessHours.thursday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Friday',
                  hours: businessInfo.businessHours.friday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Saturday',
                  hours: businessInfo.businessHours.saturday,
                ),
                const Divider(height: 1),
                _BusinessHoursTile(
                  day: 'Sunday',
                  hours: businessInfo.businessHours.sunday,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Receipt Settings Section
          _SectionHeader(
            title: 'Receipt Settings',
            onEdit: _editReceiptSettings,
          ),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.text_fields,
                  label: 'Header Font Size',
                  value: businessInfo.receiptHeaderFontSize.toString(),
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.format_bold,
                  label: 'Header Bold',
                  value: businessInfo.receiptHeaderBold ? 'Yes' : 'No',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.format_align_center,
                  label: 'Header Centered',
                  value: businessInfo.receiptHeaderCentered ? 'Yes' : 'No',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;

  const _SectionHeader({required this.title, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
      label: Text(label),
    );
  }
}

class _BusinessHoursTile extends StatelessWidget {
  final String day;
  final TimeRange hours;

  const _BusinessHoursTile({required this.day, required this.hours});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        hours.isOpen ? Icons.access_time : Icons.close,
        color: hours.isOpen ? Colors.green : Colors.grey,
      ),
      title: Text(day),
      trailing: Text(
        hours.displayText,
        style: TextStyle(
          color: hours.isOpen ? Colors.black87 : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Business Details Dialog
class _BusinessDetailsDialog extends StatefulWidget {
  final BusinessInfo businessInfo;
  final Function(BusinessInfo) onSave;

  const _BusinessDetailsDialog({
    required this.businessInfo,
    required this.onSave,
  });

  @override
  State<_BusinessDetailsDialog> createState() => _BusinessDetailsDialogState();
}

class _BusinessDetailsDialogState extends State<_BusinessDetailsDialog> {
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postcodeController;
  late TextEditingController _registrationController;
  late TextEditingController _websiteController;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.businessInfo.businessName,
    );
    _ownerNameController = TextEditingController(
      text: widget.businessInfo.ownerName,
    );
    _emailController = TextEditingController(text: widget.businessInfo.email);
    _phoneController = TextEditingController(text: widget.businessInfo.phone);
    _addressController = TextEditingController(
      text: widget.businessInfo.address,
    );
    _cityController = TextEditingController(text: widget.businessInfo.city);
    _stateController = TextEditingController(text: widget.businessInfo.state);
    _postcodeController = TextEditingController(
      text: widget.businessInfo.postcode,
    );
    _registrationController = TextEditingController(
      text: widget.businessInfo.registrationNumber ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.businessInfo.website ?? '',
    );

    // initialize logo path from existing business info
    _logoPath = widget.businessInfo.logo;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _registrationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<String> _copyToLocal(String src, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'images'));
    if (!imagesDir.existsSync()) await imagesDir.create(recursive: true);
    final ext = p.extension(src);
    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = p.join(imagesDir.path, filename);
    await File(src).copy(dest);
    return dest;
  }

  Future<void> _save() async {
    final updated = widget.businessInfo.copyWith(
      // logo is handled elsewhere in the dialog state
      businessName: _businessNameController.text,
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      postcode: _postcodeController.text,
      registrationNumber: _registrationController.text.isEmpty
          ? null
          : _registrationController.text,
      website: _websiteController.text.isEmpty ? null : _websiteController.text,
    );
    // If a logoPath was selected in the dialog, copy to app local storage and include it
    String? logoToSave = updated.logo;
    if (_logoPath != null && _logoPath!.isNotEmpty) {
      try {
        // If already under app dir we can keep it
        final appDir = await getApplicationDocumentsDirectory();
        if (!_logoPath!.startsWith(appDir.path)) {
          logoToSave = await _copyToLocal(_logoPath!, 'logo');
        } else {
          logoToSave = _logoPath;
        }
      } catch (_) {
        // ignore copy failures and fall back to original path
        logoToSave = _logoPath;
      }
    }

    final finalUpdated = updated.copyWith(logo: logoToSave ?? updated.logo);
    if (!mounted) return;
    widget.onSave(finalUpdated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Business Details'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo preview and upload
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _logoPath != null && _logoPath!.isNotEmpty
                        ? Image.file(File(_logoPath!), fit: BoxFit.cover)
                        : (widget.businessInfo.logo != null &&
                              widget.businessInfo.logo!.isNotEmpty)
                        ? Image.file(
                            File(widget.businessInfo.logo!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.photo, size: 36, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            setState(() {
                              _logoPath = result.files.single.path!;
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Logo'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _logoPath = null;
                          });
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _postcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postcode *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _registrationController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                ),
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

// Tax Settings Dialog
class _TaxSettingsDialog extends StatefulWidget {
  final BusinessInfo businessInfo;
  final Function(BusinessInfo) onSave;

  const _TaxSettingsDialog({required this.businessInfo, required this.onSave});

  @override
  State<_TaxSettingsDialog> createState() => _TaxSettingsDialogState();
}

class _TaxSettingsDialogState extends State<_TaxSettingsDialog> {
  late TextEditingController _taxNumberController;
  late TextEditingController _taxRateController;
  late TextEditingController _serviceChargeRateController;
  late bool _isTaxEnabled;
  late bool _isServiceChargeEnabled;

  @override
  void initState() {
    super.initState();
    _taxNumberController = TextEditingController(
      text: widget.businessInfo.taxNumber ?? '',
    );
    _taxRateController = TextEditingController(
      text: (widget.businessInfo.taxRate * 100).toStringAsFixed(1),
    );
    _serviceChargeRateController = TextEditingController(
      text: (widget.businessInfo.serviceChargeRate * 100).toStringAsFixed(1),
    );
    _isTaxEnabled = widget.businessInfo.isTaxEnabled;
    _isServiceChargeEnabled = widget.businessInfo.isServiceChargeEnabled;
  }

  @override
  void dispose() {
    _taxNumberController.dispose();
    _taxRateController.dispose();
    _serviceChargeRateController.dispose();
    super.dispose();
  }

  void _save() {
    final taxRate = double.tryParse(_taxRateController.text) ?? 10.0;
    final serviceChargeRate =
        double.tryParse(_serviceChargeRateController.text) ?? 5.0;
    final updated = widget.businessInfo.copyWith(
      taxNumber: _taxNumberController.text.isEmpty
          ? null
          : _taxNumberController.text,
      taxRate: taxRate / 100,
      isTaxEnabled: _isTaxEnabled,
      serviceChargeRate: serviceChargeRate / 100,
      isServiceChargeEnabled: _isServiceChargeEnabled,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tax & Service Charge Settings'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taxNumberController,
                decoration: const InputDecoration(
                  labelText: 'Tax Number',
                  border: OutlineInputBorder(),
                  hintText: 'GST/SST Number',
                ),
              ),
              const SizedBox(height: 16),
              // Tax Enable Toggle
              SwitchListTile(
                title: const Text('Enable Tax'),
                subtitle: const Text('Apply tax to all transactions'),
                value: _isTaxEnabled,
                onChanged: (value) => setState(() => _isTaxEnabled = value),
              ),
              if (_isTaxEnabled) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _taxRateController,
                  decoration: const InputDecoration(
                    labelText: 'Tax Rate (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Service Charge Enable Toggle
              SwitchListTile(
                title: const Text('Enable Service Charge'),
                subtitle: const Text(
                  'Apply service charge to all transactions',
                ),
                value: _isServiceChargeEnabled,
                onChanged: (value) =>
                    setState(() => _isServiceChargeEnabled = value),
              ),
              if (_isServiceChargeEnabled) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _serviceChargeRateController,
                  decoration: const InputDecoration(
                    labelText: 'Service Charge Rate (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These rates will be applied to all transactions',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
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

// Receipt Settings Dialog
class _ReceiptSettingsDialog extends StatefulWidget {
  final BusinessInfo businessInfo;
  final Function(BusinessInfo) onSave;

  const _ReceiptSettingsDialog({
    required this.businessInfo,
    required this.onSave,
  });

  @override
  State<_ReceiptSettingsDialog> createState() => _ReceiptSettingsDialogState();
}

class _ReceiptSettingsDialogState extends State<_ReceiptSettingsDialog> {
  late int _headerFontSize;
  late bool _headerBold;
  late bool _headerCentered;

  @override
  void initState() {
    super.initState();
    _headerFontSize = widget.businessInfo.receiptHeaderFontSize;
    _headerBold = widget.businessInfo.receiptHeaderBold;
    _headerCentered = widget.businessInfo.receiptHeaderCentered;
  }

  void _save() {
    final updated = widget.businessInfo.copyWith(
      receiptHeaderFontSize: _headerFontSize,
      receiptHeaderBold: _headerBold,
      receiptHeaderCentered: _headerCentered,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Receipt Header Settings'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configure how the business name appears on thermal receipts',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Header Font Size',
                  border: OutlineInputBorder(),
                  helperText: '1=Small, 2=Medium, 3=Large',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: _headerFontSize.toString(),
                ),
                onChanged: (value) {
                  final size = int.tryParse(value) ?? 2;
                  setState(() => _headerFontSize = size.clamp(1, 3));
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Bold Header'),
                subtitle: const Text('Make the business name bold'),
                value: _headerBold,
                onChanged: (value) => setState(() => _headerBold = value),
              ),
              SwitchListTile(
                title: const Text('Center Header'),
                subtitle: const Text('Center-align the business name'),
                value: _headerCentered,
                onChanged: (value) => setState(() => _headerCentered = value),
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

// Business Hours Screen
class _BusinessHoursScreen extends StatefulWidget {
  final BusinessHours businessHours;
  final Function(BusinessHours) onSave;

  const _BusinessHoursScreen({
    required this.businessHours,
    required this.onSave,
  });

  @override
  State<_BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<_BusinessHoursScreen> {
  late BusinessHours hours;

  @override
  void initState() {
    super.initState();
    hours = widget.businessHours;
  }

  void _updateHours(int dayIndex, TimeRange newHours) {
    setState(() {
      switch (dayIndex) {
        case 0:
          hours.monday = newHours;
          break;
        case 1:
          hours.tuesday = newHours;
          break;
        case 2:
          hours.wednesday = newHours;
          break;
        case 3:
          hours.thursday = newHours;
          break;
        case 4:
          hours.friday = newHours;
          break;
        case 5:
          hours.saturday = newHours;
          break;
        case 6:
          hours.sunday = newHours;
          break;
      }
    });
  }

  void _save() {
    widget.onSave(hours);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Business hours updated')));
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      ('Monday', hours.monday),
      ('Tuesday', hours.tuesday),
      ('Wednesday', hours.wednesday),
      ('Thursday', hours.thursday),
      ('Friday', hours.friday),
      ('Saturday', hours.saturday),
      ('Sunday', hours.sunday),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Hours'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final day = days[index];
          return _DayHoursCard(
            day: day.$1,
            hours: day.$2,
            onChanged: (newHours) => _updateHours(index, newHours),
          );
        },
      ),
    );
  }
}

class _DayHoursCard extends StatelessWidget {
  final String day;
  final TimeRange hours;
  final Function(TimeRange) onChanged;

  const _DayHoursCard({
    required this.day,
    required this.hours,
    required this.onChanged,
  });

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final currentTime = isOpenTime ? hours.openTime : hours.closeTime;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isOpenTime) {
        onChanged(hours.copyWith(openTime: timeString));
      } else {
        onChanged(hours.copyWith(closeTime: timeString));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: hours.isOpen,
                  onChanged: (value) {
                    onChanged(hours.copyWith(isOpen: value));
                  },
                ),
                Text(hours.isOpen ? 'Open' : 'Closed'),
              ],
            ),
            if (hours.isOpen) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Opening Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(hours.openTime),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Closing Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(hours.closeTime),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
