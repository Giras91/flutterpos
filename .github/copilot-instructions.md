# FlutterPOS - AI Coding Agent Instructions

## Project Overview

**FlutterPOS** is a multi-mode Point of Sale (POS) system built with Flutter for desktop (Windows). It supports three distinct business modes:
- **Retail Mode**: Direct sales with immediate checkout
- **Cafe Mode**: Order-by-calling-number system for takeaway/counter service
- **Restaurant Mode**: Full table management with table service workflow

**Platform**: Windows desktop application (Flutter Windows)
**Architecture**: Single-page app with mode-based navigation, no state management library
**Data Persistence**: Currently in-memory (mock data), no database integration yet

---

## Architecture & Data Flow

### Application Entry Point
- **main.dart** → **ModeSelectionScreen** (home screen)
- User selects business mode → Navigate to mode-specific POS screen
- All modes share common models but have different workflows

### Three-Mode Architecture

```
ModeSelectionScreen (Root)
├── Retail Mode → RetailPOSScreen
│   └── Direct checkout with cart
├── Cafe Mode → CafePOSScreen
│   └── Order numbers + active orders modal
└── Restaurant Mode → TableSelectionScreen
    └── POSOrderScreen (per-table)
```

### Business Mode Logic (`lib/models/business_mode.dart`)
```dart
enum BusinessMode { retail, cafe, restaurant }

// Mode determines:
// - hasTableManagement: restaurant only
// - useCallingNumbers: cafe only
// - workflow: direct sale vs order tracking
```

### Global Singleton Pattern - BusinessInfo
**CRITICAL**: `BusinessInfo.instance` is a global singleton used across all screens for:
- Tax settings (`isTaxEnabled`, `taxRate`)
- Service charge settings (`isServiceChargeEnabled`, `serviceChargeRate`)
- Currency display (`currencySymbol`, default "RM")
- Business details (name, address, tax number, etc.)

**Always access via**: `BusinessInfo.instance`
**To update**: Call `BusinessInfo.updateInstance(newInfo)` after making changes

---

## Key Models & Their Relationships

### Product → CartItem → RestaurantTable Flow

1. **Product** (`lib/models/product.dart`): Immutable catalog items
   - Properties: `name`, `price`, `category`, `icon`
   - No quantity - just represents the product definition

2. **CartItem** (`lib/models/cart_item.dart`): Product + quantity wrapper
   - `final Product product`
   - `int quantity` (mutable)
   - Used in all cart/order contexts

3. **RestaurantTable** (`lib/models/table_model.dart`): Restaurant mode only
   - Manages: `List<CartItem> orders`, `TableStatus`, `capacity`
   - Stateful: `status` changes (available → occupied → available)
   - Methods: `addOrder()`, `clearOrders()`, `totalAmount`, `itemCount`

### Tax & Service Charge Calculation Pattern

**ALL POS screens must implement this pattern**:

```dart
double getSubtotal() {
  return cartItems.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);
}

double getTaxAmount() {
  final info = BusinessInfo.instance;
  return info.isTaxEnabled ? getSubtotal() * info.taxRate : 0.0;
}

double getServiceChargeAmount() {
  final info = BusinessInfo.instance;
  return info.isServiceChargeEnabled ? getSubtotal() * info.serviceChargeRate : 0.0;
}

double getTotal() {
  return getSubtotal() + getTaxAmount() + getServiceChargeAmount();
}
```

**Display Pattern**:
```dart
// Conditionally show tax/service charge rows based on enabled flags
if (BusinessInfo.instance.isTaxEnabled) ...[
  Text('Tax (${BusinessInfo.instance.taxRatePercentage})'),
  Text('${BusinessInfo.instance.currencySymbol} ${getTaxAmount().toStringAsFixed(2)}'),
],
```

---

## Screen Responsibilities

### Mode Selection → Settings Hierarchy

```
ModeSelectionScreen
└── Settings (FAB) → SettingsScreen
    ├── Printers Management
    ├── Users Management
    ├── Tables Management (restaurant setup)
    └── Business Information (tax/service charge toggles)
```

### POS Screen Patterns

#### Retail Mode (`retail_pos_screen.dart`)
- **Layout**: Products grid (left 70%) | Cart sidebar (right 30%)
- **Cart State**: Local `List<CartItem> cartItems` 
- **Workflow**: Add to cart → Checkout → Clear cart
- **No persistence**: Cart cleared after checkout

