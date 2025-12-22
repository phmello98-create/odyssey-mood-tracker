// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'water_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WaterRecord _$WaterRecordFromJson(Map<String, dynamic> json) {
  return _WaterRecord.fromJson(json);
}

/// @nodoc
mixin _$WaterRecord {
  /// ID único (data no formato yyyy-MM-dd)
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;

  /// Data do registro
  @HiveField(1)
  DateTime get date => throw _privateConstructorUsedError;

  /// Quantidade de copos bebidos
  @HiveField(2)
  int get glassesCount => throw _privateConstructorUsedError;

  /// Meta de copos (padrão: 8 copos de 250ml = 2L)
  @HiveField(3)
  int get goalGlasses => throw _privateConstructorUsedError;

  /// Tamanho do copo em ml (padrão: 250ml)
  @HiveField(4)
  int get glassSizeMl => throw _privateConstructorUsedError;

  /// Horários em que bebeu água
  @HiveField(5)
  List<DateTime> get drinkTimes => throw _privateConstructorUsedError;

  /// Data de criação
  @HiveField(6)
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Data de última atualização
  @HiveField(7)
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WaterRecordCopyWith<WaterRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WaterRecordCopyWith<$Res> {
  factory $WaterRecordCopyWith(
          WaterRecord value, $Res Function(WaterRecord) then) =
      _$WaterRecordCopyWithImpl<$Res, WaterRecord>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) DateTime date,
      @HiveField(2) int glassesCount,
      @HiveField(3) int goalGlasses,
      @HiveField(4) int glassSizeMl,
      @HiveField(5) List<DateTime> drinkTimes,
      @HiveField(6) DateTime createdAt,
      @HiveField(7) DateTime updatedAt});
}

/// @nodoc
class _$WaterRecordCopyWithImpl<$Res, $Val extends WaterRecord>
    implements $WaterRecordCopyWith<$Res> {
  _$WaterRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? glassesCount = null,
    Object? goalGlasses = null,
    Object? glassSizeMl = null,
    Object? drinkTimes = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      glassesCount: null == glassesCount
          ? _value.glassesCount
          : glassesCount // ignore: cast_nullable_to_non_nullable
              as int,
      goalGlasses: null == goalGlasses
          ? _value.goalGlasses
          : goalGlasses // ignore: cast_nullable_to_non_nullable
              as int,
      glassSizeMl: null == glassSizeMl
          ? _value.glassSizeMl
          : glassSizeMl // ignore: cast_nullable_to_non_nullable
              as int,
      drinkTimes: null == drinkTimes
          ? _value.drinkTimes
          : drinkTimes // ignore: cast_nullable_to_non_nullable
              as List<DateTime>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WaterRecordImplCopyWith<$Res>
    implements $WaterRecordCopyWith<$Res> {
  factory _$$WaterRecordImplCopyWith(
          _$WaterRecordImpl value, $Res Function(_$WaterRecordImpl) then) =
      __$$WaterRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) DateTime date,
      @HiveField(2) int glassesCount,
      @HiveField(3) int goalGlasses,
      @HiveField(4) int glassSizeMl,
      @HiveField(5) List<DateTime> drinkTimes,
      @HiveField(6) DateTime createdAt,
      @HiveField(7) DateTime updatedAt});
}

