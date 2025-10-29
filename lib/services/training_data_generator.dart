import 'dart:math';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../services/database_service.dart';

/// Service to generate sample training data for practice and learning
class TrainingDataGenerator {
  static final TrainingDataGenerator instance = TrainingDataGenerator._init();
  TrainingDataGenerator._init();

  final _random = Random();

  /// Generate sample categories for training
  Future<void> generateSampleCategories() async {
    final categories = _getSampleCategories();
    for (final category in categories) {
      try {
        await DatabaseService.instance.insertCategory(category);
      } catch (e) {
        // Category might already exist, skip
      }
    }
  }

  /// Generate sample items for training
  Future<void> generateSampleItems() async {
    // First ensure categories exist
    final categories = await DatabaseService.instance.getCategories();
    if (categories.isEmpty) {
      await generateSampleCategories();
    }

    final updatedCategories = await DatabaseService.instance.getCategories();
    final items = _getSampleItems(updatedCategories);

    for (final item in items) {
      try {
        await DatabaseService.instance.insertItem(item);
      } catch (e) {
        // Item might already exist, skip
      }
    }
  }

  /// Clear all training data
  Future<void> clearTrainingData() async {
    // Get all items and categories
    final items = await DatabaseService.instance.getItems();
    final categories = await DatabaseService.instance.getCategories();

    // Delete all items
    for (final item in items) {
      await DatabaseService.instance.deleteItem(item.id);
    }

    // Delete all categories
    for (final category in categories) {
      await DatabaseService.instance.deleteCategory(category.id);
    }
  }

  List<Category> _getSampleCategories() {
    return [
      Category(
        id: 'training_cat_${_random.nextInt(100000)}',
        name: 'Beverages',
        description: 'Hot and cold drinks',
        icon: Icons.local_cafe,
        color: Color(0xFF8B4513),
        sortOrder: 1,
        isActive: true,
      ),
      Category(
        id: 'training_cat_${_random.nextInt(100000)}',
        name: 'Food',
        description: 'Meals and snacks',
        icon: Icons.restaurant,
        color: Color(0xFFFF6B35),
        sortOrder: 2,
        isActive: true,
      ),
      Category(
        id: 'training_cat_${_random.nextInt(100000)}',
        name: 'Desserts',
        description: 'Sweet treats',
        icon: Icons.cake,
        color: Color(0xFFF72585),
        sortOrder: 3,
        isActive: true,
      ),
      Category(
        id: 'training_cat_${_random.nextInt(100000)}',
        name: 'Merchandise',
        description: 'Retail products',
        icon: Icons.shopping_bag,
        color: Color(0xFF4361EE),
        sortOrder: 4,
        isActive: true,
      ),
    ];
  }

