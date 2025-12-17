import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/models/insight.dart';
import '../domain/models/user_pattern.dart';
import '../domain/models/correlation.dart';
import '../domain/models/prediction.dart';
import 'widgets/pattern_chart.dart';
import 'widgets/correlation_widget.dart';
import 'widgets/prediction_indicator.dart';

/// Tela de detalhe de um insight
class InsightDetailScreen extends StatefulWidget {
  final Insight insight;
  final UserPattern? relatedPattern;
  final Correlation? relatedCorrelation;
  final Prediction? relatedPrediction;
  final VoidCallback? onDismiss;
  final void Function(int rating)? onRate;
  final VoidCallback? onAction;

  const InsightDetailScreen({
    super.key,
    required this.insight,
    this.relatedPattern,
    this.relatedCorrelation,
    this.relatedPrediction,
    this.onDismiss,
    this.onRate,
    this.onAction,
  });

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  int? _userRating;

  @override
  void initState() {
    super.initState();
    _userRating = widget.insight.userRating;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priorityColor = _getPriorityColor(widget.insight.priority, colorScheme);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar com gradiente
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (widget.onDismiss != null)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onDismiss?.call();
                    Navigator.pop(context);
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      priorityColor,
                      priorityColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              widget.insight.icon,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTypeBadge(colorScheme),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Título
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    widget.insight.title.replaceAll(RegExp(r'^\W+'), ''),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Badges de meta
                Row(
                  children: [
                    _buildConfidenceBadge(colorScheme),
                    const SizedBox(width: 12),
                    _buildDateBadge(colorScheme),
                  ],
                ),

                const SizedBox(height: 24),

                // Descrição completa
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detalhes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.insight.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Padrão relacionado
                if (widget.relatedPattern != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    'Padrão Relacionado',
                    Icons.timeline_rounded,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  PatternChart(pattern: widget.relatedPattern!),
                ],

                // Correlação relacionada
                if (widget.relatedCorrelation != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    'Correlação',
                    Icons.link_rounded,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  CorrelationWidget(
                    correlation: widget.relatedCorrelation!,
                  ),
                ],

                // Previsão relacionada
                if (widget.relatedPrediction != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    'Previsão',
                    Icons.auto_awesome_rounded,
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  PredictionIndicator(prediction: widget.relatedPrediction!),
                ],

                // Metadados
                if (widget.insight.metadata.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildMetadataSection(colorScheme),
                ],

                // Avaliação
                const SizedBox(height: 32),
                _buildRatingSection(colorScheme),

                // Ação
                if (widget.insight.actionLabel != null &&
                    widget.onAction != null) ...[
                  const SizedBox(height: 24),
                  _buildActionButton(colorScheme, priorityColor),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(ColorScheme colorScheme) {
    final (label, color) = _getTypeInfo(widget.insight.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(ColorScheme colorScheme) {
    final percentage = (widget.insight.confidence * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$percentage% confiança',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge(ColorScheme colorScheme) {
    final date = widget.insight.generatedAt;
    final formatted = '${date.day}/${date.month}/${date.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(ColorScheme colorScheme) {
    final metadata = widget.insight.metadata;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.data_object_rounded,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'Dados',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metadata.entries.take(6).map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_formatKey(entry.key)}: ${_formatValue(entry.value)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Este insight foi útil?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sua avaliação melhora nossos insights',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = _userRating != null && rating <= _userRating!;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _userRating = rating);
                  widget.onRate?.call(rating);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 36,
                      color: isSelected ? Colors.amber : colorScheme.outline,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_userRating != null) ...[
            const SizedBox(height: 12),
            Text(
              _getRatingText(_userRating!),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme, Color priorityColor) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          widget.onAction?.call();
        },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(widget.insight.actionLabel!),
        style: FilledButton.styleFrom(
          backgroundColor: priorityColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(InsightPriority priority, ColorScheme colorScheme) {
    switch (priority) {
      case InsightPriority.low:
        return colorScheme.outline;
      case InsightPriority.medium:
        return colorScheme.primary;
      case InsightPriority.high:
        return Colors.orange;
      case InsightPriority.urgent:
        return Colors.red;
    }
  }

  (String, Color) _getTypeInfo(InsightType type) {
    switch (type) {
      case InsightType.pattern:
        return ('PADRÃO', Colors.purple);
      case InsightType.correlation:
        return ('CORRELAÇÃO', Colors.blue);
      case InsightType.recommendation:
        return ('SUGESTÃO', Colors.teal);
      case InsightType.prediction:
        return ('PREVISÃO', Colors.indigo);
      case InsightType.warning:
        return ('ALERTA', Colors.orange);
      case InsightType.celebration:
        return ('CONQUISTA', Colors.green);
    }
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    if (value is Map || value is List) {
      return '...';
    }
    return value.toString();
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Não foi útil';
      case 2:
        return 'Pouco útil';
      case 3:
        return 'Útil';
      case 4:
        return 'Muito útil';
      case 5:
        return 'Extremamente útil!';
      default:
        return '';
    }
  }
}
