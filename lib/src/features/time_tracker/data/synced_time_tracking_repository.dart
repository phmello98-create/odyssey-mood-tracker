// lib/src/features/time_tracker/data/synced_time_tracking_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline
class SyncedTimeTrackingRepository with SyncedRepositoryMixin {
  final TimeTrackingRepository _localRepository;
  @override
  final Ref ref;
  
  @override
  String get collectionName => 'timeTracking';
  
  SyncedTimeTrackingRepository(this._localRepository, this.ref);
  
  /// Acesso ao box Hive para ValueListenableBuilder
  Box<TimeTrackingRecord> get box => _localRepository.box;
  
  // ============================================
  // MÉTODOS DE ESCRITA (com sync)
  // ============================================
  
  /// Adiciona um registro de time tracking e enfileira para sync
  Future<int> addTimeTrackingRecord(TimeTrackingRecord record) async {
    final result = await _localRepository.addTimeTrackingRecord(record);
    await enqueueCreate(record.id, _recordToMap(record));
    return result;
  }
  
  /// Atualiza um registro de time tracking e enfileira para sync
  Future<void> updateTimeTrackingRecord(String id, TimeTrackingRecord record) async {
    await _localRepository.updateTimeTrackingRecord(id, record);
    await enqueueUpdate(id, _recordToMap(record));
  }
  
  /// Deleta um registro de time tracking e enfileira para sync
  Future<void> deleteTimeTrackingRecord(String id) async {
    await _localRepository.deleteTimeTrackingRecord(id);
    await enqueueDelete(id);
  }
  
  /// Alterna status de completado e enfileira para sync
  Future<void> toggleCompleted(String id) async {
    await _localRepository.toggleCompleted(id);
    
    // Buscar registro atualizado
    final records = _localRepository.fetchAllTimeTrackingRecords();
    final record = records.where((r) => r.id == id).firstOrNull;
    if (record != null) {
      await enqueueUpdate(id, _recordToMap(record));
    }
  }
  
  // ============================================
  // MÉTODOS DE LEITURA (não precisam de sync)
  // ============================================
  
  List<TimeTrackingRecord> fetchAllTimeTrackingRecords() => 
      _localRepository.fetchAllTimeTrackingRecords();
  
  List<TimeTrackingRecord> fetchTimeTrackingRecordsByDate(DateTime date) => 
      _localRepository.fetchTimeTrackingRecordsByDate(date);
  
  int countCompletedToday() => _localRepository.countCompletedToday();
  
  Set<String> getAllProjects() => _localRepository.getAllProjects();
  
  Set<String> getAllCategories() => _localRepository.getAllCategories();
  
  // ============================================
  // CONVERSÃO
  // ============================================
  
  Map<String, dynamic> _recordToMap(TimeTrackingRecord record) {
    return {
      'id': record.id,
      'activityName': record.activityName,
      'iconCode': record.iconCode,
      'startTime': record.startTime.toIso8601String(),
      'endTime': record.endTime.toIso8601String(),
      'durationInSeconds': record.durationInSeconds,
      'notes': record.notes,
      'category': record.category,
      'project': record.project,
      'isCompleted': record.isCompleted,
      'colorValue': record.colorValue,
      '_localModifiedAt': record.endTime.toIso8601String(),
    };
  }
}

/// Provider para o SyncedTimeTrackingRepository
final syncedTimeTrackingRepositoryProvider = Provider<SyncedTimeTrackingRepository>((ref) {
  final localRepository = ref.watch(timeTrackingRepositoryProvider);
  return SyncedTimeTrackingRepository(localRepository, ref);
});
