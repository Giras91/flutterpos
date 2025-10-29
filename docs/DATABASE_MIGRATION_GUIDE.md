# Database Migration Guide

## Overview
This guide explains how to manage database schema changes and migrations in ExtroPOS.

## Current Version
**Database Version**: 1

## Migration Strategy

ExtroPOS uses SQLite's `onUpgrade` callback to handle database migrations automatically. When the database version changes, the system runs migration scripts to update the schema and preserve existing data.

### Version Control
The database version is defined in `database_helper.dart`:

```dart
return await openDatabase(
  path,
  version: 1,  // Current version
  onCreate: _createDB,
  onUpgrade: _upgradeDB,
);
```

## How Migrations Work

### 1. New Installation (onCreate)
When the app is installed for the first time:
- `_createDB()` is called
- All tables are created
- Indexes are added
- Default data is inserted

### 2. Existing Installation (onUpgrade)
When updating to a new app version with database changes:
- `_upgradeDB()` is called
- Migration scripts run based on version numbers
- Data is preserved and transformed as needed

## Creating a Migration

### Step 1: Increment Version Number
```dart
// database_helper.dart
return await openDatabase(
  path,
  version: 2,  // Increment from 1 to 2
  onCreate: _createDB,
  onUpgrade: _upgradeDB,
);
```

### Step 2: Update onCreate
Always keep `_createDB()` in sync with the latest schema:

```dart
Future<void> _createDB(Database db, int version) async {
  await _createTables(db);  // Latest table definitions
  await _createIndexes(db); // Latest indexes
  await _insertDefaultData(db);
}
```

### Step 3: Add Migration Logic
Implement the upgrade path in `_upgradeDB()`:

```dart
Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  // Version 1 → 2
  if (oldVersion < 2) {
    // Add new column
    await db.execute('ALTER TABLE items ADD COLUMN custom_field TEXT');
    
    // Create new table
    await db.execute('''
      CREATE TABLE new_table (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Update existing data
    await db.execute('UPDATE items SET custom_field = "default"');
  }
  
  // Version 2 → 3
  if (oldVersion < 3) {
    // Add another migration
    await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
  }
}
```

## Migration Examples

### Example 1: Adding a Column

```dart
// Version 1 → 2: Add discount_percent to items
if (oldVersion < 2) {
  await db.execute('ALTER TABLE items ADD COLUMN discount_percent REAL DEFAULT 0');
}
```

### Example 2: Creating a New Table

```dart
// Version 1 → 2: Add customer loyalty table
if (oldVersion < 2) {
  await db.execute('''
    CREATE TABLE loyalty_points (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      points INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
  
  await db.execute('CREATE INDEX idx_loyalty_customer ON loyalty_points(customer_id)');
}
```

### Example 3: Data Transformation

```dart
// Version 1 → 2: Split name into first_name and last_name
if (oldVersion < 2) {
  // Add new columns
  await db.execute('ALTER TABLE users ADD COLUMN first_name TEXT');
  await db.execute('ALTER TABLE users ADD COLUMN last_name TEXT');
  
  // Migrate data
  final users = await db.query('users');
  for (final user in users) {
    final name = user['name'] as String;
    final parts = name.split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    
    await db.update(
      'users',
      {
        'first_name': firstName,
        'last_name': lastName,
      },
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }
  
  // Note: Cannot drop columns in SQLite without recreating table
}
```

### Example 4: Recreating a Table (Complex Changes)

```dart
// Version 1 → 2: Restructure items table
if (oldVersion < 2) {
  // 1. Rename old table
  await db.execute('ALTER TABLE items RENAME TO items_old');
  
  // 2. Create new table with updated schema
  await db.execute('''
    CREATE TABLE items (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      category_id TEXT NOT NULL,
      new_field TEXT,  -- New field
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories (id)
    )
  ''');
  
  // 3. Copy data from old to new
  await db.execute('''
    INSERT INTO items (id, name, description, price, category_id, created_at, updated_at)
    SELECT id, name, description, price, category_id, created_at, updated_at
    FROM items_old
  ''');
  
  // 4. Set default value for new field
  await db.execute('UPDATE items SET new_field = "default"');
  
  // 5. Drop old table
  await db.execute('DROP TABLE items_old');
  
  // 6. Recreate indexes
  await db.execute('CREATE INDEX idx_items_category ON items(category_id)');
}
```

### Example 5: Adding Foreign Key Constraints

