import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/onboarding_models.dart';

/// Repositório para persistir estado do onboarding
class OnboardingRepository {
  static const String _keyPrefix = 'onboarding_';
  static const String _keyCompleted = '${_keyPrefix}completed';
  static const String _keyViewedTips = '${_keyPrefix}viewed_tips';
  static const String _keyCompletedTours = '${_keyPrefix}completed_tours';
  static const String _keyDismissedMarks = '${_keyPrefix}dismissed_marks';
  static const String _keyCategoryUsage = '${_keyPrefix}category_usage';
  static const String _keyLastTipDate = '${_keyPrefix}last_tip_date';
  static const String _keyTipsEnabled = '${_keyPrefix}tips_enabled';
  static const String _keyCoachMarksEnabled = '${_keyPrefix}coach_marks_enabled';
  static const String _keyHighlightsEnabled = '${_keyPrefix}highlights_enabled';
  static const String _keyCurrentTourId = '${_keyPrefix}current_tour_id';
  static const String _keyCurrentTourStep = '${_keyPrefix}current_tour_step';
  static const String _keyCompletedFirstSteps = '${_keyPrefix}completed_first_steps';
  static const String _keyFirstStepsDismissed = '${_keyPrefix}first_steps_dismissed';

  final SharedPreferences _prefs;

  OnboardingRepository(this._prefs);

  // ==================== Initial Onboarding ====================

  /// Verifica se o onboarding inicial foi completado
  bool get hasCompletedInitialOnboarding {
    return _prefs.getBool(_keyCompleted) ?? false;
  }

  /// Marca o onboarding inicial como completado
  Future<void> completeInitialOnboarding() async {
    await _prefs.setBool(_keyCompleted, true);
  }

  /// Reseta o onboarding (para debug/testes)
  Future<void> resetOnboarding() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  // ==================== Viewed Tips ====================

  /// Retorna IDs das dicas visualizadas
  Set<String> get viewedTipIds {
    final list = _prefs.getStringList(_keyViewedTips) ?? [];
    return list.toSet();
  }

  /// Marca uma dica como visualizada
  Future<void> markTipAsViewed(String tipId) async {
    final current = viewedTipIds;
    current.add(tipId);
    await _prefs.setStringList(_keyViewedTips, current.toList());
    await _prefs.setString(_keyLastTipDate, DateTime.now().toIso8601String());
  }

  /// Verifica se uma dica foi visualizada
  bool hasTipBeenViewed(String tipId) {
    return viewedTipIds.contains(tipId);
  }

  // ==================== Completed Tours ====================

  /// Retorna IDs dos tours completados
  Set<String> get completedTourIds {
    final list = _prefs.getStringList(_keyCompletedTours) ?? [];
    return list.toSet();
  }

  /// Marca um tour como completado
  Future<void> markTourAsCompleted(String tourId) async {
    final current = completedTourIds;
    current.add(tourId);
    await _prefs.setStringList(_keyCompletedTours, current.toList());
    // Limpa o progresso do tour atual
    await _prefs.remove(_keyCurrentTourId);
    await _prefs.remove(_keyCurrentTourStep);
  }

  /// Verifica se um tour foi completado
  bool hasTourBeenCompleted(String tourId) {
    return completedTourIds.contains(tourId);
  }

  // ==================== Tour Progress ====================

  /// Salva o progresso do tour atual
  Future<void> saveTourProgress(String tourId, int stepIndex) async {
    await _prefs.setString(_keyCurrentTourId, tourId);
    await _prefs.setInt(_keyCurrentTourStep, stepIndex);
  }

  /// Retorna o ID do tour em andamento
  String? get currentTourId {
    return _prefs.getString(_keyCurrentTourId);
  }

  /// Retorna o índice do passo atual do tour
  int get currentTourStepIndex {
    return _prefs.getInt(_keyCurrentTourStep) ?? 0;
  }

  /// Limpa o progresso do tour
  Future<void> clearTourProgress() async {
    await _prefs.remove(_keyCurrentTourId);
    await _prefs.remove(_keyCurrentTourStep);
  }

  // ==================== Dismissed Coach Marks ====================

  /// Retorna IDs dos coach marks dispensados
  Set<String> get dismissedCoachMarkIds {
    final list = _prefs.getStringList(_keyDismissedMarks) ?? [];
    return list.toSet();
  }

  /// Marca um coach mark como dispensado
  Future<void> dismissCoachMark(String markId) async {
    final current = dismissedCoachMarkIds;
    current.add(markId);
    await _prefs.setStringList(_keyDismissedMarks, current.toList());
  }

