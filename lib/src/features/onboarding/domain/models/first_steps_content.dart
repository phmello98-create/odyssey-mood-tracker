import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Modelo para um passo do checklist inicial
class FirstStep {
  final String id;
  final String titlePt;
  final String titleEn;
  final String descriptionPt;
  final String descriptionEn;
  final IconData icon;
  final Color color;
  /// Rota para navegar ao clicar (opcional)
  final String? route;
  /// XP ganho ao completar
  final int xpReward;
  /// Ordem de exibição
  final int order;

  const FirstStep({
    required this.id,
    required this.titlePt,
    required this.titleEn,
    required this.descriptionPt,
    required this.descriptionEn,
    required this.icon,
    required this.color,
    this.route,
    this.xpReward = 10,
    required this.order,
  });

  String getTitle(bool isPortuguese) => isPortuguese ? titlePt : titleEn;
  String getDescription(bool isPortuguese) => isPortuguese ? descriptionPt : descriptionEn;
}

/// Conteúdo dos primeiros passos do usuário
class FirstStepsContent {
  static const List<FirstStep> all = [
    FirstStep(
      id: 'register_mood',
      titlePt: 'Registrar primeiro humor',
      titleEn: 'Log your first mood',
      descriptionPt: 'Como você está agora?',
      descriptionEn: 'How are you feeling now?',
      icon: Icons.mood_rounded,
      color: Color(0xFFEC4899),
      route: '/mood',
      xpReward: 15,
      order: 1,
    ),
    FirstStep(
      id: 'start_timer',
      titlePt: 'Iniciar um timer',
      titleEn: 'Start a timer',
      descriptionPt: 'Foque por alguns minutos',
      descriptionEn: 'Focus for a few minutes',
      icon: Icons.timer_rounded,
      color: Color(0xFFFF6B6B),
      route: '/timer',
      xpReward: 10,
      order: 2,
    ),
    FirstStep(
      id: 'create_habit',
      titlePt: 'Criar um hábito',
      titleEn: 'Create a habit',
      descriptionPt: 'Algo que quer fazer todo dia',
      descriptionEn: 'Something you want to do daily',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF10B981),
      route: '/habits',
      xpReward: 10,
      order: 3,
    ),
    FirstStep(
      id: 'create_note',
      titlePt: 'Escrever uma nota',
      titleEn: 'Write a note',
      descriptionPt: 'Capture uma ideia rápida',
      descriptionEn: 'Capture a quick idea',
      icon: Icons.note_rounded,
      color: Color(0xFF3B82F6),
      route: '/notes',
      xpReward: 10,
      order: 4,
    ),
    FirstStep(
      id: 'complete_tour',
      titlePt: 'Completar um tour',
      titleEn: 'Complete a tour',
      descriptionPt: 'Use o botão ? em qualquer tela',
      descriptionEn: 'Use the ? button on any screen',
      icon: Icons.help_outline_rounded,
      color: Color(0xFF8B5CF6),
      xpReward: 20,
      order: 5,
    ),
  ];

  /// Retorna passo por ID
  static FirstStep? byId(String id) {
    return all.firstWhereOrNull((step) => step.id == id);
  }

  /// Calcula total de XP disponível
  static int get totalXp => all.fold(0, (sum, step) => sum + step.xpReward);
}
