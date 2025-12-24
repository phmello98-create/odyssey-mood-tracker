import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion.dart';
import 'package:odyssey/src/features/suggestions/domain/suggestion_enums.dart';
import 'package:odyssey/src/features/suggestions/data/suggestion_repository.dart';
import 'package:odyssey/src/features/suggestions/data/suggestion_analytics_repository.dart';
import 'package:odyssey/src/features/suggestions/presentation/suggestions_screen.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/gamification/data/synced_gamification_repository.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';

/// Widget de sugestões inteligentes para a Home
/// Mostra cards horizontais com sugestões personalizadas baseadas no perfil do usuário
class HomeSuggestionsWidget extends ConsumerStatefulWidget {
  const HomeSuggestionsWidget({super.key});

  @override
  ConsumerState<HomeSuggestionsWidget> createState() =>
      _HomeSuggestionsWidgetState();
}

class _HomeSuggestionsWidgetState extends ConsumerState<HomeSuggestionsWidget>
    with SingleTickerProviderStateMixin {
  List<Suggestion> _suggestions = [];
  Set<String> _addedIds = {};
  bool _isLoading = true;
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadSuggestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final suggestionRepo = ref.read(suggestionRepositoryProvider);
      final analyticsRepo = ref.read(suggestionAnalyticsRepositoryProvider);

      await analyticsRepo.init();

      final recommended = await suggestionRepo.getRecommendedSuggestions();
      final addedIds = await analyticsRepo.getAddedSuggestionIds();

      // Pega as 6 melhores sugestões não adicionadas
      final filtered = recommended
          .where((s) => !addedIds.contains(s.id))
          .take(6)
          .toList();

      if (mounted) {
        setState(() {
          _suggestions = filtered;
          _addedIds = addedIds.toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSuggestion(Suggestion suggestion) async {
    HapticFeedback.mediumImpact();

    try {
      if (suggestion.type == SuggestionType.habit) {
        await _addHabit(suggestion);
      } else {
        await _addTask(suggestion);
      }

      // Marcar como adicionada
      final analyticsRepo = ref.read(suggestionAnalyticsRepositoryProvider);
      await analyticsRepo.markAsAdded(suggestion.id);

      // Dar XP
      final gamificationRepo = ref.read(syncedGamificationRepositoryProvider);
      await gamificationRepo.addXP(10);

      // Verificar badges
      final totalAccepted = await analyticsRepo.getTotalAddedCount();
      final newBadges = await gamificationRepo.checkSuggestionBadges(
        totalAccepted,
      );

      // Atualizar UI
      setState(() {
        _addedIds.add(suggestion.id);
      });

      // Recarregar após delay para animação
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadSuggestions();

      // Mostrar feedback
      if (mounted) {
        String message = suggestion.type == SuggestionType.habit
            ? '✓ Hábito adicionado! +10 XP'
            : '✓ Tarefa adicionada! +10 XP';

        if (newBadges.isNotEmpty) {
          message += '\n🎉 Badge: ${newBadges.first.name}!';
        }

        FeedbackService.showSuccess(context, message);
      }
    } catch (e) {
      debugPrint('Error adding suggestion: $e');
      if (mounted) {
        FeedbackService.showError(context, 'Erro ao adicionar');
      }
    }
  }

  Future<void> _addHabit(Suggestion suggestion) async {
    final habitRepo = ref.read(habitRepositoryProvider);
    await habitRepo.init();

    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: suggestion.title,
      iconCode: suggestion.icon.codePoint,
      colorValue: suggestion.colorValue,
      scheduledTime: suggestion.scheduledTime,
      daysOfWeek: suggestion.suggestedDays ?? [],
      createdAt: DateTime.now(),
      completedDates: [],
      currentStreak: 0,
      bestStreak: 0,
      order: habitRepo.getAllHabits().length,
    );

    await habitRepo.addHabit(habit);
  }

  Future<void> _addTask(Suggestion suggestion) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.init();

    final taskData = TaskData(
      key: DateTime.now().millisecondsSinceEpoch.toString(),
      title: suggestion.title,
      notes: suggestion.description,
      completed: false,
      priority: suggestion.difficulty == SuggestionDifficulty.easy
          ? 'low'
          : suggestion.difficulty == SuggestionDifficulty.medium
          ? 'medium'
          : 'high',
      category: 'personal',
      createdAt: DateTime.now(),
    );

    await taskRepo.addTask(taskData);
  }

  void _dismissSuggestion(Suggestion suggestion) {
    HapticFeedback.lightImpact();
    setState(() {
      _suggestions.removeWhere((s) => s.id == suggestion.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return _buildLoadingState(colors);
    }

    if (_suggestions.isEmpty) {
      return _buildEmptyState(colors);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.2),
                      colors.tertiary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sugestões para Você',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Baseado no seu perfil e humor',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuggestionsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: colors.onPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Carousel de Cards
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentPage = index);
            },
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              final isAdded = _addedIds.contains(suggestion.id);

              return AnimatedBuilder(
                listenable: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.15)).clamp(0.85, 1.0);
                  }

                  return Transform.scale(
                    scale: value,
                    child: _buildSuggestionCard(suggestion, isAdded, colors),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Indicadores de página
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_suggestions.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? colors.primary
                    : colors.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(
    Suggestion suggestion,
    bool isAdded,
    ColorScheme colors,
  ) {
    final cardColor = Color(suggestion.colorValue);
    final isHabit = suggestion.type == SuggestionType.habit;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SuggestionsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardColor.withOpacity(0.15), colors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com tipo e dificuldade
                  Row(
                    children: [
                      // Badge de tipo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isHabit
                              ? const Color(0xFF8B5CF6).withOpacity(0.2)
                              : const Color(0xFF06B6D4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHabit
                                  ? Icons.repeat_rounded
                                  : Icons.task_alt_rounded,
                              size: 12,
                              color: isHabit
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF06B6D4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isHabit ? 'HÁBITO' : 'TAREFA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: isHabit
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF06B6D4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de dificuldade
                      _buildDifficultyBadge(suggestion.difficulty),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Título
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: Text(
                      suggestion.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Descrição
                  Expanded(
                    child: Text(
                      suggestion.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botões de ação
                  Row(
                    children: [
                      // Info extra
                      if (suggestion.scheduledTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                suggestion.scheduledTime!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      // Botão adicionar
                      GestureDetector(
                        onTap: isAdded
                            ? null
                            : () => _addSuggestion(suggestion),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isAdded
                                ? colors.surfaceContainerHighest
                                : cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isAdded
                                ? null
                                : [
                                    BoxShadow(
                                      color: cardColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAdded
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                size: 16,
                                color: isAdded
                                    ? colors.onSurfaceVariant
                                    : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAdded ? 'Adicionado' : 'Adicionar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isAdded
                                      ? colors.onSurfaceVariant
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Ícone da sugestão (Fundo)
            Positioned(
              right: 12,
              top: 12,
              child: Opacity(
                opacity: 0.1,
                child: Icon(suggestion.icon, color: cardColor, size: 80),
              ),
            ),
            // Botão Fechar (Topo Direito)
            Positioned(
              right: 8,
              top: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _dismissSuggestion(suggestion),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(SuggestionDifficulty difficulty) {
    late Color color;
    late String label;

    switch (difficulty) {
      case SuggestionDifficulty.easy:
        color = const Color(0xFF10B981);
        label = 'Fácil';
        break;
      case SuggestionDifficulty.medium:
        color = const Color(0xFFF59E0B);
        label = 'Médio';
        break;
      case SuggestionDifficulty.hard:
        color = const Color(0xFFEF4444);
        label = 'Difícil';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colors) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Carregando sugestões...',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration_rounded,
            size: 48,
            color: colors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Você explorou todas as sugestões!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Continue praticando seus hábitos e tarefas',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuggestionsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Ver todas as sugestões',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget wrapper para AnimatedBuilder (correção de tipo)
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
