import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'pin_store.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  // Optional override for database file path (used by tests to isolate DB files)
  static String? _overrideDatabaseFilePath;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('extropos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path =
        _overrideDatabaseFilePath ?? join(await getDatabasesPath(), filePath);

    return await openDatabase(
      path,
      // bump DB version to allow migrations for table schema changes
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
    await _insertDefaultData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // v2: Add show_service_charge_breakdown column to receipt_settings
      await db.execute(
        "ALTER TABLE receipt_settings ADD COLUMN show_service_charge_breakdown INTEGER DEFAULT 1",
      );
      // Optionally update timestamps
      await db.execute(
        "UPDATE receipt_settings SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
      );
    }

    if (oldVersion < 3) {
      // v3: Add category_ids column to modifier_groups
      await db.execute(
        "ALTER TABLE modifier_groups ADD COLUMN category_ids TEXT DEFAULT ''",
      );
      // Update timestamps
      await db.execute(
        "UPDATE modifier_groups SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')",
      );
    }

    if (oldVersion < 4) {
      // v4: Add compatibility columns to tables to support newer code that
      // expects `name`, `capacity`, `occupied_since`, and `customer_name`.
      // Keep original `number` and `seats` columns for backward compatibility.
      try {
        await db.execute("ALTER TABLE tables ADD COLUMN name TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE tables ADD COLUMN capacity INTEGER DEFAULT 0",
        );
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE tables ADD COLUMN occupied_since TEXT");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE tables ADD COLUMN customer_name TEXT");
      } catch (_) {}

      // Migrate existing values from number/seats where available
      try {
        await db.execute(
          "UPDATE tables SET name = 'Table ' || number WHERE (name IS NULL OR name = '') AND number IS NOT NULL",
        );
      } catch (_) {}
      try {
        await db.execute(
          "UPDATE tables SET capacity = seats WHERE (capacity IS NULL OR capacity = 0) AND seats IS NOT NULL",
        );
      } catch (_) {}
    }

    if (oldVersion < 5) {
      // v5: Remove plaintext `pin` column from users table. PINs are now
      // persisted in the encrypted Hive PinStore. SQLite doesn't support
      // dropping a column directly, so recreate the users table without the
      // `pin` column and copy over data.
      try {
        // If there are plaintext pins in the existing DB, move them into the
        // PinStore first (PinStore should be initialized by main before DB open).
        try {
          final List<Map<String, Object?>> rows = await db.query(
            'users',
            columns: ['id', 'pin'],
          );
          for (final r in rows) {
            final id = (r['id'] ?? '').toString();
            final pin = (r['pin'] as String?) ?? '';
            if (id.isNotEmpty && pin.isNotEmpty) {
              try {
                await PinStore.instance.setPinForUser(id, pin);
              } catch (_) {}
            }
          }
        } catch (_) {
          // If the column doesn't exist or query fails, continue — we'll still
          // proceed to recreate the table without the column below.
        }

        await db.execute('''
          CREATE TABLE users_new (
            id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            full_name TEXT NOT NULL,
            email TEXT,
            role INTEGER NOT NULL,
            status INTEGER DEFAULT 1,
            last_login_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            phone_number TEXT
          )
        ''');

        // Copy data from old users table to new schema.
        // If the old schema used `name`/`is_active`/`role` as text, map them conservatively:
        // - username := name
        // - full_name := name
        // - role := 0 (unknown) since older role may be TEXT
        // - status := is_active (if present) else 1
        // - preserve created_at/updated_at
        await db.execute('''
          INSERT INTO users_new (id, username, full_name, email, role, status, last_login_at, created_at, updated_at, phone_number)
          SELECT id,
                 COALESCE(name, '') AS username,
                 COALESCE(name, '') AS full_name,
                 email,
                 0 AS role,
                 COALESCE(is_active, 1) AS status,
                 NULL AS last_login_at,
                 created_at,
                 updated_at,
                 NULL AS phone_number
          FROM users
        ''');

        await db.execute('DROP TABLE users');
        await db.execute("ALTER TABLE users_new RENAME TO users");

        // Recreate users indexes that might have been dropped during table swap
        try {
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_users_status ON users(status)',
          );
        } catch (_) {}
      } catch (_) {
        // If migration fails for any reason, ignore and allow older codepaths to continue.
      }
    }
  }

  Future<void> _createTables(Database db) async {
    // Business Information Table
    await db.execute('''
      CREATE TABLE business_info (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        tax_number TEXT,
        tax_rate REAL DEFAULT 0,
        currency TEXT DEFAULT 'USD',
        logo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Items Table
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category_id TEXT NOT NULL,
        sku TEXT,
        barcode TEXT,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        color_value INTEGER NOT NULL,
        is_available INTEGER DEFAULT 1,
        is_featured INTEGER DEFAULT 0,
        stock INTEGER DEFAULT 0,
        track_stock INTEGER DEFAULT 0,
        cost REAL,
        image_url TEXT,
        tags TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Users Table
    // Schema expected by DatabaseService and UserModel
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT,
        role INTEGER NOT NULL,
        status INTEGER DEFAULT 1,
        last_login_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        phone_number TEXT
      )
    ''');

    // Tables Table (Restaurant)
    await db.execute('''
      CREATE TABLE tables (
        id TEXT PRIMARY KEY,
        number INTEGER NOT NULL,
        seats INTEGER NOT NULL,
        status TEXT NOT NULL,
        section TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Payment Methods Table
    await db.execute('''
      CREATE TABLE payment_methods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Printers Table
    await db.execute('''
      CREATE TABLE printers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        connection_type TEXT NOT NULL,
        ip_address TEXT,
        port INTEGER,
        device_id TEXT,
        device_name TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Orders Table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL UNIQUE,
        table_id TEXT,
        user_id TEXT NOT NULL,
        status TEXT NOT NULL,
        order_type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        payment_method_id TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (table_id) REFERENCES tables (id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id)
      )
    ''');

    // Order Items Table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        item_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items (id)
      )
    ''');

    // Transactions Table (Payment History)
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        payment_method_id TEXT NOT NULL,
        amount REAL NOT NULL,
        change_amount REAL DEFAULT 0,
        transaction_date TEXT NOT NULL,
        receipt_number TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods (id)
      )
    ''');

    // Receipt Settings Table
    await db.execute('''
      CREATE TABLE receipt_settings (
        id TEXT PRIMARY KEY,
        header_text TEXT DEFAULT '',
        footer_text TEXT DEFAULT '',
        show_logo INTEGER DEFAULT 1,
        show_date_time INTEGER DEFAULT 1,
        show_order_number INTEGER DEFAULT 1,
        show_cashier_name INTEGER DEFAULT 1,
        show_tax_breakdown INTEGER DEFAULT 1,
        show_service_charge_breakdown INTEGER DEFAULT 1,
        show_thank_you_message INTEGER DEFAULT 1,
        auto_print INTEGER DEFAULT 0,
        paper_size TEXT DEFAULT 'mm80',
        paper_width INTEGER DEFAULT 80,
        font_size INTEGER DEFAULT 12,
        thank_you_message TEXT DEFAULT 'Thank you for your purchase!',
        terms_and_conditions TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Inventory Adjustments Table
    await db.execute('''
      CREATE TABLE inventory_adjustments (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        adjustment_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Cash Drawer Sessions Table
    await db.execute('''
      CREATE TABLE cash_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        opening_balance REAL NOT NULL,
        closing_balance REAL,
        expected_balance REAL,
        total_sales REAL DEFAULT 0,
        total_cash REAL DEFAULT 0,
        total_card REAL DEFAULT 0,
        total_other REAL DEFAULT 0,
        status TEXT NOT NULL,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Discounts Table
    await db.execute('''
      CREATE TABLE discounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        start_date TEXT,
        end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Modifier Groups Table
    await db.execute('''
      CREATE TABLE modifier_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        category_ids TEXT DEFAULT '',
        is_required INTEGER DEFAULT 0,
        allow_multiple INTEGER DEFAULT 0,
        min_selection INTEGER,
        max_selection INTEGER,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Modifier Items Table
    await db.execute('''
      CREATE TABLE modifier_items (
        id TEXT PRIMARY KEY,
        modifier_group_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        price_adjustment REAL DEFAULT 0,
        icon_code_point INTEGER,
        icon_font_family TEXT,
        color_value INTEGER,
        is_default INTEGER DEFAULT 0,
        is_available INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (modifier_group_id) REFERENCES modifier_groups (id) ON DELETE CASCADE
      )
    ''');

    // Item Modifiers Table (Variants, Add-ons) - Legacy/Simple modifiers
    await db.execute('''
      CREATE TABLE item_modifiers (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price_adjustment REAL DEFAULT 0,
        is_available INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    // Audit Log Table
    await db.execute('''
      CREATE TABLE audit_log (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        old_values TEXT,
        new_values TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    // Categories indexes
    await db.execute(
      'CREATE INDEX idx_categories_active ON categories(is_active)',
    );
    await db.execute(
      'CREATE INDEX idx_categories_sort ON categories(sort_order)',
    );

    // Items indexes
    await db.execute('CREATE INDEX idx_items_category ON items(category_id)');
    await db.execute('CREATE INDEX idx_items_available ON items(is_available)');
    await db.execute('CREATE INDEX idx_items_sku ON items(sku)');
    await db.execute('CREATE INDEX idx_items_barcode ON items(barcode)');

    // Orders indexes
    await db.execute('CREATE INDEX idx_orders_number ON orders(order_number)');
    await db.execute('CREATE INDEX idx_orders_status ON orders(status)');
    await db.execute('CREATE INDEX idx_orders_date ON orders(created_at)');
    await db.execute('CREATE INDEX idx_orders_user ON orders(user_id)');
    await db.execute('CREATE INDEX idx_orders_table ON orders(table_id)');

    // Order Items indexes
    await db.execute(
      'CREATE INDEX idx_order_items_order ON order_items(order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_order_items_item ON order_items(item_id)',
    );

    // Transactions indexes
    await db.execute(
      'CREATE INDEX idx_transactions_order ON transactions(order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(transaction_date)',
    );

    // Users indexes
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    // Use `status` column (new schema) instead of legacy `is_active`.
    await db.execute('CREATE INDEX idx_users_status ON users(status)');

    // Tables indexes
    await db.execute('CREATE INDEX idx_tables_status ON tables(status)');
    await db.execute('CREATE INDEX idx_tables_number ON tables(number)');

    // Inventory adjustments indexes
    await db.execute(
      'CREATE INDEX idx_inventory_item ON inventory_adjustments(item_id)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_date ON inventory_adjustments(created_at)',
    );

    // Cash sessions indexes
    await db.execute(
      'CREATE INDEX idx_cash_sessions_user ON cash_sessions(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cash_sessions_status ON cash_sessions(status)',
    );
    await db.execute(
      'CREATE INDEX idx_cash_sessions_date ON cash_sessions(opened_at)',
    );

    // Audit log indexes
    await db.execute('CREATE INDEX idx_audit_user ON audit_log(user_id)');
    await db.execute(
      'CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id)',
    );
    await db.execute('CREATE INDEX idx_audit_date ON audit_log(created_at)');

    // Modifier groups indexes
    await db.execute(
      'CREATE INDEX idx_modifier_groups_active ON modifier_groups(is_active)',
    );
    await db.execute(
      'CREATE INDEX idx_modifier_groups_sort ON modifier_groups(sort_order)',
    );

    // Modifier items indexes
    await db.execute(
      'CREATE INDEX idx_modifier_items_group ON modifier_items(modifier_group_id)',
    );
    await db.execute(
      'CREATE INDEX idx_modifier_items_available ON modifier_items(is_available)',
    );
    await db.execute(
      'CREATE INDEX idx_modifier_items_sort ON modifier_items(sort_order)',
    );
  }

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Insert default business info
    await db.insert('business_info', {
      'id': '1',
      'name': 'My Business',
      'address': '',
      'phone': '',
      'email': '',
      'tax_number': '',
      'tax_rate': 10.0,
      'currency': 'USD',
      'created_at': now,
      'updated_at': now,
    });

    // Insert default receipt settings
    await db.insert('receipt_settings', {
      'id': '1',
      'header_text': 'My Business',
      'footer_text': 'Thank you for your business!',
      'show_logo': 1,
      'show_date_time': 1,
      'show_order_number': 1,
      'show_cashier_name': 1,
      'show_tax_breakdown': 1,
      'show_service_charge_breakdown': 1,
      'show_thank_you_message': 1,
      'auto_print': 0,
      'paper_size': 'mm80',
      'paper_width': 80,
      'font_size': 12,
      'thank_you_message': 'Thank you for your purchase!',
      'terms_and_conditions': '',
      'created_at': now,
      'updated_at': now,
    });

    // Insert default admin user (match new users schema)
    await db.insert('users', {
      'id': '1',
      'username': 'admin',
      'full_name': 'Admin',
      'email': 'admin@example.com',
      // role as integer (0=admin by convention in older migrations)
      'role': 0,
      'status': 1,
      'last_login_at': null,
      'created_at': now,
      'updated_at': now,
      'phone_number': null,
    });

    // Insert default payment methods
    final paymentMethods = [
      'Cash',
      'Credit Card',
      'Debit Card',
      'Mobile Payment',
    ];
    for (int i = 0; i < paymentMethods.length; i++) {
      await db.insert('payment_methods', {
        'id': '${i + 1}',
        'name': paymentMethods[i],
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Helper method to reset database (for development/testing)
  Future<void> resetDatabase() async {
    final path =
        _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
    try {
      await deleteDatabase(path);
    } catch (_) {
      // ignore
    }
    _database = null;
    await database; // Reinitialize
  }

  /// Create a timestamped backup copy of the on-disk database file and
  /// return the absolute path to the backup file. Throws on failure.
  Future<String> backupDatabase() async {
    final path =
        _overrideDatabaseFilePath ??
        join(await getDatabasesPath(), 'extropos.db');
    final src = File(path);
    if (!await src.exists()) {
      throw Exception('Database file not found at $path');
    }

    final backupDir = dirname(path);
    final now = DateTime.now();
    final ts = now.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final destPath = join(backupDir, 'extropos_backup_$ts.db');
    final dest = File(destPath);

    await src.copy(dest.path);
    return dest.path;
  }

  /// Override the database file path. When non-null, the helper will open and
  /// reset the database at the given absolute file path. Intended for tests.
  static void overrideDatabaseFilePath(String? absoluteFilePath) {
    _overrideDatabaseFilePath = absoluteFilePath;
  }
}
