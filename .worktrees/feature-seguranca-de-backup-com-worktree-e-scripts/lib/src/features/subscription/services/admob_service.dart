// lib/src/features/subscription/services/admob_service.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// IDs de anúncios do AdMob
/// 
/// IMPORTANTE: Substituir pelos IDs reais antes de publicar!
/// Os IDs abaixo são de TESTE do Google.
class AdMobIds {
  // ============================================
  // IDs DE TESTE (usar durante desenvolvimento)
  // ============================================
  
  // Banner Test IDs
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  
  // Interstitial Test IDs
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  
  // Rewarded Test IDs
  static const String _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  
  // ============================================
  // IDs DE PRODUÇÃO (Odyssey App)
  // ============================================
  
  // App ID: ca-app-pub-3976367803523988~7313887303
  static const String _prodBannerAndroid = 'ca-app-pub-3976367803523988/6825983900';
  static const String _prodBannerIos = 'ca-app-pub-3976367803523988/6825983900'; // TODO: Criar ID iOS separado
  
  static const String _prodInterstitialAndroid = 'ca-app-pub-3976367803523988/8146804435';
  static const String _prodInterstitialIos = 'ca-app-pub-3976367803523988/8146804435'; // TODO: Criar ID iOS separado
  
  static const String _prodRewardedAndroid = 'ca-app-pub-3976367803523988/3462272208';
  static const String _prodRewardedIos = 'ca-app-pub-3976367803523988/3462272208'; // TODO: Criar ID iOS separado
  
  // ============================================
  // GETTERS (retorna teste em debug, produção em release)
  // ============================================
  
  static bool get _isTest => kDebugMode;
  
  static String get bannerId {
    if (Platform.isAndroid) {
      return _isTest ? _testBannerAndroid : _prodBannerAndroid;
    } else if (Platform.isIOS) {
      return _isTest ? _testBannerIos : _prodBannerIos;
    }
    return _testBannerAndroid;
  }
  
  static String get interstitialId {
    if (Platform.isAndroid) {
      return _isTest ? _testInterstitialAndroid : _prodInterstitialAndroid;
    } else if (Platform.isIOS) {
      return _isTest ? _testInterstitialIos : _prodInterstitialIos;
    }
    return _testInterstitialAndroid;
  }
  
  static String get rewardedId {
    if (Platform.isAndroid) {
      return _isTest ? _testRewardedAndroid : _prodRewardedAndroid;
    } else if (Platform.isIOS) {
      return _isTest ? _testRewardedIos : _prodRewardedIos;
    }
    return _testRewardedAndroid;
  }
}

