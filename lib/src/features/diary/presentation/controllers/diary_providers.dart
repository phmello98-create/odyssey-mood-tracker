import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/diary_entry.dart';
import '../../data/repositories/diary_repository.dart';
import '../../data/synced_diary_repository.dart';
import '../../domain/entities/diary_entry_entity.dart';

// Re-export dos controllers modernos
export 'diary_controller.dart';
export 'diary_editor_controller.dart';
export 'diary_state.dart';
// O syncedDiaryRepositoryProvider está em synced_diary_repository.dart
// Re-export para conveniência
export '../../data/synced_diary_repository.dart' show syncedDiaryRepositoryProvider;

/// Provider para o repository local de diário
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository();
});

// ============================================
// PROVIDERS LEGADOS (para compatibilidade)
// ============================================

/// Provider para todas as entradas de diário (legado)
@Deprecated('Use diaryControllerProvider instead')
final diaryEntriesProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getAllEntries();
});

/// Provider para entradas de um ano específico (legado)
@Deprecated('Use diaryControllerProvider with filter instead')
final diaryEntriesByYearProvider =
    FutureProvider.family<List<DiaryEntry>, int>((ref, year) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getEntriesByYear(year);
});

/// Provider para entradas favoritas (legado)
@Deprecated('Use diaryControllerProvider with filter instead')
final starredEntriesProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getStarredEntries();
});

/// Provider para busca de entradas (legado)
@Deprecated('Use diaryControllerProvider.search() instead')
final searchEntriesProvider =
    FutureProvider.family<List<DiaryEntry>, String>((ref, query) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.searchEntries(query);
});

/// Provider para contagem de entradas
final diaryEntriesCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getEntriesCount();
});

/// Provider para todas as tags (legado - use diaryTagsProvider)
@Deprecated('Use diaryTagsProvider instead')
final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getAllTags();
});

/// Provider para uma entrada específica (legado)
@Deprecated('Use singleDiaryEntryProvider instead')
final diaryEntryProvider =
    FutureProvider.family<DiaryEntry?, String>((ref, id) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getEntry(id);
});

// ============================================
// PROVIDERS MODERNOS (usar estes)
// ============================================

/// Provider para entradas do mês atual (para calendário)
final currentMonthEntriesProvider = FutureProvider<Map<DateTime, List<DiaryEntryEntity>>>((ref) async {
  final repository = ref.watch(syncedDiaryRepositoryProvider);
  final now = DateTime.now();
  final entries = await repository.getEntriesByMonth(now.year, now.month);

  final Map<DateTime, List<DiaryEntryEntity>> byDay = {};
  for (final entry in entries) {
    final key = DateTime(entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);
    byDay.putIfAbsent(key, () => []).add(entry);
  }

  return byDay;
});

/// Provider para entradas de um mês específico
final monthEntriesProvider = FutureProvider.family<Map<DateTime, List<DiaryEntryEntity>>, DateTime>((ref, month) async {
  final repository = ref.watch(syncedDiaryRepositoryProvider);
  final entries = await repository.getEntriesByMonth(month.year, month.month);

  final Map<DateTime, List<DiaryEntryEntity>> byDay = {};
  for (final entry in entries) {
    final key = DateTime(entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);
    byDay.putIfAbsent(key, () => []).add(entry);
  }

  return byDay;
});
