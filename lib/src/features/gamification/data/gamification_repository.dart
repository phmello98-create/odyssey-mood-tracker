import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/utils/services/modern_notification_service.dart';
import '../domain/user_stats.dart';
import '../domain/user_skills.dart';

/// Mapeamento de ações para skills
class SkillMapping {
  static const Map<String, List<({String skillId, int xp})>> actionToSkills = {
    'mood_record': [
      (skillId: 'emotional_iq', xp: 5),
      (skillId: 'mindfulness', xp: 3),
    ],
    'task_complete': [
      (skillId: 'discipline', xp: 10),
      (skillId: 'planning', xp: 5),
    ],
    'pomodoro_complete': [
      (skillId: 'focus', xp: 15),
      (skillId: 'discipline', xp: 5),
    ],
    'note_create': [
      (skillId: 'learning', xp: 5),
      (skillId: 'creativity', xp: 3),
    ],
    'habit_complete': [
      (skillId: 'routine', xp: 8),
      (skillId: 'discipline', xp: 3),
    ],
    'book_complete': [
      (skillId: 'learning', xp: 20),
      (skillId: 'purpose', xp: 10),
    ],
    'exercise': [(skillId: 'exercise', xp: 10)],
    'meditation': [
      (skillId: 'mindfulness', xp: 10),
      (skillId: 'emotional_iq', xp: 5),
    ],
  };
}

/// Resultado de uma ação de gamificação
class GamificationResult {
  final UserStats stats;
  final List<GameBadge> newBadges;
  final List<({String skillId, String skillName, int xpGained, bool leveledUp})>
  skillUpdates;
  final bool leveledUp;
  final int previousLevel;

  GamificationResult({
    required this.stats,
    this.newBadges = const [],
    this.skillUpdates = const [],
    this.leveledUp = false,
    this.previousLevel = 1,
  });
}

class GamificationRepository {
  final Box<dynamic> box;
  late List<SkillCategory> _skillCategories;

  GamificationRepository(this.box) {
    _skillCategories = getDefaultSkillCategories();
    _loadSkillProgress();
  }

  /// Carrega o progresso das skills do Hive
  void _loadSkillProgress() {
    final savedProgress =
        box.get('user_skills_progress') as Map<dynamic, dynamic>?;
    if (savedProgress != null) {
      for (final category in _skillCategories) {
        for (final skill in category.skills) {
          final skillData = savedProgress[skill.id] as Map<dynamic, dynamic>?;
          if (skillData != null) {
            skill.currentLevel = skillData['level'] ?? 1;
            skill.currentXP = skillData['xp'] ?? 0;
          }
        }
      }
    }
  }

  /// Salva o progresso das skills no Hive
  Future<void> _saveSkillProgress() async {
    final progress = <String, Map<String, int>>{};
    for (final category in _skillCategories) {
      for (final skill in category.skills) {
        progress[skill.id] = {
          'level': skill.currentLevel,
          'xp': skill.currentXP,
        };
      }
    }
    await box.put('user_skills_progress', progress);
  }

  /// Retorna as categorias de skills com progresso atual
  List<SkillCategory> getSkillCategories() => _skillCategories;

  /// Encontra uma skill pelo ID
  Skill? findSkill(String skillId) {
    for (final category in _skillCategories) {
      for (final skill in category.skills) {
        if (skill.id == skillId) return skill;
      }
    }
    return null;
  }

  /// Adiciona XP a uma skill específica
  Future<({bool leveledUp, int newLevel})> addXpToSkill(
    String skillId,
    int xp,
  ) async {
    final skill = findSkill(skillId);
    if (skill == null) return (leveledUp: false, newLevel: 0);

    final previousLevel = skill.currentLevel;
    skill.addXP(xp);
    await _saveSkillProgress();

    return (
      leveledUp: skill.currentLevel > previousLevel,
      newLevel: skill.currentLevel,
    );
  }

