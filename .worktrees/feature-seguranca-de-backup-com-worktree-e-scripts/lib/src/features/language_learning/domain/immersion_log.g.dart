// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'immersion_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImmersionLogAdapter extends TypeAdapter<ImmersionLog> {
  @override
  final int typeId = 24;

  @override
  ImmersionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImmersionLog(
      id: fields[0] as String,
      languageId: fields[1] as String,
      date: fields[2] as DateTime,
      durationMinutes: fields[3] as int,
      type: fields[4] as String,
      title: fields[5] as String?,
      notes: fields[6] as String?,
      rating: fields[7] as int?,
      withSubtitles: fields[8] as bool,
      subtitleLanguage: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ImmersionLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.languageId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.rating)
      ..writeByte(8)
      ..write(obj.withSubtitles)
      ..writeByte(9)
      ..write(obj.subtitleLanguage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImmersionLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
