/// Tipo de conta do usuário
enum AccountType {
  /// Usuário visitante (dados apenas locais)
  guest,

  /// Usuário gratuito (com conta)
  free,

  /// Usuário PRO (assinatura mensal/anual)
  pro,

  /// Usuário PRO vitalício
  proLifetime,
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.guest:
        return 'Visitante';
      case AccountType.free:
        return 'Gratuito';
      case AccountType.pro:
        return 'PRO';
      case AccountType.proLifetime:
        return 'PRO Vitalício';
    }
  }

  bool get isPro => this == AccountType.pro || this == AccountType.proLifetime;
  
  bool get isGuest => this == AccountType.guest;
  
  bool get canSync => this != AccountType.guest;
  
  /// Converte para string para serialização JSON
  String toJson() => name;
  
  /// Cria a partir de string
  static AccountType fromJson(String json) {
    return AccountType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => AccountType.free,
    );
  }
}
