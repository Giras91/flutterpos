# ExtroPOS Database Schema Documentation

## Overview
ExtroPOS uses SQLite database for local data persistence. The database is designed to support a complete Point of Sale system with inventory management, order processing, user management, and reporting capabilities.

**Database File**: `extropos.db`  
**Current Version**: 1  
**Location**: Application's database directory (platform-specific)

---

## Core Tables

### 1. business_info
Stores business/store information and settings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier |
| name | TEXT | NOT NULL | Business name |
| address | TEXT | | Business address |
| phone | TEXT | | Contact phone number |
| email | TEXT | | Contact email |
| tax_number | TEXT | | Tax registration number |
| tax_rate | REAL | DEFAULT 0 | Default tax rate (percentage) |
| currency | TEXT | DEFAULT 'USD' | Currency code (USD, EUR, etc.) |
| logo_path | TEXT | | Path to business logo file |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Note**: Single record table (id = '1')

---

### 2. categories
Product categories for organizing inventory.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| name | TEXT | NOT NULL | Category name |
| description | TEXT | | Category description |
| icon_code_point | INTEGER | NOT NULL | Flutter IconData code point |
| icon_font_family | TEXT | | Icon font family name |
| color_value | INTEGER | NOT NULL | ARGB color value |
| sort_order | INTEGER | DEFAULT 0 | Display order (ascending) |
| is_active | INTEGER | DEFAULT 1 | Active status (1=active, 0=inactive) |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Indexes**:
- `idx_categories_active` on (is_active)
- `idx_categories_sort` on (sort_order)

---

### 3. items
Products/items available for sale.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| name | TEXT | NOT NULL | Item name |
| description | TEXT | | Item description |
| price | REAL | NOT NULL | Selling price |
| category_id | TEXT | NOT NULL, FK | References categories(id) |
| sku | TEXT | | Stock Keeping Unit code |
| barcode | TEXT | | Barcode/UPC |
| icon_code_point | INTEGER | NOT NULL | Flutter IconData code point |
| icon_font_family | TEXT | | Icon font family name |
| color_value | INTEGER | NOT NULL | ARGB color value |
| is_available | INTEGER | DEFAULT 1 | Available for sale (1=yes, 0=no) |
| is_featured | INTEGER | DEFAULT 0 | Featured item (1=yes, 0=no) |
| stock | INTEGER | DEFAULT 0 | Current stock quantity |
| track_stock | INTEGER | DEFAULT 0 | Enable stock tracking (1=yes, 0=no) |
| cost | REAL | | Item cost (for profit calculation) |
| image_url | TEXT | | Path to item image |
| tags | TEXT | | JSON array of tags |
| sort_order | INTEGER | DEFAULT 0 | Display order within category |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Keys**:
- category_id → categories(id) ON DELETE CASCADE

**Indexes**:
- `idx_items_category` on (category_id)
- `idx_items_available` on (is_available)
- `idx_items_sku` on (sku)
- `idx_items_barcode` on (barcode)

---

### 4. users
Staff/employee user accounts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| name | TEXT | NOT NULL | User full name |
| email | TEXT | | Email address |
| pin | TEXT | NOT NULL | PIN code for login |
| role | TEXT | NOT NULL | User role (admin, cashier, waiter, etc.) |
| is_active | INTEGER | DEFAULT 1 | Active status (1=active, 0=inactive) |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Indexes**:
- `idx_users_email` on (email)
- `idx_users_active` on (is_active)

**Roles**: admin, manager, cashier, waiter, kitchen

---

### 5. tables
Restaurant table management (for dine-in mode).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| number | INTEGER | NOT NULL | Table number |
| seats | INTEGER | NOT NULL | Number of seats |
| status | TEXT | NOT NULL | Table status (available, occupied, reserved) |
| section | TEXT | | Section/area name |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Indexes**:
- `idx_tables_status` on (status)
- `idx_tables_number` on (number)

