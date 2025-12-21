import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_community_data.dart';
import '../providers/community_providers.dart';

/// Provider para query de busca inline
final inlineSearchQueryProvider = StateProvider<String>((ref) => '');

/// Pesquisas recentes
final recentSearchesProvider = StateProvider<List<String>>(
  (ref) => ['meditação', 'pomodoro', 'hábitos', 'produtividade'],
);

/// Search bar expansível com painel de descoberta inline
class ExpandableSearchWidget extends ConsumerStatefulWidget {
  const ExpandableSearchWidget({super.key});

  @override
  ConsumerState<ExpandableSearchWidget> createState() =>
      _ExpandableSearchWidgetState();
}

class _ExpandableSearchWidgetState
    extends ConsumerState<ExpandableSearchWidget> {
  bool _isExpanded = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  void _closePanel() {
    setState(() {
      _isExpanded = false;
      _focusNode.unfocus();
    });
  }

  void _onSearchChanged(String value) {
    ref.read(inlineSearchQueryProvider.notifier).state = value;
  }

  void _searchFor(String term) {
    _controller.text = term;
    ref.read(inlineSearchQueryProvider.notifier).state = term;
    // Adicionar ao histórico
    final recents = ref.read(recentSearchesProvider);
    if (!recents.contains(term.toLowerCase())) {
      ref.read(recentSearchesProvider.notifier).state = [
        term.toLowerCase(),
        ...recents.take(7),
      ];
    }
  }

  void _applyTagFilter(String tag) {
    ref.read(selectedTagProvider.notifier).state = tag;
    _closePanel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtrando posts por #$tag'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = ref.watch(inlineSearchQueryProvider);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isExpanded
                    ? colors.primary.withOpacity(0.5)
                    : colors.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search_rounded,
                  color: _isExpanded ? colors.primary : colors.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    onTap: () {
                      if (!_isExpanded) {
                        setState(() => _isExpanded = true);
                      }
                    },
                    style: TextStyle(fontSize: 14, color: colors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Buscar tópicos, pessoas, artigos...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _controller.clear();
                      ref.read(inlineSearchQueryProvider.notifier).state = '';
                    },
                  ),
                if (_isExpanded)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: _closePanel,
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),

        // Expandable Panel
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? _buildSearchPanel(colors, query)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSearchPanel(ColorScheme colors, String query) {
    if (query.isNotEmpty) {
      return _buildSearchResults(colors, query);
    }
    return _buildDiscoveryPanel(colors);
  }

  Widget _buildDiscoveryPanel(ColorScheme colors) {
    final recentSearches = ref.watch(recentSearchesProvider);
    final trendingTags = MockCommunityData.getTrendingTags(limit: 8);
    final trendingPosts = MockCommunityData.getTrendingPosts(limit: 4);

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: SingleChildScrollView(
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
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Recentes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(recentSearchesProvider.notifier).state = [];
                    },
                    child: Text(
                      'Limpar',
                      style: TextStyle(fontSize: 11, color: colors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: recentSearches
                    .take(4)
                    .map(
                      (search) => InkWell(
                        onTap: () => _searchFor(search),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.north_west_rounded,
                                size: 12,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                search,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Tags em alta
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tags em alta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: trendingTags
                  .map(
                    (tag) => InkWell(
                      onTap: () => _applyTagFilter(tag),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
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
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Posts populares
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Posts populares',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...trendingPosts.map((post) => _MiniPostPreview(post: post)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme colors, String query) {
    final searchResultsAsync = ref.watch(searchPostsProvider(query));

    return Container(
      constraints: const BoxConstraints(maxHeight: 350),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: searchResultsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: colors.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum resultado para "$query"',
                    style: TextStyle(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(12),
            itemCount: posts.length.clamp(0, 5),
            itemBuilder: (context, index) =>
                _MiniPostPreview(post: posts[index]),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Erro na busca', style: TextStyle(color: colors.error)),
        ),
      ),
    );
  }
}

class _MiniPostPreview extends StatelessWidget {
  final dynamic post;

  const _MiniPostPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to post detail
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: post.userPhotoUrl != null
                  ? NetworkImage(post.userPhotoUrl!)
                  : null,
              child: post.userPhotoUrl == null
                  ? const Icon(Icons.person, size: 12)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.userName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    post.content,
                    style: TextStyle(fontSize: 13, color: colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 12,
                  color: colors.primary,
                ),
                Text(
                  '${post.score}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
