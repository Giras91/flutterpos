import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../models/payment_method_model.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../models/receipt_settings_model.dart';
import '../models/modifier_group_model.dart';
import '../models/modifier_item_model.dart';
import '../models/printer_model.dart';
import '../models/user_model.dart';
import '../models/table_model.dart';
import '../models/business_info_model.dart';
import 'database_helper.dart';

/// Service layer for database operations
/// Provides clean CRUD methods for all entities
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  // ==================== CATEGORIES ====================

  /// Get all categories ordered by sort_order
  Future<List<Category>> getCategories() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) {
      return Category(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        description: (maps[i]['description'] as String?) ?? '',
        icon: _iconFromDb(
          maps[i]['icon_code_point'] as int?,
          maps[i]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[i]['color_value'] as int?),
        sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
        isActive: (maps[i]['is_active'] as int?) == 1,
      );
    });
  }

  /// Get a single category by ID
  Future<Category?> getCategoryById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Category(
      id: maps[0]['id'].toString(),
      name: maps[0]['name'] as String,
      description: (maps[0]['description'] as String?) ?? '',
      icon: _iconFromDb(
        maps[0]['icon_code_point'] as int?,
        maps[0]['icon_font_family'] as String?,
      ),
      color: _colorFromDb(maps[0]['color_value'] as int?),
      sortOrder: (maps[0]['sort_order'] as int?) ?? 0,
      isActive: (maps[0]['is_active'] as int?) == 1,
    );
  }

  /// Insert a new category
  Future<int> insertCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('categories', {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'icon_code_point': category.icon.codePoint,
      'icon_font_family': category.icon.fontFamily,
      'color_value': category.color.toARGB32(),
      'sort_order': category.sortOrder,
      'is_active': category.isActive ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update an existing category
  Future<int> updateCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'categories',
      {
        'name': category.name,
        'description': category.description,
        'icon_code_point': category.icon.codePoint,
        'icon_font_family': category.icon.fontFamily,
        'color_value': category.color.toARGB32(),
        'sort_order': category.sortOrder,
        'is_active': category.isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete a category (soft delete by setting is_active = 0)
  Future<int> deleteCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'categories',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently delete a category
  Future<int> permanentlyDeleteCategory(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ITEMS ====================

  /// Get all items
  Future<List<Item>> getItems({String? categoryId}) async {
    final db = await DatabaseHelper.instance.database;

    String? where;
    List<dynamic>? whereArgs;

    if (categoryId != null) {
      where = 'category_id = ? AND is_available = ?';
      whereArgs = [categoryId, 1];
    } else {
      where = 'is_available = ?';
      whereArgs = [1];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        description: (maps[i]['description'] as String?) ?? '',
        categoryId: maps[i]['category_id']?.toString() ?? '',
        price: (maps[i]['price'] as num).toDouble(),
        cost: (maps[i]['cost'] as num?)?.toDouble(),
        sku: maps[i]['sku'] as String?,
        barcode: maps[i]['barcode'] as String?,
        icon: _iconFromDb(
          maps[i]['icon_code_point'] as int?,
          maps[i]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[i]['color_value'] as int?),
        imageUrl: maps[i]['image_url'] as String?,
        stock: (maps[i]['stock'] as int?) ?? 0,
        isAvailable: (maps[i]['is_available'] as int?) == 1,
        isFeatured: (maps[i]['is_featured'] as int?) == 1,
        trackStock: (maps[i]['track_stock'] as int?) == 1,
        sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
      );
    });
  }

  /// Get a single item by ID
  Future<Item?> getItemById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Item(
      id: maps[0]['id'].toString(),
      name: maps[0]['name'] as String,
      description: (maps[0]['description'] as String?) ?? '',
      categoryId: maps[0]['category_id']?.toString() ?? '',
      price: (maps[0]['price'] as num).toDouble(),
      cost: (maps[0]['cost'] as num?)?.toDouble(),
      sku: maps[0]['sku'] as String?,
      barcode: maps[0]['barcode'] as String?,
      icon: _iconFromDb(
        maps[0]['icon_code_point'] as int?,
        maps[0]['icon_font_family'] as String?,
      ),
      color: _colorFromDb(maps[0]['color_value'] as int?),
      imageUrl: maps[0]['image_url'] as String?,
      stock: (maps[0]['stock'] as int?) ?? 0,
      isAvailable: (maps[0]['is_available'] as int?) == 1,
      isFeatured: (maps[0]['is_featured'] as int?) == 1,
      trackStock: (maps[0]['track_stock'] as int?) == 1,
      sortOrder: (maps[0]['sort_order'] as int?) ?? 0,
    );
  }

  /// Import items from a JSON string. JSON can be a list of item objects or
  /// a wrapper object containing an `items` array. Returns number of items
  /// successfully imported.
  Future<int> importItemsFromJson(String jsonString) async {
    final db = await DatabaseHelper.instance.database;
    final dynamic parsed = jsonDecode(jsonString);
    final List<dynamic> list;

    if (parsed is List) {
      list = parsed;
    } else if (parsed is Map && parsed['items'] is List) {
      list = parsed['items'] as List<dynamic>;
    } else {
      throw FormatException('Invalid JSON format for items import');
    }

    int imported = 0;

    for (final raw in list) {
      try {
        final Map<String, dynamic> obj = Map<String, dynamic>.from(raw as Map);
        final name = (obj['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final price = (obj['price'] != null)
            ? (obj['price'] is num
                  ? (obj['price'] as num).toDouble()
                  : double.tryParse(obj['price'].toString()) ?? 0.0)
            : 0.0;

        final categoryName = (obj['category'] ?? 'Uncategorized').toString();

        // Resolve or create category
        String categoryId;
        final existing = await db.query(
          'categories',
          where: 'name = ?',
          whereArgs: [categoryName],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          categoryId = existing[0]['id'] as String;
        } else {
          categoryId = DateTime.now().millisecondsSinceEpoch.toString();
          final category = Category(
            id: categoryId,
            name: categoryName,
            description: (obj['category_description'] ?? '').toString(),
            icon: Icons.category,
            color: Colors.blue,
          );
          await insertCategory(category);
        }

        final itemId =
            (obj['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
                .toString();

        final item = Item(
          id: itemId,
          name: name,
          description: (obj['description'] ?? '').toString(),
          price: price,
          categoryId: categoryId,
          sku: obj['sku']?.toString(),
          barcode: obj['barcode']?.toString(),
          icon: Icons.shopping_bag,
          color: Colors.blue,
          isAvailable: (obj['isAvailable'] == null)
              ? true
              : (obj['isAvailable'] == true || obj['isAvailable'] == 1),
          isFeatured: (obj['isFeatured'] == true || obj['isFeatured'] == 1),
          trackStock: (obj['trackStock'] == true || obj['trackStock'] == 1),
          stock: (obj['stock'] is int)
              ? obj['stock'] as int
              : int.tryParse(obj['stock']?.toString() ?? '') ?? 0,
          cost: (obj['cost'] != null)
              ? (obj['cost'] is num
                    ? (obj['cost'] as num).toDouble()
                    : double.tryParse(obj['cost'].toString()))
              : null,
        );

        await insertItem(item);
        imported++;
      } catch (e) {
        // Ignore individual item import errors and continue
        debugPrint('Import item failed: $e');
        continue;
      }
    }

    return imported;
  }

  /// Import items from a simple CSV string. Header row is expected. Returns
  /// number of items imported. This is intentionally forgiving and supports
  /// comma separated values with a header including at least `name` and `price`.
  Future<int> importItemsFromCsv(String csv) async {
    // Use the csv package which supports quoted fields and multiline cells
    final converter = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    );
    final List<List<dynamic>> rows;
    try {
      rows = converter.convert(csv);
    } catch (e) {
      // Fallback to simple split if parsing fails
      final lines = csv
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) return 0;
      final header = _splitCsvLine(lines.first);
      final parsedFallback = <Map<String, String>>[];
      for (final row in lines.skip(1)) {
        final cols = _splitCsvLine(row);
        final map = <String, String>{};
        for (int i = 0; i < header.length && i < cols.length; i++) {
          map[header[i].toLowerCase()] = cols[i];
        }
        parsedFallback.add(map);
      }
      return await importItemsFromJson(jsonEncode(parsedFallback));
    }

    if (rows.isEmpty) return 0;

    final header = rows.first
        .map((e) => e?.toString().trim().toLowerCase() ?? '')
        .toList();
    final parsed = <Map<String, String>>[];
    for (final r in rows.skip(1)) {
      final map = <String, String>{};
      for (int i = 0; i < header.length && i < r.length; i++) {
        map[header[i]] = r[i]?.toString() ?? '';
      }
      parsed.add(map);
    }

    return await importItemsFromJson(jsonEncode(parsed));
  }

  List<String> _splitCsvLine(String line) {
    final List<String> parts = [];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (char == ',' && !inQuotes) {
        parts.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    parts.add(buffer.toString().trim());
    return parts;
  }

  /// Parse content that may be JSON or CSV into a list of item-like maps.
  /// This does NOT insert into the database. Used for previews in the UI.
  Future<List<Map<String, dynamic>>> parseItemsFromContent(
    String content,
  ) async {
    // Try JSON first
    try {
      final parsed = jsonDecode(content);
      List<dynamic> list;
      if (parsed is List) {
        list = parsed;
      } else if (parsed is Map && parsed['items'] is List) {
        list = parsed['items'] as List<dynamic>;
      } else {
        throw FormatException('Unknown JSON structure');
      }

      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      // Fallback to CSV parsing using csv package for robust handling
      try {
        final converter = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        );
        final rows = converter.convert(content);
        if (rows.isEmpty) return [];
        final header = rows.first
            .map((e) => e?.toString().toLowerCase() ?? '')
            .toList();
        final parsed = <Map<String, dynamic>>[];
        for (final r in rows.skip(1)) {
          final map = <String, dynamic>{};
          for (int i = 0; i < header.length && i < r.length; i++) {
            map[header[i]] = r[i]?.toString() ?? '';
          }
          parsed.add(map);
        }
        return parsed;
      } catch (e) {
        // If csv parsing fails, return empty list
        return [];
      }
    }
  }

  /// Insert a new item
  Future<int> insertItem(Item item) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('items', {
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'category_id': item.categoryId,
      'price': item.price,
      'cost': item.cost,
      'sku': item.sku,
      'barcode': item.barcode,
      'icon_code_point': item.icon.codePoint,
      'icon_font_family': item.icon.fontFamily,
      'color_value': item.color.toARGB32(),
      'image_url': item.imageUrl,
      'stock': item.trackStock ? item.stock : 0,
      'is_available': item.isAvailable ? 1 : 0,
      'is_featured': item.isFeatured ? 1 : 0,
      'track_stock': item.trackStock ? 1 : 0,
      'sort_order': item.sortOrder,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update an existing item
  Future<int> updateItem(Item item) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'items',
      {
        'name': item.name,
        'description': item.description,
        'category_id': item.categoryId,
        'price': item.price,
        'cost': item.cost,
        'sku': item.sku,
        'barcode': item.barcode,
        'icon_code_point': item.icon.codePoint,
        'icon_font_family': item.icon.fontFamily,
        'color_value': item.color.toARGB32(),
        'image_url': item.imageUrl,
        'stock': item.stock,
        'is_available': item.isAvailable ? 1 : 0,
        'is_featured': item.isFeatured ? 1 : 0,
        'track_stock': item.trackStock ? 1 : 0,
        'sort_order': item.sortOrder,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete an item (soft delete)
  Future<int> deleteItem(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'items',
      {'is_available': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update item stock quantity
  Future<int> updateItemStock(String id, int quantity) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'items',
      {'stock': quantity, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== RECEIPT SETTINGS ====================

  /// Get receipt settings
  Future<ReceiptSettings> getReceiptSettings() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipt_settings',
      limit: 1,
    );

    if (maps.isEmpty) {
      // Return default settings
      return ReceiptSettings();
    }

    return ReceiptSettings(
      showLogo: maps[0]['show_logo'] == 1,
      showDateTime: maps[0]['show_date_time'] == 1,
      showOrderNumber: maps[0]['show_order_number'] == 1,
      showCashierName: maps[0]['show_cashier_name'] == 1,
      showTaxBreakdown: maps[0]['show_tax_breakdown'] == 1,
      showServiceChargeBreakdown:
          (maps[0]['show_service_charge_breakdown'] as int?) != 0,
      showThankYouMessage: maps[0]['show_thank_you_message'] == 1,
      autoPrint: maps[0]['auto_print'] == 1,
      paperSize: ReceiptPaperSize.values.firstWhere(
        (e) => e.name == (maps[0]['paper_size'] as String? ?? 'mm80'),
        orElse: () => ReceiptPaperSize.mm80,
      ),
      paperWidth: (maps[0]['paper_width'] as int?) ?? 80,
      fontSize: (maps[0]['font_size'] as int?) ?? 12,
      headerText: maps[0]['header_text'] ?? 'ExtroPOS',
      footerText: maps[0]['footer_text'] ?? 'Thank you for your business!',
      thankYouMessage:
          maps[0]['thank_you_message'] ?? 'Thank you! Please come again.',
      termsAndConditions: maps[0]['terms_and_conditions'] ?? '',
    );
  }

  /// Save receipt settings
  Future<void> saveReceiptSettings(ReceiptSettings settings) async {
    final db = await DatabaseHelper.instance.database;

    // Check if settings exist
    final List<Map<String, dynamic>> existing = await db.query(
      'receipt_settings',
      limit: 1,
    );

    final data = {
      'show_logo': settings.showLogo ? 1 : 0,
      'show_date_time': settings.showDateTime ? 1 : 0,
      'show_order_number': settings.showOrderNumber ? 1 : 0,
      'show_cashier_name': settings.showCashierName ? 1 : 0,
      'show_tax_breakdown': settings.showTaxBreakdown ? 1 : 0,
      'show_service_charge_breakdown': settings.showServiceChargeBreakdown
          ? 1
          : 0,
      'show_thank_you_message': settings.showThankYouMessage ? 1 : 0,
      'auto_print': settings.autoPrint ? 1 : 0,
      'paper_size': settings.paperSize.name,
      'paper_width': settings.paperWidth,
      'font_size': settings.fontSize,
      'header_text': settings.headerText,
      'footer_text': settings.footerText,
      'thank_you_message': settings.thankYouMessage,
      'terms_and_conditions': settings.termsAndConditions,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      // Update existing settings
      await db.update(
        'receipt_settings',
        data,
        where: 'id = ?',
        whereArgs: [existing[0]['id']],
      );
    } else {
      // Insert new settings
      data['created_at'] = DateTime.now().toIso8601String();
      await db.insert('receipt_settings', data);
    }
  }

  // ==================== PRINTERS ====================

  /// Get all active printers
  Future<List<Printer>> getPrinters() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'printers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'is_default DESC, name ASC',
    );

    return maps.map((map) => _printerFromDb(map)).toList();
  }

  /// Get a single printer by ID
  Future<Printer?> getPrinterById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'printers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _printerFromDb(maps[0]);
  }

  /// Get default printer
  Future<Printer?> getDefaultPrinter() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'printers',
      where: 'is_default = ? AND is_active = ?',
      whereArgs: [1, 1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _printerFromDb(maps[0]);
  }

  /// Save a printer (insert or update)
  Future<void> savePrinter(Printer printer) async {
    final db = await DatabaseHelper.instance.database;

    // Check if printer exists
    final existing = await db.query(
      'printers',
      where: 'id = ?',
      whereArgs: [printer.id],
      limit: 1,
    );

    final data = {
      'id': printer.id,
      'name': printer.name,
      'type': printer.type.name,
      'connection_type': printer.connectionType.name,
      'ip_address': printer.ipAddress,
      'port': printer.port,
      'device_id':
          printer.usbDeviceId ??
          printer.bluetoothAddress ??
          printer.platformSpecificId,
      'device_name': printer.modelName,
      'is_default': printer.isDefault ? 1 : 0,
      'is_active': 1,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      await db.update(
        'printers',
        data,
        where: 'id = ?',
        whereArgs: [printer.id],
      );
    } else {
      data['created_at'] = DateTime.now().toIso8601String();
      await db.insert('printers', data);
    }
  }

  /// Delete a printer
  Future<void> deletePrinter(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'printers',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Set default printer (clears other defaults)
  Future<void> setDefaultPrinter(String id) async {
    final db = await DatabaseHelper.instance.database;

    // Clear all defaults
    await db.update('printers', {
      'is_default': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Set new default
    await db.update(
      'printers',
      {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Printer _printerFromDb(Map<String, dynamic> map) {
    final connectionType = PrinterConnectionType.values.firstWhere(
      (e) => e.name == map['connection_type'],
      orElse: () => PrinterConnectionType.network,
    );

    final type = PrinterType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => PrinterType.receipt,
    );

    switch (connectionType) {
      case PrinterConnectionType.network:
        return Printer.network(
          id: map['id'],
          name: map['name'],
          type: type,
          ipAddress: map['ip_address'] ?? '',
          port: map['port'] ?? 9100,
          isDefault: map['is_default'] == 1,
          modelName: map['device_name'],
        );
      case PrinterConnectionType.usb:
        return Printer.usb(
          id: map['id'],
          name: map['name'],
          type: type,
          usbDeviceId: map['device_id'] ?? '',
          isDefault: map['is_default'] == 1,
          modelName: map['device_name'],
        );
      case PrinterConnectionType.bluetooth:
        return Printer.bluetooth(
          id: map['id'],
          name: map['name'],
          type: type,
          bluetoothAddress: map['device_id'] ?? '',
          isDefault: map['is_default'] == 1,
          modelName: map['device_name'],
        );
    }
  }

  // ==================== HELPER METHODS ====================

  /// Convert IconData to string representation
  IconData _iconFromDb(int? codePoint, String? fontFamily) {
    if (codePoint == null) return Icons.category;
    return IconData(codePoint, fontFamily: fontFamily ?? 'MaterialIcons');
  }

  Color _colorFromDb(int? colorValue) {
    if (colorValue == null) return Colors.blue;
    return Color(colorValue);
  }

  // ==================== SEARCH & FILTER ====================

  /// Search items by name or SKU
  Future<List<Item>> searchItems(String query) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where:
          '(name LIKE ? OR sku LIKE ? OR barcode LIKE ?) AND is_available = ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 1],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        description: (maps[i]['description'] as String?) ?? '',
        categoryId: maps[i]['category_id']?.toString() ?? '',
        price: (maps[i]['price'] as num).toDouble(),
        cost: (maps[i]['cost'] as num?)?.toDouble(),
        sku: maps[i]['sku'] as String?,
        barcode: maps[i]['barcode'] as String?,
        icon: _iconFromDb(
          maps[i]['icon_code_point'] as int?,
          maps[i]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[i]['color_value'] as int?),
        imageUrl: maps[i]['image_url'] as String?,
        stock: (maps[i]['stock'] as int?) ?? 0,
        isAvailable: (maps[i]['is_available'] as int?) == 1,
        isFeatured: (maps[i]['is_featured'] as int?) == 1,
        trackStock: (maps[i]['track_stock'] as int?) == 1,
        sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
      );
    });
  }

  /// Get low stock items
  Future<List<Item>> getLowStockItems() async {
    final db = await DatabaseHelper.instance.database;
    // Use a default threshold of 10 since schema doesn't include low_stock_threshold
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM items 
      WHERE track_stock = 1 
      AND is_available = 1 
      AND stock <= 10
      ORDER BY stock ASC
    ''');

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        description: (maps[i]['description'] as String?) ?? '',
        categoryId: maps[i]['category_id']?.toString() ?? '',
        price: (maps[i]['price'] as num).toDouble(),
        cost: (maps[i]['cost'] as num?)?.toDouble(),
        sku: maps[i]['sku'] as String?,
        barcode: maps[i]['barcode'] as String?,
        icon: _iconFromDb(
          maps[i]['icon_code_point'] as int?,
          maps[i]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[i]['color_value'] as int?),
        imageUrl: maps[i]['image_url'] as String?,
        stock: (maps[i]['stock'] as int?) ?? 0,
        isAvailable: (maps[i]['is_available'] as int?) == 1,
        isFeatured: (maps[i]['is_featured'] as int?) == 1,
        trackStock: (maps[i]['track_stock'] as int?) == 1,
        sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
      );
    });
  }

  /// Get favorite items
  Future<List<Item>> getFavoriteItems() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'is_featured = ? AND is_available = ?',
      whereArgs: [1, 1],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        description: (maps[i]['description'] as String?) ?? '',
        categoryId: maps[i]['category_id']?.toString() ?? '',
        price: (maps[i]['price'] as num).toDouble(),
        cost: (maps[i]['cost'] as num?)?.toDouble(),
        sku: maps[i]['sku'] as String?,
        barcode: maps[i]['barcode'] as String?,
        icon: _iconFromDb(
          maps[i]['icon_code_point'] as int?,
          maps[i]['icon_font_family'] as String?,
        ),
        color: _colorFromDb(maps[i]['color_value'] as int?),
        imageUrl: maps[i]['image_url'] as String?,
        stock: (maps[i]['stock'] as int?) ?? 0,
        isAvailable: (maps[i]['is_available'] as int?) == 1,
        isFeatured: (maps[i]['is_featured'] as int?) == 1,
        trackStock: (maps[i]['track_stock'] as int?) == 1,
        sortOrder: (maps[i]['sort_order'] as int?) ?? 0,
      );
    });
  }

  // ==================== MODIFIER GROUPS ====================

  /// Get all modifier groups
  Future<List<ModifierGroup>> getModifierGroups() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_groups',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierGroup.fromJson(maps[i]));
  }

  /// Get modifier groups for a specific category
  Future<List<ModifierGroup>> getModifierGroupsForCategory(
    String categoryId,
  ) async {
    final allGroups = await getModifierGroups();
    return allGroups
        .where((group) => group.appliesToCategory(categoryId))
        .toList();
  }

  /// Get a single modifier group by ID
  Future<ModifierGroup?> getModifierGroupById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ModifierGroup.fromJson(maps[0]);
  }

  /// Insert a new modifier group
  Future<void> insertModifierGroup(ModifierGroup group) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('modifier_groups', group.toJson());
  }

  /// Update an existing modifier group
  Future<void> updateModifierGroup(ModifierGroup group) async {
    final db = await DatabaseHelper.instance.database;
    final updatedGroup = group.copyWith(updatedAt: DateTime.now());
    await db.update(
      'modifier_groups',
      updatedGroup.toJson(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  /// Delete a modifier group
  Future<void> deleteModifierGroup(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_groups', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MODIFIER ITEMS ====================

  /// Get all modifier items for a specific group
  Future<List<ModifierItem>> getModifierItems(String groupId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      where: 'modifier_group_id = ? AND is_available = ?',
      whereArgs: [groupId, 1],
      orderBy: 'sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierItem.fromJson(maps[i]));
  }

  /// Get all modifier items (for management)
  Future<List<ModifierItem>> getAllModifierItems() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      orderBy: 'modifier_group_id ASC, sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => ModifierItem.fromJson(maps[i]));
  }

  /// Get a single modifier item by ID
  Future<ModifierItem?> getModifierItemById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'modifier_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ModifierItem.fromJson(maps[0]);
  }

  /// Insert a new modifier item
  Future<void> insertModifierItem(ModifierItem item) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('modifier_items', item.toJson());
  }

  /// Update an existing modifier item
  Future<void> updateModifierItem(ModifierItem item) async {
    final db = await DatabaseHelper.instance.database;
    final updatedItem = item.copyWith(updatedAt: DateTime.now());
    await db.update(
      'modifier_items',
      updatedItem.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete a modifier item
  Future<void> deleteModifierItem(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_items', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SALES (ORDERS & TRANSACTIONS) ====================

  /// Save a completed sale (order + items + transaction) in a single transaction.
  /// Returns the generated order number on success, or null if persistence was skipped (e.g., unmapped items).
  Future<String?> saveCompletedSale({
    required List<CartItem> cartItems,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
    String orderType = 'retail',
    String? tableId,
    int? cafeOrderNumber,
    String? userId,
  }) async {
    if (cartItems.isEmpty) return null;

    final db = await DatabaseHelper.instance.database;

    // Prefetch items to map product names -> item IDs (required by schema)
    final rawItems = await db.query('items', columns: ['id', 'name', 'price']);
    final Map<String, Map<String, Object?>> itemByName = {
      for (final row in rawItems) (row['name'] as String): row,
    };

    // Ensure all cart items can be mapped to DB items; otherwise skip persistence
    final unmapped = cartItems
        .where((ci) => !itemByName.containsKey(ci.product.name))
        .toList();
    if (unmapped.isNotEmpty) {
      // Skip saving to avoid violating NOT NULL + FK constraints on order_items.item_id
      return null;
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final uuid = const Uuid();
    final generatedOrderNumber = _generateOrderNumber(
      orderType: orderType,
      cafeOrderNumber: cafeOrderNumber,
    );
    final resolvedUserId = userId ?? '1'; // default admin (seeded)

    await db.transaction((txn) async {
      final orderId = uuid.v4();

      await txn.insert('orders', {
        'id': orderId,
        'order_number': generatedOrderNumber,
        'table_id': tableId,
        'user_id': resolvedUserId,
        'status': 'completed',
        'order_type': orderType,
        'subtotal': subtotal,
        'tax': tax,
        'discount': 0,
        'total': total,
        'payment_method_id': paymentMethod.id,
        'notes': null,
        'created_at': nowIso,
        'updated_at': nowIso,
        'completed_at': nowIso,
      });

      for (final ci in cartItems) {
        final dbItem = itemByName[ci.product.name]!;
        final itemId = dbItem['id'] as String;

        // Encode modifiers into notes JSON for the line item
        final mods = ci.modifiers
            .map(
              (m) => {
                'id': m.id,
                'groupId': m.modifierGroupId,
                'name': m.name,
                'priceAdjustment': m.priceAdjustment,
              },
            )
            .toList();
        final notes = mods.isEmpty ? null : jsonEncode({'modifiers': mods});

        await txn.insert('order_items', {
          'id': uuid.v4(),
          'order_id': orderId,
          'item_id': itemId,
          'item_name': ci.product.name,
          // Store unit price as final (base + modifiers) to reflect charged price
          'item_price': ci.finalPrice,
          'quantity': ci.quantity,
          'subtotal': ci.totalPrice,
          'notes': notes,
          'created_at': nowIso,
        });
      }

      await txn.insert('transactions', {
        'id': uuid.v4(),
        'order_id': orderId,
        'payment_method_id': paymentMethod.id,
        'amount': total,
        'change_amount': change,
        'transaction_date': nowIso,
        'receipt_number': generatedOrderNumber,
        'created_at': nowIso,
      });
    });

    return generatedOrderNumber;
  }

  String _generateOrderNumber({
    required String orderType,
    int? cafeOrderNumber,
  }) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');

    switch (orderType) {
      case 'cafe':
        final numStr = (cafeOrderNumber ?? 0).toString().padLeft(3, '0');
        return 'C-$numStr-$y$m$d$hh$mm$ss$ms';
      case 'restaurant':
        return 'T-$y$m$d$hh$mm$ss$ms';
      default:
        return 'R-$y$m$d$hh$mm$ss$ms';
    }
  }

  /// Get a list of recent orders (raw maps) - newest first
  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 50}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps;
  }

  /// Get orders with optional filters and pagination. Returns raw maps.
  /// - from/to are inclusive and compare against `created_at` (ISO string)
  /// - paymentMethodId filters by payment_method_id
  /// - offset/limit for paging
  Future<List<Map<String, dynamic>>> getOrders({
    DateTime? from,
    DateTime? to,
    String? paymentMethodId,
    int offset = 0,
    int limit = 50,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (from != null) {
      whereClauses.add("created_at >= ?");
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add("created_at <= ?");
      whereArgs.add(to.toIso8601String());
    }
    if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
      whereClauses.add("payment_method_id = ?");
      whereArgs.add(paymentMethodId);
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps;
  }

  /// Export orders (with order items) to CSV string. Each row represents
  /// an order item with order-level fields included.
  Future<String> exportOrdersCsv({
    DateTime? from,
    DateTime? to,
    String? paymentMethodId,
    int limit = 100000,
  }) async {
    final orders = await getOrders(
      from: from,
      to: to,
      paymentMethodId: paymentMethodId,
      offset: 0,
      limit: limit,
    );
    final sb = StringBuffer();
    // Machine-readable metadata as CSV key,value rows
    final now = DateTime.now().toIso8601String();
    final bizName = BusinessInfo.instance.businessName;
    final bizAddress = BusinessInfo.instance.fullAddress;
    final taxNumber = BusinessInfo.instance.taxNumber ?? '';

    sb.writeln('meta_key,meta_value');
    sb.writeln('generated_at,${_escapeCsv(now)}');
    sb.writeln('business_name,${_escapeCsv(bizName)}');
    sb.writeln('business_address,${_escapeCsv(bizAddress)}');
    sb.writeln('tax_number,${_escapeCsv(taxNumber)}');
    sb.writeln(
      'opening_time,${_escapeCsv(BusinessInfo.instance.openingTimeToday)}',
    );
    sb.writeln(
      'closing_time,${_escapeCsv(BusinessInfo.instance.closingTimeToday)}',
    );
    sb.writeln(); // blank line before column headers
    sb.writeln(
      'order_number,created_at,total,payment_method_id,table_id,user_id,status,item_id,item_name,quantity,item_price,item_subtotal,notes',
    );

    for (final o in orders) {
      final orderId = o['id'] as String;
      final orderNumber = (o['order_number'] ?? '').toString();
      final createdAt = (o['created_at'] ?? '').toString();
      final total = ((o['total'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(
        2,
      );
      final paymentMethod = (o['payment_method_id'] ?? '').toString();
      final tableId = (o['table_id'] ?? '').toString();
      final userId = (o['user_id'] ?? '').toString();
      final status = (o['status'] ?? '').toString();

      final items = await getOrderItems(orderId);
      if (items.isEmpty) {
        // Emit an order-level row with empty item columns
        sb.writeln(
          '${_escapeCsv(orderNumber)},${_escapeCsv(createdAt)},$total,${_escapeCsv(paymentMethod)},${_escapeCsv(tableId)},${_escapeCsv(userId)},${_escapeCsv(status)},,,0,0.00,',
        );
        continue;
      }

      for (final it in items) {
        final itemId = (it['item_id'] ?? '').toString();
        final itemName = (it['item_name'] ?? '').toString();
        final qty = (it['quantity'] as num?)?.toInt() ?? 0;
        final itemPrice = ((it['item_price'] as num?)?.toDouble() ?? 0.0)
            .toStringAsFixed(2);
        final itemSubtotal = ((it['subtotal'] as num?)?.toDouble() ?? 0.0)
            .toStringAsFixed(2);
        final notes = (it['notes'] ?? '').toString();

        sb.writeln(
          '${_escapeCsv(orderNumber)},${_escapeCsv(createdAt)},$total,${_escapeCsv(paymentMethod)},${_escapeCsv(tableId)},${_escapeCsv(userId)},${_escapeCsv(status)},${_escapeCsv(itemId)},${_escapeCsv(itemName)},$qty,$itemPrice,$itemSubtotal,${_escapeCsv(notes)}',
        );
      }
    }

    return sb.toString();
  }

  String _escapeCsv(String input) {
    final s = input.replaceAll('\r', '').replaceAll('\n', ' ');
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Get order items for a specific order
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at ASC',
    );
    return maps;
  }

  /// Get transactions associated with an order
  Future<List<Map<String, dynamic>>> getTransactionsForOrder(
    String orderId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'transaction_date DESC',
    );
    return maps;
  }

  // ==================== USERS ====================

  /// Get all users
  Future<List<User>> getUsers() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'username ASC',
    );

    return List.generate(maps.length, (i) {
      final id = maps[i]['id'].toString();
      // Prefer the encrypted pin if present
      return User(
        id: id,
        username: maps[i]['username'] as String,
        fullName: maps[i]['full_name'] as String,
        email: maps[i]['email'] as String,
        role: UserRole.values[maps[i]['role'] as int],
        status: UserStatus.values[maps[i]['status'] as int],
        lastLoginAt: maps[i]['last_login_at'] != null
            ? DateTime.parse(maps[i]['last_login_at'] as String)
            : null,
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
        phoneNumber: maps[i]['phone_number'] as String?,
      );
    });
  }

  /// Get a single user by ID
  Future<User?> getUserById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    final idStr = map['id'].toString();
    return User(
      id: idStr,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      role: UserRole.values[map['role'] as int],
      status: UserStatus.values[map['status'] as int],
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      phoneNumber: map['phone_number'] as String?,
    );
  }

  /// Insert a new user
  Future<int> insertUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    // PINs are persisted in the encrypted Hive PinStore. Callers should
    // write the PIN into PinStore before calling insertUser/updateUser.

    return await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'full_name': user.fullName,
      'email': user.email,
      'role': user.role.index,
      'status': user.status.index,
      'last_login_at': user.lastLoginAt?.toIso8601String(),
      'created_at': user.createdAt.toIso8601String(),
      'phone_number': user.phoneNumber,
    });
  }

  /// Update an existing user
  Future<int> updateUser(User user) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'users',
      {
        'username': user.username,
        'full_name': user.fullName,
        'email': user.email,
        'role': user.role.index,
        'status': user.status.index,
        'last_login_at': user.lastLoginAt?.toIso8601String(),
        'phone_number': user.phoneNumber,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Delete a user
  Future<int> deleteUser(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TABLES ====================

  /// Get all tables
  Future<List<RestaurantTable>> getTables() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return RestaurantTable(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        capacity: maps[i]['capacity'] as int,
        status: TableStatus.values[maps[i]['status'] as int],
        orders: [], // Orders are not stored in DB, only in memory
        occupiedSince: maps[i]['occupied_since'] != null
            ? DateTime.parse(maps[i]['occupied_since'] as String)
            : null,
        customerName: maps[i]['customer_name'] as String?,
      );
    });
  }

  /// Get a single table by ID
  Future<RestaurantTable?> getTableById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return RestaurantTable(
      id: map['id'].toString(),
      name: map['name'] as String,
      capacity: map['capacity'] as int,
      status: TableStatus.values[map['status'] as int],
      orders: [], // Orders are not stored in DB, only in memory
      occupiedSince: map['occupied_since'] != null
          ? DateTime.parse(map['occupied_since'] as String)
          : null,
      customerName: map['customer_name'] as String?,
    );
  }

  /// Insert a new table
  Future<int> insertTable(RestaurantTable table) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('tables', {
      'id': table.id,
      'name': table.name,
      'capacity': table.capacity,
      'status': table.status.index,
      'occupied_since': table.occupiedSince?.toIso8601String(),
      'customer_name': table.customerName,
    });
  }

  /// Update an existing table
  Future<int> updateTable(RestaurantTable table) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'tables',
      {
        'name': table.name,
        'capacity': table.capacity,
        'status': table.status.index,
        'occupied_since': table.occupiedSince?.toIso8601String(),
        'customer_name': table.customerName,
      },
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  /// Delete a table
  Future<int> deleteTable(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== PAYMENT METHODS ====================

  /// Get all payment methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return PaymentMethod(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'] as String,
        status: PaymentMethodStatus.values[maps[i]['status'] as int],
        isDefault: (maps[i]['is_default'] as int?) == 1,
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
      );
    });
  }

  /// Get a single payment method by ID
  Future<PaymentMethod?> getPaymentMethodById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return PaymentMethod(
      id: map['id'].toString(),
      name: map['name'] as String,
      status: PaymentMethodStatus.values[map['status'] as int],
      isDefault: (map['is_default'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Insert a new payment method
  Future<int> insertPaymentMethod(PaymentMethod paymentMethod) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('payment_methods', {
      'id': paymentMethod.id,
      'name': paymentMethod.name,
      'status': paymentMethod.status.index,
      'is_default': paymentMethod.isDefault ? 1 : 0,
      'created_at':
          paymentMethod.createdAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    });
  }

  /// Update an existing payment method
  Future<int> updatePaymentMethod(PaymentMethod paymentMethod) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'payment_methods',
      {
        'name': paymentMethod.name,
        'status': paymentMethod.status.index,
        'is_default': paymentMethod.isDefault ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [paymentMethod.id],
    );
  }

  /// Delete a payment method
  Future<int> deletePaymentMethod(String id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== DELETE ALL METHODS ====================

  /// Delete all sales (orders, order_items, transactions)
  Future<void> deleteAllSales() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions');
    await db.delete('order_items');
    await db.delete('orders');
  }

  /// Delete all modifier items
  Future<void> deleteAllModifierItems() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('item_modifiers');
    await db.delete('modifier_items');
  }

  /// Delete all modifier groups
  Future<void> deleteAllModifierGroups() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('modifier_groups');
  }

  /// Delete all items
  Future<void> deleteAllItems() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('items');
  }

  /// Delete all categories
  Future<void> deleteAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categories');
  }

  /// Delete all tables
  Future<void> deleteAllTables() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tables');
  }

  /// Delete all users
  Future<void> deleteAllUsers() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('users');
  }

  /// Delete all payment methods
  Future<void> deleteAllPaymentMethods() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('payment_methods');
  }

  /// Delete all printers
  Future<void> deleteAllPrinters() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('printers');
  }
}
