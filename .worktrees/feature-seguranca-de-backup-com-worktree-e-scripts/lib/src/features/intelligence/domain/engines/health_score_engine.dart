import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Engine de cálculo do Health Score unificado
class HealthScoreEngine {
  /// Pesos das dimensões
  static const weights = {
    'mood': 0.35,
    'habits': 0.25,
    'productivity': 0.20,
    'consistency': 0.20,
  };

  /// Calcula Health Score completo
  HealthReport analyze({
    required List<MoodInput> moodRecords,
    required List<HabitInput> habits,
    required List<TaskInput> tasks,
    int expectedDays = 30,
  }) {
    // Calcula cada dimensão
    final moodDim = _analyzeMood(moodRecords);
    final habitsDim = _analyzeHabits(habits, expectedDays);
    final productivityDim = _analyzeProductivity(tasks);
    final consistencyDim = _analyzeConsistency(moodRecords, expectedDays);

    final dimensions = [moodDim, habitsDim, productivityDim, consistencyDim];

    // Score geral
    final overall = dimensions.fold<double>(
      0,
      (sum, d) => sum + d.score * d.weight,
    );
    final level = _scoreToLevel(overall);

    // Pontos fortes e fracos
    final sorted = List<DimensionScore>.from(dimensions)
      ..sort((a, b) => b.score.compareTo(a.score));
    
    final strengths = sorted.where((d) => d.score >= 70).take(2).map((d) => d.name).toList();
    final weaknesses = sorted.where((d) => d.score < 50).take(2).map((d) => d.name).toList();

    // Ações prioritárias
    final priorityActions = <String>[];
    for (final dim in sorted) {
      if (dim.score < 60 && dim.recommendations.isNotEmpty) {
        priorityActions.add(dim.recommendations.first);
      }
    }

    // Tendência
    final trend = _calculateTrend(moodRecords);

    return HealthReport(
      overallScore: overall,
      level: level,
      dimensions: dimensions,
      topStrengths: strengths,
      topWeaknesses: weaknesses,
      priorityActions: priorityActions.take(3).toList(),
      trend: trend,
    );
  }

  DimensionScore _analyzeMood(List<MoodInput> records) {
    if (records.isEmpty) {
      return _emptyDimension('Humor', weights['mood']!);
    }

    final scores = records.map((r) => r.score).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final avgNormalized = (avg - 1) / 4 * 100; // 1-5 -> 0-100

    // Volatilidade
    final stdDev = _calculateStdDev(scores, avg);
    final cv = avg > 0 ? stdDev / avg : 0;
    final stabilityScore = math.max(0, 100 - cv * 200);

    // Tendência recente
    double trendScore = 50;
    if (scores.length >= 7) {
      final recent = scores.sublist(scores.length - 7);
      final older = scores.length >= 14
          ? scores.sublist(0, 7)
          : scores.sublist(0, scores.length ~/ 2);
      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final olderAvg = older.reduce((a, b) => a + b) / older.length;
      final diff = recentAvg - olderAvg;
      trendScore = (50 + diff * 25).clamp(0, 100);
    }

    final finalScore = avgNormalized * 0.5 + stabilityScore * 0.25 + trendScore * 0.25;

    final recommendations = <String>[];
    if (avgNormalized < 50) {
      recommendations.add('Registre atividades que melhoram seu humor');
    }
    if (stabilityScore < 50) {
      recommendations.add('Tente manter rotinas consistentes');
    }
    if (trendScore < 40) {
      recommendations.add('Atenção: humor em tendência de queda');
    }

    return DimensionScore(
      name: 'Humor',
      score: finalScore,
      weight: weights['mood']!,
      level: _scoreToLevel(finalScore),
      factors: {
        'média': avgNormalized.toDouble(),
        'estabilidade': stabilityScore.toDouble(),
        'tendência': trendScore.toDouble(),
      },
      recommendations: recommendations,
    );
  }

