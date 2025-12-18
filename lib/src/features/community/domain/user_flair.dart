/// Sistema de Títulos de Usuário (User Flairs)
/// Títulos baseados em karma, atividade e conquistas

/// Flair/Título do usuário
class UserFlair {
  final String title;
  final String? emoji;
  final int colorValue;
  final FlairType type;
  final bool isCustom;

  const UserFlair({
    required this.title,
    this.emoji,
    required this.colorValue,
    required this.type,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'emoji': emoji,
    'colorValue': colorValue,
    'type': type.name,
    'isCustom': isCustom,
  };

  factory UserFlair.fromJson(Map<String, dynamic> json) => UserFlair(
    title: json['title'],
    emoji: json['emoji'],
    colorValue: json['colorValue'],
    type: FlairType.values.firstWhere((e) => e.name == json['type']),
    isCustom: json['isCustom'] ?? false,
  );
}

enum FlairType {
  karma, // Baseado em karma
  streak, // Baseado em streak
  special, // Especial (moderador, verificado)
  custom, // Personalizado
}

/// Flairs padrão baseados em karma
class DefaultFlairs {
  static const UserFlair explorer = UserFlair(
    title: 'Explorador',
    emoji: '🌱',
    colorValue: 0xFF8B8B8B,
    type: FlairType.karma,
  );

  static const UserFlair adventurer = UserFlair(
    title: 'Aventureiro',
    emoji: '⚡',
    colorValue: 0xFF4CAF50,
    type: FlairType.karma,
  );

  static const UserFlair guide = UserFlair(
    title: 'Guia',
    emoji: '⭐',
    colorValue: 0xFF2196F3,
    type: FlairType.karma,
  );

  static const UserFlair mentor = UserFlair(
    title: 'Mentor',
    emoji: '💎',
    colorValue: 0xFF9C27B0,
    type: FlairType.karma,
  );

  static const UserFlair sage = UserFlair(
    title: 'Sábio',
    emoji: '👑',
    colorValue: 0xFFFFD700,
    type: FlairType.karma,
  );

  static const UserFlair legend = UserFlair(
    title: 'Lenda',
    emoji: '🔥',
    colorValue: 0xFFFF4500,
    type: FlairType.karma,
  );

  // Streak flairs
  static const UserFlair streak7 = UserFlair(
    title: '7 dias',
    emoji: '🔥',
    colorValue: 0xFFFF5722,
    type: FlairType.streak,
  );

  static const UserFlair streak30 = UserFlair(
    title: '30 dias',
    emoji: '💎',
    colorValue: 0xFF00BCD4,
    type: FlairType.streak,
  );

  // Special flairs
  static const UserFlair moderator = UserFlair(
    title: 'Moderador',
    emoji: '🛡️',
    colorValue: 0xFF4CAF50,
    type: FlairType.special,
  );

  static const UserFlair verified = UserFlair(
    title: 'Verificado',
    emoji: '✅',
    colorValue: 0xFF2196F3,
    type: FlairType.special,
  );

  static const UserFlair topContributor = UserFlair(
    title: 'Top Contribuidor',
    emoji: '🏆',
    colorValue: 0xFFFFD700,
    type: FlairType.special,
  );

  static UserFlair fromKarma(int karma) {
    if (karma >= 10000) return legend;
    if (karma >= 5000) return sage;
    if (karma >= 1000) return mentor;
    if (karma >= 500) return guide;
    if (karma >= 100) return adventurer;
    return explorer;
  }
}
