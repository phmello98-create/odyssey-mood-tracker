import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/purchase_service.dart';

/// Tipos de plano disponíveis
enum SubscriptionPlan {
  free,    // Com ads
  pro,     // Sem ads + recursos extras
}

/// Estado da assinatura
class SubscriptionState {
  final SubscriptionPlan plan;
  final bool adsEnabled;
  final DateTime? proExpiresAt;
  final bool isLifetime;
  final bool isLoading;
  final String? errorMessage;

  const SubscriptionState({
    this.plan = SubscriptionPlan.free,
    this.adsEnabled = true,
    this.proExpiresAt,
    this.isLifetime = false,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isPro => plan == SubscriptionPlan.pro;
  
  bool get isProValid {
    if (plan != SubscriptionPlan.pro) return false;
    if (isLifetime) return true;
    if (proExpiresAt == null) return false;
    return proExpiresAt!.isAfter(DateTime.now());
  }

  SubscriptionState copyWith({
    SubscriptionPlan? plan,
    bool? adsEnabled,
    DateTime? proExpiresAt,
    bool? isLifetime,
    bool? isLoading,
    String? errorMessage,
    bool clearExpiration = false,
    bool clearError = false,
  }) {
    return SubscriptionState(
      plan: plan ?? this.plan,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      proExpiresAt: clearExpiration ? null : (proExpiresAt ?? this.proExpiresAt),
      isLifetime: isLifetime ?? this.isLifetime,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier para gerenciar assinatura
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    _initialize();
  }

  static const _planKey = 'subscription_plan';
  static const _adsEnabledKey = 'ads_enabled';
  static const _proExpiresAtKey = 'pro_expires_at';
  static const _isLifetimeKey = 'pro_is_lifetime';

  final _purchaseService = PurchaseService();
  StreamSubscription? _purchaseSubscription;

  Future<void> _initialize() async {
    await _loadSubscription();
    await _initializePurchaseService();
  }

  Future<void> _loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    
    final planIndex = prefs.getInt(_planKey) ?? 0;
    final plan = SubscriptionPlan.values[planIndex];
    
    final adsEnabled = prefs.getBool(_adsEnabledKey) ?? true;
    final isLifetime = prefs.getBool(_isLifetimeKey) ?? false;
    
    final expiresAtStr = prefs.getString(_proExpiresAtKey);
    DateTime? proExpiresAt;
    if (expiresAtStr != null) {
      proExpiresAt = DateTime.tryParse(expiresAtStr);
    }
    
    state = SubscriptionState(
      plan: plan,
      adsEnabled: adsEnabled,
      proExpiresAt: proExpiresAt,
      isLifetime: isLifetime,
    );
  }

  Future<void> _initializePurchaseService() async {
    await _purchaseService.initialize();
    
    // Ouvir resultados de compra
    _purchaseSubscription = _purchaseService.purchaseStream.listen((result) {
      if (result.success && result.productId != null) {
        _handleSuccessfulPurchase(result.productId!);
      } else if (!result.success && result.errorMessage != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.errorMessage,
        );
      }
    });
    
    // Configurar callbacks
    _purchaseService.onPurchaseSuccess = _handleSuccessfulPurchase;
    _purchaseService.onPurchaseError = (error) {
      state = state.copyWith(isLoading: false, errorMessage: error);
    };
  }

  void _handleSuccessfulPurchase(String productId) {
    debugPrint('[SubscriptionNotifier] Purchase successful: $productId');
    
    if (productId == ProductIds.proLifetime) {
      activateProLifetime();
    } else if (productId == ProductIds.proMonthly) {
      activateProSubscription(const Duration(days: 30));
    } else if (productId == ProductIds.proYearly) {
      activateProSubscription(const Duration(days: 365));
    }
    
    state = state.copyWith(isLoading: false, clearError: true);
  }

  Future<void> _saveSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_planKey, state.plan.index);
    await prefs.setBool(_adsEnabledKey, state.adsEnabled);
    await prefs.setBool(_isLifetimeKey, state.isLifetime);
    
