// lib/src/features/auth/services/cloud_storage_service.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Resultado de upload para o Firebase Storage
class UploadResult {
  final bool success;
  final String? downloadUrl;
  final String? storagePath;
  final String? errorMessage;

  const UploadResult._({
    required this.success,
    this.downloadUrl,
    this.storagePath,
    this.errorMessage,
  });

  factory UploadResult.success({
    required String downloadUrl,
    required String storagePath,
  }) =>
      UploadResult._(
        success: true,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
      );

  factory UploadResult.failure(String message) => UploadResult._(
        success: false,
        errorMessage: message,
      );
}

/// Serviço para gerenciar arquivos no Firebase Storage
/// 
/// Use cases:
/// - Upload de fotos de perfil
/// - Upload de capas de livros
/// - Download de imagens para cache local
class CloudStorageService {
  final FirebaseStorage _storage;
  final String userId;

  // Paths no Storage
  static const String _profilePhotosPath = 'users/{uid}/profile';
  static const String _bookCoversPath = 'users/{uid}/books/covers';
  static const String _attachmentsPath = 'users/{uid}/attachments';

  // Limites
  static const int maxProfilePhotoSize = 5 * 1024 * 1024; // 5MB
  static const int maxBookCoverSize = 2 * 1024 * 1024; // 2MB

  CloudStorageService({
    FirebaseStorage? storage,
    required this.userId,
  }) : _storage = storage ?? FirebaseStorage.instance;

  // ============================================
  // PROFILE PHOTOS
  // ============================================

