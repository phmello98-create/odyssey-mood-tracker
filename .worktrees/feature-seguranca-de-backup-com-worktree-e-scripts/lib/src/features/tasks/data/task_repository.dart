import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/gamification/data/synced_gamification_repository.dart';
import 'package:odyssey/src/utils/services/notification_scheduler.dart';
import 'package:odyssey/src/utils/services/modern_notification_service.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref);
});

/// Classe que representa uma tarefa com tipagem forte
class TaskData {
  final dynamic key;
  final String title;
  final String? notes;
  final bool completed;
  final String priority; // 'low', 'medium', 'high'
  final String? category;
  final DateTime? dueDate;
  final String? dueTime;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskData({
    required this.key,
    required this.title,
    this.notes,
    this.completed = false,
    this.priority = 'medium',
    this.category,
    this.dueDate,
    this.dueTime,
    required this.createdAt,
    this.completedAt,
  });

  factory TaskData.fromMap(dynamic key, Map data) {
    return TaskData(
      key: key,
      title: data['title'] ?? 'Tarefa',
      notes: data['notes'],
      completed: data['completed'] == true,
      priority: data['priority'] ?? 'medium',
      category: data['category'],
      dueDate: data['dueDate'] != null ? DateTime.tryParse(data['dueDate']) : null,
      dueTime: data['dueTime'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      completedAt: data['completedAt'] != null ? DateTime.tryParse(data['completedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'notes': notes,
      'completed': completed,
      'priority': priority,
      'category': category,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  TaskData copyWith({
    dynamic key,
    String? title,
    String? notes,
    bool? completed,
    String? priority,
    String? category,
    DateTime? dueDate,
    String? dueTime,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TaskData(
      key: key ?? this.key,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class TaskRepository {
  static const String _boxName = 'tasks';
  Box? _box;
  bool _isInitialized = false;
  final Ref? _ref;

  TaskRepository([this._ref]);

  // Cache de tarefas para evitar leituras repetidas
  List<TaskData>? _cachedTasks;
  DateTime? _lastCacheUpdate;
  static const _cacheValidityDuration = Duration(seconds: 5);

  /// Retorna o ValueListenable do box para uso com ValueListenableBuilder
  ValueListenable<Box>? get boxListenable => _box?.listenable();

  /// Inicializa o repositório
  Future<void> init() async {
    if (_isInitialized) return;
    _box = await Hive.openBox(_boxName);
    _isInitialized = true;
    _invalidateCache();
  }

  /// Garante que o box está aberto
  Future<Box> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;
    }
    return _box!;
  }

  void _invalidateCache() {
    _cachedTasks = null;
    _lastCacheUpdate = null;
  }

  bool _isCacheValid() {
    if (_cachedTasks == null || _lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration;
  }

  /// Retorna todas as tarefas
  Future<List<TaskData>> getAllTasks() async {
    if (_isCacheValid()) return _cachedTasks!;

    final box = await _ensureBox();
    final tasks = <TaskData>[];
    
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        tasks.add(TaskData.fromMap(key, Map<String, dynamic>.from(value)));
      }
    }
    
    // Ordena por data de criação (mais recentes primeiro)
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    _cachedTasks = tasks;
    _lastCacheUpdate = DateTime.now();
    
    return tasks;
  }

  /// Retorna tarefas pendentes
  Future<List<TaskData>> getPendingTasks() async {
    final tasks = await getAllTasks();
    return tasks.where((t) => !t.completed).toList();
  }

  /// Retorna tarefas completadas
  Future<List<TaskData>> getCompletedTasks() async {
    final tasks = await getAllTasks();
    return tasks.where((t) => t.completed).toList();
  }

  /// Retorna tarefas para uma data específica
  Future<List<TaskData>> getTasksForDate(DateTime date) async {
    final tasks = await getAllTasks();
    return tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == date.year &&
             t.dueDate!.month == date.month &&
             t.dueDate!.day == date.day;
    }).toList();
  }

  /// Retorna tarefas pendentes para hoje
  Future<List<TaskData>> getPendingTasksForToday() async {
    final now = DateTime.now();
    final tasks = await getTasksForDate(now);
    return tasks.where((t) => !t.completed).toList();
  }

  /// Retorna contagem de tarefas pendentes
  Future<int> getPendingCount() async {
    final tasks = await getPendingTasks();
    return tasks.length;
  }

  /// Retorna contagem de tarefas pendentes para hoje
  Future<int> getPendingCountForToday() async {
    final tasks = await getPendingTasksForToday();
    return tasks.length;
  }

  /// Adiciona uma nova tarefa
  Future<dynamic> addTask(TaskData task) async {
    final box = await _ensureBox();
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(key, task.toMap());
    _invalidateCache();
    
    // Agendar notificação se tiver data e hora
    if (task.dueDate != null && task.dueTime != null) {
      await _scheduleTaskReminder(key, task);
    }
    
    return key;
  }

  /// Atualiza uma tarefa existente
  Future<void> updateTask(TaskData task) async {
    final box = await _ensureBox();
    await box.put(task.key, task.toMap());
    _invalidateCache();
    
    // Re-agendar notificação se tiver data e hora
    final taskKey = task.key.toString();
    await NotificationScheduler.instance.cancelTaskReminder(taskKey);
    if (task.dueDate != null && task.dueTime != null && !task.completed) {
      await _scheduleTaskReminder(taskKey, task);
    }
  }

  /// Remove uma tarefa
  Future<void> deleteTask(dynamic key) async {
    final box = await _ensureBox();
    await box.delete(key);
    _invalidateCache();
    
    // Cancelar notificação agendada
    await NotificationScheduler.instance.cancelTaskReminder(key.toString());
  }

  /// Agenda notificação para tarefa com horário
  Future<void> _scheduleTaskReminder(String taskId, TaskData task) async {
    if (task.dueDate == null || task.dueTime == null) return;
    
    try {
      // Parse do horário (formato "HH:mm")
      final timeParts = task.dueTime!.split(':');
      if (timeParts.length != 2) return;
      
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      
      final scheduledTime = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        hour,
        minute,
      );
      
      // Só agenda se for no futuro
      if (scheduledTime.isAfter(DateTime.now())) {
        await NotificationScheduler.instance.scheduleTaskAtTime(
          taskId: taskId,
          title: task.title,
          when: scheduledTime,
          body: task.notes ?? 'Lembrete da tarefa agendada',
        );
        debugPrint('📅 Notificação agendada para tarefa: ${task.title} às $hour:$minute');
      }
    } catch (e) {
      debugPrint('❌ Erro ao agendar notificação de tarefa: $e');
    }
  }

  /// Alterna o status de conclusão de uma tarefa
  Future<TaskData?> toggleTaskCompletion(dynamic key) async {
    final box = await _ensureBox();
    final data = box.get(key);
    
    if (data == null || data is! Map) return null;
    
    final task = TaskData.fromMap(key, Map<String, dynamic>.from(data));
    final newCompleted = !task.completed;
    
    final updatedTask = task.copyWith(
      completed: newCompleted,
      completedAt: newCompleted ? DateTime.now() : null,
    );
    
    await box.put(key, updatedTask.toMap());
    _invalidateCache();
    
    // Cancelar notificação quando completar tarefa
    if (newCompleted) {
      await NotificationScheduler.instance.cancelTaskReminder(key.toString());
      // Cancelar também a notificação moderna
      await ModernNotificationService.instance.cancelTaskReminder(key.hashCode);
    }
    
    // Integração com gamificação - dar XP quando completar tarefa
    if (newCompleted && _ref != null) {
      try {
        final gamificationRepo = _ref.read(syncedGamificationRepositoryProvider);
        await gamificationRepo.completeTask();
      } catch (e) {
        debugPrint('Erro ao atualizar gamificação: $e');
      }
    }
    
    return updatedTask;
  }

  /// Retorna estatísticas das tarefas
  Future<Map<String, dynamic>> getTaskStats() async {
    final tasks = await getAllTasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int totalTasks = tasks.length;
    int completedTasks = tasks.where((t) => t.completed).length;
    int pendingTasks = totalTasks - completedTasks;
    
    // Tarefas atrasadas (com data de vencimento anterior a hoje e não completadas)
    int overdueTasks = tasks.where((t) {
      if (t.completed || t.dueDate == null) return false;
      final dueDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDate.isBefore(today);
    }).length;
    
    // Tarefas de alta prioridade pendentes
    int highPriorityPending = tasks.where((t) => 
      !t.completed && t.priority == 'high'
    ).length;
    
    // Taxa de conclusão (últimos 7 dias)
    final weekAgo = today.subtract(const Duration(days: 7));
    final recentTasks = tasks.where((t) => t.createdAt.isAfter(weekAgo));
    double weeklyCompletionRate = 0;
    if (recentTasks.isNotEmpty) {
      weeklyCompletionRate = recentTasks.where((t) => t.completed).length / 
                            recentTasks.length;
    }
    
    return {
      'total': totalTasks,
      'completed': completedTasks,
      'pending': pendingTasks,
      'overdue': overdueTasks,
      'highPriorityPending': highPriorityPending,
      'weeklyCompletionRate': weeklyCompletionRate,
    };
  }

  /// Adia uma tarefa para amanhã
  Future<TaskData?> postponeTaskToTomorrow(dynamic key) async {
    return moveTaskToDate(key, DateTime.now().add(const Duration(days: 1)));
  }

  /// Move uma tarefa para hoje
  Future<TaskData?> moveTaskToToday(dynamic key) async {
    return moveTaskToDate(key, DateTime.now());
  }

  /// Move uma tarefa para depois de amanhã
  Future<TaskData?> moveTaskToDayAfterTomorrow(dynamic key) async {
    return moveTaskToDate(key, DateTime.now().add(const Duration(days: 2)));
  }

  /// Move uma tarefa para uma data específica
  Future<TaskData?> moveTaskToDate(dynamic key, DateTime targetDate) async {
    final box = await _ensureBox();
    final data = box.get(key);
    
    if (data == null || data is! Map) return null;
    
    final task = TaskData.fromMap(key, Map<String, dynamic>.from(data));
    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    final updatedTask = task.copyWith(
      dueDate: targetDateOnly,
    );
    
    await box.put(key, updatedTask.toMap());
    _invalidateCache();
    
    // Re-agendar notificação se houver horário
    final taskKey = key.toString();
    await NotificationScheduler.instance.cancelTaskReminder(taskKey);
    if (updatedTask.dueTime != null) {
      await _scheduleTaskReminder(taskKey, updatedTask);
    }
    
    return updatedTask;
  }

  /// Retorna tarefas atrasadas (vencidas e não completadas)
  Future<List<TaskData>> getOverdueTasks() async {
    final tasks = await getAllTasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return tasks.where((t) {
      if (t.completed || t.dueDate == null) return false;
      final dueDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDate.isBefore(today);
    }).toList();
  }

  /// Limpa tarefas completadas há mais de X dias
  Future<int> clearOldCompletedTasks({int daysOld = 30}) async {
    final box = await _ensureBox();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    final keysToDelete = <dynamic>[];
    
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map && value['completed'] == true) {
        final completedAt = value['completedAt'] != null 
            ? DateTime.tryParse(value['completedAt']) 
            : null;
        if (completedAt != null && completedAt.isBefore(cutoffDate)) {
          keysToDelete.add(key);
        }
      }
    }
    
    for (final key in keysToDelete) {
      await box.delete(key);
    }
    
    _invalidateCache();
    return keysToDelete.length;
  }
}
