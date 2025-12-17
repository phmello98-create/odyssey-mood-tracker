// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InsightAdapter extends TypeAdapter<Insight> {
  @override
  final int typeId = 32;

  @override
  Insight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Insight(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as InsightType,
      priority: fields[4] as InsightPriority,
      confidence: fields[5] as double,
      generatedAt: fields[6] as DateTime,
      validUntil: fields[7] as DateTime,
      metadata: (fields[8] as Map).cast<String, dynamic>(),
      isRead: fields[9] as bool,
      userRating: fields[10] as int?,
      actionId: fields[11] as String?,
      actionLabel: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Insight obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.confidence)
      ..writeByte(6)
      ..write(obj.generatedAt)
      ..writeByte(7)
      ..write(obj.validUntil)
      ..writeByte(8)
      ..write(obj.metadata)
      ..writeByte(9)
      ..write(obj.isRead)
      ..writeByte(10)
      ..write(obj.userRating)
      ..writeByte(11)
      ..write(obj.actionId)
      ..writeByte(12)
      ..write(obj.actionLabel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InsightTypeAdapter extends TypeAdapter<InsightType> {
  @override
  final int typeId = 27;

  @override
  InsightType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InsightType.pattern;
      case 1:
        return InsightType.correlation;
      case 2:
        return InsightType.recommendation;
      case 3:
        return InsightType.prediction;
      case 4:
        return InsightType.warning;
      case 5:
        return InsightType.celebration;
      default:
        return InsightType.pattern;
    }
  }

  @override
  void write(BinaryWriter writer, InsightType obj) {
    switch (obj) {
      case InsightType.pattern:
        writer.writeByte(0);
        break;
      case InsightType.correlation:
        writer.writeByte(1);
        break;
      case InsightType.recommendation:
        writer.writeByte(2);
        break;
      case InsightType.prediction:
        writer.writeByte(3);
        break;
      case InsightType.warning:
        writer.writeByte(4);
        break;
      case InsightType.celebration:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InsightPriorityAdapter extends TypeAdapter<InsightPriority> {
  @override
  final int typeId = 31;

  @override
  InsightPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InsightPriority.low;
      case 1:
        return InsightPriority.medium;
      case 2:
        return InsightPriority.high;
      case 3:
        return InsightPriority.urgent;
      default:
        return InsightPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, InsightPriority obj) {
    switch (obj) {
      case InsightPriority.low:
        writer.writeByte(0);
        break;
      case InsightPriority.medium:
        writer.writeByte(1);
        break;
      case InsightPriority.high:
        writer.writeByte(2);
        break;
      case InsightPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