  List<Item> _getSampleItems(List<Category> categories) {
    if (categories.isEmpty) return [];

    final beverageCategory =
        categories.firstWhere((c) => c.name == 'Beverages', orElse: () => categories.first);
    final foodCategory =
        categories.firstWhere((c) => c.name == 'Food', orElse: () => categories.first);
    final dessertCategory =
        categories.firstWhere((c) => c.name == 'Desserts', orElse: () => categories.first);
    final merchCategory = categories.firstWhere(
        (c) => c.name == 'Merchandise',
        orElse: () => categories.first);

    return [
      // Beverages
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Espresso',
        description: 'Strong coffee shot',
        categoryId: beverageCategory.id,
        price: 3.50,
        cost: 0.80,
        sku: 'BEV-ESP-001',
        icon: Icons.coffee,
        color: Color(0xFF8B4513),
        stock: 100,
        isAvailable: true,
        isFeatured: true,
        trackStock: false,
        sortOrder: 1,
      ),
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Cappuccino',
        description: 'Espresso with steamed milk',
        categoryId: beverageCategory.id,
        price: 4.50,
        cost: 1.20,
        sku: 'BEV-CAP-001',
        icon: Icons.coffee,
        color: Color(0xFF8B4513),
        stock: 100,
        isAvailable: true,
        isFeatured: true,
        trackStock: false,
        sortOrder: 2,
      ),
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Iced Latte',
        description: 'Espresso with cold milk over ice',
        categoryId: beverageCategory.id,
        price: 5.00,
        cost: 1.50,
        sku: 'BEV-LAT-001',
        icon: Icons.local_drink,
        color: Color(0xFF6F4E37),
        stock: 100,
        isAvailable: true,
        isFeatured: false,
        trackStock: false,
        sortOrder: 3,
      ),
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Orange Juice',
        description: 'Freshly squeezed orange juice',
        categoryId: beverageCategory.id,
        price: 4.00,
        cost: 1.00,
        sku: 'BEV-OJ-001',
        icon: Icons.local_drink,
        color: Color(0xFFFFA500),
        stock: 50,
        isAvailable: true,
        isFeatured: false,
        trackStock: true,
        sortOrder: 4,
      ),

      // Food
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Croissant',
        description: 'Buttery French pastry',
        categoryId: foodCategory.id,
        price: 3.00,
        cost: 0.90,
        sku: 'FOOD-CRO-001',
        icon: Icons.bakery_dining,
        color: Color(0xFFFFD700),
        stock: 30,
        isAvailable: true,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Sandwich',
        description: 'Fresh deli sandwich',
        categoryId: foodCategory.id,
        price: 7.50,
        cost: 2.50,
        sku: 'FOOD-SAN-001',
        icon: Icons.lunch_dining,
        color: Color(0xFFCD853F),
        stock: 25,
        isAvailable: true,
        isFeatured: true,
        trackStock: true,
        sortOrder: 2,
      ),
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Salad Bowl',
        description: 'Fresh mixed greens',
        categoryId: foodCategory.id,
        price: 8.00,
        cost: 2.00,
        sku: 'FOOD-SAL-001',
        icon: Icons.set_meal,
        color: Color(0xFF32CD32),
        stock: 20,
        isAvailable: true,
        isFeatured: false,
        trackStock: true,
        sortOrder: 3,
      ),

      // Desserts
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Chocolate Cake',
        description: 'Rich chocolate layer cake',
        categoryId: dessertCategory.id,
        price: 6.50,
        cost: 1.80,
        sku: 'DES-CAK-001',
        icon: Icons.cake,
        color: Color(0xFF8B4513),
        stock: 15,
        isAvailable: true,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Cheesecake',
        description: 'Creamy New York style',
        categoryId: dessertCategory.id,
        price: 7.00,
        cost: 2.00,
        sku: 'DES-CHE-001',
        icon: Icons.cake,
        color: Color(0xFFFFF8DC),
        stock: 12,
        isAvailable: true,
        isFeatured: false,
        trackStock: true,
        sortOrder: 2,
      ),
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Cookie',
        description: 'Freshly baked chocolate chip',
        categoryId: dessertCategory.id,
        price: 2.50,
        cost: 0.60,
        sku: 'DES-COO-001',
        icon: Icons.cookie,
        color: Color(0xFFCD853F),
        stock: 40,
        isAvailable: true,
        isFeatured: false,
        trackStock: true,
        sortOrder: 3,
      ),

      // Merchandise
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'Coffee Mug',
        description: 'Branded ceramic mug',
        categoryId: merchCategory.id,
        price: 12.00,
        cost: 4.00,
        sku: 'MERCH-MUG-001',
        icon: Icons.local_cafe,
        color: Color(0xFF4361EE),
        stock: 25,
        isAvailable: true,
        isFeatured: true,
        trackStock: true,
        sortOrder: 1,
      ),
      Item(
        id: 'training_item_${_random.nextInt(100000)}',
        name: 'T-Shirt',
        description: 'Branded cotton t-shirt',
        categoryId: merchCategory.id,
        price: 20.00,
        cost: 8.00,
        sku: 'MERCH-TSH-001',
        icon: Icons.checkroom,
        color: Color(0xFF4361EE),
        stock: 15,
        isAvailable: true,
        isFeatured: false,
        trackStock: true,
        sortOrder: 2,
      ),
    ];
  }
}

