// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'odyssey_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OdysseyUserImpl _$$OdysseyUserImplFromJson(Map<String, dynamic> json) =>
    _$OdysseyUserImpl(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String?,
      photoURL: json['photoURL'] as String?,
      isGuest: json['isGuest'] as bool? ?? false,
      isPro: json['isPro'] as bool? ?? false,
      accountType:
          $enumDecodeNullable(_$AccountTypeEnumMap, json['accountType']) ??
              AccountType.free,
      proExpiresAt: json['proExpiresAt'] == null
          ? null
          : DateTime.parse(json['proExpiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSyncAt: json['lastSyncAt'] == null
          ? null
          : DateTime.parse(json['lastSyncAt'] as String),
      preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
      syncEnabled: json['syncEnabled'] as bool? ?? true,
      currentDeviceId: json['currentDeviceId'] as String?,
      devices: (json['devices'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      emailVerified: json['emailVerified'] as bool? ?? false,
      authProvider: json['authProvider'] as String? ?? 'guest',
    );

Map<String, dynamic> _$$OdysseyUserImplToJson(_$OdysseyUserImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'displayName': instance.displayName,
      'email': instance.email,
      'photoURL': instance.photoURL,
      'isGuest': instance.isGuest,
      'isPro': instance.isPro,
      'accountType': _$AccountTypeEnumMap[instance.accountType]!,
      'proExpiresAt': instance.proExpiresAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
      'preferences': instance.preferences,
      'syncEnabled': instance.syncEnabled,
      'currentDeviceId': instance.currentDeviceId,
      'devices': instance.devices,
      'emailVerified': instance.emailVerified,
      'authProvider': instance.authProvider,
    };

const _$AccountTypeEnumMap = {
  AccountType.guest: 'guest',
  AccountType.free: 'free',
  AccountType.pro: 'pro',
  AccountType.proLifetime: 'proLifetime',
};
