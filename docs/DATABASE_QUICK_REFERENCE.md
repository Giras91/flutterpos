# Database Quick Reference Guide

## Setup & Initialization

### 1. Import Database Helper
```dart
import 'package:extropos/services/database_helper.dart';
```

### 2. Get Database Instance
```dart
final db = await DatabaseHelper.instance.database;
```

### 3. Close Database (Optional)
```dart
await DatabaseHelper.instance.close();
```

---

## Common Operations

### Create (INSERT)

#### Insert a Category
```dart
final now = DateTime.now().toIso8601String();

await db.insert('categories', {
  'id': 'unique-id',
  'name': 'Beverages',
  'description': 'Hot and cold drinks',
  'icon_code_point': Icons.local_cafe.codePoint,
  'icon_font_family': Icons.local_cafe.fontFamily,
  'color_value': Colors.brown.value,
  'sort_order': 1,
  'is_active': 1,
  'created_at': now,
  'updated_at': now,
});
```

#### Insert an Item
```dart
await db.insert('items', {
  'id': 'unique-id',
  'name': 'Espresso',
  'description': 'Strong black coffee',
  'price': 3.50,
  'category_id': 'category-id',
  'icon_code_point': Icons.local_cafe.codePoint,
  'icon_font_family': Icons.local_cafe.fontFamily,
  'color_value': Colors.brown.value,
  'is_available': 1,
  'is_featured': 0,
  'stock': 100,
  'track_stock': 0,
  'sort_order': 1,
  'created_at': now,
  'updated_at': now,
});
```

#### Insert an Order
```dart
await db.insert('orders', {
  'id': 'order-id',
  'order_number': 'ORD-001',
  'user_id': 'user-id',
  'status': 'pending',
  'order_type': 'dine-in',
  'subtotal': 25.00,
  'tax': 2.50,
  'discount': 0,
  'total': 27.50,
  'created_at': now,
  'updated_at': now,
});
```

### Read (SELECT)

#### Get All Records
```dart
final categories = await db.query('categories');
```

#### Get with Conditions
```dart
final activeCategories = await db.query(
  'categories',
  where: 'is_active = ?',
  whereArgs: [1],
  orderBy: 'sort_order ASC',
);
```

#### Get Single Record
```dart
final category = await db.query(
  'categories',
  where: 'id = ?',
  whereArgs: [categoryId],
  limit: 1,
);
```

#### Get with JOIN
```dart
final results = await db.rawQuery('''
  SELECT i.*, c.name as category_name
  FROM items i
  JOIN categories c ON i.category_id = c.id
  WHERE i.is_available = 1
  ORDER BY i.sort_order ASC
''');
```

### Update (UPDATE)

#### Update a Record
```dart
await db.update(
  'items',
  {
    'name': 'New Name',
    'price': 4.50,
    'updated_at': DateTime.now().toIso8601String(),
  },
  where: 'id = ?',
  whereArgs: [itemId],
);
```

#### Bulk Update
```dart
await db.update(
  'items',
  {'is_available': 0},
  where: 'category_id = ?',
  whereArgs: [categoryId],
);
```

### Delete (DELETE)

#### Delete a Record
```dart
await db.delete(
  'items',
  where: 'id = ?',
  whereArgs: [itemId],
);
```

#### Delete Multiple
```dart
await db.delete(
  'order_items',
  where: 'order_id = ?',
  whereArgs: [orderId],
);
```

#### Delete All (Clear Table)
```dart
await db.delete('audit_log');
```

---

## Advanced Queries

### Count Records
```dart
final count = Sqflite.firstIntValue(
  await db.rawQuery('SELECT COUNT(*) FROM items WHERE is_available = 1')
);
```

### Aggregations
```dart
final result = await db.rawQuery('''
  SELECT 
    COUNT(*) as total_orders,
    SUM(total) as total_sales,
    AVG(total) as average_order
  FROM orders
  WHERE status = 'completed'
    AND created_at >= date('now', '-30 days')
''');
```

### Group By
```dart
final categoryTotals = await db.rawQuery('''
  SELECT 
    c.name,
    COUNT(o.id) as order_count,
    SUM(oi.subtotal) as total_sales
  FROM categories c
  JOIN items i ON c.id = i.category_id
  JOIN order_items oi ON i.id = oi.item_id
  JOIN orders o ON oi.order_id = o.id
  WHERE o.status = 'completed'
  GROUP BY c.id
  ORDER BY total_sales DESC
''');
```

### Date Filtering
```dart
final todaySales = await db.query(
  'orders',
  where: 'date(created_at) = date(?)',
  whereArgs: [DateTime.now().toIso8601String()],
);
```

---

## Transactions

### Basic Transaction
```dart
await db.transaction((txn) async {
  // Insert order
  await txn.insert('orders', orderData);
  
  // Insert order items
  for (final item in orderItems) {
    await txn.insert('order_items', item);
  }
  
  // Update stock
  for (final item in orderItems) {
    await txn.rawUpdate('''
      UPDATE items 
      SET stock = stock - ? 
      WHERE id = ?
    ''', [item['quantity'], item['item_id']]);
  }
});
```

### Transaction with Rollback
```dart
try {
  await db.transaction((txn) async {
    await txn.insert('orders', orderData);
    await txn.insert('transactions', paymentData);
    
    // If this fails, entire transaction rolls back
    await txn.insert('audit_log', auditData);
  });
} catch (e) {
  print('Transaction failed: $e');
  // All changes are automatically rolled back
}
```

---

## Batch Operations

