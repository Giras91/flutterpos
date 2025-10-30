import 'package:flutter/material.dart';

/// Small helper service to centralize technician override logic.
class TechnicianService {
  static const technicianPin = '888888';

  /// If the provided pin is the technician override pin, navigate to
  /// the maintenance screen and return true. Otherwise return false.
  static Future<bool> handlePinIfTechnician(
    BuildContext context,
    String pin,
  ) async {
    if (pin.trim() == technicianPin) {
      // Replace current stack with maintenance screen
      Navigator.pushReplacementNamed(context, '/maintenance');
      return true;
    }
    return false;
  }
}
