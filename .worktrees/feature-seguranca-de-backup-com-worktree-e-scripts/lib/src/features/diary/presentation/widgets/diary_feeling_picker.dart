import 'package:flutter/material.dart';

/// Sentimentos disponíveis para entradas do diário
enum DiaryFeeling {
  amazing('😄', 'Incrível', Color(0xFFFFD700)),
  happy('😊', 'Feliz', Color(0xFF4CAF50)),
  good('🙂', 'Bem', Color(0xFF8BC34A)),
  okay('😐', 'Ok', Color(0xFFFFC107)),
  sad('😢', 'Triste', Color(0xFF2196F3)),
  anxious('😰', 'Ansioso', Color(0xFFFF9800)),
  angry('😠', 'Irritado', Color(0xFFF44336)),
  tired('😴', 'Cansado', Color(0xFF9E9E9E)),
  excited('🤩', 'Empolgado', Color(0xFFE91E63)),
  grateful('🙏', 'Grato', Color(0xFF9C27B0)),
  peaceful('😌', 'Sereno', Color(0xFF00BCD4)),
  loved('🥰', 'Amado', Color(0xFFFF4081)),
  confused('😕', 'Confuso', Color(0xFF795548)),
  proud('😎', 'Orgulhoso', Color(0xFFFF5722)),
  hopeful('🌟', 'Esperançoso', Color(0xFFFFEB3B));

  const DiaryFeeling(this.emoji, this.label, this.color);
  final String emoji;
  final String label;
  final Color color;

  /// Encontra feeling pelo emoji
  static DiaryFeeling? fromEmoji(String? emoji) {
    if (emoji == null) return null;
    try {
      return DiaryFeeling.values.firstWhere((f) => f.emoji == emoji);
    } catch (_) {
      return null;
    }
  }
}

/// Componente de seleção de sentimentos
/// Inspirado no StoryPad feeling picker
class DiaryFeelingPicker extends StatelessWidget {
  final DiaryFeeling? selectedFeeling;
  final ValueChanged<DiaryFeeling?> onFeelingChanged;
  final bool showLabel;
  final bool compact;

  const DiaryFeelingPicker({
    super.key,
    this.selectedFeeling,
    required this.onFeelingChanged,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactFeelingPicker(
        selectedFeeling: selectedFeeling,
        onFeelingChanged: onFeelingChanged,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Como você está se sentindo?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DiaryFeeling.values.map((feeling) {
            final isSelected = selectedFeeling == feeling;
            return _FeelingChip(
              feeling: feeling,
              isSelected: isSelected,
              onTap: () {
                if (isSelected) {
                  onFeelingChanged(null); // Deselect
                } else {
                  onFeelingChanged(feeling);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Chip de sentimento individual
class _FeelingChip extends StatelessWidget {
  final DiaryFeeling feeling;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeelingChip({
    required this.feeling,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected
            ? feeling.color.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: isSelected ? 2 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? feeling.color
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  feeling.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  feeling.label,
                  style: TextStyle(
                    color: isSelected
                        ? feeling.color
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Versão compacta do feeling picker (para toolbar)
class _CompactFeelingPicker extends StatelessWidget {
  final DiaryFeeling? selectedFeeling;
  final ValueChanged<DiaryFeeling?> onFeelingChanged;

  const _CompactFeelingPicker({
    this.selectedFeeling,
    required this.onFeelingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DiaryFeeling?>(
      initialValue: selectedFeeling,
      tooltip: 'Selecionar sentimento',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selectedFeeling?.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedFeeling != null
                ? selectedFeeling!.color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedFeeling?.emoji ?? '😊',
              style: const TextStyle(fontSize: 20),
            ),
            if (selectedFeeling != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: selectedFeeling!.color,
                size: 20,
              ),
            ] else
              Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        if (selectedFeeling != null)
          PopupMenuItem<DiaryFeeling?>(
            value: null,
            child: Row(
              children: [
                Icon(
                  Icons.clear,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Remover sentimento',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        if (selectedFeeling != null) const PopupMenuDivider(),
        ...DiaryFeeling.values.map((feeling) {
          return PopupMenuItem<DiaryFeeling?>(
            value: feeling,
            child: Row(
              children: [
                Text(
                  feeling.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Text(feeling.label),
                if (selectedFeeling == feeling) ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: feeling.color,
                    size: 20,
                  ),
                ],
              ],
            ),
          );
        }),
      ],
      onSelected: onFeelingChanged,
    );
  }
}

/// Botão simples de feeling (para mostrar em cards)
class DiaryFeelingButton extends StatelessWidget {
  final DiaryFeeling feeling;
  final VoidCallback? onTap;
  final bool showLabel;
  final double size;

  const DiaryFeelingButton({
    super.key,
    required this.feeling,
    this.onTap,
    this.showLabel = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: feeling.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: feeling.color.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          feeling.emoji,
          style: TextStyle(fontSize: size * 0.6),
        ),
      ),
    );

    if (onTap == null && !showLabel) {
      return SizedBox(width: size, height: size, child: content);
    }

    if (!showLabel) {
      return SizedBox(
        width: size,
        height: size,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: content,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: size, height: size, child: content),
            const SizedBox(width: 8),
            Text(
              feeling.label,
              style: TextStyle(
                color: feeling.color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
