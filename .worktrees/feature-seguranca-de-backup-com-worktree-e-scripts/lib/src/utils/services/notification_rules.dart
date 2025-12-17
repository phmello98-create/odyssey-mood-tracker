import 'package:flutter/foundation.dart';

/// Tipos de trigger para notificações
enum NotificationTrigger {
  /// Baseado em tempo (horário do dia, dia da semana)
  timeBased,

  /// Baseado em comportamento do usuário
  behaviorBased,

  /// Baseado em padrões identificados
  patternBased,

  /// Baseado em eventos específicos
  eventBased,

  /// Baseado em inatividade
  inactivityBased,
}

/// Prioridade da notificação
enum NotificationPriority {
  urgent,
  high,
  medium,
  low,
}

/// Tipo de conteúdo inteligente
enum SmartContentType {
  /// Conteúdo padrão estático
  standard,

  /// Conteúdo adaptativo baseado em dados
  adaptive,

  /// Conteúdo totalmente personalizado
  personalized,

  /// Conteúdo contextual (clima, hora, etc)
  contextual,
}

/// Regra individual de notificação
class NotificationRule {
  final String id;
  final String name;
  final NotificationTrigger trigger;
  final String condition;
  final NotificationPriority priority;
  final SmartContentType contentType;
  final bool enabled;
  final Map<String, dynamic> metadata;