#### Cafe Mode (`cafe_pos_screen.dart`)
- **Layout**: Products grid (left 70%) | Cart + Order number (right 30%)
- **Cart State**: Local `List<CartItem> cartItems`
- **Order Tracking**: `List<CafeOrder> activeOrders` with auto-incrementing `nextOrderNumber`
- **Workflow**: Add to cart → Complete order (generates order #) → New order
- **Modal**: Active orders shown in bottom sheet with GridView

#### Restaurant Mode (`table_selection_screen.dart` → `pos_order_screen.dart`)
- **Two-screen flow**:
  1. Table selection grid (shows table status)
  2. Per-table order screen (passed `RestaurantTable` instance)
- **Cart State**: Stored IN the `RestaurantTable.orders` (persistent across navigation)
- **Workflow**: Select table → Add items → Save & return OR Checkout
- **Table Status**: Auto-updates to `occupied` when items added

### Settings Screens

#### Business Info Screen (`business_info_screen.dart`)
- **Tax & Service Charge Dialog**: 
  - Enable/disable toggles
  - Percentage rate inputs (entered as whole numbers, stored as decimals)
  - Updates `BusinessInfo.instance` → affects ALL POS calculations immediately
- **Business Hours**: Separate screen with per-day time ranges
- **Important**: Uses `copyWith()` pattern for updates

#### Tables Management (`tables_management_screen.dart`)
- CRUD for `RestaurantTable` definitions
- **Stats cards**: Total tables, available, occupied counts
- **Grid layout**: Responsive columns (1-4 based on screen width)
- **Dialogs**: Add/edit table with name, capacity inputs

---

## Responsive Design Standards

### CRITICAL: All screens MUST be overflow-safe

**Problem**: Flutter's default layouts cause "BOTTOM OVERFLOW" errors on small screens or when windows resize.

**Solution Pattern Applied**:

#### 1. GridView with Adaptive Columns
```dart
LayoutBuilder(
  builder: (context, constraints) {
    int crossAxisCount = 4; // default
    if (constraints.maxWidth < 600) crossAxisCount = 1;
    else if (constraints.maxWidth < 900) crossAxisCount = 2;
    else if (constraints.maxWidth < 1200) crossAxisCount = 3;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        // ... other properties
      ),
      // ...
    );
  },
)
```

#### 2. Text Overflow Protection
```dart
// Always wrap text in constrained spaces with:
Flexible(
  child: Text(
    'Long text that might overflow',
    overflow: TextOverflow.ellipsis,
  ),
)
```

#### 3. Scrollable Dialogs
```dart
// Replace fixed SizedBox with:
ConstrainedBox(
  constraints: BoxConstraints(
    maxWidth: 400,
    maxHeight: MediaQuery.of(context).size.height * 0.6,
  ),
  child: SingleChildScrollView(
    child: Column(/* form fields */),
  ),
)
```

#### 4. Responsive Card Layouts
```dart
// Use LayoutBuilder to switch between Row/Wrap:
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 800) {
      return Wrap(spacing: 16, children: cards);
    } else {
      return Row(children: cards.map((c) => Expanded(child: c)).toList());
    }
  },
)
```

**Breakpoints Used**:
- `< 600px`: Mobile (1 column)
- `600-900px`: Small tablet (2 columns)
- `900-1200px`: Tablet (3 columns)
- `≥ 1200px`: Desktop (4+ columns)

---

## Reusable Widgets

### CartItemWidget (`lib/widgets/cart_item_widget.dart`)
- Standard cart line item with +/- quantity buttons
- **Props**: `CartItem item`, `VoidCallback onRemove`, `VoidCallback onAdd`
- **Used in**: All three POS modes
- Displays: Product name, unit price, quantity controls, line total

### ProductCard (`lib/widgets/product_card.dart`)
- Grid item for product selection
- **Props**: `Product product`, `VoidCallback onTap`
- Shows: Product icon, name, price
- Tap → adds to cart (handled by parent)

---

## Common Patterns & Conventions

### Navigation Pattern
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TargetScreen()),
);

// For data return (e.g., table orders):
final result = await Navigator.push<List<CartItem>>(...);
if (result != null) {
  // Handle returned data
}
```

### Color Scheme
- **Primary Blue**: `Color(0xFF2563EB)` (AppBar, buttons, accents)
- **Background**: `Colors.grey[100]` for main areas
- **Cards**: White with elevation
- **Text**: Black87 for primary, `Colors.grey[600]` for secondary

### Currency Formatting
```dart
'${BusinessInfo.instance.currencySymbol} ${amount.toStringAsFixed(2)}'
// Example: "RM 12.50"
```

### Mock Data Location
- Products: Defined locally in each POS screen (not centralized)
- Tables: Defined in `TablesManagementScreen` and `TableSelectionScreen`
- Reports: Defined in `ReportsScreen`

---

## Testing & Development

### Run Commands
```bash
cd d:\flutterpos\flutterpos
flutter analyze  # Check for errors
flutter run -d windows  # Run on Windows
```

### Current Limitations (Future Work)
- No database/persistence (all data in-memory)
- No authentication system
- Payment methods not implemented
- Printer integration not functional
- Reports are mock data only

---

## Common Pitfalls & Solutions

### ❌ WRONG: Fixed crossAxisCount
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4, // Will overflow on small screens!
  ),
)
```

