import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_providers.dart';
import 'coach_mark_overlay.dart';
import 'contextual_tip_widgets.dart';
import '../screens/interactive_onboarding_screen.dart';
import '../../domain/models/onboarding_models.dart';

/// Widget wrapper que gerencia todo o sistema de onboarding
/// Envolva seu MaterialApp.home com este widget
class OnboardingWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onOnboardingComplete;

  const OnboardingWrapper({
    super.key,
    required this.child,
    this.onOnboardingComplete,
  });

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  bool _showingOnboarding = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  void _checkOnboarding() {
    if (_initialized) return;
    _initialized = true;
    
    final state = ref.read(interactiveOnboardingProvider);
    debugPrint('[OnboardingWrapper] Checking onboarding: shouldShow=${state.shouldShowInitialOnboarding}, hasCompleted=${state.hasCompletedInitial}');
    
    if (state.shouldShowInitialOnboarding) {
      setState(() => _showingOnboarding = true);
    }
  }

  void _onOnboardingComplete() {
    debugPrint('[OnboardingWrapper] Onboarding completed');
    setState(() => _showingOnboarding = false);
    widget.onOnboardingComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes
    final state = ref.watch(interactiveOnboardingProvider);

    if (_showingOnboarding && !state.hasCompletedInitial) {
      return InteractiveOnboardingScreen(
        onComplete: _onOnboardingComplete,
      );
    }

    // Usa um Stack com Overlay para mostrar coach marks por cima de tudo
    return Material(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Child principal
          widget.child,
          
          // Overlay para tips (já retorna Positioned ou SizedBox.shrink)
          const _TipOverlayWidget(),
          
          // Overlay para coach marks (tours) - precisa cobrir toda a tela
          const _CoachMarkOverlayWidget(),
        ],
      ),
    );
  }
}

/// Overlay para mostrar dicas flutuantes
class _TipOverlayWidget extends ConsumerWidget {
  const _TipOverlayWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interactiveOnboardingProvider);
    
    if (!state.isShowingTip || state.currentTip == null || state.isShowingTour) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 100,
      child: AnimatedBreathingTipCard(
        tip: state.currentTip!,
        onDismiss: () {
          ref.read(interactiveOnboardingProvider.notifier).dismissTip();
        },
      ),
    );
  }
}

/// Overlay para mostrar coach marks durante tours
class _CoachMarkOverlayWidget extends ConsumerStatefulWidget {
  const _CoachMarkOverlayWidget();

  @override
  ConsumerState<_CoachMarkOverlayWidget> createState() => _CoachMarkOverlayWidgetState();
}

class _CoachMarkOverlayWidgetState extends ConsumerState<_CoachMarkOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interactiveOnboardingProvider);
    
    debugPrint('[_CoachMarkOverlayWidget] Build: isShowingTour=${state.isShowingTour}, currentTourId=${state.currentTourId}, currentTourStep=${state.currentTourStep}, currentTourCoachMark=${state.currentTourCoachMark?.id}');
    
    // Se não está mostrando tour ou não tem coach mark atual, não mostra nada
    if (!state.isShowingTour || state.currentTourCoachMark == null) {
      debugPrint('[_CoachMarkOverlayWidget] NOT showing: isShowingTour=${state.isShowingTour}, hasCoachMark=${state.currentTourCoachMark != null}');
      if (_animController.isAnimating || _animController.value > 0) {
        _animController.reverse();
      }
      return const SizedBox.shrink();
    }

    final mark = state.currentTourCoachMark!;
    final targetKey = state.registeredKeys[mark.id];
    
    debugPrint('[_CoachMarkOverlayWidget] WILL SHOW mark: ${mark.id}, hasKey=${targetKey != null}');
    debugPrint('[_CoachMarkOverlayWidget] Registered keys: ${state.registeredKeys.keys.toList()}');

    // Inicia animação de entrada após o frame atual para evitar condição de corrida
    if (!_animController.isAnimating && _animController.value == 0) {
      debugPrint('[_CoachMarkOverlayWidget] Scheduling animation forward');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_animController.isAnimating && _animController.value == 0) {
          debugPrint('[_CoachMarkOverlayWidget] Starting animation forward');
          _animController.forward();
        }
      });
    }

    // Mostra o widget imediatamente com opacity baseada na animação
    // Isso evita o bug onde o widget não aparece porque animation.value == 0
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final animValue = _animController.value;
        debugPrint('[_CoachMarkOverlayWidget] Animation value: $animValue');
        
        // Usa opacidade mínima de 0.01 para garantir que o widget seja renderizado
        // e a animação possa prosseguir
        final effectiveAnimValue = animValue > 0 ? animValue : 0.01;
        
        return Opacity(
          opacity: animValue > 0 ? 1.0 : 0.0, // Esconde completamente se animação não começou
          child: CoachMarkWidget(
            mark: mark,
            targetKey: targetKey,
            animationValue: effectiveAnimValue,
            onDismiss: () {
              ref.read(interactiveOnboardingProvider.notifier).dismissCoachMark();
            },
            onNext: () {
              ref.read(interactiveOnboardingProvider.notifier).nextTourStep();
            },
            onSkip: () {
              ref.read(interactiveOnboardingProvider.notifier).skipTour();
            },
          ),
        );
      },
    );
  }
}

/// Provider helper para mostrar dicas em contexto
extension OnboardingContextExtension on WidgetRef {
  /// Mostra uma dica específica por ID
  void showTip(String tipId) {
    final tips = read(unviewedTipsProvider);
    final tip = tips.where((t) => t.id == tipId).firstOrNull;
    if (tip != null) {
      read(interactiveOnboardingProvider.notifier).showTip(tip);
    }
  }

  /// Inicia um tour
  void startTour(String tourId) {
    read(interactiveOnboardingProvider.notifier).startTour(tourId);
  }

  /// Mostra dica aleatória
  void showRandomTip() {
    read(interactiveOnboardingProvider.notifier).showRandomTip();
  }

  /// Rastreia uso de categoria
  void trackFeatureUsage(FeatureCategory category) {
    read(interactiveOnboardingProvider.notifier).trackCategoryUsage(category);
  }
}
