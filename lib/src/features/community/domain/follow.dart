/// Model de relacionamento de seguidor
class Follow {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  const Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'] as String,
      followerId: json['followerId'] as String,
      followingId: json['followingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Estatísticas de seguidores de um usuário
class FollowStats {
  final String userId;
  final int followersCount;
  final int followingCount;

  const FollowStats({
    required this.userId,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  FollowStats copyWith({
    String? userId,
    int? followersCount,
    int? followingCount,
  }) {
    return FollowStats(
      userId: userId ?? this.userId,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
  }

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      userId: json['userId'] as String,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
    );
  }
}
