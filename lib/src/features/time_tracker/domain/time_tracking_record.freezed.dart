// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_tracking_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TimeTrackingRecord {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get activityName => throw _privateConstructorUsedError;
  @HiveField(2)
  int get iconCode => throw _privateConstructorUsedError;
  @HiveField(3)
  DateTime get startTime => throw _privateConstructorUsedError;
  @HiveField(4)
  DateTime get endTime => throw _privateConstructorUsedError;
  @HiveField(5)
  int get durationInSeconds => throw _privateConstructorUsedError;
  @HiveField(6)
  String? get notes => throw _privateConstructorUsedError;
  @HiveField(7)
  String? get category => throw _privateConstructorUsedError;
  @HiveField(8)
  String? get project => throw _privateConstructorUsedError;
  @HiveField(9)
  bool get isCompleted => throw _privateConstructorUsedError;
  @HiveField(10)
  int? get colorValue => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @HiveField(0) String id,
            @HiveField(1) String activityName,
            @HiveField(2) int iconCode,
            @HiveField(3) DateTime startTime,
            @HiveField(4) DateTime endTime,
            @HiveField(5) int durationInSeconds,
            @HiveField(6) String? notes,
            @HiveField(7) String? category,
            @HiveField(8) String? project,
            @HiveField(9) bool isCompleted,
            @HiveField(10) int? colorValue)
        internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @HiveField(0) String id,
            @HiveField(1) String activityName,
            @HiveField(2) int iconCode,
            @HiveField(3) DateTime startTime,
            @HiveField(4) DateTime endTime,
            @HiveField(5) int durationInSeconds,
            @HiveField(6) String? notes,
            @HiveField(7) String? category,
            @HiveField(8) String? project,
            @HiveField(9) bool isCompleted,
            @HiveField(10) int? colorValue)?
        internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @HiveField(0) String id,
            @HiveField(1) String activityName,
            @HiveField(2) int iconCode,
            @HiveField(3) DateTime startTime,
            @HiveField(4) DateTime endTime,
            @HiveField(5) int durationInSeconds,
            @HiveField(6) String? notes,
            @HiveField(7) String? category,
            @HiveField(8) String? project,
            @HiveField(9) bool isCompleted,
            @HiveField(10) int? colorValue)?
        internal,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_TimeTrackingRecord value) internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_TimeTrackingRecord value)? internal,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_TimeTrackingRecord value)? internal,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TimeTrackingRecordCopyWith<TimeTrackingRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeTrackingRecordCopyWith<$Res> {
  factory $TimeTrackingRecordCopyWith(
          TimeTrackingRecord value, $Res Function(TimeTrackingRecord) then) =
      _$TimeTrackingRecordCopyWithImpl<$Res, TimeTrackingRecord>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String activityName,
      @HiveField(2) int iconCode,
      @HiveField(3) DateTime startTime,
      @HiveField(4) DateTime endTime,
      @HiveField(5) int durationInSeconds,
      @HiveField(6) String? notes,
      @HiveField(7) String? category,
      @HiveField(8) String? project,
      @HiveField(9) bool isCompleted,
      @HiveField(10) int? colorValue});
}

