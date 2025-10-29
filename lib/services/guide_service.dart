import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing interactive guides, tutorials, and contextual help
class GuideService extends ChangeNotifier {
  static final GuideService instance = GuideService._init();
  GuideService._init();

  SharedPreferences? _prefs;
  final Map<String, bool> _completedGuides = {};
  final Set<String> _currentlyShowingGuides = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCompletedGuides();
  }

  void _loadCompletedGuides() {
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('guide_completed_')) {
        final guideName = key.replaceFirst('guide_completed_', '');
        _completedGuides[guideName] = _prefs!.getBool(key) ?? false;
      }
    }
  }

  /// Check if a guide has been completed
  bool hasCompletedGuide(String guideName) {
    return _completedGuides[guideName] ?? false;
  }

  /// Mark a guide as completed
  Future<void> markGuideCompleted(String guideName) async {
    _completedGuides[guideName] = true;
    await _prefs?.setBool('guide_completed_$guideName', true);
    notifyListeners();
  }

  /// Reset a specific guide
  Future<void> resetGuide(String guideName) async {
    _completedGuides[guideName] = false;
    await _prefs?.setBool('guide_completed_$guideName', false);
    notifyListeners();
  }

  /// Reset all guides
  Future<void> resetAllGuides() async {
    for (final guideName in _completedGuides.keys) {
      await _prefs?.setBool('guide_completed_$guideName', false);
    }
    _completedGuides.clear();
    notifyListeners();
  }

  /// Track which guides are currently being shown (prevent duplicates)
  bool isGuideCurrentlyShowing(String guideName) {
    return _currentlyShowingGuides.contains(guideName);
  }

  void markGuideAsShowing(String guideName) {
    _currentlyShowingGuides.add(guideName);
  }

  void markGuideAsHidden(String guideName) {
    _currentlyShowingGuides.remove(guideName);
  }
}

/// Represents a single step in an interactive guide
class GuideStep {
  final String title;
  final String description;
  final IconData icon;
  final String? targetKey; // GlobalKey identifier for highlighting
  final Offset? tooltipPosition;
  final List<String>? actionHints;

  const GuideStep({
    required this.title,
    required this.description,
    required this.icon,
    this.targetKey,
    this.tooltipPosition,
    this.actionHints,
  });
}

/// Predefined guides for common workflows
class PredefinedGuides {
  // Retail POS Guide
  static const String retailPOSIntro = 'retail_pos_intro';
  static const String retailFirstSale = 'retail_first_sale';
  static const String retailPayment = 'retail_payment';

  // Cafe POS Guide
  static const String cafePOSIntro = 'cafe_pos_intro';
  static const String cafeOrderPlacement = 'cafe_order_placement';
  static const String cafeActiveOrders = 'cafe_active_orders';

  // Restaurant POS Guide
  static const String restaurantPOSIntro = 'restaurant_pos_intro';
  static const String restaurantTableSelection = 'restaurant_table_selection';
  static const String restaurantOrderManagement = 'restaurant_order_management';

  // Settings Guides
  static const String categoriesSetup = 'categories_setup';
  static const String itemsSetup = 'items_setup';
  static const String businessInfoSetup = 'business_info_setup';
  static const String receiptSettingsSetup = 'receipt_settings_setup';

  static List<GuideStep> getGuideSteps(String guideName) {
    switch (guideName) {
      case retailPOSIntro:
        return _retailPOSIntroSteps;
      case retailFirstSale:
        return _retailFirstSaleSteps;
      case cafePOSIntro:
        return _cafePOSIntroSteps;
      case restaurantPOSIntro:
        return _restaurantPOSIntroSteps;
      case categoriesSetup:
        return _categoriesSetupSteps;
      case itemsSetup:
        return _itemsSetupSteps;
      default:
        return [];
    }
  }

  static final List<GuideStep> _retailPOSIntroSteps = [
    const GuideStep(
      title: 'Welcome to Retail Mode',
      description: 'This is your retail point of sale screen. Let\'s walk through the key features.',
      icon: Icons.shopping_bag,
    ),
    const GuideStep(
      title: 'Product Categories',
      description: 'Browse products by category. Tap a category to filter the product list.',
      icon: Icons.category,
      actionHints: ['Tap on a category tab', 'Products will filter automatically'],
    ),
    const GuideStep(
      title: 'Product Grid',
      description: 'Tap any product to add it to your cart. The cart appears on the right side.',
      icon: Icons.grid_view,
      actionHints: ['Tap a product card', 'It will be added to the cart'],
    ),
    const GuideStep(
      title: 'Shopping Cart',
      description: 'View your cart on the right. Adjust quantities with +/- buttons or remove items.',
      icon: Icons.shopping_cart,
      actionHints: ['Increase/decrease quantity', 'Remove items if needed'],
    ),
    const GuideStep(
      title: 'Checkout Process',
      description: 'When ready, tap "Checkout" to select a payment method and complete the sale.',
      icon: Icons.payment,
      actionHints: ['Tap Checkout button', 'Select payment method', 'Complete transaction'],
    ),
  ];

