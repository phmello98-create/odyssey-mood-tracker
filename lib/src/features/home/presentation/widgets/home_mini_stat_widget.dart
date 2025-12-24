// lib/src/features/home/presentation/widgets/home_mini_stat_widget.dart

import 'package:flutter/material.dart';

/// Widget de estatística mini para exibição compacta
///
/// Usado em cards de insights e resumos para mostrar
/// uma métrica com ícone, valor e label
class HomeMiniStatWidget extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const HomeMiniStatWidget({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
