import 'dart:math' as math;
import '../../data/intelligence_config.dart';
import '../models/correlation.dart';

/// Engine para calcular correlações entre variáveis
class CorrelationEngine {
  /// Calcula correlação de Pearson entre duas listas
  double calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 3) return 0;

    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    final sumY2 = y.map((v) => v * v).reduce((a, b) => a + b);

    final numerator = n * sumXY - sumX * sumY;
    final denominator =
        math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  /// Calcula p-value para correlação de Pearson (teste t)
  double calculatePValue(double r, int n) {
    if (n <= 2) return 1.0;
    if (r.abs() >= 1.0) return 0.0;

    final t = r * math.sqrt((n - 2) / (1 - r * r));
    final df = n - 2;

    // Aproximação usando distribuição t
    return _tDistributionPValue(t.abs(), df);
  }

  /// Aproximação do p-value usando distribuição t
  double _tDistributionPValue(double t, int df) {
    // Aproximação simplificada para testes rápidos
    // Para df > 30, usa aproximação normal
    if (df > 30) {
      final z = t;
      // Aproximação da CDF normal
      final p = 0.5 * (1 + _erf(z / math.sqrt(2)));
      return 2 * (1 - p); // Two-tailed
    }

    // Para df menores, usa tabela simplificada
    // Valores críticos aproximados para alpha = 0.05
    final criticalValues = {
      1: 12.71,
      2: 4.30,
      3: 3.18,
      4: 2.78,
      5: 2.57,
      10: 2.23,
      15: 2.13,
      20: 2.09,
      25: 2.06,
      30: 2.04,
    };

    final nearestDf = criticalValues.keys
        .reduce((a, b) => (a - df).abs() < (b - df).abs() ? a : b);
    final criticalValue = criticalValues[nearestDf]!;

    if (t > criticalValue * 1.5) return 0.001;
    if (t > criticalValue) return 0.05;
    if (t > criticalValue * 0.7) return 0.10;
    return 0.20;
  }

  /// Função erro (erf) - aproximação
  double _erf(double x) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return sign * y;
  }

  /// Calcula correlação entre humor e atividade
  Correlation? calculateMoodVsActivity({
    required String activityId,
    required String activityName,
    required List<DailyDataPoint> dailyData,
  }) {
    if (dailyData.length < IntelligenceConfig.minDataPointsForCorrelation) {
      return null;
    }

    final moodScores = <double>[];
    final activityDone = <double>[];

    for (final day in dailyData) {
      moodScores.add(day.avgMood);
      activityDone.add(day.activitiesDone.contains(activityId) ? 1.0 : 0.0);
    }

    final r = calculatePearsonCorrelation(moodScores, activityDone);

    if (r.abs() < IntelligenceConfig.minCorrelationThreshold) return null;

    final pValue = calculatePValue(r, dailyData.length);
    final strength = Correlation.classifyStrength(r);

    // Calcula diferença de médias
    final withActivity = <double>[];
    final withoutActivity = <double>[];

    for (int i = 0; i < dailyData.length; i++) {
      if (activityDone[i] == 1.0) {
        withActivity.add(moodScores[i]);
      } else {
        withoutActivity.add(moodScores[i]);
      }
    }

    final avgWith = withActivity.isEmpty
        ? 0.0
        : withActivity.reduce((a, b) => a + b) / withActivity.length;
    final avgWithout = withoutActivity.isEmpty
        ? 0.0
        : withoutActivity.reduce((a, b) => a + b) / withoutActivity.length;

    final difference = avgWith - avgWithout;
    final percentDiff = avgWithout > 0
        ? ((difference / avgWithout) * 100).toStringAsFixed(0)
        : '0';

    String description;
    if (r > 0) {
      description = '$activityName melhora seu humor em $percentDiff%';
    } else {
      description = '$activityName está associado a humor mais baixo';
    }

    return Correlation(
      id: 'corr_activity_${activityId}_${DateTime.now().millisecondsSinceEpoch}',
      variable1: 'activity_$activityId',
      variable1Label: activityName,
      variable2: 'mood_score',
      variable2Label: 'Humor',
      coefficient: r,
      pValue: pValue,
      sampleSize: dailyData.length,
      strength: strength,
      calculatedAt: DateTime.now(),
      description: description,
    );
  }

  /// Calcula correlação entre humor e hora do dia
  Correlation? calculateMoodVsTimeOfDay({
    required List<MoodTimePoint> moodData,
  }) {
    if (moodData.length < IntelligenceConfig.minDataPointsForCorrelation) {
      return null;
    }

    final hours = moodData.map((p) => p.hour.toDouble()).toList();
    final scores = moodData.map((p) => p.score).toList();

    final r = calculatePearsonCorrelation(hours, scores);

    if (r.abs() < IntelligenceConfig.minCorrelationThreshold) return null;

    final pValue = calculatePValue(r, moodData.length);
    final strength = Correlation.classifyStrength(r);

    String description;
    if (r > 0) {
      description = 'Seu humor tende a melhorar ao longo do dia';
    } else {
      description = 'Seu humor tende a cair ao longo do dia';
    }

    return Correlation(
      id: 'corr_time_${DateTime.now().millisecondsSinceEpoch}',
      variable1: 'hour_of_day',
      variable1Label: 'Hora do Dia',
      variable2: 'mood_score',
      variable2Label: 'Humor',
      coefficient: r,
      pValue: pValue,
      sampleSize: moodData.length,
      strength: strength,
      calculatedAt: DateTime.now(),
      description: description,
    );
  }

  /// Calcula correlação entre tarefas completas e humor
  Correlation? calculateTasksVsMood({
    required List<DailyDataPoint> dailyData,
  }) {
    if (dailyData.length < IntelligenceConfig.minDataPointsForCorrelation) {
      return null;
    }

    final tasksCompleted =
        dailyData.map((d) => d.tasksCompleted.toDouble()).toList();
    final moodScores = dailyData.map((d) => d.avgMood).toList();

    final r = calculatePearsonCorrelation(tasksCompleted, moodScores);

    if (r.abs() < IntelligenceConfig.minCorrelationThreshold) return null;

    final pValue = calculatePValue(r, dailyData.length);
    final strength = Correlation.classifyStrength(r);

    String description;
    if (r > 0) {
      description = 'Completar tarefas está associado a melhor humor';
    } else {
      description = 'Mais tarefas completas não melhoram seu humor';
    }

    return Correlation(
      id: 'corr_tasks_${DateTime.now().millisecondsSinceEpoch}',
      variable1: 'tasks_completed',
      variable1Label: 'Tarefas Completas',
      variable2: 'mood_score',
      variable2Label: 'Humor',
      coefficient: r,
      pValue: pValue,
      sampleSize: dailyData.length,
      strength: strength,
      calculatedAt: DateTime.now(),
      description: description,
    );
  }

  /// Calcula todas as correlações relevantes
  List<Correlation> calculateAllCorrelations({
    required List<DailyDataPoint> dailyData,
    required List<MoodTimePoint> moodTimeData,
    required Map<String, String> activityNames,
  }) {
    final correlations = <Correlation>[];

    // Correlação humor vs hora
    final timeCorr = calculateMoodVsTimeOfDay(moodData: moodTimeData);
    if (timeCorr != null && timeCorr.isSignificant) {
      correlations.add(timeCorr);
    }

    // Correlação tarefas vs humor
    final taskCorr = calculateTasksVsMood(dailyData: dailyData);
    if (taskCorr != null && taskCorr.isSignificant) {
      correlations.add(taskCorr);
    }

    // Correlação hábitos vs humor
    final habitCorr = calculateHabitsVsMood(dailyData: dailyData);
    if (habitCorr != null && habitCorr.isSignificant) {
      correlations.add(habitCorr);
    }

    // Correlação tempo focado vs humor
    final focusCorr = calculateFocusTimeVsMood(dailyData: dailyData);
    if (focusCorr != null && focusCorr.isSignificant) {
      correlations.add(focusCorr);
    }

    // Correlação por atividade
    for (final entry in activityNames.entries) {
      final actCorr = calculateMoodVsActivity(
        activityId: entry.key,
        activityName: entry.value,
        dailyData: dailyData,
      );
      if (actCorr != null && actCorr.isSignificant) {
        correlations.add(actCorr);
      }
    }

    // Ordena por força da correlação
    correlations.sort((a, b) => b.coefficient.abs().compareTo(a.coefficient.abs()));

    return correlations.take(IntelligenceConfig.maxCorrelationsStored).toList();
  }

  /// Calcula correlação entre hábitos completos e humor
  Correlation? calculateHabitsVsMood({
    required List<DailyDataPoint> dailyData,
  }) {
    if (dailyData.length < IntelligenceConfig.minDataPointsForCorrelation) {
      return null;
    }

    final habitsCompleted =
        dailyData.map((d) => d.habitsCompleted.toDouble()).toList();
    final moodScores = dailyData.map((d) => d.avgMood).toList();

    final r = calculatePearsonCorrelation(habitsCompleted, moodScores);

    if (r.abs() < IntelligenceConfig.minCorrelationThreshold) return null;

    final pValue = calculatePValue(r, dailyData.length);
    final strength = Correlation.classifyStrength(r);

    String description;
    if (r > 0) {
      description = 'Completar hábitos está associado a melhor humor';
    } else {
      description = 'Mais hábitos completos não melhoram seu humor';
    }

    return Correlation(
      id: 'corr_habits_${DateTime.now().millisecondsSinceEpoch}',
      variable1: 'habits_completed',
      variable1Label: 'Hábitos Completos',
      variable2: 'mood_score',
      variable2Label: 'Humor',
      coefficient: r,
      pValue: pValue,
      sampleSize: dailyData.length,
      strength: strength,
      calculatedAt: DateTime.now(),
      description: description,
    );
  }

  /// Calcula correlação entre tempo focado e humor
  Correlation? calculateFocusTimeVsMood({
    required List<DailyDataPoint> dailyData,
  }) {
    if (dailyData.length < IntelligenceConfig.minDataPointsForCorrelation) {
      return null;
    }

    // Filtra dias com dados de tempo
    final dataWithTime = dailyData.where((d) => d.timeTracked.inMinutes > 0).toList();
    if (dataWithTime.length < 7) return null;

    final focusMinutes =
        dataWithTime.map((d) => d.timeTracked.inMinutes.toDouble()).toList();
    final moodScores = dataWithTime.map((d) => d.avgMood).toList();

    final r = calculatePearsonCorrelation(focusMinutes, moodScores);

    if (r.abs() < IntelligenceConfig.minCorrelationThreshold) return null;

    final pValue = calculatePValue(r, dataWithTime.length);
    final strength = Correlation.classifyStrength(r);

    String description;
    if (r > 0) {
      description = 'Mais tempo focado está associado a melhor humor';
    } else {
      description = 'Tempo focado não melhora seu humor (talvez estresse?)';
    }

    return Correlation(
      id: 'corr_focus_${DateTime.now().millisecondsSinceEpoch}',
      variable1: 'focus_time',
      variable1Label: 'Tempo Focado',
      variable2: 'mood_score',
      variable2Label: 'Humor',
      coefficient: r,
      pValue: pValue,
      sampleSize: dataWithTime.length,
      strength: strength,
      calculatedAt: DateTime.now(),
      description: description,
    );
  }

  /// Calcula correlação de Spearman (não-linear, baseada em ranks)
  double calculateSpearmanCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 3) return 0;

    // Converte para ranks
    final ranksX = _toRanks(x);
    final ranksY = _toRanks(y);

    // Usa Pearson nos ranks
    return calculatePearsonCorrelation(ranksX, ranksY);
  }

  /// Converte valores para ranks
  List<double> _toRanks(List<double> values) {
    final indexed = values.asMap().entries.toList();
    indexed.sort((a, b) => a.value.compareTo(b.value));
    
    final ranks = List<double>.filled(values.length, 0);
    for (int i = 0; i < indexed.length; i++) {
      ranks[indexed[i].key] = i + 1.0;
    }
    return ranks;
  }
}

/// Dados diários agregados
class DailyDataPoint {
  final DateTime date;
  final double avgMood;
  final int tasksCompleted;
  final int habitsCompleted;
  final List<String> activitiesDone;
  final Duration timeTracked;

  DailyDataPoint({
    required this.date,
    required this.avgMood,
    this.tasksCompleted = 0,
    this.habitsCompleted = 0,
    this.activitiesDone = const [],
    this.timeTracked = Duration.zero,
  });
}

/// Ponto de humor com hora
class MoodTimePoint {
  final int hour;
  final double score;
  final DateTime date;

  MoodTimePoint({
    required this.hour,
    required this.score,
    required this.date,
  });
}