  /// Processa XP de skills para uma ação
  Future<
    List<({String skillId, String skillName, int xpGained, bool leveledUp})>
  >
  _processSkillXP(String action) async {
    final skillMappings = SkillMapping.actionToSkills[action];
    if (skillMappings == null) return [];

    final updates =
        <({String skillId, String skillName, int xpGained, bool leveledUp})>[];

    for (final mapping in skillMappings) {
      final skill = findSkill(mapping.skillId);
      if (skill != null) {
        final result = await addXpToSkill(mapping.skillId, mapping.xp);
        updates.add((
          skillId: mapping.skillId,
          skillName: skill.name,
          xpGained: mapping.xp,
          leveledUp: result.leveledUp,
        ));
      }
    }

    return updates;
  }

  UserStats getStats() {
    final data = box.get('user_stats');
    if (data == null) {
      // Primeira vez - criar com data de criação
      final newStats = UserStats(createdAt: DateTime.now());
      saveStats(newStats);
      return newStats;
    }

    // Parse from Map if stored as Map
    if (data is Map) {
      // Parse personal goals
      List<PersonalGoal> goals = [];
      if (data['personalGoals'] != null) {
        goals = (data['personalGoals'] as List)
            .map((g) => PersonalGoal.fromMap(Map<String, dynamic>.from(g)))
            .toList();
      }

      // Parse weekly stats
      WeeklyStats? currentWeek;
      WeeklyStats? previousWeek;
      if (data['currentWeekStats'] != null) {
        currentWeek = WeeklyStats.fromMap(
          Map<String, dynamic>.from(data['currentWeekStats']),
        );
      }
      if (data['previousWeekStats'] != null) {
        previousWeek = WeeklyStats.fromMap(
          Map<String, dynamic>.from(data['previousWeekStats']),
        );
      }

      return UserStats(
        totalXP: data['totalXP'] ?? 0,
        level: data['level'] ?? 1,
        currentStreak: data['currentStreak'] ?? 0,
        longestStreak: data['longestStreak'] ?? 0,
        lastActiveDate: data['lastActiveDate'] != null
            ? DateTime.tryParse(data['lastActiveDate'])
            : null,
        moodRecordsCount: data['moodRecordsCount'] ?? 0,
        timeTrackedMinutes: data['timeTrackedMinutes'] ?? 0,
        tasksCompleted: data['tasksCompleted'] ?? 0,
        notesCreated: data['notesCreated'] ?? 0,
        unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
        pomodoroSessions: data['pomodoroSessions'] ?? 0,
        // Novos campos
        bio: data['bio'],
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'])
            : DateTime.now(),
        totalDaysActive: data['totalDaysActive'] ?? 0,
        habitsCompleted: data['habitsCompleted'] ?? 0,
        booksRead: data['booksRead'] ?? 0,
        averageMoodScore: (data['averageMoodScore'] ?? 0.0).toDouble(),
        recentMoods: data['recentMoods'] != null
            ? List<double>.from(
                data['recentMoods'].map((e) => (e as num).toDouble()),
              )
            : [],
        currentWeekStats: currentWeek,
        previousWeekStats: previousWeek,
        personalGoals: goals,
        currentMoodEmoji: data['currentMoodEmoji'],
        favoriteActivity: data['favoriteActivity'],
      );
    }

    return data as UserStats;
  }

  Future<void> saveStats(UserStats stats) async {
    await box.put('user_stats', {
      'totalXP': stats.totalXP,
      'level': stats.level,
      'currentStreak': stats.currentStreak,
      'longestStreak': stats.longestStreak,
      'lastActiveDate': stats.lastActiveDate?.toIso8601String(),
      'moodRecordsCount': stats.moodRecordsCount,
      'timeTrackedMinutes': stats.timeTrackedMinutes,
      'tasksCompleted': stats.tasksCompleted,
      'notesCreated': stats.notesCreated,
      'unlockedBadges': stats.unlockedBadges,
      'pomodoroSessions': stats.pomodoroSessions,
      // Novos campos
      'bio': stats.bio,
      'createdAt': stats.createdAt?.toIso8601String(),
      'totalDaysActive': stats.totalDaysActive,
      'habitsCompleted': stats.habitsCompleted,
      'booksRead': stats.booksRead,
      'averageMoodScore': stats.averageMoodScore,
      'recentMoods': stats.recentMoods,
      'currentWeekStats': stats.currentWeekStats?.toMap(),
      'previousWeekStats': stats.previousWeekStats?.toMap(),
      'personalGoals': stats.personalGoals.map((g) => g.toMap()).toList(),
      'currentMoodEmoji': stats.currentMoodEmoji,
      'favoriteActivity': stats.favoriteActivity,
    });
  }

