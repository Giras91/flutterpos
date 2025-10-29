import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:extropos/main.dart' show ExtroPOSApp;
import 'package:extropos/services/config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Setup routing', () {
    testWidgets('shows SetupScreen when first-run (isSetupDone = false)', (
      tester,
    ) async {
      // Start with pref saying setup not done
      SharedPreferences.setMockInitialValues({
        'app_is_setup_done': false,
        // Prevent tutorial timer in ModeSelectionScreen during tests
        'has_seen_tutorial': true,
      });

      await ConfigService.instance.init();

      await tester.pumpWidget(const ExtroPOSApp());
      await tester.pumpAndSettle();

      // AppBar title in SetupScreen
      expect(find.text('Welcome — Setup'), findsOneWidget);
      // Also check for the prominent setup headline
      expect(find.textContaining("Let's get your store ready"), findsOneWidget);
    });

    testWidgets('shows home when setup already done (isSetupDone = true)', (
      tester,
    ) async {
      // Mark setup as completed in prefs
      SharedPreferences.setMockInitialValues({
        'app_is_setup_done': true,
        // Prevent tutorial timer in ModeSelectionScreen during tests
        'has_seen_tutorial': true,
      });

      await ConfigService.instance.init();

      await tester.pumpWidget(const ExtroPOSApp());
      await tester.pumpAndSettle();

      // ModeSelectionScreen contains the large 'ExtroPOS' title
      expect(find.text('ExtroPOS'), findsOneWidget);
      expect(find.text('Select Business Mode'), findsOneWidget);
    });
  });
}
