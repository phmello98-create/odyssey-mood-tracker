# 🔒 PROMPT PARA IA ENGENHEIRA - IMPLEMENTAÇÃO COMPLETA DE SEGURANÇA

## 🎯 MISSÃO

Você é uma engenheira de segurança sênior especializada em Flutter, criptografia e compliance (LGPD/GDPR). Sua missão é implementar TODAS as correções de segurança críticas no app **Odyssey** para torná-lo pronto para produção.

## ⚠️ CONTEXTO CRÍTICO

O Odyssey é um app de saúde mental e produtividade que coleta **dados sensíveis**:
- Registros de humor (mood_records)
- Diário pessoal (diary_entries)
- Notas privadas (notes_v2)
- Tarefas e hábitos

**PROBLEMA:** Estes dados estão em texto puro no Hive, violando LGPD/GDPR.

## 🚨 5 VULNERABILIDADES CRÍTICAS A CORRIGIR

### 1. CRIPTOGRAFIA LOCAL (HIVE)
### 2. BACKUPS CRIPTOGRAFADOS
### 3. CONSENTIMENTO LGPD/GDPR
### 4. EXPORTAÇÃO DE DADOS
### 5. DELEÇÃO COMPLETA DE CONTA

---

## 📦 PACKAGES A ADICIONAR

Adicione ao `pubspec.yaml`:

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  encrypt: ^5.0.3
  crypto: ^3.0.3  # já tem
```

---

## 🔐 IMPLEMENTAÇÃO 1: CRIPTOGRAFIA DO HIVE

### Criar arquivo: `lib/src/security/secure_hive_manager.dart`

```dart
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

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
  
  /// Obter ou criar chave de criptografia
  static Future<List<int>> getOrCreateEncryptionKey() async {
    try {
      // Tentar recuperar chave existente
      String? keyString = await _storage.read(key: _keyName);
      
      if (keyString != null && keyString.isNotEmpty) {
        return base64Decode(keyString);
      }
      
      // Gerar nova chave segura
      final key = Hive.generateSecureKey();
      await _storage.write(
        key: _keyName,
        value: base64Encode(key),
      );
      
      return key;
    } catch (e) {
      debugPrint('Error getting encryption key: $e');
      rethrow;
    }
  }
  
  /// Obter cipher para criptografia
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
}
```

### Modificar: `lib/src/providers/app_initializer_provider.dart`

Encontre a inicialização do Hive e substitua por:

```dart
Future<void> _initializeHive() async {
  await Hive.initFlutter();
  
  // Registrar adapters (manter como está)
  Hive.registerAdapter(MoodRecordAdapter());
  // ... outros adapters
  
  // Abrir boxes CRIPTOGRAFADOS para dados sensíveis
  final cipher = await SecureHiveManager.getCipher();
  
  await Hive.openBox<MoodRecord>(
    'mood_records',
    encryptionCipher: cipher,
  );
  
  await Hive.openBox<DiaryEntry>(
    'diary_entries',
    encryptionCipher: cipher,
  );
  
  await Hive.openBox(
    'notes_v2',
    encryptionCipher: cipher,
  );
  
  await Hive.openBox(
    'tasks',
    encryptionCipher: cipher,
  );
  
  // Boxes não-sensíveis continuam sem criptografia
  await Hive.openBox('settings');
  await Hive.openBox('app_state');
  // ... outros boxes não-sensíveis
}
```

### Criar migração de dados: `lib/src/security/hive_encryption_migration.dart`

```dart
import 'package:hive/hive.dart';

class HiveEncryptionMigration {
  /// Migrar dados de boxes não-criptografados para criptografados
  static Future<bool> needsMigration() async {
    // Verificar se existe box antigo não-criptografado
    try {
      final box = await Hive.openBox('mood_records_old');
      final needsMigration = box.isNotEmpty;
      await box.close();
      return needsMigration;
    } catch (e) {
      return false; // Box não existe, não precisa migrar
    }
  }
  
