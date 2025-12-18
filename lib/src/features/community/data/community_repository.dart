import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/post.dart';
import '../domain/post_dto.dart';
import '../domain/user_profile.dart';

/// Repository para gerenciar posts da comunidade
class CommunityRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommunityRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  /// Referência para a collection de posts
  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection('posts');

  /// Referência para a collection de perfis públicos
  CollectionReference<Map<String, dynamic>> get _profilesRef =>
      _firestore.collection('users_public');

  /// Busca o feed de posts com paginação
  Future<List<Post>> getFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _postsRef
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar feed: $e');
    }
  }

  /// Stream do feed de posts
  Stream<List<Post>> watchFeed({int limit = 20}) {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Cria um novo post
  Future<Post> createPost(CreatePostDto dto) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Buscar perfil público do usuário
      final profile = await getProfile(user.uid);

      final now = DateTime.now();
      final postData = {
        'userId': user.uid,
        'userName': profile.displayName,
        'userPhotoUrl': profile.photoUrl,
        'userLevel': profile.level,
        'content': dto.content,
        'type': dto.type.name,
        'metadata': dto.metadata,
        'reactions': {},
        'commentCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'categories': dto.categories,
      };

      final docRef = await _postsRef.add(postData);
      return Post.fromJson({...postData, 'id': docRef.id});
    } catch (e) {
      throw Exception('Erro ao criar post: $e');
    }
  }

  /// Busca um post específico
  Future<Post?> getPost(String postId) async {
    try {
      final doc = await _postsRef.doc(postId).get();
      if (!doc.exists) return null;
      return Post.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Erro ao buscar post: $e');
    }
  }

  /// Atualiza um post
  Future<void> updatePost(String postId, UpdatePostDto dto) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final post = await getPost(postId);
      if (post == null) {
        throw Exception('Post não encontrado');
      }

      if (post.userId != user.uid) {
        throw Exception('Sem permissão para editar este post');
      }

      final updateData = {
        ...dto.toJson(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _postsRef.doc(postId).update(updateData);
    } catch (e) {
      throw Exception('Erro ao atualizar post: $e');
    }
  }

  /// Deleta um post
  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final post = await getPost(postId);
      if (post == null) {
        throw Exception('Post não encontrado');
      }

      if (post.userId != user.uid) {
        throw Exception('Sem permissão para deletar este post');
      }

      await _postsRef.doc(postId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar post: $e');
    }
  }

  /// Adiciona uma reação a um post
  Future<void> addReaction(String postId, String emoji) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final reactionRef = _postsRef
          .doc(postId)
          .collection('reactions')
          .doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final reactionDoc = await transaction.get(reactionRef);

        if (reactionDoc.exists) {
          // Já reagiu, atualizar emoji
          transaction.update(reactionRef, {
            'emoji': emoji,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });
        } else {
          // Nova reação
          transaction.set(reactionRef, {
            'emoji': emoji,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });
        }

        // Atualizar contador de reações no post
        final postRef = _postsRef.doc(postId);
        final postDoc = await transaction.get(postRef);
        if (postDoc.exists) {
          final reactions = Map<String, int>.from(
            postDoc.data()?['reactions'] ?? {},
          );
          reactions[emoji] = (reactions[emoji] ?? 0) + 1;
          transaction.update(postRef, {'reactions': reactions});
        }
      });
    } catch (e) {
      throw Exception('Erro ao adicionar reação: $e');
    }
  }

  /// Remove a reação do usuário de um post
  Future<void> removeReaction(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final reactionRef = _postsRef
          .doc(postId)
          .collection('reactions')
          .doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final reactionDoc = await transaction.get(reactionRef);

        if (reactionDoc.exists) {
          final emoji = reactionDoc.data()?['emoji'] as String;
          transaction.delete(reactionRef);

          // Atualizar contador de reações no post
          final postRef = _postsRef.doc(postId);
          final postDoc = await transaction.get(postRef);
          if (postDoc.exists) {
            final reactions = Map<String, int>.from(
              postDoc.data()?['reactions'] ?? {},
            );
            if (reactions.containsKey(emoji)) {
              reactions[emoji] = (reactions[emoji]! - 1)
                  .clamp(0, double.infinity)
                  .toInt();
              if (reactions[emoji] == 0) {
                reactions.remove(emoji);
              }
            }
            transaction.update(postRef, {'reactions': reactions});
          }
        }
      });
    } catch (e) {
      throw Exception('Erro ao remover reação: $e');
    }
  }

  /// Busca perfil público de um usuário
  Future<PublicUserProfile> getProfile(String userId) async {
    try {
      final doc = await _profilesRef.doc(userId).get();
      if (!doc.exists) {
        // Criar perfil padrão se não existir
        final defaultProfile = PublicUserProfile(
          userId: userId,
          displayName: 'Usuário',
          level: 1,
          totalXP: 0,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
        await _profilesRef.doc(userId).set(defaultProfile.toJson());
        return defaultProfile;
      }
      return PublicUserProfile.fromJson({...doc.data()!, 'userId': doc.id});
    } catch (e) {
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  /// Atualiza perfil público do usuário
  Future<void> updateProfile(PublicUserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    if (profile.userId != user.uid) {
      throw Exception('Sem permissão para editar este perfil');
    }

    try {
      await _profilesRef.doc(user.uid).set(profile.toJson());
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: $e');
    }
  }

  /// Sincroniza perfil público com dados de gamificação
  Future<void> syncProfileFromGameStats({
    required String displayName,
    String? photoUrl,
    required int level,
    required int totalXP,
    required List<String> badges,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final existingProfile = await getProfile(user.uid);
      final updatedProfile = existingProfile.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        level: level,
        totalXP: totalXP,
        badges: badges,
        lastActive: DateTime.now(),
      );
      await updateProfile(updatedProfile);
    } catch (e) {
      throw Exception('Erro ao sincronizar perfil: $e');
    }
  }

  /// Busca usuários por nome
  Future<List<PublicUserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      // Busca case-insensitive usando query range
      final lowerQuery = query.toLowerCase();
      final snapshot = await _profilesRef
          .orderBy('displayName')
          .limit(20)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                PublicUserProfile.fromJson({...doc.data(), 'userId': doc.id}),
          )
          .where(
            (profile) => profile.displayName.toLowerCase().contains(lowerQuery),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }
}
