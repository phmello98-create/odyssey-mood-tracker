/// Tipos de posts na comunidade
enum PostType { text, achievement, insight, mood, image, gallery }

/// Model de Post para a comunidade (Estilo Reddit)
class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int userLevel;
  final String content;
  final PostType type;
  final Map<String, dynamic>? metadata;

  // Sistema de votos (Reddit-style)
  final int upvotes;
  final int downvotes;
  final List<String> upvotedBy; // IDs dos usuários que deram upvote
  final List<String> downvotedBy; // IDs dos usuários que deram downvote

  // Legado (para compatibilidade)
  final Map<String, int> reactions;
  final int commentCount;

  // Novos campos
  final List<String> imageUrls; // URLs das imagens
  final List<String> tags; // Hashtags
  final int viewCount; // Visualizações

  // Autor info enriquecido
  final int authorKarma; // Karma do autor
  final String? authorFlair; // Título do autor
  final String? authorBadge; // Badge principal do autor

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
    this.upvotes = 0,
    this.downvotes = 0,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
    this.reactions = const {},
    this.commentCount = 0,
    this.imageUrls = const [],
    this.tags = const [],
    this.viewCount = 0,
    this.authorKarma = 0,
    this.authorFlair,
    this.authorBadge,
    required this.createdAt,
    required this.updatedAt,
    this.categories = const [],
  });

  /// Score do post (upvotes - downvotes)
  int get score => upvotes - downvotes;

  /// Total de reações (legado + votos)
  int get totalReactions =>
      reactions.values.fold(0, (sum, count) => sum + count);

  /// Total de engajamento
  int get engagement => score + commentCount + (viewCount ~/ 10);

  /// Verifica se usuário deu upvote
  bool hasUpvoted(String userId) => upvotedBy.contains(userId);

  /// Verifica se usuário deu downvote
  bool hasDownvoted(String userId) => downvotedBy.contains(userId);

  /// Tem imagens?
  bool get hasImages => imageUrls.isNotEmpty;

  /// É galeria?
  bool get isGallery => imageUrls.length > 1;

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    int? userLevel,
    String? content,
    PostType? type,
    Map<String, dynamic>? metadata,
    int? upvotes,
    int? downvotes,
    List<String>? upvotedBy,
    List<String>? downvotedBy,
    Map<String, int>? reactions,
    int? commentCount,
    List<String>? imageUrls,
    List<String>? tags,
    int? viewCount,
    int? authorKarma,
    String? authorFlair,
    String? authorBadge,
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
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      downvotedBy: downvotedBy ?? this.downvotedBy,
      reactions: reactions ?? this.reactions,
      commentCount: commentCount ?? this.commentCount,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      authorKarma: authorKarma ?? this.authorKarma,
      authorFlair: authorFlair ?? this.authorFlair,
      authorBadge: authorBadge ?? this.authorBadge,
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
      'upvotes': upvotes,
      'downvotes': downvotes,
      'upvotedBy': upvotedBy,
      'downvotedBy': downvotedBy,
      'reactions': reactions,
      'commentCount': commentCount,
      'imageUrls': imageUrls,
      'tags': tags,
      'viewCount': viewCount,
      'authorKarma': authorKarma,
      'authorFlair': authorFlair,
      'authorBadge': authorBadge,
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
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      upvotedBy: List<String>.from(json['upvotedBy'] ?? []),
      downvotedBy: List<String>.from(json['downvotedBy'] ?? []),
      reactions: Map<String, int>.from(json['reactions'] ?? {}),
      commentCount: json['commentCount'] as int? ?? 0,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: json['viewCount'] as int? ?? 0,
      authorKarma: json['authorKarma'] as int? ?? 0,
      authorFlair: json['authorFlair'] as String?,
      authorBadge: json['authorBadge'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  /// Verifica se o usuário atual reagiu ao post (legado)
  bool hasUserReacted(String userId, String emoji) {
    return reactions.containsKey('$userId:$emoji');
  }
}