  /// Atualiza a bio do usuário
  Future<void> updateBio(String bio) async {
    var stats = getStats();
    stats = stats.copyWith(bio: bio);
    await saveStats(stats);
  }

  /// Adiciona uma meta pessoal
  Future<void> addPersonalGoal(PersonalGoal goal) async {
    var stats = getStats();
    final goals = [...stats.personalGoals, goal];
    stats = stats.copyWith(personalGoals: goals);
    await saveStats(stats);
  }

  /// Atualiza progresso de uma meta
  Future<void> updateGoalProgress(String goalId, int newValue) async {
    var stats = getStats();
    final goals = stats.personalGoals.map((g) {
      if (g.id == goalId) {
        return g.copyWith(
          currentValue: newValue,
          isCompleted: newValue >= g.targetValue,
        );
      }
      return g;
    }).toList();
    stats = stats.copyWith(personalGoals: goals);
    await saveStats(stats);
  }

  /// Incrementa progresso de uma meta
  Future<void> incrementGoalProgress(String goalId, {int delta = 1}) async {
    var stats = getStats();
    final goals = stats.personalGoals.map((g) {
      if (g.id == goalId) {
        final newValue = g.currentValue + delta;
        return g.copyWith(
          currentValue: newValue,
          isCompleted: newValue >= g.targetValue,
        );
      }
      return g;
    }).toList();
    stats = stats.copyWith(personalGoals: goals);
    await saveStats(stats);
  }

  /// Remove uma meta pessoal
  Future<void> removePersonalGoal(String goalId) async {
    var stats = getStats();
    final goals = stats.personalGoals.where((g) => g.id != goalId).toList();
    stats = stats.copyWith(personalGoals: goals);
    await saveStats(stats);
  }

  /// Atualiza o humor atual
  Future<void> updateCurrentMood(String emoji, double moodValue) async {
    var stats = getStats();

    // Adiciona ao histórico recente (mantém últimos 7)
    final recentMoods = [...stats.recentMoods, moodValue];
    if (recentMoods.length > 7) {
      recentMoods.removeAt(0);
    }

    // Calcula nova média
    final avgMood = recentMoods.isNotEmpty
        ? recentMoods.reduce((a, b) => a + b) / recentMoods.length
        : moodValue;

    stats = stats.copyWith(
      currentMoodEmoji: emoji,
      recentMoods: recentMoods,
      averageMoodScore: avgMood,
    );
    await saveStats(stats);
  }

  /// Atualiza estatísticas semanais
  Future<void> updateWeeklyStats() async {
    var stats = getStats();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Se já temos stats da semana atual, verifica se mudou de semana
    if (stats.currentWeekStats != null) {
      final currentWeekStart = stats.currentWeekStats!.weekStart;
      final daysDiff = weekStart.difference(currentWeekStart).inDays;

      if (daysDiff >= 7) {
        // Mudou de semana - move current para previous
        stats = stats.copyWith(
          previousWeekStats: stats.currentWeekStats,
          currentWeekStats: WeeklyStats(weekStart: weekStart),
        );
      }
    } else {
      // Primeira vez
      stats = stats.copyWith(
        currentWeekStats: WeeklyStats(weekStart: weekStart),
      );
    }

    await saveStats(stats);
  }

  // Add XP and check for level up
  Future<UserStats> addXP(int xp) async {
    var stats = getStats();
    int previousLevel = stats.level;
    int newXP = stats.totalXP + xp;

    // Calculate correct level based on total XP
    int newLevel = UserStats.levelForTotalXP(newXP);

    stats = stats.copyWith(totalXP: newXP, level: newLevel);

    await saveStats(stats);

    // Notificar Level Up se subiu de nível
    if (newLevel > previousLevel) {
      // Calcular XP para próximo nível
      final xpForNextLevel = (newLevel * 100 * 1.5).round();
      await ModernNotificationService.instance.sendLevelUp(
        newLevel: newLevel,
        xpToNextLevel: xpForNextLevel,
      );
    }

    return stats;
  }

