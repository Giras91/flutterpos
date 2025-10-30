import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages a secure encryption key stored in platform secure storage.
class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._();
  SecureStorageService._();

  static const _keyName = 'hive_encryption_key_v1';
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<void> init() async {
    // No-op for now; FlutterSecureStorage is ready to use
  }

  /// Returns a 32-byte key for Hive AES encryption. Generates and stores one
  /// if none exists.
  Future<Uint8List> getEncryptionKey() async {
    final stored = await _secure.read(key: _keyName);
    if (stored != null && stored.isNotEmpty) {
      try {
        final bytes = base64Decode(stored);
        if (bytes.length == 32) return Uint8List.fromList(bytes);
      } catch (_) {
        // fallthrough to generate new
      }
    }
    // Generate a cryptographically secure 32-byte key
    final rnd = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => rnd.nextInt(256)),
    );
    final b64 = base64Encode(key);
    await _secure.write(key: _keyName, value: b64);
    return key;
  }

  Future<void> clearKey() async {
    await _secure.delete(key: _keyName);
  }
}
