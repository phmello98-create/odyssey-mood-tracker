import 'dart:math' as math;
import '../models/prediction.dart';
import '../models/user_pattern.dart';
import 'pattern_engine.dart';

/// Engine para fazer previsões sobre comportamento futuro
class PredictionEngine {
  /// Prediz risco de quebra de streak
  Prediction? predictStreakBreak({
    required String habitId,
    required String habitName,
    required int currentStreak,
    required List<bool> last30DaysCompleted,
    required List<UserPattern> patterns,
  }) {
    if (currentStreak < 3) return null;

    // Calcula taxa de conclusão por dia da semana
    final completionByDay = <int, List<bool>>{};
    final now = DateTime.now();

    for (int i = 0; i < last30DaysCompleted.length; i++) {
      final date = now.subtract(Duration(days: last30DaysCompleted.length - 1 - i));
      final dayOfWeek = date.weekday;
      completionByDay.putIfAbsent(dayOfWeek, () => []).add(last30DaysCompleted[i]);
    }

    // Calcula taxa por dia
    final rateByDay = completionByDay.map((day, completions) {
      final completed = completions.where((c) => c).length;
      return MapEntry(day, completed / completions.length);
    });

    // Verifica amanhã
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDay = tomorrow.weekday;
    final tomorrowRate = rateByDay[tomorrowDay] ?? 0.5;

    // Probabilidade de falha
    final failProbability = 1 - tomorrowRate;

    // Só alerta se risco > 30%
    if (failProbability < 0.3) return null;

    // Encontra padrão relevante
    String reasoning = 'Baseado em seu histórico';
    if (tomorrowRate < 0.5) {
      reasoning = 'Você costuma pular às ${_getDayName(tomorrowDay)}';
    }

    // Verifica se há padrão de queda após certo número de dias
    final avgStreakLength = _calculateAverageStreakLength(last30DaysCompleted);
    if (currentStreak >= avgStreakLength * 0.9) {
      reasoning = 'Seus streaks costumam durar ~$avgStreakLength dias';
      // Aumenta probabilidade
    }

    return Prediction(
      id: 'pred_streak_${habitId}_${DateTime.now().millisecondsSinceEpoch}',
      type: PredictionType.streakBreak,
      targetId: habitId,
      targetName: habitName,
      probability: failProbability,
      predictedFor: tomorrow,
      reasoning: reasoning,
      features: {
        'currentStreak': currentStreak,
        'tomorrowRate': tomorrowRate,
        'avgStreakLength': avgStreakLength,
        'rateByDay': rateByDay,
      },
      generatedAt: DateTime.now(),
    );
  }

  /// Prediz humor para amanhã
  Prediction? predictMoodForTomorrow({
    required List<MoodDataPoint> last14Days,
    required List<UserPattern> patterns,
  }) {
    if (last14Days.length < 7) return null;

    // Ordena por data
    final sorted = List<MoodDataPoint>.from(last14Days)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Média dos últimos 7 dias
    final recent = sorted.sublist(math.max(0, sorted.length - 7));
    final avgRecent = recent.map((p) => p.score).reduce((a, b) => a + b) / recent.length;

    // Tendência (regressão linear)
    final x = List.generate(sorted.length, (i) => i.toDouble());
    final y = sorted.map((p) => p.score).toList();
    final trend = _linearRegression(x, y);
    final slope = trend.$1;

    // Predição baseada em tendência
    final predictedScore = avgRecent + slope;

    // Determina tipo
    PredictionType type;
    String reasoning;
    double probability;

    if (slope > 0.1) {
      type = PredictionType.moodImprovement;
      reasoning = 'Seu humor está em tendência de alta';
      probability = math.min(0.5 + slope, 0.9);
    } else if (slope < -0.1) {
      type = PredictionType.moodDrop;
      reasoning = 'Seu humor está em tendência de queda';
      probability = math.min(0.5 + slope.abs(), 0.9);
    } else {
      // Humor estável, verifica padrão de dia da semana
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dayPattern = patterns.firstWhere(
        (p) => p.type == PatternType.temporal && p.data['moodByDay'] != null,
        orElse: () => UserPattern(
          id: '',
          type: PatternType.temporal,
          description: '',
          strength: 0,
          firstDetected: DateTime.now(),
          lastConfirmed: DateTime.now(),
        ),
      );

      if (dayPattern.strength > 0) {
        final moodByDay = dayPattern.data['moodByDay'] as Map<int, double>?;
        final tomorrowMood = moodByDay?[tomorrow.weekday] ?? avgRecent;

        if (tomorrowMood > avgRecent + 0.3) {
          type = PredictionType.moodImprovement;
          reasoning = '${_getDayName(tomorrow.weekday)} costuma ser um bom dia para você';
          probability = 0.6;
        } else if (tomorrowMood < avgRecent - 0.3) {
          type = PredictionType.moodDrop;
          reasoning = '${_getDayName(tomorrow.weekday)} costuma ser um dia mais difícil';
          probability = 0.6;
        } else {
          return null; // Sem previsão significativa
        }
      } else {
        return null;
      }
    }

    return Prediction(
      id: 'pred_mood_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      probability: probability,
      predictedFor: DateTime.now().add(const Duration(days: 1)),
      reasoning: reasoning,
      features: {
        'avgRecent': avgRecent,
        'slope': slope,
        'predictedScore': predictedScore,
      },
      generatedAt: DateTime.now(),
    );
  }

