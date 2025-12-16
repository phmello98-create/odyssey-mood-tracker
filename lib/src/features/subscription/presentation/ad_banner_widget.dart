import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:odyssey/src/features/subscription/subscription_provider.dart';
import 'package:odyssey/src/features/subscription/services/admob_service.dart';

/// Widget de banner de anúncios usando AdMob
/// Mostra anúncio apenas se o usuário não for PRO
class AdBannerWidget extends ConsumerStatefulWidget {
  final double? height;
  final AdSize adSize;
  final EdgeInsets margin;

  const AdBannerWidget({
    super.key,
    this.height,
    this.adSize = AdSize.banner,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return;

    final adMob = AdMobService();
    if (!adMob.isInitialized) {
      // AdMob não inicializado, mostrar placeholder
      return;
    }

    _bannerAd = adMob.createBannerAd(
      size: widget.adSize,
      onLoaded: () {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      onFailed: (error) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      },
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAds = ref.watch(showAdsProvider);

    if (!showAds) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final height = widget.height ?? widget.adSize.height.toDouble();

    // Se o anúncio foi carregado, mostrar
    if (_isLoaded && _bannerAd != null) {
      return Container(
        height: height,
        margin: widget.margin,
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Se houve erro, não mostrar nada
    if (_hasError) {
      return const SizedBox.shrink();
    }

    // Placeholder enquanto carrega
    return Container(
      height: height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Widget de banner adaptativo que se ajusta à largura da tela
class AdaptiveBannerWidget extends ConsumerStatefulWidget {
  final EdgeInsets margin;

  const AdaptiveBannerWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  ConsumerState<AdaptiveBannerWidget> createState() => _AdaptiveBannerWidgetState();
}

class _AdaptiveBannerWidgetState extends ConsumerState<AdaptiveBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  double _adHeight = 50;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAdaptiveAd();
  }

  Future<void> _loadAdaptiveAd() async {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return;

    final adMob = AdMobService();
    if (!adMob.isInitialized) return;

    // Calcular largura disponível
    final width = MediaQuery.of(context).size.width - 
        widget.margin.left - widget.margin.right;

    _bannerAd = await adMob.createAdaptiveBannerAd(
      width: width,
      onLoaded: () {
        if (mounted) {
          setState(() {
            _isLoaded = true;
            _adHeight = _bannerAd!.size.height.toDouble();
          });
        }
      },
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAds = ref.watch(showAdsProvider);

    if (!showAds) {
      return const SizedBox.shrink();
    }

    if (_isLoaded && _bannerAd != null) {
      return Container(
        height: _adHeight,
        margin: widget.margin,
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Placeholder
    return Container(
      height: 50,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// Widget de anúncio intersticial (tela cheia)
class InterstitialAdManager {
  static final InterstitialAdManager _instance = InterstitialAdManager._internal();
  factory InterstitialAdManager() => _instance;
  InterstitialAdManager._internal();

  final _adMob = AdMobService();

  /// Mostrar anúncio intersticial (se carregado e usuário não for PRO)
  Future<bool> showAd(WidgetRef ref, {void Function()? onDismissed}) async {
    final showAds = ref.read(showAdsProvider);
    
    if (!showAds) {
      return false;
    }

    return await _adMob.showInterstitialAd(onDismissed: onDismissed);
  }

  /// Mostra intersticial após certas ações (contador interno)
  Future<bool> maybeShowAfterAction(WidgetRef ref) async {
    final showAds = ref.read(showAdsProvider);
    
    if (!showAds) {
      return false;
    }

    return await _adMob.maybeShowInterstitialAfterAction();
  }
}

/// Widget de anúncio recompensado
class RewardedAdManager {
  static final RewardedAdManager _instance = RewardedAdManager._internal();
  factory RewardedAdManager() => _instance;
  RewardedAdManager._internal();

  final _adMob = AdMobService();

  /// Verificar se anúncio está disponível
  bool get isAvailable => _adMob.isRewardedReady;

  /// Mostrar anúncio recompensado e retornar se usuário ganhou recompensa
  Future<bool> showAd({void Function()? onDismissed}) async {
    final reward = await _adMob.showRewardedAd(onDismissed: onDismissed);
    return reward != null;
  }

  /// Mostrar anúncio e retornar quantidade da recompensa
  Future<int> showAdForReward({void Function()? onDismissed}) async {
    final reward = await _adMob.showRewardedAd(onDismissed: onDismissed);
    return reward?.amount.toInt() ?? 0;
  }
}

/// Botão para assistir anúncio e ganhar recompensa
class WatchAdButton extends ConsumerWidget {
  final String label;
  final String rewardDescription;
  final VoidCallback onRewardEarned;
  final IconData icon;

  const WatchAdButton({
    super.key,
    required this.label,
    required this.rewardDescription,
    required this.onRewardEarned,
    this.icon = Icons.play_circle_filled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final rewardedAd = RewardedAdManager();
    final isAvailable = rewardedAd.isAvailable;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Material(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isAvailable
              ? () async {
                  final earned = await rewardedAd.showAd();
                  if (earned) {
                    onRewardEarned();
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        rewardDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow_rounded,
                  color: colors.primary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
