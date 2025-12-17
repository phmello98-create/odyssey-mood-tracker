/// Configurações de privacidade do perfil público
class PrivacySettings {
  final bool showBadges;
  final bool showLevel;
  final bool showPosts;
  final bool allowComments;

  const PrivacySettings({
    this.showBadges = true,
    this.showLevel = true,
    this.showPosts = true,
    this.allowComments = true,
  });

  PrivacySettings copyWith({
    bool? showBadges,
    bool? showLevel,
    bool? showPosts,
    bool? allowComments,
  }) {
    return PrivacySettings(
      showBadges: showBadges ?? this.showBadges,
      showLevel: showLevel ?? this.showLevel,
      showPosts: showPosts ?? this.showPosts,
      allowComments: allowComments ?? this.allowComments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showBadges': showBadges,
      'showLevel': showLevel,
      'showPosts': showPosts,
      'allowComments': allowComments,
    };
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showBadges: json['showBadges'] as bool? ?? true,
      showLevel: json['showLevel'] as bool? ?? true,
      showPosts: json['showPosts'] as bool? ?? true,
      allowComments: json['allowComments'] as bool? ?? true,
    );
  }
}

/// Perfil público do usuário na comunidade
class PublicUserProfile {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int level;
  final int totalXP;
  final List<String> badges;
  final String? bio;
  final PrivacySettings privacySettings;
  final DateTime createdAt;
  final DateTime lastActive;

  const PublicUserProfile({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.level,
    required this.totalXP,
    this.badges = const [],
    this.bio,
    this.privacySettings = const PrivacySettings(),
    required this.createdAt,
    required this.lastActive,
  });

  PublicUserProfile copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    int? level,
    int? totalXP,
    List<String>? badges,
    String? bio,
    PrivacySettings? privacySettings,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return PublicUserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      badges: badges ?? this.badges,
      bio: bio ?? this.bio,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'level': level,
      'totalXP': totalXP,
      'badges': badges,
      'bio': bio,
      'privacySettings': privacySettings.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    return PublicUserProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      level: json['level'] as int,
      totalXP: json['totalXP'] as int,
      badges: List<String>.from(json['badges'] ?? []),
      bio: json['bio'] as String?,
      privacySettings: json['privacySettings'] != null
          ? PrivacySettings.fromJson(json['privacySettings'])
          : const PrivacySettings(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
    );
  }

  /// Cria perfil público a partir de UserStats (gamificação)
  factory PublicUserProfile.fromUserStats({
    required String userId,
    required String displayName,
    String? photoUrl,
    required int level,
    required int totalXP,
    required List<String> badges,
    String? bio,
    PrivacySettings? privacySettings,
  }) {
    final now = DateTime.now();
    return PublicUserProfile(
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      level: level,
      totalXP: totalXP,
      badges: badges,
      bio: bio,
      privacySettings: privacySettings ?? const PrivacySettings(),
      createdAt: now,
      lastActive: now,
    );
  }
}
