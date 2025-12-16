// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SuggestionAdapter extends TypeAdapter<_$SuggestionImpl> {
  @override
  final int typeId = 16;

  @override
  _$SuggestionImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$SuggestionImpl(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as SuggestionType,
      category: fields[4] as SuggestionCategory,
      iconKey: fields[5] as String,
      colorValue: fields[6] as int,
      minLevel: fields[7] as int,
      difficulty: fields[8] as SuggestionDifficulty,
      relatedActivities: (fields[9] as List?)?.cast<String>(),
      relatedMoods: (fields[10] as List?)?.cast<String>(),
      scheduledTime: fields[11] as String?,
      suggestedDays: (fields[12] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, _$SuggestionImpl obj) {
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
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.iconKey)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.minLevel)
      ..writeByte(8)
      ..write(obj.difficulty)
      ..writeByte(11)
      ..write(obj.scheduledTime)
      ..writeByte(9)
      ..write(obj.relatedActivities)
      ..writeByte(10)
      ..write(obj.relatedMoods)
      ..writeByte(12)
      ..write(obj.suggestedDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SuggestionImpl _$$SuggestionImplFromJson(Map<String, dynamic> json) =>
    _$SuggestionImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$SuggestionTypeEnumMap, json['type']),
      category: $enumDecode(_$SuggestionCategoryEnumMap, json['category']),
      iconKey: json['iconKey'] as String,
      colorValue: (json['colorValue'] as num).toInt(),
      minLevel: (json['minLevel'] as num?)?.toInt() ?? 1,
      difficulty: $enumDecodeNullable(
              _$SuggestionDifficultyEnumMap, json['difficulty']) ??
          SuggestionDifficulty.easy,
      relatedActivities: (json['relatedActivities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      relatedMoods: (json['relatedMoods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      scheduledTime: json['scheduledTime'] as String?,
      suggestedDays: (json['suggestedDays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$SuggestionImplToJson(_$SuggestionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$SuggestionTypeEnumMap[instance.type]!,
      'category': _$SuggestionCategoryEnumMap[instance.category]!,
      'iconKey': instance.iconKey,
      'colorValue': instance.colorValue,
      'minLevel': instance.minLevel,
      'difficulty': _$SuggestionDifficultyEnumMap[instance.difficulty]!,
      'relatedActivities': instance.relatedActivities,
      'relatedMoods': instance.relatedMoods,
      'scheduledTime': instance.scheduledTime,
      'suggestedDays': instance.suggestedDays,
    };

const _$SuggestionTypeEnumMap = {
  SuggestionType.habit: 'habit',
  SuggestionType.task: 'task',
};

const _$SuggestionCategoryEnumMap = {
  SuggestionCategory.selfKnowledge: 'selfKnowledge',
  SuggestionCategory.presence: 'presence',
  SuggestionCategory.relations: 'relations',
  SuggestionCategory.creation: 'creation',
  SuggestionCategory.reflection: 'reflection',
  SuggestionCategory.selfActualization: 'selfActualization',
  SuggestionCategory.consciousness: 'consciousness',
  SuggestionCategory.emptiness: 'emptiness',
};

const _$SuggestionDifficultyEnumMap = {
  SuggestionDifficulty.easy: 'easy',
  SuggestionDifficulty.medium: 'medium',
  SuggestionDifficulty.hard: 'hard',
};
