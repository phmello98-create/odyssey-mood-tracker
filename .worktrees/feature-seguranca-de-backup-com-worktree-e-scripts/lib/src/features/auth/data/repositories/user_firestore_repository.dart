// lib/src/features/auth/data/repositories/user_firestore_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/odyssey_user.dart';
import '../../domain/models/account_type.dart';
import '../../domain/repositories/user_repository.dart';

/// Implementação do UserRepository usando Firestore
class UserFirestoreRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  
  UserFirestoreRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Referência para a coleção de usuários
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');
  
  /// Referência para um documento de usuário específico
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  @override
  Future<OdysseyUser?> getUser(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      return _fromFirestore(doc.data()!, uid);
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error getting user: $e');
      return null;
    }
  }

  @override
  Future<void> saveUser(OdysseyUser user) async {
    try {
      final data = _toFirestore(user);
      await _userDoc(user.uid).set(data, SetOptions(merge: true));
      debugPrint('[UserFirestoreRepository] User saved: ${user.uid}');
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error saving user: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      // Adiciona timestamp de atualização
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _userDoc(uid).update(updates);
      debugPrint('[UserFirestoreRepository] User updated: $uid');
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error updating user: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      // Primeiro, deletar todas as subcoleções
      await _deleteSubcollections(uid);
      
      // Depois, deletar o documento do usuário
      await _userDoc(uid).delete();
      debugPrint('[UserFirestoreRepository] User deleted: $uid');
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error deleting user: $e');
      rethrow;
    }
  }
  
  /// Deleta todas as subcoleções do usuário
  Future<void> _deleteSubcollections(String uid) async {
    final collections = ['moods', 'tasks', 'habits', 'notes', 'quotes'];
    
    for (final collectionName in collections) {
      final snapshot = await _userDoc(uid).collection(collectionName).get();
      
      if (snapshot.docs.isEmpty) continue;
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  @override
  Stream<OdysseyUser?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return _fromFirestore(snapshot.data()!, uid);
    });
  }

  @override
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error checking user existence: $e');
      return false;
    }
  }

  @override
  Future<void> updateLastSyncTimestamp(String uid) async {
    try {
      await _userDoc(uid).update({
        'lastSyncAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error updating last sync: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePreferences(String uid, Map<String, dynamic> preferences) async {
    try {
      await _userDoc(uid).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error updating preferences: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProStatus(String uid, {
    required bool isPro,
    DateTime? expiresAt,
  }) async {
    try {
      final updates = <String, dynamic>{
        'isPro': isPro,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (isPro) {
        updates['accountType'] = expiresAt == null 
            ? AccountType.proLifetime.name 
            : AccountType.pro.name;
        if (expiresAt != null) {
          updates['proExpiresAt'] = Timestamp.fromDate(expiresAt);
        }
      } else {
        updates['accountType'] = AccountType.free.name;
        updates['proExpiresAt'] = null;
      }
      
      await _userDoc(uid).update(updates);
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error updating pro status: $e');
      rethrow;
    }
  }

  @override
  Future<void> addDevice(String uid, String deviceId) async {
    try {
      await _userDoc(uid).update({
        'devices': FieldValue.arrayUnion([deviceId]),
        'currentDeviceId': deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error adding device: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeDevice(String uid, String deviceId) async {
    try {
      await _userDoc(uid).update({
        'devices': FieldValue.arrayRemove([deviceId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[UserFirestoreRepository] Error removing device: $e');
      rethrow;
    }
  }
  
  // ===========================================
  // CONVERSÕES FIRESTORE <-> MODELO
  // ===========================================
  
  /// Converte dados do Firestore para OdysseyUser
  OdysseyUser _fromFirestore(Map<String, dynamic> data, String uid) {
    // Parse AccountType
    AccountType accountType = AccountType.free;
    if (data['accountType'] != null) {
      try {
        accountType = AccountType.values.firstWhere(
          (e) => e.name == data['accountType'],
          orElse: () => AccountType.free,
        );
      } catch (_) {
        accountType = AccountType.free;
      }
    }
    
    // Parse DateTime fields
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
      }
    }
    
    DateTime? lastSyncAt;
    if (data['lastSyncAt'] != null) {
      if (data['lastSyncAt'] is Timestamp) {
        lastSyncAt = (data['lastSyncAt'] as Timestamp).toDate();
      } else if (data['lastSyncAt'] is String) {
        lastSyncAt = DateTime.tryParse(data['lastSyncAt']);
      }
    }
    
    DateTime? proExpiresAt;
    if (data['proExpiresAt'] != null) {
      if (data['proExpiresAt'] is Timestamp) {
        proExpiresAt = (data['proExpiresAt'] as Timestamp).toDate();
      } else if (data['proExpiresAt'] is String) {
        proExpiresAt = DateTime.tryParse(data['proExpiresAt']);
      }
    }
    
    return OdysseyUser(
      uid: uid,
      displayName: data['displayName'] ?? 'Usuário',
      email: data['email'],
      photoURL: data['photoURL'],
      isGuest: data['isGuest'] ?? false,
      isPro: data['isPro'] ?? false,
      accountType: accountType,
      proExpiresAt: proExpiresAt,
      createdAt: createdAt,
      lastSyncAt: lastSyncAt,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      syncEnabled: data['syncEnabled'] ?? true,
      currentDeviceId: data['currentDeviceId'],
      devices: List<String>.from(data['devices'] ?? []),
      emailVerified: data['emailVerified'] ?? false,
      authProvider: data['authProvider'] ?? 'email',
    );
  }
  
  /// Converte OdysseyUser para dados do Firestore
  Map<String, dynamic> _toFirestore(OdysseyUser user) {
    return {
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'isGuest': user.isGuest,
      'isPro': user.isPro,
      'accountType': user.accountType.name,
      'proExpiresAt': user.proExpiresAt != null 
          ? Timestamp.fromDate(user.proExpiresAt!) 
          : null,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'lastSyncAt': user.lastSyncAt != null 
          ? Timestamp.fromDate(user.lastSyncAt!) 
          : null,
      'preferences': user.preferences,
      'syncEnabled': user.syncEnabled,
      'currentDeviceId': user.currentDeviceId,
      'devices': user.devices,
      'emailVerified': user.emailVerified,
      'authProvider': user.authProvider,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
