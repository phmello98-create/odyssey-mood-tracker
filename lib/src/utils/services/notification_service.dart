import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/src/utils/services/notification_analytics.dart';
import 'package:odyssey/src/utils/services/notification_action_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum centralizado para IDs de notificação - evita colisões
enum NotificationId {
  moodReminder(1),
  streakAlert(2),
  pomodoroComplete(4),
  dailyInsight(5),
  timerRunning(100),
  // Range para task reminders: 1000-1999
  taskReminderBase(1000),
  // Range para remote notifications: 500-599
  remoteNotificationBase(500),
  achievementNotification(599),
  levelUpNotification(598),
  reengagementNotification(597);

  final int id;
  const NotificationId(this.id);

  /// Gera ID único para task reminder baseado no taskId
  static int taskReminderId(String taskId) {
    final hash = taskId.hashCode.abs() % 999;
    return taskReminderBase.id + hash;
  }
}

/// Serviço centralizado de notificações usando Awesome Notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  
  NotificationService._();

  bool _initialized = false;
  
  // Callback para controlar timer externamente
  static Function()? onStopTimer;
  static Function()? onPauseTimer;
  static Function()? onResumeTimer;

  // Notification IDs (mantidos para compatibilidade)
  static const int moodReminderId = 1;
  static const int streakAlertId = 2;
  static const int taskReminderId = 3;
  static const int pomodoroCompleteId = 4;
  static const int dailyInsightId = 5;
  static const int timerRunningId = 100;

  // Channel Keys
  static const String channelPomodoro = 'pomodoro_channel';
  static const String channelReminders = 'reminders_channel';
  static const String channelInsights = 'insights_channel';
  static const String channelGamification = 'gamification_channel';
  static const String channelTimer = 'timer_channel';

  // Mapa de IDs de tasks agendadas para cancelamento
  final Map<String, int> _scheduledTaskReminders = {};

  /// Inicializa o serviço de notificações
  Future<void> initialize({bool requestPermissions = true, bool configureListeners = true}) async {
    if (_initialized) return;

    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification', // Usar ícone personalizado
      [
        NotificationChannel(
          channelKey: channelPomodoro,
          channelName: 'Pomodoro Timer',
          channelDescription: 'Notificações do timer Pomodoro',
          defaultColor: const Color(0xFF4CAF50),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: highVibrationPattern,
        ),
        NotificationChannel(
          channelKey: channelReminders,
          channelName: 'Lembretes',
          channelDescription: 'Lembretes de tarefas e humor',
          defaultColor: const Color(0xFF7C4DFF),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: channelInsights,
          channelName: 'Insights',
          channelDescription: 'Insights e dicas diárias',
          defaultColor: const Color(0xFF2196F3),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
        ),
        NotificationChannel(
          channelKey: channelGamification,
          channelName: 'Conquistas',
          channelDescription: 'Notificações de nível e conquistas',
          defaultColor: const Color(0xFFFF9800),
          ledColor: Colors.yellow,
          importance: NotificationImportance.High,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: channelTimer,
          channelName: 'Timer em Execução',
          channelDescription: 'Notificação persistente do timer',
          defaultColor: const Color(0xFF7C4DFF),
          ledColor: Colors.purple,
          importance: NotificationImportance.Low,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
          locked: true, // Não pode ser dispensada pelo usuário
        ),
      ],
      debug: false,
    );

    if (requestPermissions) await _requestAllPermissions();
    
    // Configurar listeners para ações
    if (configureListeners) {
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );
    }

    _initialized = true;
  }

  /// Pede todas as permissões necessárias
  Future<void> _requestAllPermissions() async {
    // Permissão de notificação básica via Awesome Notifications
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: channelReminders,
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.PreciseAlarms,
          NotificationPermission.FullScreenIntent,
        ],
      );
    }
  }
  
  /// Solicita permissões manualmente (para chamada da UI)
  Future<bool> requestPermissions() async {
    await _requestAllPermissions();
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // Chave para armazenar ação pendente
  static const String _pendingActionKey = 'pending_notification_action';
  
  /// Métodos estáticos para listeners (requerido pelo Awesome Notifications)
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final action = receivedAction.buttonKeyPressed;
    final channelKey = receivedAction.channelKey ?? 'unknown';
    final notificationId = receivedAction.id?.toString() ?? 'unknown';
    
    debugPrint('[NotificationService] ========================================');
    debugPrint('[NotificationService] Action received: "$action"');
    debugPrint('[NotificationService] Channel: $channelKey');
    debugPrint('[NotificationService] Notification ID: $notificationId');
    debugPrint('[NotificationService] ========================================');
    
    // Track action analytics
    _trackAction(notificationId, channelKey, action);
    
    // Verificar se é uma ação de timer que tratamos diretamente
    bool isTimerAction = false;
    
    switch (action) {
      case 'STOP_TIMER':
        debugPrint('[NotificationService] Executing STOP_TIMER action...');
        if (onStopTimer != null) {
          onStopTimer!();
          isTimerAction = true;
          debugPrint('[NotificationService] STOP_TIMER callback executed');
        }
        await AwesomeNotifications().cancel(timerRunningId);
        break;
      case 'PAUSE_TIMER':
        debugPrint('[NotificationService] Executing PAUSE_TIMER action...');
        if (onPauseTimer != null) {
          onPauseTimer!();
          isTimerAction = true;
          debugPrint('[NotificationService] PAUSE_TIMER callback executed');
        }
        break;
      case 'RESUME_TIMER':
        debugPrint('[NotificationService] Executing RESUME_TIMER action...');
        if (onResumeTimer != null) {
          onResumeTimer!();
          isTimerAction = true;
          debugPrint('[NotificationService] RESUME_TIMER callback executed');
        }
        break;
      case 'START_BREAK':
        debugPrint('Iniciar pausa solicitado');
        isTimerAction = true;
        break;
      case 'START_FOCUS':
        debugPrint('Iniciar foco solicitado');
        isTimerAction = true;
        break;
    }
    
    // Se callback de timer não estava disponível, salvar ação pendente
    if (!isTimerAction && (action == 'STOP_TIMER' || action == 'PAUSE_TIMER' || action == 'RESUME_TIMER')) {
      debugPrint('[NotificationService] Callback not available, saving pending action: $action');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingActionKey, action);
      return;
    }
    
    // Para ações que não são de timer, delegar para o NotificationActionHandler
    // Isso inclui: navegação, marcar tarefas, hábitos, etc.
    if (!isTimerAction) {
      debugPrint('[NotificationService] Delegando para NotificationActionHandler');
      await NotificationActionHandler.handleAction(receivedAction);
    }
  }
  
  /// Verifica e executa ação pendente (chamado após TimerNotifier inicializar)
  static Future<void> checkPendingAction() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingAction = prefs.getString(_pendingActionKey);
    
    if (pendingAction != null) {
      debugPrint('[NotificationService] Found pending action: $pendingAction');
      await prefs.remove(_pendingActionKey);
      
      switch (pendingAction) {
        case 'STOP_TIMER':
          onStopTimer?.call();
          break;
        case 'PAUSE_TIMER':
          onPauseTimer?.call();
          break;
        case 'RESUME_TIMER':
          onResumeTimer?.call();
          break;
      }
    }
  }
  
  static void _trackAction(String notificationId, String channelKey, String action) {
    String type = 'general';
    if (channelKey.contains('pomodoro')) {
      type = 'pomodoro';
    } else if (channelKey.contains('reminder')) {
      type = 'reminder';
    } else if (channelKey.contains('gamification')) {
      type = 'gamification';
    } else if (channelKey.contains('timer')) {
      type = 'timer';
    }
    
    NotificationAnalyticsService.instance.trackNotificationAction(
      notificationId: notificationId,
      type: type,
      action: action,
    );
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {}

  /// Agenda lembrete diário de humor
  Future<void> scheduleDailyMoodReminder({int hour = 20, int minute = 0}) async {
    _log('scheduleDailyMoodReminder', {'hour': hour, 'minute': minute});
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: moodReminderId,
        channelKey: channelReminders,
        title: '🎭 Como você está se sentindo?',
        body: 'Registre seu humor para acompanhar seu bem-estar',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
    
    // Track scheduling
    await NotificationAnalyticsService.instance.trackNotificationSent(
      notificationId: 'mood_reminder_daily',
      type: 'mood_reminder',
      extraParams: {'hour': hour.toString()},
    );
  }

  /// Cancela lembrete de humor
  Future<void> cancelMoodReminder() async {
    await AwesomeNotifications().cancel(moodReminderId);
  }

  /// Alerta de streak em risco
  Future<void> showStreakAlert(int currentStreak) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: streakAlertId,
        channelKey: channelGamification,
        title: '🔥 Streak em risco!',
        body: 'Seu streak de $currentStreak dias está em perigo. Registre algo hoje!',
        notificationLayout: NotificationLayout.BigText,
        color: const Color(0xFFFF9800),
      ),
    );
    HapticFeedback.heavyImpact();
  }

  /// Notificação de Pomodoro completo
  Future<void> showPomodoroComplete(String taskName, int minutes) async {
    _log('showPomodoroComplete', {'taskName': taskName, 'minutes': minutes});
    
    final truncatedName = _truncateText(taskName, maxLength: 35);
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: pomodoroCompleteId,
        channelKey: channelPomodoro,
        title: '🍅 Sessão Completa!',
        body: 'Você focou $minutes min em "$truncatedName". Ótimo trabalho!',
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'START_BREAK',
          label: 'Iniciar Pausa',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Fechar',
          actionType: ActionType.DismissAction,
        ),
      ],
    );
    
    // Track
    await NotificationAnalyticsService.instance.trackNotificationSent(
      notificationId: 'pomodoro_${DateTime.now().millisecondsSinceEpoch}',
      type: 'pomodoro',
      extraParams: {'task': taskName, 'duration_minutes': minutes.toString()},
    );
    
    HapticFeedback.vibrate();
  }

  /// Notificação de Timer Livre completo
  Future<void> showTimerComplete(String taskName, Duration elapsed) async {
    final elapsedStr = _formatDuration(elapsed);
    _log('showTimerComplete', {'taskName': taskName, 'elapsed': elapsedStr});
    
    final truncatedName = _truncateText(taskName, maxLength: 35);
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: timerRunningId + 1,
        channelKey: channelTimer,
        title: '✅ Timer Concluído!',
        body: 'Você trabalhou $elapsedStr em "$truncatedName". Bom trabalho!',
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        autoDismissible: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Fechar',
          actionType: ActionType.DismissAction,
        ),
      ],
    );
    
    HapticFeedback.mediumImpact();
  }

  /// Agenda notificação para fim do Pomodoro
  Future<void> schedulePomodoroTimer(Duration duration, String taskName) async {
    final truncatedName = _truncateText(taskName, maxLength: 35);
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: pomodoroCompleteId,
        channelKey: channelPomodoro,
        title: '🍅 Pomodoro Concluído!',
        body: 'Sessão de foco em "$truncatedName" finalizada.',
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar.fromDate(
        date: DateTime.now().add(duration),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'START_BREAK',
          label: 'Iniciar Pausa',
        ),
      ],
    );
  }

  /// Cancela timer do Pomodoro
  Future<void> cancelPomodoroTimer() async {
    await AwesomeNotifications().cancel(pomodoroCompleteId);
  }

  /// Agenda notificação para fim da Pausa
  Future<void> scheduleBreakTimer(Duration duration) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: pomodoroCompleteId,
        channelKey: channelPomodoro,
        title: '☕ Pausa Terminada!',
        body: 'Hora de voltar ao foco! Vamos lá?',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar.fromDate(
        date: DateTime.now().add(duration),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'START_FOCUS',
          label: 'Iniciar Foco',
        ),
      ],
    );
  }

  /// Lembrete de tarefa (imediato)
  Future<void> showTaskReminder(String taskTitle) async {
    _log('showTaskReminder', {'taskTitle': taskTitle});
    
    final truncatedTitle = _truncateText(taskTitle, maxLength: 40);
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: taskReminderId,
        channelKey: channelReminders,
        title: '✅ Tarefa pendente',
        body: 'Não esqueça: "$truncatedTitle"',
        notificationLayout: NotificationLayout.BigText,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'COMPLETE',
          label: 'Concluir',
        ),
      ],
    );
  }

  /// Agenda lembrete para tarefa específica em horário customizado
  Future<void> scheduleTaskReminder({
    required DateTime when,
    required String taskId,
    required String title,
    String? body,
  }) async {
    _log('scheduleTaskReminder', {
      'taskId': taskId,
      'title': title,
      'when': when.toIso8601String(),
    });

    final notificationId = NotificationId.taskReminderId(taskId);
    _scheduledTaskReminders[taskId] = notificationId;
    
    final truncatedTitle = _truncateText(title, maxLength: 35);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: channelReminders,
        title: '✅ $truncatedTitle',
        body: body ?? 'Lembrete de tarefa agendada',
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Reminder,
        payload: {'taskId': taskId, 'type': 'task_reminder'},
      ),
      schedule: NotificationCalendar.fromDate(
        date: when,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'COMPLETE',
          label: 'Concluir',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'SNOOZE',
          label: 'Adiar 10min',
          actionType: ActionType.SilentAction,
        ),
      ],
    );
  }

  /// Cancela lembrete de tarefa específica por taskId
  Future<void> cancelTaskReminder(String taskId) async {
    _log('cancelTaskReminder', {'taskId': taskId});
    
    final notificationId = _scheduledTaskReminders[taskId];
    if (notificationId != null) {
      await AwesomeNotifications().cancel(notificationId);
      _scheduledTaskReminders.remove(taskId);
    } else {
      // Tenta cancelar usando o ID calculado mesmo se não estiver no mapa
      final calculatedId = NotificationId.taskReminderId(taskId);
      await AwesomeNotifications().cancel(calculatedId);
    }
  }

  /// Cancela todos os lembretes de tarefas agendados
  Future<void> cancelAllTaskReminders() async {
    _log('cancelAllTaskReminders', {'count': _scheduledTaskReminders.length});
    
    for (final id in _scheduledTaskReminders.values) {
      await AwesomeNotifications().cancel(id);
    }
    _scheduledTaskReminders.clear();

    // Cancela também qualquer ID no range de task reminders
    final scheduled = await AwesomeNotifications().listScheduledNotifications();
    for (final notification in scheduled) {
      final id = notification.content?.id ?? 0;
      if (id >= NotificationId.taskReminderBase.id && id < NotificationId.taskReminderBase.id + 1000) {
        await AwesomeNotifications().cancel(id);
      }
    }
  }

  /// Retorna lista de notificações agendadas (para debug)
  Future<List<Map<String, dynamic>>> getScheduledNotifications() async {
    final notifications = await AwesomeNotifications().listScheduledNotifications();
    return notifications.map((n) => {
      'id': n.content?.id,
      'title': n.content?.title,
      'body': n.content?.body,
      'channelKey': n.content?.channelKey,
      'payload': n.content?.payload,
    }).toList();
  }

  /// Log estruturado para debug
  void _log(String method, Map<String, dynamic> params) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] NotificationService.$method: $params');
  }

  /// Insight diário personalizado
  Future<void> showDailyInsight(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: dailyInsightId,
        channelKey: channelInsights,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }

  /// Agenda lembrete de streak para o final do dia
  Future<void> scheduleStreakReminder(int currentStreak) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: streakAlertId,
        channelKey: channelGamification,
        title: '🔥 Mantenha seu streak!',
        body: 'Você tem $currentStreak dias seguidos. Não quebre a corrente!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 21,
        minute: 30,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
  }

  /// Cancela todas as notificações
  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  // ==========================================
  // TIMER RUNNING NOTIFICATION (PERSISTENT)
  // Notificação persistente que não pode ser dispensada
  // ==========================================

  /// Mostra notificação persistente do timer em execução
  Future<void> showTimerRunningNotification({
    required String taskName,
    required Duration elapsed,
    bool isPomodoro = false,
    Duration? pomodoroTimeLeft,
    bool isPaused = false,
  }) async {
    final elapsedStr = _formatDuration(elapsed);
    final pomodoroStr = pomodoroTimeLeft != null ? _formatDuration(pomodoroTimeLeft) : null;

    String title;
    String body;

    final truncatedName = _truncateText(taskName, maxLength: 25);
    
    if (isPomodoro && pomodoroStr != null) {
      if (isPaused) {
        title = '⏸️ Pomodoro Pausado';
        body = '📋 $truncatedName • Restam $pomodoroStr';
      } else {
        title = '🍅 Pomodoro em Andamento';
        body = '📋 $truncatedName • Restam $pomodoroStr';
      }
    } else {
      if (isPaused) {
        title = '⏸️ Timer Pausado';
        body = '📋 $truncatedName • $elapsedStr';
      } else {
        title = '⏱️ Timer em Andamento';
        body = '📋 $truncatedName • $elapsedStr';
      }
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: timerRunningId,
        channelKey: channelTimer,
        title: title,
        body: body,
        icon: 'resource://drawable/ic_notification',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.StopWatch,
        locked: true,
        autoDismissible: false,
        showWhen: false,
        displayOnBackground: true,
        displayOnForeground: true,
      ),
      actionButtons: [
        if (isPaused)
          NotificationActionButton(
            key: 'RESUME_TIMER',
            label: '▶️ Continuar',
            actionType: ActionType.SilentAction,
          )
        else
          NotificationActionButton(
            key: 'PAUSE_TIMER',
            label: '⏸️ Pausar',
            actionType: ActionType.SilentAction,
          ),
        NotificationActionButton(
          key: 'STOP_TIMER',
          label: '⏹️ Parar',
          actionType: ActionType.SilentAction,
        ),
      ],
    );
  }

  /// Atualiza a notificação do timer
  Future<void> updateTimerNotification({
    required String taskName,
    required Duration elapsed,
    bool isPomodoro = false,
    Duration? pomodoroTimeLeft,
    bool isPaused = false,
  }) async {
    await showTimerRunningNotification(
      taskName: taskName,
      elapsed: elapsed,
      isPomodoro: isPomodoro,
      pomodoroTimeLeft: pomodoroTimeLeft,
      isPaused: isPaused,
    );
  }

  /// Cancela a notificação do timer
  Future<void> cancelTimerNotification() async {
    await AwesomeNotifications().cancel(timerRunningId);
  }

  /// Formata Duration para string legível
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Trunca texto longo para exibição em notificações
  /// [maxLength] é o tamanho máximo antes de truncar (padrão: 30 caracteres)
  String _truncateText(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Verifica se há timer rodando (notificação ativa)
  Future<bool> isTimerNotificationActive() async {
    final notifications = await AwesomeNotifications().listScheduledNotifications();
    return notifications.any((n) => n.content?.id == timerRunningId);
  }

  // ==========================================
  // REMOTE NOTIFICATIONS (FCM Bridge)
  // ==========================================

  static const int remoteNotificationBaseId = 500;

  /// Mostra notificação recebida via FCM
  Future<void> showRemoteNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final notificationType = payload?['type'] ?? 'general';
    String channelKey;
    Color notificationColor;

    // Determinar canal baseado no tipo
    switch (notificationType) {
      case 'mood_reminder':
        channelKey = channelReminders;
        notificationColor = const Color(0xFF7C4DFF);
        break;
      case 'streak_alert':
        channelKey = channelGamification;
        notificationColor = const Color(0xFFFF9800);
        break;
      case 'achievement':
        channelKey = channelGamification;
        notificationColor = const Color(0xFFFFD700);
        break;
      case 'pomodoro':
        channelKey = channelPomodoro;
        notificationColor = const Color(0xFF4CAF50);
        break;
      case 'insight':
        channelKey = channelInsights;
        notificationColor = const Color(0xFF2196F3);
        break;
      default:
        channelKey = channelReminders;
        notificationColor = const Color(0xFF7C4DFF);
    }

    // Gerar ID único baseado no timestamp
    final notificationId = remoteNotificationBaseId +
        (DateTime.now().millisecondsSinceEpoch % 100);
    
    // Truncar título se necessário
    final truncatedTitle = _truncateText(title, maxLength: 40);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: channelKey,
        title: truncatedTitle,
        body: body,
        notificationLayout: NotificationLayout.BigText,
        color: notificationColor,
        payload: payload?.map((k, v) => MapEntry(k, v.toString())),
      ),
      actionButtons: _getActionButtonsForType(notificationType),
    );
  }

  /// Retorna botões de ação baseados no tipo de notificação
  List<NotificationActionButton>? _getActionButtonsForType(String type) {
    switch (type) {
      case 'mood_reminder':
        return [
          NotificationActionButton(
            key: 'RECORD_MOOD',
            label: 'Registrar Humor',
            actionType: ActionType.Default,
          ),
        ];
      case 'streak_alert':
        return [
          NotificationActionButton(
            key: 'CONTINUE_STREAK',
            label: 'Manter Streak',
            actionType: ActionType.Default,
          ),
        ];
      case 'pomodoro':
        return [
          NotificationActionButton(
            key: 'START_POMODORO',
            label: 'Iniciar Sessão',
            actionType: ActionType.Default,
          ),
        ];
      default:
        return null;
    }
  }

  /// Mostra notificação de conquista especial
  Future<void> showAchievementNotification({
    required String title,
    required String description,
    String? emoji,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: remoteNotificationBaseId + 99,
        channelKey: channelGamification,
        title: '${emoji ?? "🏆"} $title',
        body: description,
        notificationLayout: NotificationLayout.BigText,
        color: const Color(0xFFFFD700),
        category: NotificationCategory.Social,
      ),
    );
    HapticFeedback.heavyImpact();
  }

  /// Mostra notificação de level up
  Future<void> showLevelUpNotification({
    required int newLevel,
    String? unlockedTitle,
  }) async {
    String body = 'Você alcançou o nível $newLevel!';
    if (unlockedTitle != null) {
      body += '\nNovo título: $unlockedTitle';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: remoteNotificationBaseId + 98,
        channelKey: channelGamification,
        title: '⭐ LEVEL UP!',
        body: body,
        notificationLayout: NotificationLayout.BigText,
        color: const Color(0xFFFFD700),
        category: NotificationCategory.Social,
        wakeUpScreen: true,
      ),
    );
    HapticFeedback.heavyImpact();
  }

  /// Mostra notificação de re-engajamento
  Future<void> showReengagementNotification({
    required int daysInactive,
    String? customMessage,
  }) async {
    String title;
    String body;

    if (daysInactive >= 14) {
      title = '🌱 Sentimos sua falta!';
      body = customMessage ?? 'Seu jardim de hábitos precisa de cuidado. Vamos retomar juntos?';
    } else if (daysInactive >= 7) {
      title = '👋 Uma semana se passou...';
      body = customMessage ?? 'Que tal registrar como você está hoje?';
    } else {
      title = '😊 Olá!';
      body = customMessage ?? 'Continue sua jornada de bem-estar!';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: remoteNotificationBaseId + 97,
        channelKey: channelReminders,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigText,
        color: const Color(0xFF7C4DFF),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'COMEBACK',
          label: 'Voltar ao App',
          actionType: ActionType.Default,
        ),
      ],
    );
  }
}

