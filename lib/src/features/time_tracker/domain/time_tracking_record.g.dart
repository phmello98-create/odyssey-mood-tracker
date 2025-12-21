// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_tracking_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeTrackingRecordImplAdapter
    extends TypeAdapter<_$TimeTrackingRecordImpl> {
  @override
  final int typeId = 2;

  @override
  _$TimeTrackingRecordImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$TimeTrackingRecordImpl(
      id: fields[0] as String,
      activityName: fields[1] as String,
      iconCode: fields[2] as int,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime,
      durationInSeconds: fields[5] as int,
      notes: fields[6] as String?,
      category: fields[7] as String?,
      project: fields[8] as String?,
      isCompleted: fields[9] as bool,
      colorValue: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, _$TimeTrackingRecordImpl obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.activityName)
      ..writeByte(2)
      ..write(obj.iconCode)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.durationInSeconds)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.project)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeTrackingRecordImplAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
