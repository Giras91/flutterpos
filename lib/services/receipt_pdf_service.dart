import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart' show BuildContext;
import '../models/cart_item.dart';
import '../models/payment_method_model.dart';
import '../models/business_info_model.dart';

class ReceiptPdfService {
  /// Generate a PDF document bytes for the given receipt data.
  static Future<Uint8List> generatePdfBytes({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
    int? orderNumber,
  }) async {
    final pdf = pw.Document();
    final info = BusinessInfo.instance;
    final currency = info.currencySymbol;

    // Optionally include a logo if BusinessInfo provides a path
    pw.Widget? headerLogo;
    try {
      final logoPath = info.logo;
      if (logoPath != null && logoPath.isNotEmpty) {
        final f = File(logoPath);
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          headerLogo = pw.Center(child: pw.Image(pw.MemoryImage(bytes), width: 80, height: 80));
        }
      }
    } catch (_) {
      headerLogo = null;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (headerLogo != null) headerLogo,
              pw.Center(
                child: pw.Column(children: [
                  pw.Text(info.businessName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(info.fullAddress, style: pw.TextStyle(fontSize: 9)),
                  if (info.taxNumber != null && info.taxNumber!.isNotEmpty) pw.Text('Tax No: ${info.taxNumber}', style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 6),
                  pw.Text(orderNumber != null ? 'Order #${orderNumber.toString().padLeft(3, '0')}' : 'Order', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateTime.now().toIso8601String(), style: pw.TextStyle(fontSize: 8)),
                ]),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Column(
                children: items.map((ci) {
                  final mods = ci.modifiers;
                  final hasMods = mods.isNotEmpty;
                  final modsText = hasMods
                      ? mods
                          .map((m) => m.priceAdjustment == 0 ? m.name : '${m.name} (${m.getPriceAdjustmentDisplay()})')
                          .join(', ')
                      : '';
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(child: pw.Text('${ci.product.name} x${ci.quantity}', style: pw.TextStyle(fontSize: 10))),
                          pw.Text('$currency ${ci.totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      if (hasMods) pw.Text(modsText, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 4),
                    ],
                  );
                }).toList(),
              ),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Subtotal'), pw.Text('$currency ${subtotal.toStringAsFixed(2)}')]),
              if (tax > 0) pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Tax'), pw.Text('$currency ${tax.toStringAsFixed(2)}')]),
              if (serviceCharge > 0) pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Service'), pw.Text('$currency ${serviceCharge.toStringAsFixed(2)}')]),
              pw.SizedBox(height: 4),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('$currency ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
              pw.Divider(),
              pw.Text('Payment: ${paymentMethod.name}'),
              pw.Text('Paid: $currency ${amountPaid.toStringAsFixed(2)}'),
              if (change > 0) pw.Text('Change: $currency ${change.toStringAsFixed(2)}'),
              pw.SizedBox(height: 12),
              pw.Center(child: pw.Text('Thank you!', style: pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    return bytes;
  }

  /// Print the receipt using platform print dialog.
  static Future<void> printReceipt({
    required BuildContext context,
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    required double change,
    int? orderNumber,
  }) async {
    final bytes = await generatePdfBytes(
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

    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }
}
