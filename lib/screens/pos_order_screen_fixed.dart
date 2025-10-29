import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
// ignore_for_file: use_build_context_synchronously
import '../models/table_model.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/payment_method_model.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../models/modifier_item_model.dart';
import '../services/database_service.dart';
import '../services/app_settings.dart';
import 'items_management_screen.dart';
import '../services/formatting_service.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/modifier_selection_dialog.dart';
import '../widgets/responsive_layout.dart';
// guide_service and guide_widgets not used in this screen (kept in other POS screens)
// reports_screen is not used here; remove unused imports to silence warnings.
import '../models/business_info_model.dart';
import 'payment_screen.dart';
import 'receipt_preview_screen.dart';
import '../services/reset_service.dart';
import '../services/printer_service.dart';
import '../services/dual_display_service.dart';
import 'settings_screen.dart';

class POSOrderScreen extends StatefulWidget {
  final RestaurantTable table;

  const POSOrderScreen({super.key, required this.table});

  @override
  State<POSOrderScreen> createState() => _POSOrderScreenState();
}

class _POSOrderScreenState extends State<POSOrderScreen> {
  String selectedCategory = 'All';
  late List<CartItem> cartItems;

  // Start empty by default — no fallback mock products or categories on first load
  List<String> categories = ['All'];

