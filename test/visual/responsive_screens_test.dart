import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:extropos/screens/retail_pos_screen.dart';
import 'package:extropos/screens/cafe_pos_screen.dart';
import 'package:extropos/screens/pos_order_screen_fixed.dart';
import 'package:extropos/screens/table_selection_screen.dart';
import 'package:extropos/models/table_model.dart';

void main() {
  final sizes = [
    const Size(360, 800), // phone portrait
    const Size(812, 375), // phone landscape
    const Size(800, 1280), // tablet
    const Size(1366, 768), // desktop
  ];

  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in sizes) {
    testWidgets('Retail POS at ${size.width}x${size.height} does not overflow', (
      WidgetTester tester,
    ) async {
      // Use the WidgetTester.view APIs (preferred over the deprecated window test helpers)
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(home: RetailPOSScreen()));
      await tester.pumpAndSettle();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Cafe POS at ${size.width}x${size.height} does not overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(home: CafePOSScreen()));
      await tester.pumpAndSettle();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      'Table selection at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MaterialApp(home: TableSelectionScreen()));
        await tester.pumpAndSettle();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      'POS Order screen at ${size.width}x${size.height} does not overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final table = RestaurantTable(id: 't1', name: 'T1', capacity: 4);
        await tester.pumpWidget(
          MaterialApp(home: POSOrderScreen(table: table)),
        );
        await tester.pumpAndSettle();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  }
}
