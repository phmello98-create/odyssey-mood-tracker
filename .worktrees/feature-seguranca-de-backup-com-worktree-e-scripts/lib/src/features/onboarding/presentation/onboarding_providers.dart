import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/auth/presentation/providers/auth_providers.dart';
import '../data/onboarding_repository.dart';
import '../domain/models/onboarding_models.dart';
import '../domain/models/onboarding_content.dart';
import '../domain/models/first_steps_content.dart';

/// Helper para debug prints condicionais
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Provider para o repositório de onboarding
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingRepository(prefs);
});

/// Estado do sistema de onboarding interativo
class InteractiveOnboardingState {
  final OnboardingProgressState progress;
  final bool isShowingOnboarding;
  final int currentOnboardingPage;
  final bool isShowingTour;
  final String? currentTourId;
  final int currentTourStep;
  final bool isShowingTip;
  final FeatureTip? currentTip;
  final bool isShowingCoachMark;
  final CoachMark? currentCoachMark;
  final Map<String, GlobalKey> registeredKeys;
  final bool firstStepsDismissed;
  final Set<String> completedFirstSteps;

  const InteractiveOnboardingState({
    this.progress = const OnboardingProgressState(),
    this.isShowingOnboarding = false,
    this.currentOnboardingPage = 0,
    this.isShowingTour = false,
    this.currentTourId,
    this.currentTourStep = 0,
    this.isShowingTip = false,
    this.currentTip,
    this.isShowingCoachMark = false,
    this.currentCoachMark,
    this.registeredKeys = const {},
    this.firstStepsDismissed = false,
    this.completedFirstSteps = const {},
  });

  /// copyWith com suporte a valores nullable
  /// Use clearTourId: true para limpar o currentTourId
  /// Use clearTip: true para limpar o currentTip
  /// Use clearCoachMark: true para limpar o currentCoachMark
  InteractiveOnboardingState copyWith({
    OnboardingProgressState? progress,
    bool? isShowingOnboarding,
    int? currentOnboardingPage,
    bool? isShowingTour,
    String? currentTourId,
    bool clearTourId = false,
    int? currentTourStep,
    bool? isShowingTip,
    FeatureTip? currentTip,
    bool clearTip = false,
    bool? isShowingCoachMark,
    CoachMark? currentCoachMark,
    bool clearCoachMark = false,
    Map<String, GlobalKey>? registeredKeys,
    bool? firstStepsDismissed,
    Set<String>? completedFirstSteps,
  }) {
    return InteractiveOnboardingState(
      progress: progress ?? this.progress,
      isShowingOnboarding: isShowingOnboarding ?? this.isShowingOnboarding,
      currentOnboardingPage: currentOnboardingPage ?? this.currentOnboardingPage,
      isShowingTour: isShowingTour ?? this.isShowingTour,
      currentTourId: clearTourId ? null : (currentTourId ?? this.currentTourId),
      currentTourStep: currentTourStep ?? this.currentTourStep,
      isShowingTip: isShowingTip ?? this.isShowingTip,
      currentTip: clearTip ? null : (currentTip ?? this.currentTip),
      isShowingCoachMark: isShowingCoachMark ?? this.isShowingCoachMark,
      currentCoachMark: clearCoachMark ? null : (currentCoachMark ?? this.currentCoachMark),
      registeredKeys: registeredKeys ?? this.registeredKeys,
      firstStepsDismissed: firstStepsDismissed ?? this.firstStepsDismissed,
      completedFirstSteps: completedFirstSteps ?? this.completedFirstSteps,
    );
  }

  /// Verifica se o onboarding inicial foi completado
  bool get hasCompletedInitial => progress.hasCompletedInitialOnboarding;

  /// Verifica se deve mostrar o onboarding
  bool get shouldShowInitialOnboarding => !hasCompletedInitial;

  /// Obtém página atual do onboarding
  OnboardingPage? get currentPage {
    if (currentOnboardingPage >= 0 && currentOnboardingPage < OnboardingPages.all.length) {
      return OnboardingPages.all[currentOnboardingPage];
    }
    return null;
  }

  /// Obtém o tour atual
  FeatureTour? get currentTour {
    if (currentTourId != null) {
      return FeatureTours.byId(currentTourId!);
    }
    return null;
  }

  /// Obtém o coach mark atual do tour
  CoachMark? get currentTourCoachMark {
    final tour = currentTour;
    if (tour != null && currentTourStep < tour.steps.length) {
      return tour.steps[currentTourStep];
    }
    return null;
  }
}

