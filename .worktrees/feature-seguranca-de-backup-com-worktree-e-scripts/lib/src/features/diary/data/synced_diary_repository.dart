// lib/src/features/diary/data/synced_diary_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';
import 'package:odyssey/src/features/diary/data/models/diary_entry.dart';
import 'package:odyssey/src/features/diary/data/repositories/diary_repository.dart';
import 'package:odyssey/src/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:odyssey/src/features/diary/domain/entities/diary_statistics.dart';
import 'package:odyssey/src/features/diary/domain/repositories/i_diary_repository.dart';
import 'package:odyssey/src/features/diary/presentation/controllers/diary_providers.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline
class SyncedDiaryRepository with SyncedRepositoryMixin implements IDiaryRepository {
  final DiaryRepository _localRepository;
  @override
  final Ref ref;

  @override
  String get collectionName => 'diary_entries';

  SyncedDiaryRepository(this._localRepository, this.ref);

  // ============================================
  // INICIALIZAÇÃO
  // ============================================

  @override
  Future<void> init() => _localRepository.init();

  @override
  Future<void> dispose() => _localRepository.dispose();

  // ============================================
  // CONVERSÕES
  // ============================================

  /// Converte DiaryEntry (model) para DiaryEntryEntity (domain)
  DiaryEntryEntity _toEntity(DiaryEntry model) {
    int? wordCount;
    if (model.searchableText != null && model.searchableText!.isNotEmpty) {
      wordCount = model.searchableText!.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }

    return DiaryEntryEntity(
      id: model.id,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      entryDate: model.entryDate,
      title: model.title,
      content: model.content,
      photoIds: model.photoIds,
      starred: model.starred,
      feeling: model.feeling,
      tags: model.tags,
      searchableText: model.searchableText,
      wordCount: wordCount,
    );
  }

  /// Converte DiaryEntryEntity (domain) para DiaryEntry (model)
  DiaryEntry _toModel(DiaryEntryEntity entity) {
    return DiaryEntry(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      entryDate: entity.entryDate,
      title: entity.title,
      content: entity.content,
      photoIds: entity.photoIds,
      starred: entity.starred,
      feeling: entity.feeling,
      tags: entity.tags,
      searchableText: entity.searchableText,
    );
  }

  /// Converte para Map para sincronização
  Map<String, dynamic> _entryToMap(DiaryEntry entry) {
    return {
      'id': entry.id,
      'createdAt': entry.createdAt.toIso8601String(),
      'updatedAt': entry.updatedAt.toIso8601String(),
      'entryDate': entry.entryDate.toIso8601String(),
      'title': entry.title,
      'content': entry.content,
      'photoIds': entry.photoIds,
      'starred': entry.starred,
      'feeling': entry.feeling,
      'tags': entry.tags,
      'searchableText': entry.searchableText,
      '_localModifiedAt': entry.updatedAt.toIso8601String(),
    };
  }

  // ============================================
  // OPERAÇÕES DE ESCRITA (com sync)
  // ============================================

  @override
  Future<DiaryEntryEntity> createEntry(DiaryEntryEntity entity) async {
    final model = _toModel(entity);
    await _localRepository.saveEntry(model);
    await enqueueCreate(model.id, _entryToMap(model));
    debugPrint('[SyncedDiaryRepository] Created entry: ${model.id}');
    return entity;
  }

  @override
  Future<DiaryEntryEntity> updateEntry(DiaryEntryEntity entity) async {
    final updated = entity.copyWith(updatedAt: DateTime.now());
    final model = _toModel(updated);
    await _localRepository.saveEntry(model);
    await enqueueUpdate(model.id, _entryToMap(model));
    debugPrint('[SyncedDiaryRepository] Updated entry: ${model.id}');
    return updated;
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _localRepository.deleteEntry(id);
    await enqueueDelete(id);
    debugPrint('[SyncedDiaryRepository] Deleted entry: $id');
  }

  @override
  Future<DiaryEntryEntity?> toggleStarred(String id) async {
    await _localRepository.toggleStarred(id);
    final entry = await _localRepository.getEntry(id);
    if (entry != null) {
      await enqueueUpdate(id, _entryToMap(entry));
      debugPrint('[SyncedDiaryRepository] Toggled starred: $id -> ${entry.starred}');
      return _toEntity(entry);
    }
    return null;
  }

  @override
  Future<DiaryEntryEntity?> addTag(String id, String tag) async {
    final entry = await _localRepository.getEntry(id);
    if (entry != null && !entry.tags.contains(tag)) {
      final updatedTags = [...entry.tags, tag];
      final updated = entry.copyWith(
        tags: updatedTags,
        updatedAt: DateTime.now(),
      );
      await _localRepository.saveEntry(updated);
      await enqueueUpdate(id, _entryToMap(updated));
      return _toEntity(updated);
    }
    return entry != null ? _toEntity(entry) : null;
  }

