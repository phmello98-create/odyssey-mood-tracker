// lib/src/features/habits/data/synced_habit_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/habit.dart';
import 'habit_repository.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline
class SyncedHabitRepository with SyncedRepositoryMixin {
  final HabitRepository _localRepository;
  @override
  final Ref ref;
  
  @override
  String get collectionName => 'habits';
  
  SyncedHabitRepository(this._localRepository, this.ref);
  
  /// Inicializa o repositório
  Future<void> init() => _localRepository.init();
  
  /// Adiciona um hábito e enfileira para sync
  Future<void> addHabit(Habit habit) async {
    await _localRepository.addHabit(habit);
    await enqueueCreate(habit.id, _habitToMap(habit));
  }
  
  /// Atualiza um hábito e enfileira para sync
  Future<void> updateHabit(Habit habit) async {
    await _localRepository.updateHabit(habit);
    await enqueueUpdate(habit.id, _habitToMap(habit));
  }
  
  /// Deleta um hábito e enfileira para sync
  Future<void> deleteHabit(String id) async {
    await _localRepository.deleteHabit(id);
    await enqueueDelete(id);
  }
  
  /// Toggle de conclusão do hábito e enfileira para sync
  Future<void> toggleHabitCompletion(String id, DateTime date) async {
    await _localRepository.toggleHabitCompletion(id, date);
    
    // Buscar o hábito atualizado para sincronizar
    final habits = _localRepository.getAllHabits();
    final habit = habits.firstWhere((h) => h.id == id, orElse: () => habits.first);
    await enqueueUpdate(id, _habitToMap(habit));
  }
  
  /// Pula um hábito para uma data e enfileira para sync
  Future<void> skipHabitForDate(String habitId, DateTime date) async {
    await _localRepository.skipHabitForDate(habitId, date);
    
    final habits = _localRepository.getAllHabits();
    final habit = habits.firstWhere((h) => h.id == habitId, orElse: () => habits.first);
    await enqueueUpdate(habitId, _habitToMap(habit));
  }
  
  /// Remove marcação de pulado e enfileira para sync
  Future<void> unskipHabitForDate(String habitId, DateTime date) async {
    await _localRepository.unskipHabitForDate(habitId, date);
    
    final habits = _localRepository.getAllHabits();
    final habit = habits.firstWhere((h) => h.id == habitId, orElse: () => habits.first);
    await enqueueUpdate(habitId, _habitToMap(habit));
  }
  
  // ============================================
  // MÉTODOS DE LEITURA (não precisam de sync)
  // ============================================
  
  List<Habit> getAllHabits() => _localRepository.getAllHabits();
  
  List<Habit> getHabitsForDate(DateTime date) => 
      _localRepository.getHabitsForDate(date);
  
  int getCompletedCountForDate(DateTime date) => 
      _localRepository.getCompletedCountForDate(date);
  
  int getTotalCountForDate(DateTime date) => 
      _localRepository.getTotalCountForDate(date);
  
  double getCompletionRateForDate(DateTime date) => 
      _localRepository.getCompletionRateForDate(date);
  
  Map<int, double> getWeekCompletionRates() => 
      _localRepository.getWeekCompletionRates();
  
  Future<bool> isHabitSkippedForDate(String habitId, DateTime date) => 
      _localRepository.isHabitSkippedForDate(habitId, date);
  
  Future<List<Habit>> getPendingHabitsForDate(DateTime date) => 
      _localRepository.getPendingHabitsForDate(date);
  
  // ============================================
  // CONVERSÃO
  // ============================================
  
  Map<String, dynamic> _habitToMap(Habit habit) {
    final latestDate = habit.completedDates.isNotEmpty 
        ? habit.completedDates.reduce((a, b) => a.isAfter(b) ? a : b)
        : habit.createdAt;
    
    return {
      'id': habit.id,
      'name': habit.name,
      'iconCode': habit.iconCode,
      'colorValue': habit.colorValue,
      'scheduledTime': habit.scheduledTime,
      'daysOfWeek': habit.daysOfWeek,
      'completedDates': habit.completedDates.map((d) => d.toIso8601String()).toList(),
      'currentStreak': habit.currentStreak,
      'bestStreak': habit.bestStreak,
      'createdAt': habit.createdAt.toIso8601String(),
      'order': habit.order,
      '_localModifiedAt': latestDate.toIso8601String(),
    };
  }
}

/// Provider para o SyncedHabitRepository
final syncedHabitRepositoryProvider = Provider<SyncedHabitRepository>((ref) {
  final localRepository = ref.watch(habitRepositoryProvider);
  return SyncedHabitRepository(localRepository, ref);
});
