// lib/src/features/notes/data/quotes_repository.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Repositório para gerenciar citações/frases no Hive
class QuotesRepository {
  static const String _boxName = 'quotes';
  Box? _box;
  bool _initialized = false;

  Box? get box => _box;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await Hive.openBox(_boxName);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing QuotesRepository: $e');
      rethrow;
    }
  }

  // CRUD Operations

  Future<String> addQuote(Map<String, dynamic> quoteData) async {
    await _ensureInitialized();
    final quoteId = quoteData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    quoteData['id'] = quoteId;
    quoteData['createdAt'] ??= DateTime.now().toIso8601String();
    await _box!.put(quoteId, quoteData);
    return quoteId;
  }

  Future<void> updateQuote(String quoteId, Map<String, dynamic> quoteData) async {
    await _ensureInitialized();
    await _box!.put(quoteId, quoteData);
  }

  Future<void> deleteQuote(String quoteId) async {
    await _ensureInitialized();
    await _box!.delete(quoteId);
  }

  Map<String, dynamic>? getQuote(String quoteId) {
    if (!_initialized || _box == null) return null;
    final data = _box!.get(quoteId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  List<Map<String, dynamic>> getAllQuotes() {
    if (!_initialized || _box == null) return [];
    return _box!.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  List<Map<String, dynamic>> getFavoriteQuotes() {
    return getAllQuotes().where((quote) => quote['isFavorite'] == true).toList();
  }

  List<Map<String, dynamic>> getNonFavoriteQuotes() {
    return getAllQuotes().where((quote) => quote['isFavorite'] != true).toList();
  }

  Future<void> toggleFavorite(String quoteId) async {
    await _ensureInitialized();
    final quote = getQuote(quoteId);
    if (quote != null) {
      quote['isFavorite'] = !(quote['isFavorite'] ?? false);
      await updateQuote(quoteId, quote);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // Search
  List<Map<String, dynamic>> searchQuotes(String query) {
    if (query.isEmpty) return getAllQuotes();
    
    final lowerQuery = query.toLowerCase();
    return getAllQuotes().where((quote) {
      final text = (quote['text'] ?? '').toString().toLowerCase();
      final author = (quote['author'] ?? '').toString().toLowerCase();
      return text.contains(lowerQuery) || author.contains(lowerQuery);
    }).toList();
  }

  // Quotes by category
  List<Map<String, dynamic>> getQuotesByCategory(String category) {
    return getAllQuotes().where((quote) => quote['category'] == category).toList();
  }

  // Add sample quotes if box is empty
  Future<void> addSampleQuotesIfEmpty() async {
    await _ensureInitialized();
    if (_box!.isEmpty) {
      final sampleQuotes = [
        {'id': '1', 'text': 'A única maneira de fazer um excelente trabalho é amar o que você faz.', 'author': 'Steve Jobs', 'category': 'motivational', 'isFavorite': true},
        {'id': '2', 'text': 'O sucesso é a soma de pequenos esforços repetidos dia após dia.', 'author': 'Robert Collier', 'category': 'motivational', 'isFavorite': false},
        {'id': '3', 'text': 'Conhece-te a ti mesmo.', 'author': 'Sócrates', 'category': 'philosophical', 'isFavorite': true},
        {'id': '4', 'text': 'A vida é o que acontece enquanto você está ocupado fazendo outros planos.', 'author': 'John Lennon', 'category': 'philosophical', 'isFavorite': true},
        {'id': '5', 'text': 'Seja a mudança que você deseja ver no mundo.', 'author': 'Mahatma Gandhi', 'category': 'motivational', 'isFavorite': true},
        {'id': '6', 'text': 'A imaginação é mais importante que o conhecimento.', 'author': 'Albert Einstein', 'category': 'philosophical', 'isFavorite': false},
        {'id': '7', 'text': 'Não é a mais forte das espécies que sobrevive, nem a mais inteligente, mas a que melhor se adapta às mudanças.', 'author': 'Charles Darwin', 'category': 'philosophical', 'isFavorite': true},
        {'id': '8', 'text': 'O medo de sofrer é pior que o próprio sofrimento.', 'author': 'Paulo Coelho', 'category': 'philosophical', 'isFavorite': false},
        {'id': '9', 'text': 'A persistência é o caminho do êxito.', 'author': 'Charlie Chaplin', 'category': 'motivational', 'isFavorite': true},
        {'id': '10', 'text': 'Tudo o que temos de decidir é o que fazer com o tempo que nos é dado.', 'author': 'J.R.R. Tolkien', 'category': 'philosophical', 'isFavorite': true},
        {'id': '11', 'text': 'Nada do que é humano me é estranho.', 'author': 'Terêncio', 'category': 'philosophical', 'isFavorite': false},
        {'id': '12', 'text': 'O homem é aquilo que ele faz de si mesmo.', 'author': 'Jean-Paul Sartre', 'category': 'philosophical', 'isFavorite': true},
      ];
      
      for (final quote in sampleQuotes) {
        await _box!.put(quote['id'], {
          ...quote,
          'createdAt': DateTime.now().subtract(Duration(days: int.parse(quote['id'] as String))).toIso8601String(),
        });
      }
    }
  }
}

/// Provider para o repositório de citações
final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return QuotesRepository();
});
