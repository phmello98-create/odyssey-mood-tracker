// lib/src/features/diary/presentation/controllers/diary_editor_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../../domain/entities/diary_template.dart';
import '../../data/synced_diary_repository.dart';
import 'diary_state.dart';
import 'diary_controller.dart';

/// Controller do editor de diário com auto-save
class DiaryEditorController extends StateNotifier<DiaryEditorState> {
  final SyncedDiaryRepository _repository;
  final Ref _ref;
  final String? _entryId;

  Timer? _autoSaveTimer;
  static const Duration _autoSaveDelay = Duration(seconds: 3);

  DiaryEditorController(
    this._repository,
    this._ref, {
    String? entryId,
  }) : _entryId = entryId,
       super(DiaryEditorState(isNewEntry: entryId == null)) {
    _init();
  }

  Future<void> _init() async {
    if (_entryId != null) {
      await _loadEntry(_entryId);
    } else {
      state = state.copyWith(
        isLoading: false,
        entry: DiaryEntryEntity.empty(),
      );
    }
  }

  Future<void> _loadEntry(String id) async {
    state = state.copyWith(isLoading: true);

    try {
      final entry = await _repository.getEntry(id);

      if (entry != null) {
        state = state.copyWith(
          entry: entry,
          isLoading: false,
          isNewEntry: false,
          lastSavedAt: entry.updatedAt,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          saveStatus: EditorSaveStatus.error,
          saveError: 'Entrada não encontrada',
        );
      }
    } catch (e) {
      debugPrint('[DiaryEditorController] Error loading entry: $e');
      state = state.copyWith(
        isLoading: false,
        saveStatus: EditorSaveStatus.error,
        saveError: 'Erro ao carregar entrada',
      );
    }
  }

  /// Aplica um template à entrada
  void applyTemplate(DiaryTemplate template) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    state = state.copyWith(
      entry: currentEntry.copyWith(
        content: template.initialContent,
        tags: [...currentEntry.tags, ...template.suggestedTags],
        templateId: template.id,
      ),
      selectedTemplateId: template.id,
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Atualiza o título
  void updateTitle(String title) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    state = state.copyWith(
      entry: currentEntry.copyWith(title: title.isEmpty ? null : title),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Atualiza o conteúdo (Quill Delta JSON)
  void updateContent(String content, String plainText) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    // Calcula contagem de palavras
    final wordCount = plainText.isEmpty
        ? 0
        : plainText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    state = state.copyWith(
      entry: currentEntry.copyWith(
        content: content,
        searchableText: plainText.isEmpty ? null : plainText,
        wordCount: wordCount,
      ),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Atualiza o sentimento
  void updateFeeling(String? feeling) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    state = state.copyWith(
      entry: currentEntry.copyWith(feeling: feeling),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Atualiza a data da entrada
  void updateEntryDate(DateTime date) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    state = state.copyWith(
      entry: currentEntry.copyWith(entryDate: date),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Adiciona uma tag
  void addTag(String tag) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    if (currentEntry.tags.contains(tag)) return;

    state = state.copyWith(
      entry: currentEntry.copyWith(tags: [...currentEntry.tags, tag]),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Remove uma tag
  void removeTag(String tag) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    state = state.copyWith(
      entry: currentEntry.copyWith(
        tags: currentEntry.tags.where((t) => t != tag).toList(),
      ),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Adiciona uma foto
  void addPhoto(String photoId) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    if (currentEntry.photoIds.contains(photoId)) return;

    state = state.copyWith(
      entry: currentEntry.copyWith(
        photoIds: [...currentEntry.photoIds, photoId],
      ),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Remove uma foto
  void removePhoto(String photoId) {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    state = state.copyWith(
      entry: currentEntry.copyWith(
        photoIds: currentEntry.photoIds.where((p) => p != photoId).toList(),
      ),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Toggle favorito
  void toggleStarred() {
    final currentEntry = state.entry ?? DiaryEntryEntity.empty();

    state = state.copyWith(
      entry: currentEntry.copyWith(starred: !currentEntry.starred),
      hasUnsavedChanges: true,
    );

    _scheduleAutoSave();
  }

  /// Agenda auto-save com debounce
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      save();
    });
  }

  /// Salva a entrada
  Future<bool> save() async {
    final entry = state.entry;
    if (entry == null) return false;

    // Não salva se não houver alterações
    if (!state.hasUnsavedChanges && !state.isNewEntry) {
      return true;
    }

    // Verifica se tem conteúdo mínimo
    final hasContent = entry.hasContent || entry.hasTitle;
    if (!hasContent && state.isNewEntry) {
      // Não salva entradas vazias
      return true;
    }

    state = state.copyWith(saveStatus: EditorSaveStatus.saving);

    try {
      final now = DateTime.now();
      final entryToSave = entry.copyWith(updatedAt: now);

      if (state.isNewEntry) {
        await _repository.createEntry(entryToSave);
        debugPrint('[DiaryEditorController] Created entry: ${entryToSave.id}');
      } else {
        await _repository.updateEntry(entryToSave);
        debugPrint('[DiaryEditorController] Updated entry: ${entryToSave.id}');
      }

      // Invalida o controller principal para atualizar a lista
      _ref.invalidate(diaryControllerProvider);

      state = state.copyWith(
        entry: entryToSave,
        hasUnsavedChanges: false,
        saveStatus: EditorSaveStatus.saved,
        lastSavedAt: now,
        isNewEntry: false,
      );

      // Reseta o status após 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && state.saveStatus == EditorSaveStatus.saved) {
          state = state.copyWith(saveStatus: EditorSaveStatus.idle);
        }
      });

      return true;
    } catch (e) {
      debugPrint('[DiaryEditorController] Error saving entry: $e');
      state = state.copyWith(
        saveStatus: EditorSaveStatus.error,
        saveError: 'Erro ao salvar entrada',
      );
      return false;
    }
  }

  /// Salva forçadamente (ignora debounce)
  Future<bool> saveNow() async {
    _autoSaveTimer?.cancel();
    return await save();
  }

  /// Deleta a entrada
  Future<bool> delete() async {
    final entry = state.entry;
    if (entry == null || state.isNewEntry) return true;

    try {
      await _repository.deleteEntry(entry.id);
      debugPrint('[DiaryEditorController] Deleted entry: ${entry.id}');

      // Invalida o controller principal para atualizar a lista
      _ref.invalidate(diaryControllerProvider);

      return true;
    } catch (e) {
      debugPrint('[DiaryEditorController] Error deleting entry: $e');
      return false;
    }
  }

  /// Verifica se está montado (StateNotifier não tem este getter por padrão)
  // ignore: annotate_overrides
  bool get mounted => !_isDisposed;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

/// Provider para o DiaryEditorController
final diaryEditorControllerProvider = StateNotifierProvider.autoDispose
    .family<DiaryEditorController, DiaryEditorState, String?>((ref, entryId) {
  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return DiaryEditorController(repository, ref, entryId: entryId);
});

/// Provider para templates disponíveis
final diaryTemplatesProvider = Provider<List<DiaryTemplate>>((ref) {
  return DiaryTemplate.defaultTemplates;
});

/// Provider para sugestões de tags baseadas no histórico
final tagSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(syncedDiaryRepositoryProvider);
  final allTags = await repository.getAllTags();

  // Retorna as tags mais usadas (ordenadas por frequência seria ideal,
  // mas por agora retornamos as primeiras 10)
  return allTags.take(10).toList();
});
