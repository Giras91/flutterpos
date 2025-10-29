// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/payment_method_model.dart';
import '../models/business_info_model.dart';
import '../services/receipt_pdf_service.dart';
import '../services/imin_printer_service.dart';
import 'dart:io' show Platform, File;
import 'package:file_selector/file_selector.dart';
import 'package:imin_printer/enums.dart' as imin;

class ReceiptPreviewScreen extends StatelessWidget {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double total;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double change;
  final int? orderNumber;

  const ReceiptPreviewScreen({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    final info = BusinessInfo.instance;
    final currency = info.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              // Prefer native direct printing on Android when IMIN printer is available
              if (Platform.isAndroid) {
                try {
                  final iminService = IminPrinterService();
                  await iminService.initialize();

                  if (await iminService.isIminPrinterAvailable()) {
                    final info = BusinessInfo.instance;
                    debugPrint(
                      'ReceiptPreview: Printing with settings - headerCentered: ${info.receiptHeaderCentered}, headerBold: ${info.receiptHeaderBold}, fontSize: ${info.receiptHeaderFontSize}',
                    );

                    // Print header - using business info settings
                    await iminService.printTextWithFormat(
                      info.businessName,
                      alignment: info.receiptHeaderCentered
                          ? imin.IminPrintAlign.center
                          : imin.IminPrintAlign.left,
                      style: info.receiptHeaderBold
                          ? imin.IminFontStyle.bold
                          : imin.IminFontStyle.normal,
                      size: info.receiptHeaderFontSize,
                    );

                    // Print address - centered, normal style
                    await iminService.printTextWithFormat(
                      BusinessInfo.instance.fullAddress,
                      alignment: imin.IminPrintAlign.center,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );

                    // Print tax number if available
                    if (BusinessInfo.instance.taxNumber != null &&
                        BusinessInfo.instance.taxNumber!.isNotEmpty) {
                      await iminService.printTextWithFormat(
                        'Tax No: ${BusinessInfo.instance.taxNumber}',
                        alignment: imin.IminPrintAlign.center,
                        style: imin.IminFontStyle.normal,
                        size: 1,
                      );
                    }

                    // Print order number - centered and bold
                    final orderText = orderNumber != null
                        ? 'Order #${orderNumber.toString().padLeft(3, '0')}'
                        : 'Order';
                    await iminService.printTextWithFormat(
                      orderText,
                      alignment: imin.IminPrintAlign.center,
                      style: imin.IminFontStyle.bold,
                      size: 1,
                    );

                    // Print date/time - centered, normal
                    await iminService.printTextWithFormat(
                      DateTime.now().toString().substring(0, 19),
                      alignment: imin.IminPrintAlign.center,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );

                    // Print separator line - left aligned
                    await iminService.printTextWithFormat(
                      '-------------------------------',
                      alignment: imin.IminPrintAlign.left,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );

                    // Print items - left aligned
                    for (final ci in items) {
                      await iminService.printTextWithFormat(
                        '${ci.product.name} x${ci.quantity}  ${BusinessInfo.instance.currencySymbol}${ci.totalPrice.toStringAsFixed(2)}',
                        alignment: imin.IminPrintAlign.left,
                        style: imin.IminFontStyle.normal,
                        size: 1,
                      );
                      if (ci.modifiers.isNotEmpty) {
                        await iminService.printTextWithFormat(
                          '  ${ci.modifiers.map((m) => m.name).join(', ')}',
                          alignment: imin.IminPrintAlign.left,
                          style: imin.IminFontStyle.normal,
                          size: 1,
                        );
                      }
                    }

                    // Print separator line
                    await iminService.printTextWithFormat(
                      '-------------------------------',
                      alignment: imin.IminPrintAlign.left,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );

                    // Print totals - left aligned
                    await iminService.printTextWithFormat(
                      'Subtotal: ${BusinessInfo.instance.currencySymbol}${subtotal.toStringAsFixed(2)}',
                      alignment: imin.IminPrintAlign.left,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );
                    if (tax > 0) {
                      await iminService.printTextWithFormat(
                        'Tax: ${BusinessInfo.instance.currencySymbol}${tax.toStringAsFixed(2)}',
                        alignment: imin.IminPrintAlign.left,
                        style: imin.IminFontStyle.normal,
                        size: 1,
                      );
                    }
                    if (serviceCharge > 0) {
                      await iminService.printTextWithFormat(
                        'Service: ${BusinessInfo.instance.currencySymbol}${serviceCharge.toStringAsFixed(2)}',
                        alignment: imin.IminPrintAlign.left,
                        style: imin.IminFontStyle.normal,
                        size: 1,
                      );
                    }
                    // Total - bold
                    await iminService.printTextWithFormat(
                      'Total: ${BusinessInfo.instance.currencySymbol}${total.toStringAsFixed(2)}',
                      alignment: imin.IminPrintAlign.left,
                      style: imin.IminFontStyle.bold,
                      size: 1,
                    );

                    // Payment info - normal style
                    await iminService.printTextWithFormat(
                      'Payment: ${paymentMethod.name}',
                      alignment: imin.IminPrintAlign.left,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );
                    await iminService.printTextWithFormat(
                      'Paid: ${BusinessInfo.instance.currencySymbol}${amountPaid.toStringAsFixed(2)}',
                      alignment: imin.IminPrintAlign.left,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );
                    if (change > 0) {
                      await iminService.printTextWithFormat(
                        'Change: ${BusinessInfo.instance.currencySymbol}${change.toStringAsFixed(2)}',
                        alignment: imin.IminPrintAlign.left,
                        style: imin.IminFontStyle.normal,
                        size: 1,
                      );
                    }

                    // Thank you message - centered
                    await iminService.printTextWithFormat(
                      '',
                      alignment: imin.IminPrintAlign.center,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );
                    await iminService.printTextWithFormat(
                      'Thank you!',
                      alignment: imin.IminPrintAlign.center,
                      style: imin.IminFontStyle.normal,
                      size: 1,
                    );

                    // Cut paper
                    await iminService.cutPaper();

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Printed to thermal printer'),
                      ),
                    );
                    return;
                  }
                } catch (e) {
                  // fall through to PDF fallback
                }
              }