    if (state.proExpiresAt != null) {
      await prefs.setString(_proExpiresAtKey, state.proExpiresAt!.toIso8601String());
    } else {
      await prefs.remove(_proExpiresAtKey);
    }
  }

  /// Ativar PRO vitalício (compra única)
  Future<void> activateProLifetime() async {
    state = state.copyWith(
      plan: SubscriptionPlan.pro,
      adsEnabled: false,
      isLifetime: true,
      clearExpiration: true,
    );
    await _saveSubscription();
  }

  /// Ativar PRO por período (assinatura)
  Future<void> activateProSubscription(Duration duration) async {
    final expiresAt = DateTime.now().add(duration);
    state = state.copyWith(
      plan: SubscriptionPlan.pro,
      adsEnabled: false,
      proExpiresAt: expiresAt,
      isLifetime: false,
    );
    await _saveSubscription();
  }

  /// Reverter para FREE
  Future<void> downgradeToFree() async {
    state = state.copyWith(
      plan: SubscriptionPlan.free,
      adsEnabled: true,
      isLifetime: false,
      clearExpiration: true,
    );
    await _saveSubscription();
  }

  /// Verificar e atualizar status (chamar no início do app)
  Future<void> checkAndUpdateStatus() async {
    if (state.plan == SubscriptionPlan.pro && !state.isLifetime) {
      if (state.proExpiresAt != null && state.proExpiresAt!.isBefore(DateTime.now())) {
        await downgradeToFree();
      }
    }
  }

  // ============================================
  // MÉTODOS DE COMPRA (integração com loja)
  // ============================================

  /// Comprar PRO vitalício via Play Store
  Future<bool> purchaseLifetime() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    if (!_purchaseService.isAvailable) {
      // Em desenvolvimento, ativa direto
      if (kDebugMode) {
        await activateProLifetime();
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Loja não disponível',
      );
      return false;
    }
    
    return await _purchaseService.purchaseLifetime();
  }

  /// Comprar assinatura mensal via Play Store
  Future<bool> purchaseMonthly() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    if (!_purchaseService.isAvailable) {
      if (kDebugMode) {
        await activateProSubscription(const Duration(days: 30));
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Loja não disponível',
      );
      return false;
    }
    
    return await _purchaseService.purchaseMonthly();
  }

  /// Comprar assinatura anual via Play Store
  Future<bool> purchaseYearly() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    if (!_purchaseService.isAvailable) {
      if (kDebugMode) {
        await activateProSubscription(const Duration(days: 365));
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Loja não disponível',
      );
      return false;
    }
    
    return await _purchaseService.purchaseYearly();
  }

  /// Restaurar compra (verificar com store)
  Future<bool> restorePurchase() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    if (!_purchaseService.isAvailable) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Loja não disponível',
      );
      return false;
    }
    
    await _purchaseService.restorePurchases();
    // O resultado virá via stream
    return true;
  }

  /// Obter preço de um produto
  String? getPrice(String productId) {
    return _purchaseService.getPrice(productId);
  }

  /// Obter preço do PRO vitalício
  String get lifetimePrice => 
      _purchaseService.getPrice(ProductIds.proLifetime) ?? 'R\$ 29,90';

  /// Obter preço do PRO mensal
  String get monthlyPrice => 
      _purchaseService.getPrice(ProductIds.proMonthly) ?? 'R\$ 4,90';

  /// Obter preço do PRO anual
  String get yearlyPrice => 
      _purchaseService.getPrice(ProductIds.proYearly) ?? 'R\$ 39,90';

  /// Limpar erro
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

/// Providers
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

final isProProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isProValid;
});

final showAdsProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.adsEnabled && !subscription.isProValid;
});

/// Benefícios do PRO
class ProBenefits {
  static const List<ProBenefit> benefits = [
    ProBenefit(
      icon: '🚫',
      title: 'Sem Anúncios',
      description: 'Experiência limpa e sem interrupções',
    ),
    ProBenefit(
      icon: '📊',
      title: 'Análises Avançadas',
      description: 'Gráficos detalhados e insights profundos',
    ),
    ProBenefit(
      icon: '☁️',
      title: 'Backup Ilimitado',
      description: 'Sincronização automática na nuvem',
    ),
    ProBenefit(
      icon: '🎨',
      title: 'Temas Exclusivos',
      description: 'Acesso a todos os temas premium',
    ),
    ProBenefit(
      icon: '📱',
      title: 'Widgets',
      description: 'Widgets personalizados na tela inicial',
    ),
    ProBenefit(
      icon: '🔔',
      title: 'Lembretes Ilimitados',
      description: 'Configure quantos lembretes precisar',
    ),
  ];
}

class ProBenefit {
  final String icon;
  final String title;
  final String description;

  const ProBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });
}
