import 'package:flutter/foundation.dart';
import 'package:odyssey/src/utils/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Métricas de engajamento com notificações
class NotificationMetrics {
  final int totalSent;
  final int totalOpened;
  final int totalDismissed;
  final double openRate;
  final Map<String, int> sentByType;
  final Map<String, int> openedByType;
  final Map<String, double> openRateByType;
  final Map<int, int> sentByHour;
  final Map<int, int> openedByHour;

  NotificationMetrics({
    required this.totalSent,
    required this.totalOpened,
    required this.totalDismissed,
    required this.openRate,
    required this.sentByType,
    required this.openedByType,
    required this.openRateByType,
    required this.sentByHour,
    required this.openedByHour,
  });

  /// Melhor horário para enviar notificações baseado na taxa de abertura
  int get bestHourToSend {
    if (openedByHour.isEmpty || sentByHour.isEmpty) return 20; // Default: 20h

    int bestHour = 20;
    double bestRate = 0;

    for (final hour in sentByHour.keys) {
      final sent = sentByHour[hour] ?? 0;
      final opened = openedByHour[hour] ?? 0;
      if (sent > 0) {
        final rate = opened / sent;
        if (rate > bestRate) {
          bestRate = rate;
          bestHour = hour;
        }
      }
    }

    return bestHour;
  }

  /// Tipo de notificação com melhor engajamento
  String get bestPerformingType {
    if (openRateByType.isEmpty) return 'mood_reminder';

    String best = 'mood_reminder';
    double bestRate = 0;

    for (final entry in openRateByType.entries) {
      if (entry.value > bestRate) {
        bestRate = entry.value;
        best = entry.key;
      }
    }

    return best;
  }
}

/// Serviço de analytics para notificações
class NotificationAnalyticsService {
  static final NotificationAnalyticsService _instance =
      NotificationAnalyticsService._();
  static NotificationAnalyticsService get instance => _instance;

  NotificationAnalyticsService._();

  SharedPreferences? _prefs;

  // Keys para persistência
  static const String _keyPrefix = 'notification_analytics_';
  static const String _keySentCount = '${_keyPrefix}sent_count';
  static const String _keyOpenedCount = '${_keyPrefix}opened_count';
  static const String _keyDismissedCount = '${_keyPrefix}dismissed_count';
  static const String _keySentByType = '${_keyPrefix}sent_by_type_';
  static const String _keyOpenedByType = '${_keyPrefix}opened_by_type_';
  static const String _keySentByHour = '${_keyPrefix}sent_by_hour_';
  static const String _keyOpenedByHour = '${_keyPrefix}opened_by_hour_';
  static const String _keyLastOptimizedHour = '${_keyPrefix}optimized_hour';