  @override
  Future<DiaryEntryEntity?> removeTag(String id, String tag) async {
    final entry = await _localRepository.getEntry(id);
    if (entry != null && entry.tags.contains(tag)) {
      final updatedTags = entry.tags.where((t) => t != tag).toList();
      final updated = entry.copyWith(
        tags: updatedTags,
        updatedAt: DateTime.now(),
      );
      await _localRepository.saveEntry(updated);
      await enqueueUpdate(id, _entryToMap(updated));
      return _toEntity(updated);
    }
    return entry != null ? _toEntity(entry) : null;
  }

  @override
  Future<DiaryEntryEntity?> addPhoto(String id, String photoId) async {
    final entry = await _localRepository.getEntry(id);
    if (entry != null && !entry.photoIds.contains(photoId)) {
      final updatedPhotoIds = [...entry.photoIds, photoId];
      final updated = entry.copyWith(
        photoIds: updatedPhotoIds,
        updatedAt: DateTime.now(),
      );
      await _localRepository.saveEntry(updated);
      await enqueueUpdate(id, _entryToMap(updated));
      return _toEntity(updated);
    }
    return entry != null ? _toEntity(entry) : null;
  }

  @override
  Future<DiaryEntryEntity?> removePhoto(String id, String photoId) async {
    final entry = await _localRepository.getEntry(id);
    if (entry != null && entry.photoIds.contains(photoId)) {
      final updatedPhotoIds = entry.photoIds.where((p) => p != photoId).toList();
      final updated = entry.copyWith(
        photoIds: updatedPhotoIds,
        updatedAt: DateTime.now(),
      );
      await _localRepository.saveEntry(updated);
      await enqueueUpdate(id, _entryToMap(updated));
      return _toEntity(updated);
    }
    return entry != null ? _toEntity(entry) : null;
  }

  // ============================================
  // OPERAÇÕES DE LEITURA (não precisam de sync)
  // ============================================

  @override
  Future<List<DiaryEntryEntity>> getAllEntries() async {
    final entries = await _localRepository.getAllEntries();
    return entries.map(_toEntity).toList();
  }

  @override
  Future<PaginatedEntries> getEntriesPaginated({
    int page = 1,
    int pageSize = 20,
    DiaryFilter? filter,
  }) async {
    var entries = await _localRepository.getAllEntries();

    // Aplicar filtros
    if (filter != null) {
      // Busca
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        entries = entries.where((e) {
          final titleMatch = e.title?.toLowerCase().contains(query) ?? false;
          final contentMatch = e.searchableText?.toLowerCase().contains(query) ?? false;
          return titleMatch || contentMatch;
        }).toList();
      }

      // Tags
      if (filter.tags != null && filter.tags!.isNotEmpty) {
        entries = entries.where((e) {
          return filter.tags!.any((tag) => e.tags.contains(tag));
        }).toList();
      }

      // Sentimento
      if (filter.feeling != null) {
        entries = entries.where((e) => e.feeling == filter.feeling).toList();
      }

      // Data início
      if (filter.startDate != null) {
        entries = entries.where((e) =>
          e.entryDate.isAfter(filter.startDate!) ||
          _isSameDay(e.entryDate, filter.startDate!)
        ).toList();
      }

      // Data fim
      if (filter.endDate != null) {
        entries = entries.where((e) =>
          e.entryDate.isBefore(filter.endDate!) ||
          _isSameDay(e.entryDate, filter.endDate!)
        ).toList();
      }

      // Favoritos
      if (filter.starred == true) {
        entries = entries.where((e) => e.starred).toList();
      }

      // Ordenação
      switch (filter.sortOrder) {
        case DiarySortOrder.newestFirst:
          entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
          break;
        case DiarySortOrder.oldestFirst:
          entries.sort((a, b) => a.entryDate.compareTo(b.entryDate));
          break;
        case DiarySortOrder.alphabetical:
          entries.sort((a, b) =>
            (a.title ?? '').toLowerCase().compareTo((b.title ?? '').toLowerCase())
          );
          break;
      }
    }

    final totalCount = entries.length;
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    if (startIndex >= totalCount) {
      return PaginatedEntries(
        entries: [],
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
        hasMore: false,
      );
    }

    final paginatedEntries = entries.sublist(startIndex, endIndex);

