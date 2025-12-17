// lib/src/features/diary/services/diary_reminder_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ID da notificação do diário (range reservado: 200-299)
const int _diaryReminderId = 200;

/// Serviço de lembretes para o diário
class DiaryReminderService {
  static const _keyEnabled = 'diary_reminder_enabled';
  static const _keyTime = 'diary_reminder_time';
  static const _keyLastNotified = 'diary_last_notified';

  final SharedPreferences _prefs;

  DiaryReminderService(this._prefs);

  /// Verifica se os lembretes estão habilitados
  bool get isEnabled => _prefs.getBool(_keyEnabled) ?? false;

  /// Retorna o horário do lembrete (formato "HH:mm")
  String get reminderTime => _prefs.getString(_keyTime) ?? '21:00';

  /// Hora do lembrete
  int get reminderHour {
    final parts = reminderTime.split(':');
    return int.tryParse(parts[0]) ?? 21;
  }

  /// Minuto do lembrete
  int get reminderMinute {
    final parts = reminderTime.split(':');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  /// Habilita os lembretes
  Future<void> enable() async {
    await _prefs.setBool(_keyEnabled, true);
    await _scheduleNotification();
    debugPrint('[DiaryReminderService] Reminders enabled');
  }

  /// Desabilita os lembretes
  Future<void> disable() async {
    await _prefs.setBool(_keyEnabled, false);
    await _cancelNotification();
    debugPrint('[DiaryReminderService] Reminders disabled');
  }

  /// Define o horário do lembrete
  Future<void> setTime(int hour, int minute) async {
    final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    await _prefs.setString(_keyTime, time);
    debugPrint('[DiaryReminderService] Reminder time set to $time');

    if (isEnabled) {
      await _scheduleNotification();
    }
  }

  /// Agenda a notificação diária usando AwesomeNotifications
  Future<void> _scheduleNotification() async {
    try {
      // Cancela notificação anterior primeiro
      await _cancelNotification();

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _diaryReminderId,
          channelKey: 'reminders_channel',
          title: '📝 Hora de escrever!',
          body: 'Como foi seu dia? Registre seus pensamentos no diário.',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          payload: {'type': 'diary_reminder'},
        ),
        schedule: NotificationCalendar(
          hour: reminderHour,
          minute: reminderMinute,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
      );
      debugPrint('[DiaryReminderService] Notification scheduled for $reminderTime');
    } catch (e) {
      debugPrint('[DiaryReminderService] Error scheduling notification: $e');
    }
  }

  /// Cancela a notificação diária
  Future<void> _cancelNotification() async {
    try {
      await AwesomeNotifications().cancel(_diaryReminderId);
      debugPrint('[DiaryReminderService] Notification cancelled');
    } catch (e) {
      debugPrint('[DiaryReminderService] Error cancelling notification: $e');
    }
  }

  /// Inicializa o serviço (chamado no startup)
  Future<void> initialize() async {
    if (isEnabled) {
      await _scheduleNotification();
    }
  }

  /// Registra que foi notificado hoje (evitar duplicatas)
  Future<void> markNotified() async {
    await _prefs.setString(_keyLastNotified, DateTime.now().toIso8601String());
  }

  /// Verifica se já foi notificado hoje
  bool wasNotifiedToday() {
    final lastNotified = _prefs.getString(_keyLastNotified);
    if (lastNotified == null) return false;

    final date = DateTime.tryParse(lastNotified);
    if (date == null) return false;

    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}

/// Provider para criar o serviço com dependências
final diaryReminderServiceProvider = FutureProvider<DiaryReminderService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final service = DiaryReminderService(prefs);
  await service.initialize();
  return service;
});
