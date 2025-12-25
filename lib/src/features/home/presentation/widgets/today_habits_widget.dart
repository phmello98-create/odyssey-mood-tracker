import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum para os modos de visualização dos hábitos
enum HabitsViewMode {
  /// Modo minimalista: apenas chips em row horizontal scrollável
  compact,

  /// Modo padrão: grid 2 colunas com cards pequenos
  normal,

  /// Modo ícones: apenas ícones em row horizontal scrollável
  minimal,
}

class TodayHabitsWidget extends ConsumerStatefulWidget {
  const TodayHabitsWidget({super.key});

  @override
  ConsumerState<TodayHabitsWidget> createState() => _TodayHabitsWidgetState();
}

class _TodayHabitsWidgetState extends ConsumerState<TodayHabitsWidget>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  List<Habit> _habits = [];
  late HabitRepository _habitRepo;
  bool _isUpdating = false;
  HabitsViewMode _viewMode = HabitsViewMode.normal;

  // Animation controller para smooth transitions
  late AnimationController _animationController;

  static const String _viewModeKey = 'habits_widget_view_mode';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _habitRepo = HabitRepository();
      await _habitRepo.init();

      // Carregar preferência salva
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getInt(_viewModeKey) ?? 1;
      _viewMode = HabitsViewMode
          .values[savedMode.clamp(0, HabitsViewMode.values.length - 1)];

      // Configurar animação inicial baseada no modo
      if (_viewMode == HabitsViewMode.normal) {
        _animationController.value = 1.0;
      }

      _loadHabits();
    } catch (e) {
      debugPrint('Error initializing habits: $e');
      if (mounted) setState(() => _initialized = true);
    }
  }

  void _loadHabits() {
    final allHabits = _habitRepo.getAllHabits();
    // Mostrar até 8 hábitos no modo compacto, 5 no normal
    _habits = allHabits
        .take(_viewMode == HabitsViewMode.compact ? 8 : 5)
        .toList();
    if (mounted) setState(() => _initialized = true);
  }

  bool _isCompletedToday(Habit habit) {
    final today = DateTime.now();
    return habit.completedDates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );
  }

  Future<void> _toggleViewMode() async {
    HapticFeedback.lightImpact();

    final nextIndex = (_viewMode.index + 1) % HabitsViewMode.values.length;
    final nextMode = HabitsViewMode.values[nextIndex];

    setState(() {
      _viewMode = nextMode;
    });

    // Recarregar hábitos com limite apropriado
    _loadHabits();

    // Salvar preferência
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_viewModeKey, nextMode.index);
  }

  Future<void> _toggleHabit(Habit habit) async {
    if (_isUpdating) return;

    HapticFeedback.lightImpact();
    setState(() => _isUpdating = true);

    try {
      final today = DateTime.now();
      final isCompleted = _isCompletedToday(habit);

      // Criar nova lista de datas
      final newCompletedDates = List<DateTime>.from(habit.completedDates);
      int newStreak = habit.currentStreak;
      int newBestStreak = habit.bestStreak;

      if (isCompleted) {
        // Remover de hoje
        newCompletedDates.removeWhere(
          (date) =>
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day,
        );
      } else {
        // Adicionar hoje
        newCompletedDates.add(today);
        newStreak++;
        if (newStreak > newBestStreak) {
          newBestStreak = newStreak;
        }
      }

      // Criar habit atualizado usando copyWith
      final updatedHabit = habit.copyWith(
        completedDates: newCompletedDates,
        currentStreak: newStreak,
        bestStreak: newBestStreak,
      );

      await _habitRepo.updateHabit(updatedHabit);
      _loadHabits();
    } catch (e) {
      debugPrint('Error toggling habit: $e');
    }

    if (mounted) setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final completedCount = _habits.where((h) => _isCompletedToday(h)).length;
    final totalCount = _habits.length;

    return _buildContainer(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header com toggle de modo
          GestureDetector(
            onTap: _habits.isNotEmpty ? _toggleViewMode : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.repeat_rounded,
                    color: colors.secondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.habitosDoDia,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      if (_initialized && _habits.isNotEmpty)
                        Text(
                          '$completedCount de $totalCount concluídos',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

                // Toggle button com ícone que indica o modo
                if (_habits.isNotEmpty) ...[
                  // Ícone do toggle que muda conforme o estado
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      _viewMode == HabitsViewMode.normal
                          ? Icons.grid_view_rounded
                          : _viewMode == HabitsViewMode.compact
                          ? Icons
                                .view_column_rounded // Icone que lembra rows/list
                          : Icons.circle_outlined, // Icone para minimal
                      key: ValueKey(_viewMode),
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HabitsCalendarScreen(),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.verTodas,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress bar sempre visível
          const SizedBox(height: 10),
          if (_initialized && _habits.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  completedCount == totalCount
                      ? colors.tertiary
                      : colors.secondary,
                ),
                minHeight: 4,
              ),
            ),

          // Conteúdo baseado no modo
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildHabitsContent(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsContent(ColorScheme colors) {
    if (!_initialized) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_habits.isEmpty) {
      return _buildEmptyState(colors);
    }

    // Retornar o widget baseado no modo de visualização
    switch (_viewMode) {
      case HabitsViewMode.compact:
        return _buildCompactView(colors);
      case HabitsViewMode.minimal:
        return _buildMinimalView(colors);
      case HabitsViewMode.normal:
        return _buildNormalView(colors);
    }
  }

  /// Modo minimal: ícones circulares horizontais scrolláveis
  Widget _buildMinimalView(ColorScheme colors) {
    return SizedBox(
      key: const ValueKey('minimal'),
      height: 44, // Altura suficiente para o círculo + sombra
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _habits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final habit = _habits[index];
          return _buildMinimalCircle(habit, colors);
        },
      ),
    );
  }

  /// Círculo minimalista com ícone
  Widget _buildMinimalCircle(Habit habit, ColorScheme colors) {
    final isCompleted = _isCompletedToday(habit);
    final habitColor = Color(habit.colorValue);

    return GestureDetector(
      onTap: () => _toggleHabit(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCompleted
              ? habitColor
              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: isCompleted
              ? null
              : Border.all(
                  color: habitColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: habitColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check, size: 20, color: Colors.white)
              : Icon(
                  IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                  size: 20,
                  color: habitColor.withValues(alpha: 0.8),
                ),
        ),
      ),
    );
  }

  /// Modo compacto: chips horizontais scrolláveis
  Widget _buildCompactView(ColorScheme colors) {
    return SizedBox(
      key: const ValueKey('compact'),
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _habits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final habit = _habits[index];
          return _buildCompactChip(habit, colors);
        },
      ),
    );
  }

  /// Chip compacto para o modo minimizado
  Widget _buildCompactChip(Habit habit, ColorScheme colors) {
    final isCompleted = _isCompletedToday(habit);
    final habitColor = Color(habit.colorValue);

    return GestureDetector(
      onTap: () => _toggleHabit(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCompleted
              ? habitColor.withValues(alpha: 0.2)
              : colors.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? habitColor.withValues(alpha: 0.5)
                : colors.outline.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox pequeno
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isCompleted ? habitColor : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: isCompleted
                    ? null
                    : Border.all(color: habitColor.withValues(alpha: 0.6)),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            // Ícone do hábito
            Icon(
              IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
              size: 14,
              color: isCompleted
                  ? habitColor
                  : habitColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            // Nome abreviado
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                habit.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Streak indicator
            if (habit.currentStreak > 0) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.local_fire_department,
                size: 10,
                color: colors.tertiary,
              ),
              Text(
                '${habit.currentStreak}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: colors.tertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Modo normal: grid 2 colunas
  Widget _buildNormalView(ColorScheme colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Padding da tela (16) + padding do container (16) + gap entre items (8)
    final itemWidth = (screenWidth - 32 - 32 - 8) / 2;

    return Wrap(
      key: const ValueKey('normal'),
      spacing: 8,
      runSpacing: 8,
      children: _habits.map((habit) {
        return SizedBox(
          width: itemWidth,
          child: _buildNormalCard(habit, colors),
        );
      }).toList(),
    );
  }

  /// Card para o modo normal
  Widget _buildNormalCard(Habit habit, ColorScheme colors) {
    final isCompleted = _isCompletedToday(habit);
    final habitColor = Color(habit.colorValue);

    return GestureDetector(
      onTap: () => _toggleHabit(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isCompleted
              ? habitColor.withValues(alpha: 0.1)
              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? habitColor.withValues(alpha: 0.4)
                : colors.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Checkbox animado
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCompleted
                    ? habitColor
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(5),
                border: isCompleted
                    ? null
                    : Border.all(color: habitColor.withValues(alpha: 0.5)),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),

            // Texto e Ícone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                        size: 14,
                        color: habitColor,
                      ),
                      const SizedBox(width: 4),
                      if (habit.currentStreak > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 10,
                              color: colors.tertiary,
                            ),
                            Text(
                              '${habit.currentStreak}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: colors.tertiary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCompleted
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: colors.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Crie seu primeiro hábito',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HabitsCalendarScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Criar',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer(ColorScheme colors, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