  static Future<void> migrateToEncrypted() async {
    final boxNames = ['mood_records', 'diary_entries', 'notes_v2', 'tasks'];
    
    for (final boxName in boxNames) {
      try {
        // Abrir box antigo (sem criptografia)
        final oldBox = await Hive.openBox(boxName + '_old');
        
        if (oldBox.isEmpty) {
          await oldBox.close();
          continue;
        }
        
        // Abrir box novo (com criptografia)
        final cipher = await SecureHiveManager.getCipher();
        final newBox = await Hive.openBox(
          boxName,
          encryptionCipher: cipher,
        );
        
        // Copiar dados
        final keys = oldBox.keys.toList();
        for (final key in keys) {
          final value = oldBox.get(key);
          if (value != null) {
            await newBox.put(key, value);
          }
        }
        
        // Fechar e deletar box antigo
        await oldBox.close();
        await Hive.deleteBoxFromDisk(boxName + '_old');
        
        debugPrint('Migrated $boxName successfully');
      } catch (e) {
        debugPrint('Error migrating $boxName: $e');
      }
    }
  }
}
```

---

## 🔐 IMPLEMENTAÇÃO 2: BACKUPS CRIPTOGRAFADOS

### Criar arquivo: `lib/src/security/encrypted_backup_service.dart`

```dart
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class EncryptedBackupService {
  /// Derivar chave de criptografia da senha usando PBKDF2
  static List<int> _deriveKey(String password, List<int> salt) {
    final iterations = 100000;
    final keyLength = 32; // 256 bits
    
    var hmac = Hmac(sha256, utf8.encode(password));
    var key = <int>[];
    
    for (var i = 1; key.length < keyLength; i++) {
      var block = hmac.convert([
        ...salt,
        ...[(i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff]
      ]).bytes;
      var u = block;
      
      for (var j = 1; j < iterations; j++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < block.length; k++) {
          block[k] ^= u[k];
        }
      }
      
      key.addAll(block);
    }
    
    return key.sublist(0, keyLength);
  }
  
  /// Criar backup criptografado
  static Future<Map<String, dynamic>> createEncryptedBackup({
    required Map<String, dynamic> backupData,
    required String password,
  }) async {
    // 1. Converter dados para JSON
    final backupJson = jsonEncode(backupData);
    
    // 2. Gerar salt aleatório
    final salt = encrypt.SecureRandom(16).bytes;
    
    // 3. Derivar chave da senha
    final keyBytes = _deriveKey(password, salt);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    
    // 4. Gerar IV aleatório
    final iv = encrypt.IV.fromSecureRandom(16);
    
    // 5. Criptografar
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc)
    );
    final encrypted = encrypter.encrypt(backupJson, iv: iv);
    
    // 6. Calcular checksum
    final checksum = md5.convert(utf8.encode(backupJson)).toString();
    
    // 7. Retornar backup criptografado
    return {
      'version': 3, // Versão com encryption
      'encrypted': true,
      'algorithm': 'AES-256-CBC',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': 100000,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv.bytes),
      'data': encrypted.base64,
      'checksum': checksum,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
    };
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
      final salt = base64Decode(encryptedBackup['salt']);
      final iv = encrypt.IV(Uint8List.fromList(
        base64Decode(encryptedBackup['iv'])
      ));
      final encryptedData = encryptedBackup['data'];
      final storedChecksum = encryptedBackup['checksum'];
      
      // 3. Derivar chave
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
      
      // 5. Validar checksum
      final computedChecksum = md5.convert(
        utf8.encode(decrypted)
      ).toString();
      
      if (computedChecksum != storedChecksum) {
        throw Exception('Backup corrupted: checksum mismatch');
      }
      
      // 6. Parsear JSON
      final backupData = jsonDecode(decrypted) as Map<String, dynamic>;
      
      return backupData;
      
    } catch (e) {
      if (e.toString().contains('padding')) {
        throw Exception('Wrong password');
      }
      rethrow;
    }
  }
}
```

### Modificar: `lib/src/utils/services/backup_service.dart`

Adicionar métodos de backup criptografado:

```dart
// ADICIONAR no BackupService

