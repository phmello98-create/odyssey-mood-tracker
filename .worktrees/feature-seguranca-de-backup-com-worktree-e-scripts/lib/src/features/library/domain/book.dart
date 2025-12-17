import 'package:hive/hive.dart';

part 'book.g.dart';

/// Status do livro na biblioteca
enum BookStatus {
  @HiveField(0)
  forLater,    // Para ler
  @HiveField(1)
  inProgress,  // Lendo
  @HiveField(2)
  read,        // Lido
  @HiveField(3)
  unfinished,  // Abandonado
}

/// Formato do livro
enum BookFormat {
  @HiveField(0)
  paperback,   // Físico brochura
  @HiveField(1)
  hardcover,   // Capa dura
  @HiveField(2)
  ebook,       // E-book
  @HiveField(3)
  audiobook,   // Audiolivro
}

/// Período de leitura de um livro
@HiveType(typeId: 22)
class ReadingPeriod {
  @HiveField(0)
  final DateTime? startDate;
  
  @HiveField(1)
  final DateTime? finishDate;
  
  @HiveField(2)
  final int? readingTimeMinutes; // Tempo customizado de leitura

  ReadingPeriod({
    this.startDate,
    this.finishDate,
    this.readingTimeMinutes,
  });

  ReadingPeriod copyWith({
    DateTime? startDate,
    DateTime? finishDate,
    int? readingTimeMinutes,
  }) {
    return ReadingPeriod(
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
    );
  }

  @override
  String toString() {
    final start = startDate?.toIso8601String() ?? '';
    final finish = finishDate?.toIso8601String() ?? '';
    final time = readingTimeMinutes?.toString() ?? '';
    return '$start|$finish|$time';
  }

  factory ReadingPeriod.fromString(String input) {
    final parts = input.split('|');
    if (parts.length != 3) return ReadingPeriod();
    
    return ReadingPeriod(
      startDate: parts[0].isNotEmpty ? DateTime.tryParse(parts[0]) : null,
      finishDate: parts[1].isNotEmpty ? DateTime.tryParse(parts[1]) : null,
      readingTimeMinutes: parts[2].isNotEmpty ? int.tryParse(parts[2]) : null,
    );
  }
}

