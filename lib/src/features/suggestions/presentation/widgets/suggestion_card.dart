import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion_enums.dart';
import 'package:odyssey/src/features/suggestions/data/suggestion_analytics_repository.dart';

class SuggestionCard extends ConsumerStatefulWidget {
  final Suggestion suggestion;
  final VoidCallback onAdd;
  final bool isAdded;
  final bool isMarked;
  final VoidCallback? onFavoriteToggle;

  const SuggestionCard({
    Key? key,
    required this.suggestion,
    required this.onAdd,
    this.isAdded = false,
    this.isMarked = false,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  ConsumerState<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<SuggestionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getDifficultyLabel() {
    switch (widget.suggestion.difficulty) {
      case SuggestionDifficulty.easy:
        return 'Fácil';
      case SuggestionDifficulty.medium:
        return 'Médio';
      case SuggestionDifficulty.hard:
        return 'Difícil';
    }
  }

  Color _getDifficultyColor() {
    switch (widget.suggestion.difficulty) {
      case SuggestionDifficulty.easy:
        return const Color(0xFF10B981);
      case SuggestionDifficulty.medium:
        return const Color(0xFFF59E0B);
      case SuggestionDifficulty.hard:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.suggestion.category) {
      case SuggestionCategory.selfKnowledge:
        return Icons.psychology;
      case SuggestionCategory.presence:
        return Icons.self_improvement;
      case SuggestionCategory.relations:
        return Icons.people;
      case SuggestionCategory.creation:
        return Icons.palette;
      case SuggestionCategory.reflection:
        return Icons.lightbulb_outline;
      case SuggestionCategory.selfActualization:
        return Icons.trending_up;
      case SuggestionCategory.consciousness:
        return Icons.visibility;
      case SuggestionCategory.emptiness:
        return Icons.blur_on;
    }
  }

  Future<void> _toggleFavorite() async {
    final analyticsRepo = ref.read(suggestionAnalyticsRepositoryProvider);
    await analyticsRepo.toggleFavorite(widget.suggestion.id);
    
    // Notificar parent para recarregar
    widget.onFavoriteToggle?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isMarked ? 'Removido dos favoritos' : 'Adicionado aos favoritos'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isAdded 
                ? Color(widget.suggestion.colorValue).withValues(alpha: 0.5)
                : borderColor,
            width: widget.isAdded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de tipo no topo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.suggestion.type == SuggestionType.habit
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                    : const Color(0xFF06B6D4).withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.suggestion.type == SuggestionType.habit
                        ? Icons.repeat_rounded
                        : Icons.task_alt,
                    size: 14,
                    color: widget.suggestion.type == SuggestionType.habit
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF06B6D4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.suggestion.type == SuggestionType.habit ? 'HÁBITO' : 'TAREFA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: widget.suggestion.type == SuggestionType.habit
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
            ),
            
            // Header com ícone, título e estrela
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícone colorido
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(widget.suggestion.colorValue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.suggestion.type == SuggestionType.habit
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                            : const Color(0xFF06B6D4).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.suggestion.icon,
                      color: Color(widget.suggestion.colorValue),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Título
                  Expanded(
                    child: Text(
                      widget.suggestion.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Botão de favorito (estrela)
                  IconButton(
                    icon: Icon(
                      widget.isMarked ? Icons.star : Icons.star_border,
                      color: widget.isMarked ? const Color(0xFFF59E0B) : Colors.grey,
                    ),
                    onPressed: _toggleFavorite,
                    tooltip: widget.isMarked ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                  ),
                ],
              ),
            ),
            
            // Descrição
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.suggestion.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tags e metadados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Dificuldade
                  _buildTag(
                    icon: Icons.trending_up,
                    label: _getDifficultyLabel(),
                    color: _getDifficultyColor(),
                  ),
                  
                  // Nível mínimo
                  _buildTag(
                    icon: Icons.emoji_events,
                    label: 'Nível ${widget.suggestion.minLevel}',
                    color: const Color(0xFF6366F1),
                  ),
                  
                  // Horário sugerido (se houver)
                  if (widget.suggestion.scheduledTime != null)
                    _buildTag(
                      icon: Icons.schedule,
                      label: widget.suggestion.scheduledTime!,
                      color: const Color(0xFF06B6D4),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botão de ação
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: widget.isAdded ? null : widget.onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isAdded
                        ? Colors.grey
                        : Color(widget.suggestion.colorValue),
                    foregroundColor: Colors.white,
                    elevation: widget.isAdded ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isAdded ? Icons.check_circle : Icons.add_circle_outline,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isAdded 
                            ? (widget.suggestion.type == SuggestionType.habit 
                                ? 'Já adicionado aos hábitos'
                                : 'Já adicionado às tarefas')
                            : (widget.suggestion.type == SuggestionType.habit
                                ? 'Adicionar aos Hábitos'
                                : 'Adicionar às Tarefas'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
