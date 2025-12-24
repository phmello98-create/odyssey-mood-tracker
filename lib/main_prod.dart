import 'package:odyssey/bootstrap.dart';
import 'package:odyssey/src/config/app_flavor.dart';

/// Entry point para ambiente de PRODUÇÃO
///
/// Use este entry point para:
/// - Build final para usuários
/// - Upload para Play Store
/// - Versão limpa sem ferramentas de debug
///
/// Comando: flutter run --flavor prod -t lib/main_prod.dart
void main() {
  bootstrap(AppFlavor.prod);
}
