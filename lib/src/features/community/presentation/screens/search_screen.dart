import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/user_profile.dart';
import '../../data/mock_community_data.dart';
import '../providers/community_providers.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';
import 'public_profile_screen.dart';

/// Pesquisa unificada para o estado de busca
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Tipo de pesquisa ativo
enum SearchType { posts, users }

final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.posts);

/// Histórico de pesquisas recentes (mock)
final recentSearchesProvider = StateProvider<List<String>>(
  (ref) => ['meditação', 'pomodoro', 'hábitos', 'produtividade'],
);

/// Tela de busca de posts e usuários
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Auto focus no campo de busca
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final type = _tabController.index == 0
          ? SearchType.posts
          : SearchType.users;
      ref.read(searchTypeProvider.notifier).state = type;
    }
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focusNode.requestFocus();
  }

  void _onSearchSubmit(String query) {
    if (query.isNotEmpty) {
      // Adicionar ao histórico
      final recents = ref.read(recentSearchesProvider);
      if (!recents.contains(query.toLowerCase())) {
        ref.read(recentSearchesProvider.notifier).state = [
          query.toLowerCase(),
          ...recents.take(9),
        ];
      }
    }
  }

  void _searchFor(String query) {
    _searchController.text = query;
    ref.read(searchQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmit,
          style: TextStyle(fontSize: 16, color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Buscar na comunidade...',
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _clearSearch,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Usuários'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostSearchResults(query: query, onSearchFor: _searchFor),
          _UserSearchResults(query: query, onSearchFor: _searchFor),
        ],
      ),
    );
  }
}

/// Resultados da busca de posts
class _PostSearchResults extends ConsumerWidget {
  final String query;
  final Function(String) onSearchFor;

  const _PostSearchResults({required this.query, required this.onSearchFor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    if (query.isEmpty) {
      return _buildDiscoveryState(context, ref, colors);
    }

    final searchResultsAsync = ref.watch(searchPostsProvider(query));

    return searchResultsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _buildNoResultsState(colors, query);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PostCard(post: posts[index]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Erro na busca',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryState(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
  ) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final trendingTags = MockCommunityData.getTrendingTags(limit: 6);
    final trendingPosts = MockCommunityData.getTrendingPosts(limit: 3);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pesquisas recentes
          if (recentSearches.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pesquisas recentes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(recentSearchesProvider.notifier).state = [];
                  },
                  child: Text(
                    'Limpar',
                    style: TextStyle(fontSize: 12, color: colors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches
                  .map(
                    (search) => ActionChip(
                      avatar: Icon(
                        Icons.north_west_rounded,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      label: Text(search),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onSearchFor(search);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Tags em alta
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Tags em alta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendingTags
                .map(
                  (tag) => ActionChip(
                    avatar: Text(
                      '#',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    label: Text(tag),
                    backgroundColor: colors.primaryContainer.withOpacity(0.3),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onSearchFor(tag);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          // Posts populares
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Posts populares',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...trendingPosts.map((post) => _PostPreviewCard(post: post)),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ColorScheme colors, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhum post encontrado para "$query"',
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Card de preview de post compacto
class _PostPreviewCard extends StatelessWidget {
  final dynamic post;

  const _PostPreviewCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // TODO: Navigate to post detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundImage: post.userPhotoUrl != null
                    ? NetworkImage(post.userPhotoUrl!)
                    : null,
                child: post.userPhotoUrl == null
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.content,
                      style: TextStyle(fontSize: 14, color: colors.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stats
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Resultados da busca de usuários
class _UserSearchResults extends ConsumerWidget {
  final String query;
  final Function(String) onSearchFor;

  const _UserSearchResults({required this.query, required this.onSearchFor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    if (query.isEmpty) {
      return _buildDiscoveryState(context, ref, colors);
    }

    final searchResultsAsync = ref.watch(searchUsersProvider(query));

    return searchResultsAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return _buildNoResultsState(colors, query);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _UserSearchItem(user: users[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Erro na busca',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryState(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dica
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Digite o nome de um usuário para encontrar seu perfil',
                    style: TextStyle(fontSize: 13, color: colors.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ColorScheme colors, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_rounded,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhum usuário encontrado para "$query"',
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Card de preview de usuário compacto
class _UserPreviewCard extends StatelessWidget {
  final dynamic user;

  const _UserPreviewCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PublicProfileScreen(userId: user.id, userName: user.username),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar com borda de nível
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: _getLevelColors(user.level)),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.surface,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.username,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (user.flair != null)
                          Text(
                            user.flair!,
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Nível ${user.level}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user.karma} karma',
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
              // Arrow
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getLevelColors(int level) {
    if (level >= 50) return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
    if (level >= 30) return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
    if (level >= 10) return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
    return [const Color(0xFF6B4EFF), const Color(0xFF9C27B0)];
  }
}

/// Item de usuário nos resultados da busca
class _UserSearchItem extends ConsumerWidget {
  final PublicUserProfile user;

  const _UserSearchItem({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnProfile = currentUserId == user.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(
                userId: user.userId,
                userName: user.displayName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              UserAvatar(photoUrl: user.photoUrl, level: user.level, size: 48),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (user.privacySettings.showLevel) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nível ${user.level}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (user.bio != null && user.bio!.isNotEmpty)
                          Expanded(
                            child: Text(
                              user.bio!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Follow Button (se não for o próprio perfil)
              if (!isOwnProfile) _FollowButton(userId: user.userId),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão de seguir para usuários nos resultados da busca
class _FollowButton extends ConsumerWidget {
  final String userId;

  const _FollowButton({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isFollowingAsync = ref.watch(isFollowingProvider(userId));

    return isFollowingAsync.when(
      data: (isFollowing) {
        return isFollowing
            ? OutlinedButton(
                onPressed: () => _handleUnfollow(ref, context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  side: BorderSide(color: colors.outline),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Seguindo', style: TextStyle(fontSize: 12)),
              )
            : ElevatedButton(
                onPressed: () => _handleFollow(ref, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Seguir', style: TextStyle(fontSize: 12)),
              );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleFollow(WidgetRef ref, BuildContext context) async {
    HapticFeedback.lightImpact();
    try {
      final isOffline = ref.read(isOfflineModeProvider);
      if (isOffline) {
        // Em modo offline, apenas simula
        ref.invalidate(isFollowingProvider(userId));
        return;
      }
      final followRepo = ref.read(followRepositoryProvider);
      if (followRepo == null) return;
      await followRepo.followUser(userId);
      ref.invalidate(isFollowingProvider(userId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao seguir: $e')));
      }
    }
  }

  Future<void> _handleUnfollow(WidgetRef ref, BuildContext context) async {
    HapticFeedback.lightImpact();
    try {
      final isOffline = ref.read(isOfflineModeProvider);
      if (isOffline) {
        // Em modo offline, apenas simula
        ref.invalidate(isFollowingProvider(userId));
        return;
      }
      final followRepo = ref.read(followRepositoryProvider);
      if (followRepo == null) return;
      await followRepo.unfollowUser(userId);
      ref.invalidate(isFollowingProvider(userId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao deixar de seguir: $e')));
      }
    }
  }
}
