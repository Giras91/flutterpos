import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:flutter/material.dart';

void main() {
  // Initialize sqflite FFI for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService.exportOrdersCsv', () {
    setUpAll(() async {
      final tmp = await Directory.systemTemp.createTemp('extropos_test_');
      final dbFile = p.join(tmp.path, 'extropos.db');
      DatabaseHelper.overrideDatabaseFilePath(dbFile);
      await DatabaseHelper.instance.resetDatabase();
    });

    test('exports a detailed CSV containing order and item rows', () async {
      final dbService = DatabaseService.instance;

      final unique = DateTime.now().millisecondsSinceEpoch.toString();

      // Create category
      final category = Category(
        id: 'cat-$unique',
        name: 'Beverages',
        description: 'Drinks',
        icon: Icons.local_cafe,
        color: Colors.brown,
      );
      await dbService.insertCategory(category);

      // Insert item
      final item = Item(
        id: 'item-$unique',
        name: 'Export Coffee',
        description: 'For export test',
        price: 4.25,
        categoryId: category.id,
        icon: Icons.local_cafe,
        color: Colors.brown,
      );
      await dbService.insertItem(item);

      // Prepare cart item and save a completed sale
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

      // Export CSV covering a broad range
      final csv = await dbService.exportOrdersCsv(
        from: DateTime.now().subtract(const Duration(days: 1)),
        to: DateTime.now().add(const Duration(days: 1)),
        paymentMethodId: null,
        limit: 1000,
      );

      expect(csv, isNotNull);
      expect(csv.contains('order_number'), isTrue);
      expect(csv.contains(item.name), isTrue, reason: 'CSV should contain the exported item name');
      expect(csv.contains(orderNumber!), isTrue, reason: 'CSV should contain the generated order number');
    });
  });
}