  /// Verifica se um coach mark foi dispensado
  bool hasCoachMarkBeenDismissed(String markId) {
    return dismissedCoachMarkIds.contains(markId);
  }

  // ==================== Category Usage ====================

  /// Retorna contagem de uso por categoria
  Map<FeatureCategory, int> get categoryUsageCount {
    final json = _prefs.getString(_keyCategoryUsage);
    if (json == null) return {};
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(json);
      return decoded.map((key, value) {
        final category = FeatureCategory.values.firstWhere(
          (c) => c.name == key,
          orElse: () => FeatureCategory.general,
        );
        return MapEntry(category, value as int);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error decoding category usage: $e');
      return {};
    }
  }

  /// Incrementa uso de uma categoria
  Future<void> incrementCategoryUsage(FeatureCategory category) async {
    final current = categoryUsageCount;
    current[category] = (current[category] ?? 0) + 1;
    
    final encoded = jsonEncode(current.map((k, v) => MapEntry(k.name, v)));
    await _prefs.setString(_keyCategoryUsage, encoded);
  }

  // ==================== Settings ====================

  /// Verifica se dicas estão habilitadas
  bool get tipsEnabled {
    return _prefs.getBool(_keyTipsEnabled) ?? true;
  }

  /// Define se dicas estão habilitadas
  Future<void> setTipsEnabled(bool enabled) async {
    await _prefs.setBool(_keyTipsEnabled, enabled);
  }

  /// Verifica se coach marks estão habilitados
  bool get coachMarksEnabled {
    return _prefs.getBool(_keyCoachMarksEnabled) ?? true;
  }

  /// Define se coach marks estão habilitados
  Future<void> setCoachMarksEnabled(bool enabled) async {
    await _prefs.setBool(_keyCoachMarksEnabled, enabled);
  }

  /// Verifica se highlights de feature estão habilitados
  bool get featureHighlightsEnabled {
    return _prefs.getBool(_keyHighlightsEnabled) ?? true;
  }

  /// Define se highlights de feature estão habilitados
  Future<void> setFeatureHighlightsEnabled(bool enabled) async {
    await _prefs.setBool(_keyHighlightsEnabled, enabled);
  }

  /// Retorna a última data que uma dica foi mostrada
  DateTime? get lastTipShownDate {
    final str = _prefs.getString(_keyLastTipDate);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  // ==================== Full State ====================

  /// Carrega o estado completo do onboarding
  OnboardingProgressState loadState() {
    return OnboardingProgressState(
      hasCompletedInitialOnboarding: hasCompletedInitialOnboarding,
      viewedTips: viewedTipIds,
      completedTours: completedTourIds,
      dismissedCoachMarks: dismissedCoachMarkIds,
      categoryUsageCount: categoryUsageCount,
      lastTipShownDate: lastTipShownDate,
      tipsEnabled: tipsEnabled,
      coachMarksEnabled: coachMarksEnabled,
      featureHighlightsEnabled: featureHighlightsEnabled,
    );
  }

  /// Verifica se pode mostrar dica agora
  bool canShowTip() {
    if (!tipsEnabled) return false;
    
    final lastShown = lastTipShownDate;
    if (lastShown == null) return true;
    
    // Mostra no máximo 1 dica a cada 4 horas
    return DateTime.now().difference(lastShown).inHours >= 4;
  }

  // ==================== First Steps Checklist ====================

  /// Retorna IDs dos primeiros passos completados
  Set<String> getCompletedFirstSteps() {
    final list = _prefs.getStringList(_keyCompletedFirstSteps) ?? [];
    return list.toSet();
  }

  /// Marca um primeiro passo como completado
  Future<void> completeFirstStep(String stepId) async {
    final current = getCompletedFirstSteps();
    current.add(stepId);
    await _prefs.setStringList(_keyCompletedFirstSteps, current.toList());
  }

  /// Verifica se um primeiro passo foi completado
  bool hasFirstStepBeenCompleted(String stepId) {
    return getCompletedFirstSteps().contains(stepId);
  }

  /// Verifica se o checklist de primeiros passos foi dispensado
  bool get isFirstStepsDismissed {
    return _prefs.getBool(_keyFirstStepsDismissed) ?? false;
  }

  /// Dispensa o checklist de primeiros passos permanentemente
  Future<void> dismissFirstSteps() async {
    await _prefs.setBool(_keyFirstStepsDismissed, true);
  }

  /// Reseta apenas os primeiros passos (para debug)
  Future<void> resetFirstSteps() async {
    await _prefs.remove(_keyCompletedFirstSteps);
    await _prefs.remove(_keyFirstStepsDismissed);
  }
}
