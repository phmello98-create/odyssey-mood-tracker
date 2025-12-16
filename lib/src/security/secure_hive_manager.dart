import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Gerenciador de criptografia do Hive para proteção de dados sensíveis
/// Conforme LGPD Art. 46 - Segurança de dados pessoais
class SecureHiveManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  static const _keyName = 'odyssey_hive_encryption_key';
  
  static List<int>? _cachedKey;
  
  /// Boxes que contêm dados sensíveis e devem ser criptografados
  static const sensitiveBoxes = [
    'mood_records',
    'diary_entries', 
    'notes_v2',
    'tasks',
    'habits',
  ];
  
  /// Boxes que não contêm dados sensíveis
  static const nonSensitiveBoxes = [
    'settings',
    'app_state',
    'gamification',
    'quotes',
    'books_v3',
    'time_tracking_records',
  ];
  
  /// Obter ou criar chave de criptografia
  static Future<List<int>> getOrCreateEncryptionKey() async {
    // Usar cache se disponível
    if (_cachedKey != null) {
      return _cachedKey!;
    }
    
    try {
      // Tentar recuperar chave existente
      String? keyString = await _storage.read(key: _keyName);
      
      if (keyString != null && keyString.isNotEmpty) {
        _cachedKey = base64Decode(keyString);
        return _cachedKey!;
      }
      
      // Gerar nova chave segura (256 bits)
      final key = Hive.generateSecureKey();
      await _storage.write(
        key: _keyName,
        value: base64Encode(key),
      );
      
      _cachedKey = key;
      debugPrint('🔐 Nova chave de criptografia gerada');
      return key;
    } catch (e) {
      debugPrint('❌ Erro ao obter chave de criptografia: $e');
      rethrow;
    }
  }
  
  /// Obter cipher para criptografia AES-256
  static Future<HiveAesCipher> getCipher() async {
    final key = await getOrCreateEncryptionKey();
    return HiveAesCipher(key);
  }
  
  /// Abrir box criptografado
  static Future<Box<T>> openEncryptedBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    
    final cipher = await getCipher();
    return await Hive.openBox<T>(
      boxName,
      encryptionCipher: cipher,
    );
  }
  
  /// Abrir box não-criptografado (para dados não-sensíveis)
  static Future<Box<T>> openBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    
    return await Hive.openBox<T>(boxName);
  }
  
  /// Verifica se um box deve ser criptografado
  static bool shouldEncrypt(String boxName) {
    return sensitiveBoxes.contains(boxName);
  }
  
  /// Limpar cache da chave (para logout)
  static void clearKeyCache() {
    _cachedKey = null;
  }
  
  /// Deletar chave de criptografia (para deleção de conta)
  static Future<void> deleteEncryptionKey() async {
    try {
      await _storage.delete(key: _keyName);
      _cachedKey = null;
      debugPrint('🗑️ Chave de criptografia deletada');
    } catch (e) {
      debugPrint('❌ Erro ao deletar chave: $e');
    }
  }
}
