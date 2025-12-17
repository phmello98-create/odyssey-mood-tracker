import 'dart:math' as math;
import '../../data/intelligence_config.dart';
import '../models/user_pattern.dart';

/// Engine para detecção de padrões nos dados do usuário
class PatternEngine {
  /// Detecta padrões temporais nos dados de humor
  List<UserPattern> detectTemporalPatterns({
    required List<MoodDataPoint> moodData,
    required List<ActivityDataPoint> activityData,
    Map<String, String>? activityNames,
  }) {
    final patterns = <UserPattern>[];

    if (moodData.length < IntelligenceConfig.minDataPointsForPattern) {
      return patterns;
    }

    // Padrão: Humor por dia da semana
    final moodByDayOfWeek = _calculateMoodByDayOfWeek(moodData);
    final dayPattern = _detectDayOfWeekPattern(moodByDayOfWeek);
    if (dayPattern != null) patterns.add(dayPattern);

    // Padrão: Humor por hora do dia
    final moodByHour = _calculateMoodByHourOfDay(moodData);
    final hourPattern = _detectHourOfDayPattern(moodByHour);
    if (hourPattern != null) patterns.add(hourPattern);

    // Padrão: Tendência geral (subindo/caindo/estável)
    final trendPattern = _detectMoodTrend(moodData);
    if (trendPattern != null) patterns.add(trendPattern);

    // Padrão: Dias mais produtivos
    final productivityPattern = _detectProductivityPattern(activityData);
    if (productivityPattern != null) patterns.add(productivityPattern);

    // Padrão: Fim de semana vs dias úteis
    final weekendPattern = detectWeekendPattern(moodData);
    if (weekendPattern != null) patterns.add(weekendPattern);

    // Padrão: Volatilidade de humor
    final volatilityPattern = detectMoodVolatility(moodData);
    if (volatilityPattern != null) patterns.add(volatilityPattern);

    // Padrões de atividades (se tiver os nomes)
    if (activityNames != null && activityNames.isNotEmpty) {
      final activityPatterns = detectActivityPatterns(moodData, activityNames);
      patterns.addAll(activityPatterns);
    }

    return patterns;
  }

  /// Calcula média de humor por dia da semana
  Map<int, double> _calculateMoodByDayOfWeek(List<MoodDataPoint> data) {
    final grouped = <int, List<double>>{};

    for (final point in data) {
      final dayOfWeek = point.date.weekday;
      grouped.putIfAbsent(dayOfWeek, () => []).add(point.score);
    }

    return grouped.map((day, scores) =>
        MapEntry(day, scores.reduce((a, b) => a + b) / scores.length));
  }

  /// Calcula média de humor por hora do dia
  Map<int, double> _calculateMoodByHourOfDay(List<MoodDataPoint> data) {
    final grouped = <int, List<double>>{};

    for (final point in data) {
      final hour = point.date.hour;
      // Agrupa em períodos de 4 horas
      final period = (hour ~/ 4) * 4;
      grouped.putIfAbsent(period, () => []).add(point.score);
    }

    return grouped.map((hour, scores) =>
        MapEntry(hour, scores.reduce((a, b) => a + b) / scores.length));
  }

  /// Detecta padrão de dia da semana
  UserPattern? _detectDayOfWeekPattern(Map<int, double> moodByDay) {
    if (moodByDay.length < 5) return null;

    final avgMood =
        moodByDay.values.reduce((a, b) => a + b) / moodByDay.length;
    final stdDev = _calculateStdDev(moodByDay.values.toList(), avgMood);

    // Encontra melhor e pior dia
    int? bestDay;
    int? worstDay;
    double bestScore = 0;
    double worstScore = 5;

    for (final entry in moodByDay.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestDay = entry.key;
      }
      if (entry.value < worstScore) {
        worstScore = entry.value;
        worstDay = entry.key;
      }
    }

