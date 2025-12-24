// lib/src/features/home/presentation/widgets/home_empty_habits_widget.dart

import 'package:flutter/material.dart';

import 'package:odyssey/src/constants/app_theme.dart';

/// Widget de estado vazio para a lista de hábitos
///
/// Exibido quando não há hábitos para o dia selecionado
class HomeEmptyHabitsWidget extends StatelessWidget {
  /// Callback chamado quando o usuário toca em "Criar hábito"
  final VoidCallback? onCreateHabit;

  const HomeEmptyHabitsWidget({super.key, this.onCreateHabit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: UltravioletColors.surfaceVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_repeat_rounded,
            size: 48,
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum hábito para este dia',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (onCreateHabit != null)
            GestureDetector(
              onTap: onCreateHabit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: UltravioletColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: UltravioletColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  '+ Criar hábito',
                  style: TextStyle(
                    color: UltravioletColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
