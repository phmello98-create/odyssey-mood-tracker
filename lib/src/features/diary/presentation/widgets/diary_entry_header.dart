import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'diary_feeling_picker.dart';

/// Header elegante com gradiente para páginas de entrada do diário
/// Inspirado nos headers do StoryPad
class DiaryEntryHeader extends StatelessWidget {
  final DateTime date;
  final DiaryFeeling? feeling;
  final bool starred;
  final VoidCallback? onBack;
  final VoidCallback? onFeelingTap;
  final VoidCallback? onStarTap;
  final VoidCallback? onMoreTap;
  final bool showActions;

  const DiaryEntryHeader({
    super.key,
    required this.date,
    this.feeling,
    this.starred = false,
    this.onBack,
    this.onFeelingTap,
    this.onStarTap,
    this.onMoreTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getDefaultGradient(feeling, theme.colorScheme),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de ações
            _buildActionBar(context),

            // Conteúdo principal do header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data grande
                  Text(
                    DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(date),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('y', 'pt_BR').format(date),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Colors.black12,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  if (feeling != null) ...[
                    const SizedBox(height: 16),
                    _buildFeelingChip(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Botão voltar
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
            tooltip: 'Voltar',
          ),
          const Spacer(),
          if (showActions) ...[
            // Botão de sentimento
            IconButton(
              icon: Icon(
                feeling != null
                    ? Icons.sentiment_satisfied_rounded
                    : Icons.sentiment_satisfied_outlined,
                color: Colors.white,
              ),
              onPressed: onFeelingTap,
              tooltip: 'Escolher sentimento',
            ),
            // Botão de favorito
            IconButton(
              icon: Icon(
                starred ? Icons.star_rounded : Icons.star_outline_rounded,
                color: starred ? Colors.amber[300] : Colors.white,
              ),
              onPressed: onStarTap,
              tooltip: starred ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            ),
            // Botão de mais opções
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onPressed: onMoreTap,
              tooltip: 'Mais opções',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeelingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            feeling!.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Text(
            feeling!.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getDefaultGradient(DiaryFeeling? feeling, ColorScheme colorScheme) {
    if (feeling == null) {
      return [
        colorScheme.primary,
        colorScheme.primaryContainer,
      ];
    }

    // Gradiente baseado no sentimento
    return [
      feeling.color.withValues(alpha: 0.9),
      feeling.color.withValues(alpha: 0.7),
    ];
  }
}

/// Header compacto para visualização
class DiaryEntryCompactHeader extends StatelessWidget {
  final DateTime date;
  final DiaryFeeling? feeling;
  final bool starred;
  final VoidCallback? onBack;

  const DiaryEntryCompactHeader({
    super.key,
    required this.date,
    this.feeling,
    this.starred = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d \'de\' MMMM', 'pt_BR').format(date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, y', 'pt_BR').format(date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (feeling != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: feeling!.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: feeling!.color.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(feeling!.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ],
            if (starred) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.star_rounded,
                color: Colors.amber[600],
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
