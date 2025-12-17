import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/user_pattern.dart';
import '../../domain/models/prediction.dart';
import '../../domain/models/correlation.dart';
import '../../domain/engines/recommendation_engine.dart';
import 'insight_card.dart';
import 'pattern_chart.dart';
import 'prediction_indicator.dart';

/// Dashboard completo de inteligência
class IntelligenceDashboard extends StatefulWidget {
  final List<Insight> insights;
  final List<UserPattern> patterns;
  final List<Prediction> predictions;
  final List<Correlation> correlations;
  final List<DailyRecommendation> recommendations;
  final VoidCallback? onRefresh;
  final void Function(Insight)? onInsightTap;
  final void Function(UserPattern)? onPatternTap;
  final void Function(Prediction)? onPredictionTap;
  final void Function(Correlation)? onCorrelationTap;
  final void Function(DailyRecommendation)? onRecommendationTap;

  const IntelligenceDashboard({
    super.key,
    required this.insights,
    required this.patterns,
    required this.predictions,
    required this.correlations,
    required this.recommendations,
    this.onRefresh,
    this.onInsightTap,
    this.onPatternTap,
    this.onPredictionTap,
    this.onCorrelationTap,
    this.onRecommendationTap,
  });

  @override
  State<IntelligenceDashboard> createState() => _IntelligenceDashboardState();
}

