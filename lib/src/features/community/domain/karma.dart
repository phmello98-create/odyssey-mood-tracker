/// Sistema de Karma da Comunidade
/// Inspirado no Reddit - pontos baseados em engajamento

/// Nível de karma do usuário
enum KarmaTier {
  bronze, // 0-99
  silver, // 100-499
  gold, // 500-999
  platinum, // 1000-4999
  diamond, // 5000-9999
  legend, // 10000+
}

extension KarmaTierExtension on KarmaTier {
  String get label {
    switch (this) {
      case KarmaTier.bronze:
        return 'Explorador';
      case KarmaTier.silver:
        return 'Aventureiro';
      case KarmaTier.gold:
        return 'Guia';
      case KarmaTier.platinum:
        return 'Mentor';
      case KarmaTier.diamond:
        return 'Sábio';
      case KarmaTier.legend:
        return 'Lenda';
    }
  }

  String get emoji {
    switch (this) {
      case KarmaTier.bronze:
        return '🌱';
      case KarmaTier.silver:
        return '⚡';
      case KarmaTier.gold:
        return '⭐';
      case KarmaTier.platinum:
        return '💎';
      case KarmaTier.diamond:
        return '👑';
      case KarmaTier.legend:
        return '🔥';
    }
  }

  int get colorValue {
    switch (this) {
      case KarmaTier.bronze:
        return 0xFF8B7355;
      case KarmaTier.silver:
        return 0xFFA8A8A8;
      case KarmaTier.gold:
        return 0xFFFFD700;
      case KarmaTier.platinum:
        return 0xFF7B68EE;
      case KarmaTier.diamond:
        return 0xFF00CED1;
      case KarmaTier.legend:
        return 0xFFFF4500;
    }
  }

  static KarmaTier fromKarma(int karma) {
    if (karma >= 10000) return KarmaTier.legend;
    if (karma >= 5000) return KarmaTier.diamond;
    if (karma >= 1000) return KarmaTier.platinum;
    if (karma >= 500) return KarmaTier.gold;
    if (karma >= 100) return KarmaTier.silver;
    return KarmaTier.bronze;
  }
}

/// Estatísticas de karma do usuário
class UserKarma {
  final int postKarma;
  final int commentKarma;
  final int awardKarma;
  final int givenAwards;

  const UserKarma({
    this.postKarma = 0,
    this.commentKarma = 0,
    this.awardKarma = 0,
    this.givenAwards = 0,
  });

  int get totalKarma => postKarma + commentKarma + awardKarma;

  KarmaTier get tier => KarmaTierExtension.fromKarma(totalKarma);

  String get formattedKarma {
    if (totalKarma >= 10000) {
      return '${(totalKarma / 1000).toStringAsFixed(1)}k';
    }
    if (totalKarma >= 1000) {
      return '${(totalKarma / 1000).toStringAsFixed(1)}k';
    }
    return totalKarma.toString();
  }

  UserKarma copyWith({
    int? postKarma,
    int? commentKarma,
    int? awardKarma,
    int? givenAwards,
  }) {
    return UserKarma(
      postKarma: postKarma ?? this.postKarma,
      commentKarma: commentKarma ?? this.commentKarma,
      awardKarma: awardKarma ?? this.awardKarma,
      givenAwards: givenAwards ?? this.givenAwards,
    );
  }

  Map<String, dynamic> toJson() => {
    'postKarma': postKarma,
    'commentKarma': commentKarma,
    'awardKarma': awardKarma,
    'givenAwards': givenAwards,
  };

  factory UserKarma.fromJson(Map<String, dynamic> json) => UserKarma(
    postKarma: json['postKarma'] ?? 0,
    commentKarma: json['commentKarma'] ?? 0,
    awardKarma: json['awardKarma'] ?? 0,
    givenAwards: json['givenAwards'] ?? 0,
  );
}

/// Registro de voto em um post/comentário
class VoteRecord {
  final String userId; // ID do usuário que votou
  final String targetId; // ID do post ou comentário
  final VoteType type;
  final DateTime createdAt;

  const VoteRecord({
    required this.userId,
    required this.targetId,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'targetId': targetId,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VoteRecord.fromJson(Map<String, dynamic> json) => VoteRecord(
    userId: json['userId'],
    targetId: json['targetId'],
    type: VoteType.values.firstWhere((e) => e.name == json['type']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

enum VoteType { upvote, downvote }
