import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/post.dart';
import '../../domain/post_dto.dart';
import '../providers/community_providers.dart';

/// Tela de edição de post
class EditPostScreen extends ConsumerStatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late TextEditingController _contentController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final hasChanges = _contentController.text != widget.post.content;
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isLoading) return;

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O conteúdo não pode estar vazio')),
      );
      return;
    }

    if (content.length > 500) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Máximo de 500 caracteres')));
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final isOffline = ref.read(isOfflineModeProvider);

      if (isOffline) {
        // Em modo offline, usa mock
        final mockRepo = ref.read(mockCommunityRepositoryProvider);
        await mockRepo.updatePost(
          widget.post.id,
          UpdatePostDto(content: content),
        );
      } else {
        final repo = ref.read(communityRepositoryProvider);
        if (repo == null) throw Exception('Repositório não disponível');
        await repo.updatePost(widget.post.id, UpdatePostDto(content: content));
      }

      if (mounted) {
        ref.invalidate(feedProvider);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      }
    }
  }

  Future<void> _confirmDiscard() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você tem alterações não salvas. Deseja descartá-las?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final charCount = _contentController.text.length;
    final isValid = charCount > 0 && charCount <= 500;

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          await _confirmDiscard();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmDiscard,
          ),
          title: const Text('Editar Post'),
          actions: [
            TextButton(
              onPressed: _hasChanges && isValid && !_isLoading
                  ? _saveChanges
                  : null,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Text(
                      'Salvar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _hasChanges && isValid
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Post Type Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colors.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    _getPostTypeIcon(widget.post.type),
                    size: 20,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getPostTypeLabel(widget.post.type),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tipo não pode ser alterado',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: colors.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Content Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: colors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Edite seu post...',
                    hintStyle: TextStyle(color: colors.onSurfaceVariant),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  maxLength: 500,
                ),
              ),
            ),

            // Character Counter & Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Posts editados mostrarão indicador de edição',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: charCount > 500
                          ? colors.errorContainer
                          : colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$charCount/500',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: charCount > 500
                            ? colors.onErrorContainer
                            : colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPostTypeIcon(PostType type) {
    switch (type) {
      case PostType.text:
        return Icons.article_rounded;
      case PostType.mood:
        return Icons.mood_rounded;
      case PostType.achievement:
        return Icons.emoji_events_rounded;
      case PostType.insight:
        return Icons.lightbulb_rounded;
      case PostType.image:
      case PostType.gallery:
        return Icons.image_rounded;
    }
  }

  String _getPostTypeLabel(PostType type) {
    switch (type) {
      case PostType.text:
        return 'Texto';
      case PostType.mood:
        return 'Humor';
      case PostType.achievement:
        return 'Conquista';
      case PostType.insight:
        return 'Insight';
      case PostType.image:
        return 'Imagem';
      case PostType.gallery:
        return 'Galeria';
    }
  }
}