/// Modelo principal do livro
@HiveType(typeId: 21)
class Book extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? subtitle;

  @HiveField(3)
  final String author;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final int statusIndex; // BookStatus index

  @HiveField(6)
  final bool favourite;

  @HiveField(7)
  final bool deleted;

  @HiveField(8)
  final int? rating; // 0-100 (para precisão de meia estrela)

  @HiveField(9)
  final int? pages;

  @HiveField(10)
  final int? publicationYear;

  @HiveField(11)
  final String? isbn;

  @HiveField(12)
  final String? olid; // Open Library ID

  @HiveField(13)
  final String? tags; // Separados por |||||

  @HiveField(14)
  final String? myReview;

  @HiveField(15)
  final String? notes;

  @HiveField(16)
  final String? blurHash;

  @HiveField(17)
  final int formatIndex; // BookFormat index

  @HiveField(18)
  final bool hasCover;

  @HiveField(19)
  final String? readingsData; // ReadingPeriods serialized

  @HiveField(20)
  final DateTime dateAdded;

  @HiveField(21)
  final DateTime dateModified;

  @HiveField(22)
  final int currentPage;

  @HiveField(23)
  final String? coverPath; // Path local da capa

  @HiveField(24)
  final String? genre;

  @HiveField(25)
  final String? highlights; // Melhores trechos

  @HiveField(26)
  final int totalReadingTimeSeconds; // Tempo total de leitura rastreado

  Book({
    required this.id,
    required this.title,
    this.subtitle,
    required this.author,
    this.description,
    this.statusIndex = 0,
    this.favourite = false,
    this.deleted = false,
    this.rating,
    this.pages,
    this.publicationYear,
    this.isbn,
    this.olid,
    this.tags,
    this.myReview,
    this.notes,
    this.blurHash,
    this.formatIndex = 0,
    this.hasCover = false,
    this.readingsData,
    required this.dateAdded,
    required this.dateModified,
    this.currentPage = 0,
    this.coverPath,
    this.genre,
    this.highlights,
    this.totalReadingTimeSeconds = 0,
  });

  // Getters de conveniência
  BookStatus get status => BookStatus.values[statusIndex.clamp(0, BookStatus.values.length - 1)];
  BookFormat get bookFormat => BookFormat.values[formatIndex.clamp(0, BookFormat.values.length - 1)];
  
  List<ReadingPeriod> get readings {
    if (readingsData == null || readingsData!.isEmpty) return [];
    return readingsData!.split(';').map((e) => ReadingPeriod.fromString(e)).toList();
  }

  List<String> get tagsList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split('|||||');
  }

  double get progress => pages != null && pages! > 0 ? currentPage / pages! : 0;

  double? get ratingAsDouble => rating != null ? rating! / 10.0 : null;

  String get formattedReadingTime {
    if (totalReadingTimeSeconds == 0) return '0min';
    final hours = totalReadingTimeSeconds ~/ 3600;
    final minutes = (totalReadingTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  DateTime? get latestStartDate {
    final r = readings;
    if (r.isEmpty) return null;
    DateTime? latest;
    for (final reading in r) {
      if (reading.startDate != null) {
        if (latest == null || reading.startDate!.isAfter(latest)) {
          latest = reading.startDate;
        }
      }
    }
    return latest;
  }

  DateTime? get latestFinishDate {
    final r = readings;
    if (r.isEmpty) return null;
    DateTime? latest;
    for (final reading in r) {
      if (reading.finishDate != null) {
        if (latest == null || reading.finishDate!.isAfter(latest)) {
          latest = reading.finishDate;
        }
      }
    }
    return latest;
  }

  factory Book.empty({
    BookStatus status = BookStatus.forLater,
    BookFormat format = BookFormat.paperback,
  }) {
    final now = DateTime.now();
    return Book(
      id: now.millisecondsSinceEpoch.toString(),
      title: '',
      author: '',
      statusIndex: status.index,
      formatIndex: format.index,
      dateAdded: now,
      dateModified: now,
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? author,
    String? description,
    int? statusIndex,
    bool? favourite,
    bool? deleted,
    int? rating,
    int? pages,
    int? publicationYear,
    String? isbn,
    String? olid,
    String? tags,
    String? myReview,
    String? notes,
    String? blurHash,
    int? formatIndex,
    bool? hasCover,
    String? readingsData,
    DateTime? dateAdded,
    DateTime? dateModified,
    int? currentPage,
    String? coverPath,
    String? genre,
    String? highlights,
    int? totalReadingTimeSeconds,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      author: author ?? this.author,
      description: description ?? this.description,
      statusIndex: statusIndex ?? this.statusIndex,
      favourite: favourite ?? this.favourite,
      deleted: deleted ?? this.deleted,
      rating: rating ?? this.rating,
      pages: pages ?? this.pages,
      publicationYear: publicationYear ?? this.publicationYear,
      isbn: isbn ?? this.isbn,
      olid: olid ?? this.olid,
      tags: tags ?? this.tags,
      myReview: myReview ?? this.myReview,
      notes: notes ?? this.notes,
      blurHash: blurHash ?? this.blurHash,
      formatIndex: formatIndex ?? this.formatIndex,
      hasCover: hasCover ?? this.hasCover,
      readingsData: readingsData ?? this.readingsData,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      currentPage: currentPage ?? this.currentPage,
      coverPath: coverPath ?? this.coverPath,
      genre: genre ?? this.genre,
      highlights: highlights ?? this.highlights,
      totalReadingTimeSeconds: totalReadingTimeSeconds ?? this.totalReadingTimeSeconds,
    );
  }

  Book withStatus(BookStatus newStatus) {
    return copyWith(
      statusIndex: newStatus.index,
      dateModified: DateTime.now(),
    );
  }

  Book withReading(ReadingPeriod reading) {
    final currentReadings = readings;
    currentReadings.add(reading);
    return copyWith(
      readingsData: currentReadings.map((r) => r.toString()).join(';'),
      dateModified: DateTime.now(),
    );
  }

  Book withTag(String tag) {
    final currentTags = tagsList;
    if (!currentTags.contains(tag)) {
      currentTags.add(tag);
    }
    return copyWith(
      tags: currentTags.join('|||||'),
      dateModified: DateTime.now(),
    );
  }

  Book withoutTag(String tag) {
    final currentTags = tagsList;
    currentTags.remove(tag);
    return copyWith(
      tags: currentTags.isEmpty ? null : currentTags.join('|||||'),
      dateModified: DateTime.now(),
    );
  }
}

/// Status do artigo
enum ArticleStatus {
  @HiveField(0)
  toRead,      // Para ler
  @HiveField(1)
  reading,     // Lendo
  @HiveField(2)
  read,        // Lido
}

/// Modelo de Artigo
@HiveType(typeId: 25)
class Article {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? author;

  @HiveField(3)
  final String? source; // Site, revista, jornal, etc.

  @HiveField(4)
  final String? url;

  @HiveField(5)
  final int statusIndex;

  @HiveField(6)
  final bool favourite;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final String? tags;

  @HiveField(9)
  final DateTime dateAdded;

  @HiveField(10)
  final DateTime? dateRead;

  @HiveField(11)
  final int? readingTimeMinutes; // Tempo estimado de leitura

  @HiveField(12)
  final String? summary; // Resumo pessoal

  @HiveField(13)
  final int? rating; // 0-50 (multiplicado por 10 para ter decimais)

  @HiveField(14)
  final String? category; // Categoria do artigo

  Article({
    required this.id,
    required this.title,
    this.author,
    this.source,
    this.url,
    this.statusIndex = 0,
    this.favourite = false,
    this.notes,
    this.tags,
    required this.dateAdded,
    this.dateRead,
    this.readingTimeMinutes,
    this.summary,
    this.rating,
    this.category,
  });

  ArticleStatus get status => ArticleStatus.values[statusIndex];

  List<String> get tagsList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split('|||||');
  }

  Article copyWith({
    String? id,
    String? title,
    String? author,
    String? source,
    String? url,
    int? statusIndex,
    bool? favourite,
    String? notes,
    String? tags,
    DateTime? dateAdded,
    DateTime? dateRead,
    int? readingTimeMinutes,
    String? summary,
    int? rating,
    String? category,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      source: source ?? this.source,
      url: url ?? this.url,
      statusIndex: statusIndex ?? this.statusIndex,
      favourite: favourite ?? this.favourite,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      dateAdded: dateAdded ?? this.dateAdded,
      dateRead: dateRead ?? this.dateRead,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      summary: summary ?? this.summary,
      rating: rating ?? this.rating,
      category: category ?? this.category,
    );
  }

  factory Article.empty() {
    return Article(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      dateAdded: DateTime.now(),
    );
  }
}
