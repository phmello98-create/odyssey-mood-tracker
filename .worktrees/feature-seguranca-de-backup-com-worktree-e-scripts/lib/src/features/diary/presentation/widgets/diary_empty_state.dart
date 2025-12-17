// lib/src/features/diary/presentation/widgets/diary_empty_state.dart

import 'package:flutter/material.dart';

/// Estado vazio bonito para o diário
class DiaryEmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback? onCreateEntry;
  final VoidCallback? onClearFilters;

  const DiaryEmptyState({
    super.key,
    this.hasFilters = false,
    this.onCreateEntry,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustração
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
                    colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    hasFilters ? Icons.search_off_rounded : Icons.auto_stories_rounded,
                    size: 64,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  if (!hasFilters)
                    Positioned(
                      bottom: 30,
                      right: 30,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Título
            Text(
              hasFilters
                  ? 'Nenhuma entrada encontrada'
                  : 'Comece seu diário!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Descrição
            Text(
              hasFilters
                  ? 'Tente ajustar os filtros ou buscar por outro termo'
                  : 'Registre seus pensamentos, sentimentos e memórias. Cada entrada é um passo na jornada do autoconhecimento.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Botões de ação
            if (hasFilters) ...[
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Limpar filtros'),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: onCreateEntry,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Criar primeira entrada'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 48),

            // Dicas para novos usuários
            if (!hasFilters) ...[
              _buildTips(context, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTips(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '💡 Dicas para começar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _TipItem(
            icon: '📝',
            text: 'Escreva sobre seu dia ou um momento especial',
            color: colorScheme,
          ),
          const SizedBox(height: 8),
          _TipItem(
            icon: '😊',
            text: 'Registre como você está se sentindo',
            color: colorScheme,
          ),
          const SizedBox(height: 8),
          _TipItem(
            icon: '🏷️',
            text: 'Use tags para organizar suas entradas',
            color: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String icon;
  final String text;
  final ColorScheme color;

  const _TipItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}
