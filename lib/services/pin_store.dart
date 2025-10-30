// Uint8List is available via foundation import below; no direct typed_data import needed.
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';

/// PinStore provides encrypted storage for user PINs. Keys are namespaced by
/// user id (key: 'pin_user_{userId}').

class PinStore {
  static final PinStore instance = PinStore._();
  PinStore._();

  static const _boxName = 'pin_box';
  static const _adminPinKey = 'admin_pin';

  Box<dynamic>? _box;

  /// Initialize the PinStore.
  ///
  /// If [encryptionKey] is provided it will be used for the Hive AES cipher.
  /// If [useEncryption] is false the box will be opened without encryption
  /// (useful for tests where secure storage isn't available).
  Future<void> init({
    Uint8List? encryptionKey,
    bool useEncryption = true,
  }) async {
    // Ensure Hive is initialized by caller (main or tests)
    if (useEncryption) {
      final key =
          encryptionKey ??
          await SecureStorageService.instance.getEncryptionKey();
      await Hive.openBox(_boxName, encryptionCipher: HiveAesCipher(key));
    } else {
      await Hive.openBox(_boxName);
    }
    _box = Hive.box(_boxName);
    // Intentionally avoid noisy debug output here in normal runs.
  }

  String _userPinKey(String userId) => 'pin_user_$userId';

  Future<void> setPinForUser(String userId, String pin) async {
    await _box?.put(_userPinKey(userId), pin);
    if (kDebugMode) {
      // Debug: do not print the PIN value. Print only existence and length.
      print('PinStore: setPinForUser userId=$userId pinLength=${pin.length}');
    }
  }

  String? getPinForUser(String userId) {
    final v = _box?.get(_userPinKey(userId));
    if (v == null) return null;
    return v.toString();
  }

  /// Returns the first userId that matches the provided pin, or null.
  String? getUserIdForPin(String pin) {
    if (_box == null) return null;
    for (final key in _box!.keys) {
      if (key is String && key.startsWith('pin_user_')) {
        final v = _box!.get(key);
        if (v != null && v.toString() == pin) {
          final userId = key.replaceFirst('pin_user_', '');
          if (kDebugMode) {
            print(
              'PinStore: getUserIdForPin match userId=$userId pinLength=${pin.length}',
            );
          }
          return userId;
        }
      }
    }
    return null;
  }

  /// Migrate plaintext PINs from the existing 'users' table into the
  /// encrypted Hive box, then clear the plaintext PINs in the database.
  Future<void> migrateFromDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('users');
      for (final row in maps) {
        final id = row['id'].toString();
        final pin = (row['pin'] as String?) ?? '';
        if (pin.isNotEmpty) {
          await setPinForUser(id, pin);
          // Clear PIN in DB (overwrite with empty string)
          await db.update(
            'users',
            {'pin': ''},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
      // migration count intentionally not logged to reduce noise
    } catch (e) {
      // Non-fatal: log in debug
      if (kDebugMode) {
        print('PinStore.migrateFromDatabase failed: $e');
      }
    }
  }

  Future<void> setAdminPin(String pin) async {
    await _box?.put(_adminPinKey, pin);
    if (kDebugMode) {
      print('PinStore: setAdminPin saved pinLength=${pin.length}');
    }
  }

  String? getAdminPin() {
    final v = _box?.get(_adminPinKey);
    if (v == null) return null;
    if (kDebugMode) {
      print('PinStore: getAdminPin returning pinLength=${v.toString().length}');
    }
    return v.toString();
  }

  Future<void> clear() async {
    await _box?.delete(_adminPinKey);
  }
}