**Status Values**: available, occupied, reserved, cleaning

---

### 6. payment_methods
Available payment methods.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| name | TEXT | NOT NULL | Payment method name |
| is_active | INTEGER | DEFAULT 1 | Active status (1=active, 0=inactive) |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Default Values**: Cash, Credit Card, Debit Card, Mobile Payment

---

### 7. printers
Configured printers for receipts and kitchen orders.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| name | TEXT | NOT NULL | Printer name |
| type | TEXT | NOT NULL | Printer type (receipt, kitchen, label) |
| connection_type | TEXT | NOT NULL | Connection type (network, usb, bluetooth) |
| ip_address | TEXT | | Network printer IP address |
| port | INTEGER | | Network printer port |
| device_id | TEXT | | USB/Bluetooth device ID |
| device_name | TEXT | | USB/Bluetooth device name |
| is_default | INTEGER | DEFAULT 0 | Default printer (1=yes, 0=no) |
| is_active | INTEGER | DEFAULT 1 | Active status (1=active, 0=inactive) |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Types**: receipt, kitchen, label  
**Connection Types**: network, usb, bluetooth

---

## Transaction Tables

### 8. orders
Customer orders/sales.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| order_number | TEXT | NOT NULL, UNIQUE | Human-readable order number |
| table_id | TEXT | FK | References tables(id) (nullable) |
| user_id | TEXT | NOT NULL, FK | References users(id) |
| status | TEXT | NOT NULL | Order status |
| order_type | TEXT | NOT NULL | Order type (dine-in, takeout, delivery) |
| subtotal | REAL | NOT NULL | Subtotal before tax |
| tax | REAL | NOT NULL | Tax amount |
| discount | REAL | DEFAULT 0 | Discount amount |
| total | REAL | NOT NULL | Final total |
| payment_method_id | TEXT | FK | References payment_methods(id) |
| notes | TEXT | | Order notes/comments |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |
| completed_at | TEXT | | Completion timestamp |

**Foreign Keys**:
- table_id → tables(id) ON DELETE SET NULL
- user_id → users(id)
- payment_method_id → payment_methods(id)

**Indexes**:
- `idx_orders_number` on (order_number)
- `idx_orders_status` on (status)
- `idx_orders_date` on (created_at)
- `idx_orders_user` on (user_id)
- `idx_orders_table` on (table_id)

**Status Values**: pending, preparing, ready, completed, cancelled  
**Order Types**: dine-in, takeout, delivery, retail

---

### 9. order_items
Line items for each order.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| order_id | TEXT | NOT NULL, FK | References orders(id) |
| item_id | TEXT | NOT NULL, FK | References items(id) |
| item_name | TEXT | NOT NULL | Item name (snapshot) |
| item_price | REAL | NOT NULL | Item price at time of order |
| quantity | INTEGER | NOT NULL | Quantity ordered |
| subtotal | REAL | NOT NULL | Line total (price × quantity) |
| notes | TEXT | | Item-specific notes |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Keys**:
- order_id → orders(id) ON DELETE CASCADE
- item_id → items(id)

**Indexes**:
- `idx_order_items_order` on (order_id)
- `idx_order_items_item` on (item_id)

---

### 10. transactions
Payment transaction records.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| order_id | TEXT | NOT NULL, FK | References orders(id) |
| payment_method_id | TEXT | NOT NULL, FK | References payment_methods(id) |
| amount | REAL | NOT NULL | Payment amount |
| change_amount | REAL | DEFAULT 0 | Change given |
| transaction_date | TEXT | NOT NULL | ISO 8601 timestamp |
| receipt_number | TEXT | | Receipt number |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Keys**:
- order_id → orders(id) ON DELETE CASCADE
- payment_method_id → payment_methods(id)

**Indexes**:
- `idx_transactions_order` on (order_id)
- `idx_transactions_date` on (transaction_date)

---

## Configuration Tables

