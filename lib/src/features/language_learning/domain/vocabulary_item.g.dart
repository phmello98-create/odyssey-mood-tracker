// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabularyItemAdapter extends TypeAdapter<VocabularyItem> {
  @override
  final int typeId = 22;

  @override
  VocabularyItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabularyItem(
      id: fields[0] as String,
      languageId: fields[1] as String,
      word: fields[2] as String,
      translation: fields[3] as String,
      pronunciation: fields[4] as String?,
      exampleSentence: fields[5] as String?,
      exampleTranslation: fields[6] as String?,
      status: fields[7] as String,
      createdAt: fields[8] as DateTime,
      lastReviewedAt: fields[9] as DateTime?,
      nextReviewAt: fields[10] as DateTime?,
      reviewCount: fields[11] as int,
      correctCount: fields[12] as int,
      category: fields[13] as String?,
      notes: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VocabularyItem obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.languageId)
      ..writeByte(2)
      ..write(obj.word)
      ..writeByte(3)
      ..write(obj.translation)
      ..writeByte(4)
      ..write(obj.pronunciation)
      ..writeByte(5)
      ..write(obj.exampleSentence)
      ..writeByte(6)
      ..write(obj.exampleTranslation)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastReviewedAt)
      ..writeByte(10)
      ..write(obj.nextReviewAt)
      ..writeByte(11)
      ..write(obj.reviewCount)
      ..writeByte(12)
      ..write(obj.correctCount)
      ..writeByte(13)
      ..write(obj.category)
      ..writeByte(14)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
