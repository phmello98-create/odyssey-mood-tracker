import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/engines/recommendation_engine.dart';

/// Card para exibir recomendação de atividade
class ActivityRecommendationCard extends StatelessWidget {
  final ActivityRecommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const ActivityRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMENDAÇÃO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendation.activityName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.reason,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildScoreBadge(
                  icon: Icons.trending_up_rounded,
                  label: 'Impacto',
                  value: '+${(recommendation.expectedImpact * 100).toStringAsFixed(0)}%',
                  color: Colors.green,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                _buildScoreBadge(
                  icon: Icons.verified_rounded,
                  label: 'Confiança',
                  value: '${(recommendation.confidence * 100).toStringAsFixed(0)}%',
                  color: colorScheme.tertiary,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card para recomendação de horário
class TimeRecommendationCard extends StatelessWidget {
  final TimeRecommendation recommendation;
  final VoidCallback? onTap;

  const TimeRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getPeriodColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getPeriodIcon(),
                    color: _getPeriodColor(),
                    size: 22,
                  ),
                  Text(
                    '${recommendation.hour}h',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getPeriodColor(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.activity,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${(recommendation.expectedBoost * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPeriodIcon() {
    if (recommendation.hour >= 5 && recommendation.hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (recommendation.hour >= 12 && recommendation.hour < 18) {
      return Icons.wb_twilight_rounded;
    } else if (recommendation.hour >= 18 && recommendation.hour < 21) {
      return Icons.nights_stay_rounded;
    } else {
      return Icons.bedtime_rounded;
    }
  }

  Color _getPeriodColor() {
    if (recommendation.hour >= 5 && recommendation.hour < 12) {
      return Colors.orange;
    } else if (recommendation.hour >= 12 && recommendation.hour < 18) {
      return Colors.amber;
    } else if (recommendation.hour >= 18 && recommendation.hour < 21) {
      return Colors.deepPurple;
    } else {
      return Colors.indigo;
    }
  }
}

/// Card para recomendação diária
class DailyRecommendationCard extends StatelessWidget {
  final DailyRecommendation recommendation;
  final VoidCallback? onActionTap;

  const DailyRecommendationCard({
    super.key,
    required this.recommendation,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPriorityColor().withValues(alpha: 0.2),
            _getPriorityColor().withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getPriorityColor().withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPriorityColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: _getPriorityColor(),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor().withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getPriorityLabel(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            recommendation.category,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recommendation.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onActionTap,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(recommendation.actionLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _getPriorityColor(),
                    side: BorderSide(
                      color: _getPriorityColor().withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (recommendation.category.toLowerCase()) {
      case 'humor':
        return Icons.mood_rounded;
      case 'produtividade':
        return Icons.bolt_rounded;
      case 'hábitos':
        return Icons.repeat_rounded;
      case 'saúde':
        return Icons.favorite_rounded;
      case 'sono':
        return Icons.bedtime_rounded;
      case 'exercício':
        return Icons.fitness_center_rounded;
      case 'social':
        return Icons.people_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  Color _getPriorityColor() {
    switch (recommendation.priority) {
      case RecommendationPriority.high:
        return Colors.red;
      case RecommendationPriority.medium:
        return Colors.orange;
      case RecommendationPriority.low:
        return Colors.blue;
    }
  }

  String _getPriorityLabel() {
    switch (recommendation.priority) {
      case RecommendationPriority.high:
        return 'PRIORIDADE ALTA';
      case RecommendationPriority.medium:
        return 'PRIORIDADE MÉDIA';
      case RecommendationPriority.low:
        return 'SUGESTÃO';
    }
  }
}

/// Lista horizontal de recomendações
class RecommendationsCarousel extends StatelessWidget {
  final List<DailyRecommendation> recommendations;
  final void Function(DailyRecommendation)? onRecommendationTap;

  const RecommendationsCarousel({
    super.key,
    required this.recommendations,
    this.onRecommendationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return SizedBox(
            width: 300,
            child: DailyRecommendationCard(
              recommendation: rec,
              onActionTap: () => onRecommendationTap?.call(rec),
            ),
          );
        },
      ),
    );
  }
}
