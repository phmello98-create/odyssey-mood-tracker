import 'package:freezed_annotation/freezed_annotation.dart';
import 'odyssey_user.dart';

part 'auth_result.freezed.dart';

/// Resultado de operações de autenticação
/// 
/// Encapsula o resultado de operações como login, cadastro, logout, etc.
/// Permite tratar erros de forma consistente e exibir mensagens ao usuário.
@freezed
class AuthResult with _$AuthResult {
  const AuthResult._();
  
  /// Operação bem sucedida
  const factory AuthResult.success({
    /// Usuário resultante (null em operações como logout)
    OdysseyUser? user,
    /// Mensagem opcional de sucesso
    String? message,
  }) = AuthResultSuccess;

  /// Operação falhou
  const factory AuthResult.failure({
    /// Mensagem de erro para exibir ao usuário
    required String message,
    /// Código de erro (para debugging/analytics)
    String? errorCode,
    /// Exceção original (para debugging)
    Object? exception,
  }) = AuthResultFailure;

  /// Operação em progresso (para UI loading states)
  const factory AuthResult.loading() = AuthResultLoading;

  /// Estado inicial (nenhuma operação realizada)
  const factory AuthResult.initial() = AuthResultInitial;

  /// Verifica se é sucesso
  bool get isSuccess => this is AuthResultSuccess;

  /// Verifica se é falha
  bool get isFailure => this is AuthResultFailure;

  /// Verifica se está carregando
  bool get isLoading => this is AuthResultLoading;

  /// Obtém o usuário se sucesso, null caso contrário
  OdysseyUser? get userOrNull => maybeWhen(
    success: (user, _) => user,
    orElse: () => null,
  );

  /// Obtém a mensagem de erro se falha, null caso contrário
  String? get errorMessage => maybeWhen(
    failure: (message, _, __) => message,
    orElse: () => null,
  );

  /// Obtém mensagem (sucesso ou erro)
  String? get message => maybeWhen(
    success: (_, message) => message,
    failure: (message, _, __) => message,
    orElse: () => null,
  );
}

/// Status de sincronização
enum SyncStatus {
  /// Não sincronizado / sincronização desabilitada
  idle,
  
  /// Sincronização em progresso
  syncing,
  
  /// Sincronizado com sucesso
  synced,
  
  /// Erro na sincronização
  error,
  
  /// Aguardando conexão de rede
  waitingForNetwork,
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.idle:
        return 'Não sincronizado';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.error:
        return 'Erro na sincronização';
      case SyncStatus.waitingForNetwork:
        return 'Aguardando conexão';
    }
  }

  bool get isSyncing => this == SyncStatus.syncing;
  bool get hasError => this == SyncStatus.error;
  bool get isSynced => this == SyncStatus.synced;
}
