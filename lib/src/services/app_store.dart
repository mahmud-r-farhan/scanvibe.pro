import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_document.dart';

class AppStore {
  AppStore(this._preferences);

  static const _localeKey = 'scanvibe.locale';
  static const _onboardingKey = 'scanvibe.onboarding_complete';
  static const _documentsKey = 'scanvibe.documents';

  final SharedPreferences _preferences;

  String get localeCode => _preferences.getString(_localeKey) ?? 'en';
  bool get hasCompletedOnboarding =>
      _preferences.getBool(_onboardingKey) ?? false;

  List<ScanDocument> get documents {
    final value = _preferences.getString(_documentsKey);
    if (value == null || value.isEmpty) {
      return [];
    }
    return ScanDocument.decodeList(value);
  }

  Future<void> saveLocale(String languageCode) async {
    await _preferences.setString(_localeKey, languageCode);
  }

  Future<void> saveOnboardingComplete() async {
    await _preferences.setBool(_onboardingKey, true);
  }

  Future<void> saveDocuments(List<ScanDocument> documents) async {
    await _preferences.setString(
      _documentsKey,
      ScanDocument.encodeList(documents),
    );
  }
}
