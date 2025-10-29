/// Represents a group of modifiers (e.g., "Size", "Toppings", "Add-ons")
class ModifierGroup {
  final String id;
  final String name;
  final String description;
  
  /// Linked category IDs - if empty, applies to all categories
  final List<String> categoryIds;
  
  final bool isRequired; // Customer must select at least one
  final bool allowMultiple; // Can select multiple modifiers
  final int? minSelection; // Minimum number of selections (null = no minimum)
  final int? maxSelection; // Maximum number of selections (null = unlimited)
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModifierGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.categoryIds = const [],
    this.isRequired = false,
    this.allowMultiple = false,
    this.minSelection,
    this.maxSelection,
    this.sortOrder = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ModifierGroup copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? categoryIds,
    bool? isRequired,
    bool? allowMultiple,
    int? minSelection,
    int? maxSelection,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModifierGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryIds: categoryIds ?? this.categoryIds,
      isRequired: isRequired ?? this.isRequired,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      minSelection: minSelection ?? this.minSelection,
      maxSelection: maxSelection ?? this.maxSelection,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_ids': categoryIds.join(','), // Store as comma-separated
      'is_required': isRequired ? 1 : 0,
      'allow_multiple': allowMultiple ? 1 : 0,
      'min_selection': minSelection,
      'max_selection': maxSelection,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    return ModifierGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      categoryIds: json['category_ids'] != null && (json['category_ids'] as String).isNotEmpty
          ? (json['category_ids'] as String).split(',')
          : [],
      isRequired: (json['is_required'] as int?) == 1,
      allowMultiple: (json['allow_multiple'] as int?) == 1,
      minSelection: json['min_selection'] as int?,
      maxSelection: json['max_selection'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Validates if a selection count is valid for this group
  bool isValidSelection(int count) {
    if (isRequired && count == 0) return false;
    if (minSelection != null && count < minSelection!) return false;
    if (maxSelection != null && count > maxSelection!) return false;
    return true;
  }

  String getSelectionHint() {
    if (isRequired && !allowMultiple) {
      return 'Required - Select 1';
    } else if (isRequired && allowMultiple) {
      if (minSelection != null && maxSelection != null) {
        return 'Required - Select $minSelection to $maxSelection';
      } else if (minSelection != null) {
        return 'Required - Select at least $minSelection';
      } else if (maxSelection != null) {
        return 'Required - Select up to $maxSelection';
      } else {
        return 'Required - Select any';
      }
    } else if (!isRequired && allowMultiple) {
      if (maxSelection != null) {
        return 'Optional - Select up to $maxSelection';
      } else {
        return 'Optional - Select any';
      }
    } else {
      return 'Optional - Select 1';
    }
  }

  /// Check if this modifier group applies to a specific category
  bool appliesToCategory(String categoryId) {
    // If no categories specified, applies to all
    if (categoryIds.isEmpty) return true;
    return categoryIds.contains(categoryId);
  }
}