### 11. receipt_settings
Receipt printing configuration.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier |
| header_text | TEXT | DEFAULT '' | Receipt header text |
| footer_text | TEXT | DEFAULT '' | Receipt footer text |
| show_logo | INTEGER | DEFAULT 1 | Show logo (1=yes, 0=no) |
| show_date_time | INTEGER | DEFAULT 1 | Show date/time (1=yes, 0=no) |
| show_order_number | INTEGER | DEFAULT 1 | Show order number (1=yes, 0=no) |
| show_cashier_name | INTEGER | DEFAULT 1 | Show cashier name (1=yes, 0=no) |
| show_tax_breakdown | INTEGER | DEFAULT 1 | Show tax breakdown (1=yes, 0=no) |
| show_thank_you_message | INTEGER | DEFAULT 1 | Show thank you message (1=yes, 0=no) |
| auto_print | INTEGER | DEFAULT 0 | Auto-print receipts (1=yes, 0=no) |
| paper_size | TEXT | DEFAULT 'mm80' | Paper size (mm58, mm80, a4) |
| paper_width | INTEGER | DEFAULT 80 | Paper width in mm |
| font_size | INTEGER | DEFAULT 12 | Font size in points |
| thank_you_message | TEXT | DEFAULT 'Thank you for your purchase!' | Custom thank you message |
| terms_and_conditions | TEXT | DEFAULT '' | Terms and conditions text |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Note**: Single record table (id = '1')

---

## Inventory Management Tables

### 12. inventory_adjustments
Inventory adjustment history.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| item_id | TEXT | NOT NULL, FK | References items(id) |
| adjustment_type | TEXT | NOT NULL | Adjustment type |
| quantity | INTEGER | NOT NULL | Adjustment quantity (+ or -) |
| reason | TEXT | | Adjustment reason |
| user_id | TEXT | NOT NULL, FK | References users(id) |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Keys**:
- item_id → items(id) ON DELETE CASCADE
- user_id → users(id)

**Indexes**:
- `idx_inventory_item` on (item_id)
- `idx_inventory_date` on (created_at)

**Adjustment Types**: manual, sale, purchase, damage, loss, return

---

### 13. cash_sessions
Cash drawer opening/closing sessions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| user_id | TEXT | NOT NULL, FK | References users(id) |
| opening_balance | REAL | NOT NULL | Starting cash amount |
| closing_balance | REAL | | Counted cash at closing |
| expected_balance | REAL | | Calculated expected cash |
| total_sales | REAL | DEFAULT 0 | Total sales during session |
| total_cash | REAL | DEFAULT 0 | Total cash payments |
| total_card | REAL | DEFAULT 0 | Total card payments |
| total_other | REAL | DEFAULT 0 | Total other payments |
| status | TEXT | NOT NULL | Session status (open, closed) |
| opened_at | TEXT | NOT NULL | Opening timestamp |
| closed_at | TEXT | | Closing timestamp |
| notes | TEXT | | Session notes |

**Foreign Keys**:
- user_id → users(id)

**Indexes**:
- `idx_cash_sessions_user` on (user_id)
- `idx_cash_sessions_status` on (status)
- `idx_cash_sessions_date` on (opened_at)

**Status Values**: open, closed

---

## Additional Features Tables

### 14. discounts
Discount/promotion definitions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| name | TEXT | NOT NULL | Discount name |
| type | TEXT | NOT NULL | Discount type (percentage, fixed) |
| value | REAL | NOT NULL | Discount value |
| is_active | INTEGER | DEFAULT 1 | Active status (1=active, 0=inactive) |
| start_date | TEXT | | Start date (ISO 8601) |
| end_date | TEXT | | End date (ISO 8601) |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Types**: percentage, fixed

---

