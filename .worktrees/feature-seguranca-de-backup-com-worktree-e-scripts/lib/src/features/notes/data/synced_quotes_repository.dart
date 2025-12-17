// lib/src/features/notes/data/synced_quotes_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'quotes_repository.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline para citações
class SyncedQuotesRepository with SyncedRepositoryMixin {
  final QuotesRepository _localRepository;
  @override
  final Ref ref;
  
  @override
  String get collectionName => 'quotes';
  
  SyncedQuotesRepository(this._localRepository, this.ref);
  
  /// Inicializa o repositório
  Future<void> initialize() => _localRepository.initialize();
  
  // ============================================
  // MÉTODOS DE ESCRITA (com sync)
  // ============================================
  
  /// Adiciona uma citação e enfileira para sync
  Future<String> addQuote(Map<String, dynamic> quoteData) async {
    final quoteId = await _localRepository.addQuote(quoteData);
    await enqueueCreate(quoteId, _quoteToMap(quoteData, quoteId));
    return quoteId;
  }
  
  /// Atualiza uma citação e enfileira para sync
  Future<void> updateQuote(String quoteId, Map<String, dynamic> quoteData) async {
    await _localRepository.updateQuote(quoteId, quoteData);
    await enqueueUpdate(quoteId, _quoteToMap(quoteData, quoteId));
  }
  
  /// Deleta uma citação e enfileira para sync
  Future<void> deleteQuote(String quoteId) async {
    await _localRepository.deleteQuote(quoteId);
    await enqueueDelete(quoteId);
  }
  
  /// Alterna favorito de uma citação e enfileira para sync
  Future<void> toggleFavorite(String quoteId) async {
    await _localRepository.toggleFavorite(quoteId);
    final quote = _localRepository.getQuote(quoteId);
    if (quote != null) {
      await enqueueUpdate(quoteId, _quoteToMap(quote, quoteId));
    }
  }
  
  /// Adiciona citações de exemplo se o box estiver vazio
  Future<void> addSampleQuotesIfEmpty() async {
    await _localRepository.addSampleQuotesIfEmpty();
    // Não precisa sync porque são dados de exemplo
  }
  
  // ============================================
  // MÉTODOS DE LEITURA (não precisam de sync)
  // ============================================
  
  Map<String, dynamic>? getQuote(String quoteId) => _localRepository.getQuote(quoteId);
  
  List<Map<String, dynamic>> getAllQuotes() => _localRepository.getAllQuotes();
  
  List<Map<String, dynamic>> getFavoriteQuotes() => _localRepository.getFavoriteQuotes();
  
  List<Map<String, dynamic>> getNonFavoriteQuotes() => _localRepository.getNonFavoriteQuotes();
  
  List<Map<String, dynamic>> searchQuotes(String query) => _localRepository.searchQuotes(query);
  
  List<Map<String, dynamic>> getQuotesByCategory(String category) => _localRepository.getQuotesByCategory(category);
  
  bool get isInitialized => _localRepository.isInitialized;
  
  /// Expõe o box para uso com ValueListenableBuilder
  Box? get box => _localRepository.box;
  
  // ============================================
  // CONVERSÃO
  // ============================================
  
  Map<String, dynamic> _quoteToMap(Map<String, dynamic> quoteData, String quoteId) {
    return {
      ...quoteData,
      'id': quoteId,
      '_localModifiedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider para o SyncedQuotesRepository
final syncedQuotesRepositoryProvider = Provider<SyncedQuotesRepository>((ref) {
  final localRepository = ref.watch(quotesRepositoryProvider);
  return SyncedQuotesRepository(localRepository, ref);
});