/// Serviço principal de AdMob
/// 
/// Gerencia todos os tipos de anúncios:
/// - Banner Ads
/// - Interstitial Ads
/// - Rewarded Ads
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;
  
  // Anúncios carregados
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  // Contadores para limitar frequência
  int _interstitialShowCount = 0;
  DateTime? _lastInterstitialTime;
  
  // Configurações
  static const int _minSecondsBetweenInterstitials = 120; // 2 minutos
  static const int _actionsBeforeInterstitial = 5; // A cada 5 ações
  
  /// Inicializa o SDK do AdMob
  /// Chamar no main() antes de runApp()
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdMob] SDK initialized');
      
      // Pré-carregar anúncios
      _loadInterstitialAd();
      _loadRewardedAd();
    } catch (e) {
      debugPrint('[AdMob] Error initializing: $e');
    }
  }
  
  /// Verifica se o SDK foi inicializado
  bool get isInitialized => _isInitialized;
  
  // ============================================
  // BANNER ADS
  // ============================================
  
  /// Cria um BannerAd para ser usado em widgets
  /// O widget deve gerenciar o dispose do banner
  BannerAd createBannerAd({
    AdSize size = AdSize.banner,
    void Function()? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) {
    return BannerAd(
      adUnitId: AdMobIds.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Banner loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] Banner failed: ${error.message}');
          ad.dispose();
          onFailed?.call(error);
        },
        onAdOpened: (ad) => debugPrint('[AdMob] Banner opened'),
        onAdClosed: (ad) => debugPrint('[AdMob] Banner closed'),
        onAdImpression: (ad) => debugPrint('[AdMob] Banner impression'),
      ),
    );
  }
  
  /// Cria um banner adaptativo para a largura da tela
  Future<BannerAd> createAdaptiveBannerAd({
    required double width,
    void Function()? onLoaded,
    void Function(LoadAdError)? onFailed,
  }) async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );
    
    return BannerAd(
      adUnitId: AdMobIds.bannerId,
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Adaptive banner loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] Adaptive banner failed: ${error.message}');
          ad.dispose();
          onFailed?.call(error);
        },
      ),
    );
  }
  
  // ============================================
  // INTERSTITIAL ADS
  // ============================================
  
  /// Carrega um anúncio intersticial
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdMobIds.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Interstitial loaded');
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] Interstitial failed to load: ${error.message}');
          _interstitialAd = null;
        },
      ),
    );
  }
  
  /// Verifica se o intersticial está pronto
  bool get isInterstitialReady => _interstitialAd != null;
  
  /// Mostra o anúncio intersticial
  /// Retorna true se mostrou, false se não estava pronto
  Future<bool> showInterstitialAd({
    void Function()? onDismissed,
  }) async {
    // Verificar cooldown
    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!);
      if (elapsed.inSeconds < _minSecondsBetweenInterstitials) {
        debugPrint('[AdMob] Interstitial cooldown active');
        return false;
      }
    }
    
    if (_interstitialAd == null) {
      debugPrint('[AdMob] Interstitial not ready');
      _loadInterstitialAd();
      return false;
    }
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] Interstitial dismissed');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Pré-carregar próximo
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] Interstitial failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdMob] Interstitial showed');
        _lastInterstitialTime = DateTime.now();
        _interstitialShowCount++;
      },
    );
    
    await _interstitialAd!.show();
    _interstitialAd = null;
    return true;
  }
  
  /// Incrementa contador de ações e mostra intersticial se atingir limite
  /// Use para mostrar ads após certas ações (salvar, completar tarefa, etc.)
  Future<bool> maybeShowInterstitialAfterAction() async {
    _interstitialShowCount++;
    
    if (_interstitialShowCount >= _actionsBeforeInterstitial) {
      _interstitialShowCount = 0;
      return await showInterstitialAd();
    }
    
    return false;
  }
  
  // ============================================
  // REWARDED ADS
  // ============================================
  
  /// Carrega um anúncio recompensado
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdMobIds.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Rewarded ad loaded');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] Rewarded ad failed to load: ${error.message}');
          _rewardedAd = null;
        },
      ),
    );
  }
  
  /// Verifica se o rewarded está pronto
  bool get isRewardedReady => _rewardedAd != null;
  
  /// Mostra o anúncio recompensado
  /// Retorna o item de recompensa se o usuário assistiu completo, null caso contrário
  Future<RewardItem?> showRewardedAd({
    void Function()? onDismissed,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('[AdMob] Rewarded ad not ready');
      _loadRewardedAd();
      return null;
    }
    
    RewardItem? earnedReward;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMob] Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Pré-carregar próximo
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[AdMob] User earned reward: ${reward.amount} ${reward.type}');
        earnedReward = reward;
      },
    );
    
    _rewardedAd = null;
    return earnedReward;
  }
  
  // ============================================
  // CLEANUP
  // ============================================
  
  /// Libera todos os recursos
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
  }
}

/// Tipos de recompensa disponíveis para rewarded ads
enum RewardType {
  extraXp,        // XP bônus
  skipCooldown,   // Pular cooldown
  unlockFeature,  // Desbloquear feature temporária
  extraTip,       // Dica extra
}

/// Resultado de um rewarded ad
class AdRewardResult {
  final bool watched;
  final RewardType? rewardType;
  final int? amount;

  const AdRewardResult({
    required this.watched,
    this.rewardType,
    this.amount,
  });

  factory AdRewardResult.notWatched() => const AdRewardResult(watched: false);
  
  factory AdRewardResult.earned({
    required RewardType type,
    int amount = 1,
  }) => AdRewardResult(
    watched: true,
    rewardType: type,
    amount: amount,
  );
}