  DimensionScore _analyzeHabits(List<HabitInput> habits, int days) {
    if (habits.isEmpty) {
      return _emptyDimension('Hábitos', weights['habits']!);
    }

    // Taxa de conclusão
    final totalPossible = habits.length * days;
    final totalCompleted = habits.fold<int>(0, (sum, h) => sum + h.completionCount);
    final completionRate = totalPossible > 0 ? totalCompleted / totalPossible * 100 : 0;

    // Streaks ativos
    final activeStreaks = habits.where((h) => h.currentStreak > 0).length;
    final streakRate = activeStreaks / habits.length * 100;

    // Melhor streak
    final bestStreak = habits.fold<int>(0, (max, h) => math.max(max, h.currentStreak));
    final streakBonus = math.min(bestStreak * 5.0, 30.0);

    final finalScore = math.min(100.0, completionRate * 0.6 + streakRate * 0.3 + streakBonus * 0.1);

    final recommendations = <String>[];
    if (completionRate < 40) {
      recommendations.add('Comece com apenas 1-2 hábitos simples');
    }
    if (streakRate < 30) {
      recommendations.add('Foque em manter um hábito consistente');
    }

    return DimensionScore(
      name: 'Hábitos',
      score: finalScore,
      weight: weights['habits']!,
      level: _scoreToLevel(finalScore),
      factors: {
        'taxa_conclusão': completionRate.toDouble(),
        'streaks_ativos': streakRate.toDouble(),
        'melhor_streak': bestStreak.toDouble(),
      },
      recommendations: recommendations,
    );
  }

  DimensionScore _analyzeProductivity(List<TaskInput> tasks) {
    if (tasks.isEmpty) {
      return _emptyDimension('Produtividade', weights['productivity']!);
    }

    final completed = tasks.where((t) => t.isCompleted).length;
    final completionRate = completed / tasks.length * 100;

    // Tarefas por dia
    final dates = tasks.map((t) => t.createdAt.toIso8601String().substring(0, 10)).toSet();
    final tasksPerDay = dates.isNotEmpty ? completed / dates.length : 0;
    final volumeScore = math.min(tasksPerDay * 20, 100.0);

    final finalScore = completionRate * 0.7 + volumeScore * 0.3;

    final recommendations = <String>[];
    if (completionRate < 50) {
      recommendations.add('Divida tarefas grandes em subtarefas menores');
    }
    if (volumeScore < 40) {
      recommendations.add('Defina 2-3 tarefas importantes por dia');
    }

    return DimensionScore(
      name: 'Produtividade',
      score: finalScore,
      weight: weights['productivity']!,
      level: _scoreToLevel(finalScore),
      factors: {
        'taxa_conclusão': completionRate.toDouble(),
        'volume': volumeScore.toDouble(),
      },
      recommendations: recommendations,
    );
  }

