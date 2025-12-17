import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/comment.dart';

/// Repository para gerenciar comentários
class CommentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommentRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  /// Referência para comentários de um post
  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) =>
      _firestore.collection('posts').doc(postId).collection('comments');

  /// Busca todos os comentários de um post
  Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _commentsRef(
        postId,
      ).orderBy('createdAt', descending: false).get();

      return snapshot.docs
          .map((doc) => Comment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar comentários: $e');
    }
  }

  /// Stream de comentários de um post
  Stream<List<Comment>> watchComments(String postId) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Comment.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Adiciona um comentário a um post
  Future<Comment> addComment(
    String postId,
    String content, {
    String? parentCommentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Buscar perfil público do usuário
      final profileDoc = await _firestore
          .collection('users_public')
          .doc(user.uid)
          .get();

      final userName = profileDoc.data()?['displayName'] ?? 'Usuário';
      final userPhotoUrl = profileDoc.data()?['photoUrl'] as String?;

      final now = DateTime.now();
      final commentData = {
        'postId': postId,
        'userId': user.uid,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'createdAt': Timestamp.fromDate(now),
        'parentCommentId': parentCommentId,
      };

      final docRef = await _commentsRef(postId).add(commentData);

      // Incrementar contador de comentários no post
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return Comment.fromJson({...commentData, 'id': docRef.id});
    } catch (e) {
      throw Exception('Erro ao adicionar comentário: $e');
    }
  }

  /// Deleta um comentário
  Future<void> deleteComment(String postId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final commentDoc = await _commentsRef(postId).doc(commentId).get();
      if (!commentDoc.exists) {
        throw Exception('Comentário não encontrado');
      }

      final commentData = commentDoc.data()!;
      if (commentData['userId'] != user.uid) {
        throw Exception('Sem permissão para deletar este comentário');
      }

      await _commentsRef(postId).doc(commentId).delete();

      // Decrementar contador de comentários no post
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Erro ao deletar comentário: $e');
    }
  }

  /// Busca respostas de um comentário específico
  Future<List<Comment>> getReplies(
    String postId,
    String parentCommentId,
  ) async {
    try {
      final snapshot = await _commentsRef(postId)
          .where('parentCommentId', isEqualTo: parentCommentId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Comment.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar respostas: $e');
    }
  }
}