  /// Faz upload da foto de perfil do usuário
  /// 
  /// Retorna a URL de download se sucesso
  Future<UploadResult> uploadProfilePhoto(File imageFile) async {
    try {
      // Validar tamanho
      final fileSize = await imageFile.length();
      if (fileSize > maxProfilePhotoSize) {
        return UploadResult.failure(
          'Imagem muito grande. Máximo: ${maxProfilePhotoSize ~/ (1024 * 1024)}MB',
        );
      }

      // Gerar nome único
      final extension = path.extension(imageFile.path).toLowerCase();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$extension';
      final storagePath = _profilePhotosPath.replaceAll('{uid}', userId);
      final fullPath = '$storagePath/$fileName';

      // Deletar foto anterior se existir
      await _deleteOldProfilePhotos(storagePath);

      // Upload
      final ref = _storage.ref(fullPath);
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      );

      final uploadTask = ref.putFile(imageFile, metadata);

      // Monitorar progresso (opcional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('[CloudStorage] Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      await uploadTask;

      // Obter URL de download
      final downloadUrl = await ref.getDownloadURL();

      debugPrint('[CloudStorage] Profile photo uploaded: $fullPath');
      return UploadResult.success(
        downloadUrl: downloadUrl,
        storagePath: fullPath,
      );
    } on FirebaseException catch (e) {
      debugPrint('[CloudStorage] Firebase error uploading profile photo: ${e.message}');
      return UploadResult.failure('Erro ao enviar foto: ${e.message}');
    } catch (e) {
      debugPrint('[CloudStorage] Error uploading profile photo: $e');
      return UploadResult.failure('Erro ao enviar foto de perfil');
    }
  }

  /// Faz upload da foto de perfil a partir de bytes (útil para web)
  Future<UploadResult> uploadProfilePhotoFromBytes(
    Uint8List bytes, {
    String extension = '.jpg',
  }) async {
    try {
      if (bytes.length > maxProfilePhotoSize) {
        return UploadResult.failure(
          'Imagem muito grande. Máximo: ${maxProfilePhotoSize ~/ (1024 * 1024)}MB',
        );
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$extension';
      final storagePath = _profilePhotosPath.replaceAll('{uid}', userId);
      final fullPath = '$storagePath/$fileName';

      await _deleteOldProfilePhotos(storagePath);

      final ref = _storage.ref(fullPath);
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      );

      await ref.putData(bytes, metadata);
      final downloadUrl = await ref.getDownloadURL();

      return UploadResult.success(
        downloadUrl: downloadUrl,
        storagePath: fullPath,
      );
    } catch (e) {
      debugPrint('[CloudStorage] Error uploading profile photo from bytes: $e');
      return UploadResult.failure('Erro ao enviar foto de perfil');
    }
  }

  /// Deleta fotos de perfil antigas
  Future<void> _deleteOldProfilePhotos(String storagePath) async {
    try {
      final listResult = await _storage.ref(storagePath).listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Ignora erros ao deletar fotos antigas
      debugPrint('[CloudStorage] Could not delete old profile photos: $e');
    }
  }

  /// Deleta a foto de perfil atual
  Future<bool> deleteProfilePhoto() async {
    try {
      final storagePath = _profilePhotosPath.replaceAll('{uid}', userId);
      await _deleteOldProfilePhotos(storagePath);
      debugPrint('[CloudStorage] Profile photo deleted');
      return true;
    } catch (e) {
      debugPrint('[CloudStorage] Error deleting profile photo: $e');
      return false;
    }
  }

  // ============================================
  // BOOK COVERS
  // ============================================

  /// Faz upload da capa de um livro
  Future<UploadResult> uploadBookCover(String bookId, File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      if (fileSize > maxBookCoverSize) {
        return UploadResult.failure(
          'Imagem muito grande. Máximo: ${maxBookCoverSize ~/ (1024 * 1024)}MB',
        );
      }

      final extension = path.extension(imageFile.path).toLowerCase();
      final fileName = '${bookId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final storagePath = _bookCoversPath.replaceAll('{uid}', userId);
      final fullPath = '$storagePath/$fileName';

      // Deletar capa anterior do mesmo livro
      await _deleteBookCover(bookId);

      final ref = _storage.ref(fullPath);
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'bookId': bookId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      await ref.putFile(imageFile, metadata);
      final downloadUrl = await ref.getDownloadURL();

      debugPrint('[CloudStorage] Book cover uploaded: $fullPath');
      return UploadResult.success(
        downloadUrl: downloadUrl,
        storagePath: fullPath,
      );
    } catch (e) {
      debugPrint('[CloudStorage] Error uploading book cover: $e');
      return UploadResult.failure('Erro ao enviar capa do livro');
    }
  }

  /// Faz upload de capa de livro a partir de bytes
  Future<UploadResult> uploadBookCoverFromBytes(
    String bookId,
    Uint8List bytes, {
    String extension = '.jpg',
  }) async {
    try {
      if (bytes.length > maxBookCoverSize) {
        return UploadResult.failure(
          'Imagem muito grande. Máximo: ${maxBookCoverSize ~/ (1024 * 1024)}MB',
        );
      }

      final fileName = '${bookId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final storagePath = _bookCoversPath.replaceAll('{uid}', userId);
      final fullPath = '$storagePath/$fileName';

      await _deleteBookCover(bookId);

      final ref = _storage.ref(fullPath);
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'bookId': bookId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(bytes, metadata);
      final downloadUrl = await ref.getDownloadURL();

      return UploadResult.success(
        downloadUrl: downloadUrl,
        storagePath: fullPath,
      );
    } catch (e) {
      debugPrint('[CloudStorage] Error uploading book cover from bytes: $e');
      return UploadResult.failure('Erro ao enviar capa do livro');
    }
  }

  /// Deleta a capa de um livro específico
  Future<bool> _deleteBookCover(String bookId) async {
    try {
      final storagePath = _bookCoversPath.replaceAll('{uid}', userId);
      final listResult = await _storage.ref(storagePath).listAll();

      for (final item in listResult.items) {
        if (item.name.startsWith(bookId)) {
          await item.delete();
        }
      }
      return true;
    } catch (e) {
      debugPrint('[CloudStorage] Could not delete book cover: $e');
      return false;
    }
  }

  /// Deleta todas as capas de livros do usuário
  Future<bool> deleteAllBookCovers() async {
    try {
      final storagePath = _bookCoversPath.replaceAll('{uid}', userId);
      final listResult = await _storage.ref(storagePath).listAll();

      for (final item in listResult.items) {
        await item.delete();
      }
      debugPrint('[CloudStorage] All book covers deleted');
      return true;
    } catch (e) {
      debugPrint('[CloudStorage] Error deleting all book covers: $e');
      return false;
    }
  }

  // ============================================
  // DOWNLOAD & CACHE
  // ============================================

  /// Baixa uma imagem e salva no cache local
  Future<File?> downloadAndCache(String downloadUrl, String localFileName) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final bytes = await ref.getData();

      if (bytes == null) return null;

      final cacheDir = await getTemporaryDirectory();
      final localFile = File('${cacheDir.path}/$localFileName');
      await localFile.writeAsBytes(bytes);

      debugPrint('[CloudStorage] Downloaded and cached: $localFileName');
      return localFile;
    } catch (e) {
      debugPrint('[CloudStorage] Error downloading file: $e');
      return null;
    }
  }

  /// Baixa foto de perfil para cache local
  Future<File?> downloadProfilePhoto(String downloadUrl) async {
    final fileName = 'profile_$userId.jpg';
    return downloadAndCache(downloadUrl, fileName);
  }

  /// Baixa capa de livro para cache local
  Future<File?> downloadBookCover(String bookId, String downloadUrl) async {
    final fileName = 'book_cover_$bookId.jpg';
    return downloadAndCache(downloadUrl, fileName);
  }

  // ============================================
  // ATTACHMENTS (GENÉRICO)
  // ============================================

  /// Faz upload de um arquivo genérico
  Future<UploadResult> uploadAttachment(
    File file, {
    String? customPath,
    int? maxSizeBytes,
  }) async {
    try {
      final fileSize = await file.length();
      final maxSize = maxSizeBytes ?? (10 * 1024 * 1024); // 10MB default

      if (fileSize > maxSize) {
        return UploadResult.failure(
          'Arquivo muito grande. Máximo: ${maxSize ~/ (1024 * 1024)}MB',
        );
      }

      final extension = path.extension(file.path).toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final storagePath = customPath ?? _attachmentsPath.replaceAll('{uid}', userId);
      final fullPath = '$storagePath/$fileName';

      final ref = _storage.ref(fullPath);
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': path.basename(file.path),
        },
      );

      await ref.putFile(file, metadata);
      final downloadUrl = await ref.getDownloadURL();

      return UploadResult.success(
        downloadUrl: downloadUrl,
        storagePath: fullPath,
      );
    } catch (e) {
      debugPrint('[CloudStorage] Error uploading attachment: $e');
      return UploadResult.failure('Erro ao enviar arquivo');
    }
  }

  // ============================================
  // CLEANUP
  // ============================================

  /// Deleta todos os arquivos do usuário no Storage
  Future<bool> deleteAllUserFiles() async {
    try {
      final userPath = 'users/$userId';
      final ref = _storage.ref(userPath);

      await _deleteRecursive(ref);

      debugPrint('[CloudStorage] All user files deleted');
      return true;
    } catch (e) {
      debugPrint('[CloudStorage] Error deleting all user files: $e');
      return false;
    }
  }

  /// Deleta recursivamente todos os arquivos em um path
  Future<void> _deleteRecursive(Reference ref) async {
    try {
      final listResult = await ref.listAll();

      // Deletar arquivos
      for (final item in listResult.items) {
        await item.delete();
      }

      // Recursivamente deletar subpastas
      for (final prefix in listResult.prefixes) {
        await _deleteRecursive(prefix);
      }
    } catch (e) {
      debugPrint('[CloudStorage] Error in recursive delete: $e');
    }
  }

  // ============================================
  // UTILITIES
  // ============================================

  /// Obtém o content type baseado na extensão do arquivo
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  /// Obtém informações de uso do Storage do usuário
  Future<StorageUsageInfo> getStorageUsage() async {
    try {
      final userPath = 'users/$userId';
      final ref = _storage.ref(userPath);
      
      int totalSize = 0;
      int fileCount = 0;

      await _calculateStorageUsage(ref, (size) {
        totalSize += size;
        fileCount++;
      });

      return StorageUsageInfo(
        totalBytes: totalSize,
        fileCount: fileCount,
      );
    } catch (e) {
      debugPrint('[CloudStorage] Error getting storage usage: $e');
      return const StorageUsageInfo(totalBytes: 0, fileCount: 0);
    }
  }

  Future<void> _calculateStorageUsage(
    Reference ref,
    void Function(int size) onFileFound,
  ) async {
    try {
      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        onFileFound(metadata.size ?? 0);
      }

      for (final prefix in listResult.prefixes) {
        await _calculateStorageUsage(prefix, onFileFound);
      }
    } catch (e) {
      // Ignora erros ao calcular
    }
  }
}

/// Informações de uso do Storage
class StorageUsageInfo {
  final int totalBytes;
  final int fileCount;

  const StorageUsageInfo({
    required this.totalBytes,
    required this.fileCount,
  });

  /// Tamanho formatado (ex: "1.5 MB")
  String get formattedSize {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
