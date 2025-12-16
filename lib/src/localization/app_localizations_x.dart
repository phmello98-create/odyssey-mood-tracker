import 'package:odyssey/src/localization/app_localizations.dart';

/// Extension para adicionar helpers ao AppLocalizations
extension AppLocalizationsX on AppLocalizations {
  /// Retorna true se o idioma atual é inglês
  bool get isEnglish => localeName == 'en';

  /// Retorna true se o idioma atual é português
  bool get isPortuguese => localeName == 'pt';
}
