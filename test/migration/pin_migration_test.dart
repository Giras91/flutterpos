import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hive/hive.dart';

import 'package:extropos/services/pin_store.dart';
import 'package:extropos/services/database_helper.dart';

void main() {
  group('Database pin -> PinStore migration', () {
    late Directory tmp;
    late String dbPath;
    late String hivePath;

    setUpAll(() async {
      // Prepare temp dirs
      tmp = Directory.systemTemp.createTempSync('flutterpos_migrate_');
      dbPath = p.join(tmp.path, 'extropos_migrate.db');
      hivePath = p.join(tmp.path, 'hive');
      Directory(hivePath).createSync(recursive: true);

      // Initialize ffi sqlite for tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // Create an old-version DB (version 4) with the legacy users table
      final db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT,
              pin TEXT NOT NULL,
              role TEXT NOT NULL,
              is_active INTEGER DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
            final now = DateTime.now().toIso8601String();
            await db.insert('users', {
              'id': 'u1',
              'name': 'MigratedUser',
              'email': 'migrated@example.com',
              'pin': '4321',
              'role': 'staff',
              'is_active': 1,
              'created_at': now,
              'updated_at': now,
            });
          },
        ),
      );
      await db.close();

      // Initialize Hive / PinStore before DatabaseHelper opens DB (migration relies on PinStore)
      Hive.init(hivePath);
      await PinStore.instance.init(useEncryption: false);

      // Point DatabaseHelper to our test DB file
      DatabaseHelper.overrideDatabaseFilePath(dbPath);
    });

    tearDownAll(() async {
      try {
        await DatabaseHelper.instance.close();
      } catch (_) {}
      try {
        await Hive.close();
      } catch (_) {}
      if (await tmp.exists()) {
        await tmp.delete(recursive: true);
      }
    });

    test('migrates plaintext pin into PinStore and removes column', () async {
      // Opening DatabaseHelper.instance.database should trigger onUpgrade -> v5
      final db = await DatabaseHelper.instance.database;

      // Verify the pin was copied into PinStore
      final pin = PinStore.instance.getPinForUser('u1');
      expect(pin, '4321');

      // Verify the users table no longer contains a `pin` column
      final pragma = await db.rawQuery("PRAGMA table_info('users')");
      final names = pragma.map((r) => r['name'].toString()).toList();
      expect(names.contains('pin'), isFalse);
    });
  });
}
