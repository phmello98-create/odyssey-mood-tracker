import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/home/presentation/odyssey_home.dart';
import 'package:odyssey/src/features/mood_records/presentation/mood_log/mood_log_screen.dart';
import 'package:odyssey/src/features/time_tracker/presentation/time_tracker_screen.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';
import 'package:odyssey/src/features/gamification/presentation/profile_screen.dart';
import 'package:odyssey/src/utils/navigation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de ação de notificação
enum NotificationActionType {
  openMood,
  openTimer,
  openTasks,
  openHabits,
  openProfile,
  openAchievements,
  markTaskComplete,
  markHabitComplete,
  startPomodoro,
  startBreak,
  snooze,
}

/// Payload de ação de notificação
class NotificationActionPayload {
  final NotificationActionType actionType;
  final Map<String, String> data;

  NotificationActionPayload({
    required this.actionType,
    this.data = const {},
  });

  factory NotificationActionPayload.fromMap(Map<String, String?> payload) {
    final type = payload['action'] ?? payload['type'] ?? '';
    final actionType = _parseActionType(type);
    
    // Remove keys de metadados para deixar só dados
    final data = Map<String, String>.from(
      payload.map((k, v) => MapEntry(k, v ?? '')),
    )
      ..remove('action')
      ..remove('type');
    
    return NotificationActionPayload(
      actionType: actionType,
      data: data,
    );
  }

  static NotificationActionType _parseActionType(String type) {
    switch (type.toLowerCase()) {
      case 'mood_reminder':
      case 'open_mood':
        return NotificationActionType.openMood;
      case 'pomodoro_complete':
      case 'pomodoro_break_complete':
      case 'open_timer':
        return NotificationActionType.openTimer;
      case 'task_reminder':
      case 'open_tasks':
        return NotificationActionType.openTasks;
      case 'habit_reminder':
      case 'open_habits':
        return NotificationActionType.openHabits;
      case 'achievement':
      case 'level_up':
      case 'open_profile':
        return NotificationActionType.openProfile;
      default:
        return NotificationActionType.openMood;
    }
  }

  Map<String, String> toMap() {
    return {
      'action': actionType.name,
      ...data,
    };
  }
}

/// Handler global para ações de notificação
/// 
/// Responsável por:
/// 1. Processar cliques em notificações
/// 2. Navegar para a tela correta
/// 3. Passar dados relevantes
/// 4. Executar ações rápidas (marcar tarefa, etc)
class NotificationActionHandler {
  static final NotificationActionHandler _instance = NotificationActionHandler._();
  static NotificationActionHandler get instance => _instance;
  
  NotificationActionHandler._();

  // GlobalKey para acesso ao Navigator
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Container do Riverpod para acesso a providers
  static WidgetRef? _ref;
  
  // Callback para ações pendentes (quando app estava fechado)
  static const String _pendingActionKey = 'pending_notification_action_payload';
  
  /// Configura o WidgetRef para acesso aos providers
  static void setRef(WidgetRef ref) {
    _ref = ref;
  }

  /// Processa ação recebida de uma notificação
  /// 
  /// Esta função é chamada pelo callback do AwesomeNotifications
  /// quando o usuário interage com uma notificação
  @pragma("vm:entry-point")
  static Future<void> handleAction(ReceivedAction receivedAction) async {
    final buttonKey = receivedAction.buttonKeyPressed;
    final payload = receivedAction.payload ?? {};
    
    debugPrint('===========================================');
    debugPrint('NotificationActionHandler.handleAction');
    debugPrint('Button: $buttonKey');
    debugPrint('Payload: $payload');
    debugPrint('===========================================');
    
    // Se um botão específico foi pressionado, trata primeiro
    if (buttonKey.isNotEmpty) {
      await _handleButtonAction(buttonKey, payload);
      return;
    }
    
    // Clique no corpo da notificação - navegar para a tela apropriada
    await _handleNavigationAction(payload);
  }

