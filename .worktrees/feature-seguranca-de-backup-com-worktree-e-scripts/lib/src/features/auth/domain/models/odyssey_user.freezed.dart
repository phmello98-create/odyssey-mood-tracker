// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'odyssey_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OdysseyUser _$OdysseyUserFromJson(Map<String, dynamic> json) {
  return _OdysseyUser.fromJson(json);
}

/// @nodoc
mixin _$OdysseyUser {
  /// ID único do usuário (Firebase UID ou guest_uuid)
  String get uid => throw _privateConstructorUsedError;

  /// Nome de exibição
  String get displayName => throw _privateConstructorUsedError;

  /// Email (null para guests)
  String? get email => throw _privateConstructorUsedError;

  /// URL da foto de perfil
  String? get photoURL => throw _privateConstructorUsedError;

  /// Se é um usuário visitante (local-only)
  bool get isGuest => throw _privateConstructorUsedError;

  /// Se possui assinatura PRO ativa
  bool get isPro => throw _privateConstructorUsedError;

  /// Tipo de conta
  AccountType get accountType => throw _privateConstructorUsedError;

  /// Data de expiração do PRO (null se vitalício ou não PRO)
  DateTime? get proExpiresAt => throw _privateConstructorUsedError;

  /// Data de criação da conta
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Última sincronização com o servidor
  DateTime? get lastSyncAt => throw _privateConstructorUsedError;

  /// Preferências do usuário (configurações)
  Map<String, dynamic> get preferences => throw _privateConstructorUsedError;

  /// Se a sincronização está habilitada
  bool get syncEnabled => throw _privateConstructorUsedError;

  /// ID do dispositivo atual
  String? get currentDeviceId => throw _privateConstructorUsedError;

  /// Lista de dispositivos vinculados
  List<String> get devices => throw _privateConstructorUsedError;

  /// Se o email foi verificado
  bool get emailVerified => throw _privateConstructorUsedError;

  /// Provider de autenticação usado (google, email, guest)
  String get authProvider => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OdysseyUserCopyWith<OdysseyUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OdysseyUserCopyWith<$Res> {
  factory $OdysseyUserCopyWith(
          OdysseyUser value, $Res Function(OdysseyUser) then) =
      _$OdysseyUserCopyWithImpl<$Res, OdysseyUser>;
  @useResult
  $Res call(
      {String uid,
      String displayName,
      String? email,
      String? photoURL,
      bool isGuest,
      bool isPro,
      AccountType accountType,
      DateTime? proExpiresAt,
      DateTime createdAt,
      DateTime? lastSyncAt,
      Map<String, dynamic> preferences,
      bool syncEnabled,
      String? currentDeviceId,
      List<String> devices,
      bool emailVerified,
      String authProvider});
}

/// @nodoc
class _$OdysseyUserCopyWithImpl<$Res, $Val extends OdysseyUser>
    implements $OdysseyUserCopyWith<$Res> {
  _$OdysseyUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = null,
    Object? email = freezed,
    Object? photoURL = freezed,
    Object? isGuest = null,
    Object? isPro = null,
    Object? accountType = null,
    Object? proExpiresAt = freezed,
    Object? createdAt = null,
    Object? lastSyncAt = freezed,
    Object? preferences = null,
    Object? syncEnabled = null,
    Object? currentDeviceId = freezed,
    Object? devices = null,
    Object? emailVerified = null,
    Object? authProvider = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      isGuest: null == isGuest
          ? _value.isGuest
          : isGuest // ignore: cast_nullable_to_non_nullable
              as bool,
      isPro: null == isPro
          ? _value.isPro
          : isPro // ignore: cast_nullable_to_non_nullable
              as bool,
      accountType: null == accountType
          ? _value.accountType
          : accountType // ignore: cast_nullable_to_non_nullable
              as AccountType,
      proExpiresAt: freezed == proExpiresAt
          ? _value.proExpiresAt
          : proExpiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastSyncAt: freezed == lastSyncAt
          ? _value.lastSyncAt
          : lastSyncAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      preferences: null == preferences
          ? _value.preferences
          : preferences // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      syncEnabled: null == syncEnabled
          ? _value.syncEnabled
          : syncEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      currentDeviceId: freezed == currentDeviceId
          ? _value.currentDeviceId
          : currentDeviceId // ignore: cast_nullable_to_non_nullable
              as String?,
      devices: null == devices
          ? _value.devices
          : devices // ignore: cast_nullable_to_non_nullable
              as List<String>,
      emailVerified: null == emailVerified
          ? _value.emailVerified
          : emailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      authProvider: null == authProvider
          ? _value.authProvider
          : authProvider // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OdysseyUserImplCopyWith<$Res>
    implements $OdysseyUserCopyWith<$Res> {
  factory _$$OdysseyUserImplCopyWith(
          _$OdysseyUserImpl value, $Res Function(_$OdysseyUserImpl) then) =
      __$$OdysseyUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String displayName,
      String? email,
      String? photoURL,
      bool isGuest,
      bool isPro,
      AccountType accountType,
      DateTime? proExpiresAt,
      DateTime createdAt,
      DateTime? lastSyncAt,
      Map<String, dynamic> preferences,
      bool syncEnabled,
      String? currentDeviceId,
      List<String> devices,
      bool emailVerified,
      String authProvider});
}

