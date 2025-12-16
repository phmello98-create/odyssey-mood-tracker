// lib/src/features/diary/presentation/controllers/diary_state.dart

import 'package:flutter/foundation.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../../domain/entities/diary_statistics.dart';
import '../../domain/repositories/i_diary_repository.dart';

/// Modo de visualização do diário
enum DiaryViewMode {
  timeline,
  grid,
  calendar,
}

/// Estado principal do diário
@immutable
sealed class DiaryState {
  const DiaryState();
}

/// Estado inicial/loading
class DiaryStateInitial extends DiaryState {
  const DiaryStateInitial();
}

/// Estado de carregamento
class DiaryStateLoading extends DiaryState {
  final DiaryState? previousState;
  const DiaryStateLoading([this.previousState]);
}

/// Estado de sucesso com dados carregados
class DiaryStateLoaded extends DiaryState {
  final List<DiaryEntryEntity> entries;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final DiaryFilter filter;
  final DiaryViewMode viewMode;
  final DiaryStatistics? statistics;
  final List<String> allTags;
  final String? searchQuery;

  const DiaryStateLoaded({
    required this.entries,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.filter = const DiaryFilter(),
    this.viewMode = DiaryViewMode.timeline,
    this.statistics,
    this.allTags = const [],
    this.searchQuery,
  });

  DiaryStateLoaded copyWith({
    List<DiaryEntryEntity>? entries,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    DiaryFilter? filter,
    DiaryViewMode? viewMode,
    DiaryStatistics? statistics,
    List<String>? allTags,
    String? searchQuery,
  }) {
    return DiaryStateLoaded(
      entries: entries ?? this.entries,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filter: filter ?? this.filter,
      viewMode: viewMode ?? this.viewMode,
      statistics: statistics ?? this.statistics,
      allTags: allTags ?? this.allTags,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Verifica se está vazio (sem entradas)
  bool get isEmpty => entries.isEmpty;

  /// Verifica se há filtros ativos
  bool get hasActiveFilters => filter.hasFilters || (searchQuery != null && searchQuery!.isNotEmpty);
}

/// Estado de erro
class DiaryStateError extends DiaryState {
  final String message;
  final Exception? exception;
  final DiaryState? previousState;

  const DiaryStateError(
    this.message, {
    this.exception,
    this.previousState,
  });
}

/// Estado vazio (sem entradas)
class DiaryStateEmpty extends DiaryState {
  final bool hasFilters;
  const DiaryStateEmpty({this.hasFilters = false});
}

// ============================================
// ESTADO DO EDITOR
// ============================================

/// Estado de salvamento do editor
enum EditorSaveStatus {
  idle,
  saving,
  saved,
  error,
}

/// Estado do editor de diário
@immutable
class DiaryEditorState {
  final DiaryEntryEntity? entry;
  final bool isLoading;
  final bool hasUnsavedChanges;
  final EditorSaveStatus saveStatus;
  final String? saveError;
  final DateTime lastSavedAt;
  final String? selectedTemplateId;
  final bool isNewEntry;

  const DiaryEditorState({
    this.entry,
    this.isLoading = true,
    this.hasUnsavedChanges = false,
    this.saveStatus = EditorSaveStatus.idle,
    this.saveError,
    DateTime? lastSavedAt,
    this.selectedTemplateId,
    this.isNewEntry = true,
  }) : lastSavedAt = lastSavedAt ?? const _DefaultDateTime();

  DiaryEditorState copyWith({
    DiaryEntryEntity? entry,
    bool? isLoading,
    bool? hasUnsavedChanges,
    EditorSaveStatus? saveStatus,
    String? saveError,
    DateTime? lastSavedAt,
    String? selectedTemplateId,
    bool? isNewEntry,
  }) {
    return DiaryEditorState(
      entry: entry ?? this.entry,
      isLoading: isLoading ?? this.isLoading,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      saveStatus: saveStatus ?? this.saveStatus,
      saveError: saveError,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      isNewEntry: isNewEntry ?? this.isNewEntry,
    );
  }

  /// Verifica se pode sair sem salvar
  bool get canExitSafely => !hasUnsavedChanges || saveStatus == EditorSaveStatus.saved;

  /// Verifica se está salvando
  bool get isSaving => saveStatus == EditorSaveStatus.saving;

  /// Verifica se salvou com sucesso
  bool get isSaved => saveStatus == EditorSaveStatus.saved;
}

/// Classe auxiliar para DateTime padrão
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

// ============================================
// ESTADO DAS ESTATÍSTICAS
// ============================================

/// Estado das estatísticas
@immutable
sealed class DiaryStatsState {
  const DiaryStatsState();
}

class DiaryStatsLoading extends DiaryStatsState {
  const DiaryStatsLoading();
}

class DiaryStatsLoaded extends DiaryStatsState {
  final DiaryStatistics statistics;
  const DiaryStatsLoaded(this.statistics);
}

class DiaryStatsError extends DiaryStatsState {
  final String message;
  const DiaryStatsError(this.message);
}

// ============================================
// ESTADO DO CALENDÁRIO
// ============================================

/// Estado do calendário do diário
@immutable
class DiaryCalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<DiaryEntryEntity>> entriesByDay;
  final bool isLoading;

  const DiaryCalendarState({
    required this.focusedDay,
    this.selectedDay,
    this.entriesByDay = const {},
    this.isLoading = false,
  });

  DiaryCalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    Map<DateTime, List<DiaryEntryEntity>>? entriesByDay,
    bool? isLoading,
  }) {
    return DiaryCalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      entriesByDay: entriesByDay ?? this.entriesByDay,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Retorna as entradas do dia selecionado
  List<DiaryEntryEntity> get selectedDayEntries {
    if (selectedDay == null) return [];
    final key = DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day);
    return entriesByDay[key] ?? [];
  }

  /// Verifica se um dia tem entradas
  bool hasEntriesOn(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return entriesByDay.containsKey(key) && entriesByDay[key]!.isNotEmpty;
  }

  /// Conta entradas em um dia
  int countEntriesOn(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return entriesByDay[key]?.length ?? 0;
  }
}
