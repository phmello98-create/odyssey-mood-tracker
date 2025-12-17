// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(OdysseyUser? user, String? message) success,
    required TResult Function(
            String message, String? errorCode, Object? exception)
        failure,
    required TResult Function() loading,
    required TResult Function() initial,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(OdysseyUser? user, String? message)? success,
    TResult? Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult? Function()? loading,
    TResult? Function()? initial,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(OdysseyUser? user, String? message)? success,
    TResult Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult Function()? loading,
    TResult Function()? initial,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResultSuccess value) success,
    required TResult Function(AuthResultFailure value) failure,
    required TResult Function(AuthResultLoading value) loading,
    required TResult Function(AuthResultInitial value) initial,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResultSuccess value)? success,
    TResult? Function(AuthResultFailure value)? failure,
    TResult? Function(AuthResultLoading value)? loading,
    TResult? Function(AuthResultInitial value)? initial,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResultSuccess value)? success,
    TResult Function(AuthResultFailure value)? failure,
    TResult Function(AuthResultLoading value)? loading,
    TResult Function(AuthResultInitial value)? initial,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResultCopyWith<$Res> {
  factory $AuthResultCopyWith(
          AuthResult value, $Res Function(AuthResult) then) =
      _$AuthResultCopyWithImpl<$Res, AuthResult>;
}

/// @nodoc
class _$AuthResultCopyWithImpl<$Res, $Val extends AuthResult>
    implements $AuthResultCopyWith<$Res> {
  _$AuthResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$AuthResultSuccessImplCopyWith<$Res> {
  factory _$$AuthResultSuccessImplCopyWith(_$AuthResultSuccessImpl value,
          $Res Function(_$AuthResultSuccessImpl) then) =
      __$$AuthResultSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({OdysseyUser? user, String? message});

  $OdysseyUserCopyWith<$Res>? get user;
}

/// @nodoc
class __$$AuthResultSuccessImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthResultSuccessImpl>
    implements _$$AuthResultSuccessImplCopyWith<$Res> {
  __$$AuthResultSuccessImplCopyWithImpl(_$AuthResultSuccessImpl _value,
      $Res Function(_$AuthResultSuccessImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = freezed,
    Object? message = freezed,
  }) {
    return _then(_$AuthResultSuccessImpl(
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as OdysseyUser?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $OdysseyUserCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $OdysseyUserCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value));
    });
  }
}

/// @nodoc

class _$AuthResultSuccessImpl extends AuthResultSuccess {
  const _$AuthResultSuccessImpl({this.user, this.message}) : super._();

  /// Usuário resultante (null em operações como logout)
  @override
  final OdysseyUser? user;

  /// Mensagem opcional de sucesso
  @override
  final String? message;

  @override
  String toString() {
    return 'AuthResult.success(user: $user, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResultSuccessImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, user, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResultSuccessImplCopyWith<_$AuthResultSuccessImpl> get copyWith =>
      __$$AuthResultSuccessImplCopyWithImpl<_$AuthResultSuccessImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(OdysseyUser? user, String? message) success,
    required TResult Function(
            String message, String? errorCode, Object? exception)
        failure,
    required TResult Function() loading,
    required TResult Function() initial,
  }) {
    return success(user, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(OdysseyUser? user, String? message)? success,
    TResult? Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult? Function()? loading,
    TResult? Function()? initial,
  }) {
    return success?.call(user, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(OdysseyUser? user, String? message)? success,
    TResult Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult Function()? loading,
    TResult Function()? initial,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(user, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResultSuccess value) success,
    required TResult Function(AuthResultFailure value) failure,
    required TResult Function(AuthResultLoading value) loading,
    required TResult Function(AuthResultInitial value) initial,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResultSuccess value)? success,
    TResult? Function(AuthResultFailure value)? failure,
    TResult? Function(AuthResultLoading value)? loading,
    TResult? Function(AuthResultInitial value)? initial,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResultSuccess value)? success,
    TResult Function(AuthResultFailure value)? failure,
    TResult Function(AuthResultLoading value)? loading,
    TResult Function(AuthResultInitial value)? initial,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class AuthResultSuccess extends AuthResult {
  const factory AuthResultSuccess(
      {final OdysseyUser? user,
      final String? message}) = _$AuthResultSuccessImpl;
  const AuthResultSuccess._() : super._();

  /// Usuário resultante (null em operações como logout)
  OdysseyUser? get user;

  /// Mensagem opcional de sucesso
  String? get message;
  @JsonKey(ignore: true)
  _$$AuthResultSuccessImplCopyWith<_$AuthResultSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AuthResultFailureImplCopyWith<$Res> {
  factory _$$AuthResultFailureImplCopyWith(_$AuthResultFailureImpl value,
          $Res Function(_$AuthResultFailureImpl) then) =
      __$$AuthResultFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, String? errorCode, Object? exception});
}

