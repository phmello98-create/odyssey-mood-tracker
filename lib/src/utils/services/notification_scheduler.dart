import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// IDs de notificação para o scheduler
class SchedulerNotificationIds {
  static const int moodMorning = 2001;
  static const int moodEvening = 2002;
  static const int habitReminderBase = 3000; // 3000-3999
  static const int taskReminderBase = 4000; // 4000-4999
  static const int motivationBase = 5000; // 5000-5099
  static const int habitPendingCheck = 6001;
  static const int taskPendingCheck = 6002;
}

/// Frases motivacionais do app
class MotivationalQuotes {
  static final List<Map<String, String>> quotes = [
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
    {
      'title': '🌱 Crescendo!',
      'body': 'Seu jardim de hábitos está florescendo. Continue regando!',
    },
    {
      'title': '💜 Autoamor',
      'body': 'Cuidar de você é a base para cuidar de tudo mais.',
    },
    {
      'title': '🎨 Criativo!',
      'body': 'Você está pintando sua melhor versão, um dia de cada vez.',
    },
    {'title': '🌊 Flua!', 'body': 'Seja como a água: persistente e adaptável.'},
    {
      'title': '🦋 Transformação',
      'body': 'Cada registro é um passo na sua jornada de evolução.',
    },
  ];

  static Map<String, String> getRandom() {
    return quotes[Random().nextInt(quotes.length)];
  }
}

