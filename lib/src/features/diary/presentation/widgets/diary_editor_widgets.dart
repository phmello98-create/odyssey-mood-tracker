import 'package:flutter/material.dart';

// ============================================
// SELETOR DE HUMOR PREMIUM
// ============================================
class PremiumMoodSelector extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String> onSelected;

  const PremiumMoodSelector({
    super.key,
    required this.selectedMood,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final moods = [
      _MoodItem(
        'Incrível',
        'amazing',
        Icons.sentiment_very_satisfied_rounded,
        const Color(0xFF4ADE80),
      ),
      _MoodItem(
        'Bem',
        'good',
        Icons.sentiment_satisfied_rounded,
        const Color(0xFF81C784),
      ),
      _MoodItem(
        'Normal',
        'neutral',
        Icons.sentiment_neutral_rounded,
        const Color(0xFF64748B),
      ),
      _MoodItem(
        'Mal',
        'bad',
        Icons.sentiment_dissatisfied_rounded,
        const Color(0xFFFFB74D),
      ),
      _MoodItem(
        'Péssimo',
        'terrible',
        Icons.sentiment_very_dissatisfied_rounded,
        const Color(0xFFEF5350),
      ),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mood = moods[index];
          final isSelected = selectedMood == mood.id;

          return GestureDetector(
            onTap: () => onSelected(mood.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              decoration: BoxDecoration(
                color: isSelected
                    ? mood.color.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? mood.color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mood.icon,
                    size: 32,
                    color: isSelected
                        ? mood.color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mood.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? mood.color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoodItem {
  final String label;
  final String id;
  final IconData icon;
  final Color color;

  _MoodItem(this.label, this.id, this.icon, this.color);
}

// ============================================
// TAG INPUT COM SUGESTÕES
// ============================================
class ModernTagInput extends StatelessWidget {
  final List<String> tags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onInputTap;

  static const List<String> presetTags = [
    'Trabalho',
    'Família',
    'Saúde',
    'Estudos',
    'Lazer',
    'Gratidão',
    'Reflexão',
    'Viagem',
    'Amigos',
    'Metas',
  ];

  const ModernTagInput({
    super.key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onInputTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Sugestões que ainda não foram adicionadas
    final availablePresets = presetTags
        .where((t) => !tags.contains(t))
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags selecionadas
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((tag) => _buildSelectedTag(tag, colors))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Sugestões clicáveis
        Text(
          'Adicionar tags',
          style: theme.textTheme.labelSmall?.copyWith(color: colors.outline),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...availablePresets.map((tag) => _buildPresetTag(tag, colors)),
            _buildCustomTagButton(context, colors),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedTag(String tag, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onRemoveTag(tag),
            child: Icon(Icons.close_rounded, size: 16, color: colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTag(String tag, ColorScheme colors) {
    return GestureDetector(
      onTap: () => onAddTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
        ),
        child: Text(
          '+ $tag',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildCustomTagButton(BuildContext context, ColorScheme colors) {
    return GestureDetector(
      onTap: onInputTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.outline.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Outra...',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TITLE FIELD LIMPO (SEM FUNDO)
// ============================================
class HeadlessTitleField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const HeadlessTitleField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
          height: 1.2,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
