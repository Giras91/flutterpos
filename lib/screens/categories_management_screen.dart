import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/guide_service.dart';
import '../widgets/guide_widgets.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  final List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    try {
      final categories = await DatabaseService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories.clear();
        _categories.addAll(categories);
        _filteredCategories = List.from(_categories);
      });
    } catch (e) {
      if (!mounted) return;
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
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
            sortOrder: 1,
          ),
          Category(
            id: '2',
            name: 'Food',
            description: 'Main dishes and snacks',
            icon: Icons.restaurant,
            color: Colors.orange,
            sortOrder: 2,
          ),
          Category(
            id: '3',
            name: 'Desserts',
            description: 'Sweet treats',
            icon: Icons.cake,
            color: Colors.pink,
            sortOrder: 3,
          ),
        ]);
        _filteredCategories = List.from(_categories);
      });
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = List.from(_categories);
      } else {
        _filteredCategories = _categories
            .where((category) =>
                category.name.toLowerCase().contains(query) ||
                category.description.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _addCategory() {
    _showCategoryDialog();
  }

  void _editCategory(Category category) {
    _showCategoryDialog(category: category);
  }

  void _deleteCategory(Category category) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DatabaseService.instance.deleteCategory(category.id);
                setState(() {
                  _categories.remove(category);
                  _filterCategories();
                });
                if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${category.name} deleted')),
                  );
              } catch (e) {
                if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting category: $e'),
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

  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    IconData selectedIcon = category?.icon ?? Icons.category;
    Color selectedColor = category?.color ?? Colors.blue;
    int sortOrder = category?.sortOrder ?? _categories.length + 1;
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
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
                  InkWell(
                    onTap: () async {
                      final icon = await _showIconPicker(context, selectedIcon);
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
                          const Text('Tap to change icon'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final color = await _showColorPicker(context, selectedColor);
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
                          const Text('Tap to change color'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: sortOrder.toString()),
                    onChanged: (value) {
                      sortOrder = int.tryParse(value) ?? sortOrder;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Show this category in POS'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
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
                    const SnackBar(content: Text('Please enter a category name')),
                  );
                  return;
                }

                final newCategory = Category(
                  id: category?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descController.text,
                  icon: selectedIcon,
                  color: selectedColor,
                  sortOrder: sortOrder,
                  isActive: isActive,
                  createdAt: category?.createdAt,
                );

                try {
                  if (isEditing) {
                    await DatabaseService.instance.updateCategory(newCategory);
                  } else {
                    await DatabaseService.instance.insertCategory(newCategory);
                  }

                  setState(() {
                    if (isEditing) {
                      final index = _categories.indexWhere((c) => c.id == category.id);
                      if (index != -1) {
                        _categories[index] = newCategory;
                      }
                    } else {
                      _categories.add(newCategory);
                    }
                    _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                    _filterCategories();
                  });

                  if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'Category updated successfully'
                            : 'Category added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                } catch (e) {
                  if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving category: $e'),
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

  Future<IconData?> _showIconPicker(BuildContext context, IconData current) async {
    final icons = [
      Icons.category,
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
      Icons.ramen_dining,
      Icons.emoji_food_beverage,
      Icons.wine_bar,
      Icons.coffee,
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
                      color: colors[index] == current ? Colors.black : Colors.grey,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search categories',
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
          Expanded(
            child: _filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No categories yet'
                              : 'No categories found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Tap + to add your first category'
                              : 'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCategories.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex--;
                        }
                        final category = _filteredCategories.removeAt(oldIndex);
                        _filteredCategories.insert(newIndex, category);

                        // Update sort orders
                        for (int i = 0; i < _filteredCategories.length; i++) {
                          final index = _categories.indexWhere(
                              (c) => c.id == _filteredCategories[i].id);
                          if (index != -1) {
                            _categories[index] = _categories[index].copyWith(
                              sortOrder: i + 1,
                            );
                          }
                        }
                      });
                    },
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      return Card(
                        key: ValueKey(category.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              category.icon,
                              color: category.color,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.description),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: category.isActive
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      category.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: category.isActive
                                            ? Colors.green[700]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Order: ${category.sortOrder}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editCategory(category),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCategory(category),
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
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
        onPressed: _addCategory,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FloatingGuideButton(
              onPressed: () async {
                final steps = PredefinedGuides.getGuideSteps('categories_setup');
                if (steps.isNotEmpty) {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => InteractiveGuideOverlay(
                      guideName: 'Categories Setup Guide',
                      steps: steps,
                      onComplete: () {
                        GuideService.instance.markGuideCompleted('categories_setup');
                        Navigator.of(context).pop();
                      },
                      onSkip: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }
              },
              tooltip: 'Show Categories Guide',
            ),
          ],
        ),
      ),
    );
  }
}
