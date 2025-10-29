import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/item_model.dart';
import '../models/category_model.dart';
import '../models/business_info_model.dart';
import '../services/database_service.dart';

class ItemsManagementScreen extends StatefulWidget {
  const ItemsManagementScreen({super.key});

  @override
  State<ItemsManagementScreen> createState() => _ItemsManagementScreenState();
}

class _ItemsManagementScreenState extends State<ItemsManagementScreen> {
  final List<Item> _items = [];
  final List<Category> _categories = [];
  List<Item> _filteredItems = [];
  final _searchController = TextEditingController();
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    try {
      // Load categories from database
      final categories = await DatabaseService.instance.getCategories();
      // Load items from database
      final items = await DatabaseService.instance.getItems();
      if (!mounted) return;

      setState(() {
        _categories.clear();
        _categories.addAll(categories);
        _items.clear();
        _items.addAll(items);
        _filteredItems = List.from(_items);
      });
    } catch (e) {
      if (!mounted) return;
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Fall back to sample data if database fails
      setState(() {
        _categories.addAll([
          Category(
            id: '1',
            name: 'Beverages',
            description: 'Hot and cold drinks',
            icon: Icons.local_cafe,
            color: Colors.brown,
          ),
          Category(
            id: '2',
            name: 'Food',
            description: 'Main dishes',
            icon: Icons.restaurant,
            color: Colors.orange,
          ),
        ]);

        _items.addAll([
          Item(
            id: '1',
            name: 'Espresso',
            description: 'Strong black coffee',
            price: 3.50,
            categoryId: '1',
            icon: Icons.local_cafe,
            color: Colors.brown,
            stock: 100,
            trackStock: false,
          ),
          Item(
            id: '2',
            name: 'Cappuccino',
            description: 'Espresso with steamed milk',
            price: 4.50,
            categoryId: '1',
            icon: Icons.coffee,
            color: Colors.brown,
            stock: 100,
            trackStock: false,
          ),
        ]);

        _filteredItems = List.from(_items);
      });
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        final matchesSearch =
            query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.sku?.toLowerCase().contains(query) == true;

        final matchesCategory =
            _selectedCategoryFilter == null ||
            item.categoryId == _selectedCategoryFilter;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _addItem() {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a category first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _showItemDialog();
  }

  void _editItem(Item item) {
    _showItemDialog(item: item);
  }

  void _deleteItem(Item item) async {
    final parentMessenger = ScaffoldMessenger.of(context);
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseService.instance.deleteItem(item.id);
                setState(() {
                  _items.remove(item);
                  _filterItems();
                });
                if (!mounted) return;
                parentNavigator.pop();
                parentMessenger.showSnackBar(
                  SnackBar(content: Text('${item.name} deleted')),
                );
              } catch (e) {
                if (!mounted) return;
                parentNavigator.pop();
                parentMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error deleting item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({Item? item}) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(
      text: item?.price.toString() ?? '',
    );
    final costController = TextEditingController(
      text: item?.cost?.toString() ?? '',
    );
    final skuController = TextEditingController(text: item?.sku ?? '');
    final barcodeController = TextEditingController(text: item?.barcode ?? '');
    final stockController = TextEditingController(
      text: item?.stock.toString() ?? '0',
    );

    String selectedCategoryId = item?.categoryId ?? _categories.first.id;
    IconData selectedIcon = item?.icon ?? Icons.shopping_bag;
    Color selectedColor = item?.color ?? Colors.blue;
    bool isAvailable = item?.isAvailable ?? true;
    bool isFeatured = item?.isFeatured ?? false;
    bool trackStock = item?.trackStock ?? false;
    String? selectedImagePath = item?.imageUrl;

    final parentMessenger = ScaffoldMessenger.of(context);
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Item' : 'Add Item'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Item Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Image picker for item
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child:
                            (selectedImagePath != null &&
                                selectedImagePath!.isNotEmpty)
                            ? Image.file(
                                File(selectedImagePath!),
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.image,
                                size: 36,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(type: FileType.image);
                              if (result != null &&
                                  result.files.single.path != null) {
                                setDialogState(() {
                                  selectedImagePath = result.files.single.path!;
                                });
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Image'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedImagePath = null;
                              });
                            },
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(cat.icon, color: cat.color, size: 20),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedCategoryId = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.barcode_reader),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costController,
                          decoration: const InputDecoration(
                            labelText: 'Cost',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_cart),
                            helperText: 'For profit calculation',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: trackStock,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final icon = await _showIconPicker(
                              context,
                              selectedIcon,
                            );
                            if (icon != null) {
                              setDialogState(() {
                                selectedIcon = icon;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Icon',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Icon(selectedIcon, color: selectedColor),
                                const SizedBox(width: 8),
                                const Text('Tap to change'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final color = await _showColorPicker(
                              context,
                              selectedColor,
                            );
                            if (color != null) {
                              setDialogState(() {
                                selectedColor = color;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Color',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: selectedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Tap to change'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('Available'),
                          subtitle: const Text('Show in POS'),
                          value: isAvailable,
                          onChanged: (value) {
                            setDialogState(() {
                              isAvailable = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('Featured'),
                          subtitle: const Text('Highlight item'),
                          value: isFeatured,
                          onChanged: (value) {
                            setDialogState(() {
                              isFeatured = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Track Stock'),
                    subtitle: const Text('Monitor inventory levels'),
                    value: trackStock,
                    onChanged: (value) {
                      setDialogState(() {
                        trackStock = value;
                      });
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
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an item name')),
                  );
                  return;
                }

                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid price')),
                  );
                  return;
                }

                // If an image was selected, copy it into app storage first
                String? localImage = selectedImagePath;
                try {
                  if (selectedImagePath != null &&
                      selectedImagePath!.isNotEmpty) {
                    final appDir = await getApplicationDocumentsDirectory();
                    if (!selectedImagePath!.startsWith(appDir.path)) {
                      final imagesDir = Directory(
                        p.join(appDir.path, 'images'),
                      );
                      if (!imagesDir.existsSync()) {
                        await imagesDir.create(recursive: true);
                      }
                      final ext = p.extension(selectedImagePath!);
                      final filename =
                          'item_${DateTime.now().millisecondsSinceEpoch}$ext';
                      final dest = p.join(imagesDir.path, filename);
                      await File(selectedImagePath!).copy(dest);
                      localImage = dest;
                    }
                  }
                } catch (e) {
                  // ignore copy errors and fall back to original path
                  localImage = selectedImagePath;
                }

                final newItem = Item(
                  id:
                      item?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descController.text,
                  price: price,
                  categoryId: selectedCategoryId,
                  sku: skuController.text.isEmpty ? null : skuController.text,
                  barcode: barcodeController.text.isEmpty
                      ? null
                      : barcodeController.text,
                  icon: selectedIcon,
                  color: selectedColor,
                  isAvailable: isAvailable,
                  isFeatured: isFeatured,
                  trackStock: trackStock,
                  stock: int.tryParse(stockController.text) ?? 0,
                  cost: double.tryParse(costController.text),
                  imageUrl: localImage,
                  createdAt: item?.createdAt,
                );

                try {
                  if (isEditing) {
                    await DatabaseService.instance.updateItem(newItem);
                  } else {
                    await DatabaseService.instance.insertItem(newItem);
                  }

                  setState(() {
                    if (isEditing) {
                      final index = _items.indexWhere((i) => i.id == item.id);
                      if (index != -1) {
                        _items[index] = newItem;
                      }
                    } else {
                      _items.add(newItem);
                    }
                    _filterItems();
                  });

                  if (!mounted) return;
                  parentNavigator.pop();
                  parentMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Item updated successfully'
                            : 'Item added successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  parentMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error saving item: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog() {
    final importController = TextEditingController();
    final parentMessenger = ScaffoldMessenger.of(context);
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Import Items'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Pick a file and load content
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['json', 'csv', 'txt'],
                        );
                        if (result != null &&
                            result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          final content = await file.readAsString();
                          importController.text = content;
                          // auto-preview
                          try {
                            final preview = await DatabaseService.instance
                                .parseItemsFromContent(content);
                            setDialogState(() {
                              _importPreview = preview;
                            });
                          } catch (e) {
                            setDialogState(() {
                              _importPreview = [];
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Choose file'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final content = importController.text.trim();
                        if (content.isEmpty) {
                          parentMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Paste or choose a file first'),
                            ),
                          );
                          return;
                        }
                        try {
                          final preview = await DatabaseService.instance
                              .parseItemsFromContent(content);
                          setDialogState(() {
                            _importPreview = preview;
                          });
                        } catch (e) {
                          setDialogState(() {
                            _importPreview = [];
                          });
                          parentMessenger.showSnackBar(
                            SnackBar(content: Text('Preview failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.remove_red_eye),
                      label: const Text('Preview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: importController,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Paste JSON or CSV here',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _importPreview == null
                            ? Center(child: Text('Preview will appear here'))
                            : _importPreview!.isEmpty
                            ? Center(child: Text('No preview available'))
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _importPreview!.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 8),
                                  itemBuilder: (context, index) {
                                    final row = _importPreview![index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        row['name']?.toString() ??
                                            row['Name']?.toString() ??
                                            'Unnamed',
                                      ),
                                      subtitle: Text(
                                        'Price: ${row['price'] ?? row['Price'] ?? ''}  •  Category: ${row['category'] ?? row['Category'] ?? ''}',
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final content = importController.text.trim();
                if (content.isEmpty) {
                  parentMessenger.showSnackBar(
                    const SnackBar(content: Text('Paste some content first')),
                  );
                  return;
                }
                try {
                  // Try JSON import first
                  final imported = await DatabaseService.instance
                      .importItemsFromJson(content);
                  if (!mounted) return;
                  parentNavigator.pop();
                  parentMessenger.showSnackBar(
                    SnackBar(content: Text('Imported $imported items (JSON)')),
                  );
                  _loadData();
                } catch (eJson) {
                  // Fallback to CSV
                  try {
                    final imported = await DatabaseService.instance
                        .importItemsFromCsv(content);
                    if (!mounted) return;
                    parentNavigator.pop();
                    parentMessenger.showSnackBar(
                      SnackBar(content: Text('Imported $imported items (CSV)')),
                    );
                    _loadData();
                  } catch (eCsv) {
                    if (!mounted) return;
                    parentMessenger.showSnackBar(
                      SnackBar(content: Text('Import failed: $eCsv')),
                    );
                  }
                }
              },
              child: const Text('Import (JSON/CSV)'),
            ),
          ],
        ),
      ),
    );
  }

  // Local state used only inside import dialog preview
  List<Map<String, dynamic>>? _importPreview;

  Future<IconData?> _showIconPicker(
    BuildContext context,
    IconData current,
  ) async {
    final icons = [
      Icons.shopping_bag,
      Icons.local_cafe,
      Icons.restaurant,
      Icons.cake,
      Icons.local_pizza,
      Icons.icecream,
      Icons.lunch_dining,
      Icons.breakfast_dining,
      Icons.dinner_dining,
      Icons.liquor,
      Icons.local_bar,
      Icons.fastfood,
      Icons.coffee,
      Icons.wine_bar,
      Icons.ramen_dining,
      Icons.emoji_food_beverage,
    ];

    return showDialog<IconData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => Navigator.pop(context, icons[index]),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: icons[index] == current
                          ? const Color(0xFF2563EB)
                          : Colors.grey,
                      width: icons[index] == current ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icons[index], size: 32),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Color?> _showColorPicker(BuildContext context, Color current) async {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
    ];

    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => Navigator.pop(context, colors[index]),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors[index] == current
                          ? Colors.black
                          : Colors.grey,
                      width: colors[index] == current ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') {
                _showImportDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 18, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Import'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search items',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedCategoryFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(cat.icon, color: cat.color, size: 20),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryFilter = value;
                        _filterItems();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty &&
                                  _selectedCategoryFilter == null
                              ? 'No items yet'
                              : 'No items found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty &&
                                  _selectedCategoryFilter == null
                              ? 'Tap + to add your first item'
                              : 'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        child: InkWell(
                          onTap: () => _editItem(item),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: item.color.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            item.icon,
                                            color: item.color,
                                            size: 24,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (item.isFeatured)
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getCategoryName(item.categoryId),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Text(
                                          '${BusinessInfo.instance.currencySymbol}${item.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: item.isAvailable
                                                ? Colors.green.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.red.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            item.isAvailable
                                                ? 'Available'
                                                : 'Unavailable',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: item.isAvailable
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.trackStock) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.inventory_2,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Stock: ${item.stock}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editItem(item);
                                    } else if (value == 'delete') {
                                      _deleteItem(item);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Delete'),
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
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
