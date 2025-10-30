import 'package:shared_preferences/shared_preferences.dart';

class LicenseService {
  static final LicenseService instance = LicenseService._internal();
  LicenseService._internal();

  static const _keyInstallDate = 'installDate';
  static const _keyActivated = 'isActivated';
  static const _keyLicenseKey = 'licenseKey';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isInited => _prefs != null;

  /// Ensure installDate exists (set on first-run)
  Future<void> initializeIfNeeded() async {
    if (_prefs == null) await init();
    if (!_prefs!.containsKey(_keyInstallDate)) {
      await _prefs!.setString(
        _keyInstallDate,
        DateTime.now().toIso8601String(),
      );
      await _prefs!.setBool(_keyActivated, false);
    }
  }

  bool get isActivated => _prefs?.getBool(_keyActivated) ?? false;

  String get licenseKey => _prefs?.getString(_keyLicenseKey) ?? '';

  DateTime? get installDate {
    final v = _prefs?.getString(_keyInstallDate);
    if (v == null) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  int get daysUsed {
    final d = installDate;
    if (d == null) return 0;
    return DateTime.now().difference(d).inDays;
  }

  int get daysLeft => 30 - daysUsed;

  bool get isExpired => !isActivated && daysLeft <= 0;

  /// Simple offline activation: accept a known key and mark activated.
  Future<void> activate(String key) async {
    if (_prefs == null) await init();
    // Offline validation: sample valid key
    const validKey = 'EXTRO-2025-LICENSE';
    if (key.trim() == validKey) {
      await _prefs!.setBool(_keyActivated, true);
      await _prefs!.setString(_keyLicenseKey, key.trim());
    } else {
      throw Exception('Invalid license key');
    }
  }

  Future<void> clearActivation() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_keyActivated);
    await _prefs!.remove(_keyLicenseKey);
    await _prefs!.remove(_keyInstallDate);
  }
}