  /// Prediz se dia será produtivo
  Prediction? predictProductiveDay({
    required List<DailyProductivityData> last14Days,
    required List<UserPattern> patterns,
  }) {
    if (last14Days.length < 7) return null;

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowDay = tomorrow.weekday;

    // Calcula produtividade por dia da semana
    final productivityByDay = <int, List<double>>{};

    for (final day in last14Days) {
      final dayOfWeek = day.date.weekday;
      productivityByDay.putIfAbsent(dayOfWeek, () => []).add(day.productivityScore);
    }

    final avgByDay = productivityByDay.map((day, scores) {
      return MapEntry(day, scores.reduce((a, b) => a + b) / scores.length);
    });

    final overallAvg = last14Days
            .map((d) => d.productivityScore)
            .reduce((a, b) => a + b) /
        last14Days.length;

    final tomorrowExpected = avgByDay[tomorrowDay] ?? overallAvg;

    if (tomorrowExpected > overallAvg * 1.2) {
      return Prediction(
        id: 'pred_prod_${DateTime.now().millisecondsSinceEpoch}',
        type: PredictionType.productiveDay,
        probability: math.min(tomorrowExpected / 10, 0.9),
        predictedFor: tomorrow,
        reasoning:
            '${_getDayName(tomorrowDay)} costuma ser um dia produtivo para você',
        features: {
          'expectedScore': tomorrowExpected,
          'avgScore': overallAvg,
          'avgByDay': avgByDay,
        },
        generatedAt: DateTime.now(),
      );
    }

    return null;
  }

  /// Calcula duração média de streaks
  int _calculateAverageStreakLength(List<bool> completions) {
    final streaks = <int>[];
    int currentStreak = 0;

    for (final completed in completions) {
      if (completed) {
        currentStreak++;
      } else {
        if (currentStreak > 0) {
          streaks.add(currentStreak);
        }
        currentStreak = 0;
      }
    }

    if (currentStreak > 0) {
      streaks.add(currentStreak);
    }

    if (streaks.isEmpty) return 0;
    return (streaks.reduce((a, b) => a + b) / streaks.length).round();
  }

  /// Regressão linear
  (double, double) _linearRegression(List<double> x, List<double> y) {
    final n = x.length;
    if (n == 0) return (0, 0);

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY =
        List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return (0, sumY / n);

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    return (slope, intercept);
  }

