import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/book.dart';

/// Repositório para gerenciar livros no Hive
class BookRepository {
  static const String _boxName = 'books_v3';
  late Box<Book> _box;
  bool _initialized = false;

  Box<Book> get box => _box;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box<Book>(_boxName);
      } else {
        _box = await Hive.openBox<Book>(_boxName);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing BookRepository: $e');
      rethrow;
    }
  }

  // CRUD Operations

  Future<String> addBook(Book book) async {
    await _box.put(book.id, book);
    return book.id;
  }

  Future<void> updateBook(Book book) async {
    await _box.put(book.id, book.copyWith(dateModified: DateTime.now()));
  }

  Future<void> deleteBook(String id) async {
    final book = _box.get(id);
    if (book != null) {
      // Soft delete
      await _box.put(id, book.copyWith(deleted: true, dateModified: DateTime.now()));
    }
  }

  Future<void> permanentlyDeleteBook(String id) async {
    await _box.delete(id);
    // Also delete cover file if exists
    await _deleteCoverFile(id);
  }

  Future<void> restoreBook(String id) async {
    final book = _box.get(id);
    if (book != null) {
      await _box.put(id, book.copyWith(deleted: false, dateModified: DateTime.now()));
    }
  }

  Book? getBook(String id) {
    return _box.get(id);
  }

  List<Book> getAllBooks({bool includeDeleted = false}) {
    final books = _box.values.toList();
    if (includeDeleted) return books;
    return books.where((b) => !b.deleted).toList();
  }

  // Filtered queries

  List<Book> getBooksByStatus(BookStatus status) {
    return getAllBooks().where((b) => b.status == status).toList();
  }

  List<Book> getFinishedBooks() => getBooksByStatus(BookStatus.read);
  List<Book> getInProgressBooks() => getBooksByStatus(BookStatus.inProgress);
  List<Book> getForLaterBooks() => getBooksByStatus(BookStatus.forLater);
  List<Book> getUnfinishedBooks() => getBooksByStatus(BookStatus.unfinished);
  List<Book> getDeletedBooks() => _box.values.where((b) => b.deleted).toList();
  List<Book> getFavouriteBooks() => getAllBooks().where((b) => b.favourite).toList();

  // Statistics

  int get totalBooks => getAllBooks().length;
  int get totalPagesRead {
    return getAllBooks().fold(0, (sum, book) {
      if (book.status == BookStatus.read) {
        return sum + (book.pages ?? 0);
      } else {
        return sum + book.currentPage;
      }
    });
  }

  int get totalBooksRead => getFinishedBooks().length;
  int get totalBooksReading => getInProgressBooks().length;

  Map<int, int> getBooksPerYear() {
    final books = getFinishedBooks();
    final Map<int, int> yearCounts = {};
    
    for (final book in books) {
      final finishDate = book.latestFinishDate;
      if (finishDate != null) {
        final year = finishDate.year;
        yearCounts[year] = (yearCounts[year] ?? 0) + 1;
      }
    }
    return yearCounts;
  }

  List<String> getAllTags() {
    final Set<String> tags = {};
    for (final book in getAllBooks()) {
      tags.addAll(book.tagsList);
    }
    return tags.toList()..sort();
  }

  List<String> getAllAuthors() {
    final Set<String> authors = {};
    for (final book in getAllBooks()) {
      if (book.author.isNotEmpty) {
        authors.add(book.author);
      }
    }
    return authors.toList()..sort();
  }

  List<String> getAllGenres() {
    final Set<String> genres = {};
    for (final book in getAllBooks()) {
      if (book.genre != null && book.genre!.isNotEmpty) {
        genres.add(book.genre!);
      }
    }
    return genres.toList()..sort();
  }

  // Cover management

  Future<String> _getCoversDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${appDir.path}/book_covers');
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    return coversDir.path;
  }

  Future<String?> saveCover(String bookId, Uint8List coverBytes) async {
    try {
      final coversDir = await _getCoversDirectory();
      final coverPath = '$coversDir/$bookId.jpg';
      final file = File(coverPath);
      await file.writeAsBytes(coverBytes);
      return coverPath;
    } catch (e) {
      debugPrint('Error saving cover: $e');
      return null;
    }
  }

  Future<void> _deleteCoverFile(String bookId) async {
    try {
      final coversDir = await _getCoversDirectory();
      final coverPath = '$coversDir/$bookId.jpg';
      final file = File(coverPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting cover: $e');
    }
  }

  File? getCoverFile(String bookId) {
    final book = getBook(bookId);
    if (book?.coverPath != null) {
      final file = File(book!.coverPath!);
      if (file.existsSync()) {
        return file;
      }
    }
    return null;
  }

  // Progress update

  Future<void> updateProgress(String bookId, int currentPage) async {
    final book = getBook(bookId);
    if (book != null) {
      var newStatus = book.status;
      DateTime? finishDate;
      
      // Auto-change status based on progress
      if (currentPage > 0 && book.status == BookStatus.forLater) {
        newStatus = BookStatus.inProgress;
      }
      if (book.pages != null && currentPage >= book.pages!) {
        newStatus = BookStatus.read;
        finishDate = DateTime.now();
      }

      // Update reading period if finishing
      String? newReadingsData = book.readingsData;
      if (newStatus == BookStatus.read && book.status != BookStatus.read) {
        final readings = book.readings;
        if (readings.isEmpty) {
          readings.add(ReadingPeriod(finishDate: finishDate));
        } else {
          final lastReading = readings.last;
          readings[readings.length - 1] = lastReading.copyWith(finishDate: finishDate);
        }
        newReadingsData = readings.map((r) => r.toString()).join(';');
      }

      await updateBook(book.copyWith(
        currentPage: currentPage,
        statusIndex: newStatus.index,
        readingsData: newReadingsData,
      ));
    }
  }

  // Toggle favourite

  Future<void> toggleFavourite(String bookId) async {
    final book = getBook(bookId);
    if (book != null) {
      await updateBook(book.copyWith(favourite: !book.favourite));
    }
  }

  // Change book status
  Future<void> changeStatus(String bookId, BookStatus newStatus) async {
    final book = getBook(bookId);
    if (book != null) {
      String? newReadingsData = book.readingsData;
      
      // If starting to read (moving to inProgress), add start date
      if (newStatus == BookStatus.inProgress && book.status == BookStatus.forLater) {
        final readings = book.readings;
        readings.add(ReadingPeriod(startDate: DateTime.now()));
        newReadingsData = readings.map((r) => r.toString()).join(';');
      }
      
      // If finishing (moving to read), add finish date
      if (newStatus == BookStatus.read && book.status != BookStatus.read) {
        final readings = book.readings;
        if (readings.isEmpty) {
          readings.add(ReadingPeriod(finishDate: DateTime.now()));
        } else {
          final lastReading = readings.last;
          readings[readings.length - 1] = lastReading.copyWith(finishDate: DateTime.now());
        }
        newReadingsData = readings.map((r) => r.toString()).join(';');
      }
      
      await updateBook(book.copyWith(
        statusIndex: newStatus.index,
        readingsData: newReadingsData,
        currentPage: newStatus == BookStatus.read && book.pages != null 
            ? book.pages 
            : book.currentPage,
      ));
    }
  }

  // Add reading time
  Future<void> addReadingTime(String bookId, int seconds) async {
    final book = getBook(bookId);
    if (book != null) {
      await updateBook(book.copyWith(
        totalReadingTimeSeconds: book.totalReadingTimeSeconds + seconds,
      ));
    }
  }

  // Update highlights
  Future<void> updateHighlights(String bookId, String highlights) async {
    final book = getBook(bookId);
    if (book != null) {
      await updateBook(book.copyWith(highlights: highlights));
    }
  }

  // Search

  List<Book> searchBooks(String query) {
    if (query.isEmpty) return getAllBooks();
    
    final lowerQuery = query.toLowerCase();
    return getAllBooks().where((book) {
      return book.title.toLowerCase().contains(lowerQuery) ||
             book.author.toLowerCase().contains(lowerQuery) ||
             (book.isbn?.toLowerCase().contains(lowerQuery) ?? false) ||
             book.tagsList.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}

/// Provider para o repositório de livros
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository();
});

/// Provider para stream de livros (reativo)
final allBooksProvider = StreamProvider<List<Book>>((ref) async* {
  final repo = ref.watch(bookRepositoryProvider);
  await repo.initialize();
  
  yield repo.getAllBooks();
  
  await for (final _ in repo.box.watch()) {
    yield repo.getAllBooks();
  }
});

/// Provider para livros por status
final booksByStatusProvider = StreamProvider.family<List<Book>, BookStatus>((ref, status) async* {
  final repo = ref.watch(bookRepositoryProvider);
  await repo.initialize();
  
  yield repo.getBooksByStatus(status);
  
  await for (final _ in repo.box.watch()) {
    yield repo.getBooksByStatus(status);
  }
});

/// Provider para estatísticas da biblioteca
final libraryStatsProvider = Provider<Map<String, int>>((ref) {
  final repo = ref.watch(bookRepositoryProvider);
  if (!repo.isInitialized) return {};
  
  return {
    'total': repo.totalBooks,
    'reading': repo.totalBooksReading,
    'finished': repo.totalBooksRead,
    'pages': repo.totalPagesRead,
  };
});
