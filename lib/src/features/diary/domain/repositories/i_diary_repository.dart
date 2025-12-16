// lib/src/features/diary/domain/repositories/i_diary_repository.dart

import '../entities/diary_entry_entity.dart';
import '../entities/diary_statistics.dart';

/// Resultado de uma operação que pode falhar
sealed class DiaryResult<T> {
  const DiaryResult();
}

class DiarySuccess<T> extends DiaryResult<T> {
  final T data;
  const DiarySuccess(this.data);
}

class DiaryFailure<T> extends DiaryResult<T> {
  final String message;
  final Exception? exception;
  const DiaryFailure(this.message, [this.exception]);
}

/// Opções de ordenação
enum DiarySortOrder {
  newestFirst,
  oldestFirst,
  alphabetical,
}

/// Opções de filtro
class DiaryFilter {
  final String? searchQuery;
  final List<String>? tags;
  final String? feeling;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? starred;
  final DiarySortOrder sortOrder;

  const DiaryFilter({
    this.searchQuery,
    this.tags,
    this.feeling,
    this.startDate,
    this.endDate,
    this.starred,
    this.sortOrder = DiarySortOrder.newestFirst,
  });

  DiaryFilter copyWith({
    String? searchQuery,
    List<String>? tags,
    String? feeling,
    DateTime? startDate,
    DateTime? endDate,
    bool? starred,
    DiarySortOrder? sortOrder,
  }) {
    return DiaryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      tags: tags ?? this.tags,
      feeling: feeling ?? this.feeling,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      starred: starred ?? this.starred,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get hasFilters =>
    searchQuery != null ||
    tags != null ||
    feeling != null ||
    startDate != null ||
    endDate != null ||
    starred != null;

  DiaryFilter clearFilters() => const DiaryFilter();
}

/// Resultado paginado
class PaginatedEntries {
  final List<DiaryEntryEntity> entries;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasMore;

  const PaginatedEntries({
    required this.entries,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedEntries.empty() => const PaginatedEntries(
    entries: [],
    totalCount: 0,
    currentPage: 1,
    pageSize: 20,
    hasMore: false,
  );
}

/// Interface abstrata para o repository de diário
abstract class IDiaryRepository {
  /// Inicializa o repositório
  Future<void> init();

  /// Libera recursos
  Future<void> dispose();

  // ============================================
  // OPERAÇÕES DE LEITURA
  // ============================================

  /// Retorna todas as entradas
  Future<List<DiaryEntryEntity>> getAllEntries();

  /// Retorna entradas paginadas com filtros opcionais
  Future<PaginatedEntries> getEntriesPaginated({
    int page = 1,
    int pageSize = 20,
    DiaryFilter? filter,
  });

  /// Retorna uma entrada específica por ID
  Future<DiaryEntryEntity?> getEntry(String id);

  /// Retorna entradas de um ano específico
  Future<List<DiaryEntryEntity>> getEntriesByYear(int year);

  /// Retorna entradas de um mês específico
  Future<List<DiaryEntryEntity>> getEntriesByMonth(int year, int month);

  /// Retorna entradas de uma data específica
  Future<List<DiaryEntryEntity>> getEntriesByDate(DateTime date);

  /// Busca entradas por texto
  Future<List<DiaryEntryEntity>> searchEntries(String query);

  /// Retorna entradas marcadas como favoritas
  Future<List<DiaryEntryEntity>> getStarredEntries();

  /// Retorna entradas com um sentimento específico
  Future<List<DiaryEntryEntity>> getEntriesByFeeling(String feeling);

  /// Retorna entradas com uma tag específica
  Future<List<DiaryEntryEntity>> getEntriesByTag(String tag);

  /// Retorna entradas "neste dia" de anos anteriores
  Future<List<DiaryEntryEntity>> getOnThisDayEntries(DateTime date);

  /// Retorna a contagem total de entradas
  Future<int> getEntriesCount();

  /// Retorna todas as tags únicas usadas
  Future<List<String>> getAllTags();

  /// Retorna estatísticas do diário
  Future<DiaryStatistics> getStatistics();

  // ============================================
  // OPERAÇÕES DE ESCRITA
  // ============================================

  /// Cria uma nova entrada
  Future<DiaryEntryEntity> createEntry(DiaryEntryEntity entry);

  /// Atualiza uma entrada existente
  Future<DiaryEntryEntity> updateEntry(DiaryEntryEntity entry);

  /// Deleta uma entrada
  Future<void> deleteEntry(String id);

  /// Alterna o status de favorito de uma entrada
  Future<DiaryEntryEntity?> toggleStarred(String id);

  /// Adiciona uma tag a uma entrada
  Future<DiaryEntryEntity?> addTag(String id, String tag);

  /// Remove uma tag de uma entrada
  Future<DiaryEntryEntity?> removeTag(String id, String tag);

  /// Adiciona uma foto a uma entrada
  Future<DiaryEntryEntity?> addPhoto(String id, String photoId);

  /// Remove uma foto de uma entrada
  Future<DiaryEntryEntity?> removePhoto(String id, String photoId);

  // ============================================
  // EXPORTAÇÃO
  // ============================================

  /// Exporta entradas como JSON
  Future<String> exportAsJson({List<String>? entryIds});

  /// Exporta entradas como Markdown
  Future<String> exportAsMarkdown({List<String>? entryIds});
}
