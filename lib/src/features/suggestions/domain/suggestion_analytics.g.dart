// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_analytics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SuggestionAnalyticsAdapter extends TypeAdapter<SuggestionAnalytics> {
  @override
  final int typeId = 17;

  @override
  SuggestionAnalytics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SuggestionAnalytics(
      suggestionId: fields[0] as String,
      isMarked: fields[1] as bool,
      isAdded: fields[2] as bool,
      addedAt: fields[3] as DateTime?,
      markedAt: fields[4] as DateTime?,
      viewCount: fields[5] as int,
      lastViewedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SuggestionAnalytics obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.suggestionId)
      ..writeByte(1)
      ..write(obj.isMarked)
      ..writeByte(2)
      ..write(obj.isAdded)
      ..writeByte(3)
      ..write(obj.addedAt)
      ..writeByte(4)
      ..write(obj.markedAt)
      ..writeByte(5)
      ..write(obj.viewCount)
      ..writeByte(6)
      ..write(obj.lastViewedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionAnalyticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
