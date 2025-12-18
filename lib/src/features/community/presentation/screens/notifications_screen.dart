import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/notification.dart';
import '../providers/notifications_provider.dart';

/// Tela de notificações da comunidade
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Notificações'),
        centerTitle: true,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(notificationsProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todas marcadas como lidas'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'Marcar todas',
                style: TextStyle(fontSize: 13, color: colors.primary),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
          ? _buildEmptyState(colors)
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(notificationsProvider.notifier).refresh();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _NotificationItem(
                    notification: notification,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(notification.id);
                      // TODO: Navigate to related content
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Abrindo: ${notification.title}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.3),
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
            'Você está em dia!',
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final CommunityNotification notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final notifColor = Color(notification.colorValue);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? colors.surface
            : colors.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? colors.outline.withOpacity(0.1)
              : notifColor.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon ou Avatar
                _buildLeadingWidget(colors, notifColor),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
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
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Time
                      Text(
                        timeago.format(notification.createdAt, locale: 'pt_BR'),
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
      ),
    );
  }

  Widget _buildLeadingWidget(ColorScheme colors, Color notifColor) {
    if (notification.actorPhotoUrl != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(notification.actorPhotoUrl!),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: notifColor,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
              child: Icon(
                _getIconForType(notification.type),
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: notifColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIconForType(notification.type),
        size: 20,
        color: notifColor,
      ),
    );
  }

  IconData _getIconForType(CommunityNotificationType type) {
    switch (type) {
      case CommunityNotificationType.newFollower:
        return Icons.person_add_rounded;
      case CommunityNotificationType.postUpvote:
        return Icons.arrow_upward_rounded;
      case CommunityNotificationType.postComment:
        return Icons.chat_bubble_rounded;
      case CommunityNotificationType.commentReply:
        return Icons.reply_rounded;
      case CommunityNotificationType.mention:
        return Icons.alternate_email_rounded;
      case CommunityNotificationType.achievement:
        return Icons.emoji_events_rounded;
      case CommunityNotificationType.milestone:
        return Icons.celebration_rounded;
      case CommunityNotificationType.announcement:
        return Icons.campaign_rounded;
      case CommunityNotificationType.trending:
        return Icons.local_fire_department_rounded;
    }
  }
}
