import 'package:hive/hive.dart';
import '../../domain/models/odyssey_user.dart';
import '../../domain/models/account_type.dart';

/// Adapter Hive para OdysseyUser
/// 
/// Como Freezed e Hive não funcionam bem juntos com @HiveType,
/// usamos um adapter manual para serialização.
class OdysseyUserAdapter extends TypeAdapter<OdysseyUser> {
  @override
  final int typeId = 30;

  @override
  OdysseyUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return OdysseyUser(
      uid: fields[0] as String,
      displayName: fields[1] as String,
      email: fields[2] as String?,
      photoURL: fields[3] as String?,
      isGuest: fields[4] as bool? ?? false,
      isPro: fields[5] as bool? ?? false,
      accountType: fields[6] as AccountType? ?? AccountType.free,
      proExpiresAt: fields[7] as DateTime?,
      createdAt: fields[8] as DateTime? ?? DateTime.now(),
      lastSyncAt: fields[9] as DateTime?,
      preferences: (fields[10] as Map?)?.cast<String, dynamic>() ?? {},
      syncEnabled: fields[11] as bool? ?? true,
      currentDeviceId: fields[12] as String?,
      devices: (fields[13] as List?)?.cast<String>() ?? [],
      emailVerified: fields[14] as bool? ?? false,
      authProvider: fields[15] as String? ?? 'guest',
    );
  }

  @override
  void write(BinaryWriter writer, OdysseyUser obj) {
    writer
      ..writeByte(16) // Número de campos
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.photoURL)
      ..writeByte(4)
      ..write(obj.isGuest)
      ..writeByte(5)
      ..write(obj.isPro)
      ..writeByte(6)
      ..write(obj.accountType)
      ..writeByte(7)
      ..write(obj.proExpiresAt)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastSyncAt)
      ..writeByte(10)
      ..write(obj.preferences)
      ..writeByte(11)
      ..write(obj.syncEnabled)
      ..writeByte(12)
      ..write(obj.currentDeviceId)
      ..writeByte(13)
      ..write(obj.devices)
      ..writeByte(14)
      ..write(obj.emailVerified)
      ..writeByte(15)
      ..write(obj.authProvider);
  }
}

/// Adapter Hive para AccountType
class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 31;

  @override
  AccountType read(BinaryReader reader) {
    final index = reader.readByte();
    return AccountType.values[index];
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    writer.writeByte(obj.index);
  }
}
