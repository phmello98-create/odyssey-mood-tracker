// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LanguageAdapter extends TypeAdapter<Language> {
  @override
  final int typeId = 20;

  @override
  Language read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Language(
      id: fields[0] as String,
      name: fields[1] as String,
      flag: fields[2] as String,
      colorValue: fields[3] as int,
      level: fields[4] as String,
      totalMinutesStudied: fields[5] as int,
      currentStreak: fields[6] as int,
      bestStreak: fields[7] as int,
      createdAt: fields[8] as DateTime,
      lastStudiedAt: fields[9] as DateTime?,
      notes: fields[10] as String?,
      order: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Language obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.flag)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.totalMinutesStudied)
      ..writeByte(6)
      ..write(obj.currentStreak)
      ..writeByte(7)
      ..write(obj.bestStreak)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastStudiedAt)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
