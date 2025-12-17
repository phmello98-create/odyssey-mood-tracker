// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_pattern.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPatternAdapter extends TypeAdapter<UserPattern> {
  @override
  final int typeId = 28;

  @override
  UserPattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPattern(
      id: fields[0] as String,
      type: fields[1] as PatternType,
      description: fields[2] as String,
      strength: fields[3] as double,
      data: (fields[4] as Map).cast<String, dynamic>(),
      firstDetected: fields[5] as DateTime,
      lastConfirmed: fields[6] as DateTime,
      occurrences: fields[7] as int,
      relatedFeature: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserPattern obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.strength)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.firstDetected)
      ..writeByte(6)
      ..write(obj.lastConfirmed)
      ..writeByte(7)
      ..write(obj.occurrences)
      ..writeByte(8)
      ..write(obj.relatedFeature);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatternTypeAdapter extends TypeAdapter<PatternType> {
  @override
  final int typeId = 33;

  @override
  PatternType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PatternType.temporal;
      case 1:
        return PatternType.behavioral;
      case 2:
        return PatternType.correlation;
      case 3:
        return PatternType.cyclical;
      default:
        return PatternType.temporal;
    }
  }

  @override
  void write(BinaryWriter writer, PatternType obj) {
    switch (obj) {
      case PatternType.temporal:
        writer.writeByte(0);
        break;
      case PatternType.behavioral:
        writer.writeByte(1);
        break;
      case PatternType.correlation:
        writer.writeByte(2);
        break;
      case PatternType.cyclical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
