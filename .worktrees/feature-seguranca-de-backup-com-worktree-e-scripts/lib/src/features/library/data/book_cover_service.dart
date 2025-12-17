import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing book covers - local files and online downloads
class BookCoverService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick cover from device gallery
  static Future<Uint8List?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (image != null) {
        return await image.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
    }
    return null;
  }

  /// Take photo with camera
  static Future<Uint8List?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (image != null) {
        return await image.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
    return null;
  }

  /// Download cover from URL
  static Future<Uint8List?> downloadFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error downloading cover: $e');
    }
    return null;
  }

  /// Save cover to local storage
  static Future<String?> saveCover(String bookId, Uint8List bytes) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${appDir.path}/book_covers');
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }
      
      final coverPath = '${coversDir.path}/$bookId.jpg';
      final file = File(coverPath);
      await file.writeAsBytes(bytes);
      return coverPath;
    } catch (e) {
      debugPrint('Error saving cover: $e');
    }
    return null;
  }

  /// Delete cover from local storage
  static Future<void> deleteCover(String bookId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coverPath = '${appDir.path}/book_covers/$bookId.jpg';
      final file = File(coverPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting cover: $e');
    }
  }

  /// Get cover file if exists
  static Future<File?> getCoverFile(String bookId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coverPath = '${appDir.path}/book_covers/$bookId.jpg';
      final file = File(coverPath);
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('Error getting cover file: $e');
    }
    return null;
  }
}

/// Search results from multiple cover sources
class CoverSearchResult {
  final String url;
  final String source; // 'openlibrary', 'google', 'custom'
  final String? thumbnailUrl;

  CoverSearchResult({
    required this.url,
    required this.source,
    this.thumbnailUrl,
  });
}
