import 'package:hive/hive.dart';

part 'correlation.g.dart';

/// Força da correlação
@HiveType(typeId: 35)
enum CorrelationStrength {
  @HiveField(0)
  none,
  @HiveField(1)
  weak,
  @HiveField(2)
  moderate,
  @HiveField(3)
  strong,
  @HiveField(4)
  veryStrong,
  @HiveField(5)
  negligible,
}

/// Correlação detectada entre duas variáveis
@HiveType(typeId: 30)
class Correlation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String variable1;

  @HiveField(2)
  final String variable1Label;

  @HiveField(3)
  final String variable2;

  @HiveField(4)
  final String variable2Label;

  @HiveField(5)
  final double coefficient;

  @HiveField(6)
  final double pValue;

  @HiveField(7)
  final int sampleSize;

  @HiveField(8)
  final CorrelationStrength strength;

  @HiveField(9)
  final DateTime calculatedAt;

  @HiveField(10)
  final String? description;

  Correlation({
    required this.id,
    required this.variable1,
    required this.variable1Label,
    required this.variable2,
    required this.variable2Label,
    required this.coefficient,
    required this.pValue,
    required this.sampleSize,
    required this.strength,
    required this.calculatedAt,
    this.description,
  });

  /// Verifica se a correlação é estatisticamente significativa
  bool get isSignificant => pValue < 0.05;

  /// Verifica se é correlação positiva
  bool get isPositive => coefficient > 0;

  /// Verifica se é correlação negativa
  bool get isNegative => coefficient < 0;

  /// Retorna porcentagem da correlação
  String get percentageText => '${(coefficient.abs() * 100).toStringAsFixed(0)}%';

  /// Texto descritivo da correlação
  String get strengthText {
    switch (strength) {
      case CorrelationStrength.none:
        return 'Sem correlação';
      case CorrelationStrength.weak:
        return 'Correlação fraca';
      case CorrelationStrength.moderate:
        return 'Correlação moderada';
      case CorrelationStrength.strong:
        return 'Correlação forte';
      case CorrelationStrength.veryStrong:
        return 'Correlação muito forte';
      case CorrelationStrength.negligible:
        return 'Correlação negligenciável';
    }
  }

  /// Ícone baseado na direção
  String get icon => isPositive ? '📈' : '📉';

  /// Alias para variable1Label (para widgets)
  String get factor1 => variable1Label;

  /// Alias para variable2Label (para widgets)
  String get factor2 => variable2Label;

  /// Classifica força baseada no coeficiente
  static CorrelationStrength classifyStrength(double r) {
    final absR = r.abs();
    if (absR < 0.1) return CorrelationStrength.none;
    if (absR < 0.3) return CorrelationStrength.weak;
    if (absR < 0.5) return CorrelationStrength.moderate;
    if (absR < 0.7) return CorrelationStrength.strong;
    return CorrelationStrength.veryStrong;
  }

  Correlation copyWith({
    String? id,
    String? variable1,
    String? variable1Label,
    String? variable2,
    String? variable2Label,
    double? coefficient,
    double? pValue,
    int? sampleSize,
    CorrelationStrength? strength,
    DateTime? calculatedAt,
    String? description,
  }) {
    return Correlation(
      id: id ?? this.id,
      variable1: variable1 ?? this.variable1,
      variable1Label: variable1Label ?? this.variable1Label,
      variable2: variable2 ?? this.variable2,
      variable2Label: variable2Label ?? this.variable2Label,
      coefficient: coefficient ?? this.coefficient,
      pValue: pValue ?? this.pValue,
      sampleSize: sampleSize ?? this.sampleSize,
      strength: strength ?? this.strength,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      description: description ?? this.description,
    );
  }
}
