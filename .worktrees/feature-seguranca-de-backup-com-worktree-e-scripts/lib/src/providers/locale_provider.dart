import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State for locale management
class LocaleState {
  final Locale? selectedLocale;
  final bool followSystem;

  const LocaleState({
    this.selectedLocale,
    this.followSystem = true,
  });

  /// Get the effective locale to use
  Locale get currentLocale {
    if (followSystem || selectedLocale == null) {
      // Get system locale
      final systemLocale = PlatformDispatcher.instance.locale;
      // Check if system locale is supported
      if (systemLocale.languageCode == 'pt') {
        return const Locale('pt', 'BR');
      } else {
        return const Locale('en', 'US');
      }
    }
    return selectedLocale!;
  }

  LocaleState copyWith({
    Locale? selectedLocale,
    bool? followSystem,
  }) {
    return LocaleState(
      selectedLocale: selectedLocale ?? this.selectedLocale,
      followSystem: followSystem ?? this.followSystem,
    );
  }
}

/// Provider for managing app locale/language
class LocaleNotifier extends StateNotifier<LocaleState> {
  static const String _localeKey = 'app_locale';
  static const String _followSystemKey = 'app_follow_system_locale';
  
  LocaleNotifier() : super(const LocaleState()) {
    _loadSettings();
  }

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
  ];

  /// Load saved locale from preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final followSystem = prefs.getBool(_followSystemKey) ?? true;
    final localeCode = prefs.getString(_localeKey);
    
    Locale? savedLocale;
    if (localeCode != null) {
      final parts = localeCode.split('_');
      if (parts.length == 2) {
        savedLocale = Locale(parts[0], parts[1]);
      } else {
        savedLocale = Locale(parts[0]);
      }
    }
    
    state = LocaleState(
      selectedLocale: savedLocale,
      followSystem: followSystem,
    );
  }

  /// Set whether to follow system language
  Future<void> setFollowSystem(bool follow) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_followSystemKey, follow);
    state = state.copyWith(followSystem: follow);
  }

  /// Set the app locale (also disables followSystem)
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = locale.countryCode != null 
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await prefs.setString(_localeKey, localeCode);
    await prefs.setBool(_followSystemKey, false);
    
    state = LocaleState(
      selectedLocale: locale,
      followSystem: false,
    );
  }

  /// Toggle between PT and EN (and disable followSystem)
  Future<void> toggleLocale() async {
    final current = state.currentLocale;
    if (current.languageCode == 'pt') {
      await setLocale(const Locale('en', 'US'));
    } else {
      await setLocale(const Locale('pt', 'BR'));
    }
  }

  /// Check if following system locale
  bool get followSystem => state.followSystem;

  /// Check if current locale is Portuguese
  bool get isPortuguese => state.currentLocale.languageCode == 'pt';

  /// Check if current locale is English
  bool get isEnglish => state.currentLocale.languageCode == 'en';

  /// Get the current effective locale
  Locale get currentLocale => state.currentLocale;

  /// Get locale display name
  String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'pt':
        return 'Português (Brasil)';
      case 'en':
        return 'English (US)';
      default:
        return locale.languageCode;
    }
  }
}

/// Provider for app locale state
final localeStateProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier();
});

/// Convenience provider for just the current locale
final localeProvider = Provider<Locale>((ref) {
  return ref.watch(localeStateProvider).currentLocale;
});
