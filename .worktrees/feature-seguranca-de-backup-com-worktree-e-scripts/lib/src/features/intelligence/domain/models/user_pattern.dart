import 'package:hive/hive.dart';

part 'user_pattern.g.dart';

/// Tipo de padrão detectado
@HiveType(typeId: 33)
enum PatternType {
  @HiveField(0)
  temporal,
  @HiveField(1)
  behavioral,
  @HiveField(2)
  correlation,
  @HiveField(3)
  cyclical,
}

/// Padrão de comportamento detectado no usuário
@HiveType(typeId: 28)
class UserPattern extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final PatternType type;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double strength;

  @HiveField(4)
  final Map<String, dynamic> data;

  @HiveField(5)
  final DateTime firstDetected;

  @HiveField(6)
  DateTime lastConfirmed;

  @HiveField(7)
  int occurrences;

  @HiveField(8)
  final String? relatedFeature;

  UserPattern({
    required this.id,
    required this.type,
    required this.description,
    required this.strength,
    this.data = const {},
    required this.firstDetected,
    required this.lastConfirmed,
    this.occurrences = 1,
    this.relatedFeature,
  });

  /// Verifica se é um padrão forte
  bool get isStrong => strength >= 0.7;

  /// Verifica se é um padrão consistente (muitas ocorrências)
  bool get isConsistent => occurrences >= 5;

  /// Calcula idade do padrão em dias
  int get ageInDays => DateTime.now().difference(firstDetected).inDays;

  /// Ícone baseado no tipo
  String get icon {
    switch (type) {
      case PatternType.temporal:
        return '🕐';
      case PatternType.behavioral:
        return '🎯';
      case PatternType.correlation:
        return '🔗';
      case PatternType.cyclical:
        return '🔄';
    }
  }

  UserPattern copyWith({
    String? id,
    PatternType? type,
    String? description,
    double? strength,
    Map<String, dynamic>? data,
    DateTime? firstDetected,
    DateTime? lastConfirmed,
    int? occurrences,
    String? relatedFeature,
  }) {
    return UserPattern(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      strength: strength ?? this.strength,
      data: data ?? this.data,
      firstDetected: firstDetected ?? this.firstDetected,
      lastConfirmed: lastConfirmed ?? this.lastConfirmed,
      occurrences: occurrences ?? this.occurrences,
      relatedFeature: relatedFeature ?? this.relatedFeature,
    );
  }
}
