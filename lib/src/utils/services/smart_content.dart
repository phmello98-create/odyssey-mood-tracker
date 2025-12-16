import 'dart:math';
import 'package:odyssey/src/utils/services/notification_rules.dart';

/// Conteúdo de notificação gerado dinamicamente
class NotificationContent {
  final String title;
  final String body;
  final String? emoji;
  final Map<String, dynamic> payload;

  const NotificationContent({
    required this.title,
    required this.body,
    this.emoji,
    this.payload = const {},
  });
}

/// Gerador de conteúdo inteligente para notificações
class SmartNotificationContent {
  static final SmartNotificationContent _instance = SmartNotificationContent._();
  static SmartNotificationContent get instance => _instance;

  SmartNotificationContent._();

  final _random = Random();

  /// Gera conteúdo para lembrete de humor baseado no contexto
  NotificationContent generateMoodReminder(UserContext context) {
    // Mensagens personalizadas baseadas no streak
    if (context.currentStreak >= 30) {
      return _generateStreakMasterContent(context);
    } else if (context.currentStreak >= 14) {
      return _generateConsistentUserContent(context);
    } else if (context.currentStreak >= 7) {
      return _generateBuildingStreakContent(context);
    } else if (context.currentStreak >= 3) {
      return _generateGrowingStreakContent(context);
    }

    // Mensagens baseadas no horário do dia
    return _generateTimeBasedContent(context);
  }