/// Provider para configurações de notificação
class NotificationSettings {
  final bool moodReminderEnabled;
  final int moodReminderHour;
  final int moodReminderMinute;
  final bool streakAlertEnabled;
  final bool pomodoroNotificationsEnabled;

  NotificationSettings({
    this.moodReminderEnabled = true,
    this.moodReminderHour = 20,
    this.moodReminderMinute = 0,
    this.streakAlertEnabled = true,
    this.pomodoroNotificationsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? moodReminderEnabled,
    int? moodReminderHour,
    int? moodReminderMinute,
    bool? streakAlertEnabled,
    bool? pomodoroNotificationsEnabled,
  }) {
    return NotificationSettings(
      moodReminderEnabled: moodReminderEnabled ?? this.moodReminderEnabled,
      moodReminderHour: moodReminderHour ?? this.moodReminderHour,
      moodReminderMinute: moodReminderMinute ?? this.moodReminderMinute,
      streakAlertEnabled: streakAlertEnabled ?? this.streakAlertEnabled,
      pomodoroNotificationsEnabled: pomodoroNotificationsEnabled ?? this.pomodoroNotificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'moodReminderEnabled': moodReminderEnabled,
    'moodReminderHour': moodReminderHour,
    'moodReminderMinute': moodReminderMinute,
    'streakAlertEnabled': streakAlertEnabled,
    'pomodoroNotificationsEnabled': pomodoroNotificationsEnabled,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      moodReminderEnabled: json['moodReminderEnabled'] ?? true,
      moodReminderHour: json['moodReminderHour'] ?? 20,
      moodReminderMinute: json['moodReminderMinute'] ?? 0,
      streakAlertEnabled: json['streakAlertEnabled'] ?? true,
      pomodoroNotificationsEnabled: json['pomodoroNotificationsEnabled'] ?? true,
    );
  }
}
