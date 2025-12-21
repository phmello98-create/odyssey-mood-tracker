import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/post.dart';
import '../../domain/topic.dart';
import '../../domain/karma.dart';
import '../screens/post_detail_screen.dart';
import '../screens/public_profile_screen.dart';
import 'user_profile_popup.dart';

/// Helper class para dados do mood
class _MoodData {
  final String emoji;
  final Color color;

  const _MoodData({required this.emoji, required this.color});
}

/// Card de post rico estilo Reddit
/// Com votos, karma, badges, imagens, tags
class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final bool showUserAvatar;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.showUserAvatar = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late bool _isUpvoted;
  late bool _isDownvoted;
  late int _score;

  @override
  void initState() {
    super.initState();
    // Simulate checking if user voted (mock)
    _isUpvoted = false;
    _isDownvoted = false;
    _score = widget.post.score;
  }

  void _handleUpvote() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_isUpvoted) {
        _isUpvoted = false;
        _score -= 1;
      } else {
        if (_isDownvoted) {
          _isDownvoted = false;
          _score += 1;
        }
        _isUpvoted = true;
        _score += 1;
      }
    });
  }

  void _handleDownvote() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isDownvoted) {
        _isDownvoted = false;
        _score += 1;
      } else {
        if (_isUpvoted) {
          _isUpvoted = false;
          _score -= 1;
        }
        _isDownvoted = true;
        _score -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap ?? () => _navigateToDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceContainerHighest : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.post.isPinned
                ? colors.primary.withOpacity(0.5) // Pinned highlight
                : colors.outlineVariant.withOpacity(0.3),
            width: widget.post.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.post.isPinned
                  ? colors.primary.withOpacity(0.08)
                  : colors.shadow.withOpacity(0.05),
              blurRadius: widget.post.isPinned ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Topic + Author info
            _buildHeader(context, colors),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildContent(context, colors),
            ),

            // Images (if any)
            if (widget.post.hasImages) _buildImagePreview(context),

            // Tags
            if (widget.post.tags.isNotEmpty) _buildTags(context, colors),

            // Footer: Votes + Comments + Views
            _buildFooter(context, colors),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: widget.post)),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: widget.post.userId,
          userName: widget.post.userName,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    // Pega o primeiro tópico
    final topicName = widget.post.categories.isNotEmpty
        ? widget.post.categories.first
        : null;
    final topic = topicName != null
        ? CommunityTopic.values.firstWhere(
            (t) => t.name == topicName,
            orElse: () => CommunityTopic.general,
          )
        : CommunityTopic.general;

    // Karma tier do autor
    final karmaTier = KarmaTierExtension.fromKarma(widget.post.authorKarma);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar decorativo
          if (widget.showUserAvatar) ...[
            _buildDecoratedAvatar(colors, karmaTier),
            const SizedBox(width: 10),
          ],

          // Autor info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome + Flair/Badge + BOT Badge
                GestureDetector(
                  onTap: () => _navigateToProfile(context),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.post.userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // BOT Badge (se for bot)
                      if (widget.post.userId.startsWith('bot_'))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getBotColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getBotColor().withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.smart_toy_outlined,
                                size: 10,
                                color: _getBotColor(),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'BOT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _getBotColor(),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.post.userId.startsWith('bot_'))
                        const SizedBox(width: 6),
                      // Flair or Pinned Badge
                      if (widget.post.authorFlair != null ||
                          widget.post.isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(
                              karmaTier.colorValue,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.post.isPinned ? '📌' : karmaTier.emoji,
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.post.isPinned
                                    ? 'Fixado'
                                    : (widget.post.authorFlair ?? ''),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(karmaTier.colorValue),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Topic + Time
                Row(
                  children: [
                    // Topic badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(topic.colorValue).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            topic.emoji,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            topic.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(topic.colorValue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tempo
                    Text(
                      timeago.format(widget.post.createdAt, locale: 'pt_BR'),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Post type badge
          if (widget.post.type != PostType.text) _buildTypeBadge(colors),
        ],
      ),
    );
  }

  Widget _buildDecoratedAvatar(ColorScheme colors, KarmaTier tier) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        UserProfilePopup.show(
          context,
          userId: widget.post.userId,
          userName: widget.post.userName,
          userPhotoUrl: widget.post.userPhotoUrl,
          userLevel: widget.post.userLevel,
          karma: widget.post.authorKarma,
          flair: widget.post.authorFlair,
          onFollow: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Seguindo ${widget.post.userName}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          onViewProfile: () {
            _navigateToProfile(context);
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color(tier.colorValue),
              Color(tier.colorValue).withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
          ),
          child: ClipOval(
            child: widget.post.userPhotoUrl != null
                ? Image.network(
                    widget.post.userPhotoUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildAvatarPlaceholder(colors);
                    },
                    errorBuilder: (_, __, ___) =>
                        _buildAvatarPlaceholder(colors),
                  )
                : _buildAvatarPlaceholder(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(ColorScheme colors) {
    return Container(
      color: colors.primaryContainer,
      child: Center(
        child: Text(
          widget.post.userName.isNotEmpty
              ? widget.post.userName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ColorScheme colors) {
    String label;
    Color badgeColor;

    switch (widget.post.type) {
      case PostType.achievement:
        label = '🏆';
        badgeColor = const Color(0xFFFFD700);
        break;
      case PostType.insight:
        label = '💡';
        badgeColor = const Color(0xFF9D84B7);
        break;
      case PostType.mood:
        label = '💭';
        badgeColor = const Color(0xFF81B29A);
        break;
      case PostType.image:
      case PostType.gallery:
        label = '📷';
        badgeColor = const Color(0xFF2196F3);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colors) {
    // Mostra o mood card se houver moodLabel no metadata (qualquer tipo de post)
    final hasMood =
        widget.post.metadata != null &&
        (widget.post.metadata!['moodLabel'] != null ||
            widget.post.metadata!['mood'] != null);

    if (hasMood) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood Card Visual
          _buildMoodCard(context, colors),
          const SizedBox(height: 12),
          // Texto do post
          Text(
            widget.post.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colors.onSurface,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      widget.post.content,
      style: TextStyle(fontSize: 14, height: 1.5, color: colors.onSurface),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMoodCard(BuildContext context, ColorScheme colors) {
    final metadata = widget.post.metadata;
    final moodLabel =
        metadata?['moodLabel'] as String? ?? metadata?['mood'] as String?;
    final moodEmoji = metadata?['moodEmoji'] as String?;

    if (moodLabel == null) return const SizedBox.shrink();

    // Mapeamento de moods para cores e assets
    final moodData = _getMoodData(moodLabel);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodData.color.withOpacity(0.15),
            moodData.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: moodData.color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // Ícone/Emoji do mood em um container circular
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: moodData.color.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                moodEmoji ?? moodData.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Label do mood
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estou me sentindo',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  moodLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: moodData.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _MoodData _getMoodData(String moodLabel) {
    final label = moodLabel.toLowerCase();

    // Mapeamento exato dos moods do CreatePostScreen
    if (label == 'ótimo' || label == 'otimo') {
      return const _MoodData(emoji: '😊', color: Color(0xFF4CAF50)); // Green
    } else if (label == 'bem') {
      return const _MoodData(
        emoji: '🙂',
        color: Color(0xFF7C4DFF),
      ); // Deep Purple
    } else if (label == 'ok') {
      return const _MoodData(emoji: '😐', color: Color(0xFFFFC107)); // Amber
    } else if (label == 'mal') {
      return const _MoodData(emoji: '😔', color: Color(0xFFFF9800)); // Orange
    } else if (label == 'péssimo' || label == 'pessimo') {
      return const _MoodData(emoji: '😢', color: Color(0xFFF44336)); // Red
    }
    // Mapeamentos adicionais para compatibilidade
    else if (label.contains('incrível') ||
        label.contains('incrivel') ||
        label == 'radiante') {
      return const _MoodData(emoji: '🌟', color: Color(0xFFFFD700));
    } else if (label.contains('feliz') || label == 'alegre') {
      return const _MoodData(emoji: '😊', color: Color(0xFF4CAF50));
    } else if (label.contains('tranquilo')) {
      return const _MoodData(emoji: '😌', color: Color(0xFF81C784));
    } else if (label.contains('neutro') || label == 'calmo') {
      return const _MoodData(emoji: '😐', color: Color(0xFF90A4AE));
    } else if (label.contains('ansioso') || label.contains('preocupado')) {
      return const _MoodData(emoji: '😰', color: Color(0xFFFFB74D));
    } else if (label.contains('triste') ||
        label.contains('struggling') ||
        label.contains('difícil')) {
      return const _MoodData(emoji: '😢', color: Color(0xFF64B5F6));
    } else if (label.contains('estressado') || label.contains('irritado')) {
      return const _MoodData(emoji: '😤', color: Color(0xFFE57373));
    } else if (label.contains('cansado') || label.contains('exausto')) {
      return const _MoodData(emoji: '😴', color: Color(0xFF9575CD));
    } else if (label.contains('energético') || label.contains('energizado')) {
      return const _MoodData(emoji: '⚡', color: Color(0xFFFFCA28));
    } else if (label.contains('grato') || label.contains('agradecido')) {
      return const _MoodData(emoji: '🙏', color: Color(0xFFE91E63));
    }

    // Default
    return const _MoodData(emoji: '💭', color: Color(0xFF81B29A));
  }

  /// Retorna a cor temática do bot baseado no userId
  Color _getBotColor() {
    switch (widget.post.userId) {
      case 'bot_beatnix':
        return const Color(0xFF6366F1); // Indigo
      case 'bot_erro404':
        return const Color(0xFF10B981); // Emerald
      case 'bot_wiki':
        return const Color(0xFF8B5CF6); // Violet
      case 'bot_turbo':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    final imageUrl = widget.post.imageUrls.first;
    final isLocalFile = imageUrl.startsWith('file://');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagem - local ou de rede
            isLocalFile
                ? Image.file(
                    File(imageUrl.replaceFirst('file://', '')),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image_rounded, size: 40),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image_rounded, size: 40),
                    ),
                  ),
            // Gallery indicator
            if (widget.post.isGallery)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${widget.post.imageUrls.length - 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: widget.post.tags.take(4).map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withOpacity(0.2)),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Upvote/Downvote
          _buildVoteSection(context, colors),

          const SizedBox(width: 16),

          // Comments
          _buildStatItem(
            context,
            colors,
            Icons.chat_bubble_outline_rounded,
            widget.post.commentCount.toString(),
            'comentários',
          ),

          const SizedBox(width: 16),

          // Views
          _buildStatItem(
            context,
            colors,
            Icons.visibility_outlined,
            _formatNumber(widget.post.viewCount),
            'views',
          ),

          const Spacer(),

          // Share
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              size: 20,
              color: colors.onSurfaceVariant.withOpacity(0.6),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: Share
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteSection(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upvote
          InkWell(
            onTap: _handleUpvote,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                _isUpvoted
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_upward_outlined,
                size: 18,
                color: _isUpvoted ? Colors.orange : colors.onSurfaceVariant,
              ),
            ),
          ),

          // Score
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                _formatNumber(_score),
                key: ValueKey<int>(_score),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isUpvoted
                      ? Colors.orange
                      : (_isDownvoted ? Colors.blue : colors.onSurface),
                ),
              ),
            ),
          ),

          // Downvote
          InkWell(
            onTap: _handleDownvote,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                _isDownvoted
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_downward_outlined,
                size: 18,
                color: _isDownvoted
                    ? Colors.blue
                    : colors.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ColorScheme colors,
    IconData icon,
    String value,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
