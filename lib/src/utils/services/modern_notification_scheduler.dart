import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odyssey/src/utils/services/modern_notification_service.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';

/// Scheduler moderno de notificações
/// Gerencia todas as notificações automáticas do app
class ModernNotificationScheduler {
  static final ModernNotificationScheduler _instance =
      ModernNotificationScheduler._();
  static ModernNotificationScheduler get instance => _instance;

  ModernNotificationScheduler._();

  SharedPreferences? _prefs;
  TaskRepository? _taskRepo;
  HabitRepository? _habitRepo;

  Timer? _dailyCheckTimer;
  bool _initialized = false;

  // Chaves de configuração
  static const String _keyMoodReminderEnabled = 'modern_notif_mood_enabled';
  static const String _keyMoodReminderTime = 'modern_notif_mood_time'; // HH:mm
  static const String _keyTaskReminderEnabled = 'modern_notif_task_enabled';
  static const String _keyTaskCheckInterval =
      'modern_notif_task_interval'; // minutos
  static const String _keyHabitReminderEnabled = 'modern_notif_habit_enabled';
  static const String _keyHabitCheckInterval =
      'modern_notif_habit_interval'; // minutos
  static const String _keyMotivationEnabled = 'modern_notif_motivation_enabled';
  static const String _keyMotivationFrequency =
      'modern_notif_motivation_freq'; // por dia

  /// Inicializa o scheduler
  Future<void> initialize({
    TaskRepository? taskRepo,
    HabitRepository? habitRepo,
  }) async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _taskRepo = taskRepo;
    _habitRepo = habitRepo;

    // Configurar defaults
    await _setDefaultsIfNeeded();

    // Agendar notificações
    await _scheduleDailyNotifications();

    // Iniciar timers de verificação
    _startDailyCheckTimer();

