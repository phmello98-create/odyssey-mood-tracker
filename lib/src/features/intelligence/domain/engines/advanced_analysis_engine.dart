import 'dart:math' as math;
import 'pattern_engine.dart';

/// Engine de análise avançada com algoritmos turbo
class AdvancedAnalysisEngine {
  /// Detecta anomalias usando Z-Score
  List<MoodAnomaly> detectAnomalies({
    required List<MoodDataPoint> moodData,
    double sensitivity = 2.0,
  }) {
    if (moodData.length < 7) return [];

    final scores = moodData.map((m) => m.score).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final stdDev = _calculateStdDev(scores, mean);

    if (stdDev == 0) return [];

    final anomalies = <MoodAnomaly>[];

    for (final record in moodData) {
      final z = (record.score - mean) / stdDev;

      if (z.abs() >= sensitivity) {
        anomalies.add(MoodAnomaly(
          date: record.date,
          score: record.score,
          expectedScore: mean,
          zScore: z,
          direction: z > 0 ? AnomalyDirection.high : AnomalyDirection.low,
          activities: record.activities,
        ));
      }
    }

    return anomalies;
  }

  /// Analisa causas de anomalias
  AnomalyCauses analyzeAnomalyCauses({
    required List<MoodAnomaly> anomalies,
    required List<MoodDataPoint> allRecords,
  }) {
    final positiveActivities = <String, int>{};
    final negativeActivities = <String, int>{};

    // Conta atividades em anomalias
    for (final anomaly in anomalies) {
      for (final activity in anomaly.activities) {
        if (anomaly.direction == AnomalyDirection.high) {
          positiveActivities[activity] = (positiveActivities[activity] ?? 0) + 1;
        } else {
          negativeActivities[activity] = (negativeActivities[activity] ?? 0) + 1;
        }
      }
    }

    // Frequência base de cada atividade
    final activityFreq = <String, int>{};
    for (final record in allRecords) {
      for (final act in record.activities) {
        activityFreq[act] = (activityFreq[act] ?? 0) + 1;
      }
    }

    // Calcula lift
    final totalRecords = allRecords.length;
    final totalPositive = anomalies.where((a) => a.direction == AnomalyDirection.high).length;
    final totalNegative = anomalies.where((a) => a.direction == AnomalyDirection.low).length;

    final positiveLift = <String, double>{};
    final negativeLift = <String, double>{};

    for (final entry in activityFreq.entries) {
      final baseRate = entry.value / totalRecords;

      if (totalPositive > 0 && positiveActivities.containsKey(entry.key)) {
        final anomalyRate = positiveActivities[entry.key]! / totalPositive;
        positiveLift[entry.key] = baseRate > 0 ? anomalyRate / baseRate : 0;
      }

      if (totalNegative > 0 && negativeActivities.containsKey(entry.key)) {
        final anomalyRate = negativeActivities[entry.key]! / totalNegative;
        negativeLift[entry.key] = baseRate > 0 ? anomalyRate / baseRate : 0;
      }
    }

    return AnomalyCauses(
      positiveFactors: _sortedByValue(positiveLift, 5),
      negativeFactors: _sortedByValue(negativeLift, 5),
    );
  }

  /// Detecta volatilidade de humor
  MoodVolatility detectVolatility(List<MoodDataPoint> moodData) {
    if (moodData.length < 14) {
      return MoodVolatility(
        status: VolatilityStatus.insufficientData,
        cv: 0,
        stdDev: 0,
        mean: 0,
      );
    }

    final scores = moodData.map((m) => m.score).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final stdDev = _calculateStdDev(scores, mean);
    final cv = mean > 0 ? stdDev / mean : 0;

    VolatilityStatus status;
    if (cv > 0.25) {
      status = VolatilityStatus.high;
    } else if (cv < 0.1) {
      status = VolatilityStatus.low;
    } else {
      status = VolatilityStatus.normal;
    }

    return MoodVolatility(
      status: status,
      cv: cv.toDouble(),
      stdDev: stdDev.toDouble(),
      mean: mean.toDouble(),
    );
  }

  /// Calcula Média Móvel Exponencial (EMA)
  List<double> exponentialMovingAverage(
    List<double> values, {
    double alpha = 0.3,
  }) {
    if (values.isEmpty) return [];

    final ema = <double>[values[0]];
    for (int i = 1; i < values.length; i++) {
      ema.add(alpha * values[i] + (1 - alpha) * ema[i - 1]);
    }
    return ema;
  }

