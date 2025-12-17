import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/insight.dart';
import '../domain/models/user_pattern.dart';
import '../domain/models/prediction.dart';
import '../domain/models/correlation.dart';
import 'intelligence_config.dart';

/// Repository para persistência dos dados de inteligência
class UserInsightsRepository {
  static const String _insightsBoxName = IntelligenceConfig.insightsBox;
  static const String _patternsBoxName = IntelligenceConfig.patternsBox;
  static const String _predictionsBoxName = IntelligenceConfig.predictionsBox;
  static const String _correlationsBoxName = IntelligenceConfig.correlationsBox;
  static const String _metaBoxName = IntelligenceConfig.intelligenceMetaBox;

  Box<Insight>? _insightsBox;
  Box<UserPattern>? _patternsBox;
  Box<Prediction>? _predictionsBox;
  Box<Correlation>? _correlationsBox;
  Box<dynamic>? _metaBox;

  bool _isInitialized = false;

  /// Inicializa as boxes do Hive
  Future<void> initialize() async {
    if (_isInitialized) return;

    _insightsBox = await Hive.openBox<Insight>(_insightsBoxName);
    _patternsBox = await Hive.openBox<UserPattern>(_patternsBoxName);
    _predictionsBox = await Hive.openBox<Prediction>(_predictionsBoxName);
    _correlationsBox = await Hive.openBox<Correlation>(_correlationsBoxName);
    _metaBox = await Hive.openBox(_metaBoxName);

    _isInitialized = true;
  }

  // ============ INSIGHTS ============

  Future<List<Insight>> getAllInsights() async {
    await initialize();
    final insights = _insightsBox!.values.toList();
    // Remove expirados
    final valid = insights.where((i) => i.isValid).toList();
    // Ordena por prioridade e data
    valid.sort((a, b) {
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return b.generatedAt.compareTo(a.generatedAt);
    });
    return valid;
  }

  Future<void> saveInsight(Insight insight) async {
    await initialize();
    await _insightsBox!.put(insight.id, insight);
  }

  Future<void> saveInsights(List<Insight> insights) async {
    await initialize();
    final map = {for (var i in insights) i.id: i};
    await _insightsBox!.putAll(map);
  }

  Future<void> deleteInsight(String id) async {
    await initialize();
    await _insightsBox!.delete(id);
  }

  Future<void> markInsightAsRead(String id) async {
    await initialize();
    final insight = _insightsBox!.get(id);
    if (insight != null) {
      insight.isRead = true;
      await insight.save();
    }
  }

  Future<void> rateInsight(String id, int rating) async {
    await initialize();
    final insight = _insightsBox!.get(id);
    if (insight != null) {
      insight.userRating = rating;
      await insight.save();
    }
  }

  Future<List<Insight>> getUnreadInsights() async {
    final all = await getAllInsights();
    return all.where((i) => !i.isRead).toList();
  }

  Future<int> getUnreadCount() async {
    final unread = await getUnreadInsights();
    return unread.length;
  }

  // ============ PATTERNS ============

  Future<List<UserPattern>> getAllPatterns() async {
    await initialize();
    return _patternsBox!.values.toList();
  }

  Future<void> savePattern(UserPattern pattern) async {
    await initialize();
    await _patternsBox!.put(pattern.id, pattern);
  }

  Future<void> savePatterns(List<UserPattern> patterns) async {
    await initialize();
    // Limpa padrões antigos se exceder limite
    if (_patternsBox!.length + patterns.length > IntelligenceConfig.maxPatternsStored) {
      await _cleanOldPatterns();
    }
    final map = {for (var p in patterns) p.id: p};
    await _patternsBox!.putAll(map);
  }

  Future<void> updatePatternOccurrence(String id) async {
    await initialize();
    final pattern = _patternsBox!.get(id);
    if (pattern != null) {
      pattern.occurrences++;
      pattern.lastConfirmed = DateTime.now();
      await pattern.save();
    }
  }

  Future<void> _cleanOldPatterns() async {
    final patterns = _patternsBox!.values.toList();
    patterns.sort((a, b) => a.lastConfirmed.compareTo(b.lastConfirmed));

    final toRemove = patterns.take(patterns.length ~/ 2);
    for (final p in toRemove) {
      await _patternsBox!.delete(p.id);
    }
  }