/// Serviço de agendamento de notificações automáticas
class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._();
  static NotificationScheduler get instance => _instance;

  NotificationScheduler._();

  Timer? _habitCheckTimer;
  Timer? _taskCheckTimer;
  Timer? _motivationTimer;
  SharedPreferences? _prefs;
  HabitRepository? _habitRepo;
  TaskRepository? _taskRepo;
  bool _initialized = false;

  // Configurações
  static const String _keyMoodMorningEnabled = 'notif_mood_morning_enabled';
  static const String _keyMoodMorningHour = 'notif_mood_morning_hour';
  static const String _keyMoodEveningEnabled = 'notif_mood_evening_enabled';
  static const String _keyMoodEveningHour = 'notif_mood_evening_hour';
  static const String _keyHabitReminderEnabled = 'notif_habit_reminder_enabled';
  static const String _keyHabitReminderInterval =
      'notif_habit_reminder_interval';
  static const String _keyTaskReminderEnabled = 'notif_task_reminder_enabled';
  static const String _keyTaskReminderInterval = 'notif_task_reminder_interval';
  static const String _keyMotivationEnabled = 'notif_motivation_enabled';
  static const String _keyMotivationPerDay = 'notif_motivation_per_day';

  /// Inicializa o scheduler
  Future<void> initialize({
    HabitRepository? habitRepo,
    TaskRepository? taskRepo,
  }) async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _habitRepo = habitRepo;
    _taskRepo = taskRepo;

    // Configurar defaults se não existirem
    await _setDefaultsIfNeeded();

    // Agendar notificações de humor
    await _scheduleMoodReminders();

    // Iniciar timers de verificação
    _startHabitCheckTimer();
    _startTaskCheckTimer();
    _startMotivationTimer();

    _initialized = true;
    debugPrint('📅 NotificationScheduler inicializado');
  }

  /// Define valores padrão se não existirem
  Future<void> _setDefaultsIfNeeded() async {
    if (!_prefs!.containsKey(_keyMoodMorningEnabled)) {
      await _prefs!.setBool(_keyMoodMorningEnabled, false);
    }
    if (!_prefs!.containsKey(_keyMoodMorningHour)) {
      await _prefs!.setInt(_keyMoodMorningHour, 8);
    }
    if (!_prefs!.containsKey(_keyMoodEveningEnabled)) {
      await _prefs!.setBool(_keyMoodEveningEnabled, false);
    }
    if (!_prefs!.containsKey(_keyMoodEveningHour)) {
      await _prefs!.setInt(_keyMoodEveningHour, 20);
    }
    if (!_prefs!.containsKey(_keyHabitReminderEnabled)) {
      await _prefs!.setBool(_keyHabitReminderEnabled, false);
    }
    if (!_prefs!.containsKey(_keyHabitReminderInterval)) {
      await _prefs!.setInt(_keyHabitReminderInterval, 30); // minutos
    }
    if (!_prefs!.containsKey(_keyTaskReminderEnabled)) {
      await _prefs!.setBool(_keyTaskReminderEnabled, false);
    }
    if (!_prefs!.containsKey(_keyTaskReminderInterval)) {
      await _prefs!.setInt(_keyTaskReminderInterval, 30); // minutos
    }
    if (!_prefs!.containsKey(_keyMotivationEnabled)) {
      await _prefs!.setBool(_keyMotivationEnabled, false);
    }
    if (!_prefs!.containsKey(_keyMotivationPerDay)) {
      await _prefs!.setInt(_keyMotivationPerDay, 3); // vezes por dia
    }
  }

  // ============================================
  // LEMBRETES DE HUMOR (8h e 20h)
  // ============================================

  /// Agenda lembretes de humor para manhã e noite
  Future<void> _scheduleMoodReminders() async {
    final morningEnabled = _prefs!.getBool(_keyMoodMorningEnabled) ?? false;
    final morningHour = _prefs!.getInt(_keyMoodMorningHour) ?? 8;
    final eveningEnabled = _prefs!.getBool(_keyMoodEveningEnabled) ?? false;
    final eveningHour = _prefs!.getInt(_keyMoodEveningHour) ?? 20;

    // Cancelar existentes
    await NotificationService.instance.cancelMoodReminder();

    // Agendar manhã
    if (morningEnabled) {
      await _scheduleDailyNotification(
        id: SchedulerNotificationIds.moodMorning,
        hour: morningHour,
        minute: 0,
        title: '🌅 Bom dia! Como você está?',
        body: 'Registre seu humor para começar o dia com autoconhecimento.',
        channelKey: NotificationService.channelReminders,
      );
      debugPrint('📅 Lembrete de humor manhã agendado para ${morningHour}h');
    }

    // Agendar noite
    if (eveningEnabled) {
      await _scheduleDailyNotification(
        id: SchedulerNotificationIds.moodEvening,
        hour: eveningHour,
        minute: 0,
        title: '🌙 Hora de refletir!',
        body: 'Como foi seu dia? Registre seu humor antes de dormir.',
        channelKey: NotificationService.channelReminders,
      );
      debugPrint('📅 Lembrete de humor noite agendado para ${eveningHour}h');
    }
  }

  /// Atualiza configuração de lembrete de humor
  Future<void> updateMoodReminderSettings({
    bool? morningEnabled,
    int? morningHour,
    bool? eveningEnabled,
    int? eveningHour,
  }) async {
    if (morningEnabled != null) {
      await _prefs!.setBool(_keyMoodMorningEnabled, morningEnabled);
    }
    if (morningHour != null) {
      await _prefs!.setInt(_keyMoodMorningHour, morningHour);
    }
    if (eveningEnabled != null) {
      await _prefs!.setBool(_keyMoodEveningEnabled, eveningEnabled);
    }
    if (eveningHour != null) {
      await _prefs!.setInt(_keyMoodEveningHour, eveningHour);
    }

    await _scheduleMoodReminders();
  }

  // ============================================
  // LEMBRETES DE HÁBITOS (a cada 30min)
  // ============================================

  /// Inicia timer de verificação de hábitos pendentes
  void _startHabitCheckTimer() {
    _habitCheckTimer?.cancel();

    final enabled = _prefs!.getBool(_keyHabitReminderEnabled) ?? false;
    if (!enabled) return;

    final intervalMinutes = _prefs!.getInt(_keyHabitReminderInterval) ?? 30;

    _habitCheckTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _checkPendingHabits(),
    );

    // NÃO verificar imediatamente - evita notificações no primeiro uso
    // _checkPendingHabits();

    debugPrint(
      '📅 Timer de hábitos iniciado (intervalo: ${intervalMinutes}min)',
    );
  }

  /// Verifica hábitos pendentes e envia notificação
  Future<void> _checkPendingHabits() async {
    if (_habitRepo == null) return;

    try {
      final today = DateTime.now();
      final habits = _habitRepo!.getHabitsForDate(today);
      final pendingHabits = habits
          .where((h) => !h.isCompletedOn(today))
          .toList();

      if (pendingHabits.isEmpty) return;

      // Não notificar fora do horário ativo (8h-22h)
      final hour = today.hour;
      if (hour < 8 || hour > 22) return;

      final count = pendingHabits.length;
      final habitNames = pendingHabits.take(3).map((h) => h.name).join(', ');
      final suffix = count > 3 ? ' e mais ${count - 3}' : '';

      await _showInstantNotification(
        id: SchedulerNotificationIds.habitPendingCheck,
        title:
            '🎯 $count ${count == 1 ? 'hábito pendente' : 'hábitos pendentes'}',
        body: '$habitNames$suffix ainda não foram concluídos hoje.',
        channelKey: NotificationService.channelReminders,
      );

      debugPrint('📅 Notificação de hábitos pendentes enviada ($count)');
    } catch (e) {
      debugPrint('❌ Erro ao verificar hábitos pendentes: $e');
    }
  }

  /// Atualiza configuração de lembretes de hábitos
  Future<void> updateHabitReminderSettings({
    bool? enabled,
    int? intervalMinutes,
  }) async {
    if (enabled != null) {
      await _prefs!.setBool(_keyHabitReminderEnabled, enabled);
    }
    if (intervalMinutes != null) {
      await _prefs!.setInt(_keyHabitReminderInterval, intervalMinutes);
    }

    _startHabitCheckTimer();
  }

  // ============================================
  // LEMBRETES DE TAREFAS (a cada 30min + horário específico)
  // ============================================

  /// Inicia timer de verificação de tarefas pendentes
  void _startTaskCheckTimer() {
    _taskCheckTimer?.cancel();

    final enabled = _prefs!.getBool(_keyTaskReminderEnabled) ?? false;
    if (!enabled) return;

    final intervalMinutes = _prefs!.getInt(_keyTaskReminderInterval) ?? 30;

    _taskCheckTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _checkPendingTasks(),
    );

    // NÃO verificar imediatamente - evita notificações no primeiro uso
    // _checkPendingTasks();

    debugPrint(
      '📅 Timer de tarefas iniciado (intervalo: ${intervalMinutes}min)',
    );
  }

  /// Verifica tarefas pendentes e envia notificação
  Future<void> _checkPendingTasks() async {
    if (_taskRepo == null) return;

    try {
      final pendingTasks = await _taskRepo!.getPendingTasks();

      if (pendingTasks.isEmpty) return;

      // Não notificar fora do horário ativo (8h-22h)
      final hour = DateTime.now().hour;
      if (hour < 8 || hour > 22) return;

      // Filtrar tarefas para hoje ou atrasadas
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final relevantTasks = pendingTasks.where((t) {
        if (t.dueDate == null) return true; // Sem data = sempre relevante
        return t.dueDate!.isBefore(now) || // Atrasada
            (t.dueDate!.year == now.year &&
                t.dueDate!.month == now.month &&
                t.dueDate!.day == now.day); // Hoje
      }).toList();

      if (relevantTasks.isEmpty) return;

      final count = relevantTasks.length;
      final taskNames = relevantTasks.take(3).map((t) => t.title).join(', ');
      final suffix = count > 3 ? ' e mais ${count - 3}' : '';

      // Verificar se tem tarefas atrasadas
      final overdue = relevantTasks
          .where((t) => t.dueDate != null && t.dueDate!.isBefore(todayStart))
          .toList();

      String title;
      String body;

      if (overdue.isNotEmpty) {
        title =
            '⚠️ ${overdue.length} ${overdue.length == 1 ? 'tarefa atrasada' : 'tarefas atrasadas'}!';
        body = '$taskNames$suffix precisam de atenção.';
      } else {
        title =
            '✅ $count ${count == 1 ? 'tarefa pendente' : 'tarefas pendentes'}';
        body = '$taskNames$suffix para hoje.';
      }

      await _showInstantNotification(
        id: SchedulerNotificationIds.taskPendingCheck,
        title: title,
        body: body,
        channelKey: NotificationService.channelReminders,
      );

      debugPrint('📅 Notificação de tarefas pendentes enviada ($count)');
    } catch (e) {
      debugPrint('❌ Erro ao verificar tarefas pendentes: $e');
    }
  }

  /// Agenda lembrete para tarefa específica no horário definido pelo usuário
  Future<void> scheduleTaskAtTime({
    required String taskId,
    required String title,
    required DateTime when,
    String? body,
  }) async {
    await NotificationService.instance.scheduleTaskReminder(
      taskId: taskId,
      title: title,
      body: body ?? 'Lembrete da tarefa agendada',
      when: when,
    );
    debugPrint('📅 Tarefa "$title" agendada para ${when.hour}:${when.minute}');
  }

  /// Cancela lembrete de tarefa específica
  Future<void> cancelTaskReminder(String taskId) async {
    await NotificationService.instance.cancelTaskReminder(taskId);
  }

  /// Atualiza configuração de lembretes de tarefas
  Future<void> updateTaskReminderSettings({
    bool? enabled,
    int? intervalMinutes,
  }) async {
    if (enabled != null) {
      await _prefs!.setBool(_keyTaskReminderEnabled, enabled);
    }
    if (intervalMinutes != null) {
      await _prefs!.setInt(_keyTaskReminderInterval, intervalMinutes);
    }

    _startTaskCheckTimer();
  }

  // ============================================
  // NOTIFICAÇÕES DE MOTIVAÇÃO (aleatórias)
  // ============================================

  /// Inicia timer de motivação com horários aleatórios
  void _startMotivationTimer() {
    _motivationTimer?.cancel();

    final enabled = _prefs!.getBool(_keyMotivationEnabled) ?? false;
    if (!enabled) return;

    final timesPerDay = _prefs!.getInt(_keyMotivationPerDay) ?? 3;

    // Calcular intervalo médio entre notificações
    // Considerando horário ativo de 8h às 22h (14 horas)
    const activeHours = 14;
    final avgIntervalMinutes = (activeHours * 60) ~/ timesPerDay;

    // Adicionar variação aleatória (±30%)
    final random = Random();
    final variation = (avgIntervalMinutes * 0.3).toInt();
    final intervalMinutes =
        avgIntervalMinutes + random.nextInt(variation * 2) - variation;

    _motivationTimer = Timer.periodic(
      Duration(minutes: intervalMinutes.clamp(30, 300)), // Min 30min, Max 5h
      (_) => _sendMotivation(),
    );

    // NÃO enviar motivação imediatamente - evita notificações no primeiro uso
    // final firstDelay = Duration(minutes: random.nextInt(60) + 30);
    // Timer(firstDelay, _sendMotivation);

    debugPrint(
      '📅 Timer de motivação iniciado (intervalo médio: ${avgIntervalMinutes}min)',
    );
  }

  /// Envia notificação de motivação
  Future<void> _sendMotivation() async {
    // Não notificar fora do horário ativo (9h-21h para motivação)
    final hour = DateTime.now().hour;
    if (hour < 9 || hour > 21) return;

    final quote = MotivationalQuotes.getRandom();
    final notificationId =
        SchedulerNotificationIds.motivationBase +
        (DateTime.now().millisecondsSinceEpoch % 100);

    await _showInstantNotification(
      id: notificationId,
      title: quote['title']!,
      body: quote['body']!,
      channelKey: NotificationService.channelInsights,
    );

    debugPrint('📅 Notificação de motivação enviada');
  }

  /// Atualiza configuração de notificações de motivação
  Future<void> updateMotivationSettings({
    bool? enabled,
    int? timesPerDay,
  }) async {
    if (enabled != null) await _prefs!.setBool(_keyMotivationEnabled, enabled);
    if (timesPerDay != null) {
      await _prefs!.setInt(_keyMotivationPerDay, timesPerDay);
    }

    _startMotivationTimer();
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Agenda notificação diária recorrente
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelKey,
  }) async {
    try {
      await NotificationService.instance.scheduleDailyMoodReminder(
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      debugPrint('❌ Erro ao agendar notificação diária: $e');
    }
  }

  /// Mostra notificação instantânea
  Future<void> _showInstantNotification({
    required int id,
    required String title,
    required String body,
    required String channelKey,
  }) async {
    try {
      await NotificationService.instance.showDailyInsight(title, body);
    } catch (e) {
      debugPrint('❌ Erro ao mostrar notificação: $e');
    }
  }

  /// Obtém configurações atuais
  Map<String, dynamic> getSettings() {
    return {
      'moodMorningEnabled': _prefs?.getBool(_keyMoodMorningEnabled) ?? false,
      'moodMorningHour': _prefs?.getInt(_keyMoodMorningHour) ?? 8,
      'moodEveningEnabled': _prefs?.getBool(_keyMoodEveningEnabled) ?? false,
      'moodEveningHour': _prefs?.getInt(_keyMoodEveningHour) ?? 20,
      'habitReminderEnabled':
          _prefs?.getBool(_keyHabitReminderEnabled) ?? false,
      'habitReminderInterval': _prefs?.getInt(_keyHabitReminderInterval) ?? 30,
      'taskReminderEnabled': _prefs?.getBool(_keyTaskReminderEnabled) ?? false,
      'taskReminderInterval': _prefs?.getInt(_keyTaskReminderInterval) ?? 30,
      'motivationEnabled': _prefs?.getBool(_keyMotivationEnabled) ?? false,
      'motivationPerDay': _prefs?.getInt(_keyMotivationPerDay) ?? 3,
    };
  }

  /// Para todos os timers
  void dispose() {
    _habitCheckTimer?.cancel();
    _taskCheckTimer?.cancel();
    _motivationTimer?.cancel();
    _initialized = false;
    debugPrint('📅 NotificationScheduler disposed');
  }

  /// Reinicia todos os timers com as configurações atuais
  Future<void> restart() async {
    dispose();
    _initialized = false;
    await initialize(habitRepo: _habitRepo, taskRepo: _taskRepo);
  }
}

/// Singleton accessor
final notificationScheduler = NotificationScheduler.instance;
