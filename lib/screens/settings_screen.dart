import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import '../services/reset_service.dart';
import '../services/database_helper.dart';
import '../services/config_service.dart';
import '../screens/setup_screen.dart';
import '../services/training_data_generator.dart';
import 'printers_management_screen.dart';
import 'users_management_screen.dart';
import 'tables_management_screen.dart';
import 'business_info_screen.dart';
import 'payment_methods_management_screen.dart';
import 'receipt_settings_screen.dart';
import 'sales_history_screen.dart';
import 'categories_management_screen.dart';
import 'items_management_screen.dart';
import 'modifier_groups_management_screen.dart';
import 'database_test_screen.dart';
import 'dual_display_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Hardware',
            children: [
              _SettingsTile(
                icon: Icons.print,
                title: 'Printers Management',
                subtitle: 'Configure receipt and kitchen printers',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrintersManagementScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.monitor,
                title: 'Dual Display Settings',
                subtitle: 'Configure customer display for IMIN hardware',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DualDisplaySettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'User Management',
            children: [
              _SettingsTile(
                icon: Icons.people,
                title: 'Users Management',
                subtitle: 'Manage staff accounts and permissions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsersManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Products',
            children: [
              _SettingsTile(
                icon: Icons.category,
                title: 'Categories Management',
                subtitle: 'Organize products into categories',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesManagementScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.inventory,
                title: 'Items Management',
                subtitle: 'Add and manage products',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ItemsManagementScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.tune,
                title: 'Modifier Groups',
                subtitle: 'Manage product modifiers and options',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ModifierGroupsManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Restaurant',
            children: [
              _SettingsTile(
                icon: Icons.table_restaurant,
                title: 'Tables Management',
                subtitle: 'Configure restaurant tables and layout',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TablesManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'General',
            children: [
              _SettingsTile(
                icon: Icons.business,
                title: 'Business Information',
                subtitle: 'Store name, address, tax settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusinessInfoScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.vpn_key,
                title: 'Software Activation',
                subtitle: 'Enter license key to unlock full features',
                onTap: () {
                  Navigator.pushNamed(context, '/activation');
                },
              ),
              _SettingsTile(
                icon: Icons.attach_money,
                title: 'Payment Methods',
                subtitle: 'Configure payment options',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PaymentMethodsManagementScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.history,
                title: 'Sales History',
                subtitle: 'View recent orders and transactions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SalesHistoryScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.receipt_long,
                title: 'Receipt Settings',
                subtitle: 'Customize receipt layout and footer',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReceiptSettingsScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.refresh,
                title: 'Reset POS',
                subtitle: 'Clear all POS data (optional backup before reset)',
                onTap: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) {
                      bool backup = false;
                      return StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          title: const Text('Reset POS State'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'This will delete ALL persisted database data (categories, items, users, tables, orders, transactions) and clear in-memory POS state. This action is destructive and cannot be undone.',
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: backup,
                                onChanged: (v) =>
                                    setState(() => backup = v ?? false),
                                title: const Text(
                                  'Create backup before resetting',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, {
                                'confirmed': false,
                                'backup': false,
                              }),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, {
                                'confirmed': true,
                                'backup': backup,
                              }),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (result == null) return;

                  final confirmed = result['confirmed'] == true;
                  final doBackup = result['backup'] == true;

                  if (!confirmed) return;

                  if (doBackup) {
                    try {
                      final backupPath = await DatabaseHelper.instance
                          .backupDatabase();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Database backed up to $backupPath'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Backup failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      // Abort reset if backup is requested but fails
                      return;
                    }
                  }

                  try {
                    // Reset on-disk database (delete and recreate)
                    await DatabaseHelper.instance.resetDatabase();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error resetting database: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  // Broadcast in-memory reset
                  ResetService.instance.triggerReset();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'POS database and in-memory state cleared.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.restart_alt,
                title: 'Reset Setup',
                subtitle: 'Return to first-run setup (clears store name)',
                onTap: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) {
                      bool resetDb = false;
                      bool backup = false;
                      return StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          title: const Text('Reset Setup'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'This will clear the initial setup flag and store name so the app will show the setup screen on next start. Optionally you can reset the database to factory defaults (this will recreate seeded data).',
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: backup,
                                onChanged: (v) =>
                                    setState(() => backup = v ?? false),
                                title: const Text(
                                  'Create backup before resetting',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                              CheckboxListTile(
                                value: resetDb,
                                onChanged: (v) =>
                                    setState(() => resetDb = v ?? false),
                                title: const Text(
                                  'Also reset database to factory defaults',
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, {
                                'confirmed': false,
                                'resetDb': false,
                                'backup': false,
                              }),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, {
                                'confirmed': true,
                                'resetDb': resetDb,
                                'backup': backup,
                              }),
                              child: const Text('Reset Setup'),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (result == null) return;
                  final confirmed = result['confirmed'] == true;
                  final doResetDb = result['resetDb'] == true;
                  final doBackup = result['backup'] == true;
                  if (!confirmed) return;

                  // Clear setup flag and store name
                  try {
                    await ConfigService.instance.setSetupDone(false);
                    await ConfigService.instance.setStoreName('');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error clearing setup flag: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  if (doBackup) {
                    try {
                      final backupPath = await DatabaseHelper.instance
                          .backupDatabase();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Database backed up to $backupPath'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Backup failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      // Abort reset if backup is requested but fails
                      return;
                    }
                  }

                  if (doResetDb) {
                    try {
                      await DatabaseHelper.instance.resetDatabase();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error resetting database: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                  }

                  // Broadcast in-memory reset and navigate to setup screen
                  ResetService.instance.triggerReset();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Setup cleared — showing Setup screen now',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    // Replace stack with SetupScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (c) => const SetupScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Help & Support',
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Show Tutorial',
                subtitle: 'Replay the getting started guide',
                onTap: () async {
                  await AppSettings.instance.resetTutorial();
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tutorial will show on next app start'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.school,
                title: 'Training Mode',
                subtitle: AppSettings.instance.isTrainingMode
                    ? 'Currently enabled'
                    : 'Currently disabled',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Training Mode'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Training Mode allows you to practice using the system without affecting real data.',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'When enabled:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• All transactions are marked as training',
                          ),
                          const Text('• Data can be easily cleared'),
                          const Text('• Perfect for staff training'),
                          const SizedBox(height: 16),
                          AnimatedBuilder(
                            animation: AppSettings.instance,
                            builder: (context, child) {
                              return SwitchListTile(
                                title: const Text('Enable Training Mode'),
                                value: AppSettings.instance.isTrainingMode,
                                onChanged: (value) {
                                  AppSettings.instance.setTrainingMode(value);
                                },
                              );
                            },
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Training Data',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Load Training Data'),
                                  content: const Text(
                                    'This will add sample categories and items to your database for training purposes. This will not delete existing data.\n\nContinue?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Load Data'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                try {
                                  await TrainingDataGenerator.instance
                                      .generateSampleCategories();
                                  await TrainingDataGenerator.instance
                                      .generateSampleItems();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Training data loaded successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error loading training data: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Load Sample Data'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Clear Training Data'),
                                  content: const Text(
                                    'This will delete ALL categories and items from the database. This action cannot be undone!\n\nAre you sure?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Clear All Data'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                try {
                                  await TrainingDataGenerator.instance
                                      .clearTrainingData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Training data cleared successfully',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error clearing training data: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear All Data'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.book,
                title: 'User Guide',
                subtitle: 'Learn how to use ExtroPOS',
                onTap: () {
                  _showUserGuideDialog(context);
                },
              ),
              _SettingsTile(
                icon: Icons.block,
                title: 'Require DB Products',
                subtitle: 'Prevent adding products not present in the database',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Require DB Products'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'When enabled, you cannot add mock/fallback products to the cart. Please add the item in Items Management first.',
                          ),
                          const SizedBox(height: 12),
                          AnimatedBuilder(
                            animation: AppSettings.instance,
                            builder: (context, child) {
                              return SwitchListTile(
                                title: const Text('Enforce DB-only products'),
                                value: AppSettings.instance.requireDbProducts,
                                onChanged: (v) => AppSettings.instance
                                    .setRequireDbProducts(v),
                              );
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Developer',
            children: [
              _SettingsTile(
                icon: Icons.storage,
                title: 'Database Test',
                subtitle: 'Test and verify database functionality',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DatabaseTestScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.info,
                title: 'App Information',
                subtitle: 'ExtroPOS v1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'ExtroPOS',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.store, size: 48),
                    children: [
                      const Text(
                        'A modern point-of-sale system for retail, cafe, and restaurant businesses.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.book, size: 32, color: Colors.blue),
                  const SizedBox(width: 16),
                  const Text(
                    'User Guide',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildGuideSection('Getting Started', Icons.rocket_launch, [
                      '1. Choose your business type (Retail, Cafe, or Restaurant)',
                      '2. Configure your business information',
                      '3. Set up categories and items',
                      '4. Add payment methods and printers',
                    ]),
                    const SizedBox(height: 16),
                    _buildGuideSection('Training Mode', Icons.school, [
                      'Enable Training Mode to practice without affecting real data',
                      'Perfect for training new staff members',
                      'All transactions will be marked as training',
                      'Easily clear training data when done',
                    ]),
                    const SizedBox(height: 16),
                    _buildGuideSection('Managing Sales', Icons.point_of_sale, [
                      'Add items to cart by tapping on them',
                      'Adjust quantities as needed',
                      'Apply discounts if applicable',
                      'Select payment method and complete transaction',
                    ]),
                    const SizedBox(height: 16),
                    _buildGuideSection('Reports', Icons.analytics, [
                      'View daily, weekly, and monthly sales reports',
                      'Track best-selling items',
                      'Monitor payment method usage',
                      'Export reports for accounting',
                    ]),
                    const SizedBox(height: 16),
                    _buildGuideSection('Settings', Icons.settings, [
                      'Business Info: Update your business details',
                      'Users: Manage staff accounts and permissions',
                      'Categories & Items: Organize your products',
                      'Printers: Configure receipt printing',
                      'Payment Methods: Set up payment options',
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, IconData icon, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(point, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
