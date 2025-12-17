// lib/src/features/tasks/data/synced_task_repository.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_repository.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline
class SyncedTaskRepository with SyncedRepositoryMixin {
  final TaskRepository _localRepository;
  @override
  final Ref ref;
  
  @override
  String get collectionName => 'tasks';
  
  SyncedTaskRepository(this._localRepository, this.ref);
  
  /// Inicializa o repositório
  Future<void> init() => _localRepository.init();
  
  /// ValueListenable do box para observers
  ValueListenable? get boxListenable => _localRepository.boxListenable;
  
  /// Adiciona uma tarefa e enfileira para sync
  Future<dynamic> addTask(TaskData task) async {
    final key = await _localRepository.addTask(task);
    await enqueueCreate(key.toString(), _taskToMap(task, key.toString()));
    return key;
  }
  
  /// Atualiza uma tarefa e enfileira para sync
  Future<void> updateTask(TaskData task) async {
    await _localRepository.updateTask(task);
    await enqueueUpdate(task.key.toString(), _taskToMap(task, task.key.toString()));
  }
  
  /// Remove uma tarefa e enfileira para sync
  Future<void> deleteTask(dynamic key) async {
    await _localRepository.deleteTask(key);
    await enqueueDelete(key.toString());
  }
  
  /// Toggle de conclusão da tarefa e enfileira para sync
  Future<TaskData?> toggleTaskCompletion(dynamic key) async {
    final result = await _localRepository.toggleTaskCompletion(key);
    if (result != null) {
      await enqueueUpdate(key.toString(), _taskToMap(result, key.toString()));
    }
    return result;
  }
  
  /// Adia tarefa para amanhã e enfileira para sync
  Future<TaskData?> postponeTaskToTomorrow(dynamic key) async {
    final result = await _localRepository.postponeTaskToTomorrow(key);
    if (result != null) {
      await enqueueUpdate(key.toString(), _taskToMap(result, key.toString()));
    }
    return result;
  }
  
  /// Move tarefa para hoje e enfileira para sync
  Future<TaskData?> moveTaskToToday(dynamic key) async {
    final result = await _localRepository.moveTaskToToday(key);
    if (result != null) {
      await enqueueUpdate(key.toString(), _taskToMap(result, key.toString()));
    }
    return result;
  }
  
  /// Move tarefa para depois de amanhã e enfileira para sync
  Future<TaskData?> moveTaskToDayAfterTomorrow(dynamic key) async {
    final result = await _localRepository.moveTaskToDayAfterTomorrow(key);
    if (result != null) {
      await enqueueUpdate(key.toString(), _taskToMap(result, key.toString()));
    }
    return result;
  }
  
  /// Move tarefa para data específica e enfileira para sync
  Future<TaskData?> moveTaskToDate(dynamic key, DateTime targetDate) async {
    final result = await _localRepository.moveTaskToDate(key, targetDate);
    if (result != null) {
      await enqueueUpdate(key.toString(), _taskToMap(result, key.toString()));
    }
    return result;
  }
  
  /// Limpa tarefas antigas e sincroniza
  Future<int> clearOldCompletedTasks({int daysOld = 30}) async {
    final result = await _localRepository.clearOldCompletedTasks(daysOld: daysOld);
    // Para limpeza em massa, fazemos sync completo
    if (result > 0) await syncImmediately();
    return result;
  }
  
  // ============================================
  // MÉTODOS DE LEITURA (não precisam de sync)
  // ============================================
  
  Future<List<TaskData>> getAllTasks() => _localRepository.getAllTasks();
  
  Future<List<TaskData>> getPendingTasks() => _localRepository.getPendingTasks();
  
  Future<List<TaskData>> getCompletedTasks() => _localRepository.getCompletedTasks();
  
  Future<List<TaskData>> getTasksForDate(DateTime date) => 
      _localRepository.getTasksForDate(date);
  
  Future<List<TaskData>> getPendingTasksForToday() => 
      _localRepository.getPendingTasksForToday();
  
  Future<int> getPendingCount() => _localRepository.getPendingCount();
  
  Future<int> getPendingCountForToday() => _localRepository.getPendingCountForToday();
  
  Future<Map<String, dynamic>> getTaskStats() => _localRepository.getTaskStats();
  
  Future<List<TaskData>> getOverdueTasks() => _localRepository.getOverdueTasks();
  
  // ============================================
  // CONVERSÃO
  // ============================================
  
  Map<String, dynamic> _taskToMap(TaskData task, String key) {
    return {
      'id': key,
      'title': task.title,
      'notes': task.notes,
      'completed': task.completed,
      'dueDate': task.dueDate?.toIso8601String(),
      'dueTime': task.dueTime,
      'completedAt': task.completedAt?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
      'priority': task.priority,
      'category': task.category,
      '_localModifiedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider para o SyncedTaskRepository
final syncedTaskRepositoryProvider = Provider<SyncedTaskRepository>((ref) {
  final localRepository = ref.watch(taskRepositoryProvider);
  return SyncedTaskRepository(localRepository, ref);
});