    return PaginatedEntries(
      entries: paginatedEntries.map(_toEntity).toList(),
      totalCount: totalCount,
      currentPage: page,
      pageSize: pageSize,
      hasMore: endIndex < totalCount,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Future<DiaryEntryEntity?> getEntry(String id) async {
    final entry = await _localRepository.getEntry(id);
    return entry != null ? _toEntity(entry) : null;
  }

  @override
  Future<List<DiaryEntryEntity>> getEntriesByYear(int year) async {
    final entries = await _localRepository.getEntriesByYear(year);
    return entries.map(_toEntity).toList();
  }

  @override
  Future<List<DiaryEntryEntity>> getEntriesByMonth(int year, int month) async {
    final entries = await _localRepository.getAllEntries();
    final filtered = entries.where((e) =>
      e.entryDate.year == year && e.entryDate.month == month
    ).toList();
    filtered.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return filtered.map(_toEntity).toList();
  }

  @override
  Future<List<DiaryEntryEntity>> getEntriesByDate(DateTime date) async {
    final entries = await _localRepository.getEntriesByDate(date);
    return entries.map(_toEntity).toList();
  }

  @override
  Future<List<DiaryEntryEntity>> searchEntries(String query) async {
    final entries = await _localRepository.searchEntries(query);
    return entries.map(_toEntity).toList();
  }

  @override
  Future<List<DiaryEntryEntity>> getStarredEntries() async {
    final entries = await _localRepository.getStarredEntries();
    return entries.map(_toEntity).toList();
  }

  @override
  Future<List<DiaryEntryEntity>> getEntriesByFeeling(String feeling) async {
    final entries = await _localRepository.getEntriesByFeeling(feeling);
    return entries.map(_toEntity).toList();
  }

  @override
  Future<List<DiaryEntryEntity>> getEntriesByTag(String tag) async {
    final entries = await _localRepository.getEntriesByTag(tag);
    return entries.map(_toEntity).toList();
  }

  @override
  Future<List<DiaryEntryEntity>> getOnThisDayEntries(DateTime date) async {
    final allEntries = await _localRepository.getAllEntries();
    final onThisDay = allEntries.where((e) =>
      e.entryDate.month == date.month &&
      e.entryDate.day == date.day &&
      e.entryDate.year != date.year
    ).toList();
    onThisDay.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return onThisDay.map(_toEntity).toList();
  }

  @override
  Future<int> getEntriesCount() => _localRepository.getEntriesCount();

  @override
  Future<List<String>> getAllTags() => _localRepository.getAllTags();

  @override
  Future<DiaryStatistics> getStatistics() async {
    final entries = await _localRepository.getAllEntries();
    return DiaryStatistics.fromEntries(entries);
  }

  // ============================================
  // EXPORTAÇÃO
  // ============================================

  @override
  Future<String> exportAsJson({List<String>? entryIds}) async {
    final entries = await _localRepository.getAllEntries();
    final toExport = entryIds != null
      ? entries.where((e) => entryIds.contains(e.id)).toList()
      : entries;

    final data = toExport.map((e) => {
      'id': e.id,
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt.toIso8601String(),
      'entryDate': e.entryDate.toIso8601String(),
      'title': e.title,
      'content': e.content,
      'photoIds': e.photoIds,
      'starred': e.starred,
      'feeling': e.feeling,
      'tags': e.tags,
      'searchableText': e.searchableText,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'entriesCount': data.length,
      'entries': data,
    });
  }

  @override
  Future<String> exportAsMarkdown({List<String>? entryIds}) async {
    final entries = await _localRepository.getAllEntries();
    final toExport = entryIds != null
      ? entries.where((e) => entryIds.contains(e.id)).toList()
      : entries;

    toExport.sort((a, b) => b.entryDate.compareTo(a.entryDate));

    final buffer = StringBuffer();
    buffer.writeln('# Meu Diário');
    buffer.writeln();
    buffer.writeln('Exportado em: ${DateTime.now().toString()}');
    buffer.writeln('Total de entradas: ${toExport.length}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (final entry in toExport) {
      final dateStr = '${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}';

      if (entry.title != null && entry.title!.isNotEmpty) {
        buffer.writeln('## $dateStr - ${entry.title}');
      } else {
        buffer.writeln('## $dateStr');
      }

      if (entry.feeling != null) {
        buffer.writeln('Sentimento: ${entry.feeling}');
      }

      if (entry.tags.isNotEmpty) {
        buffer.writeln('Tags: ${entry.tags.join(', ')}');
      }

      buffer.writeln();

      if (entry.searchableText != null && entry.searchableText!.isNotEmpty) {
        buffer.writeln(entry.searchableText);
      } else {
        buffer.writeln('*[Conteúdo formatado não exportável como texto]*');
      }

      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// Provider para o SyncedDiaryRepository
final syncedDiaryRepositoryProvider = Provider<SyncedDiaryRepository>((ref) {
  final localRepository = ref.watch(diaryRepositoryProvider);
  return SyncedDiaryRepository(localRepository, ref);
});
