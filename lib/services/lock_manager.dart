import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'database_service.dart';
import 'pin_store.dart';

/// Simple singleton lock manager. Use [attemptUnlock] to verify a PIN and
/// set the currently authenticated user. Not a full auth system — lightweight
/// for offline PIN-based unlocking.
class LockManager extends ChangeNotifier {
  static final LockManager instance = LockManager._internal();
  LockManager._internal();

  User? _currentUser;
  bool _locked = true;

  User? get currentUser => _currentUser;
  bool get isLocked => _locked;

  /// Attempt to unlock using a plain PIN. Returns true when unlocked.
  /// Caller is responsible for UI navigation. This method also updates
  /// the user's lastLoginAt timestamp in the DB on success.
  Future<bool> attemptUnlock(String pin) async {
    final candidate = pin.trim();

    // First check encrypted PinStore admin PIN
    try {
      final adminPin = PinStore.instance.getAdminPin();
      if (adminPin != null && adminPin == candidate) {
        // Admin PIN matched. Prefer to resolve an admin user from DB, but if
        // the database isn't available (tests or first-run), create a
        // lightweight in-memory admin user so unlocking still works.
        try {
          final users = await UserService.instance.getAllUsers();
          User? admin;
          try {
            admin = users.firstWhere((u) => u.role == UserRole.admin);
          } catch (_) {
            admin = users.isNotEmpty ? users.first : null;
          }
          if (admin != null) {
            _currentUser = admin.copyWith(lastLoginAt: DateTime.now());
          } else {
            // Fallback in-memory admin user
            _currentUser = User(
              id: 'admin-local',
              username: 'admin',
              fullName: 'Administrator',
              email: '',
              role: UserRole.admin,
              pin: candidate,
            ).copyWith(lastLoginAt: DateTime.now());
          }
        } catch (_) {
          // If DB calls throw (sqflite not initialized in widget tests),
          // create a light in-memory admin user so tests and first-run flows
          // can still unlock using the encrypted admin PIN.
          _currentUser = User(
            id: 'admin-local',
            username: 'admin',
            fullName: 'Administrator',
            email: '',
            role: UserRole.admin,
            pin: candidate,
          ).copyWith(lastLoginAt: DateTime.now());
        }
      } else {
        final user = await UserService.instance.findByPin(candidate);
        if (user == null) return false;
        _currentUser = user.copyWith(lastLoginAt: DateTime.now());
      }
    } catch (e) {
      // Fallback to DB-only check
      final user = await UserService.instance.findByPin(candidate);
      if (user == null) return false;
      _currentUser = user.copyWith(lastLoginAt: DateTime.now());
    }
    // persist lastLoginAt update
    try {
      await DatabaseService.instance.updateUser(_currentUser!);
    } catch (_) {
      // non-fatal
    }

    _locked = false;
    notifyListeners();
    return true;
  }

  /// Lock the app again and clear in-memory current user
  void lock() {
    _currentUser = null;
    _locked = true;
    notifyListeners();
  }
}
