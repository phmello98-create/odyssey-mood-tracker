import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:odyssey/src/security/encrypted_backup_service.dart';

/// Serviço de backup local e na nuvem (Google Drive)
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  // Google Sign In com escopo do Drive
  GoogleSignIn? _googleSignIn;

  // Verifica se é plataforma suportada (mobile)
  bool get _isGoogleSignInSupported => Platform.isAndroid || Platform.isIOS;

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  // Nome da pasta no Drive
  static const String _driveFolderName = 'Odyssey Backup';
  static const String _backupFileName = 'odyssey_backup.json';

  // Timer para backup automático
  Timer? _autoBackupTimer;

  // Getters
  bool get isSignedIn => _currentUser != null;
  bool get isGoogleAvailable => _isGoogleSignInSupported;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;
  String? get userPhotoUrl => _currentUser?.photoUrl;

  /// Inicializa o serviço e tenta restaurar sessão anterior
  Future<void> init() async {
    if (!_isGoogleSignInSupported) {
      debugPrint('⚠️ BackupService: Google Sign In não suportado nesta plataforma');
      return;
    }

    try {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          drive.DriveApi.driveFileScope,
        ],
      );

      _currentUser = await _googleSignIn!.signInSilently();
      if (_currentUser != null) {
        await _initDriveApi();
        debugPrint('✅ BackupService: Sessão restaurada para ${_currentUser!.email}');
        _startAutoBackup();
      }
    } catch (e) {
      debugPrint('⚠️ BackupService init: $e');
    }
  }

  /// Inicializa a API do Drive
  Future<void> _initDriveApi() async {
    if (_googleSignIn == null) return;
    final httpClient = await _googleSignIn!.authenticatedClient();
    if (httpClient != null) {
      _driveApi = drive.DriveApi(httpClient);
    }
  }

  /// Login com Google
  Future<bool> signIn() async {
    if (!_isGoogleSignInSupported || _googleSignIn == null) {
      debugPrint('❌ Google Sign In não disponível');
      return false;
    }

    try {
      _currentUser = await _googleSignIn!.signIn();
      if (_currentUser != null) {
        await _initDriveApi();
        debugPrint('✅ Login realizado: ${_currentUser!.email}');
        _startAutoBackup();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erro no login: $e');
      return false;
    }
  }

  /// Logout
  Future<void> signOut() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
    _currentUser = null;
    _driveApi = null;
    _stopAutoBackup();
    debugPrint('✅ Logout realizado');
  }

  /// Inicia backup automático (diário às 2 AM)
  void _startAutoBackup() {
    _stopAutoBackup(); // Para timer anterior se existir

    final now = DateTime.now();
    final nextBackup = DateTime(now.year, now.month, now.day + 1, 2, 0, 0); // Amanhã às 2 AM
    final duration = nextBackup.difference(now);

    _autoBackupTimer = Timer(duration, () async {
      await _performAutoBackup();
      // Agenda próximo backup
      _startAutoBackup();
    });

    debugPrint('⏰ Próximo backup automático em ${duration.inHours} horas');
  }

  /// Para backup automático
  void _stopAutoBackup() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
  }

  /// Executa backup automático
  Future<void> _performAutoBackup() async {
    try {
      debugPrint('🔄 Iniciando backup automático...');
      final success = await backupToDrive();
      if (success) {
        debugPrint('✅ Backup automático concluído');
      } else {
        debugPrint('❌ Backup automático falhou');
      }
    } catch (e) {
      debugPrint('❌ Erro no backup automático: $e');
    }
  }

  // ==========================================
  // BACKUP LOCAL (JSON)
  // ==========================================

  /// Calcula checksum MD5 para validação
  String _calculateChecksum(String data) {
    return md5.convert(utf8.encode(data)).toString();
  }

  /// Gera o JSON com todos os dados do app
  Future<Map<String, dynamic>> generateBackupData() async {
    final backup = <String, dynamic>{
      'version': 2, // Incrementado para nova versão
      'timestamp': DateTime.now().toIso8601String(),
      'app': 'Odyssey',
      'platform': Platform.operatingSystem,
    };

    // Mood Records
    try {
      final moodBox = await Hive.openBox('mood_records');
      backup['mood_records'] = moodBox.toMap().map((k, v) => MapEntry(k.toString(), v));
      backup['mood_records_count'] = moodBox.length;
    } catch (e) {
      debugPrint('Erro ao exportar mood_records: $e');
    }

    // Tasks
    try {
      final tasksBox = await Hive.openBox('tasks');
      backup['tasks'] = tasksBox.toMap().map((k, v) => MapEntry(k.toString(), v));
      backup['tasks_count'] = tasksBox.length;
    } catch (e) {
      debugPrint('Erro ao exportar tasks: $e');
    }

    // Habits
    try {
      final habitsBox = await Hive.openBox('habits');
      backup['habits'] = habitsBox.toMap().map((k, v) => MapEntry(k.toString(), v));
      backup['habits_count'] = habitsBox.length;
    } catch (e) {
      debugPrint('Erro ao exportar habits: $e');
    }

    // Notes
    try {
      final notesBox = await Hive.openBox('notes_v2');
      backup['notes'] = notesBox.toMap().map((k, v) => MapEntry(k.toString(), v));
      backup['notes_count'] = notesBox.length;
    } catch (e) {
      debugPrint('Erro ao exportar notes: $e');
    }

    // Books/Library
    try {
      final booksBox = await Hive.openBox('books_v3');
      final booksData = <String, dynamic>{};
      for (final key in booksBox.keys) {
        final book = booksBox.get(key);
        if (book != null) {
          booksData[key.toString()] = {
            'title': book.title,
            'author': book.author,
            'coverUrl': book.coverUrl,
            'totalPages': book.totalPages,
            'currentPage': book.currentPage,
            'status': book.status.toString(),
            'rating': book.rating,
            'notes': book.notes,
            'startDate': book.startDate?.toIso8601String(),
            'finishDate': book.finishDate?.toIso8601String(),
            'readingPeriods': book.readingPeriods.map((p) => {
              'startTime': p.startTime.toIso8601String(),
              'endTime': p.endTime?.toIso8601String(),
              'pagesRead': p.pagesRead,
            }).toList(),
          };
        }
      }
      backup['books'] = booksData;
      backup['books_count'] = booksData.length;
    } catch (e) {
      debugPrint('Erro ao exportar books: $e');
    }

    // Time Tracking
    try {
      final timeBox = await Hive.openBox('time_tracking_records');
      backup['time_tracking'] = timeBox.toMap().map((k, v) => MapEntry(k.toString(), v));
      backup['time_tracking_count'] = timeBox.length;
    } catch (e) {
      debugPrint('Erro ao exportar time_tracking: $e');
    }

    // Quotes
    try {
      final quotesBox = await Hive.openBox('quotes');
      backup['quotes'] = quotesBox.toMap().map((k, v) => MapEntry(k.toString(), v));
      backup['quotes_count'] = quotesBox.length;
    } catch (e) {
      debugPrint('Erro ao exportar quotes: $e');
    }

    // Gamification
    try {
      final gamificationBox = await Hive.openBox('gamification');
      backup['gamification'] = gamificationBox.toMap().map((k, v) => MapEntry(k.toString(), v));
    } catch (e) {
      debugPrint('Erro ao exportar gamification: $e');
    }

    // Settings
    try {
      final prefs = await SharedPreferences.getInstance();
      backup['settings'] = {
        'theme_mode': prefs.getInt('theme_mode'),
        'selected_theme': prefs.getInt('selected_theme'),
        'notifications_enabled': prefs.getBool('notifications_enabled'),
        'sound_enabled': prefs.getBool('sound_enabled'),
        'user_name': prefs.getString('user_name'),
        'locale': prefs.getString('locale'),
      };
    } catch (e) {
      debugPrint('Erro ao exportar settings: $e');
    }

    // Adiciona checksum para validação
    final jsonString = jsonEncode(backup);
    backup['checksum'] = _calculateChecksum(jsonString);

    return backup;
  }

  /// Exporta backup para arquivo JSON local
  Future<File?> exportToLocalFile() async {
    try {
      final backup = await generateBackupData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/odyssey_backup_$timestamp.json');
      
      await file.writeAsString(jsonString);
      debugPrint('✅ Backup local salvo: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Erro ao exportar backup local: $e');
      return null;
    }
  }

  /// Importa backup de arquivo JSON
  Future<bool> importFromJson(String jsonString) async {
    try {
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Verificar checksum se disponível
      if (backup.containsKey('checksum')) {
        final expectedChecksum = backup['checksum'] as String;
        final calculatedChecksum = _calculateChecksum(jsonEncode(backup..remove('checksum')));
        if (expectedChecksum != calculatedChecksum) {
          debugPrint('❌ Checksum inválido - backup pode estar corrompido');
          return false;
        }
      }
      
      // Verificar versão
      final version = backup['version'] as int? ?? 1;
      debugPrint('Importando backup versão $version');

      // Mood Records
      if (backup.containsKey('mood_records')) {
        final moodBox = await Hive.openBox('mood_records');
        final data = backup['mood_records'] as Map<String, dynamic>;
        for (final entry in data.entries) {
          await moodBox.put(entry.key, entry.value);
        }
      }

      // Tasks
      if (backup.containsKey('tasks')) {
        final tasksBox = await Hive.openBox('tasks');
        final data = backup['tasks'] as Map<String, dynamic>;
        for (final entry in data.entries) {
          await tasksBox.put(entry.key, entry.value);
        }
      }

      // Habits
      if (backup.containsKey('habits')) {
        final habitsBox = await Hive.openBox('habits');
        final data = backup['habits'] as Map<String, dynamic>;
        for (final entry in data.entries) {
          await habitsBox.put(entry.key, entry.value);
        }
      }

      // Notes
      if (backup.containsKey('notes')) {
        final notesBox = await Hive.openBox('notes_v2');
        final data = backup['notes'] as Map<String, dynamic>;
        for (final entry in data.entries) {
          await notesBox.put(entry.key, entry.value);
        }
      }

      // Time Tracking
      if (backup.containsKey('time_tracking')) {
        final timeBox = await Hive.openBox('time_tracking_records');
        final data = backup['time_tracking'] as Map<String, dynamic>;
        for (final entry in data.entries) {
          await timeBox.put(entry.key, entry.value);
        }
      }

      // Quotes
      if (backup.containsKey('quotes')) {
        final quotesBox = await Hive.openBox('quotes');
        final data = backup['quotes'] as Map<String, dynamic>;
        for (final entry in data.entries) {
          await quotesBox.put(entry.key, entry.value);
        }
      }

      // Gamification
      if (backup.containsKey('gamification')) {
        final gamificationBox = await Hive.openBox('gamification');
        final data = backup['gamification'] as Map<String, dynamic>;
        for (final entry in data.entries) {
          await gamificationBox.put(entry.key, entry.value);
        }
      }

      debugPrint('✅ Backup importado com sucesso');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao importar backup: $e');
      return false;
    }
  }

  // ==========================================
  // BACKUP NA NUVEM (GOOGLE DRIVE)
  // ==========================================

  /// Obtém ou cria a pasta do app no Drive
  Future<String?> _getOrCreateBackupFolder() async {
    if (_driveApi == null) return null;

    try {
      // Procura pasta existente
      const query = "name='$_driveFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final result = await _driveApi!.files.list(q: query, spaces: 'drive');
      
      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }

      // Cria nova pasta
      final folder = drive.File()
        ..name = _driveFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      
      final created = await _driveApi!.files.create(folder);
      debugPrint('✅ Pasta criada no Drive: ${created.id}');
      return created.id;
    } catch (e) {
      debugPrint('❌ Erro ao criar pasta no Drive: $e');
      return null;
    }
  }

  /// Faz backup para o Google Drive
  Future<bool> backupToDrive() async {
    if (_driveApi == null) {
      debugPrint('❌ Não logado no Google');
      return false;
    }

    try {
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return false;

      final backup = await generateBackupData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      final bytes = utf8.encode(jsonString);

      // Verifica se já existe um backup
      final query = "name='$_backupFileName' and '$folderId' in parents and trashed=false";
      final existing = await _driveApi!.files.list(q: query, spaces: 'drive');

      if (existing.files != null && existing.files!.isNotEmpty) {
        // Atualiza arquivo existente
        final fileId = existing.files!.first.id!;
        await _driveApi!.files.update(
          drive.File()..modifiedTime = DateTime.now(),
          fileId,
          uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
        );
        debugPrint('✅ Backup atualizado no Drive');
      } else {
        // Cria novo arquivo
        final file = drive.File()
          ..name = _backupFileName
          ..parents = [folderId]
          ..mimeType = 'application/json';

        await _driveApi!.files.create(
          file,
          uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
        );
        debugPrint('✅ Backup criado no Drive');
      }

      // Salva timestamp do último backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_drive_backup', DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      debugPrint('❌ Erro no backup para Drive: $e');
      return false;
    }
  }

  /// Restaura backup do Google Drive
  Future<bool> restoreFromDrive() async {
    if (_driveApi == null) {
      debugPrint('❌ Não logado no Google');
      return false;
    }

    try {
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return false;

      // Busca o arquivo de backup
      final query = "name='$_backupFileName' and '$folderId' in parents and trashed=false";
      final result = await _driveApi!.files.list(q: query, spaces: 'drive');

      if (result.files == null || result.files!.isEmpty) {
        debugPrint('⚠️ Nenhum backup encontrado no Drive');
        return false;
      }

      final fileId = result.files!.first.id!;
      
      // Download do arquivo
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final success = await importFromJson(jsonString);
      
      if (success) {
        debugPrint('✅ Backup restaurado do Drive');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Erro ao restaurar do Drive: $e');
      return false;
    }
  }

  /// Obtém informações do último backup no Drive
  Future<DateTime?> getLastDriveBackupTime() async {
    if (_driveApi == null) return null;

    try {
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return null;

      final query = "name='$_backupFileName' and '$folderId' in parents and trashed=false";
      final result = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(modifiedTime)',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.modifiedTime;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter info do backup: $e');
      return null;
    }
  }

  /// Deleta backup do Drive
  Future<bool> deleteBackupFromDrive() async {
    if (_driveApi == null) return false;

    try {
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return false;

      final query = "name='$_backupFileName' and '$folderId' in parents and trashed=false";
      final result = await _driveApi!.files.list(q: query, spaces: 'drive');

      if (result.files != null && result.files!.isNotEmpty) {
        await _driveApi!.files.delete(result.files!.first.id!);
        debugPrint('✅ Backup deletado do Drive');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao deletar backup: $e');
      return false;
    }
  }

  // ==========================================
  // BACKUP CRIPTOGRAFADO (LGPD/GDPR)
  // ==========================================

  /// Criar backup criptografado com senha
  Future<File?> createEncryptedBackup({
    required String password,
  }) async {
    try {
      // 1. Gerar dados do backup
      final backupData = await generateBackupData();
      
      // 2. Criptografar com senha
      final encryptedBackup = await EncryptedBackupService.createEncryptedBackup(
        backupData: backupData,
        password: password,
      );
      
      // 3. Salvar em arquivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .split('T')[0];
      final file = File('${directory.path}/odyssey_backup_encrypted_$timestamp.obk');
      
      await file.writeAsString(jsonEncode(encryptedBackup));
      
      debugPrint('✅ Backup criptografado salvo: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Erro ao criar backup criptografado: $e');
      return null;
    }
  }

  /// Restaurar backup criptografado
  Future<bool> restoreEncryptedBackup({
    required File backupFile,
    required String password,
  }) async {
    try {
      // 1. Ler arquivo
      final encryptedJson = await backupFile.readAsString();
      final encryptedBackup = jsonDecode(encryptedJson) as Map<String, dynamic>;
      
      // 2. Verificar se é criptografado
      if (!EncryptedBackupService.isEncrypted(encryptedBackup)) {
        // Backup não criptografado, usar método normal
        return await importFromJson(encryptedJson);
      }
      
      // 3. Descriptografar
      final backupData = await EncryptedBackupService.decryptBackup(
        encryptedBackup: encryptedBackup,
        password: password,
      );
      
      // 4. Restaurar dados
      final jsonString = jsonEncode(backupData);
      return await importFromJson(jsonString);
      
    } catch (e) {
      debugPrint('❌ Erro ao restaurar backup criptografado: $e');
      rethrow;
    }
  }

  /// Verificar se arquivo de backup está criptografado
  Future<bool> isBackupEncrypted(File backupFile) async {
    try {
      final content = await backupFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return EncryptedBackupService.isEncrypted(data);
    } catch (e) {
      return false;
    }
  }

  /// Obter informações do backup sem descriptografar
  Future<BackupInfo?> getBackupFileInfo(File backupFile) async {
    try {
      final content = await backupFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return EncryptedBackupService.getBackupInfo(data);
    } catch (e) {
      return null;
    }
  }
}

// Instância global
final backupService = BackupService();
