import 'package:flutter/material.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String? sku;
  final String? barcode;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final bool isFeatured;
  final int stock;
  final bool trackStock;
  final double? cost;
  final String? imageUrl;
  final List<String> tags;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.sku,
    this.barcode,
    required this.icon,
    required this.color,
    this.isAvailable = true,
    this.isFeatured = false,
    this.stock = 0,
    this.trackStock = false,
    this.cost,
    this.imageUrl,
    this.tags = const [],
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Item copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? sku,
    String? barcode,
    IconData? icon,
    Color? color,
    bool? isAvailable,
    bool? isFeatured,
    int? stock,
    bool? trackStock,
    double? cost,
    String? imageUrl,
    List<String>? tags,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      stock: stock ?? this.stock,
      trackStock: trackStock ?? this.trackStock,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'sku': sku,
      'barcode': barcode,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.toARGB32(),
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'stock': stock,
      'trackStock': trackStock,
      'cost': cost,
      'imageUrl': imageUrl,
      'tags': tags,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
      ),
      color: Color(json['colorValue'] as int),
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      stock: json['stock'] as int? ?? 0,
      trackStock: json['trackStock'] as bool? ?? false,
      cost: (json['cost'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  double get profit => cost != null ? price - cost! : 0;
  double get profitMargin => cost != null && cost! > 0 ? ((price - cost!) / cost!) * 100 : 0;
}
