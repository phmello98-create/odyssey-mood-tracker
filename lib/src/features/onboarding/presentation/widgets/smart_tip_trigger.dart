import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/models/onboarding_content.dart';
import '../onboarding_providers.dart';

/// Widget que detecta inatividade do usuário e mostra dicas contextuais
/// 
/// Princípio: "Não explique tudo. Mostre apenas o próximo passo útil."
/// 
/// Funciona de duas formas:
/// 1. Detecta inatividade (sem toques por X segundos)
/// 2. Pode ser acionado manualmente via callback
class SmartTipTrigger extends ConsumerStatefulWidget {
  /// Widget filho que será monitorado para interações
  final Widget child;
  
  /// Categoria da feature para buscar dicas relevantes
  final FeatureCategory category;
  
  /// Segundos de inatividade antes de mostrar dica (default: 10s)
  final int inactivitySeconds;
  
  /// Se deve detectar inatividade automaticamente
  final bool autoDetect;
  
  /// Callback quando uma dica é mostrada
  final void Function(FeatureTip tip)? onTipShown;
  
  /// Callback para obter controller que permite disparar dicas manualmente
  final void Function(SmartTipController controller)? onControllerReady;
  
  /// Dica específica para mostrar (ignora busca automática)
  final FeatureTip? specificTip;
  
  /// Se deve pausar detecção quando em focus (ex: digitando)
  final bool pauseWhenFocused;
  
  /// Máximo de dicas a mostrar por sessão (0 = ilimitado)
  final int maxTipsPerSession;
  
  /// Se deve mostrar dicas mesmo se já foram vistas
  final bool showViewedTips;

  const SmartTipTrigger({
    super.key,
    required this.child,
    required this.category,
    this.inactivitySeconds = 10,
    this.autoDetect = true,
    this.onTipShown,
    this.onControllerReady,
    this.specificTip,
    this.pauseWhenFocused = true,
    this.maxTipsPerSession = 2,
    this.showViewedTips = false,
  });

  @override
  ConsumerState<SmartTipTrigger> createState() => _SmartTipTriggerState();
}

class _SmartTipTriggerState extends ConsumerState<SmartTipTrigger> {
  Timer? _inactivityTimer;
  int _tipsShownThisSession = 0;
  bool _isPaused = false;
  late SmartTipController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SmartTipController(
      showTip: _showTipManually,
      pause: _pauseDetection,
      resume: _resumeDetection,
      reset: _resetTimer,
    );
    
    // Notifica controller pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(_controller);
      if (widget.autoDetect) {
        _startInactivityTimer();
      }
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    
    // Não inicia se pausado ou se já mostrou o máximo de dicas
    if (_isPaused) return;
    if (widget.maxTipsPerSession > 0 && _tipsShownThisSession >= widget.maxTipsPerSession) return;
    
