// lib/src/features/diary/presentation/widgets/sentiment_analysis_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/diary_ai_service.dart';

/// Widget que mostra a análise de sentimento de uma entrada
class SentimentAnalysisWidget extends StatelessWidget {
  final SentimentAnalysis analysis;
  final bool expanded;
  final VoidCallback? onTap;

  const SentimentAnalysisWidget({
    super.key,
    required this.analysis,
    this.expanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Cores baseadas no sentimento
    final sentimentColor = _getSentimentColor(analysis.score);

    if (!expanded) {
      return _buildCompact(colorScheme, sentimentColor);
    }

    return _buildExpanded(context, colorScheme, sentimentColor, theme);
  }

  Widget _buildCompact(ColorScheme colorScheme, Color sentimentColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sentimentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sentimentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(analysis.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              _getSentimentLabel(analysis.sentimentLabel),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sentimentColor,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: sentimentColor.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded(
    BuildContext context,
    ColorScheme colorScheme,
    Color sentimentColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sentimentColor.withValues(alpha: 0.1),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: sentimentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sentimentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(analysis.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise de Sentimento',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getSentimentLabel(analysis.sentimentLabel),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: sentimentColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Score visual
              _buildScoreIndicator(sentimentColor),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de sentimento
          _buildSentimentBar(colorScheme, sentimentColor),

          const SizedBox(height: 16),

          // Resumo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    analysis.summary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Emoções detectadas
          if (analysis.emotions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Emoções Detectadas',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.emotions.entries.map((e) {
                return _buildEmotionChip(e.key, e.value, colorScheme);
              }).toList(),
            ),
          ],

          // Frases-chave
          if (analysis.keyPhrases.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Frases Destacadas',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.keyPhrases.map((phrase) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"',
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phrase,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(Color color) {
    final percentage = ((analysis.score + 1) / 2 * 100).round();
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$percentage',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildSentimentBar(ColorScheme colorScheme, Color sentimentColor) {
    // Score vai de -1 a 1, converter para 0 a 1
    final normalizedScore = (analysis.score + 1) / 2;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('😢', style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5))),
            Text('😐', style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5))),
            Text('😊', style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.2),
                    Colors.grey.withValues(alpha: 0.2),
                    Colors.green.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Indicator
            FractionallySizedBox(
              widthFactor: normalizedScore.clamp(0.05, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: sentimentColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: sentimentColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmotionChip(String emotion, double intensity, ColorScheme colorScheme) {
    final emoji = _getEmotionEmoji(emotion);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            emotion,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSentimentColor(double score) {
    if (score >= 0.3) return const Color(0xFF10B981); // Verde
    if (score >= 0) return const Color(0xFF3B82F6); // Azul
    if (score >= -0.3) return const Color(0xFFF59E0B); // Amarelo
    return const Color(0xFFEF4444); // Vermelho
  }

  String _getSentimentLabel(String label) {
    switch (label) {
      case 'muito_positivo': return 'Muito Positivo';
      case 'positivo': return 'Positivo';
      case 'neutro': return 'Neutro';
      case 'negativo': return 'Reflexivo';
      case 'muito_negativo': return 'Introspectivo';
      default: return 'Neutro';
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion) {
      case 'alegria': return '😊';
      case 'tristeza': return '😢';
      case 'gratidão': return '🙏';
      case 'ansiedade': return '😰';
      case 'raiva': return '😤';
      case 'serenidade': return '😌';
      case 'amor': return '❤️';
      case 'medo': return '😨';
      default: return '💭';
    }
  }
}

/// Widget de chip de sentimento para listas
class SentimentChip extends StatelessWidget {
  final String text;
  final double score;

  const SentimentChip({
    super.key,
    required this.text,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(score);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getColor(double score) {
    if (score >= 0.3) return const Color(0xFF10B981);
    if (score >= 0) return const Color(0xFF3B82F6);
    if (score >= -0.3) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
