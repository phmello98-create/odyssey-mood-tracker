import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:odyssey/src/utils/services/notification_action_handler.dart';

/// Serviço de notificações modernas para Android
/// 
/// Design moderno com:
/// - Ícone do app visível
/// - Nome do app pequeno
/// - Título da notificação destacado
/// - Corpo da mensagem
/// - Ações interativas
/// - Estilo expandido
class ModernNotificationService {
  static final ModernNotificationService _instance = ModernNotificationService._();
  static ModernNotificationService get instance => _instance;
  
  ModernNotificationService._();

  bool _initialized = false;

  // Channel Keys - Organizados por tipo
  static const String channelMood = 'mood_channel';
  static const String channelTasks = 'tasks_channel';
  static const String channelHabits = 'habits_channel';
  static const String channelPomodoro = 'pomodoro_channel';
  static const String channelAchievements = 'achievements_channel';
  static const String channelReminders = 'reminders_channel';
  static const String channelMotivation = 'motivation_channel';

  // Notification IDs
  static const int moodReminderId = 1001;
  static const int taskReminderBase = 2000; // 2000-2999
  static const int habitReminderBase = 3000; // 3000-3999
  static const int pomodoroId = 4001;
  static const int achievementBase = 5000; // 5000-5099
  static const int motivationId = 6001;

  /// Inicializa o serviço de notificações modernas
  Future<void> initialize() async {
    if (_initialized) return;

    await AwesomeNotifications().initialize(
      null, // Usar ícone padrão do app
      [
        // Canal de MOOD (Roxo/Violeta)
        NotificationChannel(
          channelKey: channelMood,
          channelName: 'Humor',
          channelDescription: 'Lembretes para registrar seu humor',
          defaultColor: const Color(0xFF7C3AED),
          ledColor: const Color(0xFF7C3AED),
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          channelShowBadge: true,
          locked: false,
          defaultPrivacy: NotificationPrivacy.Public,
        ),

        // Canal de TASKS (Azul)
        NotificationChannel(
          channelKey: channelTasks,
          channelName: 'Tarefas',
          channelDescription: 'Lembretes de tarefas pendentes',
          defaultColor: const Color(0xFF2196F3),
          ledColor: const Color(0xFF2196F3),
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          channelShowBadge: true,
          locked: false,
          defaultPrivacy: NotificationPrivacy.Public,
        ),

        // Canal de HABITS (Verde)
        NotificationChannel(
          channelKey: channelHabits,
          channelName: 'Hábitos',
          channelDescription: 'Lembretes de hábitos diários',
          defaultColor: const Color(0xFF4CAF50),
          ledColor: const Color(0xFF4CAF50),
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          channelShowBadge: true,
          locked: false,
          defaultPrivacy: NotificationPrivacy.Public,
        ),

        // Canal de POMODORO (Laranja/Vermelho)
        NotificationChannel(
          channelKey: channelPomodoro,
          channelName: 'Timer Pomodoro',
          channelDescription: 'Notificações do timer Pomodoro',
          defaultColor: const Color(0xFFFF5722),
          ledColor: const Color(0xFFFF5722),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          channelShowBadge: false,
          locked: false,
          defaultPrivacy: NotificationPrivacy.Public,
        ),

        // Canal de ACHIEVEMENTS (Dourado)
        NotificationChannel(
          channelKey: channelAchievements,
          channelName: 'Conquistas',
          channelDescription: 'Notificações de conquistas e níveis',
          defaultColor: const Color(0xFFFFB300),
          ledColor: const Color(0xFFFFB300),
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          channelShowBadge: true,
          locked: false,
          defaultPrivacy: NotificationPrivacy.Public,
        ),

        // Canal de REMINDERS (Roxo claro)
        NotificationChannel(
          channelKey: channelReminders,
          channelName: 'Lembretes',
          channelDescription: 'Lembretes gerais do app',
          defaultColor: const Color(0xFF9C27B0),
          ledColor: const Color(0xFF9C27B0),
          importance: NotificationImportance.Default,
          playSound: true,
          enableVibration: false,
          enableLights: true,
          channelShowBadge: true,
          locked: false,
          defaultPrivacy: NotificationPrivacy.Public,
        ),

        // Canal de MOTIVATION (Rosa)
        NotificationChannel(
          channelKey: channelMotivation,
          channelName: 'Motivação',
          channelDescription: 'Mensagens motivacionais diárias',
          defaultColor: const Color(0xFFE91E63),
          ledColor: const Color(0xFFE91E63),
          importance: NotificationImportance.Default,
          playSound: false,
          enableVibration: false,
          enableLights: true,
          channelShowBadge: false,
          locked: false,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'productivity_group',
          channelGroupName: 'Produtividade',
        ),
        NotificationChannelGroup(
          channelGroupKey: 'wellness_group',
          channelGroupName: 'Bem-estar',
        ),
      ],
    );

    // NOTA: Os listeners são configurados apenas uma vez no main.dart
    // para evitar conflitos entre NotificationService e ModernNotificationService.
    // O handler centralizado (NotificationActionHandler) é chamado por ambos.

    _initialized = true;
    debugPrint('ModernNotificationService inicializado');
  }

