import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/utils/services/modern_notification_service.dart';
import 'package:odyssey/src/utils/services/modern_notification_scheduler.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';

/// Provider para o serviço de notificações modernas
final modernNotificationServiceProvider = Provider<ModernNotificationService>((ref) {
  return ModernNotificationService.instance;
});

/// Provider para o scheduler de notificações modernas
final modernNotificationSchedulerProvider = Provider<ModernNotificationScheduler>((ref) {
  return ModernNotificationScheduler.instance;
});

/// Provider para inicialização do sistema de notificações
final modernNotificationInitProvider = FutureProvider<void>((ref) async {
  // Inicializar serviço
  final service = ref.read(modernNotificationServiceProvider);
  await service.initialize();
  
  // Solicitar permissões
  final allowed = await service.isNotificationAllowed();
  if (!allowed) {
    await service.requestPermissions();
  }
  
  // Inicializar scheduler
  final scheduler = ref.read(modernNotificationSchedulerProvider);
  final taskRepo = ref.read(taskRepositoryProvider);
  final habitRepo = ref.read(habitRepositoryProvider);
  
  await scheduler.initialize(
    taskRepo: taskRepo,
    habitRepo: habitRepo,
  );
});

/// Provider para configurações de notificações
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier(ref);
});

class NotificationSettings {
  final bool moodRemindersEnabled;
  final String moodReminderTime;
  final bool taskRemindersEnabled;
  final bool habitRemindersEnabled;
  final bool motivationEnabled;
  final int motivationFrequency;

  NotificationSettings({
    required this.moodRemindersEnabled,
    required this.moodReminderTime,
    required this.taskRemindersEnabled,
    required this.habitRemindersEnabled,
    required this.motivationEnabled,
    required this.motivationFrequency,
  });

  NotificationSettings copyWith({
    bool? moodRemindersEnabled,
    String? moodReminderTime,
    bool? taskRemindersEnabled,
    bool? habitRemindersEnabled,
    bool? motivationEnabled,
    int? motivationFrequency,
  }) {
    return NotificationSettings(
      moodRemindersEnabled: moodRemindersEnabled ?? this.moodRemindersEnabled,
      moodReminderTime: moodReminderTime ?? this.moodReminderTime,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      habitRemindersEnabled: habitRemindersEnabled ?? this.habitRemindersEnabled,
      motivationEnabled: motivationEnabled ?? this.motivationEnabled,
      motivationFrequency: motivationFrequency ?? this.motivationFrequency,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final Ref ref;
  
  NotificationSettingsNotifier(this.ref) : super(
    NotificationSettings(
      moodRemindersEnabled: true,
      moodReminderTime: '20:00',
      taskRemindersEnabled: true,
      habitRemindersEnabled: true,
      motivationEnabled: true,
      motivationFrequency: 2,
    ),
  ) {
    _loadSettings();
  }

  void _loadSettings() {
    final scheduler = ref.read(modernNotificationSchedulerProvider);
    state = NotificationSettings(
      moodRemindersEnabled: scheduler.isMoodReminderEnabled,
      moodReminderTime: scheduler.moodReminderTime,
      taskRemindersEnabled: scheduler.isTaskReminderEnabled,
      habitRemindersEnabled: scheduler.isHabitReminderEnabled,
      motivationEnabled: scheduler.isMotivationEnabled,
      motivationFrequency: scheduler.motivationFrequency,
    );
  }

  Future<void> setMoodRemindersEnabled(bool enabled) async {
    final scheduler = ref.read(modernNotificationSchedulerProvider);
    await scheduler.setMoodReminderEnabled(enabled);
    state = state.copyWith(moodRemindersEnabled: enabled);
  }

  Future<void> setMoodReminderTime(int hour, int minute) async {
    final scheduler = ref.read(modernNotificationSchedulerProvider);
    await scheduler.setMoodReminderTime(hour, minute);
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    state = state.copyWith(moodReminderTime: timeStr);
  }

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    final scheduler = ref.read(modernNotificationSchedulerProvider);
    await scheduler.setTaskReminderEnabled(enabled);
    state = state.copyWith(taskRemindersEnabled: enabled);
  }

  Future<void> setHabitRemindersEnabled(bool enabled) async {
    final scheduler = ref.read(modernNotificationSchedulerProvider);
    await scheduler.setHabitReminderEnabled(enabled);
    state = state.copyWith(habitRemindersEnabled: enabled);
  }

  Future<void> setMotivationEnabled(bool enabled) async {
    final scheduler = ref.read(modernNotificationSchedulerProvider);
    await scheduler.setMotivationEnabled(enabled);
    state = state.copyWith(motivationEnabled: enabled);
  }

  Future<void> setMotivationFrequency(int perDay) async {
    final scheduler = ref.read(modernNotificationSchedulerProvider);
    await scheduler.setMotivationFrequency(perDay);
    state = state.copyWith(motivationFrequency: perDay);
  }
}
