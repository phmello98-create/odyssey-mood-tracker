import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/diary_entry_isar.dart';
import '../../data/repositories/diary_isar_repository.dart';

final diaryIsarStreamProvider =
    StreamProvider.autoDispose<List<DiaryEntryIsar>>((ref) {
      final repository = ref.watch(diaryIsarRepositoryProvider);
      return repository.watchAll();
    });

// Provider para filtrar favoritos (futuro)
final diaryIsarStarredStreamProvider =
    StreamProvider.autoDispose<List<DiaryEntryIsar>>((ref) {
      final repository = ref.read(diaryIsarRepositoryProvider);
      // Isar repo watchAll já retorna todos, filtrar no client ou criar query especifica no repo
      // Vou criar um provider filtrado no client por enquanto para simplificar
      return repository.watchAll().map(
        (list) => list.where((e) => e.isStarred).toList(),
      );
    });

// ====================================
// PROVIDERS DE BUSCA
// ====================================

/// Provider para a query de busca atual
final diarySearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider para controlar se a barra de busca está expandida/ativa
final diarySearchExpandedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Provider para resultados da busca (usa o repository search method)
final diarySearchResultsProvider =
    FutureProvider.autoDispose<List<DiaryEntryIsar>>((ref) async {
      final query = ref.watch(diarySearchQueryProvider);
      final repository = ref.watch(diaryIsarRepositoryProvider);

      if (query.isEmpty || query.length < 2) {
        return <DiaryEntryIsar>[];
      }

      return repository.search(query);
    });

/// Provider combinado que retorna entradas filtradas baseado na busca
/// Se não há busca ativa, retorna todas as entradas
final diaryFilteredEntriesProvider =
    Provider.autoDispose<AsyncValue<List<DiaryEntryIsar>>>((ref) {
      final query = ref.watch(diarySearchQueryProvider);

      if (query.isEmpty || query.length < 2) {
        // Sem busca, retorna stream normal
        return ref.watch(diaryIsarStreamProvider);
      } else {
        // Com busca ativa, retorna resultados da pesquisa
        return ref.watch(diarySearchResultsProvider);
      }
    });
