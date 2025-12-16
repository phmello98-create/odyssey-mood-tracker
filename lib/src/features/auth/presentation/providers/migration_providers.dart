// lib/src/features/auth/presentation/providers/migration_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/migration_service.dart';
import 'auth_providers.dart';
import 'sync_providers.dart';

// ============================================
// MIGRATION SERVICE PROVIDER
// ============================================

/// Provider para o MigrationService
/// 
/// Retorna null se o sync service não estiver disponível
/// (usuário não logado ou guest)
final migrationServiceProvider = Provider<MigrationService?>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  
  if (syncService == null) {
    return null;
  }
  
  return MigrationService(
    syncService: syncService,
    prefs: prefs,
  );
});

// ============================================
// MIGRATION STATE
// ============================================

/// Estado da migração
class MigrationState {
  final MigrationStatus status;
  final double progress;
  final String? currentStep;
  final MigrationResult? lastResult;
  final String? errorMessage;
  final bool needsMigration;

  const MigrationState({
    this.status = MigrationStatus.notStarted,
    this.progress = 0.0,
    this.currentStep,
    this.lastResult,
    this.errorMessage,
    this.needsMigration = false,
  });

  MigrationState copyWith({
    MigrationStatus? status,
    double? progress,
    String? currentStep,
    MigrationResult? lastResult,
    String? errorMessage,
    bool? needsMigration,
  }) {
    return MigrationState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage ?? this.errorMessage,
      needsMigration: needsMigration ?? this.needsMigration,
    );
  }

  bool get isInProgress => status == MigrationStatus.inProgress;
  bool get isCompleted => status == MigrationStatus.completed;
  bool get isFailed => status == MigrationStatus.failed;
}

// ============================================
// MIGRATION CONTROLLER
// ============================================

/// Controller para gerenciar operações de migração
class MigrationController extends StateNotifier<MigrationState> {
  final MigrationService? _migrationService;

  MigrationController(this._migrationService) : super(const MigrationState()) {
    _checkMigrationStatus();
  }

  /// Verifica se o serviço está disponível
  bool get isAvailable => _migrationService != null;

  /// Verifica o status inicial da migração
  Future<void> _checkMigrationStatus() async {
    if (_migrationService == null) return;

    try {
      final needs = await _migrationService.needsMigration();
      state = state.copyWith(needsMigration: needs);
    } catch (e) {
      // Ignora erros na verificação inicial
    }
  }

  /// Executa a migração de dados para a nuvem
  Future<MigrationResult?> migrateToCloud() async {
    if (_migrationService == null) {
      state = state.copyWith(
        status: MigrationStatus.failed,
        errorMessage: 'Serviço de migração não disponível. Faça login primeiro.',
      );
      return null;
    }

    state = state.copyWith(
      status: MigrationStatus.inProgress,
      progress: 0.0,
      currentStep: 'Iniciando migração...',
      errorMessage: null,
    );

    try {
      final result = await _migrationService.migrateToCloud(
        onProgress: (step, progress) {
          state = state.copyWith(
            currentStep: step,
            progress: progress,
          );
        },
      );

      state = state.copyWith(
        status: result.success 
            ? MigrationStatus.completed 
            : MigrationStatus.failed,
        progress: 1.0,
        currentStep: result.success 
            ? 'Migração concluída!' 
            : 'Migração concluída com erros',
        lastResult: result,
        needsMigration: !result.success,
        errorMessage: result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.failed,
        errorMessage: 'Erro na migração: $e',
        currentStep: null,
      );
      return null;
    }
  }

  /// Restaura dados da nuvem para o dispositivo
  Future<MigrationResult?> restoreFromCloud() async {
    if (_migrationService == null) {
      state = state.copyWith(
        status: MigrationStatus.failed,
        errorMessage: 'Serviço de migração não disponível. Faça login primeiro.',
      );
      return null;
    }

    state = state.copyWith(
      status: MigrationStatus.inProgress,
      progress: 0.0,
      currentStep: 'Iniciando restauração...',
      errorMessage: null,
    );

    try {
      final result = await _migrationService.restoreFromCloud(
        onProgress: (step, progress) {
          state = state.copyWith(
            currentStep: step,
            progress: progress,
          );
        },
      );

      state = state.copyWith(
        status: result.success 
            ? MigrationStatus.completed 
            : MigrationStatus.failed,
        progress: 1.0,
        currentStep: result.success 
            ? 'Restauração concluída!' 
            : 'Restauração concluída com erros',
        lastResult: result,
        errorMessage: result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.failed,
        errorMessage: 'Erro na restauração: $e',
        currentStep: null,
      );
      return null;
    }
  }

  /// Força uma nova migração
  Future<MigrationResult?> forceMigration() async {
    if (_migrationService == null) return null;

    state = state.copyWith(
      status: MigrationStatus.inProgress,
      progress: 0.0,
      currentStep: 'Preparando migração forçada...',
      errorMessage: null,
    );

    try {
      final result = await _migrationService.forceMigration(
        onProgress: (step, progress) {
          state = state.copyWith(
            currentStep: step,
            progress: progress,
          );
        },
      );

      state = state.copyWith(
        status: result.success 
            ? MigrationStatus.completed 
            : MigrationStatus.failed,
        progress: 1.0,
        lastResult: result,
        needsMigration: !result.success,
        errorMessage: result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        status: MigrationStatus.failed,
        errorMessage: 'Erro na migração: $e',
      );
      return null;
    }
  }

  /// Reseta o estado
  void reset() {
    state = const MigrationState();
    _checkMigrationStatus();
  }

  /// Limpa erro
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider para o MigrationController
final migrationControllerProvider =
    StateNotifierProvider<MigrationController, MigrationState>((ref) {
  final migrationService = ref.watch(migrationServiceProvider);
  return MigrationController(migrationService);
});

// ============================================
// CONVENIENCE PROVIDERS
// ============================================

/// Provider para verificar se precisa de migração
final needsMigrationProvider = FutureProvider<bool>((ref) async {
  final migrationService = ref.watch(migrationServiceProvider);
  if (migrationService == null) return false;
  
  return await migrationService.needsMigration();
});

/// Provider para obter a data da última migração
final lastMigrationDateProvider = Provider<DateTime?>((ref) {
  final migrationService = ref.watch(migrationServiceProvider);
  return migrationService?.getLastMigrationDate();
});

/// Provider para verificar se a migração está em progresso
final isMigrationInProgressProvider = Provider<bool>((ref) {
  return ref.watch(migrationControllerProvider).isInProgress;
});

/// Provider que verifica e oferece migração automaticamente
/// 
/// Use este provider para detectar quando o usuário precisa migrar
/// seus dados após fazer login.
final autoMigrationCheckProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isGuest) return false;
  
  final migrationService = ref.watch(migrationServiceProvider);
  if (migrationService == null) return false;
  
  return await migrationService.needsMigration();
});
