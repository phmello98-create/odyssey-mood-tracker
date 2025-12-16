import 'package:hive/hive.dart';

part 'prediction.g.dart';

/// Tipo de previsão
@HiveType(typeId: 34)
enum PredictionType {
  @HiveField(0)
  streakBreak,
  @HiveField(1)
  streakSuccess,
  @HiveField(2)
  moodDrop,
  @HiveField(3)
  moodImprovement,
  @HiveField(4)
  taskCompletion,
  @HiveField(5)
  habitCompletion,
  @HiveField(6)
  productiveDay,
}

/// Previsão gerada pelo sistema
@HiveType(typeId: 29)
class Prediction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final PredictionType type;

  @HiveField(2)
  final String? targetId;

  @HiveField(3)
  final String? targetName;

  @HiveField(4)
  final double probability;

  @HiveField(5)
  final DateTime predictedFor;

  @HiveField(6)
  final String reasoning;

  @HiveField(7)
  final Map<String, dynamic> features;

  @HiveField(8)
  final DateTime generatedAt;

  @HiveField(9)
  bool? wasAccurate;

  Prediction({
    required this.id,
    required this.type,
    this.targetId,
    this.targetName,
    required this.probability,
    required this.predictedFor,
    required this.reasoning,
    this.features = const {},
    required this.generatedAt,
    this.wasAccurate,
  });

  /// Verifica se é uma previsão de alto risco
  bool get isHighRisk => probability >= 0.7;

  /// Verifica se é uma previsão positiva ou negativa
  bool get isPositive =>
      type == PredictionType.streakSuccess ||
      type == PredictionType.moodImprovement ||
      type == PredictionType.taskCompletion ||
      type == PredictionType.habitCompletion ||
      type == PredictionType.productiveDay;

  /// Verifica se a previsão já passou
  bool get hasExpired => DateTime.now().isAfter(predictedFor);

  /// Descrição legível da previsão (para widgets)
  String get description {
    if (targetName != null && targetName!.isNotEmpty) {
      return '$typeLabel: $targetName';
    }
    return reasoning.isNotEmpty ? reasoning : typeLabel;
  }

  /// Confiança da previsão (alias para probability, para widgets)
  double get confidence => probability;

  /// Sugestão de ação baseada no tipo de previsão
  String? get actionSuggestion {
    switch (type) {
      case PredictionType.streakBreak:
        return 'Complete seu hábito hoje para manter o streak!';
      case PredictionType.streakSuccess:
        return 'Continue assim, você está indo muito bem!';
      case PredictionType.moodDrop:
        return 'Que tal fazer algo que te faz bem hoje?';
      case PredictionType.moodImprovement:
        return 'Aproveite o bom momento!';
      case PredictionType.taskCompletion:
        return 'Foque nas tarefas prioritárias';
      case PredictionType.habitCompletion:
        return 'Mantenha sua rotina consistente';
      case PredictionType.productiveDay:
        return 'Use esse dia para tarefas importantes!';
    }
  }

  /// Ícone baseado no tipo
  String get icon {
    switch (type) {
      case PredictionType.streakBreak:
        return '⚠️';
      case PredictionType.streakSuccess:
        return '🔥';
      case PredictionType.moodDrop:
        return '📉';
      case PredictionType.moodImprovement:
        return '📈';
      case PredictionType.taskCompletion:
        return '✅';
      case PredictionType.habitCompletion:
        return '🎯';
      case PredictionType.productiveDay:
        return '⚡';
    }
  }

  /// Texto do tipo
  String get typeLabel {
    switch (type) {
      case PredictionType.streakBreak:
        return 'Risco de Streak';
      case PredictionType.streakSuccess:
        return 'Streak Provável';
      case PredictionType.moodDrop:
        return 'Queda de Humor';
      case PredictionType.moodImprovement:
        return 'Melhora de Humor';
      case PredictionType.taskCompletion:
        return 'Conclusão de Tarefa';
      case PredictionType.habitCompletion:
        return 'Hábito Provável';
      case PredictionType.productiveDay:
        return 'Dia Produtivo';
    }
  }

  Prediction copyWith({
    String? id,
    PredictionType? type,
    String? targetId,
    String? targetName,
    double? probability,
    DateTime? predictedFor,
    String? reasoning,
    Map<String, dynamic>? features,
    DateTime? generatedAt,
    bool? wasAccurate,
  }) {
    return Prediction(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      probability: probability ?? this.probability,
      predictedFor: predictedFor ?? this.predictedFor,
      reasoning: reasoning ?? this.reasoning,
      features: features ?? this.features,
      generatedAt: generatedAt ?? this.generatedAt,
      wasAccurate: wasAccurate ?? this.wasAccurate,
    );
  }
}
