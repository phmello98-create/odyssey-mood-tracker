// lib/src/features/library/data/synced_book_repository.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/library/data/book_repository.dart';
import 'package:odyssey/src/features/library/domain/book.dart';
import 'package:odyssey/src/features/auth/services/synced_repository_mixin.dart';

/// Repository wrapper que adiciona sincronização automática via fila offline
class SyncedBookRepository with SyncedRepositoryMixin {
  final BookRepository _localRepository;
  @override
  final Ref ref;
  
  @override
  String get collectionName => 'books';
  
  SyncedBookRepository(this._localRepository, this.ref);
  
  /// Inicializa o repositório
  Future<void> initialize() => _localRepository.initialize();
  
  bool get isInitialized => _localRepository.isInitialized;
  
  /// Acesso ao box Hive para ValueListenableBuilder
  Box<Book> get box => _localRepository.box;
  
  // ============================================
  // MÉTODOS DE ESCRITA (com sync)
  // ============================================
  
  /// Adiciona um livro e enfileira para sync
  Future<String> addBook(Book book) async {
    final result = await _localRepository.addBook(book);
    await enqueueCreate(book.id, _bookToMap(book));
    return result;
  }
  
  /// Atualiza um livro e enfileira para sync
  Future<void> updateBook(Book book) async {
    await _localRepository.updateBook(book);
    await enqueueUpdate(book.id, _bookToMap(book));
  }
  
  /// Deleta um livro (soft delete) e enfileira para sync
  Future<void> deleteBook(String id) async {
    await _localRepository.deleteBook(id);
    final book = _localRepository.getBook(id);
    if (book != null) {
      await enqueueUpdate(id, _bookToMap(book));
    }
  }
  
  /// Deleta permanentemente um livro e enfileira para sync
  Future<void> permanentlyDeleteBook(String id) async {
    await _localRepository.permanentlyDeleteBook(id);
    await enqueueDelete(id);
  }
  
  /// Restaura um livro deletado e enfileira para sync
  Future<void> restoreBook(String id) async {
    await _localRepository.restoreBook(id);
    final book = _localRepository.getBook(id);
    if (book != null) {
      await enqueueUpdate(id, _bookToMap(book));
    }
  }
  
  /// Atualiza o progresso de leitura e enfileira para sync
  Future<void> updateProgress(String bookId, int currentPage) async {
    await _localRepository.updateProgress(bookId, currentPage);
    final book = _localRepository.getBook(bookId);
    if (book != null) {
      await enqueueUpdate(bookId, _bookToMap(book));
    }
  }
  
  /// Alterna favorito e enfileira para sync
  Future<void> toggleFavourite(String bookId) async {
    await _localRepository.toggleFavourite(bookId);
    final book = _localRepository.getBook(bookId);
    if (book != null) {
      await enqueueUpdate(bookId, _bookToMap(book));
    }
  }
  
  /// Muda o status do livro e enfileira para sync
  Future<void> changeStatus(String bookId, BookStatus newStatus) async {
    await _localRepository.changeStatus(bookId, newStatus);
    final book = _localRepository.getBook(bookId);
    if (book != null) {
      await enqueueUpdate(bookId, _bookToMap(book));
    }
  }
  
  /// Adiciona tempo de leitura e enfileira para sync
  Future<void> addReadingTime(String bookId, int seconds) async {
    await _localRepository.addReadingTime(bookId, seconds);
    final book = _localRepository.getBook(bookId);
    if (book != null) {
      await enqueueUpdate(bookId, _bookToMap(book));
    }
  }
  
  /// Atualiza highlights e enfileira para sync
  Future<void> updateHighlights(String bookId, String highlights) async {
    await _localRepository.updateHighlights(bookId, highlights);
    final book = _localRepository.getBook(bookId);
    if (book != null) {
      await enqueueUpdate(bookId, _bookToMap(book));
    }
  }
  
  /// Salva capa do livro (local apenas, não sincroniza arquivo)
  Future<String?> saveCover(String bookId, Uint8List coverBytes) async {
    final result = await _localRepository.saveCover(bookId, coverBytes);
    // TODO: Usar CloudStorageService para sincronizar capa
    return result;
  }
  
  // ============================================
  // MÉTODOS DE LEITURA (não precisam de sync)
  // ============================================
  
  Book? getBook(String id) => _localRepository.getBook(id);
  
  List<Book> getAllBooks({bool includeDeleted = false}) => 
      _localRepository.getAllBooks(includeDeleted: includeDeleted);
  
  List<Book> getBooksByStatus(BookStatus status) => 
      _localRepository.getBooksByStatus(status);
  
  List<Book> getFinishedBooks() => _localRepository.getFinishedBooks();
  List<Book> getInProgressBooks() => _localRepository.getInProgressBooks();
  List<Book> getForLaterBooks() => _localRepository.getForLaterBooks();
  List<Book> getUnfinishedBooks() => _localRepository.getUnfinishedBooks();
  List<Book> getDeletedBooks() => _localRepository.getDeletedBooks();
  List<Book> getFavouriteBooks() => _localRepository.getFavouriteBooks();
  
  int get totalBooks => _localRepository.totalBooks;
  int get totalPagesRead => _localRepository.totalPagesRead;
  int get totalBooksRead => _localRepository.totalBooksRead;
  int get totalBooksReading => _localRepository.totalBooksReading;
  
  Map<int, int> getBooksPerYear() => _localRepository.getBooksPerYear();
  List<String> getAllTags() => _localRepository.getAllTags();
  List<String> getAllAuthors() => _localRepository.getAllAuthors();
  List<String> getAllGenres() => _localRepository.getAllGenres();
  
  List<Book> searchBooks(String query) => _localRepository.searchBooks(query);
  
  // ============================================
  // CONVERSÃO
  // ============================================
  
  Map<String, dynamic> _bookToMap(Book book) {
    return {
      'id': book.id,
      'title': book.title,
      'subtitle': book.subtitle,
      'author': book.author,
      'description': book.description,
      'statusIndex': book.statusIndex,
      'favourite': book.favourite,
      'deleted': book.deleted,
      'rating': book.rating,
      'pages': book.pages,
      'publicationYear': book.publicationYear,
      'isbn': book.isbn,
      'olid': book.olid,
      'tags': book.tags,
      'myReview': book.myReview,
      'notes': book.notes,
      'blurHash': book.blurHash,
      'formatIndex': book.formatIndex,
      'hasCover': book.hasCover,
      'readingsData': book.readingsData,
      'dateAdded': book.dateAdded.toIso8601String(),
      'dateModified': book.dateModified.toIso8601String(),
      'currentPage': book.currentPage,
      'coverPath': book.coverPath,
      'genre': book.genre,
      'highlights': book.highlights,
      'totalReadingTimeSeconds': book.totalReadingTimeSeconds,
      '_localModifiedAt': book.dateModified.toIso8601String(),
    };
  }
}

/// Provider para o SyncedBookRepository
final syncedBookRepositoryProvider = Provider<SyncedBookRepository>((ref) {
  final localRepository = ref.watch(bookRepositoryProvider);
  return SyncedBookRepository(localRepository, ref);
});