class _IntelligenceDashboardState extends State<IntelligenceDashboard> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        widget.onRefresh?.call();
      },
      child: CustomScrollView(
        slivers: [
          // Header com resumo
          SliverToBoxAdapter(
            child: _buildHeader(context, colorScheme),
          ),

          // Seção de navegação
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeaderDelegate(
              child: _buildSectionTabs(context, colorScheme),
              backgroundColor: colorScheme.surface,
            ),
          ),

          // Conteúdo da seção selecionada
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildSelectedSection(context),
          ),

          // Espaço no final
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final unreadInsights = widget.insights.where((i) => !i.isRead).length;
    final urgentPredictions =
        widget.predictions.where((p) => p.isHighRisk && !p.isPositive).length;
    final strongCorrelations = widget.correlations
        .where((c) =>
            c.strength == CorrelationStrength.strong ||
            c.strength == CorrelationStrength.veryStrong)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('🧠', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inteligência Odyssey',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Insights personalizados para você',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _QuickStat(
                icon: Icons.lightbulb_outline_rounded,
                value: unreadInsights,
                label: 'Novos',
                color: Colors.amber,
              ),
              _QuickStat(
                icon: Icons.warning_amber_rounded,
                value: urgentPredictions,
                label: 'Alertas',
                color: Colors.orange,
              ),
              _QuickStat(
                icon: Icons.timeline_rounded,
                value: widget.patterns.length,
                label: 'Padrões',
                color: Colors.purple,
              ),
              _QuickStat(
                icon: Icons.link_rounded,
                value: strongCorrelations,
                label: 'Conexões',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs(BuildContext context, ColorScheme colorScheme) {
    final sections = [
      ('Resumo', Icons.dashboard_rounded),
      ('Insights', Icons.lightbulb_outline_rounded),
      ('Padrões', Icons.timeline_rounded),
      ('Previsões', Icons.auto_awesome_rounded),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: sections.asMap().entries.map((entry) {
          final index = entry.key;
          final (label, icon) = entry.value;
          final isSelected = _selectedSection == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedSection = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedSection(BuildContext context) {
    switch (_selectedSection) {
      case 0:
        return _buildSummarySection(context);
      case 1:
        return _buildInsightsSection(context);
      case 2:
        return _buildPatternsSection(context);
      case 3:
        return _buildPredictionsSection(context);
      default:
        return _buildSummarySection(context);
    }
  }

  Widget _buildSummarySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),

        // Recomendações do dia
        if (widget.recommendations.isNotEmpty) ...[
          const _SectionTitle(
            title: 'Recomendações do Dia',
            icon: Icons.tips_and_updates_rounded,
          ),
          const SizedBox(height: 12),
          ...widget.recommendations.take(3).map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DailyRecommendationCardInternal(
                  recommendation: rec,
                  onTap: () => widget.onRecommendationTap?.call(rec),
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Insight destacado
        if (widget.insights.isNotEmpty) ...[
          const _SectionTitle(
            title: 'Insight em Destaque',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 12),
          InsightCard(
            insight: widget.insights.first,
            onTap: () => widget.onInsightTap?.call(widget.insights.first),
          ),
          const SizedBox(height: 16),
        ],

        // Previsões urgentes
        if (widget.predictions.any((p) => p.isHighRisk && !p.isPositive)) ...[
          const _SectionTitle(
            title: 'Atenção Necessária',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          ...widget.predictions
              .where((p) => p.isHighRisk && !p.isPositive)
              .take(2)
              .map((pred) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PredictionIndicator(
                      prediction: pred,
                      onTap: () => widget.onPredictionTap?.call(pred),
                    ),
                  )),
          const SizedBox(height: 16),
        ],

        // Correlações fortes
        if (widget.correlations.any((c) =>
            c.strength == CorrelationStrength.strong ||
            c.strength == CorrelationStrength.veryStrong)) ...[
          const _SectionTitle(
            title: 'Conexões Descobertas',
            icon: Icons.link_rounded,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.correlations
                  .where((c) =>
                      c.strength == CorrelationStrength.strong ||
                      c.strength == CorrelationStrength.veryStrong)
                  .length
                  .clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final corr = widget.correlations
                    .where((c) =>
                        c.strength == CorrelationStrength.strong ||
                        c.strength == CorrelationStrength.veryStrong)
                    .elementAt(index);
                return _CorrelationChipInternal(
                  correlation: corr,
                  onTap: () => widget.onCorrelationTap?.call(corr),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildInsightsSection(BuildContext context) {
    if (widget.insights.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyState(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Nenhum insight ainda',
          subtitle: 'Continue registrando para gerar insights',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return const SizedBox(height: 16);
          }
          final insight = widget.insights[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InsightCard(
              insight: insight,
              onTap: () => widget.onInsightTap?.call(insight),
            ),
          );
        },
        childCount: widget.insights.length + 1,
      ),
    );
  }

  Widget _buildPatternsSection(BuildContext context) {
    if (widget.patterns.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyState(
          icon: Icons.timeline_rounded,
          title: 'Nenhum padrão detectado',
          subtitle: 'Precisamos de mais dados para identificar padrões',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return const SizedBox(height: 16);
          }
          final pattern = widget.patterns[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => widget.onPatternTap?.call(pattern),
              child: PatternChart(pattern: pattern),
            ),
          );
        },
        childCount: widget.patterns.length + 1,
      ),
    );
  }

  Widget _buildPredictionsSection(BuildContext context) {
    if (widget.predictions.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyState(
          icon: Icons.auto_awesome_rounded,
          title: 'Nenhuma previsão disponível',
          subtitle: 'O sistema aprenderá com mais registros',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return const SizedBox(height: 16);
          }
          final prediction = widget.predictions[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PredictionIndicator(
              prediction: prediction,
              onTap: () => widget.onPredictionTap?.call(prediction),
            ),
          );
        },
        childCount: widget.predictions.length + 1,
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = color ?? colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  _SectionHeaderDelegate({
    required this.child,
    required this.backgroundColor,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: child,
    );
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

/// Card para recomendação diária (interno deste arquivo)
class _DailyRecommendationCardInternal extends StatelessWidget {
  final DailyRecommendation recommendation;
  final VoidCallback? onTap;

  const _DailyRecommendationCardInternal({
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priorityColor = _getPriorityColor(recommendation.priority);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: priorityColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: priorityColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recommendation.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return Colors.grey;
      case RecommendationPriority.medium:
        return Colors.blue;
      case RecommendationPriority.high:
        return Colors.orange;
    }
  }
}

/// Chip compacto de correlação (interno deste arquivo)
class _CorrelationChipInternal extends StatelessWidget {
  final Correlation correlation;
  final VoidCallback? onTap;

  const _CorrelationChipInternal({
    required this.correlation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = correlation.isPositive;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  correlation.icon,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    correlation.percentageText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              correlation.variable1Label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.add_rounded : Icons.remove_rounded,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    correlation.variable2Label,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
