import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/user_profile.dart';
import '../../domain/follow.dart';
import '../providers/community_providers.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';

/// Tela de perfil público de um usuário
class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const PublicProfileScreen({super.key, required this.userId, this.userName});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(userProfileProvider(widget.userId));
    final followStatsAsync = ref.watch(followStatsProvider(widget.userId));
    final isFollowingAsync = ref.watch(isFollowingProvider(widget.userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final userPostsAsync = ref.watch(userPostsProvider(widget.userId));
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileAsync.when(
        data: (profile) => _buildProfileContent(
          context,
          colors,
          profile,
          followStatsAsync,
          isFollowingAsync,
          isOwnProfile,
          userPostsAsync,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    ColorScheme colors,
    PublicUserProfile profile,
    AsyncValue<FollowStats> followStatsAsync,
    AsyncValue<bool> isFollowingAsync,
    bool isOwnProfile,
    AsyncValue<dynamic> userPostsAsync,
  ) {
    return CustomScrollView(
      slivers: [
        // Header com gradiente
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: colors.surface,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withOpacity(0.8),
                    colors.secondary.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Profile Info
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                // Avatar
                UserAvatar(
                  photoUrl: profile.photoUrl,
                  level: profile.level,
                  size: 80,
                ),
                const SizedBox(height: 12),

                // Nome
                Text(
                  profile.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),

                // Level Badge
                if (profile.privacySettings.showLevel)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Nível ${profile.level} • ${profile.totalXP} XP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ),

                // Bio
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      profile.bio!,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: followStatsAsync.when(
                    data: (stats) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(
                          colors,
                          '${stats.followersCount}',
                          'Seguidores',
                        ),
                        _buildStat(
                          colors,
                          '${stats.followingCount}',
                          'Seguindo',
                        ),
                        _buildStat(
                          colors,
                          timeago.format(profile.createdAt, locale: 'pt_BR'),
                          'Membro',
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Erro'),
                  ),
                ),

                // Follow Button
                if (!isOwnProfile)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: isFollowingAsync.when(
                      data: (isFollowing) => SizedBox(
                        width: double.infinity,
                        child: isFollowing
                            ? OutlinedButton(
                                onPressed: () => _handleUnfollow(),
                                child: const Text('Seguindo'),
                              )
                            : ElevatedButton(
                                onPressed: () => _handleFollow(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Seguir'),
                              ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                const SizedBox(height: 16),

                // Badges
                if (profile.badges.isNotEmpty &&
                    profile.privacySettings.showBadges)
                  _buildBadgesSection(colors, profile),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.onSurfaceVariant,
                  indicatorColor: colors.primary,
                  tabs: const [
                    Tab(
                      text: 'Posts',
                      icon: Icon(Icons.article_rounded, size: 20),
                    ),
                    Tab(
                      text: 'Conquistas',
                      icon: Icon(Icons.emoji_events_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Tab Content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Posts
              userPostsAsync.when(
                data: (posts) {
                  if ((posts as List).isEmpty) {
                    return _buildEmptyState(
                      colors,
                      'Nenhum post ainda',
                      Icons.article_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(
                        post: posts[index],
                        showUserAvatar: false,
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
              ),

              // Achievements
              _buildAchievementsTab(colors, profile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(ColorScheme colors, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(ColorScheme colors, PublicUserProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: profile.badges
            .map(
              (badge) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colors.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(ColorScheme colors, PublicUserProfile profile) {
    if (profile.badges.isEmpty) {
      return _buildEmptyState(
        colors,
        'Nenhuma conquista',
        Icons.emoji_events_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: profile.badges.length,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 36,
              color: colors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              profile.badges[index],
              style: TextStyle(fontSize: 11, color: colors.onSurface),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFollow() async {
    HapticFeedback.lightImpact();
    try {
      final repo = ref.read(followRepositoryProvider);
      await repo.followUser(widget.userId);
      ref.invalidate(isFollowingProvider(widget.userId));
      ref.invalidate(followStatsProvider(widget.userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _handleUnfollow() async {
    HapticFeedback.lightImpact();
    try {
      final repo = ref.read(followRepositoryProvider);
      await repo.unfollowUser(widget.userId);
      ref.invalidate(isFollowingProvider(widget.userId));
      ref.invalidate(followStatsProvider(widget.userId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}
