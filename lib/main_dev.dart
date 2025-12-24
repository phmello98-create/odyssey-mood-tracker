import 'package:odyssey/bootstrap.dart';
import 'package:odyssey/src/config/app_flavor.dart';

/// Entry point para ambiente de DESENVOLVIMENTO
///
/// Use este entry point para:
/// - Testar funcionalidades novas
/// - Usar seed data
/// - Acessar ferramentas de debug
/// - Testar sem afetar dados de produção
///
/// Comando: flutter run --flavor dev -t lib/main_dev.dart
void main() {
  bootstrap(AppFlavor.dev);
}
