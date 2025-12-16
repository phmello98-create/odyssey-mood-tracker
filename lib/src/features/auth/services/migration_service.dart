// lib/src/features/auth/services/migration_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_service.dart';

/// Status da migração
enum MigrationStatus {
  notStarted,
  inProgress,
  completed,
  failed,
}

/// Resultado de uma etapa de migração
class MigrationStepResult {
  final String step;
  final bool success;
  final int itemsCount;
  final String? errorMessage;

  MigrationStepResult({
    required this.step,
    required this.success,
    this.itemsCount = 0,
    this.errorMessage,
  });
}

/// Resultado completo da migração
class MigrationResult {
  final bool success;
  final List<MigrationStepResult> steps;
  final DateTime completedAt;
  final Duration duration;
  final String? errorMessage;

  MigrationResult({
    required this.success,
    required this.steps,
    required this.completedAt,
    required this.duration,
    this.errorMessage,
  });

  /// Total de itens migrados
  int get totalItemsMigrated => steps
      .where((s) => s.success)
      .fold(0, (sum, s) => sum + s.itemsCount);

  /// Etapas que falharam
  List<MigrationStepResult> get failedSteps =>
      steps.where((s) => !s.success).toList();
}

/// Serviço de migração de dados locais (Hive) para nuvem (Firestore)
class MigrationService {
  final SyncService _syncService;
  final SharedPreferences _prefs;

  // Chaves de SharedPreferences
  static const String _migratedKey = 'data_migrated_v1';
  static const String _migrationDateKey = 'migration_date';
  static const String _migrationVersionKey = 'migration_version';
  static const String _lastMigrationResultKey = 'last_migration_result';

  // Versão atual da migração (incrementar quando houver mudanças no schema)
  static const int _currentMigrationVersion = 1;

  MigrationService({
    required SyncService syncService,
    required SharedPreferences prefs,
  })  : _syncService = syncService,
        _prefs = prefs;

  /// Verifica se precisa fazer migração
  Future<bool> needsMigration() async {
    final wasMigrated = _prefs.getBool(_migratedKey) ?? false;
    if (!wasMigrated) return true;

    // Verifica se a versão da migração está atualizada
    final migratedVersion = _prefs.getInt(_migrationVersionKey) ?? 0;
    return migratedVersion < _currentMigrationVersion;
  }