  /// Solicita permissões de notificação
  Future<bool> requestPermissions() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// Verifica se tem permissões
  Future<bool> isNotificationAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // ==================== NOTIFICAÇÕES DE MOOD ====================

  /// Envia notificação de lembrete de humor
  Future<void> sendMoodReminder({
    required String title,
    required String body,
    String? bigBody,
    DateTime? scheduledDate,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: moodReminderId,
        channelKey: channelMood,
        title: title,
        body: body,
        bigPicture: null,
        largeIcon: null,
        notificationLayout: NotificationLayout.Default,
        summary: 'Odyssey',
        category: NotificationCategory.Reminder,
        wakeUpScreen: false,
        fullScreenIntent: false,
        criticalAlert: false,
        autoDismissible: true,
        backgroundColor: const Color(0xFF7C3AED),
        payload: {'type': 'mood_reminder'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'MOOD_LOG_NOW',
          label: 'Registrar agora',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'MOOD_LATER',
          label: 'Mais tarde',
          autoDismissible: true,
          actionType: ActionType.DismissAction,
        ),
      ],
      schedule: scheduledDate != null
          ? NotificationCalendar.fromDate(date: scheduledDate)
          : null,
    );
  }

  // ==================== NOTIFICAÇÕES DE TASKS ====================

  /// Envia notificação de tarefa pendente
  Future<void> sendTaskReminder({
    required int taskId,
    required String taskTitle,
    required String taskDescription,
    DateTime? dueDate,
    DateTime? scheduledDate,
  }) async {
    final notifId = taskReminderBase + (taskId % 999);

    String body = taskDescription.isEmpty 
        ? 'Você tem uma tarefa pendente' 
        : taskDescription;

    if (dueDate != null) {
      final now = DateTime.now();
      if (dueDate.isBefore(now)) {
        body = '⚠️ Atrasada! $body';
      } else if (dueDate.difference(now).inHours < 24) {
        body = '⏰ Vence hoje! $body';
      }
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notifId,
        channelKey: channelTasks,
        title: '✅ $taskTitle',
        body: body,
        notificationLayout: NotificationLayout.Default,
        summary: 'Odyssey • Tarefas',
        category: NotificationCategory.Reminder,
        wakeUpScreen: false,
        autoDismissible: true,
        backgroundColor: const Color(0xFF2196F3),
        payload: {
          'type': 'task_reminder',
          'taskId': taskId.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'TASK_COMPLETE',
          label: 'Marcar como concluída',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'TASK_OPEN',
          label: 'Abrir',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'TASK_SNOOZE',
          label: 'Adiar',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
      ],
      schedule: scheduledDate != null
          ? NotificationCalendar.fromDate(date: scheduledDate)
          : null,
    );
  }

  /// Cancela notificação de tarefa
  Future<void> cancelTaskReminder(int taskId) async {
    final notifId = taskReminderBase + (taskId % 999);
    await AwesomeNotifications().cancel(notifId);
  }

  // ==================== NOTIFICAÇÕES DE HÁBITOS ====================

  /// Envia notificação de hábito pendente
  Future<void> sendHabitReminder({
    required int habitId,
    required String habitName,
    required String habitDescription,
    int streak = 0,
    DateTime? scheduledDate,
  }) async {
    final notifId = habitReminderBase + (habitId % 999);

    String body = habitDescription.isEmpty 
        ? 'Hora de praticar seu hábito!' 
        : habitDescription;

    if (streak > 0) {
      body = '🔥 Sequência de $streak dias! $body';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notifId,
        channelKey: channelHabits,
        title: '💪 $habitName',
        body: body,
        notificationLayout: NotificationLayout.Default,
        summary: 'Odyssey • Hábitos',
        category: NotificationCategory.Reminder,
        wakeUpScreen: false,
        autoDismissible: true,
        backgroundColor: const Color(0xFF4CAF50),
        payload: {
          'type': 'habit_reminder',
          'habitId': habitId.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'HABIT_COMPLETE',
          label: 'Marcar como feito',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'HABIT_SKIP',
          label: 'Pular por hoje',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
      ],
      schedule: scheduledDate != null
          ? NotificationCalendar.fromDate(date: scheduledDate)
          : null,
    );
  }

  /// Cancela notificação de hábito
  Future<void> cancelHabitReminder(int habitId) async {
    final notifId = habitReminderBase + (habitId % 999);
    await AwesomeNotifications().cancel(notifId);
  }

  // ==================== NOTIFICAÇÕES DE POMODORO ====================

  /// Envia notificação de Pomodoro completo
  Future<void> sendPomodoroComplete({
    required int sessionNumber,
    required int totalMinutes,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: pomodoroId,
        channelKey: channelPomodoro,
        title: '⏰ Pomodoro Completo!',
        body: 'Sessão #$sessionNumber concluída! Tempo de pausa.',
        notificationLayout: NotificationLayout.Default,
        summary: 'Odyssey • Timer',
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        autoDismissible: true,
        backgroundColor: const Color(0xFFFF5722),
        payload: {
          'type': 'pomodoro_complete',
          'session': sessionNumber.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'POMODORO_PAUSE',
          label: 'Iniciar pausa',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'POMODORO_CONTINUE',
          label: 'Continuar focando',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  /// Envia notificação de pausa completa
  Future<void> sendPomodoroBreakComplete() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: pomodoroId + 1,
        channelKey: channelPomodoro,
        title: '☕ Pausa Completa!',
        body: 'Hora de voltar ao foco!',
        notificationLayout: NotificationLayout.Default,
        summary: 'Odyssey • Timer',
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        autoDismissible: true,
        backgroundColor: const Color(0xFFFF5722),
        payload: {'type': 'pomodoro_break_complete'},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'POMODORO_START',
          label: 'Iniciar sessão',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  // ==================== NOTIFICAÇÕES DE CONQUISTAS ====================

  /// Envia notificação de conquista desbloqueada
  Future<void> sendAchievementUnlocked({
    required String achievementName,
    required String achievementDescription,
    int xpReward = 0,
  }) async {
    final bodyText = '$achievementName\n$achievementDescription${xpReward > 0 ? "\n\n+$xpReward XP" : ""}';
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: achievementBase + DateTime.now().millisecond,
        channelKey: channelAchievements,
        title: '🏆 Conquista Desbloqueada!',
        body: bodyText,
        notificationLayout: NotificationLayout.BigText,
        summary: 'Odyssey • Conquistas',
        category: NotificationCategory.Status,
        wakeUpScreen: false,
        autoDismissible: true,
        backgroundColor: const Color(0xFFFFB300),
        payload: {
          'type': 'achievement',
          'name': achievementName,
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'ACHIEVEMENT_VIEW',
          label: 'Ver conquistas',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  /// Envia notificação de novo nível
  Future<void> sendLevelUp({
    required int newLevel,
    int xpToNextLevel = 0,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: achievementBase + 1,
        channelKey: channelAchievements,
        title: '🎉 Level Up!',
        body: 'Você alcançou o nível $newLevel!',
        notificationLayout: NotificationLayout.Default,
        summary: 'Odyssey • Gamificação',
        category: NotificationCategory.Status,
        wakeUpScreen: false,
        autoDismissible: true,
        backgroundColor: const Color(0xFFFFB300),
        payload: {
          'type': 'level_up',
          'level': newLevel.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'LEVEL_VIEW',
          label: 'Ver perfil',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  // ==================== NOTIFICAÇÕES MOTIVACIONAIS ====================

  /// Envia notificação motivacional
  Future<void> sendMotivationalNotification({
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: motivationId,
        channelKey: channelMotivation,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        summary: 'Odyssey',
        category: NotificationCategory.Status,
        wakeUpScreen: false,
        autoDismissible: true,
        backgroundColor: const Color(0xFFE91E63),
        payload: {'type': 'motivation'},
      ),
    );
  }

  // ==================== NOTIFICAÇÕES EXPANDIDAS ====================

  /// Envia notificação com big text (para mensagens longas)
  Future<void> sendBigTextNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required String bigBody,
    List<NotificationActionButton>? actionButtons,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: '$body\n$bigBody',
        notificationLayout: NotificationLayout.BigText,
        summary: 'Odyssey',
        autoDismissible: true,
      ),
      actionButtons: actionButtons,
    );
  }

  /// Envia notificação com inbox style (lista de itens)
  Future<void> sendInboxNotification({
    required int id,
    required String channelKey,
    required String title,
    required List<String> lines,
    List<NotificationActionButton>? actionButtons,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: '${lines.length} items',
        notificationLayout: NotificationLayout.Inbox,
        summary: 'Odyssey',
        autoDismissible: true,
        payload: {'lines': lines.join('|')},
      ),
      actionButtons: actionButtons,
    );
  }

  // ==================== GERENCIAMENTO ====================

  /// Cancela notificação específica
  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Cancela notificações agendadas
  Future<void> cancelAllScheduledNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
  }

  /// Lista notificações ativas
  Future<List<NotificationModel>> getActiveNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  // ==================== CALLBACKS ====================

  /// Callback principal para ações de notificação
  /// 
  /// Chamado quando o usuário:
  /// - Clica na notificação
  /// - Pressiona um botão de ação
  /// 
  /// Delega para o NotificationActionHandler que cuida da navegação
  @pragma("vm:entry-point")
  static Future<void> _onActionReceived(ReceivedAction receivedAction) async {
    debugPrint('===================================================');
    debugPrint('ModernNotificationService._onActionReceived');
    debugPrint('ID: ${receivedAction.id}');
    debugPrint('Channel: ${receivedAction.channelKey}');
    debugPrint('Button: ${receivedAction.buttonKeyPressed}');
    debugPrint('Payload: ${receivedAction.payload}');
    debugPrint('===================================================');
    
    // Delegar para o handler centralizado
    await NotificationActionHandler.handleAction(receivedAction);
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreated(ReceivedNotification notification) async {
    debugPrint('ModernNotificationService: Notificação criada: ${notification.title}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayed(ReceivedNotification notification) async {
    debugPrint('ModernNotificationService: Notificação exibida: ${notification.title}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceived(ReceivedAction receivedAction) async {
    debugPrint('ModernNotificationService: Notificação dispensada: ${receivedAction.id}');
  }
}
