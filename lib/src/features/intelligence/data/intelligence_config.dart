/// Configurações do sistema de inteligência
class IntelligenceConfig {
  IntelligenceConfig._();

  // ============ ANÁLISE ============

  /// Mínimo de dias de dados para detectar padrões
  static const int minDataPointsForPattern = 7;

  /// Mínimo de dias de dados para calcular correlações
  static const int minDataPointsForCorrelation = 14;

  /// Correlação mínima para ser considerada (|r| > 0.3)
  static const double minCorrelationThreshold = 0.3;

  /// Confiança mínima para exibir insight (60%)
  static const double minConfidenceThreshold = 0.6;

  /// P-value máximo para significância estatística
  static const double maxPValue = 0.05;

  // ============ CACHE ============

  /// Validade de um insight (1 dia)
  static const Duration insightValidity = Duration(days: 1);

  /// Validade de um padrão detectado (7 dias)
  static const Duration patternValidity = Duration(days: 7);

  /// Validade de uma previsão (12 horas)
  static const Duration predictionValidity = Duration(hours: 12);

  /// Validade de uma correlação (3 dias)
  static const Duration correlationValidity = Duration(days: 3);

  // ============ PERFORMANCE ============

  /// Máximo de insights gerados por análise
  static const int maxInsightsGenerated = 10;

  /// Máximo de padrões armazenados em cache
  static const int maxPatternsStored = 50;

  /// Máximo de correlações armazenadas
  static const int maxCorrelationsStored = 30;

  /// Máximo de previsões ativas
  static const int maxPredictionsStored = 20;

  /// Timeout para análise completa
  static const Duration analysisTimeout = Duration(seconds: 5);

  // ============ UI ============

  /// Insights por página na UI
  static const int insightsPerPage = 5;

  /// Mostrar insights de baixa confiança?
  static const bool showLowConfidenceInsights = false;

  /// Dias de histórico a analisar
  static const int daysToAnalyze = 30;

  // ============ HIVE BOXES ============

  static const String insightsBox = 'insights';
  static const String patternsBox = 'user_patterns';
  static const String predictionsBox = 'predictions';
  static const String correlationsBox = 'correlations';
  static const String intelligenceMetaBox = 'intelligence_meta';
}

/// Metadados da análise
class AnalysisMeta {
  final DateTime lastAnalysis;
  final int totalInsightsGenerated;
  final int totalPatternsDetected;
  final int totalCorrelationsFound;
  final Duration lastAnalysisDuration;

  AnalysisMeta({
    required this.lastAnalysis,
    this.totalInsightsGenerated = 0,
    this.totalPatternsDetected = 0,
    this.totalCorrelationsFound = 0,
    this.lastAnalysisDuration = Duration.zero,
  });

  bool get needsRefresh {
    final hoursSinceLastAnalysis =
        DateTime.now().difference(lastAnalysis).inHours;
    return hoursSinceLastAnalysis >= 12;
  }

  Map<String, dynamic> toJson() => {
        'lastAnalysis': lastAnalysis.toIso8601String(),
        'totalInsightsGenerated': totalInsightsGenerated,
        'totalPatternsDetected': totalPatternsDetected,
        'totalCorrelationsFound': totalCorrelationsFound,
        'lastAnalysisDurationMs': lastAnalysisDuration.inMilliseconds,
      };

  factory AnalysisMeta.fromJson(Map<String, dynamic> json) => AnalysisMeta(
        lastAnalysis: DateTime.parse(json['lastAnalysis'] as String),
        totalInsightsGenerated: json['totalInsightsGenerated'] as int? ?? 0,
        totalPatternsDetected: json['totalPatternsDetected'] as int? ?? 0,
        totalCorrelationsFound: json['totalCorrelationsFound'] as int? ?? 0,
        lastAnalysisDuration:
            Duration(milliseconds: json['lastAnalysisDurationMs'] as int? ?? 0),
      );
}
