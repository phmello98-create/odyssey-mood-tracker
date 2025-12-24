import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/sync_providers.dart';
import '../../data/community_repository.dart';
import '../../data/mock_community_repository.dart';
import '../../data/comment_repository.dart';
import '../../data/follow_repository.dart';
import '../../data/report_repository.dart';
import '../../data/mock_community_data.dart';
import '../../domain/post.dart';
import '../../domain/user_profile.dart';
import '../../domain/comment.dart';
import '../../domain/follow.dart';
import '../../domain/topic.dart';

/// Provider para verificar se está em modo offline (Linux/Windows)
final isOfflineModeProvider = Provider<bool>((ref) {
  // Forçando FALSE para ver os bots reais do Firestore no Linux
  return false;
});

/// Provider para MockCommunityRepository
final mockCommunityRepositoryProvider = Provider<MockCommunityRepository>((
  ref,
) {
  return MockCommunityRepository();
});

/// Provider para CommunityRepository (ou Mock em modo offline)
final communityRepositoryProvider = Provider<CommunityRepository?>((ref) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) {
    return null; // Usa mock repository
  }
  final firestore = ref.watch(firestoreProvider);
  final auth = FirebaseAuth.instance;
  return CommunityRepository(firestore: firestore, auth: auth);
});

/// Provider para CommentRepository
final commentRepositoryProvider = Provider<CommentRepository?>((ref) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) return null;
  final firestore = ref.watch(firestoreProvider);
  final auth = FirebaseAuth.instance;
  return CommentRepository(firestore: firestore, auth: auth);
});

/// Provider para FollowRepository
final followRepositoryProvider = Provider<FollowRepository?>((ref) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) return null;
  final firestore = ref.watch(firestoreProvider);
  final auth = FirebaseAuth.instance;
  return FollowRepository(firestore: firestore, auth: auth);
});

/// Provider para ReportRepository
final reportRepositoryProvider = Provider<ReportRepository?>((ref) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) return null;
  final firestore = ref.watch(firestoreProvider);
  final auth = FirebaseAuth.instance;
  return ReportRepository(firestore: firestore, auth: auth);
});

/// Provider para ID do usuário atual
final currentUserIdProvider = Provider<String?>((ref) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) return 'mock_user_local';
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Provider para tópico selecionado no filtro
final selectedTopicProvider = StateProvider<CommunityTopic?>((ref) => null);

/// Provider para tipo de post selecionado no filtro
final selectedPostTypeProvider = StateProvider<PostType?>((ref) => null);

/// Provider para ordenação do feed
enum FeedSortOrder { recent, popular, trending }

final feedSortOrderProvider = StateProvider<FeedSortOrder>(
  (ref) => FeedSortOrder.recent,
);

/// Provider para tag selecionada no filtro
final selectedTagProvider = StateProvider<String?>((ref) => null);

/// Stream provider para o feed de posts (com filtros e fallback para mock data)
/// Inclui timeout para evitar loading infinito no mobile
final feedProvider = StreamProvider<List<Post>>((ref) {
  final topic = ref.watch(selectedTopicProvider);
  final postType = ref.watch(selectedPostTypeProvider);
  final selectedTag = ref.watch(selectedTagProvider);
  final isOffline = ref.watch(isOfflineModeProvider);

  // Se estiver offline (Linux), usa mock data
  if (isOffline) {
    final mockRepo = ref.watch(mockCommunityRepositoryProvider);
    return mockRepo.watchFeed(limit: 50).map((posts) {
      return _filterPosts(posts, topic, postType, selectedTag);
    });
  }

  try {
    final repo = ref.watch(communityRepositoryProvider);
    if (repo == null) {
      return Stream.value(_getMockPosts(topic, postType, selectedTag));
    }

    // Cria um stream com timeout para evitar loading infinito
    // Se o Firestore não responder em 10 segundos, usa mock data
    return repo
        .watchFeed(limit: 50)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) {
            // Timeout atingido, emite mock data
            sink.add(_getMockPosts(topic, postType, selectedTag));
          },
        )
        .map((posts) {
          // Se recebeu lista vazia do Firestore, usa mock data para UX melhor
          if (posts.isEmpty) {
            return _getMockPosts(topic, postType, selectedTag);
          }
          return _filterPosts(posts, topic, postType, selectedTag);
        })
        .handleError((error, stackTrace) {
          // Se Firebase falhar, retorna mock data
          debugPrint('FeedProvider error: $error');
          return _getMockPosts(topic, postType, selectedTag);
        });
  } catch (e) {
    // Fallback para mock data se Firebase não estiver disponível
    debugPrint('FeedProvider catch: $e');
    return Stream.value(_getMockPosts(topic, postType, selectedTag));
  }
});

/// Helper para filtrar posts
List<Post> _filterPosts(
  List<Post> posts,
  CommunityTopic? topic,
  PostType? postType,
  String? selectedTag,
) {
  var filtered = posts;
  if (topic != null) {
    filtered = filtered
        .where((p) => p.categories.contains(topic.name))
        .toList();
  }
  if (postType != null) {
    filtered = filtered.where((p) => p.type == postType).toList();
  }
  if (selectedTag != null) {
    filtered = filtered
        .where(
          (p) =>
              p.tags.any((t) => t.toLowerCase() == selectedTag.toLowerCase()),
        )
        .toList();
  }
  return filtered;
}

/// Helper para obter posts mock filtrados
List<Post> _getMockPosts(
  CommunityTopic? topic,
  PostType? postType,
  String? tag,
) {
  var posts = topic != null
      ? MockCommunityData.getPostsByTopic(topic)
      : MockCommunityData.getPosts();

  if (postType != null) {
    posts = posts.where((p) => p.type == postType).toList();
  }

  if (tag != null) {
    posts = posts
        .where((p) => p.tags.any((t) => t.toLowerCase() == tag.toLowerCase()))
        .toList();
  }

  return posts;
}

