// lib/src/features/home/presentation/widgets/home_empty_tasks_widget.dart

import 'package:flutter/material.dart';

import 'package:odyssey/src/constants/app_theme.dart';

/// Widget de estado vazio para a lista de tarefas
///
/// Exibido quando não há tarefas para o dia selecionado
class HomeEmptyTasksWidget extends StatelessWidget {
  /// Se está exibindo para "hoje" ou outro dia
  final bool isToday;

  const HomeEmptyTasksWidget({super.key, this.isToday = true});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('empty_tasks'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 48,
            color: UltravioletColors.accentGreen.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            isToday
                ? 'Nenhuma tarefa para hoje!'
                : 'Nenhuma tarefa para este dia',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Digite acima para criar',
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
