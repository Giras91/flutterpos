import 'package:flutter/foundation.dart';

/// A small global service to broadcast a reset signal to running screens.
///
/// Screens can listen to `ResetService.instance` (it's a [ChangeNotifier]) and
/// clear local state when `triggerReset()` is called.
class ResetService extends ChangeNotifier {
  ResetService._private();

  static final ResetService instance = ResetService._private();

  int _counter = 0;

  /// Call this to request all listeners to reset their local state.
  void triggerReset() {
    _counter++;
    notifyListeners();
  }

  /// Current counter value; useful for debugging.
  int get counter => _counter;
}