  /// Detecta sazonalidade semanal
  Map<int, double> detectWeeklySeasonality(List<MoodDataPoint> moodData) {
    final byWeekday = <int, List<double>>{};

    for (final record in moodData) {
      final weekday = record.date.weekday;
      byWeekday.putIfAbsent(weekday, () => []).add(record.score);
    }

    // Média por dia da semana
    final avgByDay = <int, double>{};
    for (final entry in byWeekday.entries) {
      avgByDay[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    // Desvio da média geral
    final overallAvg = moodData.map((m) => m.score).reduce((a, b) => a + b) / moodData.length;
    return avgByDay.map((day, avg) => MapEntry(day, avg - overallAvg));
  }

  /// Previsão avançada para próximos dias
  List<MoodPrediction> predictNextDays({
    required List<MoodDataPoint> moodData,
    int daysAhead = 7,
    double alpha = 0.3,
  }) {
    if (moodData.length < 14) return [];

    final sortedData = List<MoodDataPoint>.from(moodData)
      ..sort((a, b) => a.date.compareTo(b.date));
    final scores = sortedData.map((m) => m.score).toList();

    // Calcula EMA
    final ema = exponentialMovingAverage(scores, alpha: alpha);
    final currentEma = ema.last;

    // Calcula tendência (slope dos últimos 7 dias)
    final recent = scores.length > 7 ? scores.sublist(scores.length - 7) : scores;
    final x = List.generate(recent.length, (i) => i.toDouble());
    final slope = _linearSlope(x, recent);

    // Detecta sazonalidade
    final seasonality = detectWeeklySeasonality(sortedData);

    // Gera previsões
    final predictions = <MoodPrediction>[];
    final lastDate = sortedData.last.date;

    for (int i = 1; i <= daysAhead; i++) {
      final predDate = lastDate.add(Duration(days: i));
      final weekday = predDate.weekday;

      // Base: EMA + tendência + sazonalidade
      var prediction = currentEma + (slope * i);
      prediction += seasonality[weekday] ?? 0;
      prediction = prediction.clamp(1.0, 5.0);

      // Confiança diminui com distância
      final confidence = math.max(0.3, 1 - (i * 0.1));

      predictions.add(MoodPrediction(
        date: predDate,
        predictedScore: prediction,
        confidence: confidence,
        components: PredictionComponents(
          ema: currentEma,
          trend: slope * i,
          seasonality: seasonality[weekday] ?? 0,
        ),
      ));
    }

    return predictions;
  }

  /// Agrupa dias similares usando clustering simplificado
  List<DayCluster> clusterDays({
    required List<DayProfile> days,
    int nClusters = 4,
  }) {
    if (days.length < nClusters) return [];

    // Extrai features
    final features = days.map((d) => _extractDayFeatures(d)).toList();

    // K-Means simplificado
    final random = math.Random(42);
    final indices = List.generate(days.length, (i) => i)..shuffle(random);
    var centroids = indices.take(nClusters).map((i) => List<double>.from(features[i])).toList();

    for (int iter = 0; iter < 50; iter++) {
      // Assign clusters
      final clusters = List.generate(nClusters, (_) => <int>[]);
      for (int i = 0; i < features.length; i++) {
        final distances = centroids.map((c) => _distance(features[i], c)).toList();
        final clusterIdx = distances.indexOf(distances.reduce(math.min));
        clusters[clusterIdx].add(i);
      }

      // Update centroids
      final newCentroids = <List<double>>[];
      for (int c = 0; c < nClusters; c++) {
        if (clusters[c].isEmpty) {
          newCentroids.add(centroids[c]);
          continue;
        }

        final nFeatures = features[0].length;
        final centroid = List.generate(nFeatures, (f) {
          return clusters[c].map((i) => features[i][f]).reduce((a, b) => a + b) / clusters[c].length;
        });
        newCentroids.add(centroid);
      }

      if (_centroidsEqual(centroids, newCentroids)) break;
      centroids = newCentroids;
    }

    // Interpreta clusters
    return centroids.asMap().entries.map((e) {
      final type = _interpretCluster(e.value);
      return DayCluster(
        id: e.key,
        type: type,
        centroid: e.value,
        avgMood: e.value[0] * 5,
        avgTasks: e.value[1] * 5,
        avgHabits: e.value[2] * 4,
        avgFocusHours: e.value[3] * 2,
      );
    }).toList();
  }

  /// Score de insight para priorização
  double scoreInsight({
    required double confidence,
    required double novelty,
    required double actionability,
    required double relevance,
    DateTime? lastShown,
  }) {
    const weights = {
      'confidence': 0.25,
      'novelty': 0.30,
      'actionability': 0.25,
      'relevance': 0.20,
    };

    // Penalidade se mostrado recentemente
    double cooldownPenalty = 0;
    if (lastShown != null) {
      final hoursSince = DateTime.now().difference(lastShown).inHours;
      if (hoursSince < 24) {
        cooldownPenalty = 0.5 * (1 - hoursSince / 24);
      }
    }

    final baseScore = (weights['confidence']! * confidence) +
        (weights['novelty']! * novelty) +
        (weights['actionability']! * actionability) +
        (weights['relevance']! * relevance);

    return math.max(0, baseScore - cooldownPenalty);
  }

  // ============ HELPERS ============

  double _calculateStdDev(List<double> values, double mean) {
    if (values.isEmpty) return 0;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  Map<String, double> _sortedByValue(Map<String, double> map, int limit) {
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  double _linearSlope(List<double> x, List<double> y) {
    final n = x.length;
    if (n == 0) return 0;

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);

    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return 0;

    return (n * sumXY - sumX * sumY) / denom;
  }

  List<double> _extractDayFeatures(DayProfile day) {
    return [
      day.avgMood / 5, // Normalizado 0-1
      math.min(day.tasksCompleted / 5, 1),
      math.min(day.habitsCompleted / 4, 1),
      math.min(day.focusMinutes / 120, 1),
      day.activities.length / 5,
    ];
  }

  double _distance(List<double> a, List<double> b) {
    var sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += math.pow(a[i] - b[i], 2);
    }
    return math.sqrt(sum);
  }

  bool _centroidsEqual(List<List<double>> a, List<List<double>> b) {
    for (int i = 0; i < a.length; i++) {
      for (int j = 0; j < a[i].length; j++) {
        if ((a[i][j] - b[i][j]).abs() > 0.001) return false;
      }
    }
    return true;
  }

  DayType _interpretCluster(List<double> centroid) {
    final mood = centroid[0];
    final tasks = centroid[1];
    final habits = centroid[2];
    final focus = centroid[3];

    if (mood >= 0.7 && (tasks >= 0.6 || habits >= 0.6)) {
      return DayType.productive;
    } else if (mood >= 0.7 && focus < 0.3) {
      return DayType.relaxed;
    } else if (mood <= 0.4) {
      return DayType.difficult;
    } else if (focus >= 0.7) {
      return DayType.energetic;
    } else {
      return DayType.balanced;
    }
  }
}

// ============ MODELOS ============

enum AnomalyDirection { high, low }

class MoodAnomaly {
  final DateTime date;
  final double score;
  final double expectedScore;
  final double zScore;
  final AnomalyDirection direction;
  final List<String> activities;

  MoodAnomaly({
    required this.date,
    required this.score,
    required this.expectedScore,
    required this.zScore,
    required this.direction,
    this.activities = const [],
  });

  String get description {
    final diff = (score - expectedScore).abs().toStringAsFixed(1);
    return direction == AnomalyDirection.high
        ? 'Dia excepcionalmente bom (+$diff)'
        : 'Dia excepcionalmente difícil (-$diff)';
  }

  String get icon => direction == AnomalyDirection.high ? '🌟' : '⚠️';
}

class AnomalyCauses {
  final Map<String, double> positiveFactors;
  final Map<String, double> negativeFactors;

  AnomalyCauses({
    required this.positiveFactors,
    required this.negativeFactors,
  });
}

enum VolatilityStatus { low, normal, high, insufficientData }

class MoodVolatility {
  final VolatilityStatus status;
  final double cv; // Coefficient of variation
  final double stdDev;
  final double mean;

  MoodVolatility({
    required this.status,
    required this.cv,
    required this.stdDev,
    required this.mean,
  });

  String get description {
    switch (status) {
      case VolatilityStatus.high:
        return 'Seu humor é muito variável (oscilações frequentes)';
      case VolatilityStatus.low:
        return 'Seu humor é muito estável (poucas variações)';
      case VolatilityStatus.normal:
        return 'Seu humor tem variações normais';
      case VolatilityStatus.insufficientData:
        return 'Dados insuficientes para análise';
    }
  }

  String get icon {
    switch (status) {
      case VolatilityStatus.high:
        return '📊';
      case VolatilityStatus.low:
        return '😌';
      case VolatilityStatus.normal:
        return '⚖️';
      case VolatilityStatus.insufficientData:
        return '❓';
    }
  }
}

class PredictionComponents {
  final double ema;
  final double trend;
  final double seasonality;

  PredictionComponents({
    required this.ema,
    required this.trend,
    required this.seasonality,
  });
}

class MoodPrediction {
  final DateTime date;
  final double predictedScore;
  final double confidence;
  final PredictionComponents components;

  MoodPrediction({
    required this.date,
    required this.predictedScore,
    required this.confidence,
    required this.components,
  });

  String get weekdayName {
    const days = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days[date.weekday];
  }
}

class DayProfile {
  final DateTime date;
  final double avgMood;
  final int tasksCompleted;
  final int habitsCompleted;
  final List<String> activities;
  final int focusMinutes;

  DayProfile({
    required this.date,
    required this.avgMood,
    required this.tasksCompleted,
    required this.habitsCompleted,
    required this.activities,
    required this.focusMinutes,
  });
}

enum DayType { productive, relaxed, difficult, balanced, energetic }

class DayCluster {
  final int id;
  final DayType type;
  final List<double> centroid;
  final double avgMood;
  final double avgTasks;
  final double avgHabits;
  final double avgFocusHours;

  DayCluster({
    required this.id,
    required this.type,
    required this.centroid,
    required this.avgMood,
    required this.avgTasks,
    required this.avgHabits,
    required this.avgFocusHours,
  });

  String get label {
    switch (type) {
      case DayType.productive:
        return 'Dia Produtivo 🚀';
      case DayType.relaxed:
        return 'Dia Relaxante 🌴';
      case DayType.difficult:
        return 'Dia Difícil 😔';
      case DayType.balanced:
        return 'Dia Equilibrado ⚖️';
      case DayType.energetic:
        return 'Dia Energético ⚡';
    }
  }
}
