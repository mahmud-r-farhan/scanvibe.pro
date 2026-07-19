import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  const SettingsState({
    this.locale = const Locale('en'),
    this.isDarkMode = false,
    this.hasCompletedOnboarding = false,
    this.ocrLanguage = 'latin',
    this.defaultScanMode = 'document',
    this.defaultFilter = 'auto_enhance',
    this.autoCapture = true,
    this.autoProcessOcr = true,
    this.imageQuality = 0.92,
    this.maxImageWidth = 2200,
  });

  final Locale locale;
  final bool isDarkMode;
  final bool hasCompletedOnboarding;
  final String ocrLanguage;
  final String defaultScanMode;
  final String defaultFilter;
  final bool autoCapture;
  final bool autoProcessOcr;
  final double imageQuality;
  final int maxImageWidth;

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsState copyWith({
    Locale? locale,
    bool? isDarkMode,
    bool? hasCompletedOnboarding,
    String? ocrLanguage,
    String? defaultScanMode,
    String? defaultFilter,
    bool? autoCapture,
    bool? autoProcessOcr,
    double? imageQuality,
    int? maxImageWidth,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
      defaultScanMode: defaultScanMode ?? this.defaultScanMode,
      defaultFilter: defaultFilter ?? this.defaultFilter,
      autoCapture: autoCapture ?? this.autoCapture,
      autoProcessOcr: autoProcessOcr ?? this.autoProcessOcr,
      imageQuality: imageQuality ?? this.imageQuality,
      maxImageWidth: maxImageWidth ?? this.maxImageWidth,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _prefix = 'scanvibe.';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString('${_prefix}locale') ?? 'en';
    final isDarkMode = prefs.getBool('${_prefix}dark_mode') ?? false;
    final hasOnboarding = prefs.getBool('${_prefix}onboarding_complete') ?? false;
    final ocrLang = prefs.getString('${_prefix}ocr_language') ?? 'latin';
    final scanMode = prefs.getString('${_prefix}scan_mode') ?? 'document';
    final filter = prefs.getString('${_prefix}filter') ?? 'auto_enhance';
    final autoCapture = prefs.getBool('${_prefix}auto_capture') ?? true;
    final autoOcr = prefs.getBool('${_prefix}auto_process_ocr') ?? true;

    state = SettingsState(
      locale: Locale(localeCode),
      isDarkMode: isDarkMode,
      hasCompletedOnboarding: hasOnboarding,
      ocrLanguage: ocrLang,
      defaultScanMode: scanMode,
      defaultFilter: filter,
      autoCapture: autoCapture,
      autoProcessOcr: autoOcr,
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}locale', locale.languageCode);
  }

  Future<void> toggleDarkMode() async {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}dark_mode', state.isDarkMode);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasCompletedOnboarding: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}onboarding_complete', true);
  }

  Future<void> setOcrLanguage(String language) async {
    state = state.copyWith(ocrLanguage: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}ocr_language', language);
  }

  Future<void> setDefaultScanMode(String mode) async {
    state = state.copyWith(defaultScanMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}scan_mode', mode);
  }

  Future<void> setDefaultFilter(String filter) async {
    state = state.copyWith(defaultFilter: filter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}filter', filter);
  }

  Future<void> setAutoCapture(bool value) async {
    state = state.copyWith(autoCapture: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}auto_capture', value);
  }

  Future<void> setAutoProcessOcr(bool value) async {
    state = state.copyWith(autoProcessOcr: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}auto_process_ocr', value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
