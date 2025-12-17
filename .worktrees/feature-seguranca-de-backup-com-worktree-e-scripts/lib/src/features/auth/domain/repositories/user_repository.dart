// lib/src/features/auth/domain/repositories/user_repository.dart

import '../models/odyssey_user.dart';

/// Interface abstrata para o repositório de usuários
/// 
/// Define operações CRUD para gerenciar dados do usuário no Firestore
abstract class UserRepository {
  /// Obtém um usuário pelo ID
  Future<OdysseyUser?> getUser(String uid);
  
  /// Cria ou atualiza um usuário
  Future<void> saveUser(OdysseyUser user);
  
  /// Atualiza campos específicos do usuário
  Future<void> updateUser(String uid, Map<String, dynamic> updates);
  
  /// Deleta um usuário e todos seus dados
  Future<void> deleteUser(String uid);
  
  /// Observa mudanças no usuário em tempo real
  Stream<OdysseyUser?> watchUser(String uid);
  
  /// Verifica se um usuário existe
  Future<bool> userExists(String uid);
  
  /// Atualiza o timestamp da última sincronização
  Future<void> updateLastSyncTimestamp(String uid);
  
  /// Atualiza preferências do usuário
  Future<void> updatePreferences(String uid, Map<String, dynamic> preferences);
  
  /// Atualiza status PRO do usuário
  Future<void> updateProStatus(String uid, {
    required bool isPro,
    DateTime? expiresAt,
  });
  
  /// Adiciona um dispositivo à lista de dispositivos do usuário
  Future<void> addDevice(String uid, String deviceId);
  
  /// Remove um dispositivo da lista
  Future<void> removeDevice(String uid, String deviceId);
}
