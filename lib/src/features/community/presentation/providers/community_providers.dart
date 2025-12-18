import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/sync_providers.dart';
import '../../data/community_repository.dart';
import '../../data/comment_repository.dart';
import '../../data/follow_repository.dart';
import '../../data/report_repository.dart';
import '../../data/mock_community_data.dart';
import '../../domain/post.dart';
import '../../domain/user_profile.dart';
import '../../domain/comment.dart';
import '../../domain/follow.dart';
import '../../domain/topic.dart';

/// Provider para CommunityRepository
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = FirebaseAuth.instance;
  return CommunityRepository(firestore: firestore, auth: auth);
});

/// Provider para CommentRepository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = FirebaseAuth.instance;
  return CommentRepository(firestore: firestore, auth: auth);
});

/// Provider para FollowRepository
final followRepositoryProvider = Provider<FollowRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = FirebaseAuth.instance;
  return FollowRepository(firestore: firestore, auth: auth);
});

/// Provider para ReportRepository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = FirebaseAuth.instance;
  return ReportRepository(firestore: firestore, auth: auth);
});

/// Provider para ID do usuário atual
final currentUserIdProvider = Provider<String?>((ref) {
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
final feedProvider = StreamProvider<List<Post>>((ref) {
  final topic = ref.watch(selectedTopicProvider);
  final postType = ref.watch(selectedPostTypeProvider);
  final selectedTag = ref.watch(selectedTagProvider);

  try {
    final repo = ref.watch(communityRepositoryProvider);
    return repo
        .watchFeed(limit: 50)
        .map((posts) {
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
                  (p) => p.tags.any(
                    (t) => t.toLowerCase() == selectedTag.toLowerCase(),
                  ),
                )
                .toList();
          }
          return filtered;
        })
        .handleError((error) {
          // Se Firebase falhar, usa mock data
          return Stream.value(_getMockPosts(topic, postType, selectedTag));
        });
  } catch (e) {
    // Fallback para mock data se Firebase não estiver disponível
    return Stream.value(_getMockPosts(topic, postType, selectedTag));
  }
});

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
  final repo = ref.watch(communityRepositoryProvider);
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
  final repo = ref.watch(communityRepositoryProvider);
  final allPosts = await repo.getFeed(limit: 100);
  return allPosts.where((p) => p.userId == userId).toList();
});

/// Future provider para perfil público de um usuário
final userProfileProvider = FutureProvider.family<PublicUserProfile, String>((
  ref,
  userId,
) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getProfile(userId);
});

/// Stream provider para comentários de um post
final commentsProvider = StreamProvider.family<List<Comment>, String>((
  ref,
  postId,
) {
  final repo = ref.watch(commentRepositoryProvider);
  return repo.watchComments(postId);
});

/// Provider para verificar se está seguindo um usuário
final isFollowingProvider = FutureProvider.family<bool, String>((ref, userId) {
  final repo = ref.watch(followRepositoryProvider);
  return repo.isFollowing(userId);
});

/// Provider para estatísticas de follow
final followStatsProvider = FutureProvider.family<FollowStats, String>((
  ref,
  userId,
) {
  final repo = ref.watch(followRepositoryProvider);
  return repo.getFollowStats(userId);
});

/// Provider para busca de posts
final searchPostsProvider = FutureProvider.family<List<Post>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(communityRepositoryProvider);
  final allPosts = await repo.getFeed(limit: 100);
  final lowerQuery = query.toLowerCase();
  return allPosts
      .where(
        (p) =>
            p.content.toLowerCase().contains(lowerQuery) ||
            p.userName.toLowerCase().contains(lowerQuery),
      )
      .toList();
});

/// Provider para busca de usuários
final searchUsersProvider =
    FutureProvider.family<List<PublicUserProfile>, String>((ref, query) async {
      if (query.trim().isEmpty) return [];
      final repo = ref.watch(communityRepositoryProvider);
      // Por enquanto busca local - idealmente seria uma query no Firestore
      return repo.searchUsers(query);
    });

/// State provider para controlar o estado de criação de post
final isCreatingPostProvider = StateProvider<bool>((ref) => false);

/// State provider para o post sendo visualizado
final selectedPostProvider = StateProvider<Post?>((ref) => null);

/// Provider para posts em destaque/trending
final trendingPostsProvider = FutureProvider<List<Post>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  final posts = await repo.getFeed(limit: 50);
  // Ordena por engajamento (reações + comentários)
  posts.sort(
    (a, b) => (b.totalReactions + b.commentCount).compareTo(
      a.totalReactions + a.commentCount,
    ),
  );
  return posts.take(5).toList();
});
