/// Sistema de Badges da Comunidade
/// Inspirado em Reddit, Discord e Duolingo

/// Categorias de badges
enum BadgeCategory {
  onboarding, // Boas-vindas
  contribution, // Contribuição
  engagement, // Engajamento
  specialist, // Especialista
  special, // Especiais
  streak, // Streaks
}

/// Definição de um badge
class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeCategory category;
  final int colorValue;
  final bool isRare;
  final int? requiredValue; // Valor necessário para desbloquear

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.colorValue,
    this.isRare = false,
    this.requiredValue,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'category': category.name,
    'colorValue': colorValue,
    'isRare': isRare,
    'requiredValue': requiredValue,
  };

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    emoji: json['emoji'],
    category: BadgeCategory.values.firstWhere(
      (e) => e.name == json['category'],
    ),
    colorValue: json['colorValue'],
    isRare: json['isRare'] ?? false,
    requiredValue: json['requiredValue'],
  );
}

/// Badge conquistado por um usuário
class UserBadge {
  final Badge badge;
  final DateTime earnedAt;
  final bool isDisplayed; // Badge principal exibido no perfil

  const UserBadge({
    required this.badge,
    required this.earnedAt,
    this.isDisplayed = false,
  });

  Map<String, dynamic> toJson() => {
    'badge': badge.toJson(),
    'earnedAt': earnedAt.toIso8601String(),
    'isDisplayed': isDisplayed,
  };

  factory UserBadge.fromJson(Map<String, dynamic> json) => UserBadge(
    badge: Badge.fromJson(json['badge']),
    earnedAt: DateTime.parse(json['earnedAt']),
    isDisplayed: json['isDisplayed'] ?? false,
  );
}

/// Catálogo de todos os badges disponíveis
class BadgeCatalog {
  static const List<Badge> all = [
    // Onboarding
    Badge(
      id: 'first_post',
      name: 'Primeiro Passo',
      description: 'Criou seu primeiro post',
      emoji: '🌟',
      category: BadgeCategory.onboarding,
      colorValue: 0xFFFFD700,
    ),
    Badge(
      id: 'first_comment',
      name: 'Voz Ativa',
      description: 'Fez seu primeiro comentário',
      emoji: '💬',
      category: BadgeCategory.onboarding,
      colorValue: 0xFF4CAF50,
    ),
    Badge(
      id: 'profile_complete',
      name: 'Perfil Completo',
      description: 'Completou seu perfil',
      emoji: '👤',
      category: BadgeCategory.onboarding,
      colorValue: 0xFF2196F3,
    ),

    // Contribution
    Badge(
      id: 'writer_10',
      name: 'Escritor',
      description: 'Criou 10 posts',
      emoji: '📝',
      category: BadgeCategory.contribution,
      colorValue: 0xFF9C27B0,
      requiredValue: 10,
    ),
    Badge(
      id: 'writer_50',
      name: 'Prolífico',
      description: 'Criou 50 posts',
      emoji: '✨',
      category: BadgeCategory.contribution,
      colorValue: 0xFF673AB7,
      requiredValue: 50,
    ),
    Badge(
      id: 'writer_100',
      name: 'Autor',
      description: 'Criou 100 posts',
      emoji: '📚',
      category: BadgeCategory.contribution,
      colorValue: 0xFF3F51B5,
      isRare: true,
      requiredValue: 100,
    ),

    // Engagement
    Badge(
      id: 'karma_100',
      name: 'Querido',
      description: 'Recebeu 100 upvotes',
      emoji: '❤️',
      category: BadgeCategory.engagement,
      colorValue: 0xFFE91E63,
      requiredValue: 100,
    ),
    Badge(
      id: 'karma_1000',
      name: 'Em Chamas',
      description: 'Recebeu 1000 upvotes',
      emoji: '🔥',
      category: BadgeCategory.engagement,
      colorValue: 0xFFFF5722,
      requiredValue: 1000,
    ),
    Badge(
      id: 'karma_10000',
      name: 'Lenda',
      description: 'Recebeu 10.000 upvotes',
      emoji: '👑',
      category: BadgeCategory.engagement,
      colorValue: 0xFFFFD700,
      isRare: true,
      requiredValue: 10000,
    ),

    // Specialist
    Badge(
      id: 'mindfulness_guru',
      name: 'Guru Mindfulness',
      description: '20 posts em Mindfulness',
      emoji: '🧘',
      category: BadgeCategory.specialist,
      colorValue: 0xFF9D84B7,
      requiredValue: 20,
    ),
    Badge(
      id: 'productivity_master',
      name: 'Mestre Produtividade',
      description: '20 posts em Produtividade',
      emoji: '⚡',
      category: BadgeCategory.specialist,
      colorValue: 0xFFE8B86D,
      requiredValue: 20,
    ),
    Badge(
      id: 'supporter',
      name: 'Apoiador',
      description: '50 comentários de apoio',
      emoji: '🤝',
      category: BadgeCategory.specialist,
      colorValue: 0xFFD4A5A5,
      requiredValue: 50,
    ),

    // Special
    Badge(
      id: 'anniversary',
      name: 'Aniversariante',
      description: '1 ano na comunidade',
      emoji: '🎂',
      category: BadgeCategory.special,
      colorValue: 0xFFFF9800,
      isRare: true,
    ),
    Badge(
      id: 'verified',
      name: 'Verificado',
      description: 'Conta verificada',
      emoji: '✅',
      category: BadgeCategory.special,
      colorValue: 0xFF2196F3,
      isRare: true,
    ),
    Badge(
      id: 'moderator',
      name: 'Moderador',
      description: 'Membro da equipe',
      emoji: '🛡️',
      category: BadgeCategory.special,
      colorValue: 0xFF4CAF50,
      isRare: true,
    ),

    // Streak
    Badge(
      id: 'streak_7',
      name: 'Semana Consistente',
      description: '7 dias seguidos',
      emoji: '🔥',
      category: BadgeCategory.streak,
      colorValue: 0xFFFF5722,
      requiredValue: 7,
    ),
    Badge(
      id: 'streak_30',
      name: 'Mês Dedicado',
      description: '30 dias seguidos',
      emoji: '💎',
      category: BadgeCategory.streak,
      colorValue: 0xFF00BCD4,
      isRare: true,
      requiredValue: 30,
    ),
    Badge(
      id: 'top_contributor',
      name: 'Top Contribuidor',
      description: 'Mais ativo do mês',
      emoji: '🏆',
      category: BadgeCategory.streak,
      colorValue: 0xFFFFD700,
      isRare: true,
    ),
  ];

  static Badge? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Badge> byCategory(BadgeCategory category) {
    return all.where((b) => b.category == category).toList();
  }
}
