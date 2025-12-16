// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Suggestion _$SuggestionFromJson(Map<String, dynamic> json) {
  return _Suggestion.fromJson(json);
}

/// @nodoc
mixin _$Suggestion {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get title => throw _privateConstructorUsedError;
  @HiveField(2)
  String get description => throw _privateConstructorUsedError;
  @HiveField(3)
  SuggestionType get type => throw _privateConstructorUsedError;
  @HiveField(4)
  SuggestionCategory get category => throw _privateConstructorUsedError;
  @HiveField(5)
  String get iconKey => throw _privateConstructorUsedError;
  @HiveField(6)
  int get colorValue => throw _privateConstructorUsedError;
  @HiveField(7)
  int get minLevel => throw _privateConstructorUsedError;
  @HiveField(8)
  SuggestionDifficulty get difficulty => throw _privateConstructorUsedError;
  @HiveField(9)
  List<String>? get relatedActivities => throw _privateConstructorUsedError;
  @HiveField(10)
  List<String>? get relatedMoods => throw _privateConstructorUsedError;
  @HiveField(11)
  String? get scheduledTime => throw _privateConstructorUsedError;
  @HiveField(12)
  List<int>? get suggestedDays => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SuggestionCopyWith<Suggestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SuggestionCopyWith<$Res> {
  factory $SuggestionCopyWith(
          Suggestion value, $Res Function(Suggestion) then) =
      _$SuggestionCopyWithImpl<$Res, Suggestion>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String title,
      @HiveField(2) String description,
      @HiveField(3) SuggestionType type,
      @HiveField(4) SuggestionCategory category,
      @HiveField(5) String iconKey,
      @HiveField(6) int colorValue,
      @HiveField(7) int minLevel,
      @HiveField(8) SuggestionDifficulty difficulty,
      @HiveField(9) List<String>? relatedActivities,
      @HiveField(10) List<String>? relatedMoods,
      @HiveField(11) String? scheduledTime,
      @HiveField(12) List<int>? suggestedDays});
}

/// @nodoc
class _$SuggestionCopyWithImpl<$Res, $Val extends Suggestion>
    implements $SuggestionCopyWith<$Res> {
  _$SuggestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? category = null,
    Object? iconKey = null,
    Object? colorValue = null,
    Object? minLevel = null,
    Object? difficulty = null,
    Object? relatedActivities = freezed,
    Object? relatedMoods = freezed,
    Object? scheduledTime = freezed,
    Object? suggestedDays = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SuggestionType,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as SuggestionCategory,
      iconKey: null == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String,
      colorValue: null == colorValue
          ? _value.colorValue
          : colorValue // ignore: cast_nullable_to_non_nullable
              as int,
      minLevel: null == minLevel
          ? _value.minLevel
          : minLevel // ignore: cast_nullable_to_non_nullable
              as int,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as SuggestionDifficulty,
      relatedActivities: freezed == relatedActivities
          ? _value.relatedActivities
          : relatedActivities // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      relatedMoods: freezed == relatedMoods
          ? _value.relatedMoods
          : relatedMoods // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      scheduledTime: freezed == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as String?,
      suggestedDays: freezed == suggestedDays
          ? _value.suggestedDays
          : suggestedDays // ignore: cast_nullable_to_non_nullable
              as List<int>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SuggestionImplCopyWith<$Res>
    implements $SuggestionCopyWith<$Res> {
  factory _$$SuggestionImplCopyWith(
          _$SuggestionImpl value, $Res Function(_$SuggestionImpl) then) =
      __$$SuggestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String title,
      @HiveField(2) String description,
      @HiveField(3) SuggestionType type,
      @HiveField(4) SuggestionCategory category,
      @HiveField(5) String iconKey,
      @HiveField(6) int colorValue,
      @HiveField(7) int minLevel,
      @HiveField(8) SuggestionDifficulty difficulty,
      @HiveField(9) List<String>? relatedActivities,
      @HiveField(10) List<String>? relatedMoods,
      @HiveField(11) String? scheduledTime,
      @HiveField(12) List<int>? suggestedDays});
}

