// lib/src/features/diary/presentation/widgets/diary_insights_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/diary_ai_service.dart';

/// Widget que exibe insights gerados sobre o diário
class DiaryInsightsWidget extends ConsumerWidget {
  final bool compact;
  final VoidCallback? onViewAll;

  const DiaryInsightsWidget({
    super.key,
    this.compact = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(diaryInsightsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return insightsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();

        if (compact) {
          return _buildCompact(context, insights.first, colorScheme, theme);
        }

        return _buildFull(context, insights, colorScheme, theme);
      },
    );
  }

  Widget _buildCompact(
    BuildContext context,
    DiaryInsight insight,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onViewAll?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getInsightColor(insight.type).withValues(alpha: 0.15),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getInsightColor(insight.type).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getInsightColor(insight.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(insight.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insight.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (onViewAll != null)
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(
    BuildContext context,
    List<DiaryInsight> insights,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.tertiary.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Ver todos'),
                  ),
              ],
            ),
          ),

          // Lista de insights
          ...insights.take(3).map((insight) => _buildInsightCard(
            context,
            insight,
            colorScheme,
            theme,
          )),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    DiaryInsight insight,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final color = _getInsightColor(insight.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone com gradiente
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(insight.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getInsightTypeLabel(insight.type),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'streak': return const Color(0xFFFF6B35);
      case 'pattern': return const Color(0xFF6366F1);
      case 'mood': return const Color(0xFF10B981);
      case 'milestone': return const Color(0xFFF59E0B);
      case 'stats': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF3B82F6);
    }
  }

  String _getInsightTypeLabel(String type) {
    switch (type) {
      case 'streak': return 'SEQUÊNCIA';
      case 'pattern': return 'PADRÃO';
      case 'mood': return 'HUMOR';
      case 'milestone': return 'MARCO';
      case 'stats': return 'ESTATÍSTICA';
      default: return 'INSIGHT';
    }
  }
}

/// Widget de streak do diário
class DiaryStreakWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final bool compact;

  const DiaryStreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      return _buildCompact(colorScheme);
    }

    return _buildFull(context, colorScheme, theme);
  }

  Widget _buildCompact(ColorScheme colorScheme) {
    if (currentStreak == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.2),
            const Color(0xFFF59E0B).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$currentStreak dias',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.15),
            const Color(0xFFF59E0B).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Ícone de fogo animado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),

          // Streak atual
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStreak == 0
                      ? 'Comece sua sequência!'
                      : '$currentStreak ${currentStreak == 1 ? 'dia' : 'dias'} consecutivos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(height: 4),
                if (longestStreak > 0)
                  Text(
                    'Recorde: $longestStreak dias',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                if (currentStreak > 0)
                  Text(
                    _getMotivationalMessage(currentStreak),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          // Próximo marco
          if (currentStreak > 0) _buildNextMilestone(currentStreak, colorScheme),
        ],
      ),
    );
  }

  Widget _buildNextMilestone(int streak, ColorScheme colorScheme) {
    final nextMilestone = _getNextMilestone(streak);
    final progress = streak / nextMilestone;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B35)),
              ),
            ),
            Text(
              '$nextMilestone',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Próximo',
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  int _getNextMilestone(int streak) {
    if (streak < 7) return 7;
    if (streak < 14) return 14;
    if (streak < 30) return 30;
    if (streak < 60) return 60;
    if (streak < 100) return 100;
    if (streak < 365) return 365;
    return ((streak ~/ 100) + 1) * 100;
  }

  String _getMotivationalMessage(int streak) {
    if (streak >= 365) return 'Um ano inteiro! Você é incrível! 🎉';
    if (streak >= 100) return 'Mais de 100 dias! Inspirador! 🌟';
    if (streak >= 30) return 'Um mês de consistência! 💪';
    if (streak >= 14) return 'Duas semanas! Continue assim! 🚀';
    if (streak >= 7) return 'Uma semana completa! 🎯';
    if (streak >= 3) return 'Está criando um hábito! 📝';
    return 'Mantenha o ritmo! ✨';
  }
}
