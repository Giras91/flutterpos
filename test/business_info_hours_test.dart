import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// no foundation import needed

import 'package:extropos/models/business_info_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BusinessHours persist & load from SharedPreferences', () async {
    // Create a custom BusinessHours instance
    final customHours = BusinessHours(
      monday: TimeRange(isOpen: false, openTime: '00:00', closeTime: '00:00'),
      tuesday: TimeRange(isOpen: true, openTime: '08:00', closeTime: '20:00'),
      wednesday: TimeRange(isOpen: true, openTime: '08:00', closeTime: '20:00'),
      thursday: TimeRange(isOpen: true, openTime: '08:00', closeTime: '20:00'),
      friday: TimeRange(isOpen: true, openTime: '09:00', closeTime: '22:00'),
      saturday: TimeRange(isOpen: true, openTime: '10:00', closeTime: '23:00'),
      sunday: TimeRange(isOpen: false, openTime: '00:00', closeTime: '00:00'),
    );

    // Prepare mock SharedPreferences with business_hours JSON
    final initialValues = <String, Object>{
      'business_hours': jsonEncode(customHours.toJson()),
    };
    SharedPreferences.setMockInitialValues(initialValues);

    // Initialize BusinessInfo which should load from prefs
    await BusinessInfo.initialize();

    // Validate loaded hours match what we saved
    final loaded = BusinessInfo.instance.businessHours;

    expect(loaded.monday.isOpen, equals(customHours.monday.isOpen));
    expect(loaded.tuesday.openTime, equals(customHours.tuesday.openTime));
    expect(loaded.friday.closeTime, equals(customHours.friday.closeTime));
    expect(loaded.sunday.isOpen, equals(customHours.sunday.isOpen));
  });
}
