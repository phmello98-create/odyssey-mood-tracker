import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mood_records/domain/mood_log/mood_record.dart';
import '../../mood_records/data/mood_log/mood_record_repository.dart';
import '../../habits/domain/habit.dart';
import '../../habits/data/habit_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../../time_tracker/domain/time_tracking_record.dart';
import '../../time_tracker/data/time_tracking_repository.dart';
import '../domain/engines/pattern_engine.dart';
import '../domain/engines/correlation_engine.dart';
import '../domain/engines/prediction_engine.dart';
import '../services/intelligence_service.dart';

/// Adapter para converter dados do app em formato do sistema de inteligência
class IntelligenceDataAdapter {
  /// Converte MoodRecords para MoodDataPoints
  static List<MoodDataPoint> convertMoodRecords(List<MoodRecord> records) {
    return records.map((r) => MoodDataPoint(
      date: r.date,
      score: r.score.toDouble(),
      activities: r.activities.map((a) => a.activityName).toList(),
    )).toList();
  }

  /// Converte MoodRecords para MoodTimePoints
  static List<MoodTimePoint> convertToMoodTimePoints(List<MoodRecord> records) {
    return records.map((r) => MoodTimePoint(
      hour: r.date.hour,
      score: r.score.toDouble(),
      date: r.date,
    )).toList();
  }

  /// Converte atividades completadas para ActivityDataPoints
  static List<ActivityDataPoint> convertActivities(List<MoodRecord> records) {
    final points = <ActivityDataPoint>[];

    for (final record in records) {
      for (final activity in record.activities) {
        points.add(ActivityDataPoint(
          date: record.date,
          activityId: activity.activityName,
          activityName: activity.activityName,
          completed: true,
        ));
      }
    }

    return points;
  }

  /// Agrega dados diários
  static List<DailyDataPoint> aggregateDailyData({
    required List<MoodRecord> moodRecords,
    required List<TaskData> tasks,
    required List<Habit> habits,
    required List<TimeTrackingRecord> timeEntries,
    int days = 30,
  }) {
    final dailyData = <DailyDataPoint>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = date.add(const Duration(days: 1));

      // Moods do dia
      final dayMoods = moodRecords.where((m) =>
          m.date.isAfter(date) && m.date.isBefore(nextDate));

      final avgMood = dayMoods.isEmpty
          ? 0.0
          : dayMoods.map((m) => m.score).reduce((a, b) => a + b) / dayMoods.length;

      // Tarefas completas do dia
      final tasksCompleted = tasks.where((t) =>
          t.completed &&
          t.completedAt != null &&
          t.completedAt!.isAfter(date) &&
          t.completedAt!.isBefore(nextDate)).length;

      // Hábitos completos do dia
      final habitsCompleted = habits.where((h) {
        final completions = h.completedDates;
        return completions.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
      }).length;

      // Atividades do dia
      final activitiesDone = <String>{};
      for (final mood in dayMoods) {
        for (final activity in mood.activities) {
          activitiesDone.add(activity.activityName);
        }
      }

      // Tempo rastreado
      final dayTimeEntries = timeEntries.where((e) =>
          e.startTime.isAfter(date) && e.startTime.isBefore(nextDate));
      final timeTracked = dayTimeEntries.fold<Duration>(
        Duration.zero,
        (sum, e) => sum + e.duration,
      );

      if (avgMood > 0 || tasksCompleted > 0 || habitsCompleted > 0) {
        dailyData.add(DailyDataPoint(
          date: date,
          avgMood: avgMood,
          tasksCompleted: tasksCompleted,
          habitsCompleted: habitsCompleted,
          activitiesDone: activitiesDone.toList(),
          timeTracked: timeTracked,
        ));
      }
    }