  /// Trata ações de botões específicos
  static Future<void> _handleButtonAction(String buttonKey, Map<String, String?> payload) async {
    switch (buttonKey) {
      // Ações de Mood
      case 'MOOD_LOG_NOW':
        await _navigateToScreen(NotificationActionType.openMood, payload);
        break;
      case 'MOOD_LATER':
        // Apenas dispensa, pode agendar snooze
        break;
        
      // Ações de Tasks
      case 'TASK_COMPLETE':
        await _markTaskComplete(payload);
        break;
      case 'TASK_OPEN':
        await _navigateToScreen(NotificationActionType.openTasks, payload);
        break;
      case 'TASK_SNOOZE':
        await _snoozeNotification(payload, const Duration(minutes: 10));
        break;
        
      // Ações de Habits
      case 'HABIT_COMPLETE':
        await _markHabitComplete(payload);
        break;
      case 'HABIT_SKIP':
        // Apenas dispensa
        break;
        
      // Ações de Pomodoro (ModernNotificationService)
      case 'POMODORO_PAUSE':
      case 'POMODORO_START':
      case 'POMODORO_CONTINUE':
        await _navigateToScreen(NotificationActionType.openTimer, payload);
        break;
        
      // Ações de Timer (NotificationService legado) - NÃO tratar aqui
      // Estas são tratadas diretamente pelo NotificationService.onActionReceivedMethod
      case 'STOP_TIMER':
      case 'PAUSE_TIMER':
      case 'RESUME_TIMER':
      case 'START_BREAK':
      case 'START_FOCUS':
        // Delegado para NotificationService
        debugPrint('Ação de timer delegada para NotificationService: $buttonKey');
        break;
        
      // Ações de Achievements
      case 'ACHIEVEMENT_VIEW':
      case 'LEVEL_VIEW':
        await _navigateToScreen(NotificationActionType.openProfile, payload);
        break;
        
      default:
        debugPrint('Botão não tratado: $buttonKey');
    }
  }

  /// Trata navegação quando clica no corpo da notificação
  static Future<void> _handleNavigationAction(Map<String, String?> payload) async {
    final actionPayload = NotificationActionPayload.fromMap(payload);
    await _navigateToScreen(actionPayload.actionType, payload);
  }

  /// Navega para a tela apropriada
  static Future<void> _navigateToScreen(
    NotificationActionType actionType,
    Map<String, String?> payload,
  ) async {
    // Verificar se temos contexto de navegação
    final navigator = navigatorKey.currentState;
    
    if (navigator == null) {
      // App pode estar em background ou fechado
      // Salvar ação para executar quando app abrir
      debugPrint('Navigator não disponível, salvando ação pendente');
      await _savePendingAction(actionType, payload);
      return;
    }

    // Usar o provider de navegação se disponível
    if (_ref != null) {
      switch (actionType) {
        case NotificationActionType.openMood:
          _ref!.read(navigationProvider.notifier).goToMood();
          break;
        case NotificationActionType.openTimer:
          _ref!.read(navigationProvider.notifier).goToTimer();
          break;
        case NotificationActionType.openProfile:
        case NotificationActionType.openAchievements:
          _ref!.read(navigationProvider.notifier).goToProfile();
          break;
        case NotificationActionType.openTasks:
          // Tasks não está na navegação principal, precisa push
          navigator.push(
            MaterialPageRoute(builder: (_) => const TasksScreen()),
          );
          break;
        case NotificationActionType.openHabits:
          // Habits não está na navegação principal, precisa push
          navigator.push(
            MaterialPageRoute(builder: (_) => const HabitsCalendarScreen()),
          );
          break;
        default:
          _ref!.read(navigationProvider.notifier).goToHome();
      }
    } else {
      // Fallback: navegação direta via Navigator
      await _navigateDirectly(navigator, actionType, payload);
    }
  }