/// Notifier para gerenciar o estado do onboarding interativo
class InteractiveOnboardingNotifier extends StateNotifier<InteractiveOnboardingState> {
  final OnboardingRepository _repository;

  InteractiveOnboardingNotifier(this._repository) 
      : super(const InteractiveOnboardingState()) {
    _loadState();
  }

  void _loadState() {
    final progress = _repository.loadState();
    state = state.copyWith(
      progress: progress,
      firstStepsDismissed: _repository.isFirstStepsDismissed,
      completedFirstSteps: _repository.getCompletedFirstSteps(),
    );
    
    // Verifica se há tour em andamento
    final tourId = _repository.currentTourId;
    if (tourId != null) {
      state = state.copyWith(
        currentTourId: tourId,
        currentTourStep: _repository.currentTourStepIndex,
        isShowingTour: true,
      );
    }
  }

  // ==================== Onboarding Inicial ====================

  /// Inicia o onboarding inicial
  void startInitialOnboarding() {
    state = state.copyWith(
      isShowingOnboarding: true,
      currentOnboardingPage: 0,
    );
  }

  /// Avança para a próxima página do onboarding
  void nextOnboardingPage() {
    if (state.currentOnboardingPage < OnboardingPages.all.length - 1) {
      state = state.copyWith(
        currentOnboardingPage: state.currentOnboardingPage + 1,
      );
    } else {
      completeInitialOnboarding();
    }
  }

  /// Volta para a página anterior do onboarding
  void previousOnboardingPage() {
    if (state.currentOnboardingPage > 0) {
      state = state.copyWith(
        currentOnboardingPage: state.currentOnboardingPage - 1,
      );
    }
  }

  /// Pula o onboarding inicial
  void skipInitialOnboarding() {
    completeInitialOnboarding();
  }

  /// Completa o onboarding inicial
  Future<void> completeInitialOnboarding() async {
    await _repository.completeInitialOnboarding();
    state = state.copyWith(
      isShowingOnboarding: false,
      progress: state.progress.copyWith(hasCompletedInitialOnboarding: true),
    );
  }

  /// Define a página atual do onboarding
  void setOnboardingPage(int page) {
    if (page >= 0 && page < OnboardingPages.all.length) {
      state = state.copyWith(currentOnboardingPage: page);
    }
  }

  // ==================== Feature Tours ====================

  /// Inicia um tour guiado (permite replay mesmo se já foi completado)
  Future<void> startTour(String tourId) async {
    _debugLog('[Onboarding] startTour called with tourId: $tourId');
    
    // Verifica se o tour existe
    final tour = FeatureTours.byId(tourId);
    if (tour == null) {
      _debugLog('[Onboarding] Tour não encontrado: $tourId');
      return;
    }
    
    _debugLog('[Onboarding] Iniciando tour: $tourId com ${tour.steps.length} passos');
    _debugLog('[Onboarding] First step: ${tour.steps.first.id}');
    
    await _repository.saveTourProgress(tourId, 0);
    
    final newState = state.copyWith(
      isShowingTour: true,
      currentTourId: tourId,
      currentTourStep: 0,
    );
    
    _debugLog('[Onboarding] New state: isShowingTour=${newState.isShowingTour}, currentTourId=${newState.currentTourId}, currentTourCoachMark=${newState.currentTourCoachMark?.id}');
    
    state = newState;
  }

  /// Avança para o próximo passo do tour
  Future<void> nextTourStep() async {
    final tour = state.currentTour;
    if (tour == null) return;

    if (state.currentTourStep < tour.steps.length - 1) {
      final nextStep = state.currentTourStep + 1;
      await _repository.saveTourProgress(tour.id, nextStep);
      state = state.copyWith(currentTourStep: nextStep);
    } else {
      await completeTour();
    }
  }

  /// Volta para o passo anterior do tour
  Future<void> previousTourStep() async {
    if (state.currentTourStep > 0) {
      final prevStep = state.currentTourStep - 1;
      if (state.currentTourId != null) {
        await _repository.saveTourProgress(state.currentTourId!, prevStep);
      }
      state = state.copyWith(currentTourStep: prevStep);
    }
  }

  /// Pula o tour atual
  Future<void> skipTour() async {
    await _repository.clearTourProgress();
    state = state.copyWith(
      isShowingTour: false,
      clearTourId: true,
      currentTourStep: 0,
    );
  }

