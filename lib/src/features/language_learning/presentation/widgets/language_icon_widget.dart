import 'package:flutter/material.dart';
import '../../domain/language.dart';

/// Widget para exibir ícone estilizado de um idioma
class LanguageIconWidget extends StatelessWidget {
  final Language language;
  final double size;
  final bool showBorder;

  const LanguageIconWidget({
    super.key,
    required this.language,
    this.size = 48,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(language.colorValue);
    final fontSize = size * 0.4;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: showBorder 
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Center(
        child: Text(
          language.flag,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Widget compacto para ícone em listas horizontais
class LanguageIconCompact extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final VoidCallback? onTap;

  const LanguageIconCompact({
    super.key,
    required this.language,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = Color(language.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isSelected ? null : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : colors.outline.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  language.flag,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              language.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge pequeno para identificar idioma
class LanguageBadge extends StatelessWidget {
  final Language language;
  final double size;

  const LanguageBadge({
    super.key,
    required this.language,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(language.colorValue);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Text(
          language.flag,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}
