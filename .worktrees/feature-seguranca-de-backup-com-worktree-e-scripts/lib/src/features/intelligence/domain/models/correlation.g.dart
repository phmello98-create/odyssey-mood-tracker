// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correlation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CorrelationAdapter extends TypeAdapter<Correlation> {
  @override
  final int typeId = 30;

  @override
  Correlation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Correlation(
      id: fields[0] as String,
      variable1: fields[1] as String,
      variable1Label: fields[2] as String,
      variable2: fields[3] as String,
      variable2Label: fields[4] as String,
      coefficient: fields[5] as double,
      pValue: fields[6] as double,
      sampleSize: fields[7] as int,
      strength: fields[8] as CorrelationStrength,
      calculatedAt: fields[9] as DateTime,
      description: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Correlation obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.variable1)
      ..writeByte(2)
      ..write(obj.variable1Label)
      ..writeByte(3)
      ..write(obj.variable2)
      ..writeByte(4)
      ..write(obj.variable2Label)
      ..writeByte(5)
      ..write(obj.coefficient)
      ..writeByte(6)
      ..write(obj.pValue)
      ..writeByte(7)
      ..write(obj.sampleSize)
      ..writeByte(8)
      ..write(obj.strength)
      ..writeByte(9)
      ..write(obj.calculatedAt)
      ..writeByte(10)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorrelationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CorrelationStrengthAdapter extends TypeAdapter<CorrelationStrength> {
  @override
  final int typeId = 35;

  @override
  CorrelationStrength read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CorrelationStrength.none;
      case 1:
        return CorrelationStrength.weak;
      case 2:
        return CorrelationStrength.moderate;
      case 3:
        return CorrelationStrength.strong;
      case 4:
        return CorrelationStrength.veryStrong;
      case 5:
        return CorrelationStrength.negligible;
      default:
        return CorrelationStrength.none;
    }
  }

  @override
  void write(BinaryWriter writer, CorrelationStrength obj) {
    switch (obj) {
      case CorrelationStrength.none:
        writer.writeByte(0);
        break;
      case CorrelationStrength.weak:
        writer.writeByte(1);
        break;
      case CorrelationStrength.moderate:
        writer.writeByte(2);
        break;
      case CorrelationStrength.strong:
        writer.writeByte(3);
        break;
      case CorrelationStrength.veryStrong:
        writer.writeByte(4);
        break;
      case CorrelationStrength.negligible:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorrelationStrengthAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
