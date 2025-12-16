import 'package:flutter/services.dart';

/// Serviço centralizado para feedback háptico
/// Fornece métodos semânticos para diferentes tipos de feedback
class HapticService {
  // Singleton
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _enabled = true;

  /// Habilita/desabilita feedback háptico globalmente
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Feedback para seleção de item
  void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Feedback leve para toques simples
  void lightTap() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Feedback médio para ações importantes
  void mediumTap() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Feedback forte para ações críticas
  void heavyTap() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Feedback de sucesso (conclusão de tarefa, etc)
  void success() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Feedback de erro
  void error() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Feedback de aviso
  void warning() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Feedback para mudança de página/navegação
  void navigation() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Feedback para toggle/switch
  void toggle() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Feedback para drag/arrastar
  void drag() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Feedback para soltar item arrastado
  void drop() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Feedback para confirmação (checkbox, etc)
  void confirm() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Feedback para cancelamento
  void cancel() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Feedback para deslizar (swipe)
  void swipe() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Feedback para completar hábito/tarefa
  void complete() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Feedback para desfazer ação
  void undo() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Feedback para deletar
  void delete() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Feedback para notificação/alerta
  void notification() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Feedback para refresh/pull to refresh
  void refresh() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Feedback para scroll snap
  void scrollSnap() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Feedback para pressão longa
  void longPress() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Feedback para modal/bottom sheet
  void modal() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Feedback para achievement/conquista
  void achievement() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Feedback para level up
  void levelUp() async {
    if (!_enabled) return;
    // Sequência de vibrações para level up
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  /// Feedback para streak
  void streak() async {
    if (!_enabled) return;
    // Sequência de vibrações para streak
    for (int i = 0; i < 3; i++) {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  /// Feedback para timer/alarme
  void timer() async {
    if (!_enabled) return;
    // Padrão de vibração para timer
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();
  }

  /// Feedback customizado com duração (apenas Android)
  void custom(int milliseconds) {
    if (!_enabled) return;
    // HapticFeedback não suporta duração customizada nativamente
    // Usamos o mais próximo disponível
    if (milliseconds < 50) {
      HapticFeedback.selectionClick();
    } else if (milliseconds < 100) {
      HapticFeedback.lightImpact();
    } else if (milliseconds < 200) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }
}

/// Instância global do serviço de haptics
final hapticService = HapticService();
