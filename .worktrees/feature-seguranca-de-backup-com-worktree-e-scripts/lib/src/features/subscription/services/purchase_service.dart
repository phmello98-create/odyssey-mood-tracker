// lib/src/features/subscription/services/purchase_service.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// IDs dos produtos no Google Play / App Store
class ProductIds {
  // Compra única (vitalício)
  static const String proLifetime = 'odyssey_pro_lifetime';
  
  // Assinaturas
  static const String proMonthly = 'odyssey_pro_monthly';
  static const String proYearly = 'odyssey_pro_yearly';
  
  static const Set<String> all = {
    proLifetime,
    proMonthly,
    proYearly,
  };
  
  static const Set<String> subscriptions = {
    proMonthly,
    proYearly,
  };
  
  static const Set<String> consumables = {};
  
  static const Set<String> nonConsumables = {
    proLifetime,
  };
}

/// Estado de uma compra
enum PurchaseState {
  idle,
  loading,
  purchasing,
  restoring,
  success,
  error,
  cancelled,
}

/// Resultado de uma operação de compra
class PurchaseResult {
  final bool success;
  final String? productId;
  final String? errorMessage;
  final PurchaseDetails? purchaseDetails;

  const PurchaseResult({
    required this.success,
    this.productId,
    this.errorMessage,
    this.purchaseDetails,
  });

  factory PurchaseResult.successful(String productId, PurchaseDetails details) =>
      PurchaseResult(
        success: true,
        productId: productId,
        purchaseDetails: details,
      );

  factory PurchaseResult.failed(String message) => PurchaseResult(
        success: false,
        errorMessage: message,
      );

  factory PurchaseResult.cancelled() => const PurchaseResult(
        success: false,
        errorMessage: 'Compra cancelada pelo usuário',
      );
}

