import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion_enums.dart';
import 'package:odyssey/src/features/suggestions/data/suggestion_data.dart';
import 'package:odyssey/src/features/suggestions/data/suggestion_analytics_repository.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';

final suggestionRepositoryProvider = Provider<SuggestionRepository>((ref) {
  return SuggestionRepository(ref);
});

class SuggestionRepository {
  final Ref _ref;

  SuggestionRepository(this._ref);

  /// Retorna todas as sugestões
  List<Suggestion> getAllSuggestions() {
    return List.from(allSuggestions);
  }

  /// Retorna sugestões filtradas por categoria
  List<Suggestion> getSuggestionsByCategory(SuggestionCategory category) {
    return allSuggestions
        .where((s) => s.category == category)
        .toList();
  }

  /// Retorna sugestões filtradas por tipo (hábito ou tarefa)
  List<Suggestion> getSuggestionsByType(SuggestionType type) {
    return allSuggestions
        .where((s) => s.type == type)
        .toList();
  }

  /// Retorna sugestões recomendadas com base no perfil do usuário
  Future<List<Suggestion>> getRecommendedSuggestions() async {
    try {
      // 1. Obter nível do usuário
      final gamificationRepo = _ref.read(gamificationRepositoryProvider);
      final userStats = gamificationRepo.getStats();
      final userLevel = userStats.level;

      // 2. Obter atividades recentes (últimos 7 dias)
      final recentActivities = await _getRecentActivities();

      // 3. Obter humor médio recente
      final avgMoodScore = await _getAverageMoodScore();

      // 4. Obter sugestões já adicionadas
      final analyticsRepo = _ref.read(suggestionAnalyticsRepositoryProvider);
      await analyticsRepo.init();
      final addedIds = await analyticsRepo.getAddedSuggestionIds();

      // 5. Filtrar sugestões apropriadas para o nível
      var suggestions = allSuggestions
          .where((s) => s.minLevel <= userLevel)
          .where((s) => !addedIds.contains(s.id)) // Excluir já adicionadas
          .toList();

      // 6. Calcular score de relevância para cada sugestão
      final scoredSuggestions = suggestions.map((s) {
        final score = _calculateRelevanceScore(
          s,
          userLevel,
          recentActivities,
          avgMoodScore,
        );
        return MapEntry(s, score);
      }).toList();

      // 7. Ordenar por relevância
      scoredSuggestions.sort((a, b) => b.value.compareTo(a.value));

      return scoredSuggestions.map((e) => e.key).toList();
    } catch (e) {
      // Em caso de erro, retorna todas as sugestões sem filtragem
      return getAllSuggestions();
    }
  }

  /// Retorna sugestões para iniciantes (nível 1-2)
  List<Suggestion> getBeginnerSuggestions() {
    return allSuggestions
        .where((s) => s.minLevel <= 2)
        .where((s) => s.difficulty == SuggestionDifficulty.easy)
        .toList();
  }

  /// Retorna sugestões favoritas do usuário
  Future<List<Suggestion>> getFavoriteSuggestions() async {
    final analyticsRepo = _ref.read(suggestionAnalyticsRepositoryProvider);
    await analyticsRepo.init();
    final favoriteIds = await analyticsRepo.getFavoriteSuggestionIds();
    
    return allSuggestions
        .where((s) => favoriteIds.contains(s.id))
        .toList();
  }

  /// Busca sugestão por ID
  Suggestion? getSuggestionById(String id) {
    try {
      return allSuggestions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Busca sugestões por texto
  List<Suggestion> searchSuggestions(String query) {
    final lowerQuery = query.toLowerCase();
    return allSuggestions.where((s) {
      return s.title.toLowerCase().contains(lowerQuery) ||
             s.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ============================================
  // MÉTODOS AUXILIARES PRIVADOS
  // ============================================

  /// Obtém atividades recentes dos registros de humor
  Future<List<String>> _getRecentActivities() async {
    try {
      final moodRepo = _ref.read(moodRecordRepositoryProvider);
      
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final allRecords = moodRepo.fetchMoodRecords();
      final recentRecords = allRecords.values.where((record) {
        return record.date.isAfter(weekAgo);
      }).toList();

      // Extrai nomes de atividades
      final activities = <String>[];
      for (final record in recentRecords) {
        for (final activity in record.activities) {
          activities.add(activity.activityName);
        }
      }

      return activities;
    } catch (e) {
      return [];
    }
  }

  /// Calcula score médio de humor dos últimos 7 dias
  Future<double> _getAverageMoodScore() async {
    try {
      final moodRepo = _ref.read(moodRecordRepositoryProvider);
      
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final allRecords = moodRepo.fetchMoodRecords();
      final recentRecords = allRecords.values.where((record) {
        return record.date.isAfter(weekAgo);
      }).toList();

      if (recentRecords.isEmpty) return 3.0; // Neutro

      final totalScore = recentRecords.fold<int>(
        0,
        (sum, record) => sum + record.score,
      );

      return totalScore / recentRecords.length;
    } catch (e) {
      return 3.0; // Neutro em caso de erro
    }
  }

  /// Calcula score de relevância para uma sugestão
  int _calculateRelevanceScore(
    Suggestion suggestion,
    int userLevel,
    List<String> recentActivities,
    double avgMoodScore,
  ) {
    int score = 0;

    // 1. Prioriza sugestões do nível atual ou próximo (+50 ou +30)
    if (suggestion.minLevel == userLevel) {
      score += 50;
    } else if (suggestion.minLevel == userLevel + 1) {
      score += 30;
    } else if (suggestion.minLevel == userLevel - 1) {
      score += 20;
    }

    // 2. Humor baixo (< 3) → prioriza bem-estar e presença (+40)
    if (avgMoodScore < 3.0) {
      if (suggestion.category == SuggestionCategory.presence ||
          suggestion.category == SuggestionCategory.selfActualization) {
        score += 40;
      }
    }

    // 3. Humor alto (>= 4) → prioriza desafios (+30)
    if (avgMoodScore >= 4.0) {
      if (suggestion.difficulty == SuggestionDifficulty.hard) {
        score += 30;
      }
    }

    // 4. Atividades relacionadas (+30 por match)
    if (suggestion.relatedActivities != null) {
      for (final activity in suggestion.relatedActivities!) {
        if (recentActivities.contains(activity)) {
          score += 30;
          break; // Conta apenas uma vez
        }
      }
    }

    // 5. Penaliza sugestões muito difíceis para iniciantes (-100)
    if (userLevel <= 2 && suggestion.difficulty == SuggestionDifficulty.hard) {
      score -= 100;
    }

    // 6. Prioriza hábitos sobre tarefas (+10)
    if (suggestion.type == SuggestionType.habit) {
      score += 10;
    }

    // 7. Sugestões fáceis para iniciantes (+20)
    if (userLevel <= 2 && suggestion.difficulty == SuggestionDifficulty.easy) {
      score += 20;
    }

    return score;
  }
}