  /// Retorna a data da última migração
  DateTime? getLastMigrationDate() {
    final timestamp = _prefs.getInt(_migrationDateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Retorna a versão da migração atual
  int getCurrentMigrationVersion() => _currentMigrationVersion;

  /// Retorna a versão da última migração feita
  int getLastMigrationVersion() => _prefs.getInt(_migrationVersionKey) ?? 0;

  /// Executa a migração completa de dados para a nuvem
  /// 
  /// [onProgress] - Callback chamado a cada etapa com (etapa, progresso 0-1)
  Future<MigrationResult> migrateToCloud({
    void Function(String step, double progress)? onProgress,
  }) async {
    final startTime = DateTime.now();
    final steps = <MigrationStepResult>[];
    
    try {
      debugPrint('[MigrationService] Starting migration...');

      // Etapa 1: Moods (20%)
      onProgress?.call('Migrando humores...', 0.0);
      final moodsResult = await _syncService.syncMoods();
      steps.add(MigrationStepResult(
        step: 'moods',
        success: moodsResult.success,
        itemsCount: moodsResult.itemsSynced,
        errorMessage: moodsResult.errorMessage,
      ));
      onProgress?.call('Humores migrados', 0.2);

      // Etapa 2: Tasks (40%)
      onProgress?.call('Migrando tarefas...', 0.2);
      final tasksResult = await _syncService.syncTasks();
      steps.add(MigrationStepResult(
        step: 'tasks',
        success: tasksResult.success,
        itemsCount: tasksResult.itemsSynced,
        errorMessage: tasksResult.errorMessage,
      ));
      onProgress?.call('Tarefas migradas', 0.4);

      // Etapa 3: Habits (60%)
      onProgress?.call('Migrando hábitos...', 0.4);
      final habitsResult = await _syncService.syncHabits();
      steps.add(MigrationStepResult(
        step: 'habits',
        success: habitsResult.success,
        itemsCount: habitsResult.itemsSynced,
        errorMessage: habitsResult.errorMessage,
      ));
      onProgress?.call('Hábitos migrados', 0.6);

      // Etapa 4: Notes (80%)
      onProgress?.call('Migrando notas...', 0.6);
      final notesResult = await _syncService.syncNotes();
      steps.add(MigrationStepResult(
        step: 'notes',
        success: notesResult.success,
        itemsCount: notesResult.itemsSynced,
        errorMessage: notesResult.errorMessage,
      ));
      onProgress?.call('Notas migradas', 0.8);

      // Etapa 5: Quotes (100%)
      onProgress?.call('Migrando citações...', 0.8);
      final quotesResult = await _syncService.syncQuotes();
      steps.add(MigrationStepResult(
        step: 'quotes',
        success: quotesResult.success,
        itemsCount: quotesResult.itemsSynced,
        errorMessage: quotesResult.errorMessage,
      ));
      onProgress?.call('Citações migradas', 1.0);

      // Verifica se todas as etapas foram bem-sucedidas
      final allSuccess = steps.every((s) => s.success);
      final endTime = DateTime.now();

      if (allSuccess) {
        // Marca como migrado
        await _prefs.setBool(_migratedKey, true);
        await _prefs.setInt(_migrationDateKey, endTime.millisecondsSinceEpoch);
        await _prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
        
        debugPrint('[MigrationService] Migration completed successfully');
      } else {
        debugPrint('[MigrationService] Migration completed with errors');
      }

      return MigrationResult(
        success: allSuccess,
        steps: steps,
        completedAt: endTime,
        duration: endTime.difference(startTime),
      );
    } catch (e) {
      debugPrint('[MigrationService] Migration failed: $e');
      
      return MigrationResult(
        success: false,
        steps: steps,
        completedAt: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        errorMessage: e.toString(),
      );
    }
  }

  /// Restaura dados da nuvem para o dispositivo local
  Future<MigrationResult> restoreFromCloud({
    void Function(String step, double progress)? onProgress,
  }) async {
    final startTime = DateTime.now();
    final steps = <MigrationStepResult>[];
    
    try {
      debugPrint('[MigrationService] Starting restore from cloud...');

      // Etapa 1: Moods
      onProgress?.call('Restaurando humores...', 0.0);
      final moodsResult = await _syncService.downloadMoods();
      steps.add(MigrationStepResult(
        step: 'moods',
        success: moodsResult.success,
        itemsCount: moodsResult.itemsSynced,
        errorMessage: moodsResult.errorMessage,
      ));
      onProgress?.call('Humores restaurados', 0.2);

      // Etapa 2: Tasks
      onProgress?.call('Restaurando tarefas...', 0.2);
      final tasksResult = await _syncService.downloadTasks();
      steps.add(MigrationStepResult(
        step: 'tasks',
        success: tasksResult.success,
        itemsCount: tasksResult.itemsSynced,
        errorMessage: tasksResult.errorMessage,
      ));
      onProgress?.call('Tarefas restauradas', 0.4);

      // Etapa 3: Habits
      onProgress?.call('Restaurando hábitos...', 0.4);
      final habitsResult = await _syncService.downloadHabits();
      steps.add(MigrationStepResult(
        step: 'habits',
        success: habitsResult.success,
        itemsCount: habitsResult.itemsSynced,
        errorMessage: habitsResult.errorMessage,
      ));
      onProgress?.call('Hábitos restaurados', 0.6);

      // Etapa 4: Notes
      onProgress?.call('Restaurando notas...', 0.6);
      final notesResult = await _syncService.downloadNotes();
      steps.add(MigrationStepResult(
        step: 'notes',
        success: notesResult.success,
        itemsCount: notesResult.itemsSynced,
        errorMessage: notesResult.errorMessage,
      ));
      onProgress?.call('Notas restauradas', 0.8);

      // Etapa 5: Quotes
      onProgress?.call('Restaurando citações...', 0.8);
      final quotesResult = await _syncService.downloadQuotes();
      steps.add(MigrationStepResult(
        step: 'quotes',
        success: quotesResult.success,
        itemsCount: quotesResult.itemsSynced,
        errorMessage: quotesResult.errorMessage,
      ));
      onProgress?.call('Citações restauradas', 1.0);

      final allSuccess = steps.every((s) => s.success);
      final endTime = DateTime.now();

      debugPrint('[MigrationService] Restore ${allSuccess ? 'completed' : 'completed with errors'}');

      return MigrationResult(
        success: allSuccess,
        steps: steps,
        completedAt: endTime,
        duration: endTime.difference(startTime),
      );
    } catch (e) {
      debugPrint('[MigrationService] Restore failed: $e');
      
      return MigrationResult(
        success: false,
        steps: steps,
        completedAt: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        errorMessage: e.toString(),
      );
    }
  }

  /// Reseta o status de migração (útil para debug/testes)
  Future<void> resetMigration() async {
    await _prefs.remove(_migratedKey);
    await _prefs.remove(_migrationDateKey);
    await _prefs.remove(_migrationVersionKey);
    await _prefs.remove(_lastMigrationResultKey);
    debugPrint('[MigrationService] Migration status reset');
  }

  /// Força uma nova migração mesmo se já foi feita
  Future<MigrationResult> forceMigration({
    void Function(String step, double progress)? onProgress,
  }) async {
    await resetMigration();
    return migrateToCloud(onProgress: onProgress);
  }
}
