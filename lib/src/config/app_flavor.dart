import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum que define os ambientes disponíveis do app
enum AppFlavor {
  /// Ambiente de desenvolvimento - com ferramentas de debug, seed data, etc.
  dev,

  /// Ambiente de produção - limpo para usuários finais
  prod,
}

/// Extensão para facilitar verificações
extension AppFlavorExtension on AppFlavor {
  /// Retorna true se for ambiente de desenvolvimento
  bool get isDev => this == AppFlavor.dev;

  /// Retorna true se for ambiente de produção
  bool get isProd => this == AppFlavor.prod;

  /// Nome do ambiente para exibição
  String get displayName {
    switch (this) {
      case AppFlavor.dev:
        return 'Dev';
      case AppFlavor.prod:
        return 'Odyssey';
    }
  }

  /// Sufixo do package name (para Android)
  String get packageSuffix {
    switch (this) {
      case AppFlavor.dev:
        return '.dev';
      case AppFlavor.prod:
        return '';
    }
  }
}

/// Configuração global do flavor atual
/// É setado uma vez no bootstrap e não muda durante a execução
class FlavorConfig {
  static AppFlavor _flavor = AppFlavor.prod;

  /// Define o flavor (chamado apenas no bootstrap)
  static void setFlavor(AppFlavor flavor) {
    _flavor = flavor;
    debugPrint('🏷️ Flavor configurado: ${flavor.displayName}');
  }

  /// Retorna o flavor atual
  static AppFlavor get current => _flavor;

  /// Atalhos para verificação
  static bool get isDev => _flavor.isDev;
  static bool get isProd => _flavor.isProd;
}

/// Provider Riverpod para acessar o flavor atual
final currentFlavorProvider = Provider<AppFlavor>((ref) {
  return FlavorConfig.current;
});

/// Provider que indica se está em modo dev
final isDevModeProvider = Provider<bool>((ref) {
  return FlavorConfig.isDev;
});
