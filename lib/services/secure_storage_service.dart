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

  /// Export the stored encryption key as a base64 string, or null if none.
  Future<String?> exportKey() async {
    final stored = await _secure.read(key: _keyName);
    if (stored == null || stored.isEmpty) return null;
    return stored;
  }

  /// Import a base64-encoded 32-byte key into secure storage.
  /// Throws [FormatException] if the provided key is invalid.
  Future<void> importKey(String base64Key) async {
    try {
      final bytes = base64Decode(base64Key);
      if (bytes.length != 32) {
        throw FormatException('Key must decode to 32 bytes');
      }
      await _secure.write(key: _keyName, value: base64Key);
    } catch (e) {
      // Rewrap common errors as FormatException for callers
      throw FormatException('Invalid base64 key: $e');
    }
  }

  /// Returns whether a key currently exists in secure storage.
  Future<bool> hasKey() async {
    final s = await _secure.read(key: _keyName);
    return s != null && s.isNotEmpty;
  }
}
