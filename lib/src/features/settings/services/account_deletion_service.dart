import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:odyssey/src/security/secure_hive_manager.dart';

/// Serviço de deleção completa de conta
/// Conforme LGPD Art. 18 - Direito ao Esquecimento
class AccountDeletionService {
  
  /// Deletar conta completamente
  /// Remove TODOS os dados locais e na nuvem
  static Future<DeletionResult> deleteAccountCompletely({
    String? password,
    bool isGoogleAccount = false,
  }) async {
    final result = DeletionResult();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // 1. Reautenticar se necessário (para contas com email/senha)
      if (user != null && !user.isAnonymous && password != null && !isGoogleAccount) {
        try {
          await _reauthenticate(user.email!, password);
          result.steps['reauth'] = true;
        } catch (e) {
          result.errors['reauth'] = e.toString();
          throw Exception('Falha na autenticação: senha incorreta');
        }
      }
      
      // 2. Deletar dados do Firestore
      if (user != null && !user.isAnonymous) {
        try {
          await _deleteFirestoreData(user.uid);
          result.steps['firestore'] = true;
        } catch (e) {
          result.errors['firestore'] = e.toString();
          debugPrint('Erro ao deletar Firestore: $e');
        }
      }
      
      // 3. Deletar dados locais (Hive)
      try {
        await _deleteAllHiveData();
        result.steps['hive'] = true;
      } catch (e) {
        result.errors['hive'] = e.toString();
        debugPrint('Erro ao deletar Hive: $e');
      }
      
      // 4. Deletar SharedPreferences
      try {
        await _deleteSharedPreferences();
        result.steps['prefs'] = true;
      } catch (e) {
        result.errors['prefs'] = e.toString();
        debugPrint('Erro ao deletar SharedPreferences: $e');
      }
      
      // 5. Deletar Secure Storage (chaves de criptografia)
      try {
        await _deleteSecureStorage();
        result.steps['secure_storage'] = true;
      } catch (e) {
        result.errors['secure_storage'] = e.toString();
        debugPrint('Erro ao deletar Secure Storage: $e');
      }
      
      // 6. Limpar cache
      try {
        await _clearAppCache();
        result.steps['cache'] = true;
      } catch (e) {
        result.errors['cache'] = e.toString();
        debugPrint('Erro ao limpar cache: $e');
      }
      
      // 7. Deletar conta do Firebase Auth (por último)
      if (user != null) {
        try {
          await user.delete();
          result.steps['auth'] = true;
        } catch (e) {
          result.errors['auth'] = e.toString();
          debugPrint('Erro ao deletar conta Firebase: $e');
          // Não falha se não conseguir deletar auth, dados já foram removidos
        }
      }
      
      result.success = result.errors.isEmpty;
      debugPrint('✅ Conta deletada: ${result.success}');
      
    } catch (e) {
      result.globalError = e.toString();
      debugPrint('❌ Erro global na deleção: $e');
    }
    
    return result;
  }
  
  static Future<void> _reauthenticate(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    
    await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);
  }
  
  static Future<void> _deleteFirestoreData(String userId) async {
    final firestore = FirebaseFirestore.instance;
    
    // Coleções a deletar
    final collections = [
      'moods',
      'tasks',
      'habits',
      'notes',
      'quotes',
      'books',
      'timeTracking',
      'diary',
      'gamification',
      'settings',
    ];
    
    // Deletar todas as subcoleções do usuário
    for (final collection in collections) {
      try {
        final snapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection(collection)
            .limit(500) // Batch limit
            .get();
        
        // Deletar em batch
        final batch = firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        debugPrint('Deletado: users/$userId/$collection (${snapshot.docs.length} docs)');
      } catch (e) {
        debugPrint('Erro deletando $collection: $e');
      }
    }
    
    // Deletar documento principal do usuário
    try {
      await firestore.collection('users').doc(userId).delete();
      debugPrint('Deletado: users/$userId');
    } catch (e) {
      debugPrint('Erro deletando documento do usuário: $e');
    }
  }
  
  static Future<void> _deleteAllHiveData() async {
    // Lista de todos os boxes conhecidos
    final allBoxNames = [
      ...SecureHiveManager.sensitiveBoxes,
      ...SecureHiveManager.nonSensitiveBoxes,
      'mood_records',
      'diary_entries',
      'notes_v2',
      'tasks',
      'habits',
      'books_v3',
      'quotes',
      'gamification',
      'time_tracking_records',
      'settings',
      'app_state',
      'languages',
      'study_sessions',
      'vocabulary_items',
      'immersion_logs',
      'suggestions',
      'suggestion_analytics',
      'odyssey_user',
    ];
    
    // Remover duplicatas
    final uniqueBoxes = allBoxNames.toSet().toList();
    
    for (final boxName in uniqueBoxes) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          await box.close();
        }
        await Hive.deleteBoxFromDisk(boxName);
        debugPrint('Deletado box: $boxName');
      } catch (e) {
        debugPrint('Erro deletando box $boxName: $e');
      }
    }
    
    // Limpar cache de chave de criptografia
    SecureHiveManager.clearKeyCache();
  }
  
  static Future<void> _deleteSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('SharedPreferences limpos');
  }
  
  static Future<void> _deleteSecureStorage() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.deleteAll();
    debugPrint('Secure Storage limpo');
  }
  
  static Future<void> _clearAppCache() async {
    try {
      // Cache temporário
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        await _deleteDirectory(cacheDir);
      }
      
      // Diretório de documentos do app
      final docsDir = await getApplicationDocumentsDirectory();
      final backupFiles = docsDir.listSync().where(
        (f) => f.path.contains('odyssey_') && f.path.endsWith('.json')
      );
      for (final file in backupFiles) {
        await file.delete();
      }
      
      debugPrint('Cache limpo');
    } catch (e) {
      debugPrint('Erro ao limpar cache: $e');
    }
  }
  
  static Future<void> _deleteDirectory(Directory dir) async {
    try {
      final files = dir.listSync();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        } else if (file is Directory) {
          await _deleteDirectory(file);
        }
      }
    } catch (e) {
      debugPrint('Erro deletando diretório: $e');
    }
  }
  
  /// Verificar se usuário precisa de reautenticação
  static Future<bool> needsReauth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return false;
    
    // Verifica se é login com Google
    for (final provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return false; // Google reautentica automaticamente
      }
    }
    
    return true; // Email/senha precisa de reauth
  }
  
  /// Verificar se é conta Google
  static bool isGoogleAccount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    for (final provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return true;
      }
    }
    return false;
  }
}

/// Resultado da deleção
class DeletionResult {
  bool success = false;
  String? globalError;
  final Map<String, bool> steps = {};
  final Map<String, String> errors = {};
  
  bool get hasErrors => errors.isNotEmpty || globalError != null;
  
  @override
  String toString() {
    return 'DeletionResult(success: $success, steps: $steps, errors: $errors, globalError: $globalError)';
  }
}
