import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._init();
  AppSettings._init();

  SharedPreferences? _prefs;
  bool _isTrainingMode = false;
  bool _hasSeenTutorial = false;
  bool _requireDbProducts = false;

  bool get isTrainingMode => _isTrainingMode;
  bool get hasSeenTutorial => _hasSeenTutorial;
  bool get requireDbProducts => _requireDbProducts;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isTrainingMode = _prefs?.getBool('training_mode') ?? false;
    _hasSeenTutorial = _prefs?.getBool('has_seen_tutorial') ?? false;
    _requireDbProducts = _prefs?.getBool('require_db_products') ?? false;
    notifyListeners();
  }

  Future<void> setTrainingMode(bool value) async {
    _isTrainingMode = value;
    await _prefs?.setBool('training_mode', value);
    notifyListeners();
  }

  Future<void> markTutorialAsSeen() async {
    _hasSeenTutorial = true;
    await _prefs?.setBool('has_seen_tutorial', true);
    notifyListeners();
  }

  Future<void> resetTutorial() async {
    _hasSeenTutorial = false;
    await _prefs?.setBool('has_seen_tutorial', false);
    notifyListeners();
  }

  Future<void> setRequireDbProducts(bool value) async {
    _requireDbProducts = value;
    await _prefs?.setBool('require_db_products', value);
    notifyListeners();
  }
}
