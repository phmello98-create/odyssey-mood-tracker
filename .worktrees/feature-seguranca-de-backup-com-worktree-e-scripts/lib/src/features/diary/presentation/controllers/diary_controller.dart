// lib/src/features/diary/presentation/controllers/diary_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../../domain/entities/diary_statistics.dart';
import '../../domain/repositories/i_diary_repository.dart';
import '../../data/synced_diary_repository.dart';
import 'diary_state.dart';

/// Controller principal do diário
class DiaryController extends StateNotifier<DiaryState> {
  final SyncedDiaryRepository _repository;

  static const int _pageSize = 20;
  Timer? _searchDebounce;

  DiaryController(this._repository) : super(const DiaryStateInitial()) {
    _init();
  }

  Future<void> _init() async {
    await loadEntries();
  }

  /// Carrega entradas com paginação e filtros
  Future<void> loadEntries({
    bool refresh = false,
    DiaryFilter? filter,
    DiaryViewMode? viewMode,
  }) async {
    final currentState = state;

    // Mantém o estado anterior durante o carregamento
    if (currentState is DiaryStateLoaded && !refresh) {
      state = DiaryStateLoading(currentState);
    } else {
      state = const DiaryStateLoading();
    }

    try {
      final effectiveFilter = filter ??
        (currentState is DiaryStateLoaded ? currentState.filter : const DiaryFilter());
      final effectiveViewMode = viewMode ??
        (currentState is DiaryStateLoaded ? currentState.viewMode : DiaryViewMode.timeline);

      final result = await _repository.getEntriesPaginated(
        page: 1,
        pageSize: _pageSize,
        filter: effectiveFilter,
      );

      final tags = await _repository.getAllTags();
      final stats = await _repository.getStatistics();

      if (result.entries.isEmpty) {
        state = DiaryStateEmpty(hasFilters: effectiveFilter.hasFilters);
      } else {
        state = DiaryStateLoaded(
          entries: result.entries,
          totalCount: result.totalCount,
          currentPage: 1,
          hasMore: result.hasMore,
          filter: effectiveFilter,
          viewMode: effectiveViewMode,
          statistics: stats,
          allTags: tags,
        );
      }
    } catch (e, stack) {
      debugPrint('[DiaryController] Error loading entries: $e\n$stack');
      state = DiaryStateError(
        'Erro ao carregar entradas',
        exception: e is Exception ? e : Exception(e.toString()),
        previousState: currentState is DiaryStateLoaded ? currentState : null,
      );
    }
  }

  /// Carrega mais entradas (paginação infinita)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! DiaryStateLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = currentState.copyWith(isLoadingMore: true);

    try {
      final nextPage = currentState.currentPage + 1;
      final result = await _repository.getEntriesPaginated(
        page: nextPage,
        pageSize: _pageSize,
        filter: currentState.filter,
      );

      state = currentState.copyWith(
        entries: [...currentState.entries, ...result.entries],
        currentPage: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('[DiaryController] Error loading more: $e');
      state = currentState.copyWith(isLoadingMore: false);
    }
  }