Future<File> createEncryptedBackup({
  required String password,
}) async {
  try {
    // 1. Criar backup completo (dados não-criptografados)
    final backupData = await _collectAllData();
    
    // 2. Criptografar
    final encryptedBackup = await EncryptedBackupService.createEncryptedBackup(
      backupData: backupData,
      password: password,
    );
    
    // 3. Salvar em arquivo
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/odyssey_backup_encrypted_$timestamp.obk');
    
    await file.writeAsString(jsonEncode(encryptedBackup));
    
    return file;
  } catch (e) {
    throw Exception('Failed to create encrypted backup: $e');
  }
}

Future<void> restoreEncryptedBackup({
  required File backupFile,
  required String password,
}) async {
  try {
    // 1. Ler arquivo
    final encryptedJson = await backupFile.readAsString();
    final encryptedBackup = jsonDecode(encryptedJson);
    
    // 2. Descriptografar
    final backupData = await EncryptedBackupService.decryptBackup(
      encryptedBackup: encryptedBackup,
      password: password,
    );
    
    // 3. Restaurar dados
    await _restoreAllData(backupData);
    
  } catch (e) {
    throw Exception('Failed to restore backup: $e');
  }
}
```

---

## 🔐 IMPLEMENTAÇÃO 3: CONSENTIMENTO LGPD/GDPR

### Criar arquivo: `lib/src/features/auth/presentation/health_data_consent_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthDataConsentScreen extends ConsumerStatefulWidget {
  const HealthDataConsentScreen({super.key});
  
  @override
  ConsumerState<HealthDataConsentScreen> createState() => _HealthDataConsentScreenState();
}

class _HealthDataConsentScreenState extends ConsumerState<HealthDataConsentScreen> {
  bool _consent = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seus Dados de Saúde'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.health_and_safety,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'O Odyssey coleta dados sensíveis de saúde mental',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ao usar as funcionalidades de registro de humor e diário, '
              'você estará compartilhando informações sobre seu estado '
              'emocional e bem-estar mental. Esses dados são considerados '
              'sensíveis pela LGPD e GDPR.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            
            _buildFeatureCard(
              context,
              icon: Icons.phone_android,
              title: 'Armazenamento Local Criptografado',
              description: 'Seus dados são armazenados com criptografia AES-256 '
                          'no seu dispositivo.',
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              context,
              icon: Icons.cloud_off,
              title: 'Sincronização Opcional',
              description: 'Você escolhe se quer sincronizar na nuvem. '
                          'Por padrão, tudo fica local.',
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              context,
              icon: Icons.visibility_off,
              title: 'Privacidade Total',
              description: 'Não vendemos, não compartilhamos, não '
                          'acessamos seus dados pessoais.',
            ),
            const SizedBox(height: 32),
            
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _consent,
                onChanged: (value) => setState(() => _consent = value!),
                title: Text(
                  'Eu entendo e consinto explicitamente com a coleta '
                  'e processamento dos meus dados sensíveis de saúde mental.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _consent ? _saveConsent : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Aceitar e Continuar'),
            ),
            const SizedBox(height: 12),
            
            TextButton.icon(
              onPressed: _showPrivacyPolicy,
              icon: const Icon(Icons.article),
              label: const Text('Ler Política de Privacidade Completa'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_data_consent_given', true);
    await prefs.setString(
      'health_data_consent_date',
      DateTime.now().toIso8601String(),
    );
    
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
  
  Future<void> _showPrivacyPolicy() async {
    // TODO: Mostrar política de privacidade completa
    // Pode ser uma WebView ou um documento markdown
  }
}
```

### Adicionar verificação de consentimento no app:

```dart
// No WelcomeScreen ou após login, verificar se tem consentimento

Future<bool> _checkHealthDataConsent() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('health_data_consent_given') ?? false;
}