  // Update streak
  Future<UserStats> updateStreak() async {
    var stats = getStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (stats.lastActiveDate != null) {
      final lastActive = DateTime(
        stats.lastActiveDate!.year,
        stats.lastActiveDate!.month,
        stats.lastActiveDate!.day,
      );
      final diff = today.difference(lastActive).inDays;

      if (diff == 0) {
        // Same day, no change
        return stats;
      } else if (diff == 1) {
        // Consecutive day
        final newStreak = stats.currentStreak + 1;
        stats = stats.copyWith(
          currentStreak: newStreak,
          longestStreak: newStreak > stats.longestStreak
              ? newStreak
              : stats.longestStreak,
          lastActiveDate: now,
        );
      } else {
        // Streak broken
        stats = stats.copyWith(currentStreak: 1, lastActiveDate: now);
      }
    } else {
      // First activity
      stats = stats.copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastActiveDate: now,
      );
    }

    await saveStats(stats);
    return stats;
  }

  // Record mood and get XP - agora com skills
  Future<GamificationResult> recordMood() async {
    var stats = getStats();
    final previousLevel = stats.level;
    final newCount = stats.moodRecordsCount + 1;
    stats = stats.copyWith(moodRecordsCount: newCount);

    // Add XP geral
    stats = await addXP(XPValues.moodRecord);

    // Processar XP das skills
    final skillUpdates = await _processSkillXP('mood_record');

    // Update streak
    stats = await updateStreak();

    // Check for new badges
    final newBadges = _checkBadges(stats, BadgeType.mood, newCount);
    if (newBadges.isNotEmpty) {
      stats = stats.copyWith(
        unlockedBadges: [
          ...stats.unlockedBadges,
          ...newBadges.map((b) => b.id),
        ],
      );
      await addXP(newBadges.length * XPValues.badgeUnlocked);
    }

    // Check first mood badge
    if (newCount == 1 && !stats.unlockedBadges.contains('first_mood')) {
      final firstMoodBadge = allBadges.firstWhere((b) => b.id == 'first_mood');
      stats = stats.copyWith(
        unlockedBadges: [...stats.unlockedBadges, 'first_mood'],
      );
      newBadges.add(firstMoodBadge);
      await addXP(XPValues.badgeUnlocked);
    }

    await saveStats(stats);
    stats = getStats(); // Refresh stats after all updates

    return GamificationResult(
      stats: stats,
      newBadges: newBadges,
      skillUpdates: skillUpdates,
      leveledUp: stats.level > previousLevel,
      previousLevel: previousLevel,
    );
  }

  // Complete task and get XP - agora com skills
  Future<GamificationResult> completeTask() async {
    var stats = getStats();
    final previousLevel = stats.level;
    final newCount = stats.tasksCompleted + 1;
    stats = stats.copyWith(tasksCompleted: newCount);

    stats = await addXP(XPValues.taskCompleted);
    final skillUpdates = await _processSkillXP('task_complete');
    stats = await updateStreak();

    final newBadges = _checkBadges(stats, BadgeType.tasks, newCount);
    if (newBadges.isNotEmpty) {
      stats = stats.copyWith(
        unlockedBadges: [
          ...stats.unlockedBadges,
          ...newBadges.map((b) => b.id),
        ],
      );
      await addXP(newBadges.length * XPValues.badgeUnlocked);
    }

    if (newCount == 1 && !stats.unlockedBadges.contains('first_task')) {
      final firstTaskBadge = allBadges.firstWhere((b) => b.id == 'first_task');
      stats = stats.copyWith(
        unlockedBadges: [...stats.unlockedBadges, 'first_task'],
      );
      newBadges.add(firstTaskBadge);
      await addXP(XPValues.badgeUnlocked);
    }

    await saveStats(stats);
    stats = getStats();

    return GamificationResult(
      stats: stats,
      newBadges: newBadges,
      skillUpdates: skillUpdates,
      leveledUp: stats.level > previousLevel,
      previousLevel: previousLevel,
    );
  }

  // Complete pomodoro session - agora com skills
  Future<GamificationResult> completePomodoroSession() async {
    var stats = getStats();
    final previousLevel = stats.level;
    final newCount = stats.pomodoroSessions + 1;
    stats = stats.copyWith(pomodoroSessions: newCount);

    stats = await addXP(XPValues.pomodoroSession);
    final skillUpdates = await _processSkillXP('pomodoro_complete');
    stats = await updateStreak();

    final newBadges = _checkBadges(stats, BadgeType.pomodoro, newCount);
    if (newBadges.isNotEmpty) {
      stats = stats.copyWith(
        unlockedBadges: [
          ...stats.unlockedBadges,
          ...newBadges.map((b) => b.id),
        ],
      );
      await addXP(newBadges.length * XPValues.badgeUnlocked);
    }

    await saveStats(stats);
    stats = getStats();

    return GamificationResult(
      stats: stats,
      newBadges: newBadges,
      skillUpdates: skillUpdates,
      leveledUp: stats.level > previousLevel,
      previousLevel: previousLevel,
    );
  }

  // Track time (in minutes)
  Future<GamificationResult> trackTime(int minutes) async {
    var stats = getStats();
    final previousLevel = stats.level;
    final newTotal = stats.timeTrackedMinutes + minutes;
    stats = stats.copyWith(timeTrackedMinutes: newTotal);

    stats = await updateStreak();

    final newBadges = _checkBadges(stats, BadgeType.time, newTotal);
    if (newBadges.isNotEmpty) {
      stats = stats.copyWith(
        unlockedBadges: [
          ...stats.unlockedBadges,
          ...newBadges.map((b) => b.id),
        ],
      );
      await addXP(newBadges.length * XPValues.badgeUnlocked);
    }

    await saveStats(stats);
    stats = getStats();

    return GamificationResult(
      stats: stats,
      newBadges: newBadges,
      skillUpdates: [],
      leveledUp: stats.level > previousLevel,
      previousLevel: previousLevel,
    );
  }

  // Create note - agora com skills
  Future<GamificationResult> createNote() async {
    var stats = getStats();
    final previousLevel = stats.level;
    final newCount = stats.notesCreated + 1;
    stats = stats.copyWith(notesCreated: newCount);

    stats = await addXP(XPValues.noteCreated);
    final skillUpdates = await _processSkillXP('note_create');
    stats = await updateStreak();

    final newBadges = _checkBadges(stats, BadgeType.notes, newCount);
    if (newBadges.isNotEmpty) {
      stats = stats.copyWith(
        unlockedBadges: [
          ...stats.unlockedBadges,
          ...newBadges.map((b) => b.id),
        ],
      );
      await addXP(newBadges.length * XPValues.badgeUnlocked);
    }

    await saveStats(stats);
    stats = getStats();

    return GamificationResult(
      stats: stats,
      newBadges: newBadges,
      skillUpdates: skillUpdates,
      leveledUp: stats.level > previousLevel,
      previousLevel: previousLevel,
    );
  }

  // Complete habit - novo método
  Future<GamificationResult> completeHabit() async {
    var stats = getStats();
    final previousLevel = stats.level;

    stats = await addXP(XPValues.habitCompleted);
    final skillUpdates = await _processSkillXP('habit_complete');
    stats = await updateStreak();

    await saveStats(stats);
    stats = getStats();

    return GamificationResult(
      stats: stats,
      newBadges: [],
      skillUpdates: skillUpdates,
      leveledUp: stats.level > previousLevel,
      previousLevel: previousLevel,
    );
  }

  // Complete book - novo método
  Future<GamificationResult> completeBook() async {
    var stats = getStats();
    final previousLevel = stats.level;

    stats = await addXP(XPValues.bookCompleted);
    final skillUpdates = await _processSkillXP('book_complete');
    stats = await updateStreak();

    await saveStats(stats);
    stats = getStats();

    return GamificationResult(
      stats: stats,
      newBadges: [],
      skillUpdates: skillUpdates,
      leveledUp: stats.level > previousLevel,
      previousLevel: previousLevel,
    );
  }

  List<GameBadge> _checkBadges(UserStats stats, BadgeType type, int value) {
    final typeBadges = allBadges.where((b) => b.type == type).toList();
    final newBadges = <GameBadge>[];

    for (final badge in typeBadges) {
      if (!stats.unlockedBadges.contains(badge.id) &&
          value >= badge.requiredValue) {
        newBadges.add(badge);
      }
    }

    return newBadges;
  }

  // Check streak badges
  Future<List<GameBadge>> checkStreakBadges() async {
    var stats = getStats();
    final streakBadges = allBadges
        .where((b) => b.type == BadgeType.streak)
        .toList();
    final newBadges = <GameBadge>[];

    for (final badge in streakBadges) {
      if (!stats.unlockedBadges.contains(badge.id) &&
          stats.currentStreak >= badge.requiredValue) {
        newBadges.add(badge);
      }
    }

    if (newBadges.isNotEmpty) {
      stats = stats.copyWith(
        unlockedBadges: [
          ...stats.unlockedBadges,
          ...newBadges.map((b) => b.id),
        ],
      );
      await addXP(newBadges.length * XPValues.badgeUnlocked);
      await saveStats(stats);
    }

    return newBadges;
  }

  // Check and unlock suggestion badges based on total accepted suggestions
  Future<List<GameBadge>> checkSuggestionBadges(
    int totalSuggestionsAccepted,
  ) async {
    var stats = getStats();
    final suggestionBadgeIds = [
      'first_suggestion',
      'suggestion_5',
      'suggestion_10',
      'suggestion_20',
    ];
    final suggestionBadges = allBadges
        .where((b) => suggestionBadgeIds.contains(b.id))
        .toList();
    final newBadges = <GameBadge>[];

    for (final badge in suggestionBadges) {
      if (!stats.unlockedBadges.contains(badge.id) &&
          totalSuggestionsAccepted >= badge.requiredValue) {
        newBadges.add(badge);
      }
    }

    if (newBadges.isNotEmpty) {
      stats = stats.copyWith(
        unlockedBadges: [
          ...stats.unlockedBadges,
          ...newBadges.map((b) => b.id),
        ],
      );
      await addXP(newBadges.length * XPValues.badgeUnlocked);
      await saveStats(stats);
    }

    return newBadges;
  }

  // Get all badges with unlock status
  List<(GameBadge, bool)> getAllBadgesWithStatus() {
    final stats = getStats();
    return allBadges.map((badge) {
      return (badge, stats.unlockedBadges.contains(badge.id));
    }).toList();
  }

  // Seed demo data
  Future<void> seedDemoData() async {
    final stats = UserStats(
      totalXP: 1850,
      level: 5,
      currentStreak: 7,
      longestStreak: 14,
      lastActiveDate: DateTime.now(),
      moodRecordsCount: 28,
      timeTrackedMinutes: 485,
      tasksCompleted: 32,
      notesCreated: 12,
      unlockedBadges: [
        'first_mood',
        'first_task',
        'streak_3',
        'streak_7',
        'mood_10',
        'tasks_10',
        'time_60',
        'time_300',
        'pomo_5',
        'notes_10',
      ],
      pomodoroSessions: 18,
    );
    await saveStats(stats);
  }
}

// Provider
final gamificationBoxProvider = FutureProvider<Box>((ref) async {
  return await Hive.openBox('gamification');
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final boxAsync = ref.watch(gamificationBoxProvider);
  return boxAsync.when(
    data: (box) => GamificationRepository(box),
    loading: () => throw Exception('Loading'),
    error: (e, st) => throw e,
  );
});

final userStatsProvider = Provider<UserStats>((ref) {
  try {
    final repo = ref.watch(gamificationRepositoryProvider);
    return repo.getStats();
  } catch (e) {
    return UserStats();
  }
});
