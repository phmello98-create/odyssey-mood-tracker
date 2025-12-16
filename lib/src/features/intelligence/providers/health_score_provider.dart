import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/engines/health_score_engine.dart';
import '../../mood_records/data/mood_log/mood_record_repository.dart';
import '../../habits/data/habit_repository.dart';
import '../../tasks/data/task_repository.dart';

/// Provider que calcula o Health Score com dados reais
final healthScoreProvider = FutureProvider.autoDispose<HealthReport?>((ref) async {
  try {
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final habitRepo = ref.watch(habitRepositoryProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);

    // Coleta dados
    final moodRecordsMap = moodRepo.fetchMoodRecords();
    final moodRecords = moodRecordsMap.values.toList();

    await habitRepo.init();
    final habits = habitRepo.getAllHabits();

    await taskRepo.init();
    final tasks = await taskRepo.getAllTasks();

    // Verifica se tem dados suficientes
    if (moodRecords.isEmpty) {
      return null;
    }

    // Converte para formato do engine
    final moodInputs = moodRecords.map((r) => MoodInput(
      date: r.date,
      score: r.score.toDouble(),
      activities: r.activities.map((a) => a.activityName).toList(),
    )).toList();

    final habitInputs = habits.map((h) => HabitInput(
      id: h.id,
      name: h.name,
      completionCount: h.completedDates.length,
      currentStreak: h.currentStreak,
    )).toList();

    final taskInputs = tasks.map((t) => TaskInput(
      id: t.key.toString(),
      isCompleted: t.completed,
      createdAt: t.createdAt,
      completedAt: t.completedAt,
    )).toList();

    // Calcula Health Score
    final engine = HealthScoreEngine();
    final report = engine.analyze(
      moodRecords: moodInputs,
      habits: habitInputs,
      tasks: taskInputs,
      expectedDays: 30,
    );

    return report;
  } catch (e) {
    return null;
  }
});

/// Provider simples para verificar se tem dados suficientes
final hasEnoughDataProvider = Provider<bool>((ref) {
  final healthScore = ref.watch(healthScoreProvider);
  return healthScore.maybeWhen(
    data: (report) => report != null && report.overallScore > 0,
    orElse: () => false,
  );
});
