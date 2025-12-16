// lib/src/features/gamification/data/synced_gamification_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_stats.dart';
import '../domain/user_skills.dart';
import 'gamification_repository.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline
class SyncedGamificationRepository with SyncedRepositoryMixin {
  final GamificationRepository _localRepository;
  @override
  final Ref ref;
  
  @override
  String get collectionName => 'gamification';
  
  SyncedGamificationRepository(this._localRepository, this.ref);
  
  // ============================================
  // MÉTODOS DE LEITURA (não precisam de sync)
  // ============================================
  
  UserStats getStats() => _localRepository.getStats();
  
  List<SkillCategory> getSkillCategories() => _localRepository.getSkillCategories();
  
  Skill? findSkill(String skillId) => _localRepository.findSkill(skillId);
  
  List<(GameBadge, bool)> getAllBadgesWithStatus() => 
      _localRepository.getAllBadgesWithStatus();
  
  // ============================================
  // MÉTODOS DE ESCRITA (com sync)
  // ============================================
  
  /// Salva stats e enfileira para sync
  Future<void> saveStats(UserStats stats) async {
    await _localRepository.saveStats(stats);
    await _enqueueGamificationData();
  }
  
  /// Adiciona XP geral e enfileira para sync
  Future<UserStats> addXP(int xp) async {
    final result = await _localRepository.addXP(xp);
    await _enqueueGamificationData();
    return result;
  }
  
  /// Atualiza streak e enfileira para sync
  Future<UserStats> updateStreak() async {
    final result = await _localRepository.updateStreak();
    await _enqueueGamificationData();
    return result;
  }
  
  /// Adiciona XP a uma skill e enfileira para sync
  Future<({bool leveledUp, int newLevel})> addXpToSkill(String skillId, int xp) async {
    final result = await _localRepository.addXpToSkill(skillId, xp);
    await _enqueueGamificationData();
    return result;
  }
  
  /// Registra mood e enfileira para sync
  Future<GamificationResult> recordMood() async {
    final result = await _localRepository.recordMood();
    await _enqueueGamificationData();
    return result;
  }
  
  /// Completa task e enfileira para sync
  Future<GamificationResult> completeTask() async {
    final result = await _localRepository.completeTask();
    await _enqueueGamificationData();
    return result;
  }
  
  /// Completa sessão pomodoro e enfileira para sync
  Future<GamificationResult> completePomodoroSession() async {
    final result = await _localRepository.completePomodoroSession();
    await _enqueueGamificationData();
    return result;
  }
  
  /// Registra tempo e enfileira para sync
  Future<GamificationResult> trackTime(int minutes) async {
    final result = await _localRepository.trackTime(minutes);
    await _enqueueGamificationData();
    return result;
  }
  
  /// Cria nota e enfileira para sync
  Future<GamificationResult> createNote() async {
    final result = await _localRepository.createNote();
    await _enqueueGamificationData();
    return result;
  }
  
  /// Completa hábito e enfileira para sync
  Future<GamificationResult> completeHabit() async {
    final result = await _localRepository.completeHabit();
    await _enqueueGamificationData();
    return result;
  }
  
  /// Completa livro e enfileira para sync
  Future<GamificationResult> completeBook() async {
    final result = await _localRepository.completeBook();
    await _enqueueGamificationData();
    return result;
  }
  
  /// Verifica badges de streak e enfileira para sync
  Future<List<GameBadge>> checkStreakBadges() async {
    final result = await _localRepository.checkStreakBadges();
    if (result.isNotEmpty) {
      await _enqueueGamificationData();
    }
    return result;
  }
  
  /// Verifica badges de sugestões e enfileira para sync
  Future<List<GameBadge>> checkSuggestionBadges(int totalSuggestionsAccepted) async {
    final result = await _localRepository.checkSuggestionBadges(totalSuggestionsAccepted);
    if (result.isNotEmpty) {
      await _enqueueGamificationData();
    }
    return result;
  }
  
  /// Seed demo data e enfileira para sync (para testes)
  Future<void> seedDemoData() async {
    await _localRepository.seedDemoData();
    await _enqueueGamificationData();
  }
  
  // ============================================
  // SYNC HELPERS
  // ============================================
  
  /// Enfileira dados de gamificação para sync
  /// Gamificação é um documento único, não uma coleção
  Future<void> _enqueueGamificationData() async {
    if (!canSync) return;
    
    final stats = _localRepository.getStats();
    final data = _statsToMap(stats);
    
    await enqueueUpdate('data', data);
  }
  
  Map<String, dynamic> _statsToMap(UserStats stats) {
    return {
      'totalXP': stats.totalXP,
      'level': stats.level,
      'currentStreak': stats.currentStreak,
      'longestStreak': stats.longestStreak,
      'lastActiveDate': stats.lastActiveDate?.toIso8601String(),
      'moodRecordsCount': stats.moodRecordsCount,
      'tasksCompleted': stats.tasksCompleted,
      'pomodoroSessions': stats.pomodoroSessions,
      'timeTrackedMinutes': stats.timeTrackedMinutes,
      'notesCreated': stats.notesCreated,
      'unlockedBadges': stats.unlockedBadges,
      '_localModifiedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider para o SyncedGamificationRepository
final syncedGamificationRepositoryProvider = Provider<SyncedGamificationRepository>((ref) {
  final localRepository = ref.watch(gamificationRepositoryProvider);
  return SyncedGamificationRepository(localRepository, ref);
});