/// Serviço de compras in-app
/// 
/// Gerencia:
/// - Compra de PRO vitalício
/// - Assinaturas mensais/anuais
/// - Restauração de compras
/// - Verificação de status
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Stream controllers
  final _stateController = StreamController<PurchaseState>.broadcast();
  final _purchaseController = StreamController<PurchaseResult>.broadcast();
  
  // Estado
  bool _isAvailable = false;
  bool _isInitialized = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  
  // Callbacks
  void Function(String productId)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;
  
  /// Stream do estado atual
  Stream<PurchaseState> get stateStream => _stateController.stream;
  
  /// Stream de resultados de compra
  Stream<PurchaseResult> get purchaseStream => _purchaseController.stream;
  
  /// Se o serviço está disponível
  bool get isAvailable => _isAvailable;
  
  /// Se foi inicializado
  bool get isInitialized => _isInitialized;
  
  /// Lista de produtos disponíveis
  List<ProductDetails> get products => _products;
  
  /// Inicializa o serviço
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        debugPrint('[PurchaseService] Store not available');
        _isInitialized = true;
        return;
      }
      
      // Escutar atualizações de compra
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) => debugPrint('[PurchaseService] Purchase stream error: $error'),
      );
      
      // Carregar produtos
      await loadProducts();
      
      _isInitialized = true;
      debugPrint('[PurchaseService] Initialized successfully');
    } catch (e) {
      debugPrint('[PurchaseService] Error initializing: $e');
      _isInitialized = true;
    }
  }
  
  /// Carrega os produtos da loja
  Future<void> loadProducts() async {
    if (!_isAvailable) return;
    
    try {
      _stateController.add(PurchaseState.loading);
      
      final response = await _inAppPurchase.queryProductDetails(ProductIds.all);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[PurchaseService] Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('[PurchaseService] Loaded ${_products.length} products');
      
      for (final product in _products) {
        debugPrint('  - ${product.id}: ${product.price}');
      }
      
      _stateController.add(PurchaseState.idle);
    } catch (e) {
      debugPrint('[PurchaseService] Error loading products: $e');
      _stateController.add(PurchaseState.error);
    }
  }
  
  /// Obtém um produto pelo ID
  ProductDetails? getProduct(String productId) {
    return _products.where((p) => p.id == productId).firstOrNull;
  }
  
  /// Obtém o preço formatado de um produto
  String? getPrice(String productId) {
    return getProduct(productId)?.price;
  }
  
  /// Inicia a compra de um produto
  Future<bool> purchase(String productId) async {
    if (!_isAvailable) {
      _purchaseController.add(PurchaseResult.failed('Loja não disponível'));
      return false;
    }
    
    final product = getProduct(productId);
    if (product == null) {
      _purchaseController.add(PurchaseResult.failed('Produto não encontrado'));
      return false;
    }
    
    _stateController.add(PurchaseState.purchasing);
    
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      
      bool success;
      if (ProductIds.subscriptions.contains(productId)) {
        // Assinatura
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else if (ProductIds.consumables.contains(productId)) {
        // Consumível
        success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      } else {
        // Não-consumível (vitalício)
        success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
      
      if (!success) {
        _stateController.add(PurchaseState.error);
        _purchaseController.add(PurchaseResult.failed('Não foi possível iniciar a compra'));
      }
      
      return success;
    } catch (e) {
      debugPrint('[PurchaseService] Error purchasing: $e');
      _stateController.add(PurchaseState.error);
      _purchaseController.add(PurchaseResult.failed('Erro ao processar compra'));
      return false;
    }
  }
  
  /// Compra PRO vitalício
  Future<bool> purchaseLifetime() => purchase(ProductIds.proLifetime);
  
  /// Compra assinatura mensal
  Future<bool> purchaseMonthly() => purchase(ProductIds.proMonthly);
  
  /// Compra assinatura anual
  Future<bool> purchaseYearly() => purchase(ProductIds.proYearly);
  
  /// Restaura compras anteriores
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      _purchaseController.add(PurchaseResult.failed('Loja não disponível'));
      return;
    }
    
    _stateController.add(PurchaseState.restoring);
    
    try {
      await _inAppPurchase.restorePurchases();
      // O resultado virá via purchaseStream
    } catch (e) {
      debugPrint('[PurchaseService] Error restoring: $e');
      _stateController.add(PurchaseState.error);
      _purchaseController.add(PurchaseResult.failed('Erro ao restaurar compras'));
    }
  }
  
  /// Processa atualizações de compra
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      debugPrint('[PurchaseService] Purchase update: ${purchase.productID} - ${purchase.status}');
      
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _stateController.add(PurchaseState.purchasing);
          break;
          
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verificar compra (em produção, verificar no servidor)
          final valid = await _verifyPurchase(purchase);
          
          if (valid) {
            // Completar a compra (importante no Android)
            if (purchase.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(purchase);
            }
            
            _stateController.add(PurchaseState.success);
            _purchaseController.add(PurchaseResult.successful(
              purchase.productID,
              purchase,
            ));
            
            onPurchaseSuccess?.call(purchase.productID);
          } else {
            _stateController.add(PurchaseState.error);
            _purchaseController.add(PurchaseResult.failed('Compra inválida'));
          }
          break;
          
        case PurchaseStatus.error:
          _stateController.add(PurchaseState.error);
          _purchaseController.add(PurchaseResult.failed(
            purchase.error?.message ?? 'Erro desconhecido',
          ));
          onPurchaseError?.call(purchase.error?.message ?? 'Erro');
          break;
          
        case PurchaseStatus.canceled:
          _stateController.add(PurchaseState.cancelled);
          _purchaseController.add(PurchaseResult.cancelled());
          break;
      }
    }
  }
  
  /// Verifica se uma compra é válida
  /// 
  /// Em produção, isso deve ser feito no servidor usando:
  /// - Google Play Developer API para Android
  /// - App Store Server API para iOS
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Implementar verificação no servidor
    // Por enquanto, aceita todas as compras
    
    if (kDebugMode) {
      debugPrint('[PurchaseService] Skipping verification in debug mode');
      return true;
    }
    
    // Em produção:
    // 1. Enviar purchase.verificationData para seu servidor
    // 2. Servidor verifica com Google/Apple
    // 3. Retornar resultado
    
    // Exemplo de dados de verificação:
    // Android: purchase.verificationData.serverVerificationData (token)
    // iOS: purchase.verificationData.serverVerificationData (receipt)
    
    return true;
  }
  
  /// Verifica se o usuário tem uma assinatura ativa
  /// 
  /// Chamar no início do app para verificar status
  Future<bool> hasActiveSubscription() async {
    if (!_isAvailable) return false;
    
    try {
      // No Android, podemos verificar compras passadas
      if (Platform.isAndroid) {
        // Usar Google Play Billing Library
        // Isso requer implementação adicional
      }
      
      // No iOS, verificar receipt
      if (Platform.isIOS) {
        // Verificar receipt com Apple
      }
      
      // Por enquanto, retorna false (verificar via SharedPreferences)
      return false;
    } catch (e) {
      debugPrint('[PurchaseService] Error checking subscription: $e');
      return false;
    }
  }
  
  /// Libera recursos
  void dispose() {
    _purchaseSubscription?.cancel();
    _stateController.close();
    _purchaseController.close();
  }
}

/// Extensão para facilitar acesso aos dados do produto
extension ProductDetailsExtension on ProductDetails {
  /// Retorna o preço formatado
  String get formattedPrice => price;
  
  /// Retorna o período da assinatura (se aplicável)
  String? get subscriptionPeriod {
    if (!ProductIds.subscriptions.contains(id)) return null;
    
    if (id == ProductIds.proMonthly) return 'mês';
    if (id == ProductIds.proYearly) return 'ano';
    return null;
  }
  
  /// Verifica se é uma assinatura
  bool get isSubscription => ProductIds.subscriptions.contains(id);
  
  /// Verifica se é o plano vitalício
  bool get isLifetime => id == ProductIds.proLifetime;
}
