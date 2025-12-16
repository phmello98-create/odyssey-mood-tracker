import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/habit.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

class HabitRepository {
  static const String _boxName = 'habits';
  late Box<Habit> _box;
  bool _isInitialized = false;

  Box<Habit> get box => _box;

  Future<void> init() async {
    if (_isInitialized) return;
    
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(HabitAdapter());
    }
    
    _box = await Hive.openBox<Habit>(_boxName);
    _isInitialized = true;
  }

  Future<void> _addSampleHabits() async {
    final now = DateTime.now();
    final sampleHabits = [
      Habit(
        id: '1',
        name: 'Meditação',
        iconCode: Icons.self_improvement.codePoint,
        colorValue: const Color(0xFF9B51E0).value,
        scheduledTime: '06:30',
        daysOfWeek: [], // Todos os dias
        completedDates: [
          now.subtract(const Duration(days: 1)),
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 3)),
        ],
        currentStreak: 3,
        bestStreak: 7,
        createdAt: now.subtract(const Duration(days: 30)),
        order: 0,
      ),
      Habit(
        id: '2',
        name: 'Exercício',
        iconCode: Icons.fitness_center.codePoint,
        colorValue: const Color(0xFFFF6B6B).value,
        scheduledTime: '07:00',
        daysOfWeek: [1, 2, 3, 4, 5], // Dias úteis
        completedDates: [
          now.subtract(const Duration(days: 1)),
        ],
        currentStreak: 1,
        bestStreak: 12,
        createdAt: now.subtract(const Duration(days: 60)),
        order: 1,
      ),
      Habit(
        id: '3',
        name: 'Leitura',
        iconCode: Icons.menu_book.codePoint,
        colorValue: const Color(0xFF07E092).value,
        scheduledTime: '22:00',
        daysOfWeek: [],
        completedDates: [],
        currentStreak: 0,
        bestStreak: 5,
        createdAt: now.subtract(const Duration(days: 14)),
        order: 2,
      ),
      Habit(
        id: '4',
        name: 'Beber 2L água',
        iconCode: Icons.water_drop.codePoint,
        colorValue: const Color(0xFF00B4D8).value,
        scheduledTime: null, // Sem horário fixo
        daysOfWeek: [],
        completedDates: [now],
        currentStreak: 1,
        bestStreak: 21,
        createdAt: now.subtract(const Duration(days: 90)),
        order: 3,
      ),
    ];

    for (final habit in sampleHabits) {
      await _box.put(habit.id, habit);
    }
  }

  List<Habit> getAllHabits() {
    final habits = _box.values.toList();
    habits.sort((a, b) => a.order.compareTo(b.order));
    return habits;
  }

  List<Habit> getHabitsForDate(DateTime date) {
    return getAllHabits().where((h) => h.isScheduledFor(date)).toList();
  }

  Future<void> addHabit(Habit habit) async {
    await _box.put(habit.id, habit);
  }

  Future<void> updateHabit(Habit habit) async {
    await _box.put(habit.id, habit);
  }

  Future<void> deleteHabit(String id) async {
    await _box.delete(id);
  }

  Future<void> toggleHabitCompletion(String id, DateTime date) async {
    final habit = _box.get(id);
    if (habit == null) return;

    final dateOnly = DateTime(date.year, date.month, date.day);
    final completedDates = List<DateTime>.from(habit.completedDates);
    
    final existingIndex = completedDates.indexWhere((d) => 
      d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day
    );

    if (existingIndex >= 0) {
      // Remover conclusão
      completedDates.removeAt(existingIndex);
    } else {
      // Adicionar conclusão
      completedDates.add(dateOnly);
    }

    final updatedHabit = habit.copyWith(completedDates: completedDates);
    final newStreak = updatedHabit.calculateCurrentStreak();
    final newBestStreak = newStreak > habit.bestStreak ? newStreak : habit.bestStreak;

    await _box.put(id, updatedHabit.copyWith(
      currentStreak: newStreak,
      bestStreak: newBestStreak,
    ));
  }

  int getCompletedCountForDate(DateTime date) {
    final habits = getHabitsForDate(date);
    return habits.where((h) => h.isCompletedOn(date)).length;
  }

  int getTotalCountForDate(DateTime date) {
    return getHabitsForDate(date).length;
  }

  double getCompletionRateForDate(DateTime date) {
    final total = getTotalCountForDate(date);
    if (total == 0) return 0;
    return getCompletedCountForDate(date) / total;
  }

  // Estatísticas da semana
  Map<int, double> getWeekCompletionRates() {
    final now = DateTime.now();
    final rates = <int, double>{};
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      rates[6 - i] = getCompletionRateForDate(date);
    }
    
    return rates;
  }

  // Box separada para armazenar datas puladas (adiadas)
  static const String _skippedBoxName = 'habits_skipped';
  Box? _skippedBox;

  Future<Box> _ensureSkippedBox() async {
    if (_skippedBox == null || !_skippedBox!.isOpen) {
      _skippedBox = await Hive.openBox(_skippedBoxName);
    }
    return _skippedBox!;
  }

  /// Marca um hábito como pulado/adiado para uma data específica
  Future<void> skipHabitForDate(String habitId, DateTime date) async {
    final box = await _ensureSkippedBox();
    final dateKey = '${habitId}_${date.year}_${date.month}_${date.day}';
    await box.put(dateKey, true);
  }

  /// Remove a marcação de pulado/adiado para uma data
  Future<void> unskipHabitForDate(String habitId, DateTime date) async {
    final box = await _ensureSkippedBox();
    final dateKey = '${habitId}_${date.year}_${date.month}_${date.day}';
    await box.delete(dateKey);
  }

  /// Verifica se um hábito está pulado para uma data específica
  Future<bool> isHabitSkippedForDate(String habitId, DateTime date) async {
    final box = await _ensureSkippedBox();
    final dateKey = '${habitId}_${date.year}_${date.month}_${date.day}';
    return box.get(dateKey) == true;
  }

  /// Retorna hábitos pendentes (não completados e não pulados) para uma data
  Future<List<Habit>> getPendingHabitsForDate(DateTime date) async {
    final habits = getHabitsForDate(date);
    final pendingHabits = <Habit>[];
    
    for (final habit in habits) {
      if (!habit.isCompletedOn(date)) {
        final isSkipped = await isHabitSkippedForDate(habit.id, date);
        if (!isSkipped) {
          pendingHabits.add(habit);
        }
      }
    }
    
    return pendingHabits;
  }
}
