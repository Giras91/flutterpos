import 'package:flutter/material.dart';
import '../models/modifier_group_model.dart';
import '../models/modifier_item_model.dart';
import '../services/database_service.dart';

class ModifierItemsManagementScreen extends StatefulWidget {
  final ModifierGroup group;

  const ModifierItemsManagementScreen({super.key, required this.group});

  @override
  State<ModifierItemsManagementScreen> createState() =>
      _ModifierItemsManagementScreenState();
}

class _ModifierItemsManagementScreenState
    extends State<ModifierItemsManagementScreen> {
  final List<ModifierItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    try {
      final items = await DatabaseService.instance.getModifierItems(
        widget.group.id,
      );
      if (!mounted) return;
      setState(() {
        _items.clear();
        _items.addAll(items);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading modifiers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showItemDialog({ModifierItem? item}) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(
      text: item?.priceAdjustment.toString() ?? '0.00',
    );

    bool isDefault = item?.isDefault ?? false;
    int sortOrder = item?.sortOrder ?? 0;

    final parentMessenger = ScaffoldMessenger.of(context);
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Modifier' : 'Add Modifier'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight:
                    MediaQuery.of(context).size.height *
                    0.5, // Reduced from 0.6
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Modifier Name *',
                      hintText: 'e.g., Large, Extra Cheese, No Ice',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price Adjustment',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixText: '± ',
                      helperText: 'Positive to add, negative to subtract',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  SwitchListTile(
                    dense: true, // Make more compact
                    title: const Text('Default Selection'),
                    subtitle: const Text('Auto-selected for customers'),
                    value: isDefault,
                    onChanged: (value) {
                      setDialogState(() => isDefault = value);
                    },
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      sortOrder = int.tryParse(value) ?? 0;
                    },
                    controller: TextEditingController(
                      text: sortOrder.toString(),
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
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a modifier name'),
                    ),
                  );
                  return;
                }

                final newItem = ModifierItem(
                  id:
                      item?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  modifierGroupId: widget.group.id,
                  name: name,
                  description: descController.text.trim(),
                  priceAdjustment: double.tryParse(priceController.text) ?? 0.0,
                  isDefault: isDefault,
                  sortOrder: sortOrder,
                  createdAt: item?.createdAt,
                );

                try {
                  if (isEditing) {
                    await DatabaseService.instance.updateModifierItem(newItem);
                  } else {
                    await DatabaseService.instance.insertModifierItem(newItem);
                  }

                  if (!mounted) return;
                  parentNavigator.pop();
                  _loadItems();

                  parentMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Modifier ${isEditing ? 'updated' : 'created'} successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  parentMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteItem(ModifierItem item) {
    final parentMessenger = ScaffoldMessenger.of(context);
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Modifier'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await DatabaseService.instance.deleteModifierItem(item.id);
                if (!mounted) return;
                parentNavigator.pop();
                _loadItems();
                parentMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Modifier deleted successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                parentNavigator.pop();
                parentMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error deleting modifier: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.name} - Modifiers'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.getSelectionHint(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (widget.group.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.group.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_items.length} modifiers',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No modifiers yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add your first modifier',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isDefault
                                ? Colors.green
                                : const Color(0xFF2563EB),
                            child: item.isDefault
                                ? const Icon(Icons.check, color: Colors.white)
                                : const Icon(Icons.add, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (item.priceAdjustment != 0)
                                Text(
                                  item.getPriceAdjustmentDisplay(),
                                  style: TextStyle(
                                    color: item.priceAdjustment > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.description.isNotEmpty) ...[
                                Text(item.description),
                                const SizedBox(height: 4),
                              ],
                              if (item.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default Selection',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF2563EB),
                                ),
                                onPressed: () => _showItemDialog(item: item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteItem(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Modifier'),
      ),
    );
  }
}
