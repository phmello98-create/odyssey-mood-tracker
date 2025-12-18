import 'package:flutter/material.dart';

class CommunityInfoBar extends StatelessWidget {
  const CommunityInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(context, Icons.people_outline_rounded, '12.4k', 'Membros'),
          Container(
            height: 20,
            width: 1,
            color: colors.outline.withOpacity(0.2),
          ),
          _buildStat(
            context,
            Icons.circle,
            '432',
            'Online',
            iconColor: const Color(0xFF4CAF50),
            iconSize: 10,
          ),
          Container(
            height: 20,
            width: 1,
            color: colors.outline.withOpacity(0.2),
          ),
          _buildStat(
            context,
            Icons.trending_up_rounded,
            '#Mindfulness',
            'Em Alta',
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    IconData icon,
    String value,
    String label, {
    Color? iconColor,
    double iconSize = 16,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: iconSize, color: iconColor ?? colors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