  List<Product> products = [];

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: '1', name: 'Cash', isDefault: true),
    PaymentMethod(id: '2', name: 'Credit Card'),
    PaymentMethod(id: '3', name: 'Debit Card'),
  ];

  @override
  void initState() {
    super.initState();
    cartItems = List.from(widget.table.orders);
    _loadFromDatabase();
    // Listen for global reset events
    ResetService.instance.addListener(_handleReset);
  }

  @override
  void dispose() {
    ResetService.instance.removeListener(_handleReset);
    super.dispose();
  }

  void _handleReset() {
    if (!mounted) return;
    setState(() {
      cartItems.clear();
    });
  }

  Future<void> _loadFromDatabase() async {
    try {
      final List<Category> dbCategories = await DatabaseService.instance
          .getCategories();
      final List<Item> dbItems = await DatabaseService.instance.getItems();

      // Update categories if any exist in DB
      if (dbCategories.isNotEmpty) {
        final List<String> newCategories = [
          'All',
          ...dbCategories.map((c) => c.name),
        ];
        if (mounted) {
          setState(() {
            categories = newCategories;
            if (!categories.contains(selectedCategory)) {
              selectedCategory = 'All';
            }
          });
        }
      }

      // Update products if any exist in DB
      if (dbItems.isNotEmpty) {
        final Map<String, Category> catById = {
          for (final c in dbCategories) c.id: c,
        };
        final List<Product> newProducts = dbItems.map((it) {
          final catName = catById[it.categoryId]?.name ?? 'Uncategorized';
          return Product(it.name, it.price, catName, it.icon);
        }).toList();
        if (mounted) {
          setState(() {
            products = newProducts;
          });
        }
      }
    } catch (e) {
      developer.log('Failed to load categories/items from DB: $e');
      // Leave categories/products empty (no fallback mock data)
    }
  }

  Future<void> addToCart(Product product) async {
    try {
      final items = await DatabaseService.instance.getItems();
      final item = items.firstWhere(
        (it) => it.name == product.name,
        orElse: () => Item(
          id: '',
          name: product.name,
          price: product.price,
          categoryId: '',
          description: '',
          icon: Icons.fastfood,
          color: Colors.blue,
        ),
      );

      String categoryId = item.categoryId;
      if (categoryId.isEmpty) {
        final categories = await DatabaseService.instance.getCategories();
        final category = categories.firstWhere(
          (c) => c.name == product.category,
          orElse: () => Category(
            id: '',
            name: '',
            description: '',
            icon: Icons.category,
            color: Colors.grey,
            sortOrder: 0,
          ),
        );
        categoryId = category.id;
      }

      List<ModifierItem> selectedModifiers = [];
      double priceAdjustment = 0.0;

      if (categoryId.isNotEmpty) {
        if (!mounted) return;
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) =>
              ModifierSelectionDialog(item: item, categoryId: categoryId),
        );

        if (!mounted) return;
        if (result == null) return;

        selectedModifiers = result['modifiers'] as List<ModifierItem>;
        priceAdjustment = result['priceAdjustment'] as double;
      }

      setState(() {
        final existingIndex = cartItems.indexWhere(
          (ci) => ci.hasSameConfiguration(product, selectedModifiers),
        );

        if (existingIndex != -1) {
          cartItems[existingIndex].quantity++;
        } else {
          cartItems.add(
            CartItem(
              product,
              1,
              modifiers: selectedModifiers,
              priceAdjustment: priceAdjustment,
            ),
          );
        }
      });
    } catch (e) {
      if (AppSettings.instance.requireDbProducts) {
        if (!mounted) return;
        final parentNavigator = Navigator.of(context);
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Product not in database'),
            content: const Text(
              'This product is not available in the database. Please add it in Items Management before selling.',
            ),
            actions: [
              TextButton(
                onPressed: () => parentNavigator.pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  parentNavigator.pop();
                  parentNavigator.push(
                    MaterialPageRoute(
                      builder: (_) => const ItemsManagementScreen(),
                    ),
                  );
                },
                child: const Text('Add Item'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        final existingIndex = cartItems.indexWhere(
          (item) => item.product.name == product.name,
        );
        if (existingIndex != -1) {
          cartItems[existingIndex].quantity++;
        } else {
          cartItems.add(CartItem(product, 1));
        }
      });
    }
  }

  void removeFromCart(int index) {
    setState(() {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity--;
      } else {
        cartItems.removeAt(index);
      }
    });
  }

  void clearCart() {
    setState(() {
      cartItems.clear();
    });
  }

  double getSubtotal() {
    return cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double getTaxAmount() {
    final businessInfo = BusinessInfo.instance;
    if (!businessInfo.isTaxEnabled) return 0;
    return getSubtotal() * businessInfo.taxRate;
  }

  double getServiceChargeAmount() {
    final businessInfo = BusinessInfo.instance;
    if (!businessInfo.isServiceChargeEnabled) return 0;
    return getSubtotal() * businessInfo.serviceChargeRate;
  }

  double getTotal() {
    return getSubtotal() + getTaxAmount() + getServiceChargeAmount();
  }

  void _saveAndReturn() {
    Navigator.pop(context, cartItems);
  }

  void _checkout() async {
    await DualDisplayService().showOrderTotal(
      getTotal(),
      BusinessInfo.instance.currencySymbol,
    );

    final parentNavigator = Navigator.of(context);
    final parentMessenger = ScaffoldMessenger.of(context);
    final result = await parentNavigator.push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: getTotal(),
          cartItems: cartItems,
          availablePaymentMethods: paymentMethods,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      final paymentMethod = result['paymentMethod'] as PaymentMethod;
      final change = result['change'] as double;
      final amountPaid = (result['amountPaid'] as double?) ?? getTotal();

      await DualDisplayService().showPaymentAmount(
        amountPaid,
        BusinessInfo.instance.currencySymbol,
      );

      final itemsSnapshot = cartItems
          .map(
            (ci) => CartItem(
              ci.product,
              ci.quantity,
              modifiers: ci.modifiers,
              priceAdjustment: ci.priceAdjustment,
            ),
          )
          .toList();

      String? orderNumber;
      try {
        orderNumber = await DatabaseService.instance.saveCompletedSale(
          cartItems: itemsSnapshot,
          subtotal: getSubtotal(),
          tax: getTaxAmount(),
          serviceCharge: getServiceChargeAmount(),
          total: getTotal(),
          paymentMethod: paymentMethod,
          amountPaid: amountPaid,
          change: change,
          orderType: 'restaurant',
          tableId: widget.table.id,
        );
      } catch (_) {}

      if (!mounted) return;

      final tableName = widget.table.name;
      final paymentName = paymentMethod.name;
      final savedOrderNote = orderNumber != null
          ? ' (Saved as $orderNumber)'
          : '';

      _tryAutoPrint(
        items: itemsSnapshot,
        subtotal: getSubtotal(),
        tax: getTaxAmount(),
        serviceCharge: getServiceChargeAmount(),
        total: getTotal(),
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        change: change,
      ).catchError((_) {});

      await parentNavigator.push(
        MaterialPageRoute(
          builder: (_) => ReceiptPreviewScreen(
            items: itemsSnapshot,
            subtotal: getSubtotal(),
            tax: getTaxAmount(),
            serviceCharge: getServiceChargeAmount(),
            total: getTotal(),
            paymentMethod: paymentMethod,
            amountPaid: amountPaid,
            change: change,
          ),
        ),
      );
      if (!mounted) return;
      parentMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Order completed for $tableName! Payment: $paymentName${change > 0 ? ', Change: ${FormattingService.currency(change)}' : ''}$savedOrderNote',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      if (change > 0) {
        await DualDisplayService().showChange(
          change,
          BusinessInfo.instance.currencySymbol,
        );
      }

      await DualDisplayService().showThankYou();

      if (!mounted) return;
      parentNavigator.pop(<CartItem>[]);
    }
  }

  Future<void> _tryAutoPrint({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
  }) async {
    try {
      developer.log('AUTO-PRINT (Restaurant): Checking settings...');
      final settings = await DatabaseService.instance.getReceiptSettings();
      developer.log('AUTO-PRINT (Restaurant): autoPrint=${settings.autoPrint}');

      if (!settings.autoPrint) {
        developer.log('AUTO-PRINT (Restaurant): Disabled in settings');
        return;
      }

      final printerService = PrinterService();
      developer.log('AUTO-PRINT (Restaurant): Discovering printers...');
      final printers = await printerService.discoverPrinters();
      developer.log(
        'AUTO-PRINT (Restaurant): Found ${printers.length} printers',
      );

      if (printers.isEmpty) {
        developer.log('AUTO-PRINT (Restaurant): No printers found, skipping');
        return;
      }

      // pick the first printer and send a simple receipt print
      final printer = printers.first;

      // Build a structured receipt data map expected by PrinterService.printReceipt
      final receiptData = <String, dynamic>{
        'title': 'Receipt',
        'timestamp': DateTime.now().toIso8601String(),
        'business': {
          'name': BusinessInfo.instance.businessName,
          'address': BusinessInfo.instance.fullAddress,
          'taxNumber': BusinessInfo.instance.taxNumber,
        },
        'items': items
            .map(
              (ci) => {
                'name': ci.product.name,
                'quantity': ci.quantity,
                'unitPrice': ci.product.price,
                'lineTotal': ci.totalPrice,
                'modifiers': ci.modifiers
                    .map(
                      (m) => {
                        'id': m.id,
                        'name': m.name,
                        'priceAdjustment': m.priceAdjustment,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
        'subtotal': subtotal,
        'tax': tax,
        'serviceCharge': serviceCharge,
        'total': total,
        'paymentMethod': {'id': paymentMethod.id, 'name': paymentMethod.name},
        'amountPaid': amountPaid,
        'change': change,
      };

      await printerService.printReceipt(printer, receiptData);
    } catch (e) {
      developer.log('AUTO-PRINT failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Table: ${widget.table.name}'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ResponsiveLayout(
        builder: (context, constraints, info) {
          final isNarrow = info.width < 900;

          Widget productsArea(double containerWidth) {
            final leftWidth = containerWidth;
            return SizedBox(
              width: leftWidth,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category selector
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) {
                          final name = categories[idx];
                          final isSel = name == selectedCategory;
                          return ChoiceChip(
                            label: Text(name),
                            selected: isSel,
                            onSelected: (_) {
                              setState(() {
                                selectedCategory = name;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Products area or empty-state hint
                    Expanded(
                      child: products.isEmpty
                          ? SingleChildScrollView(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 56,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No products available',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'No products or categories are present in the database. To restore demo data for testing, open Settings → Database Test and choose a demo dataset.',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SettingsScreen(),
                                          ),
                                        ),
                                        child: const Text('Open Settings'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: (leftWidth / 200)
                                        .floor()
                                        .clamp(1, 6),
                                    childAspectRatio: 1.1,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                  ),
                              itemCount: products.length,
                              itemBuilder: (_, index) {
                                final p = products[index];
                                if (selectedCategory != 'All' &&
                                    p.category != selectedCategory) {
                                  return const SizedBox.shrink();
                                }
                                return ProductCard(
                                  product: p,
                                  onTap: () => addToCart(p),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget cartPanel() {
            return Container(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Avoid IntrinsicHeight inside viewports — it can trigger
                    // expensive/unsupported intrinsic measurements on some
                    // platforms. Use two modes:
                    // 1) For short heights, render a fully scrollable column so
                    //    the whole panel can scroll (no IntrinsicHeight needed).
                    // 2) For sufficient height, size the panel to the
                    //    available height and use an Expanded ListView so the
                    //    footer remains pinned.
                    if (constraints.maxHeight < 260) {
                      // Very short: make everything scrollable
                      return ClipRect(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Cart',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                cartItems.isEmpty
                                    ? const Center(child: Text('Cart is empty'))
                                    : Column(
                                        children: cartItems
                                            .map(
                                              (ci) => CartItemWidget(
                                                item: ci,
                                                onAdd: () {
                                                  setState(() => ci.quantity++);
                                                },
                                                onRemove: () => removeFromCart(
                                                  cartItems.indexOf(ci),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subtotal: ${FormattingService.currency(getSubtotal())}',
                                ),
                                if (BusinessInfo.instance.isTaxEnabled)
                                  Text(
                                    'Tax: ${FormattingService.currency(getTaxAmount())}',
                                  ),
                                if (BusinessInfo
                                    .instance
                                    .isServiceChargeEnabled)
                                  Text(
                                    'Service: ${FormattingService.currency(getServiceChargeAmount())}',
                                  ),
                                Text(
                                  'Total: ${FormattingService.currency(getTotal())}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: cartItems.isEmpty
                                            ? null
                                            : _checkout,
                                        child: const Text('Checkout'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: cartItems.isEmpty
                                            ? null
                                            : _saveAndReturn,
                                        child: const Text('Save & Return'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: clearCart,
                                  child: const Text('Clear Cart'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Normal mode: enough height to pin footer and let the
                    // middle list expand/scroll.
                    return ClipRect(
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Cart',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: cartItems.isEmpty
                                  ? const Center(child: Text('Cart is empty'))
                                  : ListView.separated(
                                      itemCount: cartItems.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(),
                                      itemBuilder: (_, idx) {
                                        final ci = cartItems[idx];
                                        return CartItemWidget(
                                          item: ci,
                                          onAdd: () {
                                            setState(() => ci.quantity++);
                                          },
                                          onRemove: () => removeFromCart(idx),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Subtotal: ${FormattingService.currency(getSubtotal())}',
                            ),
                            if (BusinessInfo.instance.isTaxEnabled)
                              Text(
                                'Tax: ${FormattingService.currency(getTaxAmount())}',
                              ),
                            if (BusinessInfo.instance.isServiceChargeEnabled)
                              Text(
                                'Service: ${FormattingService.currency(getServiceChargeAmount())}',
                              ),
                            Text(
                              'Total: ${FormattingService.currency(getTotal())}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: cartItems.isEmpty
                                        ? null
                                        : _checkout,
                                    child: const Text('Checkout'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: cartItems.isEmpty
                                        ? null
                                        : _saveAndReturn,
                                    child: const Text('Save & Return'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: clearCart,
                              child: const Text('Clear Cart'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          if (isNarrow) {
            // Cap the cart panel height relative to available height so on
            // very short screens it doesn't consume almost the entire view and
            // cause the products area to overflow.
            final cartHeight = math.min(360.0, info.height * 0.45);
            return Column(
              children: [
                Expanded(child: productsArea(info.width)),
                SizedBox(height: cartHeight, child: cartPanel()),
              ],
            );
          }

          final leftWidth = info.width * 0.65;
          return Row(
            children: [
              Expanded(flex: 3, child: productsArea(leftWidth)),
              Expanded(child: cartPanel()),
            ],
          );
        },
      ),
    );
  }
}