  /// Conteúdo para usuários com streak de 30+ dias
  NotificationContent _generateStreakMasterContent(UserContext context) {
    final messages = [
      NotificationContent(
        title: '🏆 Lenda do Streak!',
        body: '${context.currentStreak} dias consecutivos! Você é inspiração. Como está hoje?',
        emoji: '🏆',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
      NotificationContent(
        title: '⭐ Mestre da Consistência',
        body: 'Seu streak de ${context.currentStreak} dias mostra dedicação incrível!',
        emoji: '⭐',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
      NotificationContent(
        title: '🔥 Imparável!',
        body: '${context.currentStreak} dias e contando! Registre mais um momento.',
        emoji: '🔥',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Conteúdo para usuários com streak de 14-29 dias
  NotificationContent _generateConsistentUserContent(UserContext context) {
    final messages = [
      NotificationContent(
        title: '💪 Consistência Forte!',
        body: '${context.currentStreak} dias de registro! Você está criando um hábito poderoso.',
        emoji: '💪',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
      NotificationContent(
        title: '🌟 Brilhando!',
        body: 'Quase ${context.currentStreak >= 21 ? "3" : "2"} semanas de streak! Continue assim!',
        emoji: '🌟',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
      NotificationContent(
        title: '📈 Em Ascensão',
        body: 'Seu streak de ${context.currentStreak} dias mostra comprometimento real!',
        emoji: '📈',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Conteúdo para usuários com streak de 7-13 dias
  NotificationContent _generateBuildingStreakContent(UserContext context) {
    final messages = [
      NotificationContent(
        title: '🔥 Uma Semana+!',
        body: '${context.currentStreak} dias seguidos! O hábito está se formando.',
        emoji: '🔥',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
      NotificationContent(
        title: '✨ Progresso Visível',
        body: 'Já são ${context.currentStreak} dias! Continue construindo esse hábito.',
        emoji: '✨',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
      NotificationContent(
        title: '🎯 No Caminho Certo',
        body: 'Streak de ${context.currentStreak} dias! Cada registro conta.',
        emoji: '🎯',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Conteúdo para usuários com streak de 3-6 dias
  NotificationContent _generateGrowingStreakContent(UserContext context) {
    final messages = [
      NotificationContent(
        title: '🌱 Crescendo!',
        body: '${context.currentStreak} dias de streak! Está começando a virar rotina.',
        emoji: '🌱',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
      NotificationContent(
        title: '💫 Bom Começo!',
        body: 'Já são ${context.currentStreak} dias! Continue registrando.',
        emoji: '💫',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
      NotificationContent(
        title: '🚀 Decolando',
        body: 'Streak de ${context.currentStreak} dias! Mantenha o momentum.',
        emoji: '🚀',
        payload: {'type': 'mood_reminder', 'streak': context.currentStreak},
      ),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Conteúdo baseado no horário do dia
  NotificationContent _generateTimeBasedContent(UserContext context) {
    if (context.isMorning) {
      return _generateMorningContent(context);
    } else if (context.isAfternoon) {
      return _generateAfternoonContent(context);
    } else if (context.isEvening) {
      return _generateEveningContent(context);
    } else {
      return _generateNightContent(context);
    }
  }

  /// Mensagens para manhã (6-12h)
  NotificationContent _generateMorningContent(UserContext context) {
    final messages = [
      const NotificationContent(
        title: '🌅 Bom Dia!',
        body: 'Como você está se sentindo nesta manhã?',
        emoji: '🌅',
        payload: {'type': 'mood_reminder', 'time_period': 'morning'},
      ),
      const NotificationContent(
        title: '☀️ Novo Dia!',
        body: 'Um momento para registrar como você acordou hoje?',
        emoji: '☀️',
        payload: {'type': 'mood_reminder', 'time_period': 'morning'},
      ),
      const NotificationContent(
        title: '🌤️ Manhã!',
        body: 'Comece o dia registrando seu humor.',
        emoji: '🌤️',
        payload: {'type': 'mood_reminder', 'time_period': 'morning'},
      ),
      const NotificationContent(
        title: '☕ Hora do Check-in',
        body: 'Como está sua energia esta manhã?',
        emoji: '☕',
        payload: {'type': 'mood_reminder', 'time_period': 'morning'},
      ),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Mensagens para tarde (12-18h)
  NotificationContent _generateAfternoonContent(UserContext context) {
    final dayType = context.isWeekend ? 'fim de semana' : 'dia';
    final messages = [
      NotificationContent(
        title: '☀️ Boa Tarde!',
        body: 'Como está sendo seu $dayType até agora?',
        emoji: '☀️',
        payload: const {'type': 'mood_reminder', 'time_period': 'afternoon'},
      ),
      const NotificationContent(
        title: '🌞 Meio do Dia',
        body: 'Um momento para pausar e registrar como você está?',
        emoji: '🌞',
        payload: {'type': 'mood_reminder', 'time_period': 'afternoon'},
      ),
      NotificationContent(
        title: '📝 Check-in da Tarde',
        body: context.isWeekend
            ? 'Curtindo o fim de semana? Registre esse momento!'
            : 'Como está o ritmo do seu dia?',
        emoji: '📝',
        payload: const {'type': 'mood_reminder', 'time_period': 'afternoon'},
      ),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Mensagens para noite (18-22h)
  NotificationContent _generateEveningContent(UserContext context) {
    final messages = [
      const NotificationContent(
        title: '🌙 Boa Noite!',
        body: 'Como foi seu dia? Registre antes de encerrar.',
        emoji: '🌙',
        payload: {'type': 'mood_reminder', 'time_period': 'evening'},
      ),
      const NotificationContent(
        title: '🌆 Fim do Dia',
        body: 'Momento de reflexão: como você está se sentindo?',
        emoji: '🌆',
        payload: {'type': 'mood_reminder', 'time_period': 'evening'},
      ),
      const NotificationContent(
        title: '✨ Hora de Refletir',
        body: 'Um registro rápido antes de descansar?',
        emoji: '✨',
        payload: {'type': 'mood_reminder', 'time_period': 'evening'},
      ),
      const NotificationContent(
        title: '🌛 Noite Chegando',
        body: 'Último check-in do dia. Como você está?',
        emoji: '🌛',
        payload: {'type': 'mood_reminder', 'time_period': 'evening'},
      ),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Mensagens para madrugada (22-6h)
  NotificationContent _generateNightContent(UserContext context) {
    final messages = [
      const NotificationContent(
        title: '🌜 Ainda Acordado?',
        body: 'Registre como está antes de dormir.',
        emoji: '🌜',
        payload: {'type': 'mood_reminder', 'time_period': 'night'},
      ),
      const NotificationContent(
        title: '💤 Hora de Descansar',
        body: 'Um registro rápido antes de dormir?',
        emoji: '💤',
        payload: {'type': 'mood_reminder', 'time_period': 'night'},
      ),
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Gera conteúdo para alerta de streak em risco
  NotificationContent generateStreakRiskAlert(UserContext context) {
    final streak = context.currentStreak;

    if (streak >= 30) {
      return NotificationContent(
        title: '🚨 Streak Lendário em Risco!',
        body: 'Seus $streak dias de dedicação! Não deixe acabar agora!',
        emoji: '🚨',
        payload: {'type': 'streak_alert', 'streak': streak, 'urgency': 'critical'},
      );
    } else if (streak >= 14) {
      return NotificationContent(
        title: '⚠️ Streak em Perigo!',
        body: '$streak dias de progresso estão em jogo. Registre agora!',
        emoji: '⚠️',
        payload: {'type': 'streak_alert', 'streak': streak, 'urgency': 'high'},
      );
    } else if (streak >= 7) {
      return NotificationContent(
        title: '🔥 Não Perca seu Streak!',
        body: '$streak dias seguidos! Falta pouco para acabar o dia.',
        emoji: '🔥',
        payload: {'type': 'streak_alert', 'streak': streak, 'urgency': 'medium'},
      );
    } else {
      return NotificationContent(
        title: '💪 Mantenha o Ritmo!',
        body: 'Seu streak de $streak dias quer continuar crescendo!',
        emoji: '💪',
        payload: {'type': 'streak_alert', 'streak': streak, 'urgency': 'low'},
      );
    }
  }

  /// Gera conteúdo para notificação de re-engajamento
  NotificationContent generateReengagementContent(int daysInactive) {
    if (daysInactive >= 14) {
      final messages = [
        NotificationContent(
          title: '💜 Sentimos sua Falta',
          body: 'Faz $daysInactive dias... que tal um recomeço gentil?',
          emoji: '💜',
          payload: {'type': 'reengagement', 'days_inactive': daysInactive},
        ),
        NotificationContent(
          title: '🌱 Novo Começo?',
          body: 'Nunca é tarde para retomar. Um registro hoje?',
          emoji: '🌱',
          payload: {'type': 'reengagement', 'days_inactive': daysInactive},
        ),
      ];
      return messages[_random.nextInt(messages.length)];
    } else if (daysInactive >= 7) {
      final messages = [
        NotificationContent(
          title: '👋 Uma Semana!',
          body: 'Faz $daysInactive dias. Como você está?',
          emoji: '👋',
          payload: {'type': 'reengagement', 'days_inactive': daysInactive},
        ),
        NotificationContent(
          title: '🤗 Olá!',
          body: 'Sentimos sua falta! Que tal um check-in rápido?',
          emoji: '🤗',
          payload: {'type': 'reengagement', 'days_inactive': daysInactive},
        ),
      ];
      return messages[_random.nextInt(messages.length)];
    } else {
      final messages = [
        NotificationContent(
          title: '😊 Olá!',
          body: 'Faz $daysInactive dias desde seu último registro.',
          emoji: '😊',
          payload: {'type': 'reengagement', 'days_inactive': daysInactive},
        ),
        NotificationContent(
          title: '✨ Que tal hoje?',
          body: 'Um registro rápido para retomar o ritmo?',
          emoji: '✨',
          payload: {'type': 'reengagement', 'days_inactive': daysInactive},
        ),
      ];
      return messages[_random.nextInt(messages.length)];
    }
  }

  /// Gera conteúdo para notificação de level up
  NotificationContent generateLevelUpContent(int newLevel, String? unlockedTitle) {
    final levelMilestones = {
      5: 'Iniciante Dedicado',
      10: 'Explorador',
      15: 'Consistente',
      20: 'Veterano',
      25: 'Especialista',
      30: 'Mestre',
      40: 'Grão-Mestre',
      50: 'Lenda',
    };

    final milestone = levelMilestones[newLevel];

    if (milestone != null) {
      return NotificationContent(
        title: '🎊 Level $newLevel - $milestone!',
        body: unlockedTitle != null
            ? 'Novo título desbloqueado: "$unlockedTitle"!'
            : 'Você alcançou um marco importante!',
        emoji: '🎊',
        payload: {'type': 'level_up', 'level': newLevel, 'milestone': milestone},
      );
    }

    final emojis = ['🎉', '🎊', '🌟', '⭐', '🏆', '💫', '✨'];
    final emoji = emojis[_random.nextInt(emojis.length)];

    return NotificationContent(
      title: '$emoji Level $newLevel!',
      body: unlockedTitle != null
          ? 'Novo título: "$unlockedTitle"!'
          : 'Continue evoluindo!',
      emoji: emoji,
      payload: {'type': 'level_up', 'level': newLevel},
    );
  }

  /// Gera conteúdo para conquista
  NotificationContent generateAchievementContent({
    required String achievementName,
    required String description,
    String? rarity,
  }) {
    final rarityEmojis = {
      'common': '🥉',
      'uncommon': '🥈',
      'rare': '🥇',
      'epic': '💎',
      'legendary': '👑',
    };

    final emoji = rarityEmojis[rarity] ?? '🏅';

    return NotificationContent(
      title: '$emoji $achievementName',
      body: description,
      emoji: emoji,
      payload: {
        'type': 'achievement',
        'achievement_name': achievementName,
        'rarity': rarity ?? 'common',
      },
    );
  }

  /// Gera conteúdo para lembrete de Pomodoro
  NotificationContent generatePomodoroReminder(UserContext context) {
    final sessions = context.pomodoroSessionsToday;

    if (sessions == 0) {
      final messages = [
        const NotificationContent(
          title: '🍅 Hora de Focar!',
          body: 'Que tal uma sessão Pomodoro para começar o dia produtivo?',
          emoji: '🍅',
          payload: {'type': 'pomodoro_reminder', 'sessions_today': 0},
        ),
        const NotificationContent(
          title: '⏱️ Primeira Sessão?',
          body: 'Inicie um Pomodoro e conquiste o dia!',
          emoji: '⏱️',
          payload: {'type': 'pomodoro_reminder', 'sessions_today': 0},
        ),
      ];
      return messages[_random.nextInt(messages.length)];
    } else {
      return NotificationContent(
        title: '🍅 Continue Produtivo!',
        body: 'Já fez $sessions ${sessions == 1 ? "sessão" : "sessões"} hoje. Mais uma?',
        emoji: '🍅',
        payload: {'type': 'pomodoro_reminder', 'sessions_today': sessions},
      );
    }
  }

  /// Gera conteúdo para revisão semanal
  NotificationContent generateWeeklyReviewContent(UserContext context) {
    return NotificationContent(
      title: '📊 Revisão da Semana',
      body: 'Veja como foi sua semana e planeje a próxima!',
      emoji: '📊',
      payload: {
        'type': 'weekly_review',
        'streak': context.currentStreak,
        'level': context.level,
      },
    );
  }

  /// Gera insight diário personalizado
  NotificationContent generateDailyInsight(UserContext context) {
    final insights = <NotificationContent>[];

    // Insight baseado no streak
    if (context.currentStreak > 0 && context.currentStreak % 7 == 0) {
      insights.add(NotificationContent(
        title: '📈 Insight Semanal',
        body: '${context.currentStreak ~/ 7} ${context.currentStreak ~/ 7 == 1 ? "semana" : "semanas"} de consistência! Você está formando um hábito sólido.',
        emoji: '📈',
        payload: {'type': 'insight', 'insight_type': 'streak_weekly'},
      ));
    }

    // Insight baseado no nível
    if (context.level > 0 && context.level % 5 == 0) {
      insights.add(NotificationContent(
        title: '🎯 Marco de Nível',
        body: 'Nível ${context.level}! Cada nível representa seu comprometimento.',
        emoji: '🎯',
        payload: {'type': 'insight', 'insight_type': 'level_milestone'},
      ));
    }

    // Insight baseado em atividades do dia
    if (context.pomodoroSessionsToday >= 4) {
      insights.add(const NotificationContent(
        title: '🏆 Dia Produtivo!',
        body: 'Várias sessões de foco hoje. Lembre-se de descansar também!',
        emoji: '🏆',
        payload: {'type': 'insight', 'insight_type': 'productivity'},
      ));
    }

    // Se não houver insights específicos, gerar um genérico
    if (insights.isEmpty) {
      final genericInsights = [
        const NotificationContent(
          title: '💡 Dica do Dia',
          body: 'Registrar seu humor regularmente ajuda a identificar padrões.',
          emoji: '💡',
          payload: {'type': 'insight', 'insight_type': 'tip'},
        ),
        const NotificationContent(
          title: '🧠 Sabia que...',
          body: 'Autoconhecimento é a base para o bem-estar emocional.',
          emoji: '🧠',
          payload: {'type': 'insight', 'insight_type': 'fact'},
        ),
        const NotificationContent(
          title: '✨ Reflexão',
          body: 'Pequenos registros diários constroem grandes insights.',
          emoji: '✨',
          payload: {'type': 'insight', 'insight_type': 'reflection'},
        ),
      ];
      return genericInsights[_random.nextInt(genericInsights.length)];
    }

    return insights[_random.nextInt(insights.length)];
  }
}
