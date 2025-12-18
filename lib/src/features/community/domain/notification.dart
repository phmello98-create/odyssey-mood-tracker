/// Tipos de notificação da comunidade
enum CommunityNotificationType {
  newFollower, // Alguém te seguiu
  postUpvote, // Upvote no seu post
  postComment, // Comentário no seu post
  commentReply, // Resposta ao seu comentário
  mention, // Mencionado em um post
  achievement, // Conquista desbloqueada
  milestone, // Marco atingido (100 upvotes, etc)
  announcement, // Anúncio oficial
  trending, // Seu post está em alta
}

/// Model de notificação da comunidade
class CommunityNotification {
  final String id;
  final CommunityNotificationType type;
  final String title;
  final String message;
  final String? actorName; // Quem causou a notificação
  final String? actorPhotoUrl;
  final String? postId; // Post relacionado (se houver)
  final String? postPreview; // Preview do conteúdo
  final DateTime createdAt;
  final bool isRead;

  const CommunityNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.actorName,
    this.actorPhotoUrl,
    this.postId,
    this.postPreview,
    required this.createdAt,
    this.isRead = false,
  });

  CommunityNotification copyWith({
    String? id,
    CommunityNotificationType? type,
    String? title,
    String? message,
    String? actorName,
    String? actorPhotoUrl,
    String? postId,
    String? postPreview,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return CommunityNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      actorName: actorName ?? this.actorName,
      actorPhotoUrl: actorPhotoUrl ?? this.actorPhotoUrl,
      postId: postId ?? this.postId,
      postPreview: postPreview ?? this.postPreview,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Ícone baseado no tipo
  String get iconName {
    switch (type) {
      case CommunityNotificationType.newFollower:
        return 'person_add';
      case CommunityNotificationType.postUpvote:
        return 'arrow_upward';
      case CommunityNotificationType.postComment:
        return 'chat_bubble';
      case CommunityNotificationType.commentReply:
        return 'reply';
      case CommunityNotificationType.mention:
        return 'alternate_email';
      case CommunityNotificationType.achievement:
        return 'emoji_events';
      case CommunityNotificationType.milestone:
        return 'celebration';
      case CommunityNotificationType.announcement:
        return 'campaign';
      case CommunityNotificationType.trending:
        return 'local_fire_department';
    }
  }

  /// Cor baseada no tipo
  int get colorValue {
    switch (type) {
      case CommunityNotificationType.newFollower:
        return 0xFF2196F3; // Blue
      case CommunityNotificationType.postUpvote:
        return 0xFF4CAF50; // Green
      case CommunityNotificationType.postComment:
        return 0xFF9C27B0; // Purple
      case CommunityNotificationType.commentReply:
        return 0xFF00BCD4; // Cyan
      case CommunityNotificationType.mention:
        return 0xFFFF9800; // Orange
      case CommunityNotificationType.achievement:
        return 0xFFFFD700; // Gold
      case CommunityNotificationType.milestone:
        return 0xFFE91E63; // Pink
      case CommunityNotificationType.announcement:
        return 0xFF673AB7; // Deep Purple
      case CommunityNotificationType.trending:
        return 0xFFFF5722; // Deep Orange
    }
  }
}