```dart
// Version 1 → 2: Add foreign key to order_items
if (oldVersion < 2) {
  // SQLite doesn't support adding FK to existing table
  // Must recreate table
  
  await db.execute('ALTER TABLE order_items RENAME TO order_items_old');
  
  await db.execute('''
    CREATE TABLE order_items (
      id TEXT PRIMARY KEY,
      order_id TEXT NOT NULL,
      item_id TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
      FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE RESTRICT
    )
  ''');
  
  await db.execute('''
    INSERT INTO order_items
    SELECT * FROM order_items_old
  ''');
  
  await db.execute('DROP TABLE order_items_old');
}
```

## Testing Migrations

### 1. Test on Development Device

```dart
// In database_test_screen.dart
Future<void> _testMigration() async {
  // 1. Install app with version 1
  // 2. Add some test data
  // 3. Update code to version 2
  // 4. Hot restart app
  // 5. Verify data migrated correctly
}
```

### 2. Use Database Test Screen

Navigate to Database Test screen to:
- View current database state
- Reset database to test fresh installs
- Insert test data
- Verify migrations

### 3. Automated Testing

```dart
// test/database_migration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Migration from v1 to v2', () async {
    // Create v1 database
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Create v1 schema
        await db.execute('CREATE TABLE items (id TEXT, name TEXT)');
      },
    );
    
    // Insert test data
    await db.insert('items', {'id': '1', 'name': 'Test'});
    await db.close();
    
    // Reopen with v2
    final db2 = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE items ADD COLUMN price REAL');
        }
      },
    );
    
    // Verify migration
    final result = await db2.query('items');
    expect(result.first.containsKey('price'), true);
    
    await db2.close();
  });
}
```

## Best Practices

### ✅ DO

1. **Always increment version number** when changing schema
2. **Test migrations** on development devices first
3. **Keep onCreate in sync** with latest schema
4. **Preserve user data** during migrations
5. **Add indexes** after data migration for performance
6. **Use transactions** for complex migrations
7. **Document** each migration in comments
8. **Backup data** before major migrations

### ❌ DON'T

1. **Don't skip version numbers** (1 → 3 without 2)
2. **Don't modify old migration code** after release
3. **Don't forget to update onCreate**
4. **Don't delete data** without user confirmation
5. **Don't use complex queries** that might fail
6. **Don't forget error handling**

## Migration Checklist

Before releasing a new version with database changes:

- [ ] Increment database version number
- [ ] Update `_createDB()` with latest schema
- [ ] Add migration logic to `_upgradeDB()`
- [ ] Test migration on development device
- [ ] Verify all existing data is preserved
- [ ] Check indexes are recreated
- [ ] Test on multiple version upgrades (1→2, 1→3, 2→3)
- [ ] Document migration in code comments
- [ ] Update DATABASE_SCHEMA.md documentation
- [ ] Add entry to this migration guide

## Rollback Strategy

If a migration fails in production:

### Option 1: Fix Forward
Release a hotfix with corrected migration:

```dart
if (oldVersion < 2) {
  try {
    // Original migration
    await db.execute('ALTER TABLE items ADD COLUMN field1 TEXT');
  } catch (e) {
    // Already exists, skip
  }
}
```

### Option 2: Database Rebuild
For critical failures, offer database reset:

```dart
// Show dialog to user
final shouldReset = await showResetDialog();
if (shouldReset) {
  await DatabaseHelper.instance.resetDatabase();
}
```

## Backup and Restore

### Backup Database

```dart
Future<void> backupDatabase() async {
  final dbPath = await getDatabasesPath();
  final source = File(join(dbPath, 'extropos.db'));
  
  // Create backup with timestamp
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final backup = File(join(backupPath, 'backup_$timestamp.db'));
  
  await source.copy(backup.path);
}
```

### Restore Database

```dart
Future<void> restoreDatabase(String backupPath) async {
  final dbPath = await getDatabasesPath();
  final target = File(join(dbPath, 'extropos.db'));
  final backup = File(backupPath);
  
  // Close database first
  await DatabaseHelper.instance.close();
  
  // Restore from backup
  await backup.copy(target.path);
  
  // Reinitialize
  await DatabaseHelper.instance.database;
}
```

## Version History

### Version 1 (Current)
**Release Date**: October 26, 2025  
**Changes**:
- Initial database schema
- All core tables created
- Default data inserted

### Version 2 (Planned)
**Target Date**: TBD  
**Planned Changes**:
- Customer management tables
- Advanced reporting tables
- Multi-location support

## Troubleshooting

### Migration Fails
1. Check logs for specific error
2. Verify SQL syntax
3. Check foreign key constraints
4. Ensure data types are compatible

### Data Loss After Migration
1. Restore from backup
2. Review migration script
3. Fix and re-release

### Performance Issues After Migration
1. Verify indexes are recreated
2. Run VACUUM to optimize
3. Analyze query performance

---

**Document Version**: 1.0  
**Compatible with**: Database Schema v1  
**Last Updated**: October 26, 2025
