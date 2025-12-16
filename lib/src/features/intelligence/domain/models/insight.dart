import 'package:hive/hive.dart';

part 'insight.g.dart';

/// Tipos de insight que o sistema pode gerar
@HiveType(typeId: 27)
enum InsightType {
  @HiveField(0)
  pattern,
  @HiveField(1)
  correlation,
  @HiveField(2)
  recommendation,
  @HiveField(3)
  prediction,
  @HiveField(4)
  warning,
  @HiveField(5)
  celebration,
}

/// Prioridade do insight
@HiveType(typeId: 31)
enum InsightPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

/// Modelo de Insight gerado pelo sistema de inteligência
@HiveType(typeId: 32)
class Insight extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final InsightType type;

  @HiveField(4)
  final InsightPriority priority;

  @HiveField(5)
  final double confidence;

  @HiveField(6)
  final DateTime generatedAt;

  @HiveField(7)
  final DateTime validUntil;

  @HiveField(8)
  final Map<String, dynamic> metadata;

  @HiveField(9)
  bool isRead;

  @HiveField(10)
  int? userRating;

  @HiveField(11)
  final String? actionId;

  @HiveField(12)
  final String? actionLabel;

  Insight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.confidence,
    required this.generatedAt,
    required this.validUntil,
    this.metadata = const {},
    this.isRead = false,
    this.userRating,
    this.actionId,
    this.actionLabel,
  });

  /// Verifica se o insight ainda é válido
  bool get isValid => DateTime.now().isBefore(validUntil);

  /// Verifica se é um insight de alta prioridade
  bool get isHighPriority =>
      priority == InsightPriority.high || priority == InsightPriority.urgent;

  /// Ícone baseado no tipo
  String get icon {
    switch (type) {
      case InsightType.pattern:
        return '📊';
      case InsightType.correlation:
        return '🔗';
      case InsightType.recommendation:
        return '💡';
      case InsightType.prediction:
        return '🔮';
      case InsightType.warning:
        return '⚠️';
      case InsightType.celebration:
        return '🎉';
    }
  }

  /// Cor baseada na prioridade (hex string)
  String get priorityColor {
    switch (priority) {
      case InsightPriority.low:
        return '#9E9E9E';
      case InsightPriority.medium:
        return '#2196F3';
      case InsightPriority.high:
        return '#FF9800';
      case InsightPriority.urgent:
        return '#F44336';
    }
  }

  Insight copyWith({
    String? id,
    String? title,
    String? description,
    InsightType? type,
    InsightPriority? priority,
    double? confidence,
    DateTime? generatedAt,
    DateTime? validUntil,
    Map<String, dynamic>? metadata,
    bool? isRead,
    int? userRating,
    String? actionId,
    String? actionLabel,
  }) {
    return Insight(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      generatedAt: generatedAt ?? this.generatedAt,
      validUntil: validUntil ?? this.validUntil,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      userRating: userRating ?? this.userRating,
      actionId: actionId ?? this.actionId,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }
}
