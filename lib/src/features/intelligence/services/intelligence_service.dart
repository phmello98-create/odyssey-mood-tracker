import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/intelligence_config.dart';
import '../data/intelligence_data_adapter.dart';
import '../domain/models/insight.dart';
import '../domain/models/user_pattern.dart';
import '../domain/models/prediction.dart';
import '../domain/models/correlation.dart';
import '../domain/engines/pattern_engine.dart';
import '../domain/engines/correlation_engine.dart';
import '../domain/engines/recommendation_engine.dart';
import '../domain/engines/prediction_engine.dart';

/// Serviço principal de inteligência que orquestra todos os engines
class IntelligenceService {
  final PatternEngine _patternEngine = PatternEngine();
  final CorrelationEngine _correlationEngine = CorrelationEngine();
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final PredictionEngine _predictionEngine = PredictionEngine();

  // Cache em memória
  List<Insight> _cachedInsights = [];
  List<UserPattern> _cachedPatterns = [];
  List<Correlation> _cachedCorrelations = [];
  List<Prediction> _cachedPredictions = [];
  DateTime? _lastAnalysis;

  /// Executa análise completa
  Future<AnalysisResult> runFullAnalysis({
    required List<MoodDataPoint> moodData,
    required List<ActivityDataPoint> activityData,
    required List<DailyDataPoint> dailyData,
    required List<MoodTimePoint> moodTimeData,
    required Map<String, String> activityNames,
    required Map<String, HabitData> habitsData,
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Verifica se precisa refresh
    if (!forceRefresh && _lastAnalysis != null) {
      final hoursSince = DateTime.now().difference(_lastAnalysis!).inHours;
      if (hoursSince < 12) {
        return AnalysisResult(
          patterns: _cachedPatterns,
          correlations: _cachedCorrelations,
          insights: _cachedInsights,
          predictions: _cachedPredictions,
          analyzedAt: _lastAnalysis!,
          processingTime: Duration.zero,
          fromCache: true,
        );
      }
    }

    try {
      // 1. Detecta padrões
      final patterns = _patternEngine.detectTemporalPatterns(
        moodData: moodData,
        activityData: activityData,
        activityNames: activityNames,
      );
      _cachedPatterns = patterns;

      // 2. Calcula correlações
      final correlations = _correlationEngine.calculateAllCorrelations(
        dailyData: dailyData,
        moodTimeData: moodTimeData,
        activityNames: activityNames,
      );
      _cachedCorrelations = correlations;

      // 3. Gera previsões
      final predictions = <Prediction>[];

      // Previsão de humor
      final moodPrediction = _predictionEngine.predictMoodForTomorrow(
        last14Days: moodData.length > 14 ? moodData.sublist(moodData.length - 14) : moodData,
        patterns: patterns,
      );
      if (moodPrediction != null) predictions.add(moodPrediction);

      // Previsão de streaks para cada hábito
      for (final entry in habitsData.entries) {
        final streakPrediction = _predictionEngine.predictStreakBreak(
          habitId: entry.key,
          habitName: entry.value.name,
          currentStreak: entry.value.currentStreak,
          last30DaysCompleted: entry.value.last30Days,
          patterns: patterns,
        );
        if (streakPrediction != null) predictions.add(streakPrediction);
      }

      _cachedPredictions = predictions;

      // 4. Gera insights
      final insights = _generateInsights(
        patterns: patterns,
        correlations: correlations,
        predictions: predictions,
        moodData: moodData,
      );
      _cachedInsights = insights;

      _lastAnalysis = DateTime.now();
      stopwatch.stop();

      return AnalysisResult(
        patterns: patterns,
        correlations: correlations,
        insights: insights,
        predictions: predictions,
        analyzedAt: _lastAnalysis!,
        processingTime: stopwatch.elapsed,
        fromCache: false,
      );
    } catch (e, stack) {
      debugPrint('[IntelligenceService] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Gera insights a partir dos dados analisados
  List<Insight> _generateInsights({
    required List<UserPattern> patterns,
    required List<Correlation> correlations,
    required List<Prediction> predictions,
    required List<MoodDataPoint> moodData,
  }) {
    final insights = <Insight>[];
    final now = DateTime.now();
    final validUntil = now.add(IntelligenceConfig.insightValidity);

    // Insights de padrões
    for (final pattern in patterns.where((p) => p.strength >= 0.5)) {
      insights.add(Insight(
        id: 'insight_pattern_${pattern.id}',
        title: '${pattern.icon} Padrão Detectado',
        description: pattern.description,
        type: InsightType.pattern,
        priority: pattern.isStrong ? InsightPriority.high : InsightPriority.medium,
        confidence: pattern.strength,
        generatedAt: now,
        validUntil: validUntil,
        metadata: pattern.data,
      ));
    }

    // Insights de correlações fortes
    for (final corr in correlations.where((c) =>
        c.strength == CorrelationStrength.strong ||
        c.strength == CorrelationStrength.veryStrong)) {
      insights.add(Insight(
        id: 'insight_corr_${corr.id}',
        title: '${corr.icon} ${corr.variable1Label} & ${corr.variable2Label}',
        description: corr.description ?? corr.strengthText,
        type: InsightType.correlation,
        priority: InsightPriority.high,
        confidence: corr.coefficient.abs(),
        generatedAt: now,
        validUntil: validUntil,
        metadata: {
          'coefficient': corr.coefficient,
          'pValue': corr.pValue,
          'sampleSize': corr.sampleSize,
        },
      ));
    }

    // Insights de previsões (warnings)
    for (final pred in predictions.where((p) => p.isHighRisk && !p.isPositive)) {
      insights.add(Insight(
        id: 'insight_pred_${pred.id}',
        title: '${pred.icon} ${pred.typeLabel}',
        description: pred.reasoning,
        type: InsightType.warning,
        priority: InsightPriority.urgent,
        confidence: pred.probability,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 24)),
        metadata: {
          'targetId': pred.targetId,
          'targetName': pred.targetName,
          'probability': pred.probability,
        },
        actionLabel: 'Ver hábito',
        actionId: pred.targetId,
      ));
    }

    // Insights positivos (celebrações)
    for (final pred in predictions.where((p) => p.isPositive && p.probability > 0.7)) {
      insights.add(Insight(
        id: 'insight_celebration_${pred.id}',
        title: '${pred.icon} ${pred.typeLabel}',
        description: pred.reasoning,
        type: InsightType.celebration,
        priority: InsightPriority.low,
        confidence: pred.probability,
        generatedAt: now,
        validUntil: now.add(const Duration(hours: 24)),
        metadata: pred.features,
      ));
    }

    // Insight de dados insuficientes
    if (moodData.length < IntelligenceConfig.minDataPointsForPattern) {
      insights.insert(
        0,
        Insight(
          id: 'insight_need_data',
          title: '📊 Continue Registrando',
          description:
              'Precisamos de ${IntelligenceConfig.minDataPointsForPattern - moodData.length} dias mais de dados para gerar insights personalizados.',
          type: InsightType.recommendation,
          priority: InsightPriority.medium,
          confidence: 1.0,
          generatedAt: now,
          validUntil: validUntil,
        ),
      );
    }

    // Ordena por prioridade e confiança
    insights.sort((a, b) {
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return b.confidence.compareTo(a.confidence);
    });

    return insights.take(IntelligenceConfig.maxInsightsGenerated).toList();
  }

  /// Retorna insight do dia (mais relevante)
  Insight? getDailyInsight() {
    if (_cachedInsights.isEmpty) return null;

    // Prioriza warnings não lidos
    final unreadWarnings = _cachedInsights
        .where((i) => !i.isRead && i.type == InsightType.warning);
    if (unreadWarnings.isNotEmpty) return unreadWarnings.first;

    // Depois insights de alta prioridade
    final highPriority =
        _cachedInsights.where((i) => !i.isRead && i.isHighPriority);
    if (highPriority.isNotEmpty) return highPriority.first;

    // Qualquer não lido
    final unread = _cachedInsights.where((i) => !i.isRead);
    if (unread.isNotEmpty) return unread.first;

    // Retorna o primeiro
    return _cachedInsights.first;
  }

  /// Retorna recomendações contextuais
  List<DailyRecommendation> getRecommendations() {
    return _recommendationEngine.generateDailyRecommendations(
      patterns: _cachedPatterns,
      correlations: _cachedCorrelations,
      today: DateTime.now(),
    );
  }

  /// Marca insight como lido
  void markInsightAsRead(String insightId) {
    final index = _cachedInsights.indexWhere((i) => i.id == insightId);
    if (index != -1) {
      _cachedInsights[index].isRead = true;
    }
  }

  /// Dá rating em um insight
  void rateInsight(String insightId, int rating) {
    final index = _cachedInsights.indexWhere((i) => i.id == insightId);
    if (index != -1) {
      _cachedInsights[index].userRating = rating;
    }
  }

  /// Limpa cache
  void clearCache() {
    _cachedInsights.clear();
    _cachedPatterns.clear();
    _cachedCorrelations.clear();
    _cachedPredictions.clear();
    _lastAnalysis = null;
  }

  // Getters
  List<Insight> get insights => List.unmodifiable(_cachedInsights);
  List<UserPattern> get patterns => List.unmodifiable(_cachedPatterns);
  List<Correlation> get correlations => List.unmodifiable(_cachedCorrelations);
  List<Prediction> get predictions => List.unmodifiable(_cachedPredictions);
  DateTime? get lastAnalysis => _lastAnalysis;
  bool get hasData => _cachedInsights.isNotEmpty;
}

/// Resultado da análise
class AnalysisResult {
  final List<UserPattern> patterns;
  final List<Correlation> correlations;
  final List<Insight> insights;
  final List<Prediction> predictions;
  final DateTime analyzedAt;
  final Duration processingTime;
  final bool fromCache;

  AnalysisResult({
    required this.patterns,
    required this.correlations,
    required this.insights,
    required this.predictions,
    required this.analyzedAt,
    required this.processingTime,
    this.fromCache = false,
  });

  int get totalPatterns => patterns.length;
  int get totalCorrelations => correlations.length;
  int get totalInsights => insights.length;
  int get totalPredictions => predictions.length;

  bool get hasSignificantFindings =>
      patterns.any((p) => p.isStrong) ||
      correlations.any((c) =>
          c.strength == CorrelationStrength.strong ||
          c.strength == CorrelationStrength.veryStrong);
}

/// Dados de hábito para previsão
class HabitData {
  final String id;
  final String name;
  final int currentStreak;
  final List<bool> last30Days;

  HabitData({
    required this.id,
    required this.name,
    required this.currentStreak,
    required this.last30Days,
  });
}

// Provider
final intelligenceServiceProvider = Provider<IntelligenceService>((ref) {
  return IntelligenceService();
});

// Provider para análise completa conectado aos dados reais
final intelligenceAnalysisProvider = FutureProvider.autoDispose<AnalysisResult?>((ref) async {
  final dataAsync = ref.watch(intelligenceDataProvider);
  
  return dataAsync.when(
    data: (data) async {
      if (data == null || !data.hasEnoughData) {
        return null;
      }
      
      final service = ref.read(intelligenceServiceProvider);
      
      return await service.runFullAnalysis(
        moodData: data.moodData,
        activityData: data.activityData,
        dailyData: data.dailyData,
        moodTimeData: data.moodTimeData,
        activityNames: data.activityNames,
        habitsData: data.habitsData,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