  // ============ PREDICTIONS ============

  Future<List<Prediction>> getAllPredictions() async {
    await initialize();
    final predictions = _predictionsBox!.values.toList();
    // Remove expiradas
    return predictions.where((p) => !p.hasExpired).toList();
  }

  Future<List<Prediction>> getActivePredictions() async {
    final all = await getAllPredictions();
    return all.where((p) => p.predictedFor.isAfter(DateTime.now())).toList();
  }

  Future<void> savePrediction(Prediction prediction) async {
    await initialize();
    await _predictionsBox!.put(prediction.id, prediction);
  }

  Future<void> savePredictions(List<Prediction> predictions) async {
    await initialize();
    final map = {for (var p in predictions) p.id: p};
    await _predictionsBox!.putAll(map);
  }

  Future<void> markPredictionAccuracy(String id, bool wasAccurate) async {
    await initialize();
    final prediction = _predictionsBox!.get(id);
    if (prediction != null) {
      await _predictionsBox!.put(
        id,
        prediction.copyWith(wasAccurate: wasAccurate),
      );
    }
  }

  // ============ CORRELATIONS ============

  Future<List<Correlation>> getAllCorrelations() async {
    await initialize();
    final correlations = _correlationsBox!.values.toList();
    // Ordena por força
    correlations.sort((a, b) => b.coefficient.abs().compareTo(a.coefficient.abs()));
    return correlations;
  }

  Future<List<Correlation>> getSignificantCorrelations() async {
    final all = await getAllCorrelations();
    return all.where((c) => c.isSignificant).toList();
  }

  Future<void> saveCorrelation(Correlation correlation) async {
    await initialize();
    await _correlationsBox!.put(correlation.id, correlation);
  }

  Future<void> saveCorrelations(List<Correlation> correlations) async {
    await initialize();
    final map = {for (var c in correlations) c.id: c};
    await _correlationsBox!.putAll(map);
  }

  // ============ META ============

  Future<AnalysisMeta?> getAnalysisMeta() async {
    await initialize();
    final data = _metaBox!.get('analysis_meta');
    if (data == null) return null;
    return AnalysisMeta.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveAnalysisMeta(AnalysisMeta meta) async {
    await initialize();
    await _metaBox!.put('analysis_meta', meta.toJson());
  }

  Future<bool> needsAnalysis() async {
    final meta = await getAnalysisMeta();
    if (meta == null) return true;
    return meta.needsRefresh;
  }

  // ============ CLEANUP ============

  Future<void> cleanExpiredData() async {
    await initialize();

    // Remove insights expirados
    final expiredInsights = _insightsBox!.values
        .where((i) => !i.isValid)
        .map((i) => i.id)
        .toList();
    for (final id in expiredInsights) {
      await _insightsBox!.delete(id);
    }

    // Remove previsões expiradas
    final expiredPredictions = _predictionsBox!.values
        .where((p) => p.hasExpired)
        .map((p) => p.id)
        .toList();
    for (final id in expiredPredictions) {
      await _predictionsBox!.delete(id);
    }
  }

  Future<void> clearAll() async {
    await initialize();
    await _insightsBox!.clear();
    await _patternsBox!.clear();
    await _predictionsBox!.clear();
    await _correlationsBox!.clear();
    await _metaBox!.clear();
  }

  // ============ STATS ============

  Future<Map<String, int>> getStats() async {
    await initialize();
    return {
      'insights': _insightsBox!.length,
      'patterns': _patternsBox!.length,
      'predictions': _predictionsBox!.length,
      'correlations': _correlationsBox!.length,
    };
  }

  Future<double> getPredictionAccuracy() async {
    await initialize();
    final predictions = _predictionsBox!.values
        .where((p) => p.wasAccurate != null)
        .toList();

    if (predictions.isEmpty) return 0;

    final accurate = predictions.where((p) => p.wasAccurate == true).length;
    return accurate / predictions.length;
  }
}

// Provider
final userInsightsRepositoryProvider = Provider<UserInsightsRepository>((ref) {
  return UserInsightsRepository();
});