    _inactivityTimer = Timer(Duration(seconds: widget.inactivitySeconds), () {
      if (mounted && !_isPaused) {
        _onInactivityDetected();
      }
    });
  }

  void _resetTimer() {
    if (widget.autoDetect) {
      _startInactivityTimer();
    }
  }

  void _pauseDetection() {
    _isPaused = true;
    _inactivityTimer?.cancel();
  }

  void _resumeDetection() {
    _isPaused = false;
    if (widget.autoDetect) {
      _startInactivityTimer();
    }
  }

  void _onUserInteraction() {
    _resetTimer();
  }

  void _onInactivityDetected() {
    final onboardingState = ref.read(interactiveOnboardingProvider);
    
    // Não mostra se está em tour ou mostrando outra dica
    if (onboardingState.isShowingTour) return;
    if (onboardingState.isShowingTip) return;
    if (!onboardingState.hasCompletedInitial) return;
    
    // Busca dica relevante
    final tip = _getRelevantTip();
    if (tip != null) {
      _showTip(tip);
    }
  }

  FeatureTip? _getRelevantTip() {
    if (widget.specificTip != null) return widget.specificTip;
    
    final progress = ref.read(interactiveOnboardingProvider).progress;
    
    // Busca dicas da categoria
    var tips = FeatureTips.byCategory(widget.category);
    
    // Filtra as já vistas (se configurado)
    if (!widget.showViewedTips) {
      tips = tips.where((t) => !progress.hasTipBeenViewed(t.id)).toList();
    }
    
    if (tips.isEmpty) return null;
    
    // Ordena por prioridade
    tips.sort((a, b) => b.priority.compareTo(a.priority));
    
    // Adiciona um pouco de aleatoriedade entre as top 3
    final topTips = tips.take(3).toList();
    topTips.shuffle();
    
    return topTips.first;
  }

  void _showTipManually(FeatureTip? tip) {
    final tipToShow = tip ?? _getRelevantTip();
    if (tipToShow != null) {
      _showTip(tipToShow);
    }
  }

  void _showTip(FeatureTip tip) {
    _tipsShownThisSession++;
    widget.onTipShown?.call(tip);
    ref.read(interactiveOnboardingProvider.notifier).showTip(tip);
    
    // Reinicia timer após mostrar dica
    if (widget.autoDetect) {
      _startInactivityTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

/// Controller para controlar SmartTipTrigger externamente
class SmartTipController {
  final void Function(FeatureTip? tip) _showTip;
  final VoidCallback _pause;
  final VoidCallback _resume;
  final VoidCallback _reset;

  SmartTipController({
    required void Function(FeatureTip? tip) showTip,
    required VoidCallback pause,
    required VoidCallback resume,
    required VoidCallback reset,
  })  : _showTip = showTip,
        _pause = pause,
        _resume = resume,
        _reset = reset;

  /// Mostra uma dica (ou busca uma relevante se null)
  void showTip([FeatureTip? tip]) => _showTip(tip);
  
  /// Pausa a detecção de inatividade
  void pause() => _pause();
  
  /// Retoma a detecção de inatividade
  void resume() => _resume();
  
  /// Reseta o timer de inatividade
  void reset() => _reset();
}

/// Widget simplificado que mostra dica após scroll parar
class ScrollIdleTipTrigger extends ConsumerStatefulWidget {
  final Widget child;
  final FeatureCategory category;
  final ScrollController scrollController;
  final int idleSeconds;

  const ScrollIdleTipTrigger({
    super.key,
    required this.child,
    required this.category,
    required this.scrollController,
    this.idleSeconds = 5,
  });

  @override
  ConsumerState<ScrollIdleTipTrigger> createState() => _ScrollIdleTipTriggerState();
}

class _ScrollIdleTipTriggerState extends ConsumerState<ScrollIdleTipTrigger> {
  Timer? _idleTimer;
  bool _hasShownTip = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _idleTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    _idleTimer?.cancel();
    
    if (_hasShownTip) return;
    
    _idleTimer = Timer(Duration(seconds: widget.idleSeconds), () {
      if (mounted && !_hasShownTip) {
        _showTip();
      }
    });
  }

  void _showTip() {
    final onboardingState = ref.read(interactiveOnboardingProvider);
    if (onboardingState.isShowingTour || onboardingState.isShowingTip) return;
    if (!onboardingState.hasCompletedInitial) return;
    
    final progress = onboardingState.progress;
    final tips = FeatureTips.byCategory(widget.category)
        .where((t) => !progress.hasTipBeenViewed(t.id))
        .toList();
    
    if (tips.isNotEmpty) {
      tips.shuffle();
      ref.read(interactiveOnboardingProvider.notifier).showTip(tips.first);
      _hasShownTip = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Provider para controlar estado global de tips inteligentes
final smartTipsEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider que retorna a próxima dica recomendada para uma categoria
final nextRecommendedTipProvider = Provider.family<FeatureTip?, FeatureCategory>((ref, category) {
  final progress = ref.watch(interactiveOnboardingProvider).progress;
  
  final tips = FeatureTips.byCategory(category)
      .where((t) => !progress.hasTipBeenViewed(t.id))
      .toList();
  
  if (tips.isEmpty) return null;
  
  tips.sort((a, b) => b.priority.compareTo(a.priority));
  return tips.first;
});

/// Extension para facilitar uso do SmartTipTrigger
extension SmartTipHelpers on WidgetRef {
  /// Mostra uma dica para a categoria especificada
  void showSmartTip(FeatureCategory category) {
    final progress = watch(interactiveOnboardingProvider).progress;
    final tips = FeatureTips.byCategory(category)
        .where((t) => !progress.hasTipBeenViewed(t.id))
        .toList();
    
    if (tips.isNotEmpty) {
      tips.sort((a, b) => b.priority.compareTo(a.priority));
      final topTips = tips.take(3).toList();
      topTips.shuffle();
      read(interactiveOnboardingProvider.notifier).showTip(topTips.first);
    }
  }
  
  /// Verifica se existem dicas não vistas para a categoria
  bool hasUnviewedTips(FeatureCategory category) {
    final progress = watch(interactiveOnboardingProvider).progress;
    return FeatureTips.byCategory(category)
        .any((t) => !progress.hasTipBeenViewed(t.id));
  }
}
