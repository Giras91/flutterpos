import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
// ignore_for_file: use_build_context_synchronously
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/business_info_model.dart';
import '../models/payment_method_model.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../services/formatting_service.dart';
import '../services/database_service.dart';
import '../services/printer_service.dart';
import '../services/dual_display_service.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/responsive_layout.dart';
import 'payment_screen.dart';
import 'receipt_preview_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class RetailPOSScreen extends StatefulWidget {
  const RetailPOSScreen({super.key});

  @override
  State<RetailPOSScreen> createState() => _RetailPOSScreenState();
}

class _RetailPOSScreenState extends State<RetailPOSScreen> {
  String selectedCategory = 'All';
  final List<CartItem> cartItems = [];

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
    _loadFromDatabase();
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

  void addToCart(Product p) {
    setState(() {
      final index = cartItems.indexWhere(
        (c) => c.product.name == p.name && c.modifiers.isEmpty,
      );
      if (index != -1) {
        cartItems[index].quantity++;
      } else {
        cartItems.add(CartItem(p, 1));
      }
    });
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

  void clearCart() => setState(() => cartItems.clear());

  double getSubtotal() => cartItems.fold(0.0, (s, c) => s + c.totalPrice);

  double getTaxAmount() {
    final info = BusinessInfo.instance;
    return info.isTaxEnabled ? getSubtotal() * info.taxRate : 0.0;
  }

  double getServiceChargeAmount() {
    final info = BusinessInfo.instance;
    return info.isServiceChargeEnabled
        ? getSubtotal() * info.serviceChargeRate
        : 0.0;
  }

  double getTotal() =>
      getSubtotal() + getTaxAmount() + getServiceChargeAmount();

  Future<void> _onCheckoutPressed() async {
    // Show order total on customer display when checkout starts
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
          availablePaymentMethods: paymentMethods,
          cartItems: cartItems,
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    if (result != null && result['success'] == true) {
      final paymentMethod = result['paymentMethod'] as PaymentMethod;
      final change = result['change'] as double;
      final amountPaid = (result['amountPaid'] as double?) ?? getTotal();

      // Show payment amount on customer display
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

      // Auto-print if enabled in settings (fire and forget, don't block UI)
      _tryAutoPrint(
        items: itemsSnapshot,
        subtotal: getSubtotal(),
        tax: getTaxAmount(),
        serviceCharge: getServiceChargeAmount(),
        total: getTotal(),
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        change: change,
      ).catchError((_) {
        // Silently ignore errors
      });

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

      parentMessenger.showSnackBar(
        SnackBar(
          content: Text('Payment successful! Method: ${paymentMethod.name}'),
        ),
      );

      // Show change amount on customer display
      if (change > 0) {
        await DualDisplayService().showChange(
          change,
          BusinessInfo.instance.currencySymbol,
        );
      }

      // Show thank you message on customer display
      await DualDisplayService().showThankYou();

      clearCart();
    }
  }

  // Auto-print receipt if enabled in settings
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
      // Load receipt settings to check if auto-print is enabled
      final settings = await DatabaseService.instance.getReceiptSettings();

      developer.log(
        'AUTO-PRINT: Settings loaded, autoPrint=${settings.autoPrint}',
      );

      if (!settings.autoPrint) {
        developer.log('AUTO-PRINT: Disabled in settings');
        return; // Auto-print is disabled
      }

      // Get printer service
      final printerService = PrinterService();

      // Check if there's a printer available (use discovery + first available)
      developer.log('AUTO-PRINT: Discovering printers...');
      final printers = await printerService.discoverPrinters();
      developer.log('AUTO-PRINT: Found ${printers.length} printers');

      if (printers.isEmpty) {
        developer.log('AUTO-PRINT: No printers found, skipping');
        return; // No printer found, skip auto-print
      }

      final printer = printers.first;
      developer.log(
        'AUTO-PRINT: Using printer: ${printer.name} (${printer.type.name})',
      );

      // Build receipt content matching ReceiptPreviewScreen format
      final buffer = StringBuffer();
      final info = BusinessInfo.instance;
      final currency = info.currencySymbol;
      final now = DateTime.now();

      // Header
      buffer.writeln(info.businessName);
      buffer.writeln(info.fullAddress);
      if (info.taxNumber != null && info.taxNumber!.isNotEmpty) {
        buffer.writeln('Tax No: ${info.taxNumber}');
      }
      buffer.writeln('');
      buffer.writeln('Order');
      buffer.writeln(_formatDateTime(now));
      buffer.writeln('');

      // Items
      for (var item in items) {
        buffer.writeln(
          '${item.product.name} x${item.quantity}  $currency ${item.totalPrice.toStringAsFixed(2)}',
        );
        if (item.modifiers.isNotEmpty) {
          final modsText = item.modifiers
              .map(
                (m) => m.priceAdjustment == 0
                    ? m.name
                    : '${m.name} (${m.getPriceAdjustmentDisplay()})',
              )
              .join(', ');
          buffer.writeln('  $modsText');
        }
      }

      buffer.writeln('');
      buffer.writeln('Subtotal: $currency ${subtotal.toStringAsFixed(2)}');

      if (info.isTaxEnabled) {
        buffer.writeln(
          'Tax (${info.taxRatePercentage}): $currency ${tax.toStringAsFixed(2)}',
        );
      }

      if (info.isServiceChargeEnabled) {
        buffer.writeln(
          'Service Charge (${info.serviceChargeRatePercentage}): $currency ${serviceCharge.toStringAsFixed(2)}',
        );
      }

      buffer.writeln('Total: $currency ${total.toStringAsFixed(2)}');
      buffer.writeln('Payment: ${paymentMethod.name}');
      buffer.writeln('Paid: $currency ${amountPaid.toStringAsFixed(2)}');
      if (change > 0) {
        buffer.writeln('Change: $currency ${change.toStringAsFixed(2)}');
      }
      buffer.writeln('');
      buffer.writeln('Thank you!');

      final receiptData = {
        'title': 'Receipt',
        'content': buffer.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Try to print silently (don't show errors to user, this is background)
      developer.log('AUTO-PRINT: Sending to printer...');
      await printerService.printReceipt(printer, receiptData);
      developer.log('AUTO-PRINT: Print command sent successfully');
    } catch (e) {
      // Silently fail - auto-print is a convenience feature, not critical
      developer.log('AUTO-PRINT ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = selectedCategory == 'All'
        ? products
        : products.where((p) => p.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Retail Mode'),
        backgroundColor: const Color(0xFF2563EB),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ResponsiveLayout(
        builder: (context, constraints, info) {
          // Use info.width and info.columns to choose stacked vs side-by-side
          final isNarrow = info.width < 900;

          if (isNarrow) {
            return Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: SizedBox(
                          height: 56,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final c = categories[index];
                              final isSelected = c == selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                child: FilterChip(
                                  label: Text(c),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      setState(() => selectedCategory = c),
                                  selectedColor: const Color(0xFF2563EB),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: filteredProducts.isEmpty
                            ? SingleChildScrollView(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 56,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No items available.\nOpen Settings → Database Test to restore demo data.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(context).push(
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
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: info.columns.clamp(1, 2),
                                      childAspectRatio: 0.85,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) => ProductCard(
                                  product: filteredProducts[index],
                                  onTap: () =>
                                      addToCart(filteredProducts[index]),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                // Constrain the totals panel height on narrow screens so it
                // doesn't force the products area to overflow on very short
                // viewports (e.g., landscape phones). Wrap the totals in a
                // SizedBox with a scrollable child so internal rows can
                // scroll when space is tight.
                SizedBox(
                  height: math.min(320.0, info.height * 0.5),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(FormattingService.currency(getSubtotal())),
                            ],
                          ),
                          if (BusinessInfo.instance.isTaxEnabled) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tax (${BusinessInfo.instance.taxRatePercentage})',
                                ),
                                Text(
                                  FormattingService.currency(getTaxAmount()),
                                ),
                              ],
                            ),
                          ],
                          if (BusinessInfo.instance.isServiceChargeEnabled) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Service Charge (${BusinessInfo.instance.serviceChargeRatePercentage})',
                                ),
                                Text(
                                  FormattingService.currency(
                                    getServiceChargeAmount(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                FormattingService.currency(getTotal()),
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: cartItems.isEmpty
                                      ? null
                                      : clearCart,
                                  child: const Text('Clear'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: cartItems.isEmpty
                                      ? null
                                      : _onCheckoutPressed,
                                  child: const Text('Checkout'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Wide layout: use info.columns for grid and show cart sidebar
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: SizedBox(
                        height: 56,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final c = categories[index];
                            final isSelected = c == selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: FilterChip(
                                label: Text(c),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => selectedCategory = c),
                                selectedColor: const Color(0xFF2563EB),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          final cols = info.columns.clamp(1, 4);
                          if (filteredProducts.isEmpty) {
                            return SingleChildScrollView(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 56,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No items available.\nOpen Settings → Database Test to restore demo data.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).push(
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
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) => ProductCard(
                              product: filteredProducts[index],
                              onTap: () => addToCart(filteredProducts[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: info.width < 1100 ? info.width * 0.35 : 380,
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRect(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.shopping_cart),
                                      SizedBox(width: 12),
                                      Text(
                                        'Current Order',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                // Use Flexible so the list can shrink when height is constrained
                                Flexible(
                                  child: cartItems.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Cart is empty',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.all(12),
                                          itemCount: cartItems.length,
                                          itemBuilder: (context, index) =>
                                              CartItemWidget(
                                                item: cartItems[index],
                                                onRemove: () =>
                                                    removeFromCart(index),
                                                onAdd: () => addToCart(
                                                  cartItems[index].product,
                                                ),
                                              ),
                                        ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, -3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Subtotal'),
                                          Text(
                                            FormattingService.currency(
                                              getSubtotal(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (BusinessInfo
                                          .instance
                                          .isTaxEnabled) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Tax (${BusinessInfo.instance.taxRatePercentage})',
                                            ),
                                            Text(
                                              FormattingService.currency(
                                                getTaxAmount(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (BusinessInfo
                                          .instance
                                          .isServiceChargeEnabled) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Service Charge (${BusinessInfo.instance.serviceChargeRatePercentage})',
                                            ),
                                            Text(
                                              FormattingService.currency(
                                                getServiceChargeAmount(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            FormattingService.currency(
                                              getTotal(),
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: cartItems.isEmpty
                                                  ? null
                                                  : clearCart,
                                              child: const Text('Clear'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton(
                                              onPressed: cartItems.isEmpty
                                                  ? null
                                                  : _onCheckoutPressed,
                                              child: const Text('Checkout'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
