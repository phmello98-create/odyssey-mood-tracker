// lib/src/features/diary/presentation/widgets/diary_entry_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/diary_entry_entity.dart';
import '../controllers/diary_controller.dart';
import 'diary_feeling_picker.dart';

/// Card elegante para exibição de entrada de diário
class DiaryEntryCard extends ConsumerWidget {
  final DiaryEntryEntity entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showFullDate;
  final bool compact;

  const DiaryEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.showFullDate = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final feeling = DiaryFeeling.fromEmoji(entry.feeling);

    // Cor de destaque baseada no sentimento
    final accentColor = feeling?.color ?? colorScheme.primary;

    return Hero(
      tag: 'diary_entry_${entry.id}',
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: compact ? 8 : 12),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap?.call();
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              onLongPress?.call();
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: accentColor.withValues(alpha: 0.1),
            highlightColor: accentColor.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surface,
                    feeling != null
                        ? accentColor.withValues(alpha: 0.03)
                        : colorScheme.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: entry.starred
                      ? Colors.amber.withValues(alpha: 0.4)
                      : colorScheme.outline.withValues(alpha: 0.15),
                  width: entry.starred ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: entry.starred
                        ? Colors.amber.withValues(alpha: 0.08)
                        : theme.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha de destaque colorida no topo (se tiver sentimento)
                    if (feeling != null)
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withValues(alpha: 0.8),
                              accentColor.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                    // Header simples
                    _buildSimpleHeader(context, ref, feeling, colorScheme),

                    // Conteúdo
                    Padding(
                      padding: EdgeInsets.all(compact ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          if (entry.hasTitle) ...[
                            _buildTitle(theme),
                            SizedBox(height: compact ? 6 : 8),
                          ],

                          // Preview do conteúdo
                          if (entry.searchableText != null && entry.searchableText!.isNotEmpty) ...[
                            _buildContentPreview(theme, colorScheme),
                            const SizedBox(height: 12),
                          ],

                          // Tags
                          if (entry.hasTags && !compact) ...[
                            _buildTags(colorScheme),
                            const SizedBox(height: 12),
                          ],

                          // Footer com estatísticas
                          if (!compact)
                            _buildFooter(theme, colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleHeader(BuildContext context, WidgetRef ref, DiaryFeeling? feeling, ColorScheme colorScheme) {
    final dateFormat = showFullDate
        ? DateFormat('dd MMM yyyy', 'pt_BR')
        : DateFormat('dd MMM', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
      child: Row(
        children: [
          // Data e hora
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                  colorScheme.primaryContainer.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(entry.entryDate),
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (!compact) ...[
                  Text(
                    ' · ${timeFormat.format(entry.entryDate)}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (feeling != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: feeling.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: feeling.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    feeling.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      feeling.label,
                      style: TextStyle(
                        color: feeling.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const Spacer(),
          // Estrela com animação
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            tween: Tween(begin: 1.0, end: entry.starred ? 1.15 : 1.0),
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: IconButton(
              icon: Icon(
                entry.starred ? Icons.star_rounded : Icons.star_outline_rounded,
                color: entry.starred ? Colors.amber[600] : colorScheme.onSurface.withValues(alpha: 0.35),
                size: 26,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(diaryControllerProvider.notifier).toggleStarred(entry.id);
              },
              tooltip: entry.starred ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      entry.title!,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContentPreview(ThemeData theme, ColorScheme colorScheme) {
    return Text(
      entry.searchableText!,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.7),
        height: 1.5,
      ),
      maxLines: compact ? 2 : 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags(ColorScheme colorScheme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: entry.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList()
        ..addAll(
          entry.tags.length > 3
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      '+${entry.tags.length - 3}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]
              : [],
        ),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme) {
    final textColor = colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      children: [
        // Tempo de leitura
        if (entry.effectiveWordCount > 0) ...[
          Icon(Icons.access_time_rounded, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '${entry.effectiveReadingTime} min',
            style: theme.textTheme.labelSmall?.copyWith(color: textColor),
          ),
          const SizedBox(width: 16),
        ],

        // Contagem de palavras
        Icon(Icons.notes_rounded, size: 14, color: textColor),
        const SizedBox(width: 4),
        Text(
          '${entry.effectiveWordCount} palavras',
          style: theme.textTheme.labelSmall?.copyWith(color: textColor),
        ),

        const Spacer(),

        // Indicador de fotos
        if (entry.hasPhotos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_rounded,
                  size: 14,
                  color: colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.photoIds.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Card compacto para lista em grid
class DiaryEntryCardCompact extends StatelessWidget {
  final DiaryEntryEntity entry;
  final VoidCallback? onTap;

  const DiaryEntryCardCompact({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM');
    final feeling = DiaryFeeling.fromEmoji(entry.feeling);
    final accentColor = feeling?.color ?? colorScheme.primary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(18),
      splashColor: accentColor.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              feeling != null
                  ? accentColor.withValues(alpha: 0.05)
                  : colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: entry.starred
                ? Colors.amber.withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.15),
            width: entry.starred ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: entry.starred
                  ? Colors.amber.withValues(alpha: 0.1)
                  : theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.7),
                        colorScheme.primaryContainer.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dateFormat.format(entry.entryDate),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (feeling != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: feeling.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(feeling.emoji, style: const TextStyle(fontSize: 18)),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Título ou preview
            Expanded(
              child: Text(
                entry.title ?? entry.searchableText ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: entry.hasTitle ? FontWeight.w600 : FontWeight.normal,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Indicadores
            if (entry.hasPhotos || entry.starred || entry.hasTags) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (entry.starred)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.star_rounded, size: 14, color: Colors.amber[600]),
                    ),
                  if (entry.hasPhotos) ...[
                    if (entry.starred) const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_rounded, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            '${entry.photoIds.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (entry.hasTags) ...[
                    if (entry.starred || entry.hasPhotos) const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${entry.tags.first}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
