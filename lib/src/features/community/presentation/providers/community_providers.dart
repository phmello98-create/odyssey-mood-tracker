import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/sync_providers.dart';
import '../../data/community_repository.dart';
import '../../data/comment_repository.dart';
import '../../domain/post.dart';
import '../../domain/user_profile.dart';
import '../../domain/comment.dart';

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

/// Stream provider para o feed de posts
final feedProvider = StreamProvider<List<Post>>((ref) {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchFeed(limit: 20);
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

/// State provider para controlar o estado de criação de post
final isCreatingPostProvider = StateProvider<bool>((ref) => false);

/// State provider para o post sendo visualizado
final selectedPostProvider = StateProvider<Post?>((ref) => null);
