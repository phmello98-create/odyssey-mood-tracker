// lib/src/features/notes/data/synced_quotes_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/quote.dart';
import 'quotes_repository.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline para citações (Isar version)
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
  Future<void> addQuote(Quote quote) async {
    await _localRepository.addQuote(quote);
    await enqueueCreate(quote.id.toString(), _quoteToMap(quote));
  }

  /// Atualiza uma citação e enfileira para sync
  Future<void> updateQuote(Quote quote) async {
    await _localRepository.updateQuote(quote);
    await enqueueUpdate(quote.id.toString(), _quoteToMap(quote));
  }

  /// Deleta uma citação e enfileira para sync
  Future<void> deleteQuote(int id) async {
    await _localRepository.deleteQuote(id);
    await enqueueDelete(id.toString());
  }

  /// Alterna favorito de uma citação e enfileira para sync
  Future<void> toggleFavorite(int id) async {
    await _localRepository.toggleFavorite(id);
    final quote = await _localRepository.getQuote(id);
    if (quote != null) {
      await enqueueUpdate(id.toString(), _quoteToMap(quote));
    }
  }

  /// Adiciona citações de exemplo se o banco estiver vazio
  Future<void> addSampleQuotesIfEmpty() async {
    await _localRepository.addSampleQuotesIfEmpty();
  }

  // ============================================
  // MÉTODOS DE LEITURA (não precisam de sync)
  // ============================================

  Future<Quote?> getQuote(int id) => _localRepository.getQuote(id);

  Future<List<Quote>> getAllQuotes() => _localRepository.getAllQuotes();

  Future<List<Quote>> getFavoriteQuotes() =>
      _localRepository.getFavoriteQuotes();

  Future<List<Quote>> searchQuotes(String query) =>
      _localRepository.searchQuotes(query);

  Stream<List<Quote>> watchQuotes() => _localRepository.watchQuotes();

  bool get isInitialized => _localRepository.isInitialized;

  // ============================================
  // CONVERSÃO
  // ============================================

  Map<String, dynamic> _quoteToMap(Quote quote) {
    return {
      'id': quote.id.toString(),
      'text': quote.text,
      'author': quote.author,
      'category': quote.category,
      'isFavorite': quote.isFavorite,
      'createdAt': quote.createdAt.toIso8601String(),
      'source': quote.source,
      '_localModifiedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider para o SyncedQuotesRepository
final syncedQuotesRepositoryProvider = Provider<SyncedQuotesRepository>((ref) {
  final localRepository = ref.watch(quotesRepositoryProvider);
  return SyncedQuotesRepository(localRepository, ref);
});