  String _getDayName(int day) {
    const days = [
      '',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    return days[day];
  }

  /// Prediz melhor horário para fazer uma atividade
  Map<String, dynamic>? predictBestTimeForActivity({
    required String activityId,
    required String activityName,
    required List<MoodDataPoint> moodData,
  }) {
    if (moodData.length < 14) return null;

    // Agrupa por hora quando a atividade foi feita
    final moodByHourWithActivity = <int, List<double>>{};
    
    for (final point in moodData) {
      if (point.activities.contains(activityId)) {
        final hour = point.date.hour;
        moodByHourWithActivity.putIfAbsent(hour, () => []).add(point.score);
      }
    }

    if (moodByHourWithActivity.length < 3) return null;

    // Encontra melhor horário
    int bestHour = 0;
    double bestAvg = 0;

    for (final entry in moodByHourWithActivity.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestHour = entry.key;
      }
    }

    return {
      'activityId': activityId,
      'activityName': activityName,
      'bestHour': bestHour,
      'bestHourFormatted': '${bestHour.toString().padLeft(2, '0')}:00',
      'avgMoodAtBestHour': bestAvg,
      'confidence': math.min(moodByHourWithActivity[bestHour]!.length / 5, 1.0),
    };
  }

  /// Calcula probabilidade de sucesso de um hábito com base em múltiplos fatores
  double calculateHabitSuccessProbability({
    required List<bool> last30Days,
    required int dayOfWeek,
    required int currentStreak,
  }) {
    // Fator 1: Taxa geral de conclusão
    final overallRate = last30Days.isEmpty
        ? 0.5
        : last30Days.where((c) => c).length / last30Days.length;

    // Fator 2: Taxa no dia da semana específico
    final now = DateTime.now();
    final dayRates = <bool>[];
    for (int i = 0; i < last30Days.length; i++) {
      final date = now.subtract(Duration(days: 29 - i));
      if (date.weekday == dayOfWeek) {
        dayRates.add(last30Days[i]);
      }
    }
    final dayRate = dayRates.isEmpty
        ? overallRate
        : dayRates.where((c) => c).length / dayRates.length;

    // Fator 3: Momentum do streak (streaks maiores têm mais inércia)
    final streakBonus = math.min(currentStreak * 0.02, 0.2); // Máx 20% bonus

    // Fator 4: Recência (últimos 7 dias pesam mais)
    final recent7 = last30Days.length >= 7
        ? last30Days.sublist(last30Days.length - 7)
        : last30Days;
    final recentRate = recent7.isEmpty
        ? overallRate
        : recent7.where((c) => c).length / recent7.length;

    // Combina fatores com pesos
    final probability = (overallRate * 0.2) +
        (dayRate * 0.3) +
        (recentRate * 0.4) +
        streakBonus +
        0.1; // Base 10%

    return probability.clamp(0.0, 1.0);
  }

  /// Prediz quais hábitos têm mais chance de serem completados hoje
  List<Map<String, dynamic>> rankHabitsByProbability({
    required Map<String, HabitPredictionData> habitsData,
  }) {
    final rankings = <Map<String, dynamic>>[];
    final today = DateTime.now().weekday;

    for (final entry in habitsData.entries) {
      final prob = calculateHabitSuccessProbability(
        last30Days: entry.value.last30Days,
        dayOfWeek: today,
        currentStreak: entry.value.currentStreak,
      );

      rankings.add({
        'habitId': entry.key,
        'habitName': entry.value.name,
        'probability': prob,
        'currentStreak': entry.value.currentStreak,
        'category': prob >= 0.7 ? 'likely' : (prob >= 0.4 ? 'moderate' : 'at_risk'),
      });
    }

    // Ordena por probabilidade decrescente
    rankings.sort((a, b) => 
        (b['probability'] as double).compareTo(a['probability'] as double));

    return rankings;
  }
}

/// Dados de hábito para previsão
class HabitPredictionData {
  final String id;
  final String name;
  final int currentStreak;
  final List<bool> last30Days;

  HabitPredictionData({
    required this.id,
    required this.name,
    required this.currentStreak,
    required this.last30Days,
  });
}

/// Dados de produtividade diária
class DailyProductivityData {
  final DateTime date;
  final double productivityScore; // 0-10
  final int tasksCompleted;
  final int habitsCompleted;
  final Duration focusTime;

  DailyProductivityData({
    required this.date,
    required this.productivityScore,
    this.tasksCompleted = 0,
    this.habitsCompleted = 0,
    this.focusTime = Duration.zero,
  });
}