// Se não tiver, mostrar tela de consentimento
if (!hasConsent) {
  final accepted = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const HealthDataConsentScreen(),
    ),
  );
  
  if (accepted != true) {
    // Usuário não aceitou, não pode usar o app
    return;
  }
}
```

---

## 🔐 IMPLEMENTAÇÃO 4: EXPORTAÇÃO DE DADOS

### Criar arquivo: `lib/src/features/settings/services/data_export_service.dart`

```dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

class DataExportService {
  /// Exportar TODOS os dados do usuário (LGPD Art. 18 - Portabilidade)
  static Future<File> exportAllUserData() async {
    final exportData = {
      'user_info': await _exportUserInfo(),
      'mood_records': await _exportMoodRecords(),
      'diary_entries': await _exportDiary(),
      'tasks': await _exportTasks(),
      'habits': await _exportHabits(),
      'notes': await _exportNotes(),
      'books': await _exportBooks(),
      'time_tracking': await _exportTimeTracking(),
      'gamification': await _exportGamification(),
      'settings': await _exportSettings(),
      'export_metadata': {
        'date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'format': 'JSON',
        'description': 'Complete data export as per LGPD/GDPR Article 18',
      },
    };
    
    // Converter para JSON formatado (legível)
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    
    // Salvar em arquivo
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/odyssey_data_export_$timestamp.json');
    
    await file.writeAsString(jsonString);
    
    return file;
  }
  
  static Future<Map<String, dynamic>> _exportUserInfo() async {
    // TODO: Pegar info do Firebase Auth
    return {
      'uid': 'user_id_here',
      'email': 'user@email.com',
      'display_name': 'User Name',
      'created_at': DateTime.now().toIso8601String(),
    };
  }
  
  static Future<List<Map<String, dynamic>>> _exportMoodRecords() async {
    final box = await Hive.openBox('mood_records');
    return box.values
        .map((record) => {
              'date': record.date.toIso8601String(),
              'label': record.label,
              'score': record.score,
              'note': record.note,
              'activities': record.activities,
            })
        .toList();
  }
  
  static Future<List<Map<String, dynamic>>> _exportDiary() async {
    final box = await Hive.openBox('diary_entries');
    return box.values
        .map((entry) => {
              'id': entry.id,
              'title': entry.title,
              'content': entry.content,
              'entry_date': entry.entryDate.toIso8601String(),
              'created_at': entry.createdAt.toIso8601String(),
              'tags': entry.tags,
              'feeling': entry.feeling,
              'starred': entry.starred,
            })
        .toList();
  }
  
  static Future<List<Map<String, dynamic>>> _exportTasks() async {
    // Similar para tasks
    return [];
  }
  
  static Future<List<Map<String, dynamic>>> _exportHabits() async {
    // Similar para habits
    return [];
  }
  
  static Future<List<Map<String, dynamic>>> _exportNotes() async {
    // Similar para notes
    return [];
  }
  
  static Future<List<Map<String, dynamic>>> _exportBooks() async {
    // Similar para books
    return [];
  }
  
  static Future<List<Map<String, dynamic>>> _exportTimeTracking() async {
    // Similar para time tracking
    return [];
  }
  
  static Future<Map<String, dynamic>> _exportGamification() async {
    // Similar para gamification
    return {};
  }
  
  static Future<Map<String, dynamic>> _exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().fold<Map<String, dynamic>>({}, (map, key) {
      map[key] = prefs.get(key);
      return map;
    });
  }
  
  /// Compartilhar export via Share sheet
  static Future<void> shareExport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Meus Dados - Odyssey',
      text: 'Exportação completa dos meus dados do app Odyssey '
            '(conforme LGPD Art. 18 - Direito à Portabilidade)',
    );
  }
}
```

### Adicionar UI em Settings:

```dart
// No SettingsScreen, adicionar:

