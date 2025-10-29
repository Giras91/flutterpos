# ExtroPOS Database Entity Relationship Diagram

## Quick Reference

### Core Entities
```
┌─────────────────┐
│  business_info  │ (Configuration)
└─────────────────┘

┌─────────────┐      ┌──────────┐      ┌───────────────┐
│ categories  │◄─────┤  items   │◄─────┤ item_modifiers│
└─────────────┘  1:N └──────────┘  1:N └───────────────┘
                         │
                         │ 1:N
                         ▼
                  ┌──────────────┐
                  │ order_items  │
                  └──────────────┘
                         │
                         │ N:1
                         ▼
┌─────────┐      ┌──────────┐      ┌──────────────────┐
│  users  │◄─────┤  orders  │─────►│ payment_methods  │
└─────────┘  1:N └──────────┘  N:1 └──────────────────┘
    │                 │ 1:N               │
    │ 1:N             ▼                   │ 1:N
    │          ┌──────────────┐           │
    │          │transactions  │◄──────────┘
    │          └──────────────┘
    │
    │          ┌──────────┐
    └─────────►│  tables  │
         N:1   └──────────┘
```

### Supporting Entities
```
┌─────────┐      ┌───────────────────────┐
│  users  │◄─────┤  cash_sessions       │
└─────────┘  1:N └───────────────────────┘
    │
    │ 1:N
    ▼
┌─────────────────────────┐      ┌──────────┐
│ inventory_adjustments   │─────►│  items   │
└─────────────────────────┘  N:1 └──────────┘

┌─────────┐      ┌─────────────┐
│  users  │◄─────┤  audit_log  │
└─────────┘  1:N └─────────────┘

┌──────────────────┐
│ receipt_settings │ (Configuration)
└──────────────────┘

┌───────────┐
│ printers  │ (Configuration)
└───────────┘

┌───────────┐
│ discounts │ (Configuration)
└───────────┘
```

## Table Categories

### 🏢 Business Configuration
- **business_info**: Core business details and settings
- **receipt_settings**: Receipt printing preferences
- **printers**: Printer configurations

### 📦 Product Management
- **categories**: Product categories
- **items**: Products/menu items
- **item_modifiers**: Variants and add-ons

### 👥 User Management
- **users**: Staff accounts
- **audit_log**: Action tracking

### 🛒 Sales & Orders
- **orders**: Customer orders
- **order_items**: Order line items
- **transactions**: Payment records

### 🍽️ Restaurant Features
- **tables**: Table management
- **payment_methods**: Payment options

### 📊 Inventory
- **inventory_adjustments**: Stock changes
- **cash_sessions**: Cash drawer sessions

### 💰 Promotions
- **discounts**: Discount definitions

## Key Relationships

### Order Processing Flow
```
User → Order → Order Items → Items
                ↓
           Transaction → Payment Method
```

### Inventory Management
```
Items ← Inventory Adjustments ← User
  ↓
Stock Level Updates
```

### Restaurant Operations
```
Table → Order → Order Items
         ↓
       User (Waiter/Cashier)
```

### Cash Management
```
User → Cash Session → Transactions
         ↓
    Opening/Closing Balance
```

## Cascade Rules

### ON DELETE CASCADE
- categories → items (delete items when category deleted)
- items → order_items (maintain referential integrity)
- items → item_modifiers (delete modifiers with item)
- items → inventory_adjustments (keep history)
- orders → order_items (delete items with order)
- orders → transactions (delete payments with order)

### ON DELETE SET NULL
- tables → orders (preserve orders when table deleted)

## Index Strategy

### High-Priority Indexes (Frequent Queries)
- orders.created_at (date range queries)
- orders.status (filtering by status)
- order_items.order_id (joining orders)
- items.category_id (category filtering)
- transactions.transaction_date (reporting)

### Lookup Indexes
- items.sku (SKU lookups)
- items.barcode (barcode scanning)
- orders.order_number (order search)
- users.email (login)

### Composite Index Opportunities
- (order_items.order_id, item_id) - order item lookups
- (orders.user_id, created_at) - user sales history
- (inventory_adjustments.item_id, created_at) - item history

## Data Flow Diagrams

### Creating an Order
```
1. User selects items → Add to cart
2. Cart items → Create order_items
3. Calculate totals → Create order
4. Process payment → Create transaction
5. Update inventory (if tracked)
6. Print receipt
```

### Inventory Adjustment
```
1. User initiates adjustment
2. Create inventory_adjustment record
3. Update items.stock
4. Log in audit_log
```

### End of Day Process
```
1. Close cash session
2. Calculate expected vs actual
3. Generate sales report
4. Reconcile transactions
5. Update audit_log
```

## Query Examples

### Top Selling Items
```sql
SELECT i.name, SUM(oi.quantity) as total_sold
FROM order_items oi
JOIN items i ON oi.item_id = i.id
JOIN orders o ON oi.order_id = o.id
WHERE o.created_at >= date('now', '-30 days')
GROUP BY i.id
ORDER BY total_sold DESC
LIMIT 10;
```

### Daily Sales Summary
```sql
SELECT 
  date(created_at) as sale_date,
  COUNT(*) as order_count,
  SUM(total) as total_sales,
  SUM(tax) as total_tax
FROM orders
WHERE status = 'completed'
GROUP BY date(created_at)
ORDER BY sale_date DESC;
```

### Low Stock Alert
```sql
SELECT id, name, stock
FROM items
WHERE track_stock = 1 AND stock <= 10
ORDER BY stock ASC;
```

### User Performance
```sql
SELECT 
  u.name,
  COUNT(o.id) as orders_processed,
  SUM(o.total) as total_sales
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE o.created_at >= date('now', '-7 days')
GROUP BY u.id
ORDER BY total_sales DESC;
```

---

**Diagram Version**: 1.0  
**Compatible with**: Database Schema v1  
**Last Updated**: October 26, 2025
