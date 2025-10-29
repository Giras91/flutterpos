import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/payment_method_model.dart';

void main() {
  // Initialize sqflite FFI for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService.saveCompletedSale', () {
    setUpAll(() async {
      final tmp = await Directory.systemTemp.createTemp('extropos_test_');
      final dbFile = p.join(tmp.path, 'extropos.db');
      DatabaseHelper.overrideDatabaseFilePath(dbFile);
      await DatabaseHelper.instance.resetDatabase();
    });

    test('happy path: saves order, items and transaction', () async {
      final dbService = DatabaseService.instance;

      // Create a category with a unique id to avoid collisions when tests run repeatedly
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString();
      final category = Category(
        id: 'cat-$uniqueSuffix',
        name: 'Beverages',
        description: 'Drinks',
        icon: Icons.local_cafe,
        color: Colors.brown,
      );
      await dbService.insertCategory(category);

      // Insert an item in DB
      final item = Item(
        id: 'item-$uniqueSuffix',
        name: 'Test Coffee',
        description: 'Tasty',
        price: 3.5,
        categoryId: category.id,
        icon: Icons.local_cafe,
        color: Colors.brown,
      );
      await dbService.insertItem(item);

      // Prepare cart item with a Product that matches DB item name
      final product = Product(item.name, item.price, category.name, item.icon);
      final cartItem = CartItem(product, 2);

      final subtotal = cartItem.totalPrice;
      final tax = 0.0;
      final serviceCharge = 0.0;
      final total = subtotal;

      final paymentMethod = PaymentMethod(id: '1', name: 'Cash');

      final orderNumber = await dbService.saveCompletedSale(
        cartItems: [cartItem],
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: total,
        paymentMethod: paymentMethod,
        amountPaid: total,
        change: 0.0,
        orderType: 'retail',
      );

      expect(orderNumber, isNotNull);

      // Verify order exists and related rows
      final orders = await dbService.getRecentOrders(limit: 10);
      final orderMap = orders.firstWhere((o) => o['order_number'] == orderNumber, orElse: () => {});
      expect(orderMap.isNotEmpty, isTrue);

      final orderId = orderMap['id'] as String;

      final items = await dbService.getOrderItems(orderId);
      expect(items.length, 1);
      expect(items.first['item_name'], item.name);

      final txs = await dbService.getTransactionsForOrder(orderId);
      expect(txs.length, 1);
      expect((txs.first['amount'] as num).toDouble(), total);
    });

    test('unmapped items should skip persistence (return null)', () async {
      final dbService = DatabaseService.instance;

      final product = Product('Nonexistent Item', 5.0, 'Misc', Icons.help);
      final cartItem = CartItem(product, 1);

      final subtotal = cartItem.totalPrice;
      final orderNumber = await dbService.saveCompletedSale(
        cartItems: [cartItem],
        subtotal: subtotal,
        tax: 0.0,
        serviceCharge: 0.0,
        total: subtotal,
        paymentMethod: PaymentMethod(id: '1', name: 'Cash'),
        amountPaid: subtotal,
        change: 0.0,
      );

      expect(orderNumber, isNull);
    });
  });
}