              // Fallback to PDF print dialog (cross-platform)
              ReceiptPdfService.printReceipt(
                context: context,
                items: items,
                subtotal: subtotal,
                tax: tax,
                serviceCharge: serviceCharge,
                total: total,
                paymentMethod: paymentMethod,
                amountPaid: amountPaid,
                change: change,
                orderNumber: orderNumber,
              );
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Print', style: TextStyle(color: Colors.white)),
          ),
          // Export PDF action
          IconButton(
            tooltip: 'Export PDF',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final suggestedName =
                    'receipt_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';
                final location = await getSaveLocation(
                  suggestedName: suggestedName,
                  acceptedTypeGroups: [
                    const XTypeGroup(label: 'PDF', extensions: ['pdf']),
                  ],
                );
                if (location == null) return; // cancelled

                // Generate PDF bytes after UI dialogs so we don't use BuildContext across async gaps
                final bytes = await ReceiptPdfService.generatePdfBytes(
                  items: items,
                  subtotal: subtotal,
                  tax: tax,
                  serviceCharge: serviceCharge,
                  total: total,
                  paymentMethod: paymentMethod,
                  amountPaid: amountPaid,
                  change: change,
                  orderNumber: orderNumber,
                );

                final file = File(location.path);
                await file.writeAsBytes(bytes);

                messenger.showSnackBar(
                  SnackBar(content: Text('Saved PDF to ${location.path}')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Export PDF failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            info.businessName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            info.fullAddress,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (info.taxNumber != null &&
                              info.taxNumber!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Tax No: ${info.taxNumber}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            orderNumber != null
                                ? 'Order #${orderNumber.toString().padLeft(3, '0')}'
                                : 'Order',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _formatDateTime(DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),

                    // Items
                    ...items.map((ci) {
                      final mods = ci.modifiers;
                      final hasMods = mods.isNotEmpty;
                      final modsText = hasMods
                          ? mods
                                .map(
                                  (m) => m.priceAdjustment == 0
                                      ? m.name
                                      : '${m.name} (${m.getPriceAdjustmentDisplay()})',
                                )
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
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'x${ci.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasMods) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      modsText,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
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
                                  '$currency ${ci.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '@ $currency ${ci.finalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const Divider(height: 24),

                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('$currency ${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (tax > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tax (${info.taxRatePercentage})'),
                          Text('$currency ${tax.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    if (serviceCharge > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Service Charge (${info.serviceChargeRatePercentage})',
                          ),
                          Text('$currency ${serviceCharge.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$currency ${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Payment info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Method'),
                        Text(paymentMethod.name),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid'),
                        Text('$currency ${amountPaid.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (change > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Change'),
                          Text('$currency ${change.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Thank you!',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
