import '../models/correlation.dart';
import '../models/user_pattern.dart';

/// Engine para gerar recomendações personalizadas
class RecommendationEngine {
  /// Recomenda atividades baseadas no humor atual
  List<ActivityRecommendation> recommendActivitiesForMood({
    required int currentMoodScore,
    required List<Correlation> correlations,
    required List<String> recentActivities,
  }) {
    final recommendations = <ActivityRecommendation>[];

    // Filtra correlações positivas com humor
    final positiveCorrelations = correlations
        .where((c) =>
            c.variable2 == 'mood_score' &&
            c.coefficient > 0.3 &&
            c.variable1.startsWith('activity_'))
        .toList();

    for (final corr in positiveCorrelations) {
      final activityId = corr.variable1.replaceFirst('activity_', '');

      // Penaliza se já fez recentemente
      final recentPenalty = recentActivities.contains(activityId) ? 0.5 : 1.0;

      // Score baseado na correlação e humor atual
      // Se humor baixo, prioriza atividades com alta correlação
      final moodBoost = currentMoodScore <= 2 ? 1.5 : 1.0;

      final score = corr.coefficient * recentPenalty * moodBoost;

      recommendations.add(ActivityRecommendation(
        activityId: activityId,
        activityName: corr.variable1Label,
        score: score,
        reason: corr.description ?? 'Baseado em seus padrões',
        expectedMoodImprovement: _estimateMoodImprovement(corr.coefficient),
      ));
    }

    // Ordena por score
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    return recommendations.take(5).toList();
  }

  /// Recomenda melhor horário para atividade
  TimeRecommendation? recommendBestTimeForActivity({
    required String activityId,
    required List<UserPattern> patterns,
  }) {
    // Procura padrão de produtividade
    final productivityPattern = patterns.firstWhere(
      (p) => p.type == PatternType.behavioral && p.data['bestHour'] != null,
      orElse: () => UserPattern(
        id: '',
        type: PatternType.behavioral,
        description: '',
        strength: 0,
        firstDetected: DateTime.now(),
        lastConfirmed: DateTime.now(),
      ),
    );

    if (productivityPattern.strength == 0) return null;

    final bestHour = productivityPattern.data['bestHour'] as int;

    return TimeRecommendation(
      hour: bestHour,
      reason: productivityPattern.description,
      confidence: productivityPattern.strength,
    );
  }

  /// Recomenda atividades baseadas no horário
  List<ActivityRecommendation> recommendForTimeOfDay({
    required int currentHour,
    required List<UserPattern> patterns,
    required List<Correlation> correlations,
  }) {
    final recommendations = <ActivityRecommendation>[];

    // Encontra padrão de hora do dia
    final hourPattern = patterns.firstWhere(
      (p) =>
          p.type == PatternType.temporal && p.data['bestPeriodName'] != null,
      orElse: () => UserPattern(
        id: '',
        type: PatternType.temporal,
        description: '',
        strength: 0,
        firstDetected: DateTime.now(),
        lastConfirmed: DateTime.now(),
      ),
    );

    // Se está no melhor período, sugere tarefas importantes
    final bestPeriod = hourPattern.data['bestPeriod'] as int?;
    final isInBestPeriod =
        bestPeriod != null && (currentHour ~/ 4) * 4 == bestPeriod;

    if (isInBestPeriod) {
      recommendations.add(ActivityRecommendation(
        activityId: 'important_tasks',
        activityName: 'Tarefas Importantes',
        score: 0.9,
        reason: 'Este é seu melhor horário para produtividade',
        expectedMoodImprovement: 0.5,
      ));
    }

    // Adiciona recomendações de atividades
    final activityRecs = recommendActivitiesForMood(
      currentMoodScore: 3,
      correlations: correlations,
      recentActivities: [],
    );

    recommendations.addAll(activityRecs);

    return recommendations;
  }