/// @nodoc
class __$$SuggestionImplCopyWithImpl<$Res>
    extends _$SuggestionCopyWithImpl<$Res, _$SuggestionImpl>
    implements _$$SuggestionImplCopyWith<$Res> {
  __$$SuggestionImplCopyWithImpl(
      _$SuggestionImpl _value, $Res Function(_$SuggestionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? category = null,
    Object? iconKey = null,
    Object? colorValue = null,
    Object? minLevel = null,
    Object? difficulty = null,
    Object? relatedActivities = freezed,
    Object? relatedMoods = freezed,
    Object? scheduledTime = freezed,
    Object? suggestedDays = freezed,
  }) {
    return _then(_$SuggestionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SuggestionType,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as SuggestionCategory,
      iconKey: null == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String,
      colorValue: null == colorValue
          ? _value.colorValue
          : colorValue // ignore: cast_nullable_to_non_nullable
              as int,
      minLevel: null == minLevel
          ? _value.minLevel
          : minLevel // ignore: cast_nullable_to_non_nullable
              as int,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as SuggestionDifficulty,
      relatedActivities: freezed == relatedActivities
          ? _value._relatedActivities
          : relatedActivities // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      relatedMoods: freezed == relatedMoods
          ? _value._relatedMoods
          : relatedMoods // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      scheduledTime: freezed == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as String?,
      suggestedDays: freezed == suggestedDays
          ? _value._suggestedDays
          : suggestedDays // ignore: cast_nullable_to_non_nullable
              as List<int>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 16, adapterName: 'SuggestionAdapter')
class _$SuggestionImpl extends _Suggestion {
  const _$SuggestionImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.title,
      @HiveField(2) required this.description,
      @HiveField(3) required this.type,
      @HiveField(4) required this.category,
      @HiveField(5) required this.iconKey,
      @HiveField(6) required this.colorValue,
      @HiveField(7) this.minLevel = 1,
      @HiveField(8) this.difficulty = SuggestionDifficulty.easy,
      @HiveField(9) final List<String>? relatedActivities,
      @HiveField(10) final List<String>? relatedMoods,
      @HiveField(11) this.scheduledTime,
      @HiveField(12) final List<int>? suggestedDays})
      : _relatedActivities = relatedActivities,
        _relatedMoods = relatedMoods,
        _suggestedDays = suggestedDays,
        super._();

  factory _$SuggestionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SuggestionImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String title;
  @override
  @HiveField(2)
  final String description;
  @override
  @HiveField(3)
  final SuggestionType type;
  @override
  @HiveField(4)
  final SuggestionCategory category;
  @override
  @HiveField(5)
  final String iconKey;
  @override
  @HiveField(6)
  final int colorValue;
  @override
  @JsonKey()
  @HiveField(7)
  final int minLevel;
  @override
  @JsonKey()
  @HiveField(8)
  final SuggestionDifficulty difficulty;
  final List<String>? _relatedActivities;
  @override
  @HiveField(9)
  List<String>? get relatedActivities {
    final value = _relatedActivities;
    if (value == null) return null;
    if (_relatedActivities is EqualUnmodifiableListView)
      return _relatedActivities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _relatedMoods;
  @override
  @HiveField(10)
  List<String>? get relatedMoods {
    final value = _relatedMoods;
    if (value == null) return null;
    if (_relatedMoods is EqualUnmodifiableListView) return _relatedMoods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @HiveField(11)
  final String? scheduledTime;
  final List<int>? _suggestedDays;
  @override
  @HiveField(12)
  List<int>? get suggestedDays {
    final value = _suggestedDays;
    if (value == null) return null;
    if (_suggestedDays is EqualUnmodifiableListView) return _suggestedDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Suggestion(id: $id, title: $title, description: $description, type: $type, category: $category, iconKey: $iconKey, colorValue: $colorValue, minLevel: $minLevel, difficulty: $difficulty, relatedActivities: $relatedActivities, relatedMoods: $relatedMoods, scheduledTime: $scheduledTime, suggestedDays: $suggestedDays)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuggestionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue) &&
            (identical(other.minLevel, minLevel) ||
                other.minLevel == minLevel) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            const DeepCollectionEquality()
                .equals(other._relatedActivities, _relatedActivities) &&
            const DeepCollectionEquality()
                .equals(other._relatedMoods, _relatedMoods) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime) &&
            const DeepCollectionEquality()
                .equals(other._suggestedDays, _suggestedDays));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      type,
      category,
      iconKey,
      colorValue,
      minLevel,
      difficulty,
      const DeepCollectionEquality().hash(_relatedActivities),
      const DeepCollectionEquality().hash(_relatedMoods),
      scheduledTime,
      const DeepCollectionEquality().hash(_suggestedDays));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SuggestionImplCopyWith<_$SuggestionImpl> get copyWith =>
      __$$SuggestionImplCopyWithImpl<_$SuggestionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SuggestionImplToJson(
      this,
    );
  }
}

abstract class _Suggestion extends Suggestion {
  const factory _Suggestion(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String title,
      @HiveField(2) required final String description,
      @HiveField(3) required final SuggestionType type,
      @HiveField(4) required final SuggestionCategory category,
      @HiveField(5) required final String iconKey,
      @HiveField(6) required final int colorValue,
      @HiveField(7) final int minLevel,
      @HiveField(8) final SuggestionDifficulty difficulty,
      @HiveField(9) final List<String>? relatedActivities,
      @HiveField(10) final List<String>? relatedMoods,
      @HiveField(11) final String? scheduledTime,
      @HiveField(12) final List<int>? suggestedDays}) = _$SuggestionImpl;
  const _Suggestion._() : super._();

  factory _Suggestion.fromJson(Map<String, dynamic> json) =
      _$SuggestionImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get title;
  @override
  @HiveField(2)
  String get description;
  @override
  @HiveField(3)
  SuggestionType get type;
  @override
  @HiveField(4)
  SuggestionCategory get category;
  @override
  @HiveField(5)
  String get iconKey;
  @override
  @HiveField(6)
  int get colorValue;
  @override
  @HiveField(7)
  int get minLevel;
  @override
  @HiveField(8)
  SuggestionDifficulty get difficulty;
  @override
  @HiveField(9)
  List<String>? get relatedActivities;
  @override
  @HiveField(10)
  List<String>? get relatedMoods;
  @override
  @HiveField(11)
  String? get scheduledTime;
  @override
  @HiveField(12)
  List<int>? get suggestedDays;
  @override
  @JsonKey(ignore: true)
  _$$SuggestionImplCopyWith<_$SuggestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