  /// Inicializa o serviço
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('📊 NotificationAnalyticsService inicializado');
  }

  /// Registra uma notificação enviada
  Future<void> trackNotificationSent({
    required String notificationId,
    required String type,
    Map<String, dynamic>? extraParams,
  }) async {
    final now = DateTime.now();
    final hour = now.hour;

    // Incrementar contadores
    await _incrementCounter(_keySentCount);
    await _incrementCounter('$_keySentByType$type');
    await _incrementCounter('$_keySentByHour$hour');

    // Enviar para Firebase Analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: notificationId,
      action: 'sent',
      extraParams: {
        'type': type,
        'hour': hour.toString(),
        ...?extraParams,
      },
    );

    debugPrint('📊 Notification sent tracked: $type at $hour:00');
  }

  /// Registra uma notificação aberta
  Future<void> trackNotificationOpened({
    required String notificationId,
    required String type,
    Map<String, dynamic>? extraParams,
  }) async {
    final now = DateTime.now();
    final hour = now.hour;

    // Incrementar contadores
    await _incrementCounter(_keyOpenedCount);
    await _incrementCounter('$_keyOpenedByType$type');
    await _incrementCounter('$_keyOpenedByHour$hour');

    // Enviar para Firebase Analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: notificationId,
      action: 'opened',
      extraParams: {
        'type': type,
        'hour': hour.toString(),
        ...?extraParams,
      },
    );

    debugPrint('📊 Notification opened tracked: $type at $hour:00');
  }

  /// Registra uma notificação dispensada
  Future<void> trackNotificationDismissed({
    required String notificationId,
    required String type,
    Map<String, dynamic>? extraParams,
  }) async {
    await _incrementCounter(_keyDismissedCount);

    // Enviar para Firebase Analytics
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: notificationId,
      action: 'dismissed',
      extraParams: {
        'type': type,
        ...?extraParams,
      },
    );

    debugPrint('📊 Notification dismissed tracked: $type');
  }

  /// Registra ação tomada a partir de uma notificação
  Future<void> trackNotificationAction({
    required String notificationId,
    required String type,
    required String action,
    Map<String, dynamic>? extraParams,
  }) async {
    await FirebaseService.instance.trackNotificationInteraction(
      notificationId: notificationId,
      action: 'action_$action',
      extraParams: {
        'type': type,
        ...?extraParams,
      },
    );

    debugPrint('📊 Notification action tracked: $action for $type');
  }

  /// Obtém métricas de engajamento
  Future<NotificationMetrics> getMetrics() async {
    final totalSent = _prefs?.getInt(_keySentCount) ?? 0;
    final totalOpened = _prefs?.getInt(_keyOpenedCount) ?? 0;
    final totalDismissed = _prefs?.getInt(_keyDismissedCount) ?? 0;
    final openRate = totalSent > 0 ? totalOpened / totalSent : 0.0;

    // Métricas por tipo
    final sentByType = <String, int>{};
    final openedByType = <String, int>{};
    final openRateByType = <String, double>{};

    final types = [
      'mood_reminder',
      'streak_alert',
      'achievement',
      'level_up',
      'pomodoro',
      'reengagement',
      'insight',
    ];

    for (final type in types) {
      final sent = _prefs?.getInt('$_keySentByType$type') ?? 0;
      final opened = _prefs?.getInt('$_keyOpenedByType$type') ?? 0;

      if (sent > 0) {
        sentByType[type] = sent;
        openedByType[type] = opened;
        openRateByType[type] = opened / sent;
      }
    }

    // Métricas por hora
    final sentByHour = <int, int>{};
    final openedByHour = <int, int>{};

    for (int hour = 0; hour < 24; hour++) {
      final sent = _prefs?.getInt('$_keySentByHour$hour') ?? 0;
      final opened = _prefs?.getInt('$_keyOpenedByHour$hour') ?? 0;

      if (sent > 0) {
        sentByHour[hour] = sent;
        openedByHour[hour] = opened;
      }
    }

    return NotificationMetrics(
      totalSent: totalSent,
      totalOpened: totalOpened,
      totalDismissed: totalDismissed,
      openRate: openRate,
      sentByType: sentByType,
      openedByType: openedByType,
      openRateByType: openRateByType,
      sentByHour: sentByHour,
      openedByHour: openedByHour,
    );
  }

  /// Obtém o melhor horário otimizado para notificações
  Future<int> getOptimizedNotificationHour() async {
    // Verificar se já foi calculado
    final cached = _prefs?.getInt(_keyLastOptimizedHour);
    if (cached != null) return cached;

    // Calcular com base nas métricas
    final metrics = await getMetrics();
    final bestHour = metrics.bestHourToSend;

    // Cachear resultado
    await _prefs?.setInt(_keyLastOptimizedHour, bestHour);

    return bestHour;
  }

  /// Recalcula o horário otimizado
  Future<int> recalculateOptimizedHour() async {
    await _prefs?.remove(_keyLastOptimizedHour);
    return getOptimizedNotificationHour();
  }

  /// Obtém taxa de abertura para um tipo específico
  Future<double> getOpenRateForType(String type) async {
    final sent = _prefs?.getInt('$_keySentByType$type') ?? 0;
    final opened = _prefs?.getInt('$_keyOpenedByType$type') ?? 0;
    return sent > 0 ? opened / sent : 0.0;
  }

  /// Verifica se notificações estão tendo bom engajamento
  Future<bool> hasGoodEngagement() async {
    final metrics = await getMetrics();
    // Considerar bom engajamento se taxa de abertura > 20%
    return metrics.openRate > 0.2;
  }

  /// Reseta todas as métricas (para debug)
  Future<void> resetMetrics() async {
    final keys = _prefs?.getKeys().where((k) => k.startsWith(_keyPrefix)) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    debugPrint('📊 Notification analytics reset');
  }

  /// Incrementa um contador
  Future<void> _incrementCounter(String key) async {
    final current = _prefs?.getInt(key) ?? 0;
    await _prefs?.setInt(key, current + 1);
  }

  /// Exporta métricas para debug
  Future<Map<String, dynamic>> exportMetrics() async {
    final metrics = await getMetrics();
    return {
      'total_sent': metrics.totalSent,
      'total_opened': metrics.totalOpened,
      'total_dismissed': metrics.totalDismissed,
      'open_rate': '${(metrics.openRate * 100).toStringAsFixed(1)}%',
      'best_hour': metrics.bestHourToSend,
      'best_type': metrics.bestPerformingType,
      'sent_by_type': metrics.sentByType,
      'open_rate_by_type': metrics.openRateByType.map(
        (k, v) => MapEntry(k, '${(v * 100).toStringAsFixed(1)}%'),
      ),
    };
  }
}

/// Extension para formatar métricas
extension NotificationMetricsFormatting on NotificationMetrics {
  String get formattedOpenRate => '${(openRate * 100).toStringAsFixed(1)}%';

  String get summaryText {
    return 'Enviadas: $totalSent | Abertas: $totalOpened ($formattedOpenRate)';
  }

  String get bestTimeText {
    final hour = bestHourToSend;
    return '$hour:00 - ${hour + 1}:00';
  }
}
