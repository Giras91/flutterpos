import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  // Initialize sqflite FFI for tests (enables openDatabase in test environment)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService import', () {
    setUpAll(() async {
      // Create a temp directory for this test run and override the DB path so
      // each test file uses an isolated DB file.
      final tmp = await Directory.systemTemp.createTemp('extropos_test_');
      final dbFile = p.join(tmp.path, 'extropos.db');
      DatabaseHelper.overrideDatabaseFilePath(dbFile);

      // Reset database to known state
      await DatabaseHelper.instance.resetDatabase();
    });

    test('import items from JSON', () async {
      final json = '''
      [
        {"name": "Test Coffee", "price": 2.5, "category": "Beverages"},
        {"name": "Test Sandwich", "price": 5.0, "category": "Food"}
      ]
      ''';

      final imported = await DatabaseService.instance.importItemsFromJson(json);
      expect(imported, greaterThanOrEqualTo(2));

      final items = await DatabaseService.instance.getItems();
      final foundNames = items.map((i) => i.name).toList();
      expect(foundNames, containsAll(['Test Coffee', 'Test Sandwich']));
    });
  });
}
