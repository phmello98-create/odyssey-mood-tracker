import 'package:hive_flutter/hive_flutter.dart';

part 'habit.g.dart';

@HiveType(typeId: 10)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int iconCode;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final String? scheduledTime; // "06:30" ou null se sem horário

  @HiveField(5)
  final List<int> daysOfWeek; // 1=Seg, 2=Ter... 7=Dom. Vazio = todos os dias

  @HiveField(6)
  final List<DateTime> completedDates;

  @HiveField(7)
  final int currentStreak;

  @HiveField(8)
  final int bestStreak;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final int order; // Para ordenação manual

  Habit({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.scheduledTime,
    this.daysOfWeek = const [],
    this.completedDates = const [],
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.createdAt,
    this.order = 0,
  });

  Habit copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    String? scheduledTime,
    List<int>? daysOfWeek,
    List<DateTime>? completedDates,
    int? currentStreak,
    int? bestStreak,
    DateTime? createdAt,
    int? order,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      completedDates: completedDates ?? this.completedDates,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.any((d) => 
      d.year == date.year && d.month == date.month && d.day == date.day
    );
  }

  bool isScheduledFor(DateTime date) {
    if (daysOfWeek.isEmpty) return true; // Todos os dias
    final weekday = date.weekday; // 1=Mon, 7=Sun
    return daysOfWeek.contains(weekday);
  }

  // Calcula streak atual baseado nas datas completadas
  int calculateCurrentStreak() {
    if (completedDates.isEmpty) return 0;
    
    final sorted = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    // Verifica se completou hoje ou ontem
    final lastCompleted = sorted.first;
    final lastCompletedDate = DateTime(lastCompleted.year, lastCompleted.month, lastCompleted.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
    
    if (lastCompletedDate != todayDate && lastCompletedDate != yesterdayDate) {
      return 0; // Streak quebrado
    }
    
    int streak = 1;
    DateTime checkDate = lastCompletedDate;
    
    for (int i = 1; i < sorted.length; i++) {
      final prevDate = DateTime(sorted[i].year, sorted[i].month, sorted[i].day);
      final expectedDate = checkDate.subtract(const Duration(days: 1));
      
      if (prevDate == expectedDate) {
        streak++;
        checkDate = prevDate;
      } else {
        break;
      }
    }
    
    return streak;
  }
}
