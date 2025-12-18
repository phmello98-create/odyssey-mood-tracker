import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/user_profile.dart';
import '../providers/community_providers.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';
import 'public_profile_screen.dart';

/// Pesquisa unificada para o estado de busca
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Tipo de pesquisa ativo
enum SearchType { posts, users }

final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.posts);

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
          _PostSearchResults(query: query),
          _UserSearchResults(query: query),
        ],
      ),
    );
  }
}

/// Resultados da busca de posts
class _PostSearchResults extends ConsumerWidget {
  final String query;

  const _PostSearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    if (query.isEmpty) {
      return _buildEmptySearchState(colors);
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

  Widget _buildEmptySearchState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Buscar posts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Digite para buscar posts na comunidade',
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
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

/// Resultados da busca de usuários
class _UserSearchResults extends ConsumerWidget {
  final String query;

  const _UserSearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    if (query.isEmpty) {
      return _buildEmptySearchState(colors);
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

  Widget _buildEmptySearchState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 64,
            color: colors.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Buscar usuários',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Digite para buscar usuários na comunidade',
            style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
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
      final followRepo = ref.read(followRepositoryProvider);
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
      final followRepo = ref.read(followRepositoryProvider);
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