### Insert Multiple Records
```dart
final batch = db.batch();

for (final item in items) {
  batch.insert('items', item);
}

await batch.commit(noResult: true);
```

### Mixed Operations
```dart
final batch = db.batch();

batch.insert('categories', newCategory);
batch.update('items', {'category_id': newCategoryId}, where: 'id = ?', whereArgs: [itemId]);
batch.delete('old_table', where: 'created_at < ?', whereArgs: [cutoffDate]);

await batch.commit();
```

---

## Search & Filtering

### Text Search
```dart
final results = await db.query(
  'items',
  where: 'name LIKE ? OR description LIKE ?',
  whereArgs: ['%$searchTerm%', '%$searchTerm%'],
);
```

### Multiple Conditions (AND)
```dart
final results = await db.query(
  'items',
  where: 'category_id = ? AND is_available = ? AND price <= ?',
  whereArgs: [categoryId, 1, maxPrice],
);
```

### Multiple Conditions (OR)
```dart
final results = await db.rawQuery('''
  SELECT * FROM items
  WHERE category_id = ? 
     OR is_featured = 1
  ORDER BY name ASC
''', [categoryId]);
```

### IN Clause
```dart
final ids = ['id1', 'id2', 'id3'];
final placeholders = List.filled(ids.length, '?').join(',');

final results = await db.rawQuery('''
  SELECT * FROM items
  WHERE id IN ($placeholders)
''', ids);
```

---

## Pagination

### Limit and Offset
```dart
final page = 2;
final pageSize = 20;
final offset = (page - 1) * pageSize;

final results = await db.query(
  'items',
  orderBy: 'created_at DESC',
  limit: pageSize,
  offset: offset,
);
```

---

## Performance Tips

### 1. Use Indexes
```dart
// Indexes are created automatically in database_helper.dart
// Check DATABASE_SCHEMA.md for all indexes
```

### 2. Use Prepared Statements
```dart
// ✅ Good - Uses prepared statement
await db.query('items', where: 'id = ?', whereArgs: [id]);

// ❌ Bad - SQL injection risk
await db.rawQuery("SELECT * FROM items WHERE id = '$id'");
```

### 3. Batch Operations
```dart
// ✅ Good - Single batch
final batch = db.batch();
for (final item in items) {
  batch.insert('items', item);
}
await batch.commit();

// ❌ Bad - Multiple round trips
for (final item in items) {
  await db.insert('items', item);
}
```

### 4. Use Transactions
```dart
// Groups multiple operations together
await db.transaction((txn) async {
  await txn.insert('orders', orderData);
  await txn.insert('order_items', itemData);
});
```

---

## Data Validation

### Check if Record Exists
```dart
final exists = await db.query(
  'items',
  where: 'id = ?',
  whereArgs: [itemId],
  limit: 1,
);

if (exists.isNotEmpty) {
  // Record exists
}
```

### Get Count
```dart
final count = Sqflite.firstIntValue(
  await db.rawQuery('SELECT COUNT(*) FROM items WHERE category_id = ?', [categoryId])
);
```

---

## Common Patterns

### Load Category with Items
```dart
Future<Map<String, dynamic>> loadCategoryWithItems(String categoryId) async {
  final db = await DatabaseHelper.instance.database;
  
  // Get category
  final category = await db.query('categories', where: 'id = ?', whereArgs: [categoryId]);
  
  if (category.isEmpty) return {};
  
  // Get items
  final items = await db.query('items', where: 'category_id = ?', whereArgs: [categoryId]);
  
  return {
    'category': category.first,
    'items': items,
  };
}
```

### Create Order with Items
```dart
Future<String> createOrder(Map<String, dynamic> orderData, List<Map<String, dynamic>> items) async {
  final db = await DatabaseHelper.instance.database;
  
  return await db.transaction((txn) async {
    // Insert order
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    await txn.insert('orders', {...orderData, 'id': orderId});
    
    // Insert order items
    for (final item in items) {
      await txn.insert('order_items', {
        ...item,
        'order_id': orderId,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    }
    
    return orderId;
  });
}
```

### Update Stock
```dart
Future<void> updateStock(String itemId, int quantity) async {
  final db = await DatabaseHelper.instance.database;
  
  await db.rawUpdate('''
    UPDATE items 
    SET stock = stock + ?, 
        updated_at = ?
    WHERE id = ?
  ''', [quantity, DateTime.now().toIso8601String(), itemId]);
}
```

---

## Debugging

### Print Query Results
```dart
final results = await db.query('items');
for (final row in results) {
  print('Item: ${row['name']} - \$${row['price']}');
}
```

### Check Table Structure
```dart
final tableInfo = await db.rawQuery('PRAGMA table_info(items)');
print(tableInfo);
```

### View All Tables
```dart
final tables = await db.rawQuery(
  "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
);
print(tables);
```

---

## Error Handling

### Try-Catch Pattern
```dart
try {
  await db.insert('items', itemData);
} on DatabaseException catch (e) {
  if (e.isUniqueConstraintError()) {
    print('Item already exists');
  } else if (e.isForeignKeyConstraintError()) {
    print('Invalid category');
  } else {
    print('Database error: $e');
  }
}
```

---

## Testing

### Access Database Test Screen
1. Open Settings
2. Scroll to "Developer" section
3. Tap "Database Test"
4. Use buttons to:
   - Refresh: Reload database state
   - Add Test Data: Insert sample records
   - Reset DB: Clear and recreate database

---

**Quick Reference Version**: 1.0  
**Compatible with**: Database Schema v1  
**Last Updated**: October 26, 2025
