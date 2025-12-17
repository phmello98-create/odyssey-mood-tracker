// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiaryEntryAdapter extends TypeAdapter<_$DiaryEntryImpl> {
  @override
  final int typeId = 20;

  @override
  _$DiaryEntryImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$DiaryEntryImpl(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      updatedAt: fields[2] as DateTime,
      entryDate: fields[3] as DateTime,
      title: fields[4] as String?,
      content: fields[5] as String,
      photoIds: (fields[6] as List).cast<String>(),
      starred: fields[7] as bool,
      feeling: fields[8] as String?,
      tags: (fields[9] as List).cast<String>(),
      searchableText: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, _$DiaryEntryImpl obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.entryDate)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(7)
      ..write(obj.starred)
      ..writeByte(8)
      ..write(obj.feeling)
      ..writeByte(10)
      ..write(obj.searchableText)
      ..writeByte(6)
      ..write(obj.photoIds)
      ..writeByte(9)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiaryEntryImpl _$$DiaryEntryImplFromJson(Map<String, dynamic> json) =>
    _$DiaryEntryImpl(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      entryDate: DateTime.parse(json['entryDate'] as String),
      title: json['title'] as String?,
      content: json['content'] as String,
      photoIds: (json['photoIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      starred: json['starred'] as bool? ?? false,
      feeling: json['feeling'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      searchableText: json['searchableText'] as String?,
    );

Map<String, dynamic> _$$DiaryEntryImplToJson(_$DiaryEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'entryDate': instance.entryDate.toIso8601String(),
      'title': instance.title,
      'content': instance.content,
      'photoIds': instance.photoIds,
      'starred': instance.starred,
      'feeling': instance.feeling,
      'tags': instance.tags,
      'searchableText': instance.searchableText,
    };
