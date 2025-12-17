import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/post.dart';
import 'user_avatar.dart';

/// Card de post no feed da comunidade
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com avatar e info do usuário
            _buildHeader(context, colors),

            // Conteúdo do post
            _buildContent(context, colors),

            // Metadata (se houver)
            if (post.metadata != null) _buildMetadata(context, colors),

            // Footer com reações e comentários
            _buildFooter(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(
            photoUrl: post.userPhotoUrl,
            level: post.userLevel,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.userName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Nv ${post.userLevel}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(post.createdAt, locale: 'pt_BR'),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Badge de tipo de post
          if (post.type != PostType.text) _buildTypeBadge(colors),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(ColorScheme colors) {
    IconData icon;
    String label;
    Color badgeColor;

    switch (post.type) {
      case PostType.achievement:
        icon = Icons.emoji_events_rounded;
        label = 'Conquista';
        badgeColor = Colors.amber;
        break;
      case PostType.insight:
        icon = Icons.lightbulb_rounded;
        label = 'Insight';
        badgeColor = Colors.purple;
        break;
      case PostType.mood:
        icon = Icons.mood_rounded;
        label = 'Humor';
        badgeColor = Colors.blue;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        post.content,
        style: TextStyle(fontSize: 15, height: 1.5, color: colors.onSurface),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, ColorScheme colors) {
    // TODO: Implementar visualização de metadata específica por tipo
    // (achievement, insight, mood)
    return const SizedBox.shrink();
  }

  Widget _buildFooter(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Reações
          _buildReactionButton(context, colors),
          const SizedBox(width: 16),
          // Comentários
          _buildCommentButton(context, colors),
          const Spacer(),
          // Compartilhar
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            onPressed: () {
              // TODO: Implementar compartilhamento
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(BuildContext context, ColorScheme colors) {
    final hasReactions = post.totalReactions > 0;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Implementar reações
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasReactions
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 20,
              color: hasReactions ? Colors.red : colors.onSurfaceVariant,
            ),
            if (hasReactions) ...[
              const SizedBox(width: 6),
              Text(
                '${post.totalReactions}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton(BuildContext context, ColorScheme colors) {
    final hasComments = post.commentCount > 0;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navegar para tela de comentários
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            if (hasComments) ...[
              const SizedBox(width: 6),
              Text(
                '${post.commentCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