ListTile(
  leading: const Icon(Icons.download),
  title: const Text('Exportar Meus Dados'),
  subtitle: const Text('Download completo em JSON'),
  trailing: const Icon(Icons.chevron_right),
  onTap: _exportData,
),

Future<void> _exportData() async {
  try {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    // Exportar
    final file = await DataExportService.exportAllUserData();
    
    Navigator.pop(context); // Fechar loading
    
    // Perguntar se quer compartilhar
    final share = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exportação Completa'),
        content: Text(
          'Seus dados foram exportados para:\n\n${file.path}\n\n'
          'Deseja compartilhar o arquivo?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    );
    
    if (share == true) {
      await DataExportService.shareExport(file);
    }
    
  } catch (e) {
    Navigator.pop(context); // Fechar loading
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text('Falha ao exportar dados: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔐 IMPLEMENTAÇÃO 5: DELEÇÃO COMPLETA DE CONTA

### Criar arquivo: `lib/src/features/settings/services/account_deletion_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AccountDeletionService {
  /// Deletar conta completamente (LGPD Art. 18 - Direito ao Esquecimento)
  static Future<void> deleteAccountCompletely({
    required String password,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception('No user logged in');
      }
      
      // 1. Reautenticar (necessário para deletar conta)
      await _reauthenticate(user.email!, password);
      
      // 2. Deletar dados do Firestore
      if (!user.isAnonymous) {
        await _deleteFirestoreData(user.uid);
      }
      
      // 3. Deletar dados do Firebase Storage (se houver)
      await _deleteStorageFiles(user.uid);
      
      // 4. Deletar backups do Google Drive (se houver)
      await _deleteGoogleDriveBackups();
      
      // 5. Deletar dados locais (Hive)
      await _deleteAllHiveData();
      
      // 6. Deletar SharedPreferences
      await _deleteSharedPreferences();
      
      // 7. Deletar Secure Storage
      await _deleteSecureStorage();
      
      // 8. Deletar conta do Firebase Auth
      await user.delete();
      
      // 9. Limpar cache
      await _clearAppCache();
      
      debugPrint('Account deleted successfully');
      
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
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
    final batch = firestore.batch();
    
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
    ];
    
    // Deletar todas as subcoleções
    for (final collection in collections) {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    
    // Deletar documento do usuário
    batch.delete(firestore.collection('users').doc(userId));
    
    // Commit batch
    await batch.commit();
  }
  
  static Future<void> _deleteStorageFiles(String userId) async {
    // TODO: Deletar arquivos do Firebase Storage se implementado
  }
  
  static Future<void> _deleteGoogleDriveBackups() async {
    // TODO: Deletar backups do Google Drive se implementado
  }
  
  static Future<void> _deleteAllHiveData() async {
    // Fechar e deletar todos os boxes
    final boxNames = Hive.box.keys.toList();
    
    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
        await Hive.deleteBoxFromDisk(boxName);
      } catch (e) {
        debugPrint('Error deleting box $boxName: $e');
      }
    }
  }
  
  static Future<void> _deleteSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  static Future<void> _deleteSecureStorage() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }
  
  static Future<void> _clearAppCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
```

### Criar UI: `lib/src/features/settings/presentation/delete_account_screen.dart`

```dart
import 'package:flutter/material.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  String _password = '';
  bool _loading = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excluir Conta'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.warning_rounded,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Atenção: Esta ação é irreversível',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              'Ao excluir sua conta, TODOS os seus dados serão '
              'permanentemente deletados:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            _buildDeletionItem('✕ Registros de humor'),
            _buildDeletionItem('✕ Diário pessoal'),
            _buildDeletionItem('✕ Tarefas e hábitos'),
            _buildDeletionItem('✕ Notas e anotações'),
            _buildDeletionItem('✕ Biblioteca de livros'),
            _buildDeletionItem('✕ Dados de gamificação'),
            _buildDeletionItem('✕ Backups na nuvem'),
            _buildDeletionItem('✕ Conta e configurações'),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recomendamos fazer um backup antes de continuar.',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _navigateToBackup,
              icon: const Icon(Icons.download),
              label: const Text('Fazer Backup Antes'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 48),
            
            Text(
              'Para continuar, digite sua senha:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              onChanged: (value) => _password = value,
            ),
            const SizedBox(height: 24),
            
            OutlinedButton.icon(
              onPressed: _loading ? null : _confirmDeletion,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever),
              label: const Text('Excluir Conta Permanentemente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  void _navigateToBackup() {
    // Navegar para tela de backup
  }
  
  Future<void> _confirmDeletion() async {
    if (_password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite sua senha')),
      );
      return;
    }
    
    // Confirmação final
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação Final'),
        content: const Text(
          'Tem ABSOLUTA certeza que deseja excluir sua conta? '
          'Esta ação NÃO pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, Excluir'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _loading = true);
    
    try {
      await AccountDeletionService.deleteAccountCompletely(
        password: _password,
      );
      
      if (mounted) {
        // Navegar para tela de boas-vindas
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

Você DEVE implementar TUDO nesta ordem:

### Fase 1: Criptografia (CRÍTICO)
- [ ] Adicionar packages ao pubspec.yaml
- [ ] Criar SecureHiveManager
- [ ] Modificar AppInitializer para usar criptografia
- [ ] Criar HiveEncryptionMigration
- [ ] Testar em múltiplos dispositivos

### Fase 2: Backups (CRÍTICO)
- [ ] Criar EncryptedBackupService
- [ ] Modificar BackupService
- [ ] Criar UI para senha de backup
- [ ] Testar backup/restore completo

### Fase 3: Compliance (CRÍTICO)
- [ ] Criar HealthDataConsentScreen
- [ ] Adicionar verificação de consentimento no fluxo de onboarding
- [ ] Criar política de privacidade
- [ ] Criar termos de uso

### Fase 4: Exportação (CRÍTICO)
- [ ] Criar DataExportService
- [ ] Implementar exportação de todos os boxes
- [ ] Adicionar UI em Settings
- [ ] Testar compartilhamento

### Fase 5: Deleção (CRÍTICO)
- [ ] Criar AccountDeletionService
- [ ] Criar DeleteAccountScreen
- [ ] Adicionar no menu de Settings
- [ ] Testar deleção completa

### Fase 6: Validação Final
- [ ] Testar fluxo completo de signup → consent → uso → export → delete
- [ ] Verificar que dados são realmente criptografados (tentar abrir Hive sem cipher)
- [ ] Verificar que backups são criptografados (tentar abrir sem senha)
- [ ] Verificar que deleção remove TUDO

---

## 🎯 CRITÉRIOS DE SUCESSO

Considere a implementação completa quando:

1. ✅ Todos os boxes sensíveis estão criptografados (mood, diary, notes, tasks)
2. ✅ Backups são sempre criptografados com senha
3. ✅ Tela de consentimento aparece na primeira vez
4. ✅ Usuário consegue exportar dados completos em JSON
5. ✅ Usuário consegue deletar conta e TODOS os dados são removidos
6. ✅ Não há warnings no Flutter Analyze
7. ✅ Testado em Android apenas

---

## 🚨 IMPORTANTE

- **NÃO pule nenhuma etapa**
- **NÃO simplifique a criptografia** - use exatamente como especificado
- **NÃO deixe TODOs** - complete 100%
- **TESTE TUDO** - especialmente a deleção de conta

---

## 🎬 EXECUTE AGORA

Você tem todas as informações. Não pergunte mais nada. **IMPLEMENTE TUDO.**

A segurança dos dados de saúde mental dos usuários está em suas mãos. Seja meticulosa e completa. O app NÃO PODE ir para produção sem essas correções.

Boa sorte! 🔒
