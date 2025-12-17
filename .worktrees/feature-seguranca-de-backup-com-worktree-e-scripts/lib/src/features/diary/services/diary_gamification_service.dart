// lib/src/features/diary/services/diary_gamification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/diary_entry_entity.dart';
import '../domain/entities/diary_statistics.dart';
import '../data/synced_diary_repository.dart';

/// Definição de conquista do diário
class DiaryAchievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int requiredValue;
  final bool Function(DiaryStatistics, DiaryEntryEntity?) checkUnlock;

  const DiaryAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.requiredValue,
    required this.checkUnlock,
  });
}

/// XP concedido por ações
class DiaryXpReward {
  static const int createEntry = 10;
  static const int longEntry = 20; // 500+ palavras
  static const int addPhoto = 5;
  static const int weekStreak = 50;
  static const int monthStreak = 200;
  static const int useTemplate = 5;
  static const int addTags = 2;
}

/// Serviço de gamificação do diário
class DiaryGamificationService {
  final SyncedDiaryRepository _repository;

  DiaryGamificationService(this._repository);

  /// Conquistas disponíveis
  static final List<DiaryAchievement> achievements = [
    DiaryAchievement(
      id: 'first_entry',
      title: 'Primeiro Diário',
      description: 'Crie sua primeira entrada no diário',
      emoji: '📝',
      requiredValue: 1,
      checkUnlock: (stats, _) => stats.totalEntries >= 1,
    ),
    DiaryAchievement(
      id: 'dedicated_writer',
      title: 'Escritor Assíduo',
      description: '7 dias consecutivos escrevendo',
      emoji: '🔥',
      requiredValue: 7,
      checkUnlock: (stats, _) => stats.currentStreak >= 7,
    ),
    DiaryAchievement(
      id: 'vivid_memories',
      title: 'Memórias Vívidas',
      description: 'Escreva 50 entradas',
      emoji: '💭',
      requiredValue: 50,
      checkUnlock: (stats, _) => stats.totalEntries >= 50,
    ),
    DiaryAchievement(
      id: 'historian',
      title: 'Historiador',
      description: 'Escreva 100 entradas',
      emoji: '📚',
      requiredValue: 100,
      checkUnlock: (stats, _) => stats.totalEntries >= 100,
    ),
    DiaryAchievement(
      id: 'reflective',
      title: 'Reflexivo',
      description: 'Use 20 tags diferentes',
      emoji: '🏷️',
      requiredValue: 20,
      checkUnlock: (stats, _) => stats.entriesByTag.length >= 20,
    ),
    DiaryAchievement(
      id: 'photographer',
      title: 'Fotógrafo',
      description: 'Anexe 50 fotos às suas entradas',
      emoji: '📸',
      requiredValue: 50,
      checkUnlock: (stats, _) => stats.totalPhotos >= 50,
    ),
    DiaryAchievement(
      id: 'marathon_writer',
      title: 'Maratonista',
      description: 'Escreva 1000+ palavras em uma entrada',
      emoji: '✍️',
      requiredValue: 1000,
      checkUnlock: (_, entry) => entry != null && entry.effectiveWordCount >= 1000,
    ),
    DiaryAchievement(
      id: 'month_streak',
      title: 'Compromisso Mensal',
      description: '30 dias consecutivos escrevendo',
      emoji: '🏆',
      requiredValue: 30,
      checkUnlock: (stats, _) => stats.currentStreak >= 30,
    ),
    DiaryAchievement(
      id: 'word_master',
      title: 'Mestre das Palavras',
      description: 'Escreva mais de 10.000 palavras no total',
      emoji: '📖',
      requiredValue: 10000,
      checkUnlock: (stats, _) => stats.totalWords >= 10000,
    ),
    DiaryAchievement(
      id: 'year_writer',
      title: 'Um Ano de Memórias',
      description: 'Mantenha o diário por 365 dias',
      emoji: '🎉',
      requiredValue: 365,
      checkUnlock: (stats, _) {
        if (stats.firstEntryDate == null) return false;
        final daysSinceFirst = DateTime.now().difference(stats.firstEntryDate!).inDays;
        return daysSinceFirst >= 365;
      },
    ),
  ];

