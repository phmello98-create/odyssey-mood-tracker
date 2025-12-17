// lib/src/features/notes/data/notes_repository.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Repositório para gerenciar notas no Hive
class NotesRepository {
  static const String _boxName = 'notes_v2';
  Box? _box;
  bool _initialized = false;

  Box? get box => _box;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await Hive.openBox(_boxName);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing NotesRepository: $e');
      rethrow;
    }
  }

  // CRUD Operations

  Future<String> addNote(Map<String, dynamic> noteData) async {
    await _ensureInitialized();
    final noteId = noteData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    noteData['id'] = noteId;
    noteData['createdAt'] ??= DateTime.now().toIso8601String();
    noteData['updatedAt'] = DateTime.now().toIso8601String();
    await _box!.put(noteId, noteData);
    return noteId;
  }

  Future<void> updateNote(String noteId, Map<String, dynamic> noteData) async {
    await _ensureInitialized();
    noteData['updatedAt'] = DateTime.now().toIso8601String();
    await _box!.put(noteId, noteData);
  }

  Future<void> deleteNote(String noteId) async {
    await _ensureInitialized();
    await _box!.delete(noteId);
  }

  Map<String, dynamic>? getNote(String noteId) {
    if (!_initialized || _box == null) return null;
    final data = _box!.get(noteId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  List<Map<String, dynamic>> getAllNotes() {
    if (!_initialized || _box == null) return [];
    return _box!.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  List<Map<String, dynamic>> getPinnedNotes() {
    return getAllNotes().where((note) => note['isPinned'] == true).toList();
  }

  List<Map<String, dynamic>> getUnpinnedNotes() {
    return getAllNotes().where((note) => note['isPinned'] != true).toList();
  }

  Future<void> togglePin(String noteId) async {
    await _ensureInitialized();
    final note = getNote(noteId);
    if (note != null) {
      note['isPinned'] = !(note['isPinned'] ?? false);
      await updateNote(noteId, note);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // Search
  List<Map<String, dynamic>> searchNotes(String query) {
    if (query.isEmpty) return getAllNotes();
    
    final lowerQuery = query.toLowerCase();
    return getAllNotes().where((note) {
      final title = (note['title'] ?? '').toString().toLowerCase();
      final content = (note['content'] ?? '').toString().toLowerCase();
      return title.contains(lowerQuery) || content.contains(lowerQuery);
    }).toList();
  }
}

/// Provider para o repositório de notas
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

/// Provider para lista de notas (reativo)
final allNotesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final repo = ref.watch(notesRepositoryProvider);
  await repo.initialize();
  
  yield repo.getAllNotes();
  
  if (repo.box != null) {
    await for (final _ in repo.box!.watch()) {
      yield repo.getAllNotes();
    }
  }
});
