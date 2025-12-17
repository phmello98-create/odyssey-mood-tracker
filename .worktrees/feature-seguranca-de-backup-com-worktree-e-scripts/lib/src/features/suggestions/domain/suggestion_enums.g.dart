// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SuggestionTypeAdapter extends TypeAdapter<SuggestionType> {
  @override
  final int typeId = 18;

  @override
  SuggestionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SuggestionType.habit;
      case 1:
        return SuggestionType.task;
      default:
        return SuggestionType.habit;
    }
  }

  @override
  void write(BinaryWriter writer, SuggestionType obj) {
    switch (obj) {
      case SuggestionType.habit:
        writer.writeByte(0);
        break;
      case SuggestionType.task:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SuggestionCategoryAdapter extends TypeAdapter<SuggestionCategory> {
  @override
  final int typeId = 19;

  @override
  SuggestionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SuggestionCategory.selfKnowledge;
      case 1:
        return SuggestionCategory.presence;
      case 2:
        return SuggestionCategory.relations;
      case 3:
        return SuggestionCategory.creation;
      case 4:
        return SuggestionCategory.reflection;
      case 5:
        return SuggestionCategory.selfActualization;
      case 6:
        return SuggestionCategory.consciousness;
      case 7:
        return SuggestionCategory.emptiness;
      default:
        return SuggestionCategory.selfKnowledge;
    }
  }

  @override
  void write(BinaryWriter writer, SuggestionCategory obj) {
    switch (obj) {
      case SuggestionCategory.selfKnowledge:
        writer.writeByte(0);
        break;
      case SuggestionCategory.presence:
        writer.writeByte(1);
        break;
      case SuggestionCategory.relations:
        writer.writeByte(2);
        break;
      case SuggestionCategory.creation:
        writer.writeByte(3);
        break;
      case SuggestionCategory.reflection:
        writer.writeByte(4);
        break;
      case SuggestionCategory.selfActualization:
        writer.writeByte(5);
        break;
      case SuggestionCategory.consciousness:
        writer.writeByte(6);
        break;
      case SuggestionCategory.emptiness:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SuggestionDifficultyAdapter extends TypeAdapter<SuggestionDifficulty> {
  @override
  final int typeId = 20;

  @override
  SuggestionDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SuggestionDifficulty.easy;
      case 1:
        return SuggestionDifficulty.medium;
      case 2:
        return SuggestionDifficulty.hard;
      default:
        return SuggestionDifficulty.easy;
    }
  }

  @override
  void write(BinaryWriter writer, SuggestionDifficulty obj) {
    switch (obj) {
      case SuggestionDifficulty.easy:
        writer.writeByte(0);
        break;
      case SuggestionDifficulty.medium:
        writer.writeByte(1);
        break;
      case SuggestionDifficulty.hard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
