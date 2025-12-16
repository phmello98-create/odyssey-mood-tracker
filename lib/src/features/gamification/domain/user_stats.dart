// UserStats model for gamification
// Note: Not using Hive adapters - storing as Map

class UserStats {
  final int totalXP;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int moodRecordsCount;
  final int timeTrackedMinutes;
  final int tasksCompleted;
  final int notesCreated;
  final List<String> unlockedBadges;
  final int pomodoroSessions;

  UserStats({
    this.totalXP = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.moodRecordsCount = 0,
    this.timeTrackedMinutes = 0,
    this.tasksCompleted = 0,
    this.notesCreated = 0,
    this.unlockedBadges = const [],
    this.pomodoroSessions = 0,
  });

  UserStats copyWith({
    int? totalXP,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? moodRecordsCount,
    int? timeTrackedMinutes,
    int? tasksCompleted,
    int? notesCreated,
    List<String>? unlockedBadges,
    int? pomodoroSessions,
  }) {
    return UserStats(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      moodRecordsCount: moodRecordsCount ?? this.moodRecordsCount,
      timeTrackedMinutes: timeTrackedMinutes ?? this.timeTrackedMinutes,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      notesCreated: notesCreated ?? this.notesCreated,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      pomodoroSessions: pomodoroSessions ?? this.pomodoroSessions,
    );
  }

  // XP needed for next level (exponential growth)
  int get xpForNextLevel => (level * 100 * 1.5).round();
  
  // Total XP needed to reach a specific level
  static int totalXPForLevel(int lvl) {
    if (lvl <= 1) return 0;
    int total = 0;
    for (int i = 1; i < lvl; i++) {
      total += (i * 100 * 1.5).round();
    }
    return total;
  }
  
  // Calculate what level you should be at given total XP
  static int levelForTotalXP(int xp) {
    int lvl = 1;
    int totalNeeded = 0;
    while (true) {
      int xpForThisLevel = (lvl * 100 * 1.5).round();
      if (totalNeeded + xpForThisLevel > xp) break;
      totalNeeded += xpForThisLevel;
      lvl++;
    }
    return lvl;
  }
  
  // XP progress in current level
  int get xpInCurrentLevel {
    int xpAtCurrentLevel = totalXPForLevel(level);
    return totalXP - xpAtCurrentLevel;
  }
  
  // Progress percentage to next level (0.0 - 1.0)
  double get levelProgress {
    if (xpForNextLevel <= 0) return 0;
    return (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);
  }

  int _totalXPForLevel(int lvl) {
    return totalXPForLevel(lvl);
  }
}

class GameBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int requiredValue;
  final BadgeType type;

  const GameBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.type,
  });
}

enum BadgeType {
  streak,
  mood,
  time,
  tasks,
  notes,
  pomodoro,
  special,
}