/// @nodoc
class __$$WaterRecordImplCopyWithImpl<$Res>
    extends _$WaterRecordCopyWithImpl<$Res, _$WaterRecordImpl>
    implements _$$WaterRecordImplCopyWith<$Res> {
  __$$WaterRecordImplCopyWithImpl(
      _$WaterRecordImpl _value, $Res Function(_$WaterRecordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? glassesCount = null,
    Object? goalGlasses = null,
    Object? glassSizeMl = null,
    Object? drinkTimes = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$WaterRecordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      glassesCount: null == glassesCount
          ? _value.glassesCount
          : glassesCount // ignore: cast_nullable_to_non_nullable
              as int,
      goalGlasses: null == goalGlasses
          ? _value.goalGlasses
          : goalGlasses // ignore: cast_nullable_to_non_nullable
              as int,
      glassSizeMl: null == glassSizeMl
          ? _value.glassSizeMl
          : glassSizeMl // ignore: cast_nullable_to_non_nullable
              as int,
      drinkTimes: null == drinkTimes
          ? _value._drinkTimes
          : drinkTimes // ignore: cast_nullable_to_non_nullable
              as List<DateTime>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WaterRecordImpl extends _WaterRecord {
  _$WaterRecordImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.date,
      @HiveField(2) this.glassesCount = 0,
      @HiveField(3) this.goalGlasses = 8,
      @HiveField(4) this.glassSizeMl = 250,
      @HiveField(5) final List<DateTime> drinkTimes = const [],
      @HiveField(6) required this.createdAt,
      @HiveField(7) required this.updatedAt})
      : _drinkTimes = drinkTimes,
        super._();

  factory _$WaterRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$WaterRecordImplFromJson(json);

  /// ID único (data no formato yyyy-MM-dd)
  @override
  @HiveField(0)
  final String id;

  /// Data do registro
  @override
  @HiveField(1)
  final DateTime date;

  /// Quantidade de copos bebidos
  @override
  @JsonKey()
  @HiveField(2)
  final int glassesCount;

  /// Meta de copos (padrão: 8 copos de 250ml = 2L)
  @override
  @JsonKey()
  @HiveField(3)
  final int goalGlasses;

  /// Tamanho do copo em ml (padrão: 250ml)
  @override
  @JsonKey()
  @HiveField(4)
  final int glassSizeMl;

  /// Horários em que bebeu água
  final List<DateTime> _drinkTimes;

  /// Horários em que bebeu água
  @override
  @JsonKey()
  @HiveField(5)
  List<DateTime> get drinkTimes {
    if (_drinkTimes is EqualUnmodifiableListView) return _drinkTimes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_drinkTimes);
  }

  /// Data de criação
  @override
  @HiveField(6)
  final DateTime createdAt;

  /// Data de última atualização
  @override
  @HiveField(7)
  final DateTime updatedAt;

  @override
  String toString() {
    return 'WaterRecord(id: $id, date: $date, glassesCount: $glassesCount, goalGlasses: $goalGlasses, glassSizeMl: $glassSizeMl, drinkTimes: $drinkTimes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WaterRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.glassesCount, glassesCount) ||
                other.glassesCount == glassesCount) &&
            (identical(other.goalGlasses, goalGlasses) ||
                other.goalGlasses == goalGlasses) &&
            (identical(other.glassSizeMl, glassSizeMl) ||
                other.glassSizeMl == glassSizeMl) &&
            const DeepCollectionEquality()
                .equals(other._drinkTimes, _drinkTimes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      date,
      glassesCount,
      goalGlasses,
      glassSizeMl,
      const DeepCollectionEquality().hash(_drinkTimes),
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WaterRecordImplCopyWith<_$WaterRecordImpl> get copyWith =>
      __$$WaterRecordImplCopyWithImpl<_$WaterRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WaterRecordImplToJson(
      this,
    );
  }
}

abstract class _WaterRecord extends WaterRecord {
  factory _WaterRecord(
      {@HiveField(0) required final String id,
      @HiveField(1) required final DateTime date,
      @HiveField(2) final int glassesCount,
      @HiveField(3) final int goalGlasses,
      @HiveField(4) final int glassSizeMl,
      @HiveField(5) final List<DateTime> drinkTimes,
      @HiveField(6) required final DateTime createdAt,
      @HiveField(7) required final DateTime updatedAt}) = _$WaterRecordImpl;
  _WaterRecord._() : super._();

  factory _WaterRecord.fromJson(Map<String, dynamic> json) =
      _$WaterRecordImpl.fromJson;

  @override

  /// ID único (data no formato yyyy-MM-dd)
  @HiveField(0)
  String get id;
  @override

  /// Data do registro
  @HiveField(1)
  DateTime get date;
  @override

  /// Quantidade de copos bebidos
  @HiveField(2)
  int get glassesCount;
  @override

  /// Meta de copos (padrão: 8 copos de 250ml = 2L)
  @HiveField(3)
  int get goalGlasses;
  @override

  /// Tamanho do copo em ml (padrão: 250ml)
  @HiveField(4)
  int get glassSizeMl;
  @override

  /// Horários em que bebeu água
  @HiveField(5)
  List<DateTime> get drinkTimes;
  @override

  /// Data de criação
  @HiveField(6)
  DateTime get createdAt;
  @override

  /// Data de última atualização
  @HiveField(7)
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$WaterRecordImplCopyWith<_$WaterRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
