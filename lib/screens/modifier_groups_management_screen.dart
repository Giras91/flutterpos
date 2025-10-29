import 'package:flutter/material.dart';
import '../models/modifier_group_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import 'modifier_items_management_screen.dart';

class ModifierGroupsManagementScreen extends StatefulWidget {
  const ModifierGroupsManagementScreen({super.key});

  @override
  State<ModifierGroupsManagementScreen> createState() =>
      _ModifierGroupsManagementScreenState();
}

class _ModifierGroupsManagementScreenState
    extends State<ModifierGroupsManagementScreen> {
  final List<ModifierGroup> _groups = [];
  final List<Category> _categories = [];
  List<ModifierGroup> _filteredGroups = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    try {
      final groups = await DatabaseService.instance.getModifierGroups();
      final categories = await DatabaseService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _groups.clear();
        _groups.addAll(groups);
        _categories.clear();
        _categories.addAll(categories);
        _filteredGroups = List.from(_groups);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading modifier groups: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = List.from(_groups);
      } else {
        _filteredGroups = _groups
            .where((group) =>
                group.name.toLowerCase().contains(query) ||
                group.description.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _showGroupDialog({ModifierGroup? group}) {
    final isEditing = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    final descController = TextEditingController(text: group?.description ?? '');
    final minController =
        TextEditingController(text: group?.minSelection?.toString() ?? '0');
    final maxController =
        TextEditingController(text: group?.maxSelection?.toString() ?? '1');
    
    bool isRequired = group?.isRequired ?? false;
    bool allowMultiple = group?.allowMultiple ?? false;
    int sortOrder = group?.sortOrder ?? 0;
    List<String> selectedCategories = List.from(group?.categoryIds ?? []);

    final parentMessenger = ScaffoldMessenger.of(context);
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Modifier Group' : 'Add Modifier Group'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name *',
                      hintText: 'e.g., Size, Add-ons, Temperature',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Applies to Categories',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave empty to apply to all categories',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = selectedCategories.contains(cat.id);
                      return FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedCategories.add(cat.id);
                            } else {
                              selectedCategories.remove(cat.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Required'),
                    subtitle: const Text('Customer must make a selection'),
                    value: isRequired,
                    onChanged: (value) {
                      setDialogState(() => isRequired = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Allow Multiple'),
                    subtitle: const Text('Can select multiple modifiers'),
                    value: allowMultiple,
                    onChanged: (value) {
                      setDialogState(() => allowMultiple = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          decoration: const InputDecoration(
                            labelText: 'Min Selection',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          decoration: const InputDecoration(
                            labelText: 'Max Selection',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      sortOrder = int.tryParse(value) ?? 0;
                    },
                    controller: TextEditingController(text: sortOrder.toString()),
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
                    const SnackBar(content: Text('Please enter a group name')),
                  );
                  return;
                }

                final newGroup = ModifierGroup(
                  id: group?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: descController.text.trim(),
                  categoryIds: selectedCategories,
                  isRequired: isRequired,
                  allowMultiple: allowMultiple,
                  minSelection: int.tryParse(minController.text),
                  maxSelection: int.tryParse(maxController.text),
                  sortOrder: sortOrder,
                  createdAt: group?.createdAt,
                );

                try {
                  if (isEditing) {
                    await DatabaseService.instance.updateModifierGroup(newGroup);
                  } else {
                    await DatabaseService.instance.insertModifierGroup(newGroup);
                  }

                  if (!mounted) return;
                  parentNavigator.pop();
                  _loadData();

                  parentMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          'Modifier group ${isEditing ? 'updated' : 'created'} successfully'),
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

  void _deleteGroup(ModifierGroup group) {
    final parentMessenger = ScaffoldMessenger.of(context);
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Modifier Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This will also delete all modifiers in this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await DatabaseService.instance.deleteModifierGroup(group.id);
                if (!mounted) return;
                parentNavigator.pop();
                _loadData();
                parentMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Modifier group deleted successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                parentNavigator.pop();
                parentMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error deleting group: $e'),
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

  String _getCategoriesDisplay(List<String> categoryIds) {
    if (categoryIds.isEmpty) return 'All Categories';
    final categoryNames = categoryIds.map((id) {
      final cat = _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => Category(
          id: id,
          name: 'Unknown',
          description: '',
          icon: Icons.help,
          color: Colors.grey,
        ),
      );
      return cat.name;
    }).toList();
    return categoryNames.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier Groups'),
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
                labelText: 'Search modifier groups',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_filteredGroups.length} modifier groups',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _groups.isEmpty
                              ? 'No modifier groups yet'
                              : 'No matching groups found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_groups.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to create your first modifier group',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = _filteredGroups[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2563EB),
                            child: const Icon(
                              Icons.category,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            group.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (group.description.isNotEmpty)
                                Text(group.description),
                              const SizedBox(height: 4),
                              Text(
                                _getCategoriesDisplay(group.categoryIds),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (group.isRequired)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Required',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                  if (group.allowMultiple) ...[
                                    if (group.isRequired) const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Multi-select',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF2563EB)),
                                onPressed: () => _showGroupDialog(group: group),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteGroup(group),
                              ),
                            ],
                          ),
                          onTap: () {
                            // Navigate to modifier items for this group
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModifierItemsManagementScreen(
                                  group: group,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupDialog(),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      ),
    );
  }
}