    return dailyData;
  }

  /// Converte hábitos para HabitData (para previsões)
  static Map<String, HabitData> convertHabits(List<Habit> habits) {
    final result = <String, HabitData>{};

    for (final habit in habits) {
      final completedDates = habit.completedDates;
      final now = DateTime.now();

      // Últimos 30 dias
      final last30Days = <bool>[];
      for (int i = 29; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        final completed = completedDates.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        last30Days.add(completed);
      }

      // Calcula streak atual
      int streak = 0;
      for (int i = last30Days.length - 1; i >= 0; i--) {
        if (last30Days[i]) {
          streak++;
        } else {
          break;
        }
      }

      result[habit.id] = HabitData(
        id: habit.id,
        name: habit.name,
        currentStreak: streak,
        last30Days: last30Days,
      );
    }

    return result;
  }

  /// Extrai nomes de atividades dos MoodRecords
  static Map<String, String> extractActivityNames(List<MoodRecord> records) {
    final names = <String, String>{};

    for (final record in records) {
      for (final activity in record.activities) {
        names[activity.activityName] = activity.activityName;
      }
    }

    return names;
  }

  /// Dados de produtividade diária
  static List<DailyProductivityData> calculateProductivity({
    required List<TaskData> tasks,
    required List<Habit> habits,
    required List<TimeTrackingRecord> timeEntries,
    int days = 14,
  }) {
    final data = <DailyProductivityData>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = date.add(const Duration(days: 1));

      // Tarefas completas
      final tasksCompleted = tasks.where((t) =>
          t.completed &&
          t.completedAt != null &&
          t.completedAt!.isAfter(date) &&
          t.completedAt!.isBefore(nextDate)).length;

      // Hábitos completos
      final habitsCompleted = habits.where((h) {
        final completions = h.completedDates;
        return completions.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
      }).length;

      // Tempo focado
      final dayTimeEntries = timeEntries.where((e) =>
          e.startTime.isAfter(date) && e.startTime.isBefore(nextDate));
      final focusTime = dayTimeEntries.fold<Duration>(
        Duration.zero,
        (sum, e) => sum + e.duration,
      );

      // Score de produtividade (0-10)
      final score = _calculateProductivityScore(
        tasksCompleted: tasksCompleted,
        habitsCompleted: habitsCompleted,
        focusMinutes: focusTime.inMinutes,
      );

      data.add(DailyProductivityData(
        date: date,
        productivityScore: score,
        tasksCompleted: tasksCompleted,
        habitsCompleted: habitsCompleted,
        focusTime: focusTime,
      ));
    }

    return data;
  }

  static double _calculateProductivityScore({
    required int tasksCompleted,
    required int habitsCompleted,
    required int focusMinutes,
  }) {
    // Pesos
    const taskWeight = 1.5;
    const habitWeight = 2.0;
    const focusWeight = 0.02; // por minuto

    final score = (tasksCompleted * taskWeight) +
        (habitsCompleted * habitWeight) +
        (focusMinutes * focusWeight);

    // Normaliza para 0-10
    return (score / 2).clamp(0.0, 10.0);
  }
}

/// Provider que prepara dados para análise
final intelligenceDataProvider = FutureProvider.autoDispose<IntelligenceAnalysisData?>((ref) async {
  try {
    // Busca dados dos repositórios
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final habitRepo = ref.watch(habitRepositoryProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);
    final timeRepo = ref.watch(timeTrackingRepositoryProvider);

    // Coleta dados
    final moodRecordsMap = moodRepo.fetchMoodRecords();
    final moodRecords = moodRecordsMap.values.toList();
    
    await habitRepo.init();
    final habits = habitRepo.getAllHabits();
    
    await taskRepo.init();
    final tasks = await taskRepo.getAllTasks();
    
    final timeEntries = timeRepo.fetchAllTimeTrackingRecords();

    // Converte para formato do sistema de inteligência
    final moodData = IntelligenceDataAdapter.convertMoodRecords(moodRecords);
    final activityData = IntelligenceDataAdapter.convertActivities(moodRecords);
    final moodTimeData = IntelligenceDataAdapter.convertToMoodTimePoints(moodRecords);
    final dailyData = IntelligenceDataAdapter.aggregateDailyData(
      moodRecords: moodRecords,
      tasks: tasks,
      habits: habits,
      timeEntries: timeEntries,
    );
    final activityNames = IntelligenceDataAdapter.extractActivityNames(moodRecords);
    final habitsData = IntelligenceDataAdapter.convertHabits(habits);
    final productivityData = IntelligenceDataAdapter.calculateProductivity(
      tasks: tasks,
      habits: habits,
      timeEntries: timeEntries,
    );

    return IntelligenceAnalysisData(
      moodData: moodData,
      activityData: activityData,
      dailyData: dailyData,
      moodTimeData: moodTimeData,
      activityNames: activityNames,
      habitsData: habitsData,
      productivityData: productivityData,
    );
  } catch (e) {
    // Retorna null se houver erro na inicialização
    return null;
  }
});

/// Dados preparados para análise
class IntelligenceAnalysisData {
  final List<MoodDataPoint> moodData;
  final List<ActivityDataPoint> activityData;
  final List<DailyDataPoint> dailyData;
  final List<MoodTimePoint> moodTimeData;
  final Map<String, String> activityNames;
  final Map<String, HabitData> habitsData;
  final List<DailyProductivityData> productivityData;

  IntelligenceAnalysisData({
    required this.moodData,
    required this.activityData,
    required this.dailyData,
    required this.moodTimeData,
    required this.activityNames,
    required this.habitsData,
    required this.productivityData,
  });

  bool get hasEnoughData => moodData.length >= 7;
}