  /// Completa o tour atual
  Future<void> completeTour() async {
    if (state.currentTourId != null) {
      await _repository.markTourAsCompleted(state.currentTourId!);
      
      final updatedProgress = state.progress.copyWith(
        completedTours: {...state.progress.completedTours, state.currentTourId!},
      );
      
      state = state.copyWith(
        isShowingTour: false,
        clearTourId: true,
        currentTourStep: 0,
        progress: updatedProgress,
      );
      
      // Track first tour completion for FirstSteps checklist
      await completeFirstStep('complete_tour');
    }
  }

  /// Completa um tour específico por ID (para tours externos como GameTourScope)
  Future<void> completeTourById(String tourId) async {
    await _repository.markTourAsCompleted(tourId);
    
    final updatedProgress = state.progress.copyWith(
      completedTours: {...state.progress.completedTours, tourId},
    );
    
    state = state.copyWith(
      progress: updatedProgress,
    );
    
    // Track first tour completion for FirstSteps checklist
    await completeFirstStep('complete_tour');
  }

  // ==================== Feature Tips ====================

  /// Mostra uma dica específica
  void showTip(FeatureTip tip) {
    state = state.copyWith(
      isShowingTip: true,
      currentTip: tip,
    );
  }

  /// Mostra uma dica aleatória não vista
  void showRandomTip() {
    if (!_repository.canShowTip()) return;
    
    final tip = FeatureTips.getRandomUnviewed(state.progress.viewedTips);
    if (tip != null) {
      showTip(tip);
    }
  }

  /// Mostra dica para uma categoria específica
  void showTipForCategory(FeatureCategory category) {
    final tips = FeatureTips.byCategory(category)
        .where((t) => !state.progress.hasTipBeenViewed(t.id))
        .toList();
    
    if (tips.isNotEmpty) {
      tips.shuffle();
      showTip(tips.first);
    }
  }

  /// Fecha a dica atual e marca como vista
  Future<void> dismissTip() async {
    if (state.currentTip != null) {
      await _repository.markTipAsViewed(state.currentTip!.id);
      
      final updatedProgress = state.progress.copyWith(
        viewedTips: {...state.progress.viewedTips, state.currentTip!.id},
        lastTipShownDate: DateTime.now(),
      );
      
      state = state.copyWith(
        isShowingTip: false,
        clearTip: true,
        progress: updatedProgress,
      );
    }
  }

  // ==================== Coach Marks ====================

  /// Mostra um coach mark específico
  void showCoachMark(CoachMark mark) {
    if (_repository.hasCoachMarkBeenDismissed(mark.id)) return;
    
    state = state.copyWith(
      isShowingCoachMark: true,
      currentCoachMark: mark,
    );
  }

  /// Dispensa o coach mark atual
  Future<void> dismissCoachMark() async {
    if (state.currentCoachMark != null) {
      await _repository.dismissCoachMark(state.currentCoachMark!.id);
      
      final updatedProgress = state.progress.copyWith(
        dismissedCoachMarks: {...state.progress.dismissedCoachMarks, state.currentCoachMark!.id},
      );
      
      state = state.copyWith(
        isShowingCoachMark: false,
        clearCoachMark: true,
        progress: updatedProgress,
      );
    }
  }

  // ==================== Widget Keys ====================

  /// Registra uma GlobalKey para um elemento de UI
  void registerKey(String id, GlobalKey key) {
    final newKeys = Map<String, GlobalKey>.from(state.registeredKeys);
    newKeys[id] = key;
    state = state.copyWith(registeredKeys: newKeys);
  }

  /// Obtém uma GlobalKey registrada
  GlobalKey? getKey(String id) {
    return state.registeredKeys[id];
  }

  // ==================== Category Usage ====================

  /// Incrementa uso de uma categoria
  Future<void> trackCategoryUsage(FeatureCategory category) async {
    await _repository.incrementCategoryUsage(category);
    
    final updatedUsage = Map<FeatureCategory, int>.from(state.progress.categoryUsageCount);
    updatedUsage[category] = (updatedUsage[category] ?? 0) + 1;
    
    state = state.copyWith(
      progress: state.progress.copyWith(categoryUsageCount: updatedUsage),
    );
  }

  // ==================== Settings ====================

  /// Habilita/desabilita dicas
  Future<void> setTipsEnabled(bool enabled) async {
    await _repository.setTipsEnabled(enabled);
    state = state.copyWith(
      progress: state.progress.copyWith(tipsEnabled: enabled),
    );
  }

