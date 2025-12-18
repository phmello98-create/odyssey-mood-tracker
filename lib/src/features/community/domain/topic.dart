/// Categorias/Tópicos da comunidade
enum CommunityTopic {
  general,
  wellness,
  productivity,
  mindfulness,
  motivation,
  support,
  achievements,
  tips,
}

/// Extensão para metadados dos tópicos
extension CommunityTopicExtension on CommunityTopic {
  String get label {
    switch (this) {
      case CommunityTopic.general:
        return 'Geral';
      case CommunityTopic.wellness:
        return 'Bem-estar';
      case CommunityTopic.productivity:
        return 'Produtividade';
      case CommunityTopic.mindfulness:
        return 'Mindfulness';
      case CommunityTopic.motivation:
        return 'Motivação';
      case CommunityTopic.support:
        return 'Apoio';
      case CommunityTopic.achievements:
        return 'Conquistas';
      case CommunityTopic.tips:
        return 'Dicas';
    }
  }

  String get description {
    switch (this) {
      case CommunityTopic.general:
        return 'Conversas gerais da comunidade';
      case CommunityTopic.wellness:
        return 'Saúde mental e física';
      case CommunityTopic.productivity:
        return 'Foco e organização';
      case CommunityTopic.mindfulness:
        return 'Meditação e consciência';
      case CommunityTopic.motivation:
        return 'Inspiração e energia';
      case CommunityTopic.support:
        return 'Apoio mútuo e acolhimento';
      case CommunityTopic.achievements:
        return 'Celebre suas vitórias';
      case CommunityTopic.tips:
        return 'Compartilhe conhecimento';
    }
  }

  String get emoji {
    switch (this) {
      case CommunityTopic.general:
        return '💬';
      case CommunityTopic.wellness:
        return '🌿';
      case CommunityTopic.productivity:
        return '⚡';
      case CommunityTopic.mindfulness:
        return '🧘';
      case CommunityTopic.motivation:
        return '🔥';
      case CommunityTopic.support:
        return '🤝';
      case CommunityTopic.achievements:
        return '🏆';
      case CommunityTopic.tips:
        return '💡';
    }
  }

  int get colorValue {
    switch (this) {
      case CommunityTopic.general:
        return 0xFF6366F1;
      case CommunityTopic.wellness:
        return 0xFF10B981;
      case CommunityTopic.productivity:
        return 0xFFF59E0B;
      case CommunityTopic.mindfulness:
        return 0xFF8B5CF6;
      case CommunityTopic.motivation:
        return 0xFFEF4444;
      case CommunityTopic.support:
        return 0xFFEC4899;
      case CommunityTopic.achievements:
        return 0xFFF97316;
      case CommunityTopic.tips:
        return 0xFF06B6D4;
    }
  }
}

/// Estatísticas de um tópico
class TopicStats {
  final CommunityTopic topic;
  final int postCount;
  final int activeUsers;
  final DateTime? lastActivity;

  const TopicStats({
    required this.topic,
    this.postCount = 0,
    this.activeUsers = 0,
    this.lastActivity,
  });

  Map<String, dynamic> toJson() => {
    'topic': topic.name,
    'postCount': postCount,
    'activeUsers': activeUsers,
    'lastActivity': lastActivity?.toIso8601String(),
  };

  factory TopicStats.fromJson(Map<String, dynamic> json) => TopicStats(
    topic: CommunityTopic.values.firstWhere(
      (t) => t.name == json['topic'],
      orElse: () => CommunityTopic.general,
    ),
    postCount: json['postCount'] ?? 0,
    activeUsers: json['activeUsers'] ?? 0,
    lastActivity: json['lastActivity'] != null
        ? DateTime.parse(json['lastActivity'])
        : null,
  );
}