  /// Calcula XP ganho ao criar/atualizar uma entrada
  Future<int> calculateXpForEntry(DiaryEntryEntity entry, {bool isNew = true}) async {
    int totalXp = 0;

    if (isNew) {
      // XP base por criar entrada
      totalXp += DiaryXpReward.createEntry;
      debugPrint('[DiaryGamification] +${DiaryXpReward.createEntry} XP (nova entrada)');

      // XP extra por entrada longa
      if (entry.effectiveWordCount >= 500) {
        totalXp += DiaryXpReward.longEntry;
        debugPrint('[DiaryGamification] +${DiaryXpReward.longEntry} XP (entrada longa)');
      }

      // XP por adicionar fotos
      if (entry.photoIds.isNotEmpty) {
        totalXp += DiaryXpReward.addPhoto * entry.photoIds.length;
        debugPrint('[DiaryGamification] +${DiaryXpReward.addPhoto * entry.photoIds.length} XP (fotos)');
      }

      // XP por usar tags
      if (entry.tags.isNotEmpty) {
        totalXp += DiaryXpReward.addTags * entry.tags.length.clamp(0, 5);
        debugPrint('[DiaryGamification] +${DiaryXpReward.addTags * entry.tags.length.clamp(0, 5)} XP (tags)');
      }

      // XP por usar template
      if (entry.templateId != null) {
        totalXp += DiaryXpReward.useTemplate;
        debugPrint('[DiaryGamification] +${DiaryXpReward.useTemplate} XP (template)');
      }
    }

    return totalXp;
  }

  /// Calcula XP por streak
  Future<int> calculateStreakXp() async {
    final stats = await _repository.getStatistics();
    int streakXp = 0;

    // XP por streak semanal (apenas na primeira vez atingindo)
    if (stats.currentStreak == 7) {
      streakXp += DiaryXpReward.weekStreak;
      debugPrint('[DiaryGamification] +${DiaryXpReward.weekStreak} XP (streak semanal)');
    }

    // XP por streak mensal (apenas na primeira vez atingindo)
    if (stats.currentStreak == 30) {
      streakXp += DiaryXpReward.monthStreak;
      debugPrint('[DiaryGamification] +${DiaryXpReward.monthStreak} XP (streak mensal)');
    }

    return streakXp;
  }

  /// Verifica conquistas desbloqueadas
  Future<List<DiaryAchievement>> checkUnlockedAchievements({
    DiaryEntryEntity? entry,
    List<String>? alreadyUnlocked,
  }) async {
    final stats = await _repository.getStatistics();
    final unlocked = <DiaryAchievement>[];

    for (final achievement in achievements) {
      // Pular se já foi desbloqueada
      if (alreadyUnlocked?.contains(achievement.id) == true) continue;

      // Verificar se foi desbloqueada
      if (achievement.checkUnlock(stats, entry)) {
        unlocked.add(achievement);
        debugPrint('[DiaryGamification] Achievement unlocked: ${achievement.title}');
      }
    }

    return unlocked;
  }

  /// Retorna progresso para cada conquista
  Future<Map<String, double>> getAchievementProgress() async {
    final stats = await _repository.getStatistics();
    final progress = <String, double>{};

    for (final achievement in achievements) {
      double currentValue;

      switch (achievement.id) {
        case 'first_entry':
        case 'vivid_memories':
        case 'historian':
          currentValue = stats.totalEntries.toDouble();
          break;
        case 'dedicated_writer':
        case 'month_streak':
          currentValue = stats.currentStreak.toDouble();
          break;
        case 'reflective':
          currentValue = stats.entriesByTag.length.toDouble();
          break;
        case 'photographer':
          currentValue = stats.totalPhotos.toDouble();
          break;
        case 'word_master':
          currentValue = stats.totalWords.toDouble();
          break;
        case 'year_writer':
          if (stats.firstEntryDate == null) {
            currentValue = 0;
          } else {
            currentValue = DateTime.now()
                .difference(stats.firstEntryDate!)
                .inDays
                .toDouble();
          }
          break;
        default:
          currentValue = 0;
      }

      progress[achievement.id] = (currentValue / achievement.requiredValue).clamp(0.0, 1.0);
    }

    return progress;
  }

  /// Integra com o sistema de gamificação do app
  Future<void> awardXp(int xp) async {
    // TODO: Integrar com syncedGamificationRepositoryProvider quando disponível
    debugPrint('[DiaryGamification] Would award $xp XP');
  }

  /// Registra conquista desbloqueada
  Future<void> recordAchievement(DiaryAchievement achievement) async {
    // TODO: Integrar com sistema de conquistas do app
    debugPrint('[DiaryGamification] Would record achievement: ${achievement.id}');
  }
}

/// Provider para o DiaryGamificationService
final diaryGamificationServiceProvider = Provider<DiaryGamificationService>((ref) {
  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return DiaryGamificationService(repository);
});
