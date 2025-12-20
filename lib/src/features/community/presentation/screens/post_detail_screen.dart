import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_providers.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_item.dart';
import '../../data/mock_community_data.dart';
import '../../domain/post.dart';

/// Tela de detalhes do post com comentários
class PostDetailScreen extends ConsumerStatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isAddingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isAddingComment = true);

    try {
      final isOffline = ref.read(isOfflineModeProvider);
      if (isOffline) {
        // Em modo offline, adiciona ao mock
        MockCommunityData.addComment(
          widget.post.id,
          content,
          'mock_user_local',
          'Você',
        );
        _commentController.clear();
        _commentFocus.unfocus();
        // Invalida o provider para atualizar a lista
        ref.invalidate(commentsProvider(widget.post.id));
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comentário adicionado!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final repo = ref.read(commentRepositoryProvider);
      if (repo == null) throw Exception('Repositório não disponível');
      await repo.addComment(widget.post.id, content);

      _commentController.clear();
      _commentFocus.unfocus();

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentário adicionado!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar comentário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final commentsAsync = ref.watch(commentsProvider(widget.post.id));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Post
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PostCard(post: widget.post),
                  ),
                ),

                // Divider
                SliverToBoxAdapter(
                  child: Container(
                    height: 8,
                    color: colors.surfaceContainerHighest.withOpacity(0.3),
                  ),
                ),

                // Cabeçalho de comentários
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Comentários',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de comentários
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyComments(colors),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index >= comments.length) return null;
                          return CommentItem(comment: comments[index]);
                        }, childCount: comments.length),
                      ),
                    );
                  },
                  loading: () => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Erro ao carregar comentários',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Campo de comentário
          _buildCommentInput(colors),
        ],
      ),
    );
  }

  Widget _buildEmptyComments(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: colors.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum comentário ainda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seja o primeiro a comentar!',
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(ColorScheme colors) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocus,
                maxLines: null,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escreva um comentário...',
                  hintStyle: TextStyle(
                    color: colors.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '',
                ),
                style: TextStyle(fontSize: 14, color: colors.onSurface),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isAddingComment ? null : _addComment,
              icon: _isAddingComment
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: _commentController.text.trim().isEmpty
                          ? colors.onSurfaceVariant.withOpacity(0.3)
                          : colors.primary,
                    ),
              style: IconButton.styleFrom(
                backgroundColor: colors.surfaceContainerHighest,
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
