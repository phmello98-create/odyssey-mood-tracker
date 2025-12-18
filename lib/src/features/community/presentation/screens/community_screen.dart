import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/topic.dart';

import '../../domain/notification.dart';
import '../providers/community_providers.dart';
import '../providers/notifications_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/community_search_bar.dart';
import '../widgets/curated_section.dart';
import '../widgets/community_info_bar.dart';
import '../widgets/quick_links_widget.dart';
import '../widgets/radio_popup_player.dart';
import '../widgets/trending_section.dart';
import '../widgets/top_users_widget.dart';
import '../providers/radio_provider.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';

/// Tela principal da comunidade - Estilo Reddit Minimalista
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showRadioPopup = false;
  bool _showNotificationsPanel = false;
  final GlobalKey _radioButtonKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(feedProvider);
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final feedAsync = ref.watch(feedProvider);
    final selectedTopic = ref.watch(selectedTopicProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar minimalista (Polida)
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: colors.surface,
                  surfaceTintColor: colors.surface,
                  elevation: 0,
                  centerTitle: false,
                  title: Row(
                    children: [
                      Icon(
                        Icons.forum_rounded,
                        color: colors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comunidade',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Radio Button (Disco Player with Popup)
                    Consumer(
                      builder: (context, ref, child) {
                        final radioState = ref.watch(radioProvider);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              key: _radioButtonKey,
                              icon: Icon(
                                radioState.isPlaying
                                    ? Icons.album_rounded
                                    : Icons.album_outlined,
                                color: radioState.isPlaying
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _showRadioPopup = !_showRadioPopup;
                                });
                              },
                              tooltip: 'Rádio Odyssey',
                            ),
                            // Music playing indicator
                            if (radioState.isPlaying && !_showRadioPopup)
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: _MusicIndicator(),
                              ),
                          ],
                        );
                      },
                    ),
                    // Notifications Button with badge
                    Consumer(
                      builder: (context, ref, child) {
                        final notifState = ref.watch(notificationsProvider);
                        final unreadCount = notifState.unreadCount;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: Icon(
                                _showNotificationsPanel
                                    ? Icons.notifications_rounded
                                    : (unreadCount > 0
                                          ? Icons.notifications_active_rounded
                                          : Icons.notifications_outlined),
                                color: _showNotificationsPanel
                                    ? const Color(0xFF9C27B0)
                                    : (unreadCount > 0
                                          ? const Color(0xFF9C27B0)
                                          : colors.onSurfaceVariant),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _showNotificationsPanel =
                                      !_showNotificationsPanel;
                                });
                              },
                              tooltip: 'Notificações',
                            ),
                            // Unread badge
                            if (unreadCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF9C27B0),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // Persistent Search Bar
                SliverToBoxAdapter(
                  child: CommunitySearchBar(onTap: _navigateToSearch),
                ),

                // Expandable Notifications Panel
                SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showNotificationsPanel
                        ? _buildNotificationsPanel(colors)
                        : const SizedBox.shrink(),
                  ),
                ),

                // Community Info Bar (Stats)
                const SliverToBoxAdapter(child: CommunityInfoBar()),

                // Curated Section (ModOdyssey)
                const SliverToBoxAdapter(child: CuratedSection()),

                // Trending Section (Hot posts + tags)
                const SliverToBoxAdapter(child: TrendingSection()),

                // Top Users / Leaderboard mini
                const SliverToBoxAdapter(child: TopUsersWidget()),

                // Quick Links / Indexes
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: QuickLinksWidget(),
                  ),
                ),

                // Topic filter chips (horizontal scroll)
                SliverToBoxAdapter(
                  child: Container(
                    height: 56, // Slightly taller for better touch targets
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: colors.outlineVariant.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: CommunityTopic.values.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "Todos" chip
                          final isSelected = selectedTopic == null;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              showCheckmark: false,
                              label: const Text('Todos'),
                              selected: isSelected,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                ref.read(selectedTopicProvider.notifier).state =
                                    null;
                              },
                              backgroundColor: colors.surfaceContainerHighest
                                  .withOpacity(0.5),
                              selectedColor: colors.primary.withOpacity(1.0),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colors.onPrimary
                                    : colors.onSurfaceVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : colors.outline.withOpacity(0.1),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }

                        final topic = CommunityTopic.values[index - 1];
                        final isSelected = selectedTopic == topic;
                        final topicColor = Color(topic.colorValue);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            showCheckmark: false,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(topic.emoji),
                                const SizedBox(width: 6),
                                Text(topic.label),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              ref.read(selectedTopicProvider.notifier).state =
                                  isSelected ? null : topic;
                            },
                            backgroundColor: colors.surfaceContainerHighest
                                .withOpacity(0.5),
                            selectedColor: topicColor,
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors
                                        .white // Assuming dark topic colors for contrast, or check luminance
                                  : colors.onSurfaceVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : colors.outline.withOpacity(0.1),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Feed de Posts
                feedAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(colors),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index >= posts.length) return null;
                        return PostCard(post: posts[index]);
                      }, childCount: posts.length),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    child: _buildErrorState(colors, error.toString()),
                  ),
                ),

                // Espaço no final para player + FAB
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // Radio Popup Overlay
          if (_showRadioPopup)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showRadioPopup = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Stack(
                  children: [
                    Positioned(
                      top: 60,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {}, // Prevent dismissal when tapping popup
                        child: RadioPopupPlayer(
                          onClose: () {
                            setState(() {
                              _showRadioPopup = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // FAB para criar post
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        backgroundColor: colors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum post ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seja o primeiro a compartilhar algo!',
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToCreatePost,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colors, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar feed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsPanel(ColorScheme colors) {
    final notifState = ref.watch(notificationsProvider);
    final notifications = notifState.notifications.take(5).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  size: 18,
                  color: Color(0xFF9C27B0),
                ),
                const SizedBox(width: 8),
                Text(
                  'Notificações',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                if (notifState.unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier).markAllAsRead();
                      HapticFeedback.lightImpact();
                    },
                    child: const Text(
                      'Marcar lidas',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showNotificationsPanel = false;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          // Content
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 40,
                    color: colors.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma notificação',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: notifications
                    .map(
                      (notif) => InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(notif.id);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? null
                                : colors.primaryContainer.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(
                                    notif.colorValue,
                                  ).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getNotifIcon(notif.type),
                                  size: 16,
                                  color: Color(notif.colorValue),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: notif.isRead
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        color: colors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      notif.message,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colors.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (!notif.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNotifIcon(CommunityNotificationType type) {
    switch (type) {
      case CommunityNotificationType.newFollower:
        return Icons.person_add_rounded;
      case CommunityNotificationType.postUpvote:
        return Icons.arrow_upward_rounded;
      case CommunityNotificationType.postComment:
        return Icons.chat_bubble_rounded;
      case CommunityNotificationType.commentReply:
        return Icons.reply_rounded;
      case CommunityNotificationType.mention:
        return Icons.alternate_email_rounded;
      case CommunityNotificationType.achievement:
        return Icons.emoji_events_rounded;
      case CommunityNotificationType.milestone:
        return Icons.celebration_rounded;
      case CommunityNotificationType.announcement:
        return Icons.campaign_rounded;
      case CommunityNotificationType.trending:
        return Icons.local_fire_department_rounded;
    }
  }
}

// Music Playing Indicator Animation
class _MusicIndicator extends StatefulWidget {
  @override
  State<_MusicIndicator> createState() => _MusicIndicatorState();
}

class _MusicIndicatorState extends State<_MusicIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.music_note_rounded, color: Colors.white, size: 8),
        );
      },
    );
  }
}