/// Provider para posts de um tópico específico
final topicPostsProvider = StreamProvider.family<List<Post>, CommunityTopic>((
  ref,
  topic,
) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) {
    final mockRepo = ref.watch(mockCommunityRepositoryProvider);
    return mockRepo
        .watchFeed(limit: 50)
        .map(
          (posts) =>
              posts.where((p) => p.categories.contains(topic.name)).toList(),
        );
  }
  final repo = ref.watch(communityRepositoryProvider);
  if (repo == null) {
    return Stream.value(MockCommunityData.getPostsByTopic(topic));
  }
  return repo
      .watchFeed(limit: 50)
      .map(
        (posts) =>
            posts.where((p) => p.categories.contains(topic.name)).toList(),
      );
});

/// Provider para posts do usuário
final userPostsProvider = FutureProvider.family<List<Post>, String>((
  ref,
  userId,
) async {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) {
    final mockRepo = ref.watch(mockCommunityRepositoryProvider);
    final allPosts = await mockRepo.getFeed(limit: 100);
    return allPosts.where((p) => p.userId == userId).toList();
  }
  final repo = ref.watch(communityRepositoryProvider);
  if (repo == null) return [];
  final allPosts = await repo.getFeed(limit: 100);
  return allPosts.where((p) => p.userId == userId).toList();
});

/// Future provider para perfil público de um usuário
final userProfileProvider = FutureProvider.family<PublicUserProfile, String>((
  ref,
  userId,
) async {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) {
    final mockRepo = ref.watch(mockCommunityRepositoryProvider);
    return mockRepo.getProfile(userId);
  }
  final repo = ref.watch(communityRepositoryProvider);
  if (repo == null) {
    return PublicUserProfile(
      userId: userId,
      displayName: 'Usuário',
      level: 1,
      totalXP: 0,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }
  return repo.getProfile(userId);
});

/// Stream provider para comentários de um post
final commentsProvider = StreamProvider.family<List<Comment>, String>((
  ref,
  postId,
) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) {
    // No modo offline, usa comentários mock
    return Stream.value(MockCommunityData.getComments(postId));
  }
  final repo = ref.watch(commentRepositoryProvider);
  if (repo == null) return Stream.value(MockCommunityData.getComments(postId));
  return repo.watchComments(postId);
});

/// Provider para verificar se está seguindo um usuário
final isFollowingProvider = FutureProvider.family<bool, String>((ref, userId) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) return Future.value(false);
  final repo = ref.watch(followRepositoryProvider);
  if (repo == null) return Future.value(false);
  return repo.isFollowing(userId);
});

/// Provider para estatísticas de follow
final followStatsProvider = FutureProvider.family<FollowStats, String>((
  ref,
  userId,
) {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) {
    final mockRepo = ref.watch(mockCommunityRepositoryProvider);
    return mockRepo.getFollowStats(userId);
  }
  final repo = ref.watch(followRepositoryProvider);
  if (repo == null) {
    return Future.value(
      FollowStats(userId: userId, followersCount: 0, followingCount: 0),
    );
  }
  return repo.getFollowStats(userId);
});

/// Provider para busca de posts
final searchPostsProvider = FutureProvider.family<List<Post>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) {
    return MockCommunityData.searchPosts(query);
  }

  try {
    final repo = ref.watch(communityRepositoryProvider);
    if (repo == null) return MockCommunityData.searchPosts(query);
    final allPosts = await repo
        .getFeed(limit: 100)
        .timeout(const Duration(seconds: 5), onTimeout: () => <Post>[]);
    if (allPosts.isEmpty) {
      // Fallback para mock data se Firestore retornou vazio
      return MockCommunityData.searchPosts(query);
    }
    final lowerQuery = query.toLowerCase();
    return allPosts
        .where(
          (p) =>
              p.content.toLowerCase().contains(lowerQuery) ||
              p.userName.toLowerCase().contains(lowerQuery),
        )
        .toList();
  } catch (e) {
    debugPrint('searchPostsProvider error: $e');
    // Fallback para mock data se Firestore falhar
    return MockCommunityData.searchPosts(query);
  }
});

/// Provider para busca de usuários
final searchUsersProvider =
    FutureProvider.family<List<PublicUserProfile>, String>((ref, query) async {
      if (query.trim().isEmpty) return [];
      final isOffline = ref.watch(isOfflineModeProvider);
      if (isOffline) {
        return MockCommunityData.searchUsers(query);
      }
      final repo = ref.watch(communityRepositoryProvider);
      if (repo == null) return MockCommunityData.searchUsers(query);
      return repo.searchUsers(query);
    });

/// State provider para controlar o estado de criação de post
final isCreatingPostProvider = StateProvider<bool>((ref) => false);

/// State provider para o post sendo visualizado
final selectedPostProvider = StateProvider<Post?>((ref) => null);

/// Provider para posts em destaque/trending
final trendingPostsProvider = FutureProvider<List<Post>>((ref) async {
  final isOffline = ref.watch(isOfflineModeProvider);
  if (isOffline) {
    return MockCommunityData.getTrendingPosts(limit: 5);
  }
  final repo = ref.watch(communityRepositoryProvider);
  if (repo == null) {
    return MockCommunityData.getTrendingPosts(limit: 5);
  }
  final posts = await repo.getFeed(limit: 50);
  // Ordena por engajamento (reações + comentários)
  posts.sort(
    (a, b) => (b.totalReactions + b.commentCount).compareTo(
      a.totalReactions + a.commentCount,
    ),
  );
  return posts.take(5).toList();
});
