import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion_analytics.dart';

final suggestionAnalyticsRepositoryProvider = Provider<SuggestionAnalyticsRepository>((ref) {
  return SuggestionAnalyticsRepository();
});

class SuggestionAnalyticsRepository {
  static const String _boxName = 'suggestion_analytics';
  Box<SuggestionAnalytics>? _box;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(SuggestionAnalyticsAdapter());
    }
    
    _box = await Hive.openBox<SuggestionAnalytics>(_boxName);
    _isInitialized = true;
  }

  Future<Box<SuggestionAnalytics>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Retorna analytics para uma sugestão específica
  Future<SuggestionAnalytics> getAnalytics(String suggestionId) async {
    final box = await _ensureBox();
    var analytics = box.get(suggestionId);
    
    if (analytics == null) {
      analytics = SuggestionAnalytics(suggestionId: suggestionId);
      await box.put(suggestionId, analytics);
    }
    
    return analytics;
  }

  /// Marca/desmarca sugestão como favorita (estrela)
  Future<void> toggleFavorite(String suggestionId) async {
    final analytics = await getAnalytics(suggestionId);
    
    if (analytics.isMarked) {
      analytics.unmarkAsFavorite();
    } else {
      analytics.markAsFavorite();
    }
  }

  /// Marca sugestão como adicionada (criou hábito/tarefa)
  Future<void> markAsAdded(String suggestionId) async {
    final analytics = await getAnalytics(suggestionId);
    analytics.markAsAdded();
  }

  /// Desmarca sugestão como adicionada (removeu hábito/tarefa)
  Future<void> unmarkAsAdded(String suggestionId) async {
    final analytics = await getAnalytics(suggestionId);
    analytics.unmarkAsAdded();
  }

  /// Incrementa contador de visualizações
  Future<void> recordView(String suggestionId) async {
    final analytics = await getAnalytics(suggestionId);
    analytics.incrementViewCount();
  }

  /// Retorna todas as sugestões marcadas como favoritas
  Future<List<String>> getFavoriteSuggestionIds() async {
    final box = await _ensureBox();
    return box.values
        .where((a) => a.isMarked)
        .map((a) => a.suggestionId)
        .toList();
  }

  /// Retorna todas as sugestões já adicionadas
  Future<List<String>> getAddedSuggestionIds() async {
    final box = await _ensureBox();
    return box.values
        .where((a) => a.isAdded)
        .map((a) => a.suggestionId)
        .toList();
  }

  /// Retorna contagem total de sugestões aceitas (para badges)
  Future<int> getTotalAddedCount() async {
    final box = await _ensureBox();
    return box.values.where((a) => a.isAdded).length;
  }

  /// Retorna sugestões mais visualizadas
  Future<List<String>> getMostViewedSuggestionIds({int limit = 10}) async {
    final box = await _ensureBox();
    final sorted = box.values.toList()
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    
    return sorted
        .take(limit)
        .map((a) => a.suggestionId)
        .toList();
  }

  /// Limpa todos os dados de analytics
  Future<void> clearAll() async {
    final box = await _ensureBox();
    await box.clear();
  }
}
