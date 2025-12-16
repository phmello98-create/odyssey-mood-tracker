import 'package:freezed_annotation/freezed_annotation.dart';
import 'account_type.dart';

part 'odyssey_user.freezed.dart';
part 'odyssey_user.g.dart';

/// Modelo de usuário completo do Odyssey
/// 
/// Este modelo representa o usuário em todas as camadas da aplicação,
/// com suporte a serialização JSON para Firestore.
/// Para persistência Hive, use OdysseyUserHiveAdapter.
@freezed
class OdysseyUser with _$OdysseyUser {
  const OdysseyUser._();
  
  const factory OdysseyUser({
    /// ID único do usuário (Firebase UID ou guest_uuid)
    required String uid,
    
    /// Nome de exibição
    required String displayName,
    
    /// Email (null para guests)
    String? email,
    
    /// URL da foto de perfil
    String? photoURL,
    
    /// Se é um usuário visitante (local-only)
    @Default(false) bool isGuest,
    
    /// Se possui assinatura PRO ativa
    @Default(false) bool isPro,
    
    /// Tipo de conta
    @Default(AccountType.free) AccountType accountType,
    
    /// Data de expiração do PRO (null se vitalício ou não PRO)
    DateTime? proExpiresAt,
    
    /// Data de criação da conta
    required DateTime createdAt,
    
    /// Última sincronização com o servidor
    DateTime? lastSyncAt,
    
    /// Preferências do usuário (configurações)
    @Default({}) Map<String, dynamic> preferences,
    
    /// Se a sincronização está habilitada
    @Default(true) bool syncEnabled,
    
    /// ID do dispositivo atual
    String? currentDeviceId,
    
    /// Lista de dispositivos vinculados
    @Default([]) List<String> devices,
    
    /// Se o email foi verificado
    @Default(false) bool emailVerified,
    
    /// Provider de autenticação usado (google, email, guest)
    @Default('guest') String authProvider,
  }) = _OdysseyUser;

  factory OdysseyUser.fromJson(Map<String, dynamic> json) =>
      _$OdysseyUserFromJson(json);

  /// Cria um usuário visitante
  factory OdysseyUser.guest({
    required String uid,
    String displayName = 'Visitante',
  }) {
    return OdysseyUser(
      uid: uid,
      displayName: displayName,
      isGuest: true,
      isPro: false,
      accountType: AccountType.guest,
      createdAt: DateTime.now(),
      syncEnabled: false,
      authProvider: 'guest',
    );
  }

  /// Verifica se a assinatura PRO expirou
  bool get isProExpired {
    if (!isPro) return false;
    if (accountType == AccountType.proLifetime) return false;
    if (proExpiresAt == null) return false;
    return DateTime.now().isAfter(proExpiresAt!);
  }

  /// Verifica se o usuário tem acesso PRO válido
  bool get hasValidProAccess => isPro && !isProExpired;

  /// Verifica se pode sincronizar dados
  bool get canSync => !isGuest && syncEnabled;

  /// Retorna as iniciais do nome para avatar
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
