import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_community_data.dart';

/// Seção de Trending - mostra posts em destaque e tags populares
class TrendingSection extends ConsumerWidget {
  const TrendingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final trendingPosts = MockCommunityData.getTrendingPosts(limit: 3);
    final trendingTags = MockCommunityData.getTrendingTags(limit: 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, color: colors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Em Alta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // TODO: Navigate to trending page
                },
                child: Text(
                  'Ver todos',
                  style: TextStyle(fontSize: 12, color: colors.primary),
                ),
              ),
            ],
          ),
        ),

        // Hot Posts Carousel
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: trendingPosts.length,
            itemBuilder: (context, index) {
              final post = trendingPosts[index];
              return _buildHotPostCard(context, post, colors);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Trending Tags
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendingTags.map((tag) {
              return _buildTagChip(context, tag, colors);
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHotPostCard(
    BuildContext context,
    dynamic post,
    ColorScheme colors,
  ) {
    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.errorContainer.withOpacity(0.3),
            colors.primaryContainer.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: Navigate to post detail
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: post.userPhotoUrl != null
                          ? NetworkImage(post.userPhotoUrl!)
                          : null,
                      child: post.userPhotoUrl == null
                          ? const Icon(Icons.person, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: colors.error,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Content preview
                Expanded(
                  child: Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Stats
                Row(
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${post.score}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${post.commentCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(BuildContext context, String tag, ColorScheme colors) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filtrando por #$tag'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            Text(tag, style: TextStyle(fontSize: 12, color: colors.onSurface)),
          ],
        ),
      ),
    );
  }
}
