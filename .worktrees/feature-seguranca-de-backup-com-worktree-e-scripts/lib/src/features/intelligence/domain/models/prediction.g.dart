// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PredictionAdapter extends TypeAdapter<Prediction> {
  @override
  final int typeId = 29;

  @override
  Prediction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Prediction(
      id: fields[0] as String,
      type: fields[1] as PredictionType,
      targetId: fields[2] as String?,
      targetName: fields[3] as String?,
      probability: fields[4] as double,
      predictedFor: fields[5] as DateTime,
      reasoning: fields[6] as String,
      features: (fields[7] as Map).cast<String, dynamic>(),
      generatedAt: fields[8] as DateTime,
      wasAccurate: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Prediction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.targetId)
      ..writeByte(3)
      ..write(obj.targetName)
      ..writeByte(4)
      ..write(obj.probability)
      ..writeByte(5)
      ..write(obj.predictedFor)
      ..writeByte(6)
      ..write(obj.reasoning)
      ..writeByte(7)
      ..write(obj.features)
      ..writeByte(8)
      ..write(obj.generatedAt)
      ..writeByte(9)
      ..write(obj.wasAccurate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PredictionTypeAdapter extends TypeAdapter<PredictionType> {
  @override
  final int typeId = 34;

  @override
  PredictionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PredictionType.streakBreak;
      case 1:
        return PredictionType.streakSuccess;
      case 2:
        return PredictionType.moodDrop;
      case 3:
        return PredictionType.moodImprovement;
      case 4:
        return PredictionType.taskCompletion;
      case 5:
        return PredictionType.habitCompletion;
      case 6:
        return PredictionType.productiveDay;
      default:
        return PredictionType.streakBreak;
    }
  }

  @override
  void write(BinaryWriter writer, PredictionType obj) {
    switch (obj) {
      case PredictionType.streakBreak:
        writer.writeByte(0);
        break;
      case PredictionType.streakSuccess:
        writer.writeByte(1);
        break;
      case PredictionType.moodDrop:
        writer.writeByte(2);
        break;
      case PredictionType.moodImprovement:
        writer.writeByte(3);
        break;
      case PredictionType.taskCompletion:
        writer.writeByte(4);
        break;
      case PredictionType.habitCompletion:
        writer.writeByte(5);
        break;
      case PredictionType.productiveDay:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
