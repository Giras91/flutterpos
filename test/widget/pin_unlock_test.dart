import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:typed_data';
import 'dart:io';

import 'package:extropos/main.dart' show ExtroPOSApp;
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/pin_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Encrypted PIN unlock flow', () {
    late Directory tmpDir;
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({
        'app_is_setup_done': true,
        'has_seen_tutorial': true,
      });
      await ConfigService.instance.init();

      // Initialize Hive for tests in a temporary directory (avoid platform plugins)
      tmpDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tmpDir.path);
      // Use a deterministic key for tests (32 bytes)
      final key = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      await PinStore.instance.init(encryptionKey: key, useEncryption: true);
      // write admin PIN that will be used to unlock
      await PinStore.instance.setAdminPin('1234');
    });

    tearDownAll(() async {
      try {
        await PinStore.instance.clear();
        await Hive.close();
        if (await tmpDir.exists()) {
          await tmpDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets('Lock screen accepts encrypted PIN and navigates to POS', (
      tester,
    ) async {
      await tester.pumpWidget(const ExtroPOSApp());
      await tester.pumpAndSettle();

      // Should show lock screen prompt
      expect(find.textContaining('Enter your PIN to unlock'), findsOneWidget);

      // Enter the admin PIN
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      // After unlocking, ModeSelectionScreen shows the 'ExtroPOS' title
      expect(find.text('ExtroPOS'), findsOneWidget);
    });
  });
}
