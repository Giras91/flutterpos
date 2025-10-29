import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../models/business_info_model.dart';
import '../models/cart_item.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<PaymentMethod> availablePaymentMethods;
  final List<CartItem>? cartItems; // Optional: show order summary

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.availablePaymentMethods,
    this.cartItems,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selectedPaymentMethod;
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Set default payment method if available
    final defaultMethod = widget.availablePaymentMethods
        .where((method) => method.isDefault && method.status == PaymentMethodStatus.active)
        .firstOrNull;
    if (defaultMethod != null) {
      _selectedPaymentMethod = defaultMethod;
    } else if (widget.availablePaymentMethods.isNotEmpty) {
      // Select first active method if no default
      _selectedPaymentMethod = widget.availablePaymentMethods
          .firstWhere((method) => method.status == PaymentMethodStatus.active);
    }

    // Pre-fill amount with total
    _amountController.text = widget.totalAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _enteredAmount => double.tryParse(_amountController.text) ?? 0.0;
  double get _change => _enteredAmount - widget.totalAmount;

  bool get _isValidPayment => _enteredAmount >= widget.totalAmount && _selectedPaymentMethod != null;

  void _processPayment() async {
    if (!_isValidPayment) return;

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isProcessing = false);

      // Return payment result
      Navigator.pop(context, {
        'success': true,
        'paymentMethod': _selectedPaymentMethod,
        'amountPaid': _enteredAmount,
        'change': _change,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = BusinessInfo.instance.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((widget.cartItems?.isNotEmpty ?? false)) ...[
              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...widget.cartItems!.map((ci) {
                        final unit = ci.finalPrice; // includes modifiers
                        final lineTotal = ci.totalPrice;
                        final mods = ci.modifiers;
                        final hasMods = mods.isNotEmpty;
                        final modsText = hasMods
                            ? mods
                                .map((m) => m.priceAdjustment == 0
                                    ? m.name
                                    : '${m.name} (${m.getPriceAdjustmentDisplay()})')
                                .join(', ')
                            : '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            ci.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('x${ci.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                    if (hasMods) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        modsText,
                                        style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$currencySymbol ${lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '@ $currencySymbol ${unit.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            if ((widget.cartItems?.isNotEmpty ?? false)) ...[
              const Text(
                'Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final items = widget.cartItems!;
                final subtotal = items.fold<double>(0.0, (sum, ci) => sum + ci.totalPrice);
                final info = BusinessInfo.instance;
                final tax = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
                final service = info.isServiceChargeEnabled ? subtotal * info.serviceChargeRate : 0.0;
                final total = subtotal + tax + service;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text('$currencySymbol ${subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (info.isTaxEnabled) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tax (${info.taxRatePercentage})'),
                              Text('$currencySymbol ${tax.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (info.isServiceChargeEnabled) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Service Charge (${info.serviceChargeRatePercentage})'),
                              Text('$currencySymbol ${service.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('$currencySymbol ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
            ],
            // Amount Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Amount Due',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currencySymbol ${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method Selection
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            if (widget.availablePaymentMethods.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No active payment methods available. Please add payment methods in settings.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              RadioGroup<PaymentMethod>(
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value);
                },
                child: Column(
                  children: widget.availablePaymentMethods
                      .where((method) => method.status == PaymentMethodStatus.active)
                      .map((method) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: RadioListTile<PaymentMethod>(
                              title: Row(
                                children: [
                                  Text(method.name),
                                  if (method.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2563EB),
                                      ),
                                      child: const Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              value: method,
                            ),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Payment Amount Input
            const Text(
              'Payment Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount Received',
                prefixText: currencySymbol,
                border: const OutlineInputBorder(),
                helperText: 'Enter the amount received from customer',
              ),
              onChanged: (value) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Change Display
            if (_enteredAmount > widget.totalAmount)
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$currencySymbol ${_change.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing || !_isValidPayment
                        ? null
                        : _processPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Process Payment',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),

            if (!_isValidPayment && !_isProcessing) ...[
              const SizedBox(height: 16),
              Text(
                _selectedPaymentMethod == null
                    ? 'Please select a payment method'
                    : 'Payment amount must be at least the total amount',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}