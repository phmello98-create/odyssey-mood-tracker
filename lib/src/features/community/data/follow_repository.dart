import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/follow.dart';
import '../domain/user_profile.dart';

/// Repository para gerenciar seguidores
class FollowRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FollowRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  /// Referência para seguidores de um usuário
  CollectionReference<Map<String, dynamic>> _followersRef(String userId) =>
      _firestore.collection('users_public').doc(userId).collection('followers');

  /// Referência para quem o usuário segue
  CollectionReference<Map<String, dynamic>> _followingRef(String userId) =>
      _firestore.collection('users_public').doc(userId).collection('following');

  /// Segue um usuário
  Future<void> followUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    if (user.uid == targetUserId) {
      throw Exception('Você não pode seguir a si mesmo');
    }

    try {
      final batch = _firestore.batch();
      final now = Timestamp.now();

      // Adicionar seguidor ao target
      final followerDoc = _followersRef(targetUserId).doc(user.uid);
      batch.set(followerDoc, {
        'followerId': user.uid,
        'followingId': targetUserId,
        'createdAt': now,
      });

      // Adicionar following ao usuário atual
      final followingDoc = _followingRef(user.uid).doc(targetUserId);
      batch.set(followingDoc, {
        'followerId': user.uid,
        'followingId': targetUserId,
        'createdAt': now,
      });

      // Atualizar contadores
      final targetProfileRef = _firestore
          .collection('users_public')
          .doc(targetUserId);
      batch.update(targetProfileRef, {
        'followersCount': FieldValue.increment(1),
      });

      final currentProfileRef = _firestore
          .collection('users_public')
          .doc(user.uid);
      batch.update(currentProfileRef, {
        'followingCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao seguir usuário: $e');
    }
  }

  /// Deixa de seguir um usuário
  Future<void> unfollowUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final batch = _firestore.batch();

      // Remover seguidor do target
      final followerDoc = _followersRef(targetUserId).doc(user.uid);
      batch.delete(followerDoc);

      // Remover following do usuário atual
      final followingDoc = _followingRef(user.uid).doc(targetUserId);
      batch.delete(followingDoc);

      // Atualizar contadores
      final targetProfileRef = _firestore
          .collection('users_public')
          .doc(targetUserId);
      batch.update(targetProfileRef, {
        'followersCount': FieldValue.increment(-1),
      });

      final currentProfileRef = _firestore
          .collection('users_public')
          .doc(user.uid);
      batch.update(currentProfileRef, {
        'followingCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao deixar de seguir usuário: $e');
    }
  }

  /// Verifica se o usuário atual segue outro usuário
  Future<bool> isFollowing(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _followingRef(user.uid).doc(targetUserId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Stream para verificar se está seguindo em tempo real
  Stream<bool> watchIsFollowing(String targetUserId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _followingRef(
      user.uid,
    ).doc(targetUserId).snapshots().map((doc) => doc.exists);
  }

  /// Busca seguidores de um usuário
  Future<List<PublicUserProfile>> getFollowers(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _followersRef(
        userId,
      ).orderBy('createdAt', descending: true).limit(limit).get();

      final profiles = <PublicUserProfile>[];
      for (final doc in snapshot.docs) {
        final followerId = doc.data()['followerId'] as String;
        final profileDoc = await _firestore
            .collection('users_public')
            .doc(followerId)
            .get();
        if (profileDoc.exists) {
          profiles.add(
            PublicUserProfile.fromJson({
              ...profileDoc.data()!,
              'userId': profileDoc.id,
            }),
          );
        }
      }
      return profiles;
    } catch (e) {
      throw Exception('Erro ao buscar seguidores: $e');
    }
  }

  /// Busca quem o usuário segue
  Future<List<PublicUserProfile>> getFollowing(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _followingRef(
        userId,
      ).orderBy('createdAt', descending: true).limit(limit).get();

      final profiles = <PublicUserProfile>[];
      for (final doc in snapshot.docs) {
        final followingId = doc.data()['followingId'] as String;
        final profileDoc = await _firestore
            .collection('users_public')
            .doc(followingId)
            .get();
        if (profileDoc.exists) {
          profiles.add(
            PublicUserProfile.fromJson({
              ...profileDoc.data()!,
              'userId': profileDoc.id,
            }),
          );
        }
      }
      return profiles;
    } catch (e) {
      throw Exception('Erro ao buscar seguindo: $e');
    }
  }

  /// Busca estatísticas de seguidores
  Future<FollowStats> getFollowStats(String userId) async {
    try {
      final profileDoc = await _firestore
          .collection('users_public')
          .doc(userId)
          .get();
      if (!profileDoc.exists) {
        return FollowStats(userId: userId);
      }

      final data = profileDoc.data()!;
      return FollowStats(
        userId: userId,
        followersCount: data['followersCount'] as int? ?? 0,
        followingCount: data['followingCount'] as int? ?? 0,
      );
    } catch (e) {
      return FollowStats(userId: userId);
    }
  }

  /// Stream para estatísticas de seguidores em tempo real
  Stream<FollowStats> watchFollowStats(String userId) {
    return _firestore.collection('users_public').doc(userId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return FollowStats(userId: userId);
      }
      final data = doc.data()!;
      return FollowStats(
        userId: userId,
        followersCount: data['followersCount'] as int? ?? 0,
        followingCount: data['followingCount'] as int? ?? 0,
      );
    });
  }
}
