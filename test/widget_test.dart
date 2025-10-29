// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:extropos/services/config_service.dart';

import 'package:extropos/main.dart';

void main() {
  testWidgets('POS app smoke test', (WidgetTester tester) async {
    // Ensure first-run setup flag is mocked as done so the app boots to home
    SharedPreferences.setMockInitialValues({
      'app_is_setup_done': true,
      // Prevent tutorial overlay from appearing during the smoke test
      'has_seen_tutorial': true,
    });

    // Initialize ConfigService so the app can read the mock pref during startup
    await ConfigService.instance.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExtroPOSApp());
    // Allow any startup timers/animations to settle (tutorial delay, etc.)
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that the mode selection screen is shown
    expect(find.text('ExtroPOS'), findsWidgets);
  });
}
