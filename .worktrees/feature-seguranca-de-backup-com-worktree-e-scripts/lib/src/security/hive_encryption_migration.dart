import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_hive_manager.dart';

/// Serviço de migração para criptografar dados existentes
/// Migra boxes não-criptografados para criptografados
class HiveEncryptionMigration {
  static const _migrationCompletedKey = 'hive_encryption_migration_completed';
  static const _migrationVersionKey = 'hive_encryption_migration_version';
  static const _currentMigrationVersion = 1;
  
  /// Verifica se a migração já foi realizada
  static Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_migrationVersionKey) ?? 0;
    return version >= _currentMigrationVersion;
  }
  
  /// Verifica se precisa migrar dados existentes
  static Future<bool> needsMigration() async {
    if (await isMigrationCompleted()) {
      return false;
    }
    
    // Verificar se existem boxes antigos com dados
    for (final boxName in SecureHiveManager.sensitiveBoxes) {
      try {
        // Tenta abrir box sem criptografia para ver se tem dados
        final box = await Hive.openBox(boxName);
        if (box.isNotEmpty) {
          await box.close();
          return true;
        }
        await box.close();
      } catch (e) {
        // Box pode já estar criptografado ou não existir
        debugPrint('Verificação de migração para $boxName: $e');
      }
    }
    
    return false;
  }
  
  /// Executa migração de dados para boxes criptografados
  /// Renomeia boxes antigos e cria novos criptografados
  static Future<MigrationResult> migrateToEncrypted() async {
    final result = MigrationResult();
    
    try {
      debugPrint('🔄 Iniciando migração de criptografia...');
      
      final cipher = await SecureHiveManager.getCipher();
      
      for (final boxName in SecureHiveManager.sensitiveBoxes) {
        try {
          // 1. Verificar se box antigo existe e tem dados
          Box? oldBox;
          try {
            oldBox = await Hive.openBox('${boxName}_unencrypted_backup');
            if (oldBox.isEmpty) {
              // Tentar o box original
              await oldBox.close();
              oldBox = await Hive.openBox(boxName);
            }
          } catch (e) {
            // Pode ser que o box já esteja criptografado
            oldBox = null;
          }
          
          if (oldBox == null || oldBox.isEmpty) {
            result.skipped.add(boxName);
            if (oldBox != null) await oldBox.close();
            continue;
          }
          
          // 2. Salvar dados em memória
          final data = Map<dynamic, dynamic>.from(oldBox.toMap());
          final oldBoxName = oldBox.name;
          await oldBox.close();
          
          // 3. Deletar box antigo
          await Hive.deleteBoxFromDisk(oldBoxName);
          
          // 4. Criar novo box criptografado com os mesmos dados
          final newBox = await Hive.openBox(
            boxName,
            encryptionCipher: cipher,
          );
          
          // 5. Restaurar dados
          for (final entry in data.entries) {
            await newBox.put(entry.key, entry.value);
          }
          
          await newBox.close();
          
          result.migrated.add(boxName);
          debugPrint('✅ Migrado: $boxName (${data.length} registros)');
          
        } catch (e) {
          result.errors[boxName] = e.toString();
          debugPrint('❌ Erro migrando $boxName: $e');
        }
      }
      
      // Marcar migração como completa
      if (result.errors.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_migrationCompletedKey, true);
        await prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
        debugPrint('✅ Migração de criptografia concluída!');
      }
      
    } catch (e) {
      result.globalError = e.toString();
      debugPrint('❌ Erro global na migração: $e');
    }
    
    return result;
  }
  
  /// Criar backup antes da migração
  static Future<void> backupBeforeMigration() async {
    debugPrint('📦 Criando backup antes da migração...');
    
    for (final boxName in SecureHiveManager.sensitiveBoxes) {
      try {
        final box = await Hive.openBox(boxName);
        if (box.isNotEmpty) {
          // Criar cópia de backup
          final backupBox = await Hive.openBox('${boxName}_pre_encryption_backup');
          for (final key in box.keys) {
            await backupBox.put(key, box.get(key));
          }
          await backupBox.close();
        }
        await box.close();
      } catch (e) {
        debugPrint('Backup de $boxName: $e');
      }
    }
    
    debugPrint('✅ Backup pré-migração concluído');
  }
  
  /// Limpar backups de migração após confirmação
  static Future<void> cleanupMigrationBackups() async {
    for (final boxName in SecureHiveManager.sensitiveBoxes) {
      try {
        await Hive.deleteBoxFromDisk('${boxName}_pre_encryption_backup');
        await Hive.deleteBoxFromDisk('${boxName}_unencrypted_backup');
      } catch (e) {
        // Ignora se não existir
      }
    }
    debugPrint('🧹 Backups de migração limpos');
  }
}

/// Resultado da migração
class MigrationResult {
  final List<String> migrated = [];
  final List<String> skipped = [];
  final Map<String, String> errors = {};
  String? globalError;
  
  bool get isSuccess => errors.isEmpty && globalError == null;
  
  @override
  String toString() {
    return 'MigrationResult(migrated: $migrated, skipped: $skipped, errors: $errors, globalError: $globalError)';
  }
}
