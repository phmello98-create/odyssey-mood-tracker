import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:odyssey/src/utils/services/notification_manager.dart';
import 'package:odyssey/src/utils/services/smart_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipo de celebração
enum CelebrationType {
  /// Streak atingido
  streak,

  /// Level up
  levelUp,

  /// Conquista desbloqueada
  achievement,

  /// Marco de tarefas
  taskMilestone,

  /// Marco de pomodoro
  pomodoroMilestone,

  /// Marco de registros de humor
  moodMilestone,

  /// Primeiro registro do dia
  firstOfDay,

  /// Consistência semanal
  weeklyConsistency,
}

/// Celebração a ser notificada
class Celebration {
  final CelebrationType type;
  final String title;
  final String body;
  final String emoji;
  final int? value;
  final String? achievementId;

  const Celebration({
    required this.type,
    required this.title,
    required this.body,
    required this.emoji,
    this.value,
    this.achievementId,
  });
}

/// Serviço de notificações gamificadas
class GamifiedNotificationsService {
  static final GamifiedNotificationsService _instance =
      GamifiedNotificationsService._();
  static GamifiedNotificationsService get instance => _instance;

  GamifiedNotificationsService._();

  SharedPreferences? _prefs;
  final _random = Random();

  // Keys para persistência
  static const String _keyPrefix = 'gamified_notif_';
  static const String _keyLastStreakCelebrated = '${_keyPrefix}last_streak';
  static const String _keyLastLevelCelebrated = '${_keyPrefix}last_level';
  static const String _keyLastPomodoroMilestone = '${_keyPrefix}pomodoro_milestone';
  static const String _keyLastMoodMilestone = '${_keyPrefix}mood_milestone';
  static const String _keyDailyFirstRecorded = '${_keyPrefix}daily_first_';
  static const String _keyWeeklyConsistency = '${_keyPrefix}weekly_consistency';

  // Marcos de streak
  static const List<int> streakMilestones = [3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365];

  // Marcos de pomodoro
  static const List<int> pomodoroMilestones = [1, 5, 10, 25, 50, 100, 200, 500, 1000];

  // Marcos de humor
  static const List<int> moodMilestones = [1, 7, 30, 50, 100, 200, 365, 500, 1000];

