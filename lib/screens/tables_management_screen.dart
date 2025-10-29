import 'package:flutter/material.dart';
import '../models/table_model.dart';

class TablesManagementScreen extends StatefulWidget {
  const TablesManagementScreen({super.key});

  @override
  State<TablesManagementScreen> createState() => _TablesManagementScreenState();
}

class _TablesManagementScreenState extends State<TablesManagementScreen> {
  List<RestaurantTable> tables = [
    RestaurantTable(id: '1', name: 'Table 1', capacity: 2),
    RestaurantTable(id: '2', name: 'Table 2', capacity: 4),
    RestaurantTable(id: '3', name: 'Table 3', capacity: 4),
    RestaurantTable(id: '4', name: 'Table 4', capacity: 6),
    RestaurantTable(id: '5', name: 'Table 5', capacity: 2),
    RestaurantTable(id: '6', name: 'Table 6', capacity: 4),
    RestaurantTable(id: '7', name: 'Table 7', capacity: 8),
    RestaurantTable(id: '8', name: 'Table 8', capacity: 2),
    RestaurantTable(id: '9', name: 'Table 9', capacity: 6),
    RestaurantTable(id: '10', name: 'Table 10', capacity: 4),
  ];

  void _addTable() {
    showDialog(
      context: context,
      builder: (context) => _TableFormDialog(
        onSave: (table) {
          setState(() {
            tables.add(table);
          });
        },
      ),
    );
  }

  void _editTable(RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => _TableFormDialog(
        table: table,
        onSave: (updatedTable) {
          setState(() {
            final index = tables.indexWhere((t) => t.id == updatedTable.id);
            if (index != -1) {
              tables[index] = updatedTable;
            }
          });
        },
      ),
    );
  }

  void _deleteTable(RestaurantTable table) {
    if (table.isOccupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete an occupied table')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Are you sure you want to delete "${table.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tables.removeWhere((t) => t.id == table.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Table deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _duplicateTable(RestaurantTable table) {
    final newId = (tables.length + 1).toString();
    final newTable = RestaurantTable(
      id: newId,
      name: 'Table $newId',
      capacity: table.capacity,
    );
    setState(() {
      tables.add(newTable);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Table duplicated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use wrapping layout for smaller screens
                if (constraints.maxWidth < 800) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.table_restaurant,
                          label: 'Total Tables',
                          value: tables.length.toString(),
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.check_circle,
                          label: 'Available',
                          value: tables.where((t) => t.isAvailable).length.toString(),
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.people,
                          label: 'Occupied',
                          value: tables.where((t) => t.isOccupied).length.toString(),
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _StatCard(
                          icon: Icons.event_seat,
                          label: 'Total Capacity',
                          value: tables.fold(0, (sum, t) => sum + t.capacity).toString(),
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  );
                }
                // Use row layout for wider screens
                return Row(
                  children: [
                    _StatCard(
                      icon: Icons.table_restaurant,
                      label: 'Total Tables',
                      value: tables.length.toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      icon: Icons.check_circle,
                      label: 'Available',
                      value: tables.where((t) => t.isAvailable).length.toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      icon: Icons.people,
                      label: 'Occupied',
                      value: tables.where((t) => t.isOccupied).length.toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      icon: Icons.event_seat,
                      label: 'Total Capacity',
                      value: tables.fold(0, (sum, t) => sum + t.capacity).toString(),
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adjust grid columns based on available width
                int crossAxisCount = 4;
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                } else if (constraints.maxWidth < 1200) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                final table = tables[index];
                return Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _editTable(table),
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_restaurant,
                                size: 48,
                                color: table.isAvailable
                                    ? Colors.green
                                    : table.isOccupied
                                        ? Colors.orange
                                        : Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                table.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${table.capacity} seats'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: table.isAvailable
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : table.isOccupied
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  table.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: table.isAvailable
                                        ? Colors.green
                                        : table.isOccupied
                                            ? Colors.orange
                                            : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _editTable(table);
                                  break;
                                case 'duplicate':
                                  _duplicateTable(table);
                                  break;
                                case 'delete':
                                  _deleteTable(table);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy, size: 18),
                                    SizedBox(width: 8),
                                    Text('Duplicate'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTable,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add),
        label: const Text('Add Table'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableFormDialog extends StatefulWidget {
  final RestaurantTable? table;
  final Function(RestaurantTable) onSave;

  const _TableFormDialog({
    this.table,
    required this.onSave,
  });

  @override
  State<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<_TableFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TableStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.table?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.table?.capacity.toString() ?? '4',
    );
    _selectedStatus = widget.table?.status ?? TableStatus.available;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter table name')),
      );
      return;
    }

    final capacity = int.tryParse(_capacityController.text);
    if (capacity == null || capacity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid capacity')),
      );
      return;
    }

    final table = RestaurantTable(
      id: widget.table?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      capacity: capacity,
      status: _selectedStatus,
      orders: widget.table?.orders,
      occupiedSince: widget.table?.occupiedSince,
      customerName: widget.table?.customerName,
    );

    widget.onSave(table);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.table == null ? 'Add Table' : 'Edit Table'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Table Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Table 1',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity *',
                  border: OutlineInputBorder(),
                  hintText: '4',
                  suffixText: 'seats',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TableStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(),
                ),
                items: TableStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
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
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
