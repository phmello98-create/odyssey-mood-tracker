import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:odyssey/src/utils/services/firebase_service.dart';
import 'package:odyssey/src/utils/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerenciador centralizado que coordena notificações locais (Awesome) e remotas (FCM)
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._();
  static NotificationManager get instance => _instance;

  NotificationManager._();

  bool _initialized = false;
  SharedPreferences? _prefs;

  // Keys para SharedPreferences
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyMoodRemindersEnabled = 'mood_reminders_enabled';
  static const String _keyStreakAlertsEnabled = 'streak_alerts_enabled';
  static const String _keyGamificationEnabled = 'gamification_notifications_enabled';
  static const String _keySmartNotifications = 'smart_notifications_enabled';
  static const String _keyLastActivityDate = 'last_activity_date';

  /// Inicializa todos os serviços de notificação
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Inicializar serviços em paralelo
      await Future.wait([
        NotificationService.instance.initialize(requestPermissions: true, configureListeners: true),
        FirebaseService.instance.initialize(),
      ]);

      // Configurar callbacks para ações de notificação
      _setupNotificationCallbacks();

      // Verificar e enviar notificação de re-engajamento se necessário
      await _checkReengagement();

      _initialized = true;
      debugPrint('✅ NotificationManager inicializado');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar NotificationManager: $e');
    }
  }

  /// Configura callbacks para responder a ações de notificação
  /// NOTA: Os callbacks do timer são configurados pelo TimerNotifier
  /// para ter acesso ao estado do timer. Não sobrescrever aqui.
  void _setupNotificationCallbacks() {
    // Callbacks do timer são configurados em TimerNotifier._setupNotificationCallbacks()
    // para ter acesso direto ao estado e métodos do timer.
    debugPrint('📬 NotificationManager: callbacks de timer delegados ao TimerNotifier');
  }

  /// Verifica se precisa enviar notificação de re-engajamento
  Future<void> _checkReengagement() async {
    final lastActivityStr = _prefs?.getString(_keyLastActivityDate);
    if (lastActivityStr == null) return;

    final lastActivity = DateTime.tryParse(lastActivityStr);
    if (lastActivity == null) return;

    final daysInactive = DateTime.now().difference(lastActivity).inDays;

    if (daysInactive >= 3 && isReengagementEnabled()) {
      await NotificationService.instance.showReengagementNotification(
        daysInactive: daysInactive,
      );
    }
  }

  /// Atualiza a data da última atividade
  Future<void> updateLastActivity() async {
    await _prefs?.setString(
      _keyLastActivityDate,
      DateTime.now().toIso8601String(),
    );
  }

  // ===========================================
  // CONFIGURAÇÕES DE NOTIFICAÇÃO
  // ===========================================

  /// Verifica se notificações estão habilitadas globalmente
  bool isNotificationsEnabled() {
    return _prefs?.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Habilita/desabilita notificações globalmente
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);

    if (!enabled) {
      // Cancelar todas as notificações agendadas
      await NotificationService.instance.cancelAll();
      // Desinscrever de tópicos FCM
      await FirebaseService.instance.unsubscribeFromTopic('all_users');
    } else {
      // Reinscrever em tópicos
      await FirebaseService.instance.subscribeToTopic('all_users');
    }
  }

  /// Verifica se lembretes de humor estão habilitados
  bool isMoodRemindersEnabled() {
    return _prefs?.getBool(_keyMoodRemindersEnabled) ?? true;
  }

  /// Habilita/desabilita lembretes de humor
  Future<void> setMoodRemindersEnabled(bool enabled) async {
    await _prefs?.setBool(_keyMoodRemindersEnabled, enabled);

    if (enabled) {
      await FirebaseService.instance.subscribeToTopic('mood_reminders');
      await NotificationService.instance.scheduleDailyMoodReminder();
    } else {
      await FirebaseService.instance.unsubscribeFromTopic('mood_reminders');
      await NotificationService.instance.cancelMoodReminder();
    }
  }

  /// Verifica se alertas de streak estão habilitados
  bool isStreakAlertsEnabled() {
    return _prefs?.getBool(_keyStreakAlertsEnabled) ?? true;
  }

  /// Habilita/desabilita alertas de streak
  Future<void> setStreakAlertsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyStreakAlertsEnabled, enabled);
  }

  /// Verifica se notificações de gamificação estão habilitadas
  bool isGamificationEnabled() {
    return _prefs?.getBool(_keyGamificationEnabled) ?? true;
  }

  /// Habilita/desabilita notificações de gamificação
  Future<void> setGamificationEnabled(bool enabled) async {
    await _prefs?.setBool(_keyGamificationEnabled, enabled);

    if (enabled) {
      await FirebaseService.instance.subscribeToTopic('gamification');
    } else {
      await FirebaseService.instance.unsubscribeFromTopic('gamification');
    }
  }

  /// Verifica se notificações inteligentes estão habilitadas
  bool isSmartNotificationsEnabled() {
    return _prefs?.getBool(_keySmartNotifications) ?? true;
  }

  /// Habilita/desabilita notificações inteligentes
  Future<void> setSmartNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keySmartNotifications, enabled);
  }

  /// Verifica se re-engajamento está habilitado
  bool isReengagementEnabled() {
    return isNotificationsEnabled() && isSmartNotificationsEnabled();
  }

  // ===========================================
  // MÉTODOS DE ENVIO DE NOTIFICAÇÃO
  // ===========================================

  /// Envia notificação de humor contextual
  Future<void> sendMoodReminder({
    int? currentStreak,
    String? customMessage,
  }) async {
    if (!isNotificationsEnabled() || !isMoodRemindersEnabled()) return;

    String title;
    String body;

    if (currentStreak != null && currentStreak >= 7) {
      title = '🔥 Mantendo o fogo!';
      body = customMessage ?? 'Seu streak de $currentStreak dias está incrível. Como está se sentindo hoje?';
    } else {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        title = '🌅 Bom dia!';
        body = customMessage ?? 'Como você está se sentindo nesta manhã?';
      } else if (hour < 18) {
        title = '☀️ Boa tarde!';
        body = customMessage ?? 'Um momento para registrar como está o seu dia?';
      } else {
        title = '🌙 Boa noite!';
        body = customMessage ?? 'Como foi seu dia? Registre seu humor antes de dormir.';
      }
    }

    await NotificationService.instance.showRemoteNotification(
      title: title,
      body: body,
      payload: {'type': 'mood_reminder', 'action': 'open_mood'},
    );

    // Track analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: 'mood_reminder_${DateTime.now().millisecondsSinceEpoch}',
      action: 'sent',
      extraParams: {'streak': currentStreak?.toString() ?? '0'},
    );
  }

  /// Envia alerta de streak em risco
  Future<void> sendStreakAlert({
    required int currentStreak,
  }) async {
    if (!isNotificationsEnabled() || !isStreakAlertsEnabled()) return;

    await NotificationService.instance.showStreakAlert(currentStreak);

    // Track analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: 'streak_alert_${DateTime.now().millisecondsSinceEpoch}',
      action: 'sent',
      extraParams: {'streak': currentStreak.toString()},
    );
  }

  /// Envia notificação de conquista
  Future<void> sendAchievementNotification({
    required String title,
    required String description,
    String? emoji,
    String? achievementId,
  }) async {
    if (!isNotificationsEnabled() || !isGamificationEnabled()) return;

    await NotificationService.instance.showAchievementNotification(
      title: title,
      description: description,
      emoji: emoji,
    );

    // Track analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: achievementId ?? 'achievement_${DateTime.now().millisecondsSinceEpoch}',
      action: 'sent',
      extraParams: {'achievement_title': title},
    );
  }

  /// Envia notificação de level up
  Future<void> sendLevelUpNotification({
    required int newLevel,
    String? unlockedTitle,
  }) async {
    if (!isNotificationsEnabled() || !isGamificationEnabled()) return;

    await NotificationService.instance.showLevelUpNotification(
      newLevel: newLevel,
      unlockedTitle: unlockedTitle,
    );

    // Atualizar segmento do usuário
    await FirebaseService.instance.setUserProperty(
      name: 'user_level',
      value: newLevel.toString(),
    );

    // Track analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: 'level_up_$newLevel',
      action: 'sent',
      extraParams: {'new_level': newLevel.toString()},
    );
  }

  /// Envia notificação de Pomodoro concluído
  Future<void> sendPomodoroComplete({
    required String taskName,
    required int minutes,
  }) async {
    if (!isNotificationsEnabled()) return;

    await NotificationService.instance.showPomodoroComplete(taskName, minutes);

    // Track analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: 'pomodoro_${DateTime.now().millisecondsSinceEpoch}',
      action: 'sent',
      extraParams: {
        'task_name': taskName,
        'duration_minutes': minutes.toString(),
      },
    );
  }

  /// Envia insight diário personalizado
  Future<void> sendDailyInsight({
    required String title,
    required String body,
  }) async {
    if (!isNotificationsEnabled() || !isSmartNotificationsEnabled()) return;

    await NotificationService.instance.showDailyInsight(title, body);

    // Track analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: 'insight_${DateTime.now().millisecondsSinceEpoch}',
      action: 'sent',
    );
  }

  // ===========================================
  // TIMER NOTIFICATIONS
  // ===========================================

  /// Mostra notificação persistente do timer
  Future<void> showTimerRunning({
    required String taskName,
    required Duration elapsed,
    bool isPomodoro = false,
    Duration? pomodoroTimeLeft,
    bool isPaused = false,
  }) async {
    await NotificationService.instance.showTimerRunningNotification(
      taskName: taskName,
      elapsed: elapsed,
      isPomodoro: isPomodoro,
      pomodoroTimeLeft: pomodoroTimeLeft,
      isPaused: isPaused,
    );
  }

  /// Atualiza notificação do timer
  Future<void> updateTimerNotification({
    required String taskName,
    required Duration elapsed,
    bool isPomodoro = false,
    Duration? pomodoroTimeLeft,
    bool isPaused = false,
  }) async {
    await NotificationService.instance.updateTimerNotification(
      taskName: taskName,
      elapsed: elapsed,
      isPomodoro: isPomodoro,
      pomodoroTimeLeft: pomodoroTimeLeft,
      isPaused: isPaused,
    );
  }

  /// Cancela notificação do timer
  Future<void> cancelTimerNotification() async {
    await NotificationService.instance.cancelTimerNotification();
  }

  // ===========================================
  // SEGMENTAÇÃO E PERSONALIZAÇÃO
  // ===========================================

  /// Atualiza segmentação do usuário baseado em stats
  Future<void> updateUserSegmentation({
    required int level,
    required int streak,
    required int totalXP,
    required int moodRecordsCount,
    required int pomodoroSessions,
  }) async {
    await FirebaseService.instance.setUserSegment(
      level: level,
      streak: streak,
      totalXP: totalXP,
    );

    // Propriedades adicionais
    await FirebaseService.instance.setUserProperty(
      name: 'mood_records_count',
      value: moodRecordsCount.toString(),
    );

    await FirebaseService.instance.setUserProperty(
      name: 'pomodoro_sessions',
      value: pomodoroSessions.toString(),
    );
  }

  /// Obtém configuração de A/B test do Remote Config
  String getNotificationVariant(String testName) {
    return FirebaseService.instance.getRemoteConfigString('${testName}_variant');
  }

  /// Verifica se feature está habilitada via Remote Config
  bool isFeatureEnabled(String featureName) {
    return FirebaseService.instance.getRemoteConfigBool(featureName);
  }
}