/// @nodoc
class _$TimeTrackingRecordCopyWithImpl<$Res, $Val extends TimeTrackingRecord>
    implements $TimeTrackingRecordCopyWith<$Res> {
  _$TimeTrackingRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? activityName = null,
    Object? iconCode = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? durationInSeconds = null,
    Object? notes = freezed,
    Object? category = freezed,
    Object? project = freezed,
    Object? isCompleted = null,
    Object? colorValue = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      activityName: null == activityName
          ? _value.activityName
          : activityName // ignore: cast_nullable_to_non_nullable
              as String,
      iconCode: null == iconCode
          ? _value.iconCode
          : iconCode // ignore: cast_nullable_to_non_nullable
              as int,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationInSeconds: null == durationInSeconds
          ? _value.durationInSeconds
          : durationInSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      project: freezed == project
          ? _value.project
          : project // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      colorValue: freezed == colorValue
          ? _value.colorValue
          : colorValue // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimeTrackingRecordImplCopyWith<$Res>
    implements $TimeTrackingRecordCopyWith<$Res> {
  factory _$$TimeTrackingRecordImplCopyWith(_$TimeTrackingRecordImpl value,
          $Res Function(_$TimeTrackingRecordImpl) then) =
      __$$TimeTrackingRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String activityName,
      @HiveField(2) int iconCode,
      @HiveField(3) DateTime startTime,
      @HiveField(4) DateTime endTime,
      @HiveField(5) int durationInSeconds,
      @HiveField(6) String? notes,
      @HiveField(7) String? category,
      @HiveField(8) String? project,
      @HiveField(9) bool isCompleted,
      @HiveField(10) int? colorValue});
}

/// @nodoc
class __$$TimeTrackingRecordImplCopyWithImpl<$Res>
    extends _$TimeTrackingRecordCopyWithImpl<$Res, _$TimeTrackingRecordImpl>
    implements _$$TimeTrackingRecordImplCopyWith<$Res> {
  __$$TimeTrackingRecordImplCopyWithImpl(_$TimeTrackingRecordImpl _value,
      $Res Function(_$TimeTrackingRecordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? activityName = null,
    Object? iconCode = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? durationInSeconds = null,
    Object? notes = freezed,
    Object? category = freezed,
    Object? project = freezed,
    Object? isCompleted = null,
    Object? colorValue = freezed,
  }) {
    return _then(_$TimeTrackingRecordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      activityName: null == activityName
          ? _value.activityName
          : activityName // ignore: cast_nullable_to_non_nullable
              as String,
      iconCode: null == iconCode
          ? _value.iconCode
          : iconCode // ignore: cast_nullable_to_non_nullable
              as int,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationInSeconds: null == durationInSeconds
          ? _value.durationInSeconds
          : durationInSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      project: freezed == project
          ? _value.project
          : project // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      colorValue: freezed == colorValue
          ? _value.colorValue
          : colorValue // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@HiveType(typeId: 2)
class _$TimeTrackingRecordImpl extends _TimeTrackingRecord {
  const _$TimeTrackingRecordImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.activityName,
      @HiveField(2) required this.iconCode,
      @HiveField(3) required this.startTime,
      @HiveField(4) required this.endTime,
      @HiveField(5) required this.durationInSeconds,
      @HiveField(6) this.notes,
      @HiveField(7) this.category,
      @HiveField(8) this.project,
      @HiveField(9) this.isCompleted = false,
      @HiveField(10) this.colorValue})
      : super._();

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String activityName;
  @override
  @HiveField(2)
  final int iconCode;
  @override
  @HiveField(3)
  final DateTime startTime;
  @override
  @HiveField(4)
  final DateTime endTime;
  @override
  @HiveField(5)
  final int durationInSeconds;
  @override
  @HiveField(6)
  final String? notes;
  @override
  @HiveField(7)
  final String? category;
  @override
  @HiveField(8)
  final String? project;
  @override
  @JsonKey()
  @HiveField(9)
  final bool isCompleted;
  @override
  @HiveField(10)
  final int? colorValue;

  @override
  String toString() {
    return 'TimeTrackingRecord.internal(id: $id, activityName: $activityName, iconCode: $iconCode, startTime: $startTime, endTime: $endTime, durationInSeconds: $durationInSeconds, notes: $notes, category: $category, project: $project, isCompleted: $isCompleted, colorValue: $colorValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeTrackingRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.activityName, activityName) ||
                other.activityName == activityName) &&
            (identical(other.iconCode, iconCode) ||
                other.iconCode == iconCode) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.durationInSeconds, durationInSeconds) ||
                other.durationInSeconds == durationInSeconds) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.project, project) || other.project == project) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      activityName,
      iconCode,
      startTime,
      endTime,
      durationInSeconds,
      notes,
      category,
      project,
      isCompleted,
      colorValue);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeTrackingRecordImplCopyWith<_$TimeTrackingRecordImpl> get copyWith =>
      __$$TimeTrackingRecordImplCopyWithImpl<_$TimeTrackingRecordImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            @HiveField(0) String id,
            @HiveField(1) String activityName,
            @HiveField(2) int iconCode,
            @HiveField(3) DateTime startTime,
            @HiveField(4) DateTime endTime,
            @HiveField(5) int durationInSeconds,
            @HiveField(6) String? notes,
            @HiveField(7) String? category,
            @HiveField(8) String? project,
            @HiveField(9) bool isCompleted,
            @HiveField(10) int? colorValue)
        internal,
  }) {
    return internal(id, activityName, iconCode, startTime, endTime,
        durationInSeconds, notes, category, project, isCompleted, colorValue);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            @HiveField(0) String id,
            @HiveField(1) String activityName,
            @HiveField(2) int iconCode,
            @HiveField(3) DateTime startTime,
            @HiveField(4) DateTime endTime,
            @HiveField(5) int durationInSeconds,
            @HiveField(6) String? notes,
            @HiveField(7) String? category,
            @HiveField(8) String? project,
            @HiveField(9) bool isCompleted,
            @HiveField(10) int? colorValue)?
        internal,
  }) {
    return internal?.call(id, activityName, iconCode, startTime, endTime,
        durationInSeconds, notes, category, project, isCompleted, colorValue);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            @HiveField(0) String id,
            @HiveField(1) String activityName,
            @HiveField(2) int iconCode,
            @HiveField(3) DateTime startTime,
            @HiveField(4) DateTime endTime,
            @HiveField(5) int durationInSeconds,
            @HiveField(6) String? notes,
            @HiveField(7) String? category,
            @HiveField(8) String? project,
            @HiveField(9) bool isCompleted,
            @HiveField(10) int? colorValue)?
        internal,
    required TResult orElse(),
  }) {
    if (internal != null) {
      return internal(id, activityName, iconCode, startTime, endTime,
          durationInSeconds, notes, category, project, isCompleted, colorValue);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_TimeTrackingRecord value) internal,
  }) {
    return internal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_TimeTrackingRecord value)? internal,
  }) {
    return internal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_TimeTrackingRecord value)? internal,
    required TResult orElse(),
  }) {
    if (internal != null) {
      return internal(this);
    }
    return orElse();
  }
}

