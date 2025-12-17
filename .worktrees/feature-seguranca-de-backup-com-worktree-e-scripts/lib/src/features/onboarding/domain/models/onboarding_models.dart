import 'package:flutter/material.dart';

/// Tipos de dicas do sistema
enum TipType {
  feature,      // Nova feature
  shortcut,     // Atalho útil
  gesture,      // Gesto escondido
  productivity, // Dica de produtividade
  hidden,       // Feature oculta
  tip,          // Dica geral
}

/// Categoria de feature para discovery
enum FeatureCategory {
  mood,
  habits,
  tasks,
  timer,
  notes,
  library,
  analytics,
  settings,
  gamification,
  general,
}

/// Estado de uma etapa do onboarding
enum OnboardingStepStatus {
  pending,
  active,
  completed,
  skipped,
}

/// Modelo para uma página do onboarding inicial
class OnboardingPage {
  final String id;
  final String titlePt;
  final String titleEn;
  final String subtitlePt;
  final String subtitleEn;
  final IconData icon;
  final List<Color> gradientColors;
  final String? lottieAsset;
  final List<String> featureHighlights;
  /// Se true, mostra uma demo interativa nesta página (ex: seletor de emoji)
  final bool hasInteractiveDemo;
  /// Se true, mostra um preview do HelpFab para familiarizar o usuário
  final bool showHelpFabPreview;

  const OnboardingPage({
    required this.id,
    required this.titlePt,
    required this.titleEn,
    required this.subtitlePt,
    required this.subtitleEn,
    required this.icon,
    required this.gradientColors,
    this.lottieAsset,
    this.featureHighlights = const [],
    this.hasInteractiveDemo = false,
    this.showHelpFabPreview = false,
  });

  String getTitle(bool isPortuguese) => isPortuguese ? titlePt : titleEn;
  String getSubtitle(bool isPortuguese) => isPortuguese ? subtitlePt : subtitleEn;
}

/// Modelo para coach mark (tooltip guiado)
class CoachMark {
  final String id;
  final String titlePt;
  final String titleEn;
  final String descriptionPt;
  final String descriptionEn;
  final GlobalKey? targetKey;
  final Alignment tooltipAlignment;
  final bool showArrow;
  final int order;
  final String? nextMarkId;
  final FeatureCategory category;
  final bool requiresInteraction;

  const CoachMark({
    required this.id,
    required this.titlePt,
    required this.titleEn,
    required this.descriptionPt,
    required this.descriptionEn,
    this.targetKey,
    this.tooltipAlignment = Alignment.bottomCenter,
    this.showArrow = true,
    required this.order,
    this.nextMarkId,
    this.category = FeatureCategory.general,
    this.requiresInteraction = false,
  });

  String getTitle(bool isPortuguese) => isPortuguese ? titlePt : titleEn;
  String getDescription(bool isPortuguese) => isPortuguese ? descriptionPt : descriptionEn;
}

/// Modelo para dica de feature discovery
class FeatureTip {
  final String id;
  final String titlePt;
  final String titleEn;
  final String descriptionPt;
  final String descriptionEn;
  final IconData icon;
  final TipType type;
  final FeatureCategory category;
  final String? actionRoute;
  final int priority;
  final bool isNew;
  final DateTime? availableFrom;
  final List<String> tags;

  const FeatureTip({
    required this.id,
    required this.titlePt,
    required this.titleEn,
    required this.descriptionPt,
    required this.descriptionEn,
    required this.icon,
    required this.type,
    required this.category,
    this.actionRoute,
    this.priority = 0,
    this.isNew = false,
    this.availableFrom,
    this.tags = const [],
  });

  String getTitle(bool isPortuguese) => isPortuguese ? titlePt : titleEn;
  String getDescription(bool isPortuguese) => isPortuguese ? descriptionPt : descriptionEn;

  /// Cor baseada no tipo de dica
  Color get typeColor {
    switch (type) {
      case TipType.feature:
        return const Color(0xFF6366F1);
      case TipType.shortcut:
        return const Color(0xFF10B981);
      case TipType.gesture:
        return const Color(0xFFF59E0B);
      case TipType.productivity:
        return const Color(0xFF3B82F6);
      case TipType.hidden:
        return const Color(0xFFEC4899);
      case TipType.tip:
        return const Color(0xFF8B5CF6);
    }
  }

  /// Ícone do tipo
  IconData get typeIcon {
    switch (type) {
      case TipType.feature:
        return Icons.star_rounded;
      case TipType.shortcut:
        return Icons.keyboard_rounded;
      case TipType.gesture:
        return Icons.touch_app_rounded;
      case TipType.productivity:
        return Icons.trending_up_rounded;
      case TipType.hidden:
        return Icons.visibility_rounded;
      case TipType.tip:
        return Icons.lightbulb_rounded;
    }
  }

