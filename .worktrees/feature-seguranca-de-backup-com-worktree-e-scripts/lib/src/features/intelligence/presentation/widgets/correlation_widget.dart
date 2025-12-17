import 'package:flutter/material.dart';
import '../../domain/models/correlation.dart';

/// Widget para exibir correlação entre variáveis
class CorrelationWidget extends StatelessWidget {
  final Correlation correlation;
  final VoidCallback? onTap;

  const CorrelationWidget({
    super.key,
    required this.correlation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: _getCorrelationColor().withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStrengthIndicator(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correlation.description ?? '${correlation.variable1Label} ↔ ${correlation.variable2Label}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCorrelationLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCorrelationColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCoefficientBadge(colorScheme),
              ],
            ),
            const SizedBox(height: 16),
            _buildCorrelationBar(colorScheme),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric(
                  icon: Icons.scatter_plot_rounded,
                  label: 'Amostras',
                  value: '${correlation.sampleSize}',
                  colorScheme: colorScheme,
                ),
                _buildMetric(
                  icon: Icons.science_rounded,
                  label: 'Confiança',
                  value: '${((1 - correlation.pValue) * 100).toStringAsFixed(0)}%',
                  colorScheme: colorScheme,
                ),
                _buildMetric(
                  icon: Icons.verified_rounded,
                  label: 'Significância',
                  value: correlation.isSignificant ? 'Sim' : 'Não',
                  colorScheme: colorScheme,
                  valueColor: correlation.isSignificant ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getCorrelationColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        correlation.coefficient > 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color: _getCorrelationColor(),
        size: 28,
      ),
    );
  }

  Widget _buildCoefficientBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getCorrelationColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${correlation.coefficient > 0 ? '+' : ''}${(correlation.coefficient * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _getCorrelationColor(),
        ),
      ),
    );
  }

  Widget _buildCorrelationBar(ColorScheme colorScheme) {
    final absCoefficient = correlation.coefficient.abs();
    final isPositive = correlation.coefficient > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              correlation.factor1,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Icon(
              isPositive ? Icons.link_rounded : Icons.link_off_rounded,
              size: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const Spacer(),
            Text(
              correlation.factor2,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: absCoefficient,
            minHeight: 8,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(_getCorrelationColor()),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Color _getCorrelationColor() {
    final abs = correlation.coefficient.abs();
    if (abs >= 0.7) {
      return correlation.coefficient > 0 ? Colors.green : Colors.red;
    } else if (abs >= 0.4) {
      return correlation.coefficient > 0 ? Colors.teal : Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  String _getCorrelationLabel() {
    final strength = correlation.strength;
    final direction = correlation.coefficient > 0 ? 'positiva' : 'negativa';

    switch (strength) {
      case CorrelationStrength.veryStrong:
        return 'Correlação muito forte $direction';
      case CorrelationStrength.strong:
        return 'Correlação forte $direction';
      case CorrelationStrength.moderate:
        return 'Correlação moderada $direction';
      case CorrelationStrength.weak:
        return 'Correlação fraca $direction';
      case CorrelationStrength.negligible:
        return 'Correlação negligenciável';
      case CorrelationStrength.none:
        return 'Sem correlação';
    }
  }
}

/// Lista de correlações
class CorrelationsList extends StatelessWidget {
  final List<Correlation> correlations;
  final void Function(Correlation)? onCorrelationTap;

  const CorrelationsList({
    super.key,
    required this.correlations,
    this.onCorrelationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (correlations.isEmpty) {
      return const Center(
        child: Text('Nenhuma correlação detectada ainda'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: correlations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final correlation = correlations[index];
        return CorrelationWidget(
          correlation: correlation,
          onTap: () => onCorrelationTap?.call(correlation),
        );
      },
    );
  }
}

/// Widget compacto para exibir correlação
class CorrelationChip extends StatelessWidget {
  final Correlation correlation;

  const CorrelationChip({
    super.key,
    required this.correlation,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            correlation.coefficient > 0
                ? Icons.add_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            correlation.factor1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            ' → ',
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          Text(
            correlation.factor2,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (correlation.coefficient.abs() >= 0.5) {
      return correlation.coefficient > 0 ? Colors.green : Colors.red;
    }
    return Colors.grey;
  }
}
