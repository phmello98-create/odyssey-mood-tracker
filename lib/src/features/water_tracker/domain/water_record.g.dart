// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterRecordAdapter extends TypeAdapter<WaterRecord> {
  @override
  final int typeId = 60;

  @override
  WaterRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      glassesCount: fields[2] as int,
      goalGlasses: fields[3] as int,
      glassSizeMl: fields[4] as int,
      drinkTimes: (fields[5] as List).cast<DateTime>(),
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WaterRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.glassesCount)
      ..writeByte(3)
      ..write(obj.goalGlasses)
      ..writeByte(4)
      ..write(obj.glassSizeMl)
      ..writeByte(5)
      ..write(obj.drinkTimes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WaterRecordImpl _$$WaterRecordImplFromJson(Map<String, dynamic> json) =>
    _$WaterRecordImpl(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      glassesCount: (json['glassesCount'] as num?)?.toInt() ?? 0,
      goalGlasses: (json['goalGlasses'] as num?)?.toInt() ?? 8,
      glassSizeMl: (json['glassSizeMl'] as num?)?.toInt() ?? 250,
      drinkTimes: (json['drinkTimes'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$WaterRecordImplToJson(_$WaterRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'glassesCount': instance.glassesCount,
      'goalGlasses': instance.goalGlasses,
      'glassSizeMl': instance.glassSizeMl,
      'drinkTimes':
          instance.drinkTimes.map((e) => e.toIso8601String()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
