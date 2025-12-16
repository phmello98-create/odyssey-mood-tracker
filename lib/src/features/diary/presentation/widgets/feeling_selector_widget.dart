import 'package:flutter/material.dart';

/// Lista de emojis disponíveis para expressar sentimentos no diário
const List<String> diaryFeelings = [
  '😊', // Feliz
  '😄', // Muito feliz
  '🥰', // Apaixonado
  '😌', // Calmo
  '😴', // Cansado
  '😐', // Neutro
  '🤔', // Pensativo
  '😔', // Triste
  '😢', // Chorando
  '😤', // Frustrado
  '😡', // Bravo
  '😰', // Ansioso
  '🤒', // Doente
  '🥳', // Celebrando
  '😎', // Confiante
  '🙏', // Grato
  '💪', // Forte
  '😮', // Surpreso
  '🤗', // Abraçando
  '😇', // Abençoado
];

/// Widget para seleção de sentimento (emoji) no diário
class FeelingSelectorWidget extends StatelessWidget {
  final String? selectedFeeling;
  final ValueChanged<String?> onFeelingSelected;
  final bool allowDeselect;

  const FeelingSelectorWidget({
    super.key,
    this.selectedFeeling,
    required this.onFeelingSelected,
    this.allowDeselect = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: diaryFeelings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final emoji = diaryFeelings[index];
          final isSelected = selectedFeeling == emoji;

          return GestureDetector(
            onTap: () {
              if (isSelected && allowDeselect) {
                onFeelingSelected(null);
              } else {
                onFeelingSelected(emoji);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget modal para seleção expandida de sentimentos
class FeelingSelectorModal extends StatelessWidget {
  final String? selectedFeeling;
  final ValueChanged<String?> onFeelingSelected;

  const FeelingSelectorModal({
    super.key,
    this.selectedFeeling,
    required this.onFeelingSelected,
  });

  static Future<String?> show(BuildContext context, {String? initialValue}) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeelingSelectorModal(
        selectedFeeling: initialValue,
        onFeelingSelected: (feeling) => Navigator.pop(context, feeling),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Como você está se sentindo?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (selectedFeeling != null)
                TextButton(
                  onPressed: () => onFeelingSelected(null),
                  child: const Text('Limpar'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid de emojis
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: diaryFeelings.map((emoji) {
              final isSelected = selectedFeeling == emoji;

              return GestureDetector(
                onTap: () => onFeelingSelected(emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
