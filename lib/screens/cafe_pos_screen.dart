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
import '../models/printer_model.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/responsive_layout.dart';
import 'payment_screen.dart';
import 'settings_screen.dart';

class CafePOSScreen extends StatefulWidget {
  const CafePOSScreen({super.key});

  @override
  State<CafePOSScreen> createState() => _CafePOSScreenState();
}

class CafeOrder {
  final int number;
  final List<CartItem> items;
  final DateTime createdAt;
  bool called;
  bool completed;

  CafeOrder({
    required this.number,
    required this.items,
    required this.createdAt,
    this.called = false,
    this.completed = false,
  });

  double get subtotal => items.fold(0.0, (s, c) => s + c.totalPrice);
}

class _CafePOSScreenState extends State<CafePOSScreen> {
  final List<CartItem> cartItems = [];
  final List<CafeOrder> activeOrders = [];
  int nextOrderNumber = 1;

  String selectedCategory = 'All';
  // Start empty by default — no fallback mock products or categories on first load
  List<String> categories = ['All'];

  List<Product> products = [];

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: 'cash', name: 'Cash', isDefault: true),
    PaymentMethod(id: 'card', name: 'Card'),
    PaymentMethod(id: 'ewallet', name: 'E-Wallet'),
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

  // Cart ops
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

  // Totals with BusinessInfo pattern
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
    if (cartItems.isEmpty) return;

    // Show order total on customer display when checkout starts
    await DualDisplayService().showOrderTotal(
      getTotal(),
      BusinessInfo.instance.currencySymbol,
    );

    final parentNav = Navigator.of(context);
    final result = await parentNav.push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: getTotal(),
          availablePaymentMethods: paymentMethods,
          cartItems: cartItems,
        ),
      ),
    );

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

      final myOrderNumber = nextOrderNumber++;

      // Push order to active orders (calling system)
      setState(() {
        activeOrders.add(
          CafeOrder(
            number: myOrderNumber,
            items: itemsSnapshot,
            createdAt: DateTime.now(),
          ),
        );
      });

      // Auto print with order number
      _tryAutoPrint(
        orderNumber: myOrderNumber,
        items: itemsSnapshot,
        subtotal: getSubtotal(),
        tax: getTaxAmount(),
        serviceCharge: getServiceChargeAmount(),
        total: getTotal(),
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        change: change,
      ).ignore();

      // Show a brief confirmation and clear cart
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #$myOrderNumber created. Payment successful.'),
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

  // Auto-print receipt with prominent calling number
  Future<void> _tryAutoPrint({
    required int orderNumber,
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
      developer.log('AUTO-PRINT (Cafe): Checking settings...');
      final settings = await DatabaseService.instance.getReceiptSettings();
      developer.log('AUTO-PRINT (Cafe): autoPrint=${settings.autoPrint}');
      if (!settings.autoPrint) return;

      final printerService = PrinterService();
      developer.log('AUTO-PRINT (Cafe): Discovering printers...');
      final printers = await printerService.discoverPrinters();
      developer.log('AUTO-PRINT (Cafe): Found ${printers.length} printers');

      if (printers.isEmpty) {
        developer.log(
          'AUTO-PRINT (Cafe): No printers found, trying external service...',
        );
        // Fallback: try external service if available
        final buffer = _buildReceiptBuffer(
          orderNumber: orderNumber,
          items: items,
          subtotal: subtotal,
          tax: tax,
          serviceCharge: serviceCharge,
          total: total,
          paymentMethod: paymentMethod,
          amountPaid: amountPaid,
          change: change,
        );
        // Map receipt settings paper size to printer paper size
        final ps = settings.paperSize.name == 'mm58'
            ? ThermalPaperSize.mm58
            : ThermalPaperSize.mm80;
        await printerService.printViaExternalService({
          'title': 'ORDER #$orderNumber',
          'content': buffer.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        }, paperSize: ps);
        debugPrint('AUTO-PRINT (Cafe): External service called');
        return;
      }

      final printer = printers.first;
      developer.log(
        'AUTO-PRINT (Cafe): Using printer ${printer.name} (${printer.type.name})',
      );
      final buffer = _buildReceiptBuffer(
        orderNumber: orderNumber,
        items: items,
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: total,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        change: change,
      );

      final receiptData = {
        'title': 'ORDER #$orderNumber',
        'content': buffer.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      developer.log('AUTO-PRINT (Cafe): Sending to printer...');
      await printerService.printReceipt(printer, receiptData);
      developer.log('AUTO-PRINT (Cafe): Print successful');
    } catch (e) {
      developer.log('AUTO-PRINT (Cafe) ERROR: $e');
    }
  }

  StringBuffer _buildReceiptBuffer({
    required int orderNumber,
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
  }) {
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
    buffer.writeln('Order #${orderNumber.toString().padLeft(3, '0')}');
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
    return buffer;
  }

  void _showActiveOrders() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int cols = 4;
                    if (constraints.maxWidth < 600) {
                      cols = 1;
                    } else if (constraints.maxWidth < 900) {
                      cols = 2;
                    } else if (constraints.maxWidth < 1200) {
                      cols = 3;
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      itemCount: activeOrders.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemBuilder: (context, index) {
                        final o = activeOrders[index];
                        final total =
                            o.subtotal +
                            (BusinessInfo.instance.isTaxEnabled
                                ? o.subtotal * BusinessInfo.instance.taxRate
                                : 0.0) +
                            (BusinessInfo.instance.isServiceChargeEnabled
                                ? o.subtotal *
                                      BusinessInfo.instance.serviceChargeRate
                                : 0.0);
                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.confirmation_number,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#${o.number}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!o.completed)
                                      Icon(
                                        o.called
                                            ? Icons.campaign
                                            : Icons.hourglass_bottom,
                                        color: o.called
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${o.items.length} item(s)  •  ${BusinessInfo.instance.currencySymbol} ${total.toStringAsFixed(2)}',
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    if (!o.called && !o.completed)
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            setState(() => o.called = true),
                                        icon: const Icon(
                                          Icons.campaign,
                                          size: 18,
                                        ),
                                        label: const Text('Mark Called'),
                                      ),
                                    const SizedBox(width: 8),
                                    if (!o.completed)
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            setState(() => o.completed = true),
                                        icon: const Icon(
                                          Icons.check_circle,
                                          size: 18,
                                        ),
                                        label: const Text('Complete'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = selectedCategory == 'All'
        ? products
        : products.where((p) => p.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Cafe Mode'),
        backgroundColor: const Color(0xFF2563EB),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Active Orders',
            onPressed: _showActiveOrders,
          ),
        ],
      ),
      body: ResponsiveLayout(
        builder: (context, constraints, info) {
          final isNarrow = info.width < 900;

          if (isNarrow) {
            final narrowContent = Column(
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
                // Constrain the cart panel height on narrow screens so internal
                // Expanded/ListView inside it has a bounded height to layout into.
                SizedBox(
                  height: math.min(420.0, math.max(200.0, info.height * 0.35)),
                  child: _buildCartPanel(),
                ),
              ],
            );

            // On narrow screens we compose a Column where the product grid is
            // Expanded and the cart panel is a fixed-height SizedBox. Avoid
            // wrapping the whole layout in a SingleChildScrollView because
            // that creates unbounded height constraints which break inner
            // Expanded/ListView layout. Returning the Column directly keeps
            // children bounded and prevents RenderBox/RenderFlex layout errors.
            return narrowContent;
          }

          // Wide layout: grid + cart sidebar
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
                            return Center(
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
              SizedBox(
                width: info.width < 1100 ? info.width * 0.35 : 380,
                child: _buildCartPanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // When the parent provides a bounded height (e.g. the narrow
        // SizedBox used in the responsive layout), allow the cart panel
        // to scroll if its intrinsic content is taller than the space.
        return ClipRect(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_cart),
                            const SizedBox(width: 12),
                            // Make the title flexible so short/narrow widths don't cause
                            // horizontal overflow when the remaining space is small.
                            const Expanded(
                              child: Text(
                                'Current Order',
                                style: TextStyle(fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            // Show next calling number preview
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'NEXT #$nextOrderNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // The main list area should take remaining space inside
                      // the IntrinsicHeight. Using Flexible here ensures the
                      // list will shrink when available space is small, and
                      // still allow scrolling because the outer SingleChildScrollView
                      // permits the whole panel to scroll when content exceeds
                      // the available height.
                      Flexible(
                        child: cartItems.isEmpty
                            ? Center(
                                child: Text(
                                  'Cart is empty',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: cartItems.length,
                                itemBuilder: (context, index) => CartItemWidget(
                                  item: cartItems[index],
                                  onRemove: () => removeFromCart(index),
                                  onAdd: () =>
                                      addToCart(cartItems[index].product),
                                ),
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text(FormattingService.currency(getSubtotal())),
                              ],
                            ),
                            if (BusinessInfo.instance.isTaxEnabled) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: cartItems.isEmpty
                                        ? null
                                        : _onCheckoutPressed,
                                    child: const Text('Complete Order'),
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
          ),
        );
      },
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
