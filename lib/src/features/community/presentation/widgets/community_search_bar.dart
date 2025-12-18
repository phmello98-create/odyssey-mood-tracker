import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommunitySearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const CommunitySearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: colors.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Buscar tópicos, pessoas, artigos...',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
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
