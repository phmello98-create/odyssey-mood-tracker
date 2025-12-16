// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityImplAdapter extends TypeAdapter<_$ActivityImpl> {
  @override
  final int typeId = 4;

  @override
  _$ActivityImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$ActivityImpl(
      activityName: fields[0] as String,
      iconCode: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, _$ActivityImpl obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.activityName)
      ..writeByte(1)
      ..write(obj.iconCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityImplAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
