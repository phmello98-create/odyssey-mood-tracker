import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/comment.dart';
import 'user_avatar.dart';

/// Widget para exibir um comentário
class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        comment.isReply ? 56 : 16,
        8,
        16,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (menor se for reply)
          UserAvatar(
            photoUrl: comment.userPhotoUrl,
            level: 1, // Comentários não mostram nível
            size: comment.isReply ? 28 : 32,
          ),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(comment.createdAt, locale: 'pt_BR'),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Conteúdo do comentário
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colors.onSurface.withOpacity(0.9),
                  ),
                ),

                // Ações
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Botão de responder
                    if (!comment.isReply && onReply != null)
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReply?.call();
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Responder',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),

                    // Botão de deletar (se aplicável)
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _showDeleteDialog(context);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Excluir',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Excluir comentário?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        content: Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: Text('Excluir', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}