    // Só cria padrão se diferença for significativa (> 0.5 desvio padrão)
    if (bestDay != null && (bestScore - avgMood) > stdDev * 0.5) {
      final dayName = _getDayName(bestDay);
      final improvement = ((bestScore - avgMood) / avgMood * 100).toStringAsFixed(0);

      return UserPattern(
        id: 'pattern_day_${DateTime.now().millisecondsSinceEpoch}',
        type: PatternType.temporal,
        description: 'Seu humor é $improvement% melhor às $dayName',
        strength: math.min((bestScore - avgMood) / stdDev, 1.0),
        data: {
          'bestDay': bestDay,
          'bestDayName': dayName,
          'bestScore': bestScore,
          'avgScore': avgMood,
          'worstDay': worstDay,
          'moodByDay': moodByDay,
        },
        firstDetected: DateTime.now(),
        lastConfirmed: DateTime.now(),
      );
    }

    return null;
  }

  /// Detecta padrão de hora do dia
  UserPattern? _detectHourOfDayPattern(Map<int, double> moodByHour) {
    if (moodByHour.length < 3) return null;

    final avgMood =
        moodByHour.values.reduce((a, b) => a + b) / moodByHour.length;

    int? bestPeriod;
    double bestScore = 0;

    for (final entry in moodByHour.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestPeriod = entry.key;
      }
    }

    if (bestPeriod != null && (bestScore - avgMood) > 0.3) {
      final periodName = _getPeriodName(bestPeriod);
      final improvement = ((bestScore - avgMood) / avgMood * 100).toStringAsFixed(0);

      return UserPattern(
        id: 'pattern_hour_${DateTime.now().millisecondsSinceEpoch}',
        type: PatternType.temporal,
        description: 'Você se sente $improvement% melhor $periodName',
        strength: math.min((bestScore - avgMood) / 2, 1.0),
        data: {
          'bestPeriod': bestPeriod,
          'bestPeriodName': periodName,
          'bestScore': bestScore,
          'avgScore': avgMood,
          'moodByHour': moodByHour,
        },
        firstDetected: DateTime.now(),
        lastConfirmed: DateTime.now(),
      );
    }

    return null;
  }

  /// Detecta tendência de humor (subindo, caindo, estável)
  UserPattern? _detectMoodTrend(List<MoodDataPoint> data) {
    if (data.length < 7) return null;

    // Ordena por data
    final sorted = List<MoodDataPoint>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Pega últimos 14 dias
    final recent = sorted.length > 14 ? sorted.sublist(sorted.length - 14) : sorted;

    // Regressão linear simples
    final x = List.generate(recent.length, (i) => i.toDouble());
    final y = recent.map((p) => p.score).toList();

    final result = _linearRegression(x, y);
    final slope = result.$1;

    String trend;
    String description;
    double strength;

    if (slope > 0.05) {
      trend = 'rising';
      description = 'Seu humor está melhorando nas últimas 2 semanas';
      strength = math.min(slope * 10, 1.0);
    } else if (slope < -0.05) {
      trend = 'falling';
      description = 'Seu humor está em queda nas últimas 2 semanas';
      strength = math.min(slope.abs() * 10, 1.0);
    } else {
      trend = 'stable';
      description = 'Seu humor está estável nas últimas 2 semanas';
      strength = 0.5;
    }

    return UserPattern(
      id: 'pattern_trend_${DateTime.now().millisecondsSinceEpoch}',
      type: PatternType.cyclical,
      description: description,
      strength: strength,
      data: {
        'trend': trend,
        'slope': slope,
        'dataPoints': recent.length,
      },
      firstDetected: DateTime.now(),
      lastConfirmed: DateTime.now(),
    );
  }

  /// Detecta padrão de produtividade
  UserPattern? _detectProductivityPattern(List<ActivityDataPoint> data) {
    if (data.length < 10) return null;

    final byHour = <int, int>{};
    for (final point in data) {
      final hour = point.date.hour;
      byHour[hour] = (byHour[hour] ?? 0) + 1;
    }

    if (byHour.isEmpty) return null;

    int bestHour = 0;
    int maxCount = 0;

    for (final entry in byHour.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        bestHour = entry.key;
      }
    }

    final total = data.length;
    final percentage = (maxCount / total * 100).toStringAsFixed(0);

    return UserPattern(
      id: 'pattern_productivity_${DateTime.now().millisecondsSinceEpoch}',
      type: PatternType.behavioral,
      description: 'Você completa $percentage% das atividades às ${bestHour}h',
      strength: maxCount / total,
      data: {
        'bestHour': bestHour,
        'completedAtBestHour': maxCount,
        'totalCompleted': total,
        'byHour': byHour,
      },
      firstDetected: DateTime.now(),
      lastConfirmed: DateTime.now(),
    );
  }

  /// Calcula desvio padrão
  double _calculateStdDev(List<double> values, double mean) {
    if (values.isEmpty) return 0;
    final variance =
        values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    return math.sqrt(variance);
  }

  /// Regressão linear simples
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
    const days = ['', 'segundas', 'terças', 'quartas', 'quintas', 'sextas', 'sábados', 'domingos'];
    return days[day];
  }

  String _getPeriodName(int startHour) {
    if (startHour < 6) return 'de madrugada';
    if (startHour < 12) return 'pela manhã';
    if (startHour < 18) return 'à tarde';
    return 'à noite';
  }

  /// Detecta padrão de variabilidade de humor (estável vs volátil)
  UserPattern? detectMoodVolatility(List<MoodDataPoint> data) {
    if (data.length < 14) return null;

    final scores = data.map((p) => p.score).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final stdDev = _calculateStdDev(scores, mean);

    // Coeficiente de variação (CV = stdDev / mean)
    final cv = stdDev / mean;

    if (cv > 0.25) {
      return UserPattern(
        id: 'pattern_volatility_${DateTime.now().millisecondsSinceEpoch}',
        type: PatternType.behavioral,
        description: 'Seu humor é bastante variável (oscilações frequentes)',
        strength: math.min(cv * 2, 1.0),
        data: {
          'volatility': 'high',
          'cv': cv,
          'stdDev': stdDev,
          'mean': mean,
        },
        firstDetected: DateTime.now(),
        lastConfirmed: DateTime.now(),
      );
    } else if (cv < 0.1) {
      return UserPattern(
        id: 'pattern_stability_${DateTime.now().millisecondsSinceEpoch}',
        type: PatternType.behavioral,
        description: 'Seu humor é bastante estável (poucas variações)',
        strength: 1.0 - cv,
        data: {
          'volatility': 'low',
          'cv': cv,
          'stdDev': stdDev,
          'mean': mean,
        },
        firstDetected: DateTime.now(),
        lastConfirmed: DateTime.now(),
      );
    }

    return null;
  }

  /// Detecta atividades que aparecem frequentemente com bom humor
  List<UserPattern> detectActivityPatterns(
    List<MoodDataPoint> moodData,
    Map<String, String> activityNames,
  ) {
    final patterns = <UserPattern>[];
    if (moodData.length < 14) return patterns;

    // Agrupa scores por atividade
    final scoresByActivity = <String, List<double>>{};
    final scoresWithoutActivity = <String, List<double>>{};

    // Inicializa todas as atividades conhecidas
    for (final name in activityNames.keys) {
      scoresByActivity[name] = [];
      scoresWithoutActivity[name] = [];
    }

    for (final point in moodData) {
      final activitiesInRecord = point.activities.toSet();

      for (final actId in activityNames.keys) {
        if (activitiesInRecord.contains(actId)) {
          scoresByActivity[actId]!.add(point.score);
        } else {
          scoresWithoutActivity[actId]!.add(point.score);
        }
      }
    }

    // Calcula diferença de médias
    for (final actId in activityNames.keys) {
      final withActivity = scoresByActivity[actId]!;
      final withoutActivity = scoresWithoutActivity[actId]!;

      if (withActivity.length < 3 || withoutActivity.length < 3) continue;

      final avgWith = withActivity.reduce((a, b) => a + b) / withActivity.length;
      final avgWithout = withoutActivity.reduce((a, b) => a + b) / withoutActivity.length;
      final difference = avgWith - avgWithout;

      // Só cria padrão se diferença for significativa
      if (difference.abs() > 0.4) {
        final activityName = activityNames[actId] ?? actId;
        final percentDiff = ((difference / avgWithout) * 100).abs().toStringAsFixed(0);

        patterns.add(UserPattern(
          id: 'pattern_activity_${actId}_${DateTime.now().millisecondsSinceEpoch}',
          type: PatternType.correlation,
          description: difference > 0
              ? '$activityName está associado a $percentDiff% melhor humor'
              : '$activityName está associado a humor mais baixo',
          strength: math.min(difference.abs() / 2, 1.0),
          data: {
            'activityId': actId,
            'activityName': activityName,
            'avgWithActivity': avgWith,
            'avgWithoutActivity': avgWithout,
            'difference': difference,
            'samplesWith': withActivity.length,
            'samplesWithout': withoutActivity.length,
          },
          firstDetected: DateTime.now(),
          lastConfirmed: DateTime.now(),
          relatedFeature: actId,
        ));
      }
    }

    // Ordena por força
    patterns.sort((a, b) => b.strength.compareTo(a.strength));
    return patterns.take(5).toList(); // Máximo 5 padrões de atividade
  }

  /// Detecta padrão de fim de semana vs dias úteis
  UserPattern? detectWeekendPattern(List<MoodDataPoint> data) {
    if (data.length < 14) return null;

    final weekdayScores = <double>[];
    final weekendScores = <double>[];

    for (final point in data) {
      if (point.date.weekday >= 6) {
        weekendScores.add(point.score);
      } else {
        weekdayScores.add(point.score);
      }
    }

    if (weekdayScores.length < 5 || weekendScores.length < 2) return null;

    final avgWeekday = weekdayScores.reduce((a, b) => a + b) / weekdayScores.length;
    final avgWeekend = weekendScores.reduce((a, b) => a + b) / weekendScores.length;
    final difference = avgWeekend - avgWeekday;

    if (difference.abs() > 0.3) {
      final percentDiff = ((difference / avgWeekday) * 100).abs().toStringAsFixed(0);
      
      return UserPattern(
        id: 'pattern_weekend_${DateTime.now().millisecondsSinceEpoch}',
        type: PatternType.temporal,
        description: difference > 0
            ? 'Seu humor é $percentDiff% melhor nos fins de semana'
            : 'Seu humor é $percentDiff% pior nos fins de semana',
        strength: math.min(difference.abs() / 1.5, 1.0),
        data: {
          'avgWeekday': avgWeekday,
          'avgWeekend': avgWeekend,
          'difference': difference,
          'weekdaySamples': weekdayScores.length,
          'weekendSamples': weekendScores.length,
        },
        firstDetected: DateTime.now(),
        lastConfirmed: DateTime.now(),
      );
    }

    return null;
  }

  /// Calcula média móvel para suavização de tendências
  List<double> calculateMovingAverage(List<double> data, int window) {
    if (data.length < window) return data;

    final result = <double>[];
    for (int i = window - 1; i < data.length; i++) {
      final windowData = data.sublist(i - window + 1, i + 1);
      result.add(windowData.reduce((a, b) => a + b) / windowData.length);
    }
    return result;
  }
}

/// Ponto de dados de humor
class MoodDataPoint {
  final DateTime date;
  final double score;
  final List<String> activities;

  MoodDataPoint({
    required this.date,
    required this.score,
    this.activities = const [],
  });
}

/// Ponto de dados de atividade
class ActivityDataPoint {
  final DateTime date;
  final String activityId;
  final String activityName;
  final bool completed;

  ActivityDataPoint({
    required this.date,
    required this.activityId,
    required this.activityName,
    this.completed = true,
  });
}