  const NotificationRule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.condition,
    this.priority = NotificationPriority.medium,
    this.contentType = SmartContentType.standard,
    this.enabled = true,
    this.metadata = const {},
  });

  NotificationRule copyWith({
    bool? enabled,
    NotificationPriority? priority,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationRule(
      id: id,
      name: name,
      trigger: trigger,
      condition: condition,
      priority: priority ?? this.priority,
      contentType: contentType,
      enabled: enabled ?? this.enabled,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Contexto do usuário para avaliação de regras
class UserContext {
  final int currentStreak;
  final int level;
  final int totalXP;
  final DateTime? lastMoodRecord;
  final DateTime? lastActivity;
  final int pomodoroSessionsToday;
  final int tasksCompletedToday;
  final int moodRecordsToday;
  final TimeOfDay currentTime;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final bool isWeekend;

  UserContext({
    required this.currentStreak,
    required this.level,
    required this.totalXP,
    this.lastMoodRecord,
    this.lastActivity,
    required this.pomodoroSessionsToday,
    required this.tasksCompletedToday,
    required this.moodRecordsToday,
    required this.currentTime,
    required this.dayOfWeek,
    required this.isWeekend,
  });

  /// Cria contexto a partir do estado atual
  factory UserContext.fromCurrentState({
    required int currentStreak,
    required int level,
    required int totalXP,
    DateTime? lastMoodRecord,
    DateTime? lastActivity,
    required int pomodoroSessionsToday,
    required int tasksCompletedToday,
    required int moodRecordsToday,
  }) {
    final now = DateTime.now();
    return UserContext(
      currentStreak: currentStreak,
      level: level,
      totalXP: totalXP,
      lastMoodRecord: lastMoodRecord,
      lastActivity: lastActivity,
      pomodoroSessionsToday: pomodoroSessionsToday,
      tasksCompletedToday: tasksCompletedToday,
      moodRecordsToday: moodRecordsToday,
      currentTime: TimeOfDay.fromDateTime(now),
      dayOfWeek: now.weekday,
      isWeekend: now.weekday == 6 || now.weekday == 7,
    );
  }

  /// Verifica se é manhã (6-12h)
  bool get isMorning => currentTime.hour >= 6 && currentTime.hour < 12;

  /// Verifica se é tarde (12-18h)
  bool get isAfternoon => currentTime.hour >= 12 && currentTime.hour < 18;

  /// Verifica se é noite (18-22h)
  bool get isEvening => currentTime.hour >= 18 && currentTime.hour < 22;

  /// Verifica se é madrugada (22-6h)
  bool get isNight => currentTime.hour >= 22 || currentTime.hour < 6;

  /// Dias desde último registro de humor
  int get daysSinceLastMood {
    if (lastMoodRecord == null) return 999;
    return DateTime.now().difference(lastMoodRecord!).inDays;
  }

  /// Dias desde última atividade
  int get daysSinceLastActivity {
    if (lastActivity == null) return 999;
    return DateTime.now().difference(lastActivity!).inDays;
  }

  /// Horas desde último registro de humor
  int get hoursSinceLastMood {
    if (lastMoodRecord == null) return 999;
    return DateTime.now().difference(lastMoodRecord!).inHours;
  }
}

/// Sistema de regras de notificação inteligentes
class NotificationRulesEngine {
  static final NotificationRulesEngine _instance = NotificationRulesEngine._();
  static NotificationRulesEngine get instance => _instance;

  NotificationRulesEngine._();

  /// Regras pré-definidas
  static const Map<String, NotificationRule> defaultRules = {
    'mood_reminder_morning': NotificationRule(
      id: 'mood_reminder_morning',
      name: 'Lembrete de Humor Matinal',
      trigger: NotificationTrigger.timeBased,
      condition: 'time_morning AND no_mood_today',
      priority: NotificationPriority.medium,
      contentType: SmartContentType.contextual,
    ),
    'mood_reminder_evening': NotificationRule(
      id: 'mood_reminder_evening',
      name: 'Lembrete de Humor Noturno',
      trigger: NotificationTrigger.timeBased,
      condition: 'time_evening AND no_mood_today',
      priority: NotificationPriority.high,
      contentType: SmartContentType.contextual,
    ),
    'streak_risk': NotificationRule(
      id: 'streak_risk',
      name: 'Streak em Risco',
      trigger: NotificationTrigger.behaviorBased,
      condition: 'streak >= 3 AND no_activity_today AND time_evening',
      priority: NotificationPriority.urgent,
      contentType: SmartContentType.personalized,
    ),
    'productivity_boost': NotificationRule(
      id: 'productivity_boost',
      name: 'Boost de Produtividade',
      trigger: NotificationTrigger.patternBased,
      condition: 'pomodoro_today < 2 AND time_afternoon AND is_weekday',
      priority: NotificationPriority.medium,
      contentType: SmartContentType.adaptive,
    ),
    'weekly_review': NotificationRule(
      id: 'weekly_review',
      name: 'Revisão Semanal',
      trigger: NotificationTrigger.timeBased,
      condition: 'is_sunday AND time_evening',
      priority: NotificationPriority.medium,
      contentType: SmartContentType.personalized,
    ),
    'level_up_celebration': NotificationRule(
      id: 'level_up_celebration',
      name: 'Celebração de Level Up',
      trigger: NotificationTrigger.eventBased,
      condition: 'just_leveled_up',
      priority: NotificationPriority.high,
      contentType: SmartContentType.personalized,
    ),
    'comeback_gentle': NotificationRule(
      id: 'comeback_gentle',
      name: 'Re-engajamento Gentil',
      trigger: NotificationTrigger.inactivityBased,
      condition: 'days_inactive >= 3 AND days_inactive < 7',
      priority: NotificationPriority.low,
      contentType: SmartContentType.adaptive,
    ),
    'comeback_urgent': NotificationRule(
      id: 'comeback_urgent',
      name: 'Re-engajamento Urgente',
      trigger: NotificationTrigger.inactivityBased,
      condition: 'days_inactive >= 7',
      priority: NotificationPriority.medium,
      contentType: SmartContentType.personalized,
    ),
    'first_pomodoro_day': NotificationRule(
      id: 'first_pomodoro_day',
      name: 'Primeira Sessão do Dia',
      trigger: NotificationTrigger.timeBased,
      condition: 'time_morning AND pomodoro_today == 0 AND is_weekday',
      priority: NotificationPriority.low,
      contentType: SmartContentType.contextual,
    ),
  };

  /// Avalia uma regra contra o contexto do usuário
  bool evaluateRule(NotificationRule rule, UserContext context) {
    if (!rule.enabled) return false;

    try {
      return _evaluateCondition(rule.condition, context);
    } catch (e) {
      debugPrint('❌ Erro ao avaliar regra ${rule.id}: $e');
      return false;
    }
  }

  /// Avalia a condição de uma regra
  bool _evaluateCondition(String condition, UserContext context) {
    // Parser simples para condições AND
    final parts = condition.split(' AND ').map((p) => p.trim()).toList();

    for (final part in parts) {
      if (!_evaluateSingleCondition(part, context)) {
        return false;
      }
    }

    return true;
  }

  /// Avalia uma condição individual
  bool _evaluateSingleCondition(String condition, UserContext context) {
    // Condições de tempo
    if (condition == 'time_morning') return context.isMorning;
    if (condition == 'time_afternoon') return context.isAfternoon;
    if (condition == 'time_evening') return context.isEvening;
    if (condition == 'time_night') return context.isNight;

    // Condições de dia
    if (condition == 'is_weekday') return !context.isWeekend;
    if (condition == 'is_weekend') return context.isWeekend;
    if (condition == 'is_sunday') return context.dayOfWeek == 7;
    if (condition == 'is_monday') return context.dayOfWeek == 1;

    // Condições de atividade
    if (condition == 'no_mood_today') return context.moodRecordsToday == 0;
    if (condition == 'no_activity_today') return context.daysSinceLastActivity >= 1;

    // Condições com comparação
    if (condition.contains('>=')) {
      final parts = condition.split('>=').map((p) => p.trim()).toList();
      final value = _getContextValue(parts[0], context);
      final threshold = int.tryParse(parts[1]) ?? 0;
      return value >= threshold;
    }

    if (condition.contains('<=')) {
      final parts = condition.split('<=').map((p) => p.trim()).toList();
      final value = _getContextValue(parts[0], context);
      final threshold = int.tryParse(parts[1]) ?? 0;
      return value <= threshold;
    }

    if (condition.contains('<')) {
      final parts = condition.split('<').map((p) => p.trim()).toList();
      final value = _getContextValue(parts[0], context);
      final threshold = int.tryParse(parts[1]) ?? 0;
      return value < threshold;
    }

    if (condition.contains('>')) {
      final parts = condition.split('>').map((p) => p.trim()).toList();
      final value = _getContextValue(parts[0], context);
      final threshold = int.tryParse(parts[1]) ?? 0;
      return value > threshold;
    }

    if (condition.contains('==')) {
      final parts = condition.split('==').map((p) => p.trim()).toList();
      final value = _getContextValue(parts[0], context);
      final threshold = int.tryParse(parts[1]) ?? 0;
      return value == threshold;
    }

    debugPrint('⚠️ Condição não reconhecida: $condition');
    return false;
  }

  /// Obtém valor do contexto baseado no nome
  int _getContextValue(String name, UserContext context) {
    switch (name) {
      case 'streak':
        return context.currentStreak;
      case 'level':
        return context.level;
      case 'total_xp':
        return context.totalXP;
      case 'pomodoro_today':
        return context.pomodoroSessionsToday;
      case 'tasks_today':
        return context.tasksCompletedToday;
      case 'mood_today':
        return context.moodRecordsToday;
      case 'days_inactive':
        return context.daysSinceLastActivity;
      case 'hours_since_mood':
        return context.hoursSinceLastMood;
      default:
        debugPrint('⚠️ Nome de contexto não reconhecido: $name');
        return 0;
    }
  }

  /// Obtém todas as regras que devem ser ativadas para o contexto atual
  List<NotificationRule> getTriggeredRules(UserContext context) {
    final triggeredRules = <NotificationRule>[];

    for (final rule in defaultRules.values) {
      if (evaluateRule(rule, context)) {
        triggeredRules.add(rule);
      }
    }

    // Ordenar por prioridade
    triggeredRules.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return triggeredRules;
  }

  /// Obtém a regra de maior prioridade que deve ser ativada
  NotificationRule? getHighestPriorityRule(UserContext context) {
    final triggered = getTriggeredRules(context);
    return triggered.isNotEmpty ? triggered.first : null;
  }

  /// Verifica se uma regra específica deve ser ativada
  bool shouldTriggerRule(String ruleId, UserContext context) {
    final rule = defaultRules[ruleId];
    if (rule == null) return false;
    return evaluateRule(rule, context);
  }
}

/// Helper class para TimeOfDay
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dt) {
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  factory TimeOfDay.now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }
}
