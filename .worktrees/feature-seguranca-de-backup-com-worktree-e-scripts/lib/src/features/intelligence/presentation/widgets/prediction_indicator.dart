import 'package:flutter/material.dart';
import '../../domain/models/prediction.dart';

/// Widget para exibir uma previsão
class PredictionIndicator extends StatelessWidget {
  final Prediction prediction;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const PredictionIndicator({
    super.key,
    required this.prediction,
    this.onTap,
    this.onDismiss,
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getTypeColor().withValues(alpha: 0.15),
              _getTypeColor().withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getTypeColor().withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prediction.description,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConfidenceBar(colorScheme),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTimeRemaining(colorScheme),
                const Spacer(),
                _buildConfidenceBadge(),
              ],
            ),
            if (prediction.actionSuggestion != null) ...[
              const SizedBox(height: 12),
              _buildActionSuggestion(colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confiança',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              '${(prediction.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getTypeColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: prediction.confidence,
            minHeight: 6,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(_getTypeColor()),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRemaining(ColorScheme colorScheme) {
    final now = DateTime.now();
    final diff = prediction.predictedFor.difference(now);

    String timeText;
    if (diff.isNegative) {
      timeText = 'Expirado';
    } else if (diff.inHours < 1) {
      timeText = 'Em ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      timeText = 'Em ${diff.inHours}h';
    } else {
      timeText = 'Em ${diff.inDays} dias';
    }

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge() {
    final level = prediction.confidence >= 0.8
        ? 'Alta'
        : prediction.confidence >= 0.5
            ? 'Média'
            : 'Baixa';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Confiança $level',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getTypeColor(),
        ),
      ),
    );
  }

  Widget _buildActionSuggestion(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prediction.actionSuggestion!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (prediction.type) {
      case PredictionType.streakBreak:
        return Icons.warning_amber_rounded;
      case PredictionType.streakSuccess:
        return Icons.local_fire_department_rounded;
      case PredictionType.moodDrop:
        return Icons.trending_down_rounded;
      case PredictionType.moodImprovement:
        return Icons.trending_up_rounded;
      case PredictionType.taskCompletion:
        return Icons.task_alt_rounded;
      case PredictionType.habitCompletion:
        return Icons.repeat_rounded;
      case PredictionType.productiveDay:
        return Icons.bolt_rounded;
    }
  }

  Color _getTypeColor() {
    switch (prediction.type) {
      case PredictionType.streakBreak:
        return Colors.red;
      case PredictionType.streakSuccess:
        return Colors.orange;
      case PredictionType.moodDrop:
        return Colors.deepOrange;
      case PredictionType.moodImprovement:
        return Colors.green;
      case PredictionType.taskCompletion:
        return Colors.blue;
      case PredictionType.habitCompletion:
        return Colors.purple;
      case PredictionType.productiveDay:
        return Colors.teal;
    }
  }

  String _getTypeLabel() {
    switch (prediction.type) {
      case PredictionType.streakBreak:
        return 'ALERTA DE STREAK';
      case PredictionType.streakSuccess:
        return 'STREAK SEGURO';
      case PredictionType.moodDrop:
        return 'ALERTA DE HUMOR';
      case PredictionType.moodImprovement:
        return 'MELHORIA PREVISTA';
      case PredictionType.taskCompletion:
        return 'PREVISÃO DE TAREFA';
      case PredictionType.habitCompletion:
        return 'PREVISÃO DE HÁBITO';
      case PredictionType.productiveDay:
        return 'DIA PRODUTIVO';
    }
  }
}

/// Card compacto de previsão para dashboard
class PredictionMiniCard extends StatelessWidget {
  final Prediction prediction;
  final VoidCallback? onTap;

  const PredictionMiniCard({
    super.key,
    required this.prediction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _getTypeColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getTypeColor().withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getTypeIcon(),
              color: _getTypeColor(),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                prediction.description,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (prediction.type) {
      case PredictionType.streakBreak:
        return Icons.warning_amber_rounded;
      case PredictionType.streakSuccess:
        return Icons.local_fire_department_rounded;
      case PredictionType.moodDrop:
        return Icons.trending_down_rounded;
      case PredictionType.moodImprovement:
        return Icons.trending_up_rounded;
      case PredictionType.taskCompletion:
        return Icons.task_alt_rounded;
      case PredictionType.habitCompletion:
        return Icons.repeat_rounded;
      case PredictionType.productiveDay:
        return Icons.bolt_rounded;
    }
  }

  Color _getTypeColor() {
    switch (prediction.type) {
      case PredictionType.streakBreak:
        return Colors.red;
      case PredictionType.streakSuccess:
        return Colors.orange;
      case PredictionType.moodDrop:
        return Colors.deepOrange;
      case PredictionType.moodImprovement:
        return Colors.green;
      case PredictionType.taskCompletion:
        return Colors.blue;
      case PredictionType.habitCompletion:
        return Colors.purple;
      case PredictionType.productiveDay:
        return Colors.teal;
    }
  }
}

/// Lista de previsões
class PredictionsList extends StatelessWidget {
  final List<Prediction> predictions;
  final void Function(Prediction)? onPredictionTap;
  final void Function(Prediction)? onPredictionDismiss;

  const PredictionsList({
    super.key,
    required this.predictions,
    this.onPredictionTap,
    this.onPredictionDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return const Center(
        child: Text('Nenhuma previsão disponível'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: predictions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        return PredictionIndicator(
          prediction: prediction,
          onTap: () => onPredictionTap?.call(prediction),
          onDismiss: onPredictionDismiss != null
              ? () => onPredictionDismiss?.call(prediction)
              : null,
        );
      },
    );
  }
}
