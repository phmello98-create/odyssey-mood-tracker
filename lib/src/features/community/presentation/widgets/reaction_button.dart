import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_providers.dart';

/// Widget de reações em posts
class ReactionButton extends ConsumerStatefulWidget {
  final String postId;
  final Map<String, int> reactions;

  const ReactionButton({
    super.key,
    required this.postId,
    required this.reactions,
  });

  @override
  ConsumerState<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends ConsumerState<ReactionButton> {
  bool _isReacting = false;
  bool _hasReacted = false;

  int get totalReactions {
    return widget.reactions.values.fold(0, (sum, count) => sum + count);
  }

  Future<void> _toggleReaction() async {
    if (_isReacting) return;

    setState(() => _isReacting = true);
    HapticFeedback.lightImpact();

    try {
      final isOffline = ref.read(isOfflineModeProvider);

      if (isOffline) {
        // Em modo offline, apenas simula localmente
        setState(() => _hasReacted = !_hasReacted);
      } else {
        final repo = ref.read(communityRepositoryProvider);
        if (repo == null) {
          // Fallback para modo offline
          setState(() => _hasReacted = !_hasReacted);
          return;
        }

        if (_hasReacted) {
          await repo.removeReaction(widget.postId);
          setState(() => _hasReacted = false);
        } else {
          await repo.addReaction(widget.postId, '❤️');
          setState(() => _hasReacted = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReacting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasReactions = totalReactions > 0 || _hasReacted;

    return InkWell(
      onTap: _toggleReaction,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                key: ValueKey(_hasReacted || hasReactions),
                _hasReacted || hasReactions
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 20,
                color: _hasReacted || hasReactions
                    ? Colors.red
                    : colors.onSurfaceVariant,
              ),
            ),
            if (hasReactions || _hasReacted) ...[
              const SizedBox(width: 6),
              Text(
                '${totalReactions + (_hasReacted ? 1 : 0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