### 15. item_modifiers
Item variants and add-ons (e.g., size, extras).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| item_id | TEXT | NOT NULL, FK | References items(id) |
| name | TEXT | NOT NULL | Modifier name |
| price_adjustment | REAL | DEFAULT 0 | Price adjustment (+ or -) |
| is_available | INTEGER | DEFAULT 1 | Available (1=yes, 0=no) |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |
| updated_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Keys**:
- item_id → items(id) ON DELETE CASCADE

**Examples**: Small, Medium, Large, Extra Cheese, No Onions

---

### 16. audit_log
Audit trail for system actions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | Unique identifier (UUID) |
| user_id | TEXT | FK | References users(id) (nullable) |
| action | TEXT | NOT NULL | Action performed |
| entity_type | TEXT | NOT NULL | Entity type affected |
| entity_id | TEXT | | Entity ID affected |
| old_values | TEXT | | JSON of old values |
| new_values | TEXT | | JSON of new values |
| created_at | TEXT | NOT NULL | ISO 8601 timestamp |

**Foreign Keys**:
- user_id → users(id)

**Indexes**:
- `idx_audit_user` on (user_id)
- `idx_audit_entity` on (entity_type, entity_id)
- `idx_audit_date` on (created_at)

**Actions**: create, update, delete, login, logout, void_order, refund

---

## Data Relationships

```
business_info (1) - Standalone configuration

categories (1) ───< (N) items
                     │
                     └──< (N) order_items
                            │
                            └──> (1) orders ──> (1) users
                                      │         
                                      ├──> (1) tables
                                      ├──> (1) payment_methods
                                      └──< (N) transactions

users (1) ───< (N) orders
         └───< (N) cash_sessions
         └───< (N) inventory_adjustments
         └───< (N) audit_log

items (1) ───< (N) item_modifiers
         └───< (N) inventory_adjustments

payment_methods (1) ───< (N) transactions
                   └───< (N) orders

printers (N) - Standalone configuration
receipt_settings (1) - Standalone configuration
discounts (N) - Standalone configuration
```

---

## Best Practices

### Data Integrity
- Use transactions for multi-table operations
- Always set timestamps (created_at, updated_at)
- Use CASCADE deletes where appropriate
- Maintain referential integrity

### Performance
- Leverage indexes for frequent queries
- Use EXPLAIN QUERY PLAN for optimization
- Avoid N+1 queries with proper JOINs
- Consider pagination for large result sets

### Security
- Never store sensitive data unencrypted
- Use parameterized queries to prevent SQL injection
- Implement proper user role validation
- Audit sensitive operations in audit_log

### Maintenance
- Regular database backups
- Monitor database size
- Vacuum database periodically
- Archive old transactions

---

## Version History

### Version 1 (Current)
- Initial database schema
- Core POS functionality
- Inventory management
- User management
- Reporting capabilities
- Audit logging

---

## Migration Guide

When upgrading database versions, the `_upgradeDB` method in `DatabaseHelper` will handle schema migrations automatically.

### Example Migration (Version 1 → 2)
```dart
Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add new column
    await db.execute('ALTER TABLE items ADD COLUMN new_field TEXT');
    
    // Create new table
    await db.execute('''CREATE TABLE new_table (...)''');
    
    // Update existing data
    await db.execute('UPDATE items SET new_field = "default"');
  }
}
```

---

## Database Utilities

### Backup
```dart
// Copy database file to backup location
final dbPath = await getDatabasesPath();
final source = File(join(dbPath, 'extropos.db'));
final backup = File(join(backupPath, 'extropos_${DateTime.now().millisecondsSinceEpoch}.db'));
await source.copy(backup.path);
```

### Reset (Development Only)
```dart
await DatabaseHelper.instance.resetDatabase();
```

### Export Data
```dart
// Export orders to JSON
final db = await DatabaseHelper.instance.database;
final orders = await db.query('orders');
final json = jsonEncode(orders);
```

---

**Document Version**: 1.0  
**Last Updated**: October 26, 2025  
**Maintainer**: ExtroPOS Development Team