    _initialized = true;
    debugPrint('📅 ModernNotificationScheduler inicializado');
  }

  /// Define configurações padrão
  Future<void> _setDefaultsIfNeeded() async {
    if (!_prefs!.containsKey(_keyMoodReminderEnabled)) {
      await _prefs!.setBool(_keyMoodReminderEnabled, false);
      await _prefs!.setString(_keyMoodReminderTime, '20:00');
    }
    if (!_prefs!.containsKey(_keyTaskReminderEnabled)) {
      await _prefs!.setBool(_keyTaskReminderEnabled, false);
      await _prefs!.setInt(_keyTaskCheckInterval, 60); // 1 hora
    }
    if (!_prefs!.containsKey(_keyHabitReminderEnabled)) {
      await _prefs!.setBool(_keyHabitReminderEnabled, false);
      await _prefs!.setInt(_keyHabitCheckInterval, 180); // 3 horas
    }
    if (!_prefs!.containsKey(_keyMotivationEnabled)) {
      await _prefs!.setBool(_keyMotivationEnabled, false);
      await _prefs!.setInt(_keyMotivationFrequency, 2); // 2x por dia
    }
  }

  /// Agenda notificações diárias
  Future<void> _scheduleDailyNotifications() async {
    // Agendar lembrete de humor
    if (_prefs!.getBool(_keyMoodReminderEnabled) ?? false) {
      await _scheduleMoodReminder();
    }
  }

  /// Agenda lembrete de humor
  Future<void> _scheduleMoodReminder() async {
    final timeStr = _prefs!.getString(_keyMoodReminderTime) ?? '20:00';
    final timeParts = timeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Se já passou hoje, agendar para amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await ModernNotificationService.instance.sendMoodReminder(
      title: 'Como você está se sentindo?',
      body: 'Registre seu humor de hoje e ganhe XP!',
      scheduledDate: scheduledDate,
    );

    debugPrint(
      '📅 Lembrete de humor agendado para ${scheduledDate.hour}:${scheduledDate.minute}',
    );
  }

  /// Inicia timer de verificação diária
  void _startDailyCheckTimer() {
    // Verificar a cada hora se há notificações para enviar
    _dailyCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _checkAndSendNotifications();
    });

    // SKIP notificação inicial na primeira execução para evitar spam de dados seed
    final isFirstLaunch =
        !(_prefs!.getBool('_notif_scheduler_initialized') ?? false);
    if (isFirstLaunch) {
      // Marcar como inicializado para que futuras aberturas chequem normalmente
      _prefs!.setBool('_notif_scheduler_initialized', true);
      debugPrint('🔔 Pulando verificação inicial (primeira execução do app)');
      return;
    }

    // Verificação inicial para execuções subsequentes
    // Aguardar um pouco para não spamar notificações assim que o app abre
    Future.delayed(const Duration(seconds: 10), () {
      if (_dailyCheckTimer != null && _dailyCheckTimer!.isActive) {
        _checkAndSendNotifications();
      }
    });
  }

  /// Verifica e envia notificações pendentes
  Future<void> _checkAndSendNotifications() async {
    debugPrint('🔔 Verificando notificações pendentes...');

    // Verificar tarefas
    if (_prefs!.getBool(_keyTaskReminderEnabled) ?? false) {
      await _checkPendingTasks();
    }

    // Verificar hábitos
    if (_prefs!.getBool(_keyHabitReminderEnabled) ?? false) {
      await _checkPendingHabits();
    }

    // Enviar motivação aleatória
    if (_prefs!.getBool(_keyMotivationEnabled) ?? false) {
      await _maybeSendMotivation();
    }
  }

  /// Verifica e notifica tarefas pendentes
  Future<void> _checkPendingTasks() async {
    if (_taskRepo == null) return;

    try {
      final now = DateTime.now();
      final tasks = await _taskRepo!.getAllTasks();

      // Tarefas para hoje que não foram concluídas
      final todayTasks = tasks.where((task) {
        if (task.completed) return false;
        if (task.dueDate == null) return false;

        final dueDate = task.dueDate!;
        return dueDate.year == now.year &&
            dueDate.month == now.month &&
            dueDate.day == now.day;
      }).toList();

      // Tarefas atrasadas
      final overdueTasks = tasks.where((task) {
        if (task.completed) return false;
        if (task.dueDate == null) return false;
        return task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
      }).toList();

      debugPrint(
        '📋 Tarefas hoje: ${todayTasks.length}, Atrasadas: ${overdueTasks.length}',
      );

      // Notificar tarefas importantes
      if (todayTasks.isNotEmpty) {
        final task = todayTasks.first;
        await ModernNotificationService.instance.sendTaskReminder(
          taskId: task.key.hashCode,
          taskTitle: task.title,
          taskDescription: task.notes ?? '',
          dueDate: task.dueDate,
        );
      }

      if (overdueTasks.isNotEmpty && todayTasks.isEmpty) {
        final task = overdueTasks.first;
        await ModernNotificationService.instance.sendTaskReminder(
          taskId: task.key.hashCode,
          taskTitle: task.title,
          taskDescription: task.notes ?? '',
          dueDate: task.dueDate,
        );
      }
    } catch (e) {
      debugPrint('Erro ao verificar tarefas: $e');
    }
  }

  /// Verifica e notifica hábitos pendentes
  Future<void> _checkPendingHabits() async {
    if (_habitRepo == null) return;

    try {
      final habits = _habitRepo!.getAllHabits();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Hábitos de hoje que não foram feitos
      final pendingHabits = habits.where((habit) {
        // Verificar se é dia de fazer esse hábito
        final weekday = now.weekday; // 1=Monday, 7=Sunday
        if (habit.daysOfWeek.isNotEmpty &&
            !habit.daysOfWeek.contains(weekday)) {
          return false;
        }

        // Verificar se já foi feito hoje
        return !habit.completedDates.any(
          (date) =>
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day,
        );
      }).toList();

      debugPrint('💪 Hábitos pendentes hoje: ${pendingHabits.length}');

      if (pendingHabits.isNotEmpty) {
        final habit = pendingHabits.first;

        await ModernNotificationService.instance.sendHabitReminder(
          habitId: habit.hashCode,
          habitName: habit.name,
          habitDescription: '', // Habit não tem description
          streak: habit.currentStreak,
        );
      }
    } catch (e) {
      debugPrint('Erro ao verificar hábitos: $e');
    }
  }

  /// Envia notificação motivacional (aleatória)
  Future<void> _maybeSendMotivation() async {
    // Verificar frequência configurada
    final frequency = _prefs!.getInt(_keyMotivationFrequency) ?? 2;

    // Verificar última notificação motivacional
    final lastMotivation = _prefs!.getString('last_motivation_date') ?? '';
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    if (lastMotivation == todayKey) {
      final count = _prefs!.getInt('motivation_count_today') ?? 0;
      if (count >= frequency) {
        return; // Já enviou o suficiente hoje
      }
    }

    // Frases motivacionais
    final motivations = [
      {
        'title': '💪 Você consegue!',
        'body': 'Cada pequeno passo te leva mais perto do seu objetivo.',
      },
      {
        'title': '🌟 Brilhe!',
        'body': 'Sua consistência é o que te diferencia. Continue assim!',
      },
      {
        'title': '🔥 Foco total!',
        'body': 'Lembre-se por que você começou. Você está indo muito bem!',
      },
      {
        'title': '🚀 Em ascensão!',
        'body': 'Seu progresso é real. Não desista agora!',
      },
      {
        'title': '✨ Incrível!',
        'body': 'Você está construindo hábitos que mudarão sua vida.',
      },
      {
        'title': '🎯 No alvo!',
        'body':
            'Disciplina é escolher entre o que você quer agora e o que você mais quer.',
      },
      {
        'title': '💎 Valioso!',
        'body': 'Seu tempo e esforço são investimentos no seu futuro.',
      },
      {
        'title': '🌈 Positivo!',
        'body': 'Cada dia é uma nova oportunidade de ser melhor.',
      },
      {
        'title': '⭐ Estrela!',
        'body': 'Você tem o poder de transformar sua rotina.',
      },
      {
        'title': '🏆 Campeão!',
        'body': 'Grandes conquistas começam com pequenas ações diárias.',
      },
    ];

    final random = motivations[DateTime.now().millisecond % motivations.length];

    await ModernNotificationService.instance.sendMotivationalNotification(
      title: random['title']!,
      body: random['body']!,
    );

    // Atualizar contador
    if (lastMotivation != todayKey) {
      await _prefs!.setString('last_motivation_date', todayKey);
      await _prefs!.setInt('motivation_count_today', 1);
    } else {
      final count = _prefs!.getInt('motivation_count_today') ?? 0;
      await _prefs!.setInt('motivation_count_today', count + 1);
    }
  }

  // ==================== CONFIGURAÇÕES ====================

  /// Habilita/desabilita lembrete de humor
  Future<void> setMoodReminderEnabled(bool enabled) async {
    await _prefs!.setBool(_keyMoodReminderEnabled, enabled);
    if (enabled) {
      await _scheduleMoodReminder();
    } else {
      await ModernNotificationService.instance.cancelNotification(
        ModernNotificationService.moodReminderId,
      );
    }
  }

  /// Define horário do lembrete de humor
  Future<void> setMoodReminderTime(int hour, int minute) async {
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    await _prefs!.setString(_keyMoodReminderTime, timeStr);
    if (_prefs!.getBool(_keyMoodReminderEnabled) ?? false) {
      await _scheduleMoodReminder();
    }
  }

  /// Habilita/desabilita lembretes de tarefas
  Future<void> setTaskReminderEnabled(bool enabled) async {
    await _prefs!.setBool(_keyTaskReminderEnabled, enabled);
  }

  /// Habilita/desabilita lembretes de hábitos
  Future<void> setHabitReminderEnabled(bool enabled) async {
    await _prefs!.setBool(_keyHabitReminderEnabled, enabled);
  }

  /// Habilita/desabilita mensagens motivacionais
  Future<void> setMotivationEnabled(bool enabled) async {
    await _prefs!.setBool(_keyMotivationEnabled, enabled);
  }

  /// Define frequência de mensagens motivacionais
  Future<void> setMotivationFrequency(int perDay) async {
    await _prefs!.setInt(_keyMotivationFrequency, perDay);
  }

  // ==================== GETTERS ====================

  bool get isMoodReminderEnabled =>
      _prefs!.getBool(_keyMoodReminderEnabled) ?? false;
  String get moodReminderTime =>
      _prefs!.getString(_keyMoodReminderTime) ?? '20:00';
  bool get isTaskReminderEnabled =>
      _prefs!.getBool(_keyTaskReminderEnabled) ?? false;
  bool get isHabitReminderEnabled =>
      _prefs!.getBool(_keyHabitReminderEnabled) ?? false;
  bool get isMotivationEnabled =>
      _prefs!.getBool(_keyMotivationEnabled) ?? false;
  int get motivationFrequency => _prefs!.getInt(_keyMotivationFrequency) ?? 2;

  /// Limpa timer ao descartar
  void dispose() {
    _dailyCheckTimer?.cancel();
  }
}
