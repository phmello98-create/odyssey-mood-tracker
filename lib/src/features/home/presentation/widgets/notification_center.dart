import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

/// Modelo de notificação do histórico
class NotificationHistoryItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? payload;

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.payload,
  });

  factory NotificationHistoryItem.fromMap(Map<dynamic, dynamic> map) {
    return NotificationHistoryItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      type: map['type'] ?? 'general',
      isRead: map['isRead'] ?? false,
      payload: map['payload'] != null 
          ? Map<String, dynamic>.from(map['payload']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
      'payload': payload,
    };
  }

  NotificationHistoryItem copyWith({bool? isRead}) {
    return NotificationHistoryItem(
      id: id,
      title: title,
      body: body,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
      payload: payload,
    );
  }
}

/// Provider para gerenciar histórico de notificações
final notificationHistoryProvider = StateNotifierProvider<NotificationHistoryNotifier, List<NotificationHistoryItem>>((ref) {
  return NotificationHistoryNotifier();
});

class NotificationHistoryNotifier extends StateNotifier<List<NotificationHistoryItem>> {
  NotificationHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const _boxName = 'notification_history';

  Future<void> _loadHistory() async {
    try {
      final box = await Hive.openBox(_boxName);
      final items = box.values.map((e) {
        if (e is Map) {
          return NotificationHistoryItem.fromMap(e);
        }
        return null;
      }).whereType<NotificationHistoryItem>().toList();
      
      // Ordenar por data mais recente
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = items;
    } catch (e) {
      debugPrint('Error loading notification history: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? payload,
  }) async {
    try {
      final box = await Hive.openBox(_boxName);
      final item = NotificationHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
        payload: payload,
      );
      
      await box.put(item.id, item.toMap());
      state = [item, ...state];
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final box = await Hive.openBox(_boxName);
      final index = state.indexWhere((item) => item.id == id);
      if (index != -1) {
        final updatedItem = state[index].copyWith(isRead: true);
        await box.put(id, updatedItem.toMap());
        state = [
          ...state.sublist(0, index),
          updatedItem,
          ...state.sublist(index + 1),
        ];
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final box = await Hive.openBox(_boxName);
      final updatedItems = state.map((item) {
        final updated = item.copyWith(isRead: true);
        box.put(item.id, updated.toMap());
        return updated;
      }).toList();
      state = updatedItems;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(id);
      state = state.where((item) => item.id != id).toList();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.clear();
      state = [];
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  int get unreadCount => state.where((item) => !item.isRead).length;
}

/// Botão de notificações com badge de contagem
class NotificationButton extends ConsumerWidget {
  final VoidCallback? onTap;

  const NotificationButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationHistoryProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap ?? () => _showNotificationCenter(context, ref),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.outline.withOpacity(0.1),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_rounded,
              color: colors.onSurfaceVariant,
              size: 24,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showNotificationCenter(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationCenterSheet(),
    );
  }
}

/// Modal central de notificações
class NotificationCenterSheet extends ConsumerStatefulWidget {
  const NotificationCenterSheet({super.key});

  @override
  ConsumerState<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends ConsumerState<NotificationCenterSheet> {
  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationHistoryProvider);
    final notifier = ref.read(notificationHistoryProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificações',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount não lidas',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (notifications.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(
                        Icons.done_all_rounded,
                        color: colors.primary,
                      ),
                      tooltip: 'Marcar todas como lidas',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        notifier.markAllAsRead();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_sweep_rounded,
                        color: colors.error,
                      ),
                      tooltip: 'Limpar todas',
                      onPressed: () => _showClearConfirmation(context, notifier),
                    ),
                  ],
                ],
              ),
            ),

            Divider(color: colors.outline.withOpacity(0.1), height: 1),

            // Notification List
            Expanded(
              child: notifications.isEmpty
                  ? _buildEmptyState(colors)
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(
                          notification,
                          colors,
                          notifier,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationHistoryItem notification,
    ColorScheme colors,
    NotificationHistoryNotifier notifier,
  ) {
    final typeConfig = _getTypeConfig(notification.type);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM');
    final now = DateTime.now();
    final isToday = notification.timestamp.day == now.day &&
        notification.timestamp.month == now.month &&
        notification.timestamp.year == now.year;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => notifier.deleteNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: colors.error,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          notifier.markAsRead(notification.id);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? colors.surfaceContainerHighest.withOpacity(0.3)
                : typeConfig.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? colors.outline.withOpacity(0.05)
                  : typeConfig.color.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeConfig.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeConfig.icon,
                  color: typeConfig.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: typeConfig.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isToday
                          ? 'Hoje às ${timeFormat.format(notification.timestamp)}'
                          : '${dateFormat.format(notification.timestamp)} às ${timeFormat.format(notification.timestamp)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _getTypeConfig(String type) {
    switch (type) {
      case 'habit':
        return (icon: Icons.repeat_rounded, color: const Color(0xFF8B5CF6));
      case 'task':
        return (icon: Icons.check_circle_rounded, color: const Color(0xFF06B6D4));
      case 'mood':
        return (icon: Icons.mood_rounded, color: const Color(0xFF10B981));
      case 'streak':
        return (icon: Icons.local_fire_department_rounded, color: const Color(0xFFF59E0B));
      case 'achievement':
        return (icon: Icons.emoji_events_rounded, color: const Color(0xFFF59E0B));
      case 'reminder':
        return (icon: Icons.alarm_rounded, color: const Color(0xFF3B82F6));
      case 'system':
        return (icon: Icons.info_rounded, color: const Color(0xFF6B7280));
      default:
        return (icon: Icons.notifications_rounded, color: const Color(0xFF6366F1));
    }
  }

  void _showClearConfirmation(BuildContext context, NotificationHistoryNotifier notifier) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Limpar notificações?',
          style: TextStyle(color: colors.onSurface),
        ),
        content: Text(
          'Todas as notificações serão removidas permanentemente.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              notifier.clearAll();
              Navigator.pop(context);
            },
            child: Text(
              'Limpar',
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 72,
            color: colors.onSurfaceVariant.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma notificação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas notificações aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
