import 'package:flutter/material.dart';
import '../models/modifier_group_model.dart';
import '../models/modifier_item_model.dart';
import '../models/item_model.dart';
import '../services/database_service.dart';
import '../services/formatting_service.dart';

/// Dialog for selecting modifiers when adding an item to cart
class ModifierSelectionDialog extends StatefulWidget {
  final Item item;
  final String categoryId;
  final Set<String>? initialSelectedItemIds;
  final Map<String, Set<String>>? initialSelectedByGroup; // groupId -> itemIds

  const ModifierSelectionDialog({
    super.key,
    required this.item,
    required this.categoryId,
    this.initialSelectedItemIds,
    this.initialSelectedByGroup,
  });

  @override
  State<ModifierSelectionDialog> createState() => _ModifierSelectionDialogState();
}

class _ModifierSelectionDialogState extends State<ModifierSelectionDialog> {
  List<ModifierGroup> _groups = [];
  Map<String, List<ModifierItem>> _groupItems = {};
  Map<String, List<String>> _selectedModifiers = {}; // groupId -> list of itemIds
  bool _isLoading = true;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadModifiers();
  }

  Future<void> _loadModifiers() async {
    try {
      // Get modifier groups for this category
      final groups = await DatabaseService.instance
          .getModifierGroupsForCategory(widget.categoryId);

      // Load items for each group
      final Map<String, List<ModifierItem>> groupItems = {};
      final Map<String, List<String>> selectedModifiers = {};

      for (final group in groups) {
        final items = await DatabaseService.instance.getModifierItems(group.id);
        groupItems[group.id] = items;

        // Candidate selections
        List<String> selected = [];

        // 1) Use explicit per-group initial selection if provided
        final groupInitial = widget.initialSelectedByGroup != null
            ? widget.initialSelectedByGroup![group.id]
            : null;
        if (groupInitial != null && groupInitial.isNotEmpty) {
          selected = items
              .where((it) => groupInitial.contains(it.id))
              .map((it) => it.id)
              .toList();
        } else if (widget.initialSelectedItemIds != null && widget.initialSelectedItemIds!.isNotEmpty) {
          // 2) Else fallback to global initial item IDs
          selected = items
              .where((it) => widget.initialSelectedItemIds!.contains(it.id))
              .map((it) => it.id)
              .toList();
        } else {
          // 3) Else defaults from the group
          selected = items.where((it) => it.isDefault).map((it) => it.id).toList();
        }

        // Enforce group rules: allowMultiple, min/max, required
        // Max
        if (group.maxSelection != null && selected.length > group.maxSelection!) {
          selected = selected.take(group.maxSelection!).toList();
        }
        // Single-select
        if (!group.allowMultiple && selected.length > 1) {
          selected = selected.isNotEmpty ? [selected.first] : [];
        }
        // If required and empty, choose defaults or first item(s)
        if (group.isRequired && selected.isEmpty) {
          final defaults = items.where((it) => it.isDefault).map((it) => it.id).toList();
          if (defaults.isNotEmpty) {
            if (group.allowMultiple) {
              final cap = group.maxSelection ?? defaults.length;
              selected = defaults.take(cap).toList();
            } else {
              selected = [defaults.first];
            }
          } else {
            // Fallback to first item
            if (items.isNotEmpty) {
              selected = [items.first.id];
            }
          }
        }
        // Min selection topping up
        if (group.minSelection != null && selected.length < group.minSelection!) {
          if (group.allowMultiple) {
            // Add more from defaults then items order until reaching min
            final defaults = items.where((it) => it.isDefault).map((it) => it.id).toList();
            for (final id in defaults) {
              if (selected.length >= group.minSelection!) break;
              if (!selected.contains(id)) selected.add(id);
            }
            for (final it in items) {
              if (selected.length >= group.minSelection!) break;
              if (!selected.contains(it.id)) selected.add(it.id);
            }
            // Respect max if min overshoots
            if (group.maxSelection != null && selected.length > group.maxSelection!) {
              selected = selected.take(group.maxSelection!).toList();
            }
          } else {
            // Single-select cannot meet min>1; pick first if empty
            if (selected.isEmpty && items.isNotEmpty) {
              selected = [items.first.id];
            }
          }
        }

        selectedModifiers[group.id] = selected;
      }

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _groupItems = groupItems;
        _selectedModifiers = selectedModifiers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading modifiers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleModifier(ModifierGroup group, String itemId) {
    setState(() {
      _validationError = null;
      final selected = _selectedModifiers[group.id] ?? [];

      if (group.allowMultiple) {
        // Multi-select mode
        if (selected.contains(itemId)) {
          selected.remove(itemId);
        } else {
          // Check max selection
          if (group.maxSelection != null && selected.length >= group.maxSelection!) {
            _validationError = 'Maximum ${group.maxSelection} selections allowed';
            return;
          }
          selected.add(itemId);
        }
      } else {
        // Single select mode
        if (selected.contains(itemId)) {
          selected.clear(); // Deselect if already selected
        } else {
          selected.clear();
          selected.add(itemId);
        }
      }

      _selectedModifiers[group.id] = selected;
    });
  }

  bool _validateSelections() {
    for (final group in _groups) {
      final selected = _selectedModifiers[group.id] ?? [];
      final count = selected.length;

      // Check required
      if (group.isRequired && count == 0) {
        setState(() {
          _validationError = '${group.name} is required';
        });
        return false;
      }

      // Check min selection
      if (group.minSelection != null && count < group.minSelection!) {
        setState(() {
          _validationError = '${group.name} requires at least ${group.minSelection} selections';
        });
        return false;
      }

      // Check max selection
      if (group.maxSelection != null && count > group.maxSelection!) {
        setState(() {
          _validationError = '${group.name} allows maximum ${group.maxSelection} selections';
        });
        return false;
      }
    }

    return true;
  }

  double _calculateTotalPriceAdjustment() {
    double total = 0.0;
    for (final groupId in _selectedModifiers.keys) {
      final selectedIds = _selectedModifiers[groupId] ?? [];
      final items = _groupItems[groupId] ?? [];
      for (final itemId in selectedIds) {
        final item = items.firstWhere((i) => i.id == itemId, orElse: () => items.first);
        total += item.priceAdjustment;
      }
    }
    return total;
  }

  bool _isSelectionsValid() {
    for (final group in _groups) {
      final selected = _selectedModifiers[group.id] ?? [];
      final count = selected.length;
      if (group.isRequired && count == 0) return false;
      if (group.minSelection != null && count < group.minSelection!) return false;
      if (group.maxSelection != null && count > group.maxSelection!) return false;
    }
    return true;
  }

  List<ModifierItem> _getSelectedModifiersList() {
    final List<ModifierItem> result = [];
    for (final groupId in _selectedModifiers.keys) {
      final selectedIds = _selectedModifiers[groupId] ?? [];
      final items = _groupItems[groupId] ?? [];
      for (final itemId in selectedIds) {
        final item = items.firstWhere((i) => i.id == itemId, orElse: () => items.first);
        result.add(item);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading modifiers...'),
            ],
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      // No modifiers for this item, return null to indicate skip dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(<String, dynamic>{
            'modifiers': <ModifierItem>[],
            'priceAdjustment': 0.0,
          });
        }
      });
      return const SizedBox.shrink();
    }

    final totalAdjustment = _calculateTotalPriceAdjustment();
    final finalPrice = widget.item.price + totalAdjustment;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customize your order',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modifier groups list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in _groups) ...[
                      _buildModifierGroup(group),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // Validation error
            if (_validationError != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Footer with price and confirm button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Base Price: ${FormattingService.currency(widget.item.price)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (totalAdjustment != 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Modifiers: ${totalAdjustment > 0 ? '+' : ''}${FormattingService.currency(totalAdjustment)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: totalAdjustment > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${FormattingService.currency(finalPrice)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSelectionsValid()
                        ? () {
                            if (_validateSelections()) {
                              Navigator.of(context).pop(<String, dynamic>{
                                'modifiers': _getSelectedModifiersList(),
                                'priceAdjustment': totalAdjustment,
                              });
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModifierGroup(ModifierGroup group) {
    final items = _groupItems[group.id] ?? [];
    final selected = _selectedModifiers[group.id] ?? [];
    final selectedCount = selected.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Selected count chip
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$selectedCount selected',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: group.isRequired ? Colors.red.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                group.getSelectionHint(),
                style: TextStyle(
                  fontSize: 11,
                  color: group.isRequired ? Colors.red.shade900 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (group.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            group.description,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 12),

        // Modifier items
        ...items.map((item) {
          final isSelected = selected.contains(item.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 2 : 0,
            color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.1) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => _toggleModifier(group, item.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Selection indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: group.allowMultiple ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: group.allowMultiple ? BorderRadius.circular(4) : null,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
                          width: 2,
                        ),
                        color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Item name and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Price adjustment
                    if (item.priceAdjustment != 0)
                      Text(
                        item.getPriceAdjustmentDisplay(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.priceAdjustment > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
