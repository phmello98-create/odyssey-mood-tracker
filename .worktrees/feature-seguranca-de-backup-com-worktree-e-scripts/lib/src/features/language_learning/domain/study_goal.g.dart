// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyGoalAdapter extends TypeAdapter<StudyGoal> {
  @override
  final int typeId = 23;

  @override
  StudyGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyGoal(
      id: fields[0] as String,
      languageId: fields[1] as String,
      dailyMinutesGoal: fields[2] as int,
      weeklyMinutesGoal: fields[3] as int,
      dailyNewWordsGoal: fields[4] as int,
      weeklyNewWordsGoal: fields[5] as int,
      remindersEnabled: fields[6] as bool,
      reminderTime: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StudyGoal obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.languageId)
      ..writeByte(2)
      ..write(obj.dailyMinutesGoal)
      ..writeByte(3)
      ..write(obj.weeklyMinutesGoal)
      ..writeByte(4)
      ..write(obj.dailyNewWordsGoal)
      ..writeByte(5)
      ..write(obj.weeklyNewWordsGoal)
      ..writeByte(6)
      ..write(obj.remindersEnabled)
      ..writeByte(7)
      ..write(obj.reminderTime)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
