import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/mock_community_data.dart';

/// Widget de Leaderboard mini - mostra top usuários ativos
class TopUsersWidget extends StatelessWidget {
  const TopUsersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Get users sorted by level/karma
    final allUsers = MockCommunityData.searchUsers('');
    // Sort by level, then XP
    final sortedUsers = List.from(allUsers)
      ..sort((a, b) {
        final levelCmp = b.level.compareTo(a.level);
        if (levelCmp != 0) return levelCmp;
        return b.totalXP.compareTo(a.totalXP);
      });
    final topUsers = sortedUsers.take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Top Membros',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // User list
          ...topUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return _buildUserRow(context, user, index + 1, colors);
          }),
        ],
      ),
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    dynamic user,
    int rank,
    ColorScheme colors,
  ) {
    final rankColors = [
      Colors.amber,
      Colors.grey.shade400,
      Colors.brown.shade300,
    ];
    final rankColor = rank <= 3
        ? rankColors[rank - 1]
        : colors.onSurfaceVariant;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil de ${user.displayName}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 24,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),

            // Avatar
            CircleAvatar(
              radius: 14,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              backgroundColor: colors.primaryContainer,
              child: user.photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 14,
                      color: colors.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: 8),

            // Name and level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Nível ${user.level}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // XP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_formatNumber(user.totalXP)} XP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