/// @nodoc
class __$$OdysseyUserImplCopyWithImpl<$Res>
    extends _$OdysseyUserCopyWithImpl<$Res, _$OdysseyUserImpl>
    implements _$$OdysseyUserImplCopyWith<$Res> {
  __$$OdysseyUserImplCopyWithImpl(
      _$OdysseyUserImpl _value, $Res Function(_$OdysseyUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = null,
    Object? email = freezed,
    Object? photoURL = freezed,
    Object? isGuest = null,
    Object? isPro = null,
    Object? accountType = null,
    Object? proExpiresAt = freezed,
    Object? createdAt = null,
    Object? lastSyncAt = freezed,
    Object? preferences = null,
    Object? syncEnabled = null,
    Object? currentDeviceId = freezed,
    Object? devices = null,
    Object? emailVerified = null,
    Object? authProvider = null,
  }) {
    return _then(_$OdysseyUserImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      isGuest: null == isGuest
          ? _value.isGuest
          : isGuest // ignore: cast_nullable_to_non_nullable
              as bool,
      isPro: null == isPro
          ? _value.isPro
          : isPro // ignore: cast_nullable_to_non_nullable
              as bool,
      accountType: null == accountType
          ? _value.accountType
          : accountType // ignore: cast_nullable_to_non_nullable
              as AccountType,
      proExpiresAt: freezed == proExpiresAt
          ? _value.proExpiresAt
          : proExpiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastSyncAt: freezed == lastSyncAt
          ? _value.lastSyncAt
          : lastSyncAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      preferences: null == preferences
          ? _value._preferences
          : preferences // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      syncEnabled: null == syncEnabled
          ? _value.syncEnabled
          : syncEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      currentDeviceId: freezed == currentDeviceId
          ? _value.currentDeviceId
          : currentDeviceId // ignore: cast_nullable_to_non_nullable
              as String?,
      devices: null == devices
          ? _value._devices
          : devices // ignore: cast_nullable_to_non_nullable
              as List<String>,
      emailVerified: null == emailVerified
          ? _value.emailVerified
          : emailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      authProvider: null == authProvider
          ? _value.authProvider
          : authProvider // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OdysseyUserImpl extends _OdysseyUser {
  const _$OdysseyUserImpl(
      {required this.uid,
      required this.displayName,
      this.email,
      this.photoURL,
      this.isGuest = false,
      this.isPro = false,
      this.accountType = AccountType.free,
      this.proExpiresAt,
      required this.createdAt,
      this.lastSyncAt,
      final Map<String, dynamic> preferences = const {},
      this.syncEnabled = true,
      this.currentDeviceId,
      final List<String> devices = const [],
      this.emailVerified = false,
      this.authProvider = 'guest'})
      : _preferences = preferences,
        _devices = devices,
        super._();

  factory _$OdysseyUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$OdysseyUserImplFromJson(json);

  /// ID único do usuário (Firebase UID ou guest_uuid)
  @override
  final String uid;

  /// Nome de exibição
  @override
  final String displayName;

  /// Email (null para guests)
  @override
  final String? email;

  /// URL da foto de perfil
  @override
  final String? photoURL;

  /// Se é um usuário visitante (local-only)
  @override
  @JsonKey()
  final bool isGuest;

  /// Se possui assinatura PRO ativa
  @override
  @JsonKey()
  final bool isPro;

  /// Tipo de conta
  @override
  @JsonKey()
  final AccountType accountType;

  /// Data de expiração do PRO (null se vitalício ou não PRO)
  @override
  final DateTime? proExpiresAt;

  /// Data de criação da conta
  @override
  final DateTime createdAt;

  /// Última sincronização com o servidor
  @override
  final DateTime? lastSyncAt;

  /// Preferências do usuário (configurações)
  final Map<String, dynamic> _preferences;

  /// Preferências do usuário (configurações)
  @override
  @JsonKey()
  Map<String, dynamic> get preferences {
    if (_preferences is EqualUnmodifiableMapView) return _preferences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_preferences);
  }

  /// Se a sincronização está habilitada
  @override
  @JsonKey()
  final bool syncEnabled;

  /// ID do dispositivo atual
  @override
  final String? currentDeviceId;

  /// Lista de dispositivos vinculados
  final List<String> _devices;

  /// Lista de dispositivos vinculados
  @override
  @JsonKey()
  List<String> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  /// Se o email foi verificado
  @override
  @JsonKey()
  final bool emailVerified;

  /// Provider de autenticação usado (google, email, guest)
  @override
  @JsonKey()
  final String authProvider;

  @override
  String toString() {
    return 'OdysseyUser(uid: $uid, displayName: $displayName, email: $email, photoURL: $photoURL, isGuest: $isGuest, isPro: $isPro, accountType: $accountType, proExpiresAt: $proExpiresAt, createdAt: $createdAt, lastSyncAt: $lastSyncAt, preferences: $preferences, syncEnabled: $syncEnabled, currentDeviceId: $currentDeviceId, devices: $devices, emailVerified: $emailVerified, authProvider: $authProvider)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OdysseyUserImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.photoURL, photoURL) ||
                other.photoURL == photoURL) &&
            (identical(other.isGuest, isGuest) || other.isGuest == isGuest) &&
            (identical(other.isPro, isPro) || other.isPro == isPro) &&
            (identical(other.accountType, accountType) ||
                other.accountType == accountType) &&
            (identical(other.proExpiresAt, proExpiresAt) ||
                other.proExpiresAt == proExpiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt) &&
            const DeepCollectionEquality()
                .equals(other._preferences, _preferences) &&
            (identical(other.syncEnabled, syncEnabled) ||
                other.syncEnabled == syncEnabled) &&
            (identical(other.currentDeviceId, currentDeviceId) ||
                other.currentDeviceId == currentDeviceId) &&
            const DeepCollectionEquality().equals(other._devices, _devices) &&
            (identical(other.emailVerified, emailVerified) ||
                other.emailVerified == emailVerified) &&
            (identical(other.authProvider, authProvider) ||
                other.authProvider == authProvider));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      uid,
      displayName,
      email,
      photoURL,
      isGuest,
      isPro,
      accountType,
      proExpiresAt,
      createdAt,
      lastSyncAt,
      const DeepCollectionEquality().hash(_preferences),
      syncEnabled,
      currentDeviceId,
      const DeepCollectionEquality().hash(_devices),
      emailVerified,
      authProvider);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OdysseyUserImplCopyWith<_$OdysseyUserImpl> get copyWith =>
      __$$OdysseyUserImplCopyWithImpl<_$OdysseyUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OdysseyUserImplToJson(
      this,
    );
  }
}

