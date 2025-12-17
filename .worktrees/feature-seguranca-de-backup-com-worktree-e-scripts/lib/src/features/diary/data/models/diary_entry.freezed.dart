// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DiaryEntry _$DiaryEntryFromJson(Map<String, dynamic> json) {
  return _DiaryEntry.fromJson(json);
}

/// @nodoc
mixin _$DiaryEntry {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(2)
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @HiveField(3)
  DateTime get entryDate => throw _privateConstructorUsedError;
  @HiveField(4)
  String? get title => throw _privateConstructorUsedError;
  @HiveField(5)
  String get content => throw _privateConstructorUsedError;
  @HiveField(6)
  List<String> get photoIds => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get starred => throw _privateConstructorUsedError;
  @HiveField(8)
  String? get feeling => throw _privateConstructorUsedError;
  @HiveField(9)
  List<String> get tags => throw _privateConstructorUsedError;
  @HiveField(10)
  String? get searchableText => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiaryEntryCopyWith<DiaryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiaryEntryCopyWith<$Res> {
  factory $DiaryEntryCopyWith(
          DiaryEntry value, $Res Function(DiaryEntry) then) =
      _$DiaryEntryCopyWithImpl<$Res, DiaryEntry>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) DateTime createdAt,
      @HiveField(2) DateTime updatedAt,
      @HiveField(3) DateTime entryDate,
      @HiveField(4) String? title,
      @HiveField(5) String content,
      @HiveField(6) List<String> photoIds,
      @HiveField(7) bool starred,
      @HiveField(8) String? feeling,
      @HiveField(9) List<String> tags,
      @HiveField(10) String? searchableText});
}

/// @nodoc
class _$DiaryEntryCopyWithImpl<$Res, $Val extends DiaryEntry>
    implements $DiaryEntryCopyWith<$Res> {
  _$DiaryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? entryDate = null,
    Object? title = freezed,
    Object? content = null,
    Object? photoIds = null,
    Object? starred = null,
    Object? feeling = freezed,
    Object? tags = null,
    Object? searchableText = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      entryDate: null == entryDate
          ? _value.entryDate
          : entryDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      photoIds: null == photoIds
          ? _value.photoIds
          : photoIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      starred: null == starred
          ? _value.starred
          : starred // ignore: cast_nullable_to_non_nullable
              as bool,
      feeling: freezed == feeling
          ? _value.feeling
          : feeling // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      searchableText: freezed == searchableText
          ? _value.searchableText
          : searchableText // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiaryEntryImplCopyWith<$Res>
    implements $DiaryEntryCopyWith<$Res> {
  factory _$$DiaryEntryImplCopyWith(
          _$DiaryEntryImpl value, $Res Function(_$DiaryEntryImpl) then) =
      __$$DiaryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) DateTime createdAt,
      @HiveField(2) DateTime updatedAt,
      @HiveField(3) DateTime entryDate,
      @HiveField(4) String? title,
      @HiveField(5) String content,
      @HiveField(6) List<String> photoIds,
      @HiveField(7) bool starred,
      @HiveField(8) String? feeling,
      @HiveField(9) List<String> tags,
      @HiveField(10) String? searchableText});
}

