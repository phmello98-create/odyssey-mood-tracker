import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/engines/advanced_analysis_engine.dart';
import '../domain/engines/prediction_engine.dart';
import '../domain/engines/pattern_engine.dart';
import '../domain/engines/health_score_engine.dart';
import 'intelligence_service.dart';
import '../../mood_records/data/mood_log/mood_record_repository.dart';
import '../../habits/data/habit_repository.dart';
import '../../../utils/services/modern_notification_service.dart';

/// Tipos de notificação inteligente
enum SmartNotificationType {
  streakRisk,        // Risco de quebra de streak
  moodDrop,          // Previsão de queda de humor
  anomalyDetected,   // Dia atípico detectado
  achievementUnlock, // Conquista desbloqueada
  habitReminder,     // Lembrete de hábito em risco
  weeklyReport,      // Resumo semanal
  bestTimeReminder,  // Melhor horário para atividade
}

/// Notificação inteligente gerada pelo sistema
class SmartNotification {
  final String id;
  final SmartNotificationType type;
  final String title;
  final String body;
  final String? actionRoute;
  final Map<String, dynamic>? data;
  final DateTime scheduledFor;
  final double priority; // 0-1

  SmartNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.actionRoute,
    this.data,
    required this.scheduledFor,
    this.priority = 0.5,
  });
}

/// Serviço de notificações inteligentes
class SmartNotificationService {
  final AdvancedAnalysisEngine _advancedEngine = AdvancedAnalysisEngine();
  final PredictionEngine _predictionEngine = PredictionEngine();
  
  /// Gera notificações baseadas na análise dos dados
  Future<List<SmartNotification>> generateSmartNotifications({
    required List<MoodDataPoint> moodData,
    required Map<String, HabitData> habitsData,
    required HealthReport? healthReport,
  }) async {
    final notifications = <SmartNotification>[];
    final now = DateTime.now();

    // 1. Verificar risco de quebra de streak
    for (final entry in habitsData.entries) {
      final prediction = _predictionEngine.predictStreakBreak(
        habitId: entry.key,
        habitName: entry.value.name,
        last30DaysCompleted: entry.value.last30Days,
        currentStreak: entry.value.currentStreak,
        patterns: [],  // Patterns vazios por padrão
      );

      if (prediction != null && prediction.probability >= 0.5) {
        // Calcula dias até risco baseado na probabilidade
        final daysUntilRisk = prediction.probability > 0.7 ? 1 : 2;
        notifications.add(SmartNotification(
          id: 'streak_risk_${entry.key}_${now.day}',
          type: SmartNotificationType.streakRisk,
          title: '🔥 Streak em risco!',
          body: '${entry.value.name}: $daysUntilRisk dia(s) para manter. Não deixe escapar!',
          scheduledFor: _getBestReminderTime(now),
          priority: 0.8,
          actionRoute: '/habits',
          data: {
            'habitId': entry.key,
            'streak': entry.value.currentStreak,
            'probability': prediction.probability,
          },
        ));
      }
    }

    // 2. Detectar anomalias e sugerir investigação
    if (moodData.length >= 14) {
      final anomalies = _advancedEngine.detectAnomalies(
        moodData: moodData,
        sensitivity: 1.8,
      );

      // Anomalias negativas recentes
      final recentNegative = anomalies
          .where((a) => 
            a.direction == AnomalyDirection.low &&
            now.difference(a.date).inDays <= 2)
          .toList();

      if (recentNegative.isNotEmpty) {
        notifications.add(SmartNotification(
          id: 'anomaly_${now.day}',
          type: SmartNotificationType.anomalyDetected,
          title: '⚠️ Dia difícil detectado',
          body: 'Notamos uma queda no seu humor. Quer registrar o que aconteceu?',
          scheduledFor: now.add(const Duration(hours: 2)),
          priority: 0.6,
          actionRoute: '/mood/add',
        ));
      }
    }

    // 3. Previsão de humor para amanhã
    if (moodData.length >= 14) {
      final predictions = _advancedEngine.predictNextDays(
        moodData: moodData,
        daysAhead: 1,
      );

      if (predictions.isNotEmpty) {
        final tomorrow = predictions.first;
        
        // Se previsão for baixa, notificar
        if (tomorrow.predictedScore < 3.0) {
          notifications.add(SmartNotification(
            id: 'mood_prediction_${now.day}',
            type: SmartNotificationType.moodDrop,
            title: '📊 Previsão para amanhã',
            body: 'Baseado nos padrões, amanhã pode ser desafiador. Que tal planejar algo bom?',
            scheduledFor: _getEveningTime(now),
            priority: 0.5,
            actionRoute: '/intelligence',
            data: {
              'predictedScore': tomorrow.predictedScore,
              'confidence': tomorrow.confidence,
            },
          ));
        }
      }
    }

    // 4. Resumo semanal (domingo à noite)
    if (now.weekday == 7 && healthReport != null) {
      notifications.add(SmartNotification(
        id: 'weekly_report_${now.day}',
        type: SmartNotificationType.weeklyReport,
        title: '📈 Seu resumo semanal',
        body: 'Health Score: ${healthReport.overallScore.toStringAsFixed(0)}. Veja o que funcionou!',
        scheduledFor: _getSundayEveningTime(now),
        priority: 0.7,
        actionRoute: '/health-score',
        data: {
          'score': healthReport.overallScore,
          'trend': healthReport.trend.toString(),
        },
      ));
    }

    // 5. Conquista desbloqueada (streaks de 7, 14, 30 dias)
    for (final entry in habitsData.entries) {
      final streak = entry.value.currentStreak;
      if (streak == 7 || streak == 14 || streak == 30 || streak == 60) {
        notifications.add(SmartNotification(
          id: 'achievement_${entry.key}_$streak',
          type: SmartNotificationType.achievementUnlock,
          title: '🏆 Conquista Desbloqueada!',
          body: '$streak dias consecutivos de ${entry.value.name}! Incrível!',
          scheduledFor: now,
          priority: 0.9,
          actionRoute: '/habits',
          data: {
            'habitId': entry.key,
            'streakMilestone': streak,
          },
        ));
      }
    }

    // Ordena por prioridade
    notifications.sort((a, b) => b.priority.compareTo(a.priority));

    return notifications;
  }

