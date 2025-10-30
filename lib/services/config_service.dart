import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static final ConfigService instance = ConfigService._init();
  ConfigService._init();

  SharedPreferences? _prefs;

  static const _keyIsSetupDone = 'app_is_setup_done';
  static const _keyStoreName = 'app_store_name';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isInited => _prefs != null;

  bool get isSetupDone => _prefs?.getBool(_keyIsSetupDone) ?? false;

  String get storeName => _prefs?.getString(_keyStoreName) ?? '';

  Future<void> setSetupDone(bool value) async {
    await _prefs?.setBool(_keyIsSetupDone, value);
  }

  Future<void> setStoreName(String name) async {
    await _prefs?.setString(_keyStoreName, name);
  }

  /// Reset setup-related keys (marks app as not setup and clears store name)
  Future<void> resetSetup() async {
    await _prefs?.remove(_keyIsSetupDone);
    await _prefs?.remove(_keyStoreName);
  }
}
