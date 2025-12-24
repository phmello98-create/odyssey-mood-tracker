// lib/src/features/home/presentation/widgets/home_quick_stats_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';

/// Widget de estatísticas rápidas para a home screen
///
/// Exibe:
/// - Melhor streak atual
/// - Hábitos completados hoje
/// - Taxa de conclusão da semana
class HomeQuickStatsWidget extends ConsumerWidget {
  /// Data selecionada para cálculo de "hoje"
  final DateTime selectedDate;

  const HomeQuickStatsWidget({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final allHabits = habitRepo.getAllHabits();
        final todayHabits = habitRepo.getHabitsForDate(selectedDate);
        final completedToday = todayHabits
            .where((h) => h.isCompletedOn(selectedDate))
            .length;

        // Calcular melhor streak
        int bestStreak = 0;
        for (final habit in allHabits) {
          final streak = habit.calculateCurrentStreak();
          if (streak > bestStreak) bestStreak = streak;
        }

        // Taxa de conclusão da semana
        double weekRate = 0;
        final weekRates = habitRepo.getWeekCompletionRates();
        if (weekRates.isNotEmpty) {
          weekRate =
              weekRates.values.reduce((a, b) => a + b) / weekRates.length;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Resumo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stats pills row
              Row(
                children: [
                  // Streak pill
                  Expanded(
                    child: _StatPill(
                      icon: Icons.local_fire_department_rounded,
                      value: '$bestStreak',
                      suffix: 'd',
                      label: 'Streak',
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Hoje pill
                  Expanded(
                    child: _StatPill(
                      icon: Icons.check_circle_rounded,
                      value: '$completedToday',
                      suffix: '/${todayHabits.length}',
                      label: 'Hoje',
                      color: WellnessColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Semana pill
                  Expanded(
                    child: _StatPill(
                      icon: Icons.trending_up_rounded,
                      value: '${(weekRate * 100).round()}',
                      suffix: '%',
                      label: 'Semana',
                      color: UltravioletColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pill individual de estatística
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? suffix;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    this.suffix,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