  /// Habilita/desabilita coach marks
  Future<void> setCoachMarksEnabled(bool enabled) async {
    await _repository.setCoachMarksEnabled(enabled);
    state = state.copyWith(
      progress: state.progress.copyWith(coachMarksEnabled: enabled),
    );
  }

  /// Habilita/desabilita highlights de feature
  Future<void> setFeatureHighlightsEnabled(bool enabled) async {
    await _repository.setFeatureHighlightsEnabled(enabled);
    state = state.copyWith(
      progress: state.progress.copyWith(featureHighlightsEnabled: enabled),
    );
  }

  // ==================== Reset ====================

  /// Reseta todo o estado do onboarding (para debug)
  Future<void> resetAll() async {
    await _repository.resetOnboarding();
    state = const InteractiveOnboardingState();
  }

  // ==================== First Steps ====================

  /// Marca um primeiro passo como completado
  Future<void> completeFirstStep(String stepId) async {
    await _repository.completeFirstStep(stepId);
    // Atualiza o estado com os novos passos completados
    state = state.copyWith(
      completedFirstSteps: _repository.getCompletedFirstSteps(),
    );
  }

  /// Dispensa o checklist de primeiros passos
  Future<void> dismissFirstSteps() async {
    await _repository.dismissFirstSteps();
    state = state.copyWith(firstStepsDismissed: true);
  }
}

/// Provider principal do onboarding interativo
final interactiveOnboardingProvider = StateNotifierProvider<
    InteractiveOnboardingNotifier, InteractiveOnboardingState>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return InteractiveOnboardingNotifier(repository);
});

/// Provider para verificar se deve mostrar onboarding inicial
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final state = ref.watch(interactiveOnboardingProvider);
  return state.shouldShowInitialOnboarding;
});

/// Provider para a página atual do onboarding
final currentOnboardingPageProvider = Provider<OnboardingPage?>((ref) {
  final state = ref.watch(interactiveOnboardingProvider);
  return state.currentPage;
});

/// Provider para dicas não vistas
final unviewedTipsProvider = Provider<List<FeatureTip>>((ref) {
  final state = ref.watch(interactiveOnboardingProvider);
  return FeatureTips.unviewed(state.progress.viewedTips);
});

/// Provider para tours não completados
final incompleteTours = Provider<List<FeatureTour>>((ref) {
  final state = ref.watch(interactiveOnboardingProvider);
  return FeatureTours.all
      .where((t) => !state.progress.completedTours.contains(t.id))
      .toList();
});

/// Provider para verificar se está em tour
final isInTourProvider = Provider<bool>((ref) {
  final state = ref.watch(interactiveOnboardingProvider);
  return state.isShowingTour;
});

/// Provider para o coach mark atual do tour
final currentTourCoachMarkProvider = Provider<CoachMark?>((ref) {
  final state = ref.watch(interactiveOnboardingProvider);
  return state.currentTourCoachMark;
});

// ==================== First Steps Providers ====================

/// Provider para passos completos do FirstSteps
final completedFirstStepsProvider = Provider<Set<String>>((ref) {
  final onboardingState = ref.watch(interactiveOnboardingProvider);
  return onboardingState.completedFirstSteps;
});

/// Provider para verificar se o checklist ainda deve ser mostrado
final shouldShowFirstStepsProvider = Provider<bool>((ref) {
  final completed = ref.watch(completedFirstStepsProvider);
  final onboardingState = ref.watch(interactiveOnboardingProvider);
  
  // Não mostra se foi dispensado pelo usuário
  if (onboardingState.firstStepsDismissed) return false;
  
  // Não mostra se ainda não completou o onboarding inicial
  if (!onboardingState.hasCompletedInitial) return false;
  
  // Mostra se pelo menos um passo não foi completado
  return completed.length < FirstStepsContent.all.length;
});

/// Provider para progresso do FirstSteps (0.0 a 1.0)
final firstStepsProgressProvider = Provider<double>((ref) {
  final completed = ref.watch(completedFirstStepsProvider);
  if (FirstStepsContent.all.isEmpty) return 1.0;
  return completed.length / FirstStepsContent.all.length;
});

/// Provider para XP total ganho nos FirstSteps
final firstStepsXpEarnedProvider = Provider<int>((ref) {
  final completed = ref.watch(completedFirstStepsProvider);
  return FirstStepsContent.all
      .where((step) => completed.contains(step.id))
      .fold(0, (sum, step) => sum + step.xpReward);
});