  /// Navegação direta quando Riverpod não está disponível
  static Future<void> _navigateDirectly(
    NavigatorState navigator,
    NotificationActionType actionType,
    Map<String, String?> payload,
  ) async {
    Widget? targetScreen;
    
    switch (actionType) {
      case NotificationActionType.openMood:
        targetScreen = const MoodRecordsScreen();
        break;
      case NotificationActionType.openTimer:
        targetScreen = const TimeTrackerScreen();
        break;
      case NotificationActionType.openTasks:
        targetScreen = const TasksScreen();
        break;
      case NotificationActionType.openHabits:
        targetScreen = const HabitsCalendarScreen();
        break;
      case NotificationActionType.openProfile:
      case NotificationActionType.openAchievements:
        targetScreen = const ProfileScreen();
        break;
      default:
        break;
    }
    
    if (targetScreen != null) {
      // Primeiro, garante que estamos na home
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OdysseyHome()),
        (route) => false,
      );
      
      // Depois, se não é uma tela da navegação principal, faz push
      if (actionType == NotificationActionType.openTasks ||
          actionType == NotificationActionType.openHabits) {
        navigator.push(
          MaterialPageRoute(builder: (_) => targetScreen!),
        );
      }
    }
  }

  /// Salva ação pendente para executar quando app abrir
  static Future<void> _savePendingAction(
    NotificationActionType actionType,
    Map<String, String?> payload,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actionPayload = NotificationActionPayload(
        actionType: actionType,
        data: payload.map((k, v) => MapEntry(k, v ?? '')),
      );
      
      // Serializar como JSON string simples
      final payloadStr = actionPayload.toMap().entries
          .map((e) => '${e.key}:${e.value}')
          .join('|');
      
      await prefs.setString(_pendingActionKey, payloadStr);
      debugPrint('Ação pendente salva: $payloadStr');
    } catch (e) {
      debugPrint('Erro ao salvar ação pendente: $e');
    }
  }

  /// Verifica e executa ação pendente (chamado após app inicializar)
  static Future<void> checkPendingAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payloadStr = prefs.getString(_pendingActionKey);
      
      if (payloadStr != null && payloadStr.isNotEmpty) {
        debugPrint('Ação pendente encontrada: $payloadStr');
        await prefs.remove(_pendingActionKey);
        
        // Deserializar
        final parts = payloadStr.split('|');
        final payload = <String, String>{};
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            payload[kv[0]] = kv[1];
          }
        }
        
        final actionPayload = NotificationActionPayload.fromMap(payload);
        
        // Pequeno delay para garantir que navegação está pronta
        await Future.delayed(const Duration(milliseconds: 500));
        await _navigateToScreen(actionPayload.actionType, payload);
      }
    } catch (e) {
      debugPrint('Erro ao verificar ação pendente: $e');
    }
  }

  /// Marca tarefa como completa via notificação
  static Future<void> _markTaskComplete(Map<String, String?> payload) async {
    final taskId = payload['taskId'];
    if (taskId == null) return;
    
    debugPrint('Marcando tarefa como completa: $taskId');
    
    // TODO: Implementar integração com TaskRepository
    // Isso requer acesso ao repository, que normalmente precisa do Riverpod context
    // Por enquanto, abre a tela de tasks
    await _navigateToScreen(NotificationActionType.openTasks, payload);
  }

  /// Marca hábito como completo via notificação
  static Future<void> _markHabitComplete(Map<String, String?> payload) async {
    final habitId = payload['habitId'];
    if (habitId == null) return;
    
    debugPrint('Marcando hábito como completo: $habitId');
    
    // TODO: Implementar integração com HabitsRepository
    // Por enquanto, abre a tela de hábitos
    await _navigateToScreen(NotificationActionType.openHabits, payload);
  }

  /// Adia notificação por um período
  static Future<void> _snoozeNotification(
    Map<String, String?> payload,
    Duration snoozeDuration,
  ) async {
    debugPrint('Adiando notificação por ${snoozeDuration.inMinutes} minutos');
    
    // TODO: Implementar reagendamento da notificação
    // Isso requer acesso ao ModernNotificationService
  }
}

/// Provider para o handler de ações de notificação
final notificationActionHandlerProvider = Provider<NotificationActionHandler>((ref) {
  return NotificationActionHandler.instance;
});