  DimensionScore _analyzeConsistency(List<MoodInput> records, int expectedDays) {
    if (records.isEmpty) {
      return _emptyDimension('Consistência', weights['consistency']!);
    }

    // Dias com registro
    final uniqueDays = records.map((r) => r.date.toIso8601String().substring(0, 10)).toSet();
    final coverage = uniqueDays.length / expectedDays * 100;

    // Streak de registros
    final sortedDays = uniqueDays.toList()..sort();
    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      try {
        final prev = DateTime.parse(sortedDays[i - 1]);
        final curr = DateTime.parse(sortedDays[i]);
        if (curr.difference(prev).inDays == 1) {
          currentStreak++;
          maxStreak = math.max(maxStreak, currentStreak);
        } else {
          currentStreak = 1;
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    final streakScore = math.min(maxStreak * 10.0, 100.0);
    final finalScore = coverage * 0.6 + streakScore * 0.4;

    final recommendations = <String>[];
    if (coverage < 50) {
      recommendations.add('Registre seu humor pelo menos 1x por dia');
    }
    if (streakScore < 30) {
      recommendations.add('Configure lembretes diários');
    }

    return DimensionScore(
      name: 'Consistência',
      score: finalScore,
      weight: weights['consistency']!,
      level: _scoreToLevel(finalScore),
      factors: {
        'cobertura': coverage,
        'regularidade': streakScore,
      },
      recommendations: recommendations,
    );
  }

  DimensionScore _emptyDimension(String name, double weight) {
    return DimensionScore(
      name: name,
      score: 0,
      weight: weight,
      level: HealthLevel.needsAttention,
      factors: {},
      recommendations: ['Comece a registrar dados para análise'],
    );
  }

  HealthLevel _scoreToLevel(double score) {
    if (score >= 80) return HealthLevel.excellent;
    if (score >= 60) return HealthLevel.good;
    if (score >= 40) return HealthLevel.moderate;
    if (score >= 20) return HealthLevel.needsAttention;
    return HealthLevel.critical;
  }

  HealthTrend _calculateTrend(List<MoodInput> records) {
    if (records.length < 14) return HealthTrend.insufficientData;

    final scores = records.map((r) => r.score).toList();
    final mid = scores.length ~/ 2;
    final firstHalf = scores.sublist(0, mid).reduce((a, b) => a + b) / mid;
    final secondHalf = scores.sublist(mid).reduce((a, b) => a + b) / (scores.length - mid);

    final diff = secondHalf - firstHalf;
    if (diff > 0.3) return HealthTrend.improving;
    if (diff < -0.3) return HealthTrend.declining;
    return HealthTrend.stable;
  }

  double _calculateStdDev(List<double> values, double mean) {
    if (values.isEmpty) return 0;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }
}

// ============ MODELOS ============

enum HealthLevel { excellent, good, moderate, needsAttention, critical }

enum HealthTrend { improving, stable, declining, insufficientData }

class DimensionScore {
  final String name;
  final double score;
  final double weight;
  final HealthLevel level;
  final Map<String, double> factors;
  final List<String> recommendations;

  DimensionScore({
    required this.name,
    required this.score,
    required this.weight,
    required this.level,
    required this.factors,
    required this.recommendations,
  });

  String get icon {
    switch (level) {
      case HealthLevel.excellent:
        return '🌟';
      case HealthLevel.good:
        return '✅';
      case HealthLevel.moderate:
        return '⚠️';
      case HealthLevel.needsAttention:
        return '🔶';
      case HealthLevel.critical:
        return '🚨';
    }
  }
}

class HealthReport {
  final double overallScore;
  final HealthLevel level;
  final List<DimensionScore> dimensions;
  final List<String> topStrengths;
  final List<String> topWeaknesses;
  final List<String> priorityActions;
  final HealthTrend trend;

  HealthReport({
    required this.overallScore,
    required this.level,
    required this.dimensions,
    required this.topStrengths,
    required this.topWeaknesses,
    required this.priorityActions,
    required this.trend,
  });

  String get trendIcon {
    switch (trend) {
      case HealthTrend.improving:
        return '📈';
      case HealthTrend.stable:
        return '➡️';
      case HealthTrend.declining:
        return '📉';
      case HealthTrend.insufficientData:
        return '❓';
    }
  }

  String get levelText {
    switch (level) {
      case HealthLevel.excellent:
        return 'Excelente';
      case HealthLevel.good:
        return 'Bom';
      case HealthLevel.moderate:
        return 'Moderado';
      case HealthLevel.needsAttention:
        return 'Atenção';
      case HealthLevel.critical:
        return 'Crítico';
    }
  }
}

// Inputs simplificados
class MoodInput {
  final DateTime date;
  final double score;
  final List<String> activities;

  MoodInput({required this.date, required this.score, this.activities = const []});
}

class HabitInput {
  final String id;
  final String name;
  final int completionCount;
  final int currentStreak;

  HabitInput({
    required this.id,
    required this.name,
    required this.completionCount,
    required this.currentStreak,
  });
}

class TaskInput {
  final String id;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskInput({
    required this.id,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
  });
}
