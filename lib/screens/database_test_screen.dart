import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/mock_database_service.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  String _status = 'Not initialized';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      setState(() {
        _status = 'Initializing...';
        _logs.clear();
      });

      _addLog('Starting database initialization...');

      final db = await DatabaseHelper.instance.database;
      _addLog('✓ Database opened successfully');

      // Test reading default data
      final businessInfo = await db.query('business_info');
      _addLog('✓ Business info loaded: ${businessInfo.length} record(s)');

      final users = await db.query('users');
      _addLog('✓ Users loaded: ${users.length} record(s)');

      final paymentMethods = await db.query('payment_methods');
      _addLog('✓ Payment methods loaded: ${paymentMethods.length} record(s)');

      final receiptSettings = await db.query('receipt_settings');
      _addLog('✓ Receipt settings loaded: ${receiptSettings.length} record(s)');

      // Test table counts
      final tables = [
        'business_info',
        'categories',
        'items',
        'users',
        'tables',
        'payment_methods',
        'printers',
        'orders',
        'order_items',
        'transactions',
        'receipt_settings',
        'inventory_adjustments',
        'cash_sessions',
        'discounts',
        'item_modifiers',
        'audit_log',
      ];

      _addLog('\nTable verification:');
      for (final table in tables) {
        try {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $table',
          );
          final count = result.first['count'] as int;
          _addLog('  - $table: $count record(s)');
        } catch (e) {
          _addLog('  - $table: ERROR - $e');
        }
      }

      setState(() {
        _status = 'Database ready ✓';
      });
      _addLog('\n✓ Database initialization completed successfully!');
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      _addLog('✗ Error: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text(
          'Are you sure you want to reset the database?\n\n'
          'This will DELETE ALL DATA and recreate the database with default values.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        setState(() {
          _status = 'Resetting...';
          _logs.clear();
        });

        _addLog('Resetting database...');
        await DatabaseHelper.instance.resetDatabase();
        _addLog('✓ Database reset successfully');

        await _initDatabase();
      } catch (e) {
        setState(() {
          _status = 'Reset error: $e';
        });
        _addLog('✗ Reset error: $e');
      }
    }
  }

  Future<void> _insertTestData() async {
    try {
      setState(() {
        _status = 'Inserting test data...';
      });

      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      // Insert test category
      await db.insert('categories', {
        'id': 'test-cat-1',
        'name': 'Test Category',
        'description': 'Test category description',
        'icon_code_point': Icons.category.codePoint,
        'icon_font_family': Icons.category.fontFamily,
        'color_value': const Color(0xFF2196F3).toARGB32(),
        'sort_order': 1,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
      _addLog('✓ Inserted test category');

      // Insert test item
      await db.insert('items', {
        'id': 'test-item-1',
        'name': 'Test Item',
        'description': 'Test item description',
        'price': 9.99,
        'category_id': 'test-cat-1',
        'icon_code_point': Icons.shopping_bag.codePoint,
        'icon_font_family': Icons.shopping_bag.fontFamily,
        'color_value': const Color(0xFF4CAF50).toARGB32(),
        'is_available': 1,
        'is_featured': 0,
        'stock': 100,
        'track_stock': 1,
        'sort_order': 1,
        'created_at': now,
        'updated_at': now,
      });
      _addLog('✓ Inserted test item');

      setState(() {
        _status = 'Test data inserted ✓';
      });

      await _initDatabase();
    } catch (e) {
      setState(() {
        _status = 'Insert error: $e';
      });
      _addLog('✗ Insert error: $e');
    }
  }

  Future<void> _restoreRetailMockData() async {
    try {
      setState(() {
        _status = 'Restoring retail mock data...';
        _logs.clear();
      });

      _addLog('Starting retail mock data restore...');
      await MockDatabaseService.instance.restoreRetailMockData();
      _addLog('✓ Retail mock data restored successfully');

      setState(() {
        _status = 'Retail mock data restored ✓';
      });

      await _initDatabase();
    } catch (e) {
      setState(() {
        _status = 'Restore error: $e';
      });
      _addLog('✗ Restore error: $e');
    }
  }

  Future<void> _restoreRestaurantMockData() async {
    try {
      setState(() {
        _status = 'Restoring restaurant mock data...';
        _logs.clear();
      });

      _addLog('Starting restaurant mock data restore...');
      await MockDatabaseService.instance.restoreRestaurantMockData();
      _addLog('✓ Restaurant mock data restored successfully');

      setState(() {
        _status = 'Restaurant mock data restored ✓';
      });

      await _initDatabase();
    } catch (e) {
      setState(() {
        _status = 'Restore error: $e';
      });
      _addLog('✗ Restore error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _status.contains('Error') || _status.contains('error')
                ? Colors.red.shade50
                : _status.contains('✓')
                ? Colors.green.shade50
                : Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        _status.contains('Error') || _status.contains('error')
                        ? Colors.red.shade700
                        : _status.contains('✓')
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _initDatabase,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _insertTestData,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Test Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _resetDatabase,
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset DB'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restoreRetailMockData,
                        icon: const Icon(Icons.store),
                        label: const Text('Retail Mock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restoreRestaurantMockData,
                        icon: const Icon(Icons.restaurant),
                        label: const Text('Restaurant Mock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log.startsWith('✗');
                final isSuccess = log.startsWith('✓');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: isError
                          ? Colors.red.shade700
                          : isSuccess
                          ? Colors.green.shade700
                          : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
