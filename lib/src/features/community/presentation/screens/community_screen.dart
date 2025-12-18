import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/topic.dart';
import '../providers/community_providers.dart';
import '../widgets/post_card.dart';
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar minimalista
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: colors.surface,
              elevation: 0,
              title: Text(
                'Comunidade',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              actions: [
                // Search button
                IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                  onPressed: _navigateToSearch,
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Topic filter chips (horizontal scroll)
            SliverToBoxAdapter(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.outlineVariant.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: CommunityTopic.values.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "Todos" chip
                      final isSelected = selectedTopic == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Todos'),
                          selected: isSelected,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            ref.read(selectedTopicProvider.notifier).state =
                                null;
                          },
                          backgroundColor: colors.surfaceContainerHighest,
                          selectedColor: colors.primary.withOpacity(0.15),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      );
                    }

                    final topic = CommunityTopic.values[index - 1];
                    final isSelected = selectedTopic == topic;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(topic.emoji),
                            const SizedBox(width: 4),
                            Text(topic.label),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          ref.read(selectedTopicProvider.notifier).state =
                              isSelected ? null : topic;
                        },
                        backgroundColor: colors.surfaceContainerHighest,
                        selectedColor: Color(
                          topic.colorValue,
                        ).withOpacity(0.15),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Color(topic.colorValue)
                              : colors.onSurfaceVariant,
                        ),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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

            // Espaço no final
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
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
}