  /// Label do tipo em português
  String get typeLabelPt {
    switch (type) {
      case TipType.feature:
        return 'Novidade';
      case TipType.shortcut:
        return 'Atalho';
      case TipType.gesture:
        return 'Gesto';
      case TipType.productivity:
        return 'Produtividade';
      case TipType.hidden:
        return 'Oculto';
      case TipType.tip:
        return 'Dica';
    }
  }

  /// Label do tipo em inglês
  String get typeLabelEn {
    switch (type) {
      case TipType.feature:
        return 'New';
      case TipType.shortcut:
        return 'Shortcut';
      case TipType.gesture:
        return 'Gesture';
      case TipType.productivity:
        return 'Productivity';
      case TipType.hidden:
        return 'Hidden';
      case TipType.tip:
        return 'Tip';
    }
  }
}

/// Modelo para tour de uma seção específica
class FeatureTour {
  final String id;
  final String sectionNamePt;
  final String sectionNameEn;
  final List<CoachMark> steps;
  final FeatureCategory category;
  final int estimatedSeconds;

  const FeatureTour({
    required this.id,
    required this.sectionNamePt,
    required this.sectionNameEn,
    required this.steps,
    required this.category,
    this.estimatedSeconds = 60,
  });

  String getSectionName(bool isPortuguese) => isPortuguese ? sectionNamePt : sectionNameEn;
}

/// Estado global do onboarding
class OnboardingProgressState {
  final bool hasCompletedInitialOnboarding;
  final Set<String> viewedTips;
  final Set<String> completedTours;
  final Set<String> dismissedCoachMarks;
  final Map<FeatureCategory, int> categoryUsageCount;
  final DateTime? lastTipShownDate;
  final bool tipsEnabled;
  final bool coachMarksEnabled;
  final bool featureHighlightsEnabled;

  const OnboardingProgressState({
    this.hasCompletedInitialOnboarding = false,
    this.viewedTips = const {},
    this.completedTours = const {},
    this.dismissedCoachMarks = const {},
    this.categoryUsageCount = const {},
    this.lastTipShownDate,
    this.tipsEnabled = true,
    this.coachMarksEnabled = true,
    this.featureHighlightsEnabled = true,
  });

  OnboardingProgressState copyWith({
    bool? hasCompletedInitialOnboarding,
    Set<String>? viewedTips,
    Set<String>? completedTours,
    Set<String>? dismissedCoachMarks,
    Map<FeatureCategory, int>? categoryUsageCount,
    DateTime? lastTipShownDate,
    bool? tipsEnabled,
    bool? coachMarksEnabled,
    bool? featureHighlightsEnabled,
  }) {
    return OnboardingProgressState(
      hasCompletedInitialOnboarding: hasCompletedInitialOnboarding ?? this.hasCompletedInitialOnboarding,
      viewedTips: viewedTips ?? this.viewedTips,
      completedTours: completedTours ?? this.completedTours,
      dismissedCoachMarks: dismissedCoachMarks ?? this.dismissedCoachMarks,
      categoryUsageCount: categoryUsageCount ?? this.categoryUsageCount,
      lastTipShownDate: lastTipShownDate ?? this.lastTipShownDate,
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      coachMarksEnabled: coachMarksEnabled ?? this.coachMarksEnabled,
      featureHighlightsEnabled: featureHighlightsEnabled ?? this.featureHighlightsEnabled,
    );
  }

  /// Verifica se um tip já foi visto
  bool hasTipBeenViewed(String tipId) => viewedTips.contains(tipId);

  /// Verifica se um tour foi completado
  bool hasTourBeenCompleted(String tourId) => completedTours.contains(tourId);

  /// Verifica se um coach mark foi dispensado
  bool hasCoachMarkBeenDismissed(String markId) => dismissedCoachMarks.contains(markId);

  /// Retorna a categoria menos usada (para sugerir descoberta)
  FeatureCategory? getLeastUsedCategory() {
    if (categoryUsageCount.isEmpty) return FeatureCategory.mood;
    
    final sorted = categoryUsageCount.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return sorted.first.key;
  }

  /// Pode mostrar tip hoje?
  bool canShowTipToday() {
    if (!tipsEnabled) return false;
    if (lastTipShownDate == null) return true;
    
    final now = DateTime.now();
    return now.difference(lastTipShownDate!).inHours >= 4;
  }
}

/// Configurações de aparência do onboarding
class OnboardingTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final double borderRadius;
  final EdgeInsets padding;
  final bool useGlassMorphism;
  final bool useGradients;
  final Duration animationDuration;

  const OnboardingTheme({
    this.primaryColor = const Color(0xFF6366F1),
    this.backgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xFFB0B0C0),
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(24),
    this.useGlassMorphism = true,
    this.useGradients = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });
}
