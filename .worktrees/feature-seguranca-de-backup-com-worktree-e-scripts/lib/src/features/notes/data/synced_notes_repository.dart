// lib/src/features/notes/data/synced_notes_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'notes_repository.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline
class SyncedNotesRepository with SyncedRepositoryMixin {
  final NotesRepository _localRepository;
  @override
  final Ref ref;
  
  @override
  String get collectionName => 'notes';
  
  SyncedNotesRepository(this._localRepository, this.ref);
  
  /// Inicializa o repositório
  Future<void> initialize() => _localRepository.initialize();
  
  // ============================================
  // MÉTODOS DE ESCRITA (com sync)
  // ============================================
  
  /// Adiciona uma nota e enfileira para sync
  Future<String> addNote(Map<String, dynamic> noteData) async {
    final noteId = await _localRepository.addNote(noteData);
    await enqueueCreate(noteId, _noteToMap(noteData, noteId));
    return noteId;
  }
  
  /// Atualiza uma nota e enfileira para sync
  Future<void> updateNote(String noteId, Map<String, dynamic> noteData) async {
    await _localRepository.updateNote(noteId, noteData);
    await enqueueUpdate(noteId, _noteToMap(noteData, noteId));
  }
  
  /// Deleta uma nota e enfileira para sync
  Future<void> deleteNote(String noteId) async {
    await _localRepository.deleteNote(noteId);
    await enqueueDelete(noteId);
  }
  
  /// Alterna pin de uma nota e enfileira para sync
  Future<void> togglePin(String noteId) async {
    await _localRepository.togglePin(noteId);
    final note = _localRepository.getNote(noteId);
    if (note != null) {
      await enqueueUpdate(noteId, _noteToMap(note, noteId));
    }
  }
  
  // ============================================
  // MÉTODOS DE LEITURA (não precisam de sync)
  // ============================================
  
  Map<String, dynamic>? getNote(String noteId) => _localRepository.getNote(noteId);
  
  List<Map<String, dynamic>> getAllNotes() => _localRepository.getAllNotes();
  
  List<Map<String, dynamic>> getPinnedNotes() => _localRepository.getPinnedNotes();
  
  List<Map<String, dynamic>> getUnpinnedNotes() => _localRepository.getUnpinnedNotes();
  
  List<Map<String, dynamic>> searchNotes(String query) => _localRepository.searchNotes(query);
  
  bool get isInitialized => _localRepository.isInitialized;
  
  /// Expõe o box para uso com ValueListenableBuilder
  Box? get box => _localRepository.box;
  
  // ============================================
  // CONVERSÃO
  // ============================================
  
  Map<String, dynamic> _noteToMap(Map<String, dynamic> noteData, String noteId) {
    return {
      ...noteData,
      'id': noteId,
      '_localModifiedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider para o SyncedNotesRepository
final syncedNotesRepositoryProvider = Provider<SyncedNotesRepository>((ref) {
  final localRepository = ref.watch(notesRepositoryProvider);
  return SyncedNotesRepository(localRepository, ref);
});
