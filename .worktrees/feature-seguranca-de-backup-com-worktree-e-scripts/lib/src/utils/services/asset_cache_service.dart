import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Serviço de cache para SVGs e imagens
/// Pré-carrega e mantém em cache assets frequentemente usados
class AssetCacheService {
  // Singleton
  static final AssetCacheService _instance = AssetCacheService._internal();
  factory AssetCacheService() => _instance;
  AssetCacheService._internal();

  // Cache de SVGs pré-carregados
  final Map<String, PictureInfo> _svgCache = {};
  
  // Cache de imagens pré-carregadas
  final Map<String, ImageProvider> _imageCache = {};
  
  // Controle de inicialização
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// Retorna Future que completa quando o cache estiver pronto
  Future<void> get ready => _initCompleter.future;

  /// Inicializa o cache com assets comuns
  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;
    
    try {
      // Lista de SVGs para pré-carregar
      final svgAssets = [
        'assets/mood_icons/smile.svg',
        'assets/mood_icons/calm.svg',
        'assets/mood_icons/neutral.svg',
        'assets/mood_icons/sad.svg',
        'assets/mood_icons/loudly_crying.svg',
      ];

      // Pré-carrega SVGs em paralelo
      await Future.wait(
        svgAssets.map((path) => _preloadSvg(path)),
      );

      _initialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      debugPrint('AssetCacheService: Erro ao inicializar cache: $e');
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(); // Completa mesmo com erro para não bloquear
      }
    }
  }

  /// Pré-carrega um SVG
  Future<void> _preloadSvg(String path) async {
    try {
      final loader = SvgAssetLoader(path);
      final picture = await vg.loadPicture(loader, null);
      _svgCache[path] = picture;
    } catch (e) {
      debugPrint('AssetCacheService: Erro ao carregar SVG $path: $e');
    }
  }

  /// Pré-carrega uma imagem
  Future<void> preloadImage(BuildContext context, String path) async {
    try {
      final imageProvider = AssetImage(path);
      await precacheImage(imageProvider, context);
      _imageCache[path] = imageProvider;
    } catch (e) {
      debugPrint('AssetCacheService: Erro ao carregar imagem $path: $e');
    }
  }

  /// Retorna um SVG do cache ou carrega se não existir
  Widget getSvg(
    String path, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    // Usa SvgPicture.asset que já tem cache interno
    // mas nossa lista de pré-carregamento ajuda no primeiro load
    return SvgPicture.asset(
      path,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn) 
          : null,
      fit: fit,
      placeholderBuilder: (context) => SizedBox(
        width: width ?? 24,
        height: height ?? 24,
      ),
    );
  }

  /// Retorna uma imagem do cache ou carrega se não existir
  Widget getImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? color,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width ?? 50,
          height: height ?? 50,
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  /// Limpa o cache
  void clearCache() {
    _svgCache.clear();
    _imageCache.clear();
  }

  /// Retorna informações sobre o cache
  Map<String, int> getCacheInfo() {
    return {
      'svgCount': _svgCache.length,
      'imageCount': _imageCache.length,
    };
  }
}

/// Instância global do serviço de cache
final assetCacheService = AssetCacheService();

/// Widget que pré-carrega SVGs de mood automaticamente
class MoodIconsPreloader extends StatefulWidget {
  final Widget child;

  const MoodIconsPreloader({
    super.key,
    required this.child,
  });

  @override
  State<MoodIconsPreloader> createState() => _MoodIconsPreloaderState();
}

class _MoodIconsPreloaderState extends State<MoodIconsPreloader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      assetCacheService.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Widget de SVG com cache otimizado
class CachedSvg extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const CachedSvg({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return assetCacheService.getSvg(
      path,
      width: width,
      height: height,
      color: color,
      fit: fit,
    );
  }
}

/// Widget de imagem com cache e placeholder
class CachedImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.color,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      color: color,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: frame != null
              ? child
              : placeholder ?? _buildDefaultPlaceholder(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildDefaultError();
      },
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width ?? 50,
      height: height ?? 50,
      color: Colors.grey.withValues(alpha: 0.1),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width ?? 50,
      height: height ?? 50,
      color: Colors.grey.withValues(alpha: 0.2),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

/// Ícone de mood otimizado com cache
class MoodIcon extends StatelessWidget {
  final String moodType; // 'great', 'good', 'okay', 'bad', 'terrible'
  final double size;
  final Color? color;

  const MoodIcon({
    super.key,
    required this.moodType,
    this.size = 24,
    this.color,
  });

  String get _assetPath {
    switch (moodType.toLowerCase()) {
      case 'great':
      case 'otimo':
        return 'assets/mood_icons/smile.svg';
      case 'good':
      case 'bem':
        return 'assets/mood_icons/calm.svg';
      case 'okay':
      case 'ok':
        return 'assets/mood_icons/neutral.svg';
      case 'bad':
      case 'mal':
        return 'assets/mood_icons/sad.svg';
      case 'terrible':
      case 'pessimo':
        return 'assets/mood_icons/loudly_crying.svg';
      default:
        return 'assets/mood_icons/neutral.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CachedSvg(
      path: _assetPath,
      width: size,
      height: size,
      color: color,
    );
  }
}
