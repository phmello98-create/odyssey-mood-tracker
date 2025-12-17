/// Tipos de posts na comunidade
enum PostType { text, achievement, insight, mood }

/// Model de Post para a comunidade
class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int userLevel;
  final String content;
  final PostType type;
  final Map<String, dynamic>? metadata;
  final Map<String, int> reactions;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> categories;

  const Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.userLevel,
    required this.content,
    required this.type,
    this.metadata,
    this.reactions = const {},
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.categories = const [],
  });

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    int? userLevel,
    String? content,
    PostType? type,
    Map<String, dynamic>? metadata,
    Map<String, int>? reactions,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? categories,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userLevel: userLevel ?? this.userLevel,
      content: content ?? this.content,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'userLevel': userLevel,
      'content': content,
      'type': type.name,
      'metadata': metadata,
      'reactions': reactions,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'categories': categories,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      userLevel: json['userLevel'] as int,
      content: json['content'] as String,
      type: PostType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PostType.text,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      reactions: Map<String, int>.from(json['reactions'] ?? {}),
      commentCount: json['commentCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  /// Verifica se o usuário atual reagiu ao post
  bool hasUserReacted(String userId, String emoji) {
    return reactions.containsKey('$userId:$emoji');
  }

  /// Total de reações
  int get totalReactions {
    return reactions.values.fold(0, (sum, count) => sum + count);
  }
}