abstract class _TimeTrackingRecord extends TimeTrackingRecord {
  const factory _TimeTrackingRecord(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String activityName,
      @HiveField(2) required final int iconCode,
      @HiveField(3) required final DateTime startTime,
      @HiveField(4) required final DateTime endTime,
      @HiveField(5) required final int durationInSeconds,
      @HiveField(6) final String? notes,
      @HiveField(7) final String? category,
      @HiveField(8) final String? project,
      @HiveField(9) final bool isCompleted,
      @HiveField(10) final int? colorValue}) = _$TimeTrackingRecordImpl;
  const _TimeTrackingRecord._() : super._();

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get activityName;
  @override
  @HiveField(2)
  int get iconCode;
  @override
  @HiveField(3)
  DateTime get startTime;
  @override
  @HiveField(4)
  DateTime get endTime;
  @override
  @HiveField(5)
  int get durationInSeconds;
  @override
  @HiveField(6)
  String? get notes;
  @override
  @HiveField(7)
  String? get category;
  @override
  @HiveField(8)
  String? get project;
  @override
  @HiveField(9)
  bool get isCompleted;
  @override
  @HiveField(10)
  int? get colorValue;
  @override
  @JsonKey(ignore: true)
  _$$TimeTrackingRecordImplCopyWith<_$TimeTrackingRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