### ✅ CORRECT: Adaptive columns with LayoutBuilder
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final columns = constraints.maxWidth < 600 ? 1 : 
                    constraints.maxWidth < 900 ? 2 : 4;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
      ),
    );
  },
)
```

### ❌ WRONG: Forgetting to check BusinessInfo flags
```dart
double getTotal() {
  return subtotal + (subtotal * 0.10); // Hardcoded tax!
}
```

### ✅ CORRECT: Always use BusinessInfo.instance
```dart
double getTaxAmount() {
  final info = BusinessInfo.instance;
  return info.isTaxEnabled ? getSubtotal() * info.taxRate : 0.0;
}
```

### ❌ WRONG: Modifying CartItem.product
```dart
cartItem.product.price = 100; // Product is immutable!
```

### ✅ CORRECT: Modify quantity, not product
```dart
cartItem.quantity += 1; // Quantity is mutable
```

---

## When Making Changes

### Adding a New Feature Checklist
1. ✅ Does it need to work across all 3 modes? → Update all POS screens
2. ✅ Does it involve pricing? → Use BusinessInfo.instance for tax/service charge
3. ✅ Does it have a grid/list? → Use LayoutBuilder for responsive columns
4. ✅ Does it have dialogs? → Make them scrollable with ConstrainedBox
5. ✅ Does it use text in constrained space? → Add `overflow: TextOverflow.ellipsis`
6. ✅ Run `flutter analyze` before committing

### Modifying BusinessInfo
1. Update `business_info_model.dart` fields
2. Update `copyWith()` method
3. Update dialog in `business_info_screen.dart`
4. Test all 3 POS modes to ensure calculations work

### Adding a New Screen
1. Create in `lib/screens/`
2. Add to Settings if it's a management screen
3. Ensure responsive layout from the start (use LayoutBuilder)
4. Follow existing navigation patterns

---

## Code Style Preferences

- **State Management**: Local `setState()` only, no BLoC/Provider/Riverpod
- **Immutability**: Models are final where possible, use `copyWith()` for updates
- **Widget Extraction**: Use private `_WidgetName` classes in same file for complex components
- **Naming**: 
  - Screens: `*Screen` suffix
  - Models: No suffix, descriptive nouns
  - Private widgets: `_WidgetName` prefix
- **Constants**: Color values as `const Color(0xFF...)` inline
- **Imports**: Material first, then models, then widgets

---

## Quick Reference: File Organization

```
lib/
├── main.dart                        # App entry point
├── models/                          # Data models (immutable where possible)
│   ├── business_info_model.dart    # Global singleton for tax/currency/business data
│   ├── business_mode.dart          # Enum for retail/cafe/restaurant
│   ├── cart_item.dart              # Product + quantity wrapper
│   ├── product.dart                # Product catalog item
│   ├── table_model.dart            # Restaurant table with orders
│   ├── sales_report.dart           # Reporting data structures
│   ├── user_model.dart             # Staff user accounts
│   └── printer_model.dart          # Printer configurations
├── screens/                         # Full-page screens
│   ├── mode_selection_screen.dart  # Root/home screen
│   ├── retail_pos_screen.dart      # Retail mode POS
│   ├── cafe_pos_screen.dart        # Cafe mode POS with order numbers
│   ├── table_selection_screen.dart # Restaurant table grid
│   ├── pos_order_screen.dart       # Per-table order screen (restaurant)
│   ├── settings_screen.dart        # Settings hub
│   ├── business_info_screen.dart   # Tax/business settings
│   ├── tables_management_screen.dart
│   ├── users_management_screen.dart
│   ├── printers_management_screen.dart
│   └── reports_screen.dart
└── widgets/                         # Reusable widgets
    ├── cart_item_widget.dart       # Cart line item with +/- buttons
    └── product_card.dart           # Product grid item
```

---

## Summary: What Makes This Codebase Unique

1. **Three-mode architecture**: Same codebase serves different workflows (retail/cafe/restaurant)
2. **Global singleton**: `BusinessInfo.instance` controls tax/currency across entire app
3. **Stateful tables**: Restaurant mode persists cart data IN the table model
4. **Responsive-first**: All layouts must handle window resizing gracefully
5. **No external state management**: Pure Flutter setState() approach
6. **Desktop-focused**: Windows primary platform, not mobile-first

When in doubt:
- Check existing POS screens for patterns
- Always use LayoutBuilder for grids
- Always check BusinessInfo.instance for tax/currency
- Keep mock data local to screens (for now)
