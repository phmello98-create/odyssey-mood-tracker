import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/models/onboarding_content.dart';
import '../onboarding_providers.dart';

/// Widget que detecta a primeira visita do usuário a uma tela
/// e oferece mostrar dica contextual ou iniciar um tour guiado
/// 
/// Princípio: "Não explique tudo. Mostre apenas o próximo passo útil."
class FirstTimeDetector extends ConsumerStatefulWidget {
  /// ID único da tela (usado para persistir que já foi visitada)
  final String screenId;
  
  /// Categoria da feature para buscar dicas/tours relevantes
  final FeatureCategory category;
  
  /// Widget filho que será renderizado
  final Widget child;
  
  /// ID do tour a oferecer (opcional - se não passar, busca pelo category)
  final String? tourId;
  
  /// Callback quando o tour é iniciado
  final VoidCallback? onTourStarted;
  
  /// Callback quando a dica é mostrada
  final VoidCallback? onTipShown;
  
  /// Se true, mostra automaticamente a dica/tour. Se false, apenas detecta.
  final bool autoShow;
  
  /// Delay antes de mostrar a dica/oferta de tour (ms)
  final int delayMs;
  
  /// Se deve mostrar opção de tour (quando disponível)
  final bool offerTour;
  
  /// Dica específica para mostrar (opcional)
  final FeatureTip? specificTip;

  const FirstTimeDetector({
    super.key,
    required this.screenId,
    required this.category,
    required this.child,
    this.tourId,
    this.onTourStarted,
    this.onTipShown,
    this.autoShow = true,
    this.delayMs = 800,
    this.offerTour = true,
    this.specificTip,
  });

  @override
  ConsumerState<FirstTimeDetector> createState() => _FirstTimeDetectorState();
}

class _FirstTimeDetectorState extends ConsumerState<FirstTimeDetector> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    // Aguarda o build inicial antes de verificar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstVisit();
    });
  }

  Future<void> _checkFirstVisit() async {
    if (_hasChecked) return;
    _hasChecked = true;

    final repository = ref.read(onboardingRepositoryProvider);
    final onboardingState = ref.read(interactiveOnboardingProvider);
    
    // Não faz nada se o onboarding inicial ainda não foi completado
    if (!onboardingState.hasCompletedInitial) return;
    
    // Não faz nada se está em um tour
    if (onboardingState.isShowingTour) return;
    
    // Verifica se é a primeira visita a esta tela
    final visitKey = 'first_visit_${widget.screenId}';
    final hasVisited = repository.hasTipBeenViewed(visitKey);
    
    if (!hasVisited) {
      // Marca como visitado
      await repository.markTipAsViewed(visitKey);
      
      // Se autoShow está habilitado, mostra dica/tour após delay
      if (widget.autoShow && mounted) {
        await Future.delayed(Duration(milliseconds: widget.delayMs));
        if (mounted) {
          _showFirstTimeContent();
        }
      }
    }
  }

  void _showFirstTimeContent() {
    final notifier = ref.read(interactiveOnboardingProvider.notifier);
    final progress = ref.read(interactiveOnboardingProvider).progress;
    
    // Busca tour disponível para a categoria
    final tour = widget.tourId != null 
        ? FeatureTours.byId(widget.tourId!)
        : FeatureTours.byCategory(widget.category);
    
    final hasTour = tour != null && 
        !progress.completedTours.contains(tour.id) &&
        widget.offerTour;
    
    // Se tem tour disponível, oferece ao usuário
    if (hasTour) {
      _showTourOffer(tour);
      return;
    }
    
    // Caso contrário, mostra uma dica contextual
    final tip = widget.specificTip ?? _getRelevantTip(progress);
    if (tip != null) {
      widget.onTipShown?.call();
      notifier.showTip(tip);
    }
  }

  FeatureTip? _getRelevantTip(OnboardingProgressState progress) {
    // Busca dicas da categoria que ainda não foram vistas
    final tips = FeatureTips.byCategory(widget.category)
        .where((t) => !progress.hasTipBeenViewed(t.id))
        .toList();
    
    if (tips.isEmpty) return null;
    
    // Ordena por prioridade e retorna a mais relevante
    tips.sort((a, b) => b.priority.compareTo(a.priority));
    return tips.first;
  }

  void _showTourOffer(FeatureTour tour) {
    final locale = Localizations.localeOf(context);
    final isPt = locale.languageCode == 'pt';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TourOfferSheet(
        tour: tour,
        isPt: isPt,
        onAccept: () {
          Navigator.pop(context);
          widget.onTourStarted?.call();
          ref.read(interactiveOnboardingProvider.notifier).startTour(tour.id);
        },
        onDecline: () {
          Navigator.pop(context);
          // Mostra uma dica rápida como alternativa
          final tip = _getRelevantTip(ref.read(interactiveOnboardingProvider).progress);
          if (tip != null) {
            ref.read(interactiveOnboardingProvider.notifier).showTip(tip);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Sheet para oferecer tour guiado ao usuário
class _TourOfferSheet extends StatelessWidget {
  final FeatureTour tour;
  final bool isPt;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _TourOfferSheet({
    required this.tour,
    required this.isPt,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF2A2A3E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Ícone animado
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.secondary],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Título
                Text(
                  isPt ? 'Primeira vez aqui?' : 'First time here?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Descrição
                Text(
                  isPt 
                      ? 'Quer um tour rápido de ${tour.estimatedSeconds}s pelo ${tour.getSectionName(isPt)}?'
                      : 'Want a quick ${tour.estimatedSeconds}s tour of ${tour.getSectionName(isPt)}?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Info de passos
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: colors.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPt 
                          ? '${tour.steps.length} passos simples'
                          : '${tour.steps.length} simple steps',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Botões
                Row(
                  children: [
                    // Botão "Depois"
                    Expanded(
                      child: TextButton(
                        onPressed: onDecline,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Text(
                          isPt ? 'Depois' : 'Later',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Botão "Vamos lá!"
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isPt ? 'Vamos lá!' : 'Let\'s go!',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider helper para verificar primeira visita
final firstVisitCheckerProvider = Provider.family<bool, String>((ref, screenId) {
  final repository = ref.watch(onboardingRepositoryProvider);
  final visitKey = 'first_visit_$screenId';
  return !repository.hasTipBeenViewed(visitKey);
});
