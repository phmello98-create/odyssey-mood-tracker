import 'dart:io';
import '../domain/post.dart';
import '../domain/post_dto.dart';
import '../domain/user_profile.dart';
import '../domain/follow.dart';
import 'mock_community_data.dart';

/// Mock Repository para desenvolvimento offline (Linux, etc.)
/// Usa dados em memória para simular o comportamento do Firebase
class MockCommunityRepository {
  // Posts criados pelo usuário (em memória)
  static final List<Post> _userCreatedPosts = [];

  // ID do usuário mock
  static const String _mockUserId = 'mock_user_local';

  /// Retorna o ID do usuário mock
  String get currentUserId => _mockUserId;

  /// Busca o feed de posts
  Future<List<Post>> getFeed({int limit = 20}) async {
    // Combina posts criados localmente + posts mock
    final allPosts = [
      ..._userCreatedPosts,
      ...MockCommunityData.getPosts(limit: limit),
    ];
    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allPosts.take(limit).toList();
  }

  /// Stream do feed de posts
  Stream<List<Post>> watchFeed({int limit = 20}) async* {
    // Emite imediatamente
    yield await getFeed(limit: limit);

    // Depois atualiza periodicamente a cada 5 segundos
    yield* Stream.periodic(const Duration(seconds: 5), (_) async {
      return await getFeed(limit: limit);
    }).asyncMap((future) => future);
  }

  /// Cria um novo post
  Future<Post> createPost(CreatePostDto dto) async {
    // Simula delay de rede
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    // Usa os caminhos das imagens locais como URLs (file:// para exibição local)
    final imageUrls = dto.localImagePaths
        .map((path) => 'file://$path')
        .toList();

    // Define o tipo baseado nas imagens
    PostType postType = dto.type;
    if (imageUrls.isNotEmpty && postType == PostType.text) {
      postType = imageUrls.length > 1 ? PostType.gallery : PostType.image;
    }

    final newPost = Post(
      id: 'local_post_${now.millisecondsSinceEpoch}',
      userId: _mockUserId,
      userName: 'Você',
      userPhotoUrl: null,
      userLevel: 5,
      content: dto.content,
      type: postType,
      imageUrls: imageUrls,
      tags: [],
      upvotes: 0,
      downvotes: 0,
      viewCount: 0,
      commentCount: 0,
      authorKarma: 100,
      createdAt: now,
      updatedAt: now,
      categories: dto.categories,
      metadata: dto.metadata,
    );

    _userCreatedPosts.insert(0, newPost);
    return newPost;
  }

  /// Busca um post específico
  Future<Post?> getPost(String postId) async {
    // Primeiro verifica posts locais
    try {
      return _userCreatedPosts.firstWhere((p) => p.id == postId);
    } catch (_) {
      // Se não encontrar, busca nos mocks
      return MockCommunityData.getPost(postId);
    }
  }

  /// Atualiza um post (apenas locais)
  Future<void> updatePost(String postId, UpdatePostDto dto) async {
    final index = _userCreatedPosts.indexWhere((p) => p.id == postId);
    if (index >= 0) {
      final post = _userCreatedPosts[index];
      _userCreatedPosts[index] = post.copyWith(
        content: dto.content ?? post.content,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Deleta um post (apenas locais)
  Future<void> deletePost(String postId) async {
    _userCreatedPosts.removeWhere((p) => p.id == postId);
  }

  /// Adiciona uma reação a um post
  Future<void> addReaction(String postId, String emoji) async {
    // Simula a reação (apenas UX, não persiste)
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Remove a reação do usuário de um post
  Future<void> removeReaction(String postId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Busca perfil público de um usuário
  Future<PublicUserProfile> getProfile(String userId) async {
    // Primeiro verifica se é o usuário local
    if (userId == _mockUserId) {
      return PublicUserProfile(
        userId: _mockUserId,
        displayName: 'Você',
        level: 5,
        totalXP: 500,
        badges: ['newcomer'],
        bio: 'Meu perfil local',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        lastActive: DateTime.now(),
      );
    }

    // Busca nos mocks
    final mockProfile = MockCommunityData.getUserProfile(userId);
    if (mockProfile != null) {
      return mockProfile;
    }

    // Retorna perfil padrão
    return PublicUserProfile(
      userId: userId,
      displayName: 'Usuário',
      level: 1,
      totalXP: 0,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  /// Atualiza perfil público do usuário
  Future<void> updateProfile(PublicUserProfile profile) async {
    // Apenas simula
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Sincroniza perfil público com dados de gamificação
  Future<void> syncProfileFromGameStats({
    required String displayName,
    String? photoUrl,
    required int level,
    required int totalXP,
    required List<String> badges,
  }) async {
    // Apenas simula
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Busca usuários por nome
  Future<List<PublicUserProfile>> searchUsers(String query) async {
    return MockCommunityData.searchUsers(query);
  }

  /// Busca estatísticas de seguidores
  Future<FollowStats> getFollowStats(String userId) async {
    return MockCommunityData.getFollowStats(userId);
  }

  /// Verifica se estamos em modo offline (Linux)
  static bool get isOfflineMode {
    return Platform.isLinux || Platform.isWindows;
  }
}
