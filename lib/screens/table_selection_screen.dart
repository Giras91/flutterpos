import 'package:flutter/material.dart';
import '../services/reset_service.dart';
import '../models/table_model.dart';
import '../models/cart_item.dart';
import 'pos_order_screen_fixed.dart';
import '../widgets/responsive_layout.dart';
import '../models/business_info_model.dart';

class TableSelectionScreen extends StatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final List<RestaurantTable> tables = [
    RestaurantTable(id: '1', name: 'Table 1', capacity: 2),
    RestaurantTable(id: '2', name: 'Table 2', capacity: 4),
    RestaurantTable(id: '3', name: 'Table 3', capacity: 4),
    RestaurantTable(id: '4', name: 'Table 4', capacity: 6),
    RestaurantTable(id: '5', name: 'Table 5', capacity: 2),
    RestaurantTable(id: '6', name: 'Table 6', capacity: 4),
    RestaurantTable(id: '7', name: 'Table 7', capacity: 8),
    RestaurantTable(id: '8', name: 'Table 8', capacity: 4),
    RestaurantTable(id: '9', name: 'Table 9', capacity: 2),
    RestaurantTable(id: '10', name: 'Table 10', capacity: 6),
  ];

  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    // Listen for reset events to clear table orders
    ResetService.instance.addListener(_handleReset);
  }

  @override
  void dispose() {
    ResetService.instance.removeListener(_handleReset);
    super.dispose();
  }

  void _handleReset() {
    if (!mounted) return;
    setState(() {
      for (final t in tables) {
        t.clearOrders();
        t.status = TableStatus.available;
      }
      _filterStatus = 'All';
    });
  }

  List<RestaurantTable> get filteredTables {
    if (_filterStatus == 'All') return tables;
    if (_filterStatus == 'Available') {
      return tables.where((t) => t.isAvailable).toList();
    }
    if (_filterStatus == 'Occupied') {
      return tables.where((t) => t.isOccupied).toList();
    }
    return tables;
  }

  void _onTableTap(RestaurantTable table) async {
    final result = await Navigator.push<List<CartItem>>(
      context,
      MaterialPageRoute(builder: (context) => POSOrderScreen(table: table)),
    );

    if (result != null) {
      setState(() {
        final tableIndex = tables.indexWhere((t) => t.id == table.id);
        if (result.isEmpty) {
          // Order completed/cleared
          tables[tableIndex].clearOrders();
        } else {
          // Update orders (saved/held)
          tables[tableIndex].orders = result;
          tables[tableIndex].status = TableStatus.occupied;

          // Show confirmation toast
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Order saved for ${table.name} (${result.length} items)',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ResponsiveLayout(
        builder: (context, constraints, info) {
          final crossAxisCount = info.columns.clamp(1, 4);

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final t = tables[index];
              return GestureDetector(
                onTap: () => _onTableTap(t),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('${t.itemCount} items'),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${BusinessInfo.instance.currencySymbol} ${t.totalAmount.toStringAsFixed(2)}',
                            ),
                            Text(t.status.toString().split('.').last),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Status chips and header are intentionally omitted here; table selection
// UI shows a simple grid. A richer header can be added later if desired.

class TableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;

  const TableCard({super.key, required this.table, required this.onTap});

  Color get _statusColor {
    switch (table.status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.orange;
      case TableStatus.reserved:
        return Colors.blue;
    }
  }

  IconData get _statusIcon {
    switch (table.status) {
      case TableStatus.available:
        return Icons.check_circle;
      case TableStatus.occupied:
        return Icons.restaurant_menu;
      case TableStatus.reserved:
        return Icons.event;
    }
  }

  String get _statusText {
    switch (table.status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: table.isOccupied ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: table.isOccupied ? _statusColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Table Icon
              Icon(Icons.table_restaurant, size: 48, color: _statusColor),
              const SizedBox(height: 8),
              // Table Name
              Text(
                table.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Capacity
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${table.capacity} seats',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 14, color: _statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Order Info (if occupied)
              if (table.isOccupied) ...[
                const SizedBox(height: 8),
                Text(
                  '${table.itemCount} items',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${BusinessInfo.instance.currencySymbol} ${table.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
