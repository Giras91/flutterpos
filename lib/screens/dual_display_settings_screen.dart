import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/imin_printer_service.dart';

class DualDisplaySettingsScreen extends StatefulWidget {
  const DualDisplaySettingsScreen({super.key});

  @override
  State<DualDisplaySettingsScreen> createState() =>
      _DualDisplaySettingsScreenState();
}

class _DualDisplaySettingsScreenState extends State<DualDisplaySettingsScreen> {
  bool _dualDisplayEnabled = false;
  bool _showWelcomeMessage = true;
  bool _showOrderTotal = true;
  bool _showPaymentAmount = true;
  bool _showChangeAmount = true;
  bool _showThankYouMessage = true;
  bool _isIminSupported = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkIminSupport();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _dualDisplayEnabled = prefs.getBool('dual_display_enabled') ?? false;
        _showWelcomeMessage =
            prefs.getBool('dual_display_show_welcome') ?? true;
        _showOrderTotal = prefs.getBool('dual_display_show_total') ?? true;
        _showPaymentAmount = prefs.getBool('dual_display_show_payment') ?? true;
        _showChangeAmount = prefs.getBool('dual_display_show_change') ?? true;
        _showThankYouMessage =
            prefs.getBool('dual_display_show_thank_you') ?? true;
      });
    } catch (e) {
      // Use defaults
    }
  }

  Future<void> _checkIminSupport() async {
    try {
      final iminService = IminPrinterService();
      await iminService.initialize();
      final isSupported = await iminService.isDualDisplaySupported();
      setState(() {
        _isIminSupported = isSupported;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isIminSupported = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // Ignore save errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual Display Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isIminSupported
          ? _buildNotSupportedView()
          : _buildSettingsView(),
    );
  }

  Widget _buildNotSupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Dual Display Not Supported',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your device does not support dual display functionality. '
              'This feature requires IMIN hardware with customer display capabilities.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dual Display',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Show information on customer display',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _dualDisplayEnabled,
                      onChanged: (value) {
                        setState(() => _dualDisplayEnabled = value);
                        _saveSetting('dual_display_enabled', value);
                      },
                    ),
                  ],
                ),
                if (_dualDisplayEnabled) ...[
                  const Divider(height: 24),
                  const Text(
                    'Display Options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildDisplayOption(
                    'Welcome Message',
                    'Show business name when idle',
                    _showWelcomeMessage,
                    (value) {
                      setState(() => _showWelcomeMessage = value);
                      _saveSetting('dual_display_show_welcome', value);
                    },
                  ),
                  _buildDisplayOption(
                    'Order Total',
                    'Show total amount during checkout',
                    _showOrderTotal,
                    (value) {
                      setState(() => _showOrderTotal = value);
                      _saveSetting('dual_display_show_total', value);
                    },
                  ),
                  _buildDisplayOption(
                    'Payment Amount',
                    'Show payment amount when processing',
                    _showPaymentAmount,
                    (value) {
                      setState(() => _showPaymentAmount = value);
                      _saveSetting('dual_display_show_payment', value);
                    },
                  ),
                  _buildDisplayOption(
                    'Change Amount',
                    'Show change amount after payment',
                    _showChangeAmount,
                    (value) {
                      setState(() => _showChangeAmount = value);
                      _saveSetting('dual_display_show_change', value);
                    },
                  ),
                  _buildDisplayOption(
                    'Thank You Message',
                    'Show thank you after transaction',
                    _showThankYouMessage,
                    (value) {
                      setState(() => _showThankYouMessage = value);
                      _saveSetting('dual_display_show_thank_you', value);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How it works',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  'Welcome',
                  'Displays business name when POS is idle',
                ),
                _buildInfoItem(
                  'Order Total',
                  'Shows the total amount during checkout process',
                ),
                _buildInfoItem(
                  'Payment',
                  'Displays the payment amount being processed',
                ),
                _buildInfoItem(
                  'Change',
                  'Shows the change amount to be returned to customer',
                ),
                _buildInfoItem(
                  'Thank You',
                  'Displays appreciation message after transaction',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
