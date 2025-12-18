import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/notification.dart';

/// Mock notifications para desenvolvimento
class MockNotificationsData {
  static List<CommunityNotification> getMockNotifications() {
    return [
      CommunityNotification(
        id: 'notif_1',
        type: CommunityNotificationType.trending,
        title: 'Seu post está em alta! 🔥',
        message: 'Seu post sobre produtividade alcançou 100+ upvotes',
        postId: 'post_1',
        postPreview:
            'Bom dia, pessoal! 👋 Acabei de completar minha primeira semana...',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      CommunityNotification(
        id: 'notif_2',
        type: CommunityNotificationType.newFollower,
        title: 'Novo seguidor!',
        message: 'Marina Costa começou a te seguir',
        actorName: 'Marina Costa',
        actorPhotoUrl: 'https://i.pravatar.cc/150?u=marina',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      CommunityNotification(
        id: 'notif_3',
        type: CommunityNotificationType.postComment,
        title: 'Novo comentário',
        message: 'Carlos Mendes comentou: "Excelente dica! Vou testar..."',
        actorName: 'Carlos Mendes',
        actorPhotoUrl: 'https://i.pravatar.cc/150?u=carlos',
        postId: 'post_5',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CommunityNotification(
        id: 'notif_4',
        type: CommunityNotificationType.postUpvote,
        title: '+25 upvotes',
        message: 'Beatriz Alves e mais 24 pessoas curtiram seu post',
        actorName: 'Beatriz Alves',
        actorPhotoUrl: 'https://i.pravatar.cc/150?u=beatriz',
        postId: 'post_1',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      CommunityNotification(
        id: 'notif_5',
        type: CommunityNotificationType.announcement,
        title: '📢 Anúncio da Comunidade',
        message: 'Novas regras de conduta foram publicadas. Confira!',
        actorName: 'Odyssey Team',
        actorPhotoUrl: 'https://i.pravatar.cc/150?u=odyssey',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      CommunityNotification(
        id: 'notif_6',
        type: CommunityNotificationType.achievement,
        title: '🏆 Conquista Desbloqueada!',
        message: 'Você ganhou o badge "Mentor" por ajudar 10 pessoas',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      CommunityNotification(
        id: 'notif_7',
        type: CommunityNotificationType.mention,
        title: 'Você foi mencionado',
        message: 'Ana Silva mencionou você em um comentário',
        actorName: 'Ana Silva',
        actorPhotoUrl: 'https://i.pravatar.cc/150?u=ana',
        postId: 'post_7',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        isRead: true,
      ),
      CommunityNotification(
        id: 'notif_8',
        type: CommunityNotificationType.milestone,
        title: '🎉 Marco atingido!',
        message: 'Você alcançou 1000 karma! Parabéns!',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      CommunityNotification(
        id: 'notif_9',
        type: CommunityNotificationType.commentReply,
        title: 'Resposta ao seu comentário',
        message: 'Fernanda Dias respondeu: "Concordo totalmente!"',
        actorName: 'Fernanda Dias',
        actorPhotoUrl: 'https://i.pravatar.cc/150?u=fernanda',
        postId: 'post_9',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }
}

/// State das notificações
class NotificationsState {
  final List<CommunityNotification> notifications;
  final bool isLoading;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<CommunityNotification>? notifications,
    bool? isLoading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier para gerenciar notificações
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState()) {
    _loadNotifications();
  }

  void _loadNotifications() {
    state = state.copyWith(isLoading: true);
    // Simula carregamento
    Future.delayed(const Duration(milliseconds: 300), () {
      state = state.copyWith(
        notifications: MockNotificationsData.getMockNotifications(),
        isLoading: false,
      );
    });
  }

  void markAsRead(String notificationId) {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void refresh() {
    _loadNotifications();
  }
}

/// Provider global das notificações
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      return NotificationsNotifier();
    });
