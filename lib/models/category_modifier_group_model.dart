/// Represents the link between a category and a modifier group
/// This allows specific categories to have specific modifier groups available
class CategoryModifierGroup {
  final String id;
  final String categoryId;
  final String modifierGroupId;
  final bool isRequired; // Override modifier group's isRequired for this category
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModifierGroup({
    required this.id,
    required this.categoryId,
    required this.modifierGroupId,
    this.isRequired = false,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  CategoryModifierGroup copyWith({
    String? id,
    String? categoryId,
    String? modifierGroupId,
    bool? isRequired,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModifierGroup(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      modifierGroupId: modifierGroupId ?? this.modifierGroupId,
      isRequired: isRequired ?? this.isRequired,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'modifier_group_id': modifierGroupId,
      'is_required': isRequired ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CategoryModifierGroup.fromJson(Map<String, dynamic> json) {
    return CategoryModifierGroup(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      modifierGroupId: json['modifier_group_id'] as String,
      isRequired: (json['is_required'] as int?) == 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