  /// Inicializa o serviço
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('🎮 GamifiedNotificationsService inicializado');
  }

  /// Verifica e envia celebração de streak
  Future<Celebration?> checkStreakCelebration(int currentStreak) async {
    final lastCelebrated = _prefs?.getInt(_keyLastStreakCelebrated) ?? 0;

    // Encontrar próximo marco
    for (final milestone in streakMilestones) {
      if (currentStreak >= milestone && lastCelebrated < milestone) {
        await _prefs?.setInt(_keyLastStreakCelebrated, milestone);

        final celebration = _generateStreakCelebration(milestone);
        await _sendCelebration(celebration);
        return celebration;
      }
    }

    return null;
  }

  /// Verifica e envia celebração de level up
  Future<Celebration?> checkLevelUpCelebration(int newLevel, String? unlockedTitle) async {
    final lastLevel = _prefs?.getInt(_keyLastLevelCelebrated) ?? 0;

    if (newLevel > lastLevel) {
      await _prefs?.setInt(_keyLastLevelCelebrated, newLevel);

      final celebration = _generateLevelUpCelebration(newLevel, unlockedTitle);
      await _sendCelebration(celebration);
      return celebration;
    }

    return null;
  }

  /// Verifica e envia celebração de pomodoro
  Future<Celebration?> checkPomodoroCelebration(int totalSessions) async {
    final lastMilestone = _prefs?.getInt(_keyLastPomodoroMilestone) ?? 0;

    for (final milestone in pomodoroMilestones) {
      if (totalSessions >= milestone && lastMilestone < milestone) {
        await _prefs?.setInt(_keyLastPomodoroMilestone, milestone);

        final celebration = _generatePomodoroCelebration(milestone);
        await _sendCelebration(celebration);
        return celebration;
      }
    }

    return null;
  }

  /// Verifica e envia celebração de humor
  Future<Celebration?> checkMoodCelebration(int totalRecords) async {
    final lastMilestone = _prefs?.getInt(_keyLastMoodMilestone) ?? 0;

    for (final milestone in moodMilestones) {
      if (totalRecords >= milestone && lastMilestone < milestone) {
        await _prefs?.setInt(_keyLastMoodMilestone, milestone);

        final celebration = _generateMoodCelebration(milestone);
        await _sendCelebration(celebration);
        return celebration;
      }
    }

    return null;
  }

  /// Verifica e envia celebração do primeiro registro do dia
  Future<Celebration?> checkFirstOfDayCelebration(String activityType) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = '$_keyDailyFirstRecorded${today}_$activityType';

    if (_prefs?.getBool(key) == true) return null;

    await _prefs?.setBool(key, true);

    final celebration = _generateFirstOfDayCelebration(activityType);
    await _sendCelebration(celebration);
    return celebration;
  }

  /// Verifica consistência semanal
  Future<Celebration?> checkWeeklyConsistency(List<bool> weekDays) async {
    // Verificar se todos os 7 dias da semana tiveram atividade
    final allDaysActive = weekDays.every((day) => day);
    if (!allDaysActive) return null;

    final lastWeek = _prefs?.getInt(_keyWeeklyConsistency) ?? 0;
    final currentWeek = _getCurrentWeekNumber();

    if (currentWeek <= lastWeek) return null;

    await _prefs?.setInt(_keyWeeklyConsistency, currentWeek);

    final celebration = _generateWeeklyConsistencyCelebration();
    await _sendCelebration(celebration);
    return celebration;
  }

  /// Gera celebração de streak
  Celebration _generateStreakCelebration(int streak) {
    String title;
    String body;
    String emoji;

    if (streak >= 365) {
      title = '🏆 UM ANO DE STREAK!';
      body = 'Você é uma lenda! 365 dias de dedicação ininterrupta!';
      emoji = '🏆';
    } else if (streak >= 100) {
      title = '👑 STREAK CENTENÁRIO!';
      body = '$streak dias! Você alcançou algo extraordinário!';
      emoji = '👑';
    } else if (streak >= 50) {
      title = '🌟 50+ DIAS!';
      body = 'Meio caminho para 100! Seu compromisso é inspirador.';
      emoji = '🌟';
    } else if (streak >= 30) {
      title = '🔥 UM MÊS!';
      body = '$streak dias de streak! O hábito está consolidado!';
      emoji = '🔥';
    } else if (streak >= 21) {
      title = '💪 21 DIAS!';
      body = 'Ciência diz: hábito formado! Continue assim!';
      emoji = '💪';
    } else if (streak >= 14) {
      title = '✨ 2 SEMANAS!';
      body = '$streak dias consecutivos! Você está voando!';
      emoji = '✨';
    } else if (streak >= 7) {
      title = '🎯 UMA SEMANA!';
      body = '7 dias de streak! O começo de algo grande!';
      emoji = '🎯';
    } else {
      title = '🌱 STREAK INICIADO!';
      body = '$streak dias seguidos! Continue crescendo!';
      emoji = '🌱';
    }

    return Celebration(
      type: CelebrationType.streak,
      title: title,
      body: body,
      emoji: emoji,
      value: streak,
    );
  }

  /// Gera celebração de level up
  Celebration _generateLevelUpCelebration(int level, String? unlockedTitle) {
    final content = SmartNotificationContent.instance
        .generateLevelUpContent(level, unlockedTitle);

    return Celebration(
      type: CelebrationType.levelUp,
      title: content.title,
      body: content.body,
      emoji: content.emoji ?? '🎉',
      value: level,
    );
  }

  /// Gera celebração de pomodoro
  Celebration _generatePomodoroCelebration(int sessions) {
    String title;
    String body;
    String emoji;

    if (sessions >= 1000) {
      title = '🏆 MIL POMODOROS!';
      body = 'Você é um mestre do foco! 1000 sessões completas!';
      emoji = '🏆';
    } else if (sessions >= 500) {
      title = '👑 500 SESSÕES!';
      body = 'Meio milhar de pomodoros! Produtividade excepcional!';
      emoji = '👑';
    } else if (sessions >= 100) {
      title = '🌟 100 POMODOROS!';
      body = 'Centena de sessões de foco! Impressionante!';
      emoji = '🌟';
    } else if (sessions >= 50) {
      title = '🔥 50 SESSÕES!';
      body = 'Metade do caminho para 100! Continue focado!';
      emoji = '🔥';
    } else if (sessions >= 25) {
      title = '💪 25 POMODOROS!';
      body = 'Um quarto de centena! A produtividade é sua!';
      emoji = '💪';
    } else if (sessions >= 10) {
      title = '✨ 10 SESSÕES!';
      body = 'Duas mãos de pomodoros! Bom ritmo!';
      emoji = '✨';
    } else if (sessions >= 5) {
      title = '🎯 5 POMODOROS!';
      body = 'Primeira mão completa! O foco está funcionando!';
      emoji = '🎯';
    } else {
      title = '🍅 PRIMEIRO POMODORO!';
      body = 'Sua jornada de foco começou! Bem-vindo!';
      emoji = '🍅';
    }

    return Celebration(
      type: CelebrationType.pomodoroMilestone,
      title: title,
      body: body,
      emoji: emoji,
      value: sessions,
    );
  }

  /// Gera celebração de registro de humor
  Celebration _generateMoodCelebration(int records) {
    String title;
    String body;
    String emoji;

    if (records >= 1000) {
      title = '🏆 MIL REGISTROS!';
      body = 'Você é um expert em autoconhecimento! 1000 check-ins!';
      emoji = '🏆';
    } else if (records >= 365) {
      title = '📅 UM ANO EM REGISTROS!';
      body = '365 check-ins! Um ano de jornada emocional documentada!';
      emoji = '📅';
    } else if (records >= 100) {
      title = '🌟 100 CHECK-INS!';
      body = 'Centena de registros! Seu diário emocional está rico!';
      emoji = '🌟';
    } else if (records >= 50) {
      title = '📊 50 REGISTROS!';
      body = 'Meio caminho para 100! Padrões estão emergindo!';
      emoji = '📊';
    } else if (records >= 30) {
      title = '📈 30 CHECK-INS!';
      body = 'Um mês de dados! O autoconhecimento cresce!';
      emoji = '📈';
    } else if (records >= 7) {
      title = '📝 UMA SEMANA!';
      body = '7 registros! O hábito de reflexão está nascendo!';
      emoji = '📝';
    } else {
      title = '🎉 PRIMEIRO REGISTRO!';
      body = 'Bem-vindo à jornada de autoconhecimento!';
      emoji = '🎉';
    }

    return Celebration(
      type: CelebrationType.moodMilestone,
      title: title,
      body: body,
      emoji: emoji,
      value: records,
    );
  }

  /// Gera celebração do primeiro registro do dia
  Celebration _generateFirstOfDayCelebration(String activityType) {
    final messages = {
      'mood': const Celebration(
        type: CelebrationType.firstOfDay,
        title: '🌅 Primeiro Check-in!',
        body: 'Ótimo começo de dia registrando seu humor!',
        emoji: '🌅',
      ),
      'pomodoro': const Celebration(
        type: CelebrationType.firstOfDay,
        title: '🍅 Primeira Sessão!',
        body: 'Dia começando produtivo com Pomodoro!',
        emoji: '🍅',
      ),
      'task': const Celebration(
        type: CelebrationType.firstOfDay,
        title: '✅ Primeira Tarefa!',
        body: 'Conquistando o dia uma tarefa por vez!',
        emoji: '✅',
      ),
      'habit': const Celebration(
        type: CelebrationType.firstOfDay,
        title: '🎯 Primeiro Hábito!',
        body: 'Construindo rotinas, um check de cada vez!',
        emoji: '🎯',
      ),
    };

    return messages[activityType] ??
        const Celebration(
          type: CelebrationType.firstOfDay,
          title: '✨ Primeira Ação!',
          body: 'Dia começando com o pé direito!',
          emoji: '✨',
        );
  }

  /// Gera celebração de consistência semanal
  Celebration _generateWeeklyConsistencyCelebration() {
    final variations = [
      const Celebration(
        type: CelebrationType.weeklyConsistency,
        title: '🏅 SEMANA PERFEITA!',
        body: '7 dias de atividade! Consistência impecável!',
        emoji: '🏅',
      ),
      const Celebration(
        type: CelebrationType.weeklyConsistency,
        title: '⭐ SEMANA COMPLETA!',
        body: 'Todos os dias da semana com registro! Incrível!',
        emoji: '⭐',
      ),
      const Celebration(
        type: CelebrationType.weeklyConsistency,
        title: '🎖️ 7/7 DIAS!',
        body: 'Semana 100% consistente! Você é demais!',
        emoji: '🎖️',
      ),
    ];

    return variations[_random.nextInt(variations.length)];
  }

  /// Envia a celebração como notificação
  Future<void> _sendCelebration(Celebration celebration) async {
    await NotificationManager.instance.sendAchievementNotification(
      title: celebration.title,
      description: celebration.body,
      emoji: celebration.emoji,
      achievementId: celebration.achievementId ??
          '${celebration.type.name}_${celebration.value ?? DateTime.now().millisecondsSinceEpoch}',
    );

    debugPrint('🎮 Celebração enviada: ${celebration.title}');
  }

  /// Obtém número da semana atual
  int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final daysDifference = now.difference(firstDayOfYear).inDays;
    return (daysDifference / 7).ceil();
  }

  /// Reseta celebrações (para debug)
  Future<void> resetCelebrations() async {
    final keys = _prefs?.getKeys().where((k) => k.startsWith(_keyPrefix)) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    debugPrint('🎮 Celebrações resetadas');
  }
}