  /// Busca entradas com debounce
  void search(String query) {
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      // Limpa a busca imediatamente
      final currentState = state;
      if (currentState is DiaryStateLoaded) {
        loadEntries(
          filter: currentState.filter.copyWith(searchQuery: null),
        );
      } else {
        loadEntries();
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final currentState = state;
      if (currentState is DiaryStateLoaded) {
        loadEntries(
          filter: currentState.filter.copyWith(searchQuery: query),
        );
      } else {
        loadEntries(filter: DiaryFilter(searchQuery: query));
      }
    });
  }

  /// Aplica filtros
  Future<void> applyFilter(DiaryFilter filter) async {
    await loadEntries(filter: filter);
  }

  /// Limpa filtros
  Future<void> clearFilters() async {
    await loadEntries(filter: const DiaryFilter());
  }

  /// Muda o modo de visualização
  void setViewMode(DiaryViewMode mode) {
    final currentState = state;
    if (currentState is DiaryStateLoaded) {
      state = currentState.copyWith(viewMode: mode);
    }
  }

  /// Cria uma nova entrada
  Future<DiaryEntryEntity?> createEntry(DiaryEntryEntity entry) async {
    try {
      final created = await _repository.createEntry(entry);
      debugPrint('[DiaryController] Created entry: ${created.id}');

      // Recarrega a lista
      await loadEntries(refresh: true);

      return created;
    } catch (e) {
      debugPrint('[DiaryController] Error creating entry: $e');
      return null;
    }
  }

  /// Atualiza uma entrada existente
  Future<DiaryEntryEntity?> updateEntry(DiaryEntryEntity entry) async {
    try {
      final updated = await _repository.updateEntry(entry);
      debugPrint('[DiaryController] Updated entry: ${updated.id}');

      // Atualiza na lista local
      final currentState = state;
      if (currentState is DiaryStateLoaded) {
        final updatedEntries = currentState.entries.map((e) {
          return e.id == updated.id ? updated : e;
        }).toList();

        state = currentState.copyWith(entries: updatedEntries);
      }

      return updated;
    } catch (e) {
      debugPrint('[DiaryController] Error updating entry: $e');
      return null;
    }
  }

  /// Deleta uma entrada
  Future<bool> deleteEntry(String id) async {
    try {
      await _repository.deleteEntry(id);
      debugPrint('[DiaryController] Deleted entry: $id');

      // Remove da lista local
      final currentState = state;
      if (currentState is DiaryStateLoaded) {
        final updatedEntries = currentState.entries
            .where((e) => e.id != id)
            .toList();

        if (updatedEntries.isEmpty && !currentState.hasActiveFilters) {
          state = const DiaryStateEmpty();
        } else {
          state = currentState.copyWith(
            entries: updatedEntries,
            totalCount: currentState.totalCount - 1,
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('[DiaryController] Error deleting entry: $e');
      return false;
    }
  }

  /// Toggle favorito
  Future<void> toggleStarred(String id) async {
    try {
      final updated = await _repository.toggleStarred(id);
      if (updated == null) return;

      // Atualiza na lista local
      final currentState = state;
      if (currentState is DiaryStateLoaded) {
        final updatedEntries = currentState.entries.map((e) {
          return e.id == id ? updated : e;
        }).toList();

        // Se filtrando por favoritos, remove da lista
        if (currentState.filter.starred == true && !updated.starred) {
          state = currentState.copyWith(
            entries: updatedEntries.where((e) => e.starred).toList(),
          );
        } else {
          state = currentState.copyWith(entries: updatedEntries);
        }
      }
    } catch (e) {
      debugPrint('[DiaryController] Error toggling starred: $e');
    }
  }

  /// Retorna uma entrada por ID
  Future<DiaryEntryEntity?> getEntry(String id) async {
    return await _repository.getEntry(id);
  }

  /// Retorna estatísticas
  Future<DiaryStatistics> getStatistics() async {
    return await _repository.getStatistics();
  }

  /// Retorna entradas "neste dia" de anos anteriores
  Future<List<DiaryEntryEntity>> getOnThisDayEntries() async {
    return await _repository.getOnThisDayEntries(DateTime.now());
  }

  /// Exporta entradas como JSON
  Future<String> exportAsJson({List<String>? entryIds}) async {
    return await _repository.exportAsJson(entryIds: entryIds);
  }

  /// Exporta entradas como Markdown
  Future<String> exportAsMarkdown({List<String>? entryIds}) async {
    return await _repository.exportAsMarkdown(entryIds: entryIds);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

/// Provider para o DiaryController
final diaryControllerProvider = StateNotifierProvider<DiaryController, DiaryState>((ref) {
  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return DiaryController(repository);
});

/// Provider para estatísticas do diário com cache
final diaryStatisticsProvider = FutureProvider.autoDispose<DiaryStatistics>((ref) async {
  // Keep alive for 5 minutes to avoid recalculating stats frequently
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return await repository.getStatistics();
});

/// Provider para entradas "neste dia" com cache
final onThisDayEntriesProvider = FutureProvider.autoDispose<List<DiaryEntryEntity>>((ref) async {
  // Keep alive for 1 hour - these entries don't change frequently
  final link = ref.keepAlive();
  final timer = Timer(const Duration(hours: 1), link.close);
  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return await repository.getOnThisDayEntries(DateTime.now());
});

/// Provider para todas as tags com cache
final diaryTagsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  // Keep alive for 10 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 10), link.close);
  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return await repository.getAllTags();
});

/// Provider para uma entrada específica com cache
final singleDiaryEntryProvider = FutureProvider.autoDispose.family<DiaryEntryEntity?, String>((ref, id) async {
  // Keep alive for 2 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 2), link.close);
  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return await repository.getEntry(id);
});

/// Provider para entradas de uma data específica com cache
final entriesByDateProvider = FutureProvider.autoDispose.family<List<DiaryEntryEntity>, DateTime>((ref, date) async {
  // Keep alive for 5 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return await repository.getEntriesByDate(date);
});