  /// Gera recomendações gerais do dia
  List<DailyRecommendation> generateDailyRecommendations({
    required List<UserPattern> patterns,
    required List<Correlation> correlations,
    required DateTime today,
  }) {
    final recommendations = <DailyRecommendation>[];
    final dayOfWeek = today.weekday;

    // Recomendação baseada em padrão de dia da semana
    final dayPattern = patterns.firstWhere(
      (p) => p.type == PatternType.temporal && p.data['bestDay'] != null,
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
      final bestDay = dayPattern.data['bestDay'] as int;
      final worstDay = dayPattern.data['worstDay'] as int?;

      if (dayOfWeek == bestDay) {
        recommendations.add(DailyRecommendation(
          title: 'Dia de Alta Energia!',
          description:
              'Historicamente, ${_getDayName(bestDay)} é seu melhor dia. Aproveite para tarefas importantes!',
          priority: RecommendationPriority.high,
          icon: '⚡',
        ));
      } else if (dayOfWeek == worstDay) {
        recommendations.add(DailyRecommendation(
          title: 'Dia para Cuidar de Si',
          description:
              'Este costuma ser um dia mais difícil. Seja gentil consigo mesmo.',
          priority: RecommendationPriority.medium,
          icon: '💆',
        ));
      }
    }

    // Recomendação baseada em correlações fortes
    final strongCorr = correlations.where((c) =>
        c.strength == CorrelationStrength.strong ||
        c.strength == CorrelationStrength.veryStrong);

    for (final corr in strongCorr.take(2)) {
      if (corr.coefficient > 0) {
        recommendations.add(DailyRecommendation(
          title: 'Sugestão: ${corr.variable1Label}',
          description: corr.description ?? 'Melhora seu humor',
          priority: RecommendationPriority.medium,
          icon: '💡',
          actionId: corr.variable1,
        ));
      }
    }

    return recommendations;
  }

  double _estimateMoodImprovement(double correlation) {
    // Estima melhoria de humor baseada na correlação
    return correlation * 1.5; // Simplificado
  }

  String _getDayName(int day) {
    const days = [
      '',
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo'
    ];
    return days[day];
  }
}

/// Recomendação de atividade
class ActivityRecommendation {
  final String activityId;
  final String activityName;
  final double score;
  final String reason;
  final double expectedMoodImprovement;

  ActivityRecommendation({
    required this.activityId,
    required this.activityName,
    required this.score,
    required this.reason,
    required this.expectedMoodImprovement,
  });

  /// Impacto esperado (alias para expectedMoodImprovement, para widgets)
  double get expectedImpact => expectedMoodImprovement;

  /// Confiança baseada no score (para widgets)
  double get confidence => score.clamp(0.0, 1.0);
}

/// Recomendação de horário
class TimeRecommendation {
  final int hour;
  final String reason;
  final double confidence;

  TimeRecommendation({
    required this.hour,
    required this.reason,
    required this.confidence,
  });

  String get formattedTime => '${hour.toString().padLeft(2, '0')}:00';

  /// Atividade recomendada (para widgets)
  String get activity => reason;

  /// Boost esperado (alias para confidence, para widgets)
  double get expectedBoost => confidence;
}

/// Recomendação diária
class DailyRecommendation {
  final String title;
  final String description;
  final RecommendationPriority priority;
  final String icon;
  final String? actionId;

  DailyRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
    this.actionId,
  });

  /// Categoria baseada no ícone (para widgets)
  String get category {
    switch (icon) {
      case '⚡': return 'Produtividade';
      case '💆': return 'Bem-estar';
      case '💡': return 'Sugestão';
      case '😴': return 'Sono';
      case '🏋️': return 'Exercício';
      case '😊': return 'Humor';
      default: return 'Geral';
    }
  }

  /// Label da ação (para widgets)
  String get actionLabel => actionId != null ? 'Fazer' : 'Entendi';
}

enum RecommendationPriority { low, medium, high }