/// @nodoc
class __$$AuthResultFailureImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthResultFailureImpl>
    implements _$$AuthResultFailureImplCopyWith<$Res> {
  __$$AuthResultFailureImplCopyWithImpl(_$AuthResultFailureImpl _value,
      $Res Function(_$AuthResultFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? errorCode = freezed,
    Object? exception = freezed,
  }) {
    return _then(_$AuthResultFailureImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      exception: freezed == exception ? _value.exception : exception,
    ));
  }
}

/// @nodoc

class _$AuthResultFailureImpl extends AuthResultFailure {
  const _$AuthResultFailureImpl(
      {required this.message, this.errorCode, this.exception})
      : super._();

  /// Mensagem de erro para exibir ao usuário
  @override
  final String message;

  /// Código de erro (para debugging/analytics)
  @override
  final String? errorCode;

  /// Exceção original (para debugging)
  @override
  final Object? exception;

  @override
  String toString() {
    return 'AuthResult.failure(message: $message, errorCode: $errorCode, exception: $exception)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResultFailureImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode) &&
            const DeepCollectionEquality().equals(other.exception, exception));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, errorCode,
      const DeepCollectionEquality().hash(exception));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResultFailureImplCopyWith<_$AuthResultFailureImpl> get copyWith =>
      __$$AuthResultFailureImplCopyWithImpl<_$AuthResultFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(OdysseyUser? user, String? message) success,
    required TResult Function(
            String message, String? errorCode, Object? exception)
        failure,
    required TResult Function() loading,
    required TResult Function() initial,
  }) {
    return failure(message, errorCode, exception);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(OdysseyUser? user, String? message)? success,
    TResult? Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult? Function()? loading,
    TResult? Function()? initial,
  }) {
    return failure?.call(message, errorCode, exception);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(OdysseyUser? user, String? message)? success,
    TResult Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult Function()? loading,
    TResult Function()? initial,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(message, errorCode, exception);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResultSuccess value) success,
    required TResult Function(AuthResultFailure value) failure,
    required TResult Function(AuthResultLoading value) loading,
    required TResult Function(AuthResultInitial value) initial,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResultSuccess value)? success,
    TResult? Function(AuthResultFailure value)? failure,
    TResult? Function(AuthResultLoading value)? loading,
    TResult? Function(AuthResultInitial value)? initial,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResultSuccess value)? success,
    TResult Function(AuthResultFailure value)? failure,
    TResult Function(AuthResultLoading value)? loading,
    TResult Function(AuthResultInitial value)? initial,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class AuthResultFailure extends AuthResult {
  const factory AuthResultFailure(
      {required final String message,
      final String? errorCode,
      final Object? exception}) = _$AuthResultFailureImpl;
  const AuthResultFailure._() : super._();

  /// Mensagem de erro para exibir ao usuário
  String get message;

  /// Código de erro (para debugging/analytics)
  String? get errorCode;

  /// Exceção original (para debugging)
  Object? get exception;
  @JsonKey(ignore: true)
  _$$AuthResultFailureImplCopyWith<_$AuthResultFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AuthResultLoadingImplCopyWith<$Res> {
  factory _$$AuthResultLoadingImplCopyWith(_$AuthResultLoadingImpl value,
          $Res Function(_$AuthResultLoadingImpl) then) =
      __$$AuthResultLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AuthResultLoadingImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthResultLoadingImpl>
    implements _$$AuthResultLoadingImplCopyWith<$Res> {
  __$$AuthResultLoadingImplCopyWithImpl(_$AuthResultLoadingImpl _value,
      $Res Function(_$AuthResultLoadingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$AuthResultLoadingImpl extends AuthResultLoading {
  const _$AuthResultLoadingImpl() : super._();

  @override
  String toString() {
    return 'AuthResult.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AuthResultLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(OdysseyUser? user, String? message) success,
    required TResult Function(
            String message, String? errorCode, Object? exception)
        failure,
    required TResult Function() loading,
    required TResult Function() initial,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(OdysseyUser? user, String? message)? success,
    TResult? Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult? Function()? loading,
    TResult? Function()? initial,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(OdysseyUser? user, String? message)? success,
    TResult Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult Function()? loading,
    TResult Function()? initial,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResultSuccess value) success,
    required TResult Function(AuthResultFailure value) failure,
    required TResult Function(AuthResultLoading value) loading,
    required TResult Function(AuthResultInitial value) initial,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResultSuccess value)? success,
    TResult? Function(AuthResultFailure value)? failure,
    TResult? Function(AuthResultLoading value)? loading,
    TResult? Function(AuthResultInitial value)? initial,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResultSuccess value)? success,
    TResult Function(AuthResultFailure value)? failure,
    TResult Function(AuthResultLoading value)? loading,
    TResult Function(AuthResultInitial value)? initial,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class AuthResultLoading extends AuthResult {
  const factory AuthResultLoading() = _$AuthResultLoadingImpl;
  const AuthResultLoading._() : super._();
}

/// @nodoc
abstract class _$$AuthResultInitialImplCopyWith<$Res> {
  factory _$$AuthResultInitialImplCopyWith(_$AuthResultInitialImpl value,
          $Res Function(_$AuthResultInitialImpl) then) =
      __$$AuthResultInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AuthResultInitialImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthResultInitialImpl>
    implements _$$AuthResultInitialImplCopyWith<$Res> {
  __$$AuthResultInitialImplCopyWithImpl(_$AuthResultInitialImpl _value,
      $Res Function(_$AuthResultInitialImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$AuthResultInitialImpl extends AuthResultInitial {
  const _$AuthResultInitialImpl() : super._();

  @override
  String toString() {
    return 'AuthResult.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AuthResultInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(OdysseyUser? user, String? message) success,
    required TResult Function(
            String message, String? errorCode, Object? exception)
        failure,
    required TResult Function() loading,
    required TResult Function() initial,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(OdysseyUser? user, String? message)? success,
    TResult? Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult? Function()? loading,
    TResult? Function()? initial,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(OdysseyUser? user, String? message)? success,
    TResult Function(String message, String? errorCode, Object? exception)?
        failure,
    TResult Function()? loading,
    TResult Function()? initial,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthResultSuccess value) success,
    required TResult Function(AuthResultFailure value) failure,
    required TResult Function(AuthResultLoading value) loading,
    required TResult Function(AuthResultInitial value) initial,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthResultSuccess value)? success,
    TResult? Function(AuthResultFailure value)? failure,
    TResult? Function(AuthResultLoading value)? loading,
    TResult? Function(AuthResultInitial value)? initial,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthResultSuccess value)? success,
    TResult Function(AuthResultFailure value)? failure,
    TResult Function(AuthResultLoading value)? loading,
    TResult Function(AuthResultInitial value)? initial,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class AuthResultInitial extends AuthResult {
  const factory AuthResultInitial() = _$AuthResultInitialImpl;
  const AuthResultInitial._() : super._();
}
