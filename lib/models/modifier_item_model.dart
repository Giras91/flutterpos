import 'package:flutter/material.dart';
import 'business_info_model.dart';

/// Represents an individual modifier option (e.g., "Large", "Extra Cheese", "No Onions")
class ModifierItem {
  final String id;
  final String modifierGroupId;
  final String name;
  final String description;
  final double priceAdjustment; // Price to add/subtract (can be negative)
  final IconData? icon;
  final Color? color;
  final bool isDefault; // Auto-selected by default
  final bool isAvailable;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModifierItem({
    required this.id,
    required this.modifierGroupId,
    required this.name,
    this.description = '',
    this.priceAdjustment = 0.0,
    this.icon,
    this.color,
    this.isDefault = false,
    this.isAvailable = true,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  ModifierItem copyWith({
    String? id,
    String? modifierGroupId,
    String? name,
    String? description,
    double? priceAdjustment,
    IconData? icon,
    Color? color,
    bool? isDefault,
    bool? isAvailable,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModifierItem(
      id: id ?? this.id,
      modifierGroupId: modifierGroupId ?? this.modifierGroupId,
      name: name ?? this.name,
      description: description ?? this.description,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modifier_group_id': modifierGroupId,
      'name': name,
      'description': description,
      'price_adjustment': priceAdjustment,
      'icon_code_point': icon?.codePoint,
      'icon_font_family': icon?.fontFamily,
      'color_value': color?.toARGB32(),
      'is_default': isDefault ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ModifierItem.fromJson(Map<String, dynamic> json) {
    return ModifierItem(
      id: json['id'] as String,
      modifierGroupId: json['modifier_group_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon_code_point'] != null
          ? IconData(
              json['icon_code_point'] as int,
              fontFamily: json['icon_font_family'] as String?,
            )
          : null,
      color: json['color_value'] != null
          ? Color(json['color_value'] as int)
          : null,
      isDefault: (json['is_default'] as int?) == 1,
      isAvailable: (json['is_available'] as int?) == 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String getPriceAdjustmentDisplay() {
    if (priceAdjustment == 0) {
      return '';
    }
    final currency = BusinessInfo.instance.currencySymbol;
    if (priceAdjustment > 0) {
      return '+$currency${priceAdjustment.toStringAsFixed(2)}';
    }
    return '$currency${priceAdjustment.toStringAsFixed(2)}';
  }
}