/// @nodoc
class __$$DiaryEntryImplCopyWithImpl<$Res>
    extends _$DiaryEntryCopyWithImpl<$Res, _$DiaryEntryImpl>
    implements _$$DiaryEntryImplCopyWith<$Res> {
  __$$DiaryEntryImplCopyWithImpl(
      _$DiaryEntryImpl _value, $Res Function(_$DiaryEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? entryDate = null,
    Object? title = freezed,
    Object? content = null,
    Object? photoIds = null,
    Object? starred = null,
    Object? feeling = freezed,
    Object? tags = null,
    Object? searchableText = freezed,
  }) {
    return _then(_$DiaryEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      entryDate: null == entryDate
          ? _value.entryDate
          : entryDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      photoIds: null == photoIds
          ? _value._photoIds
          : photoIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      starred: null == starred
          ? _value.starred
          : starred // ignore: cast_nullable_to_non_nullable
              as bool,
      feeling: freezed == feeling
          ? _value.feeling
          : feeling // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      searchableText: freezed == searchableText
          ? _value.searchableText
          : searchableText // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 20, adapterName: 'DiaryEntryAdapter')
class _$DiaryEntryImpl implements _DiaryEntry {
  const _$DiaryEntryImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.createdAt,
      @HiveField(2) required this.updatedAt,
      @HiveField(3) required this.entryDate,
      @HiveField(4) this.title,
      @HiveField(5) required this.content,
      @HiveField(6) final List<String> photoIds = const [],
      @HiveField(7) this.starred = false,
      @HiveField(8) this.feeling,
      @HiveField(9) final List<String> tags = const [],
      @HiveField(10) this.searchableText})
      : _photoIds = photoIds,
        _tags = tags;

  factory _$DiaryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiaryEntryImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final DateTime createdAt;
  @override
  @HiveField(2)
  final DateTime updatedAt;
  @override
  @HiveField(3)
  final DateTime entryDate;
  @override
  @HiveField(4)
  final String? title;
  @override
  @HiveField(5)
  final String content;
  final List<String> _photoIds;
  @override
  @JsonKey()
  @HiveField(6)
  List<String> get photoIds {
    if (_photoIds is EqualUnmodifiableListView) return _photoIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoIds);
  }

  @override
  @JsonKey()
  @HiveField(7)
  final bool starred;
  @override
  @HiveField(8)
  final String? feeling;
  final List<String> _tags;
  @override
  @JsonKey()
  @HiveField(9)
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @HiveField(10)
  final String? searchableText;

  @override
  String toString() {
    return 'DiaryEntry(id: $id, createdAt: $createdAt, updatedAt: $updatedAt, entryDate: $entryDate, title: $title, content: $content, photoIds: $photoIds, starred: $starred, feeling: $feeling, tags: $tags, searchableText: $searchableText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiaryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.entryDate, entryDate) ||
                other.entryDate == entryDate) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._photoIds, _photoIds) &&
            (identical(other.starred, starred) || other.starred == starred) &&
            (identical(other.feeling, feeling) || other.feeling == feeling) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.searchableText, searchableText) ||
                other.searchableText == searchableText));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      createdAt,
      updatedAt,
      entryDate,
      title,
      content,
      const DeepCollectionEquality().hash(_photoIds),
      starred,
      feeling,
      const DeepCollectionEquality().hash(_tags),
      searchableText);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiaryEntryImplCopyWith<_$DiaryEntryImpl> get copyWith =>
      __$$DiaryEntryImplCopyWithImpl<_$DiaryEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiaryEntryImplToJson(
      this,
    );
  }
}

abstract class _DiaryEntry implements DiaryEntry {
  const factory _DiaryEntry(
      {@HiveField(0) required final String id,
      @HiveField(1) required final DateTime createdAt,
      @HiveField(2) required final DateTime updatedAt,
      @HiveField(3) required final DateTime entryDate,
      @HiveField(4) final String? title,
      @HiveField(5) required final String content,
      @HiveField(6) final List<String> photoIds,
      @HiveField(7) final bool starred,
      @HiveField(8) final String? feeling,
      @HiveField(9) final List<String> tags,
      @HiveField(10) final String? searchableText}) = _$DiaryEntryImpl;

  factory _DiaryEntry.fromJson(Map<String, dynamic> json) =
      _$DiaryEntryImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  DateTime get createdAt;
  @override
  @HiveField(2)
  DateTime get updatedAt;
  @override
  @HiveField(3)
  DateTime get entryDate;
  @override
  @HiveField(4)
  String? get title;
  @override
  @HiveField(5)
  String get content;
  @override
  @HiveField(6)
  List<String> get photoIds;
  @override
  @HiveField(7)
  bool get starred;
  @override
  @HiveField(8)
  String? get feeling;
  @override
  @HiveField(9)
  List<String> get tags;
  @override
  @HiveField(10)
  String? get searchableText;
  @override
  @JsonKey(ignore: true)
  _$$DiaryEntryImplCopyWith<_$DiaryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