abstract class _OdysseyUser extends OdysseyUser {
  const factory _OdysseyUser(
      {required final String uid,
      required final String displayName,
      final String? email,
      final String? photoURL,
      final bool isGuest,
      final bool isPro,
      final AccountType accountType,
      final DateTime? proExpiresAt,
      required final DateTime createdAt,
      final DateTime? lastSyncAt,
      final Map<String, dynamic> preferences,
      final bool syncEnabled,
      final String? currentDeviceId,
      final List<String> devices,
      final bool emailVerified,
      final String authProvider}) = _$OdysseyUserImpl;
  const _OdysseyUser._() : super._();

  factory _OdysseyUser.fromJson(Map<String, dynamic> json) =
      _$OdysseyUserImpl.fromJson;

  @override

  /// ID único do usuário (Firebase UID ou guest_uuid)
  String get uid;
  @override

  /// Nome de exibição
  String get displayName;
  @override

  /// Email (null para guests)
  String? get email;
  @override

  /// URL da foto de perfil
  String? get photoURL;
  @override

  /// Se é um usuário visitante (local-only)
  bool get isGuest;
  @override

  /// Se possui assinatura PRO ativa
  bool get isPro;
  @override

  /// Tipo de conta
  AccountType get accountType;
  @override

  /// Data de expiração do PRO (null se vitalício ou não PRO)
  DateTime? get proExpiresAt;
  @override

  /// Data de criação da conta
  DateTime get createdAt;
  @override

  /// Última sincronização com o servidor
  DateTime? get lastSyncAt;
  @override

  /// Preferências do usuário (configurações)
  Map<String, dynamic> get preferences;
  @override

  /// Se a sincronização está habilitada
  bool get syncEnabled;
  @override

  /// ID do dispositivo atual
  String? get currentDeviceId;
  @override

  /// Lista de dispositivos vinculados
  List<String> get devices;
  @override

  /// Se o email foi verificado
  bool get emailVerified;
  @override

  /// Provider de autenticação usado (google, email, guest)
  String get authProvider;
  @override
  @JsonKey(ignore: true)
  _$$OdysseyUserImplCopyWith<_$OdysseyUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