  /// Agenda as notificações geradas
  Future<void> scheduleSmartNotifications(List<SmartNotification> notifications) async {
    for (final notification in notifications.take(5)) { // Máximo 5 por dia
      try {
        // Usa o serviço de notificações existente baseado no tipo
        switch (notification.type) {
          case SmartNotificationType.streakRisk:
          case SmartNotificationType.habitReminder:
            await ModernNotificationService.instance.sendHabitReminder(
              habitId: notification.id.hashCode,
              habitName: notification.title,
              habitDescription: notification.body,
              scheduledDate: notification.scheduledFor,
            );
            break;
          case SmartNotificationType.moodDrop:
          case SmartNotificationType.anomalyDetected:
            await ModernNotificationService.instance.sendMoodReminder(
              title: notification.title,
              body: notification.body,
              scheduledDate: notification.scheduledFor,
            );
            break;
          case SmartNotificationType.achievementUnlock:
            await ModernNotificationService.instance.sendAchievementUnlocked(
              achievementName: notification.title,
              achievementDescription: notification.body,
            );
            break;
          case SmartNotificationType.weeklyReport:
          case SmartNotificationType.bestTimeReminder:
            await ModernNotificationService.instance.sendMotivationalNotification(
              title: notification.title,
              body: notification.body,
            );
            break;
        }
        
        debugPrint('📱 Notificação agendada: ${notification.title}');
      } catch (e) {
        debugPrint('❌ Erro ao agendar notificação: $e');
      }
    }
  }

  /// Retorna o melhor horário para lembrete (manhã)
  DateTime _getBestReminderTime(DateTime now) {
    var time = DateTime(now.year, now.month, now.day, 8, 30);
    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }
    return time;
  }

  /// Retorna horário da noite
  DateTime _getEveningTime(DateTime now) {
    var time = DateTime(now.year, now.month, now.day, 20, 0);
    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }
    return time;
  }

  /// Retorna domingo à noite
  DateTime _getSundayEveningTime(DateTime now) {
    return DateTime(now.year, now.month, now.day, 19, 0);
  }
}

/// Provider do serviço de notificações inteligentes
final smartNotificationServiceProvider = Provider<SmartNotificationService>((ref) {
  return SmartNotificationService();
});

/// Provider que gera e agenda notificações automaticamente
final smartNotificationsProvider = FutureProvider.autoDispose<List<SmartNotification>>((ref) async {
  try {
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final habitRepo = ref.watch(habitRepositoryProvider);

    // Coleta dados
    final moodRecordsMap = moodRepo.fetchMoodRecords();
    final moodRecords = moodRecordsMap.values.toList();

    await habitRepo.init();
    final habits = habitRepo.getAllHabits();

    // Converte para formato dos engines
    final moodData = moodRecords.map((r) => MoodDataPoint(
      date: r.date,
      score: r.score.toDouble(),
      activities: r.activities.map((a) => a.activityName).toList(),
    )).toList();

    final habitsData = <String, HabitData>{};
    for (final habit in habits) {
      final now = DateTime.now();
      final last30Days = <bool>[];
      
      for (int i = 29; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        final completed = habit.completedDates.any((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        last30Days.add(completed);
      }

      habitsData[habit.id] = HabitData(
        id: habit.id,
        name: habit.name,
        currentStreak: habit.currentStreak,
        last30Days: last30Days,
      );
    }

    final service = ref.read(smartNotificationServiceProvider);
    final notifications = await service.generateSmartNotifications(
      moodData: moodData,
      habitsData: habitsData,
      healthReport: null, // Pode conectar ao healthScoreProvider
    );

    return notifications;
  } catch (e) {
    debugPrint('Erro ao gerar notificações: $e');
    return [];
  }
});
