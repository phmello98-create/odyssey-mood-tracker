// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadingPeriodAdapter extends TypeAdapter<ReadingPeriod> {
  @override
  final int typeId = 22;

  @override
  ReadingPeriod read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingPeriod(
      startDate: fields[0] as DateTime?,
      finishDate: fields[1] as DateTime?,
      readingTimeMinutes: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingPeriod obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.finishDate)
      ..writeByte(2)
      ..write(obj.readingTimeMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 21;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String,
      title: fields[1] as String,
      subtitle: fields[2] as String?,
      author: fields[3] as String,
      description: fields[4] as String?,
      statusIndex: fields[5] as int,
      favourite: fields[6] as bool,
      deleted: fields[7] as bool,
      rating: fields[8] as int?,
      pages: fields[9] as int?,
      publicationYear: fields[10] as int?,
      isbn: fields[11] as String?,
      olid: fields[12] as String?,
      tags: fields[13] as String?,
      myReview: fields[14] as String?,
      notes: fields[15] as String?,
      blurHash: fields[16] as String?,
      formatIndex: fields[17] as int,
      hasCover: fields[18] as bool,
      readingsData: fields[19] as String?,
      dateAdded: fields[20] as DateTime,
      dateModified: fields[21] as DateTime,
      currentPage: fields[22] as int,
      coverPath: fields[23] as String?,
      genre: fields[24] as String?,
      highlights: fields[25] as String?,
      totalReadingTimeSeconds: fields[26] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.subtitle)
      ..writeByte(3)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.statusIndex)
      ..writeByte(6)
      ..write(obj.favourite)
      ..writeByte(7)
      ..write(obj.deleted)
      ..writeByte(8)
      ..write(obj.rating)
      ..writeByte(9)
      ..write(obj.pages)
      ..writeByte(10)
      ..write(obj.publicationYear)
      ..writeByte(11)
      ..write(obj.isbn)
      ..writeByte(12)
      ..write(obj.olid)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.myReview)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.blurHash)
      ..writeByte(17)
      ..write(obj.formatIndex)
      ..writeByte(18)
      ..write(obj.hasCover)
      ..writeByte(19)
      ..write(obj.readingsData)
      ..writeByte(20)
      ..write(obj.dateAdded)
      ..writeByte(21)
      ..write(obj.dateModified)
      ..writeByte(22)
      ..write(obj.currentPage)
      ..writeByte(23)
      ..write(obj.coverPath)
      ..writeByte(24)
      ..write(obj.genre)
      ..writeByte(25)
      ..write(obj.highlights)
      ..writeByte(26)
      ..write(obj.totalReadingTimeSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArticleAdapter extends TypeAdapter<Article> {
  @override
  final int typeId = 25;

  @override
  Article read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Article(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String?,
      source: fields[3] as String?,
      url: fields[4] as String?,
      statusIndex: fields[5] as int,
      favourite: fields[6] as bool,
      notes: fields[7] as String?,
      tags: fields[8] as String?,
      dateAdded: fields[9] as DateTime,
      dateRead: fields[10] as DateTime?,
      readingTimeMinutes: fields[11] as int?,
      summary: fields[12] as String?,
      rating: fields[13] as int?,
      category: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Article obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.url)
      ..writeByte(5)
      ..write(obj.statusIndex)
      ..writeByte(6)
      ..write(obj.favourite)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.dateAdded)
      ..writeByte(10)
      ..write(obj.dateRead)
      ..writeByte(11)
      ..write(obj.readingTimeMinutes)
      ..writeByte(12)
      ..write(obj.summary)
      ..writeByte(13)
      ..write(obj.rating)
      ..writeByte(14)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