// All available badges - Nomes criativos e divertidos
const List<GameBadge> allBadges = [
  // Streak badges - Tema: Chamas e Fogo
  GameBadge(id: 'streak_3', name: 'Faísca Inicial', description: '3 dias seguidos - A chama acendeu!', icon: '🔥', requiredValue: 3, type: BadgeType.streak),
  GameBadge(id: 'streak_7', name: 'Fogueira Acesa', description: '7 dias seguidos - O fogo pegou!', icon: '🔥', requiredValue: 7, type: BadgeType.streak),
  GameBadge(id: 'streak_14', name: 'Guardião da Chama', description: '14 dias seguidos - Você protege o fogo', icon: '🌟', requiredValue: 14, type: BadgeType.streak),
  GameBadge(id: 'streak_30', name: 'Senhor do Fogo', description: '30 dias seguidos - Domínio absoluto!', icon: '👑', requiredValue: 30, type: BadgeType.streak),
  GameBadge(id: 'streak_100', name: 'Fênix Imortal', description: '100 dias seguidos - Lenda viva!', icon: '🦅', requiredValue: 100, type: BadgeType.streak),

  // Mood badges - Tema: Sabedoria Interior
  GameBadge(id: 'mood_10', name: 'Aprendiz da Mente', description: '10 check-ins emocionais', icon: '🔮', requiredValue: 10, type: BadgeType.mood),
  GameBadge(id: 'mood_50', name: 'Oráculo Interior', description: '50 check-ins - Você se conhece bem', icon: '🧙', requiredValue: 50, type: BadgeType.mood),
  GameBadge(id: 'mood_100', name: 'Mestre dos Sentimentos', description: '100 check-ins - Sabedoria emocional', icon: '🎭', requiredValue: 100, type: BadgeType.mood),

  // Time tracking badges - Tema: Tempo e Magia
  GameBadge(id: 'time_60', name: 'Domador do Tempo', description: '1 hora de foco puro', icon: '⏳', requiredValue: 60, type: BadgeType.time),
  GameBadge(id: 'time_300', name: 'Mago do Relógio', description: '5 horas focadas', icon: '🕐', requiredValue: 300, type: BadgeType.time),
  GameBadge(id: 'time_600', name: 'Arquiteto do Tempo', description: '10 horas de dedicação', icon: '⚡', requiredValue: 600, type: BadgeType.time),
  GameBadge(id: 'time_1200', name: 'Senhor Kronos', description: '20 horas - O tempo te obedece!', icon: '🌀', requiredValue: 1200, type: BadgeType.time),

  // Tasks badges - Tema: Conquistas Épicas
  GameBadge(id: 'tasks_10', name: 'Caçador de Tarefas', description: '10 missões concluídas', icon: '🗡️', requiredValue: 10, type: BadgeType.tasks),
  GameBadge(id: 'tasks_50', name: 'Destruidor de Listas', description: '50 missões - Nada te para!', icon: '⚔️', requiredValue: 50, type: BadgeType.tasks),
  GameBadge(id: 'tasks_100', name: 'Herói Produtivo', description: '100 missões - Você é uma lenda!', icon: '🛡️', requiredValue: 100, type: BadgeType.tasks),

  // Pomodoro badges - Tema: Tomate Ninja
  GameBadge(id: 'pomo_5', name: 'Ninja do Tomate', description: '5 pomodoros completos', icon: '🍅', requiredValue: 5, type: BadgeType.pomodoro),
  GameBadge(id: 'pomo_25', name: 'Samurai Vermelho', description: '25 pomodoros - Disciplina total!', icon: '🥷', requiredValue: 25, type: BadgeType.pomodoro),
  GameBadge(id: 'pomo_100', name: 'Grão-Mestre Tomate', description: '100 pomodoros - Você é o tomate!', icon: '👹', requiredValue: 100, type: BadgeType.pomodoro),

  // Notes badges - Tema: Escriba Místico
  GameBadge(id: 'notes_10', name: 'Escriba Novato', description: '10 pergaminhos escritos', icon: '📜', requiredValue: 10, type: BadgeType.notes),
  GameBadge(id: 'notes_50', name: 'Guardião dos Segredos', description: '50 notas - Biblioteca pessoal!', icon: '📚', requiredValue: 50, type: BadgeType.notes),

  // Special badges - Primeiros Passos
  GameBadge(id: 'first_mood', name: 'Despertar Interior', description: 'Primeiro check-in de humor', icon: '🌱', requiredValue: 1, type: BadgeType.special),
  GameBadge(id: 'first_task', name: 'A Jornada Começa', description: 'Primeira tarefa concluída', icon: '🚀', requiredValue: 1, type: BadgeType.special),
  
  // Suggestion badges - Exploração e Crescimento
  GameBadge(id: 'first_suggestion', name: 'Explorador Interior', description: 'Primeira sugestão aceita - A jornada começa', icon: '🧭', requiredValue: 1, type: BadgeType.special),
  GameBadge(id: 'suggestion_5', name: 'Mente Aberta', description: '5 sugestões aceitas - Você abraça o novo', icon: '🌟', requiredValue: 5, type: BadgeType.special),
  GameBadge(id: 'suggestion_10', name: 'Alquimista de Hábitos', description: '10 sugestões transformadas em prática', icon: '🔮', requiredValue: 10, type: BadgeType.special),
  GameBadge(id: 'suggestion_20', name: 'Sábio do Autoconhecimento', description: '20 sugestões - Mestre da transformação', icon: '🦉', requiredValue: 20, type: BadgeType.special),
];

// XP values for different actions
class XPValues {
  static const int moodRecord = 10;
  static const int taskCompleted = 15;
  static const int pomodoroSession = 25;
  static const int noteCreated = 5;
  static const int dailyStreak = 20;
  static const int weeklyStreak = 50;
  static const int badgeUnlocked = 100;
  static const int habitCompleted = 8;
  static const int bookCompleted = 50;
  static const int weeklyGoalMet = 75;
}

// Sistema de títulos baseado em XP total - Nomes criativos e divertidos
class UserTitles {
  static const List<({int xpRequired, String name, String emoji, String description})> titles = [
    (xpRequired: 0, name: 'Padawan do Foco', emoji: '🌱', description: 'A jornada começa aqui'),
    (xpRequired: 100, name: 'Caçador de Metas', emoji: '🔍', description: 'Explorando possibilidades'),
    (xpRequired: 250, name: 'Guardião do Tempo', emoji: '⏰', description: 'O tempo é seu aliado'),
    (xpRequired: 500, name: 'Mago da Produtividade', emoji: '🧙', description: 'Feitiços de foco'),
    (xpRequired: 1000, name: 'Ninja das Tarefas', emoji: '🥷', description: 'Silencioso e eficiente'),
    (xpRequired: 2500, name: 'Druida Interior', emoji: '🌿', description: 'Harmonia com a natureza'),
    (xpRequired: 5000, name: 'Arquimago do Hábito', emoji: '✨', description: 'Magia em cada dia'),
    (xpRequired: 10000, name: 'Senhor dos Rituais', emoji: '🔮', description: 'Domínio dos hábitos'),
    (xpRequired: 25000, name: 'Fênix Renascida', emoji: '🦅', description: 'Sempre evoluindo'),
    (xpRequired: 50000, name: 'Oráculo do Tempo', emoji: '👁️', description: 'Vê além do horizonte'),
    (xpRequired: 100000, name: 'Lenda Viva', emoji: '👑', description: 'Inspiração para todos'),
  ];

  static ({String name, String emoji, String description}) getTitleForXP(int xp) {
    var currentTitle = titles.first;
    for (final title in titles) {
      if (xp >= title.xpRequired) {
        currentTitle = title;
      } else {
        break;
      }
    }
    return (name: currentTitle.name, emoji: currentTitle.emoji, description: currentTitle.description);
  }

  static ({int xpRequired, String name})? getNextTitle(int xp) {
    for (final title in titles) {
      if (xp < title.xpRequired) {
        return (xpRequired: title.xpRequired, name: title.name);
      }
    }
    return null;
  }
}
