import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Serviço de backup criptografado com AES-256-CBC
/// Usa PBKDF2 para derivação de chave a partir de senha
class EncryptedBackupService {
  static const _iterations = 100000;
  static const _keyLength = 32; // 256 bits
  
  /// Derivar chave de criptografia da senha usando PBKDF2
  static List<int> _deriveKey(String password, List<int> salt) {
    var hmac = Hmac(sha256, utf8.encode(password));
    var key = <int>[];
    
    for (var i = 1; key.length < _keyLength; i++) {
      var block = hmac.convert([
        ...salt,
        ...[(i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff]
      ]).bytes;
      var u = List<int>.from(block);
      
      for (var j = 1; j < _iterations; j++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < block.length; k++) {
          block[k] ^= u[k];
        }
      }
      
      key.addAll(block);
    }
    
    return key.sublist(0, _keyLength);
  }
  
  /// Validar força da senha
  static PasswordStrength validatePassword(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }
    
    int strength = 0;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    
    if (strength >= 4) return PasswordStrength.strong;
    if (strength >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }
  
  /// Criar backup criptografado
  static Future<Map<String, dynamic>> createEncryptedBackup({
    required Map<String, dynamic> backupData,
    required String password,
  }) async {
    try {
      // 1. Validar senha
      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }
      
      // 2. Converter dados para JSON
      final backupJson = jsonEncode(backupData);
      
      // 3. Gerar salt aleatório (16 bytes)
      final salt = encrypt.SecureRandom(16).bytes;
      
      // 4. Derivar chave da senha
      final keyBytes = _deriveKey(password, salt);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      
      // 5. Gerar IV aleatório (16 bytes)
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // 6. Criptografar com AES-256-CBC
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc)
      );
      final encrypted = encrypter.encrypt(backupJson, iv: iv);
      
      // 7. Calcular checksum do JSON original (para validação)
      final checksum = md5.convert(utf8.encode(backupJson)).toString();
      
      // 8. Retornar backup criptografado com metadados
      return {
        'version': 3,
        'encrypted': true,
        'algorithm': 'AES-256-CBC',
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': _iterations,
        'salt': base64Encode(salt),
        'iv': base64Encode(iv.bytes),
        'data': encrypted.base64,
        'checksum': checksum,
        'timestamp': DateTime.now().toIso8601String(),
        'app': 'Odyssey',
        'app_version': '1.0.0',
      };
    } catch (e) {
      debugPrint('❌ Erro ao criar backup criptografado: $e');
      rethrow;
    }
  }
  
  /// Descriptografar backup
  static Future<Map<String, dynamic>> decryptBackup({
    required Map<String, dynamic> encryptedBackup,
    required String password,
  }) async {
    try {
      // 1. Validar formato
      if (encryptedBackup['encrypted'] != true) {
        throw Exception('Backup is not encrypted');
      }
      
      // 2. Extrair metadados
      final salt = base64Decode(encryptedBackup['salt'] as String);
      final iv = encrypt.IV(Uint8List.fromList(
        base64Decode(encryptedBackup['iv'] as String)
      ));
      final encryptedData = encryptedBackup['data'] as String;
      final storedChecksum = encryptedBackup['checksum'] as String?;
      
      // 3. Derivar chave da senha
      final keyBytes = _deriveKey(password, salt);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      
      // 4. Descriptografar
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc)
      );
      
      final decrypted = encrypter.decrypt64(
        encryptedData,
        iv: iv,
      );
      
      // 5. Validar checksum se disponível
      if (storedChecksum != null) {
        final computedChecksum = md5.convert(utf8.encode(decrypted)).toString();
        
        if (computedChecksum != storedChecksum) {
          throw Exception('Backup corrupted: checksum mismatch');
        }
      }
      
      // 6. Parsear JSON
      final backupData = jsonDecode(decrypted) as Map<String, dynamic>;
      
      debugPrint('✅ Backup descriptografado com sucesso');
      return backupData;
      
    } catch (e) {
      if (e.toString().contains('padding') || e.toString().contains('Padding')) {
        throw Exception('Wrong password');
      }
      debugPrint('❌ Erro ao descriptografar: $e');
      rethrow;
    }
  }
  
  /// Verificar se um backup está criptografado
  static bool isEncrypted(Map<String, dynamic> backup) {
    return backup['encrypted'] == true;
  }
  
  /// Obter informações do backup sem descriptografar
  static BackupInfo getBackupInfo(Map<String, dynamic> backup) {
    return BackupInfo(
      version: backup['version'] as int? ?? 1,
      isEncrypted: backup['encrypted'] == true,
      algorithm: backup['algorithm'] as String?,
      timestamp: backup['timestamp'] != null 
          ? DateTime.tryParse(backup['timestamp'] as String)
          : null,
      appVersion: backup['app_version'] as String?,
    );
  }
}

/// Força da senha
enum PasswordStrength { weak, medium, strong }

/// Informações do backup
class BackupInfo {
  final int version;
  final bool isEncrypted;
  final String? algorithm;
  final DateTime? timestamp;
  final String? appVersion;
  
  BackupInfo({
    required this.version,
    required this.isEncrypted,
    this.algorithm,
    this.timestamp,
    this.appVersion,
  });
}
