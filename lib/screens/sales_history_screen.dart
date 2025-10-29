import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/formatting_service.dart';
import '../models/payment_method_model.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import '../models/business_info_model.dart';

// Note: writes CSV to `exports/` folder in project root.

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  DateTime? _from;
  DateTime? _to;
  String? _selectedPaymentMethodId;
  List<PaymentMethod> _paymentMethods = [];

  int _page = 0;
  final int _pageSize = 50;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _loadOrders();
  }

  Future<void> _loadPaymentMethods() async {
    final methods = await DatabaseService.instance.getPaymentMethods();
    if (!mounted) return;
    setState(() {
      _paymentMethods = methods;
    });
  }

  Future<void> _loadOrders({int page = 0}) async {
    setState(() => _loading = true);
    final offset = page * _pageSize;
    final orders = await DatabaseService.instance.getOrders(
      from: _from,
      to: _to,
      paymentMethodId: _selectedPaymentMethodId,
      offset: offset,
      limit: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _page = page;
      _hasMore = orders.length == _pageSize;
      _loading = false;
    });
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
    final orderId = order['id'] as String;
    final items = await DatabaseService.instance.getOrderItems(orderId);
    final transactions = await DatabaseService.instance.getTransactionsForOrder(
      orderId,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order ${order['order_number'] ?? orderId}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (it) => ListTile(
                  title: Text(it['item_name'] as String),
                  subtitle: Text(
                    'Qty: ${it['quantity']} • @ ${FormattingService.currency((it['item_price'] as num).toDouble())}',
                  ),
                  trailing: Text(
                    FormattingService.currency(
                      (it['subtotal'] as num).toDouble(),
                    ),
                  ),
                ),
              ),
              const Divider(),
              const Text(
                'Transactions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...transactions.map(
                (t) => ListTile(
                  title: Text(t['payment_method_id'] ?? 'Unknown'),
                  subtitle: Text(t['transaction_date'] ?? ''),
                  trailing: Text(
                    FormattingService.currency((t['amount'] as num).toDouble()),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final messenger = ScaffoldMessenger.of(context);

      // Let the OS-native dialog handle filename and location in one step
      // Build a slug for the business name to make the filename filesystem-safe
      final bizSlug = BusinessInfo.instance.businessName
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .trim();
      String dateRangeSegment = '';
      if (_from != null || _to != null) {
        final f = _from != null
            ? _from!.toIso8601String().split('T').first
            : 'any';
        final t = _to != null ? _to!.toIso8601String().split('T').first : 'any';
        dateRangeSegment = '_${f}_to_$t';
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final suggestedName =
          'sales_history_$bizSlug${dateRangeSegment}_$timestamp.csv';
      final location = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );
      if (location == null) return; // user cancelled

      // Generate CSV (per-order-item rows)
      final csv = await DatabaseService.instance.exportOrdersCsv(
        from: _from,
        to: _to,
        paymentMethodId: _selectedPaymentMethodId,
        limit: 100000,
      );

      if (csv.trim().isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('No orders to export')),
        );
        return;
      }

      final file = File(location.path);
      await file.writeAsString(csv);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Exported orders to ${location.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _from ??
                                    DateTime.now().subtract(
                                      const Duration(days: 7),
                                    ),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && mounted) {
                                setState(() => _from = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'From',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _from == null
                                    ? 'Any'
                                    : _from!.toIso8601String().split('T').first,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _to ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && mounted) {
                                setState(() => _to = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'To',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _to == null
                                    ? 'Any'
                                    : _to!.toIso8601String().split('T').first,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedPaymentMethodId,
                            decoration: const InputDecoration(
                              labelText: 'Payment Method',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All'),
                              ),
                              ..._paymentMethods.map(
                                (m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.name),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedPaymentMethodId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _loadOrders(page: 0),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _orders.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(child: Text('No orders found')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final o = _orders[index];
                              final date = o['created_at'] as String? ?? '';
                              final total =
                                  (o['total'] as num?)?.toDouble() ?? 0.0;
                              return ListTile(
                                title: Text(o['order_number'] ?? 'Order'),
                                subtitle: Text(date),
                                trailing: Text(
                                  FormattingService.currency(total),
                                ),
                                onTap: () => _showOrderDetails(o),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _page > 0
                              ? () => _loadOrders(page: _page - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Previous'),
                        ),
                        Text('Page ${_page + 1}'),
                        TextButton.icon(
                          onPressed: _hasMore
                              ? () => _loadOrders(page: _page + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
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