  static final List<GuideStep> _retailFirstSaleSteps = [
    const GuideStep(
      title: 'Making Your First Sale',
      description: 'Let\'s process a complete transaction from start to finish.',
      icon: Icons.sell,
    ),
    const GuideStep(
      title: 'Step 1: Add Products',
      description: 'Tap on at least one product to add it to the cart.',
      icon: Icons.add_shopping_cart,
      actionHints: ['Select products from the grid', 'Adjust quantities as needed'],
    ),
    const GuideStep(
      title: 'Step 2: Review Cart',
      description: 'Check the cart summary. Notice the subtotal, tax, and total amounts.',
      icon: Icons.receipt,
      actionHints: ['Verify product list', 'Check pricing', 'Review totals'],
    ),
    const GuideStep(
      title: 'Step 3: Checkout',
      description: 'Tap the Checkout button to proceed to payment selection.',
      icon: Icons.point_of_sale,
    ),
    const GuideStep(
      title: 'Step 4: Select Payment',
      description: 'Choose a payment method (Cash, Card, etc.) and complete the transaction.',
      icon: Icons.credit_card,
      actionHints: ['Choose payment method', 'Enter amount if cash', 'Confirm payment'],
    ),
  ];

  static final List<GuideStep> _cafePOSIntroSteps = [
    const GuideStep(
      title: 'Welcome to Cafe Mode',
      description: 'Cafe mode is designed for quick service with order numbers. Let\'s explore the features.',
      icon: Icons.local_cafe,
    ),
    const GuideStep(
      title: 'Order Number System',
      description: 'Each order gets a unique number. Customers can track their order status using this number.',
      icon: Icons.tag,
    ),
    const GuideStep(
      title: 'Building Orders',
      description: 'Add items to the cart just like retail mode. The cart shows on the right side.',
      icon: Icons.add_circle,
      actionHints: ['Browse categories', 'Tap items to add', 'Adjust quantities'],
    ),
    const GuideStep(
      title: 'Complete Order',
      description: 'Tap "Complete Order" to assign an order number and process payment.',
      icon: Icons.done,
      actionHints: ['Complete order', 'Select payment', 'Order number displayed'],
    ),
    const GuideStep(
      title: 'Active Orders',
      description: 'View all active orders by tapping the "Active Orders" button at the top.',
      icon: Icons.list_alt,
      actionHints: ['Tap Active Orders', 'See all pending orders', 'Track order status'],
    ),
  ];

  static final List<GuideStep> _restaurantPOSIntroSteps = [
    const GuideStep(
      title: 'Welcome to Restaurant Mode',
      description: 'Restaurant mode features table management for full-service dining.',
      icon: Icons.restaurant,
    ),
    const GuideStep(
      title: 'Table Selection',
      description: 'Start by selecting a table from the table grid. Each table shows its current status.',
      icon: Icons.table_restaurant,
      actionHints: ['Available tables are green', 'Occupied tables are orange', 'Tap to select'],
    ),
    const GuideStep(
      title: 'Table Orders',
      description: 'Once you select a table, you can add items to that table\'s order.',
      icon: Icons.restaurant_menu,
      actionHints: ['Add items', 'Orders saved to table', 'Return anytime to view/edit'],
    ),
    const GuideStep(
      title: 'Save or Checkout',
      description: 'You can save an order to return later, or checkout to complete the transaction.',
      icon: Icons.save,
      actionHints: ['Save: keeps table occupied', 'Checkout: completes & frees table'],
    ),
  ];

  static final List<GuideStep> _categoriesSetupSteps = [
    const GuideStep(
      title: 'Managing Categories',
      description: 'Categories help organize your products. Let\'s set up your first category.',
      icon: Icons.category,
    ),
    const GuideStep(
      title: 'Add a Category',
      description: 'Tap the + button to create a new category. Give it a name, icon, and color.',
      icon: Icons.add_circle,
      actionHints: ['Tap + button', 'Enter category name', 'Choose icon and color', 'Save'],
    ),
    const GuideStep(
      title: 'Edit Categories',
      description: 'Tap any category card to edit its details or change the sort order.',
      icon: Icons.edit,
      actionHints: ['Tap category card', 'Update fields', 'Save changes'],
    ),
    const GuideStep(
      title: 'Using Categories',
      description: 'Categories appear in all POS modes to filter products quickly.',
      icon: Icons.filter_list,
    ),
  ];

  static final List<GuideStep> _itemsSetupSteps = [
    const GuideStep(
      title: 'Managing Items',
      description: 'Items are the products you sell. Let\'s add your first item.',
      icon: Icons.inventory,
    ),
    const GuideStep(
      title: 'Add an Item',
      description: 'Tap the + button. Enter the item name, price, category, and other details.',
      icon: Icons.add_box,
      actionHints: ['Tap + button', 'Fill in item details', 'Assign to category', 'Set price', 'Save'],
    ),
    const GuideStep(
      title: 'Stock Tracking (Optional)',
      description: 'Enable stock tracking if you want to monitor inventory levels for this item.',
      icon: Icons.inventory_2,
      actionHints: ['Toggle "Track Stock"', 'Set initial stock level', 'Low stock alerts available'],
    ),
    const GuideStep(
      title: 'Item Visibility',
      description: 'Items marked as available will appear in POS screens immediately.',
      icon: Icons.visibility,
    ),
  ];
}
