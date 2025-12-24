import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/features/habits/presentation/habits_calendar_screen.dart';

class TodayHabitsWidget extends ConsumerStatefulWidget {
  const TodayHabitsWidget({super.key});

  @override
  ConsumerState<TodayHabitsWidget> createState() => _TodayHabitsWidgetState();
}

class _TodayHabitsWidgetState extends ConsumerState<TodayHabitsWidget> {
  bool _initialized = false;
  List<Habit> _habits = [];
  late HabitRepository _habitRepo;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _habitRepo = HabitRepository();
      await _habitRepo.init();
      _loadHabits();
    } catch (e) {
      debugPrint('Error initializing habits: $e');
      if (mounted) setState(() => _initialized = true);
    }
  }

  void _loadHabits() {
    final allHabits = _habitRepo.getAllHabits();
    // Filtrar hábitos ativos (limite de 5 para o widget)
    _habits = allHabits.take(5).toList();
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

    return _buildContainer(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                AppLocalizations.of(context)!.habitosDoDia,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
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
          const SizedBox(height: 12),
          _buildHabitsContent(colors),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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

    final completedCount = _habits.where((h) => _isCompletedToday(h)).length;
    final totalCount = _habits.length;

    return Column(
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalCount > 0 ? completedCount / totalCount : 0,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colors.secondary),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$completedCount/$totalCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Habits list
        ..._habits.map((habit) => _buildHabitItem(habit, colors)),
      ],
    );
  }

  Widget _buildHabitItem(Habit habit, ColorScheme colors) {
    final isCompleted = _isCompletedToday(habit);
    final habitColor = Color(habit.colorValue);

    return GestureDetector(
      onTap: () => _toggleHabit(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCompleted
              ? habitColor.withValues(alpha: 0.1)
              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted
                ? habitColor.withValues(alpha: 0.4)
                : colors.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted
                    ? habitColor
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: isCompleted
                    ? null
                    : Border.all(color: habitColor.withValues(alpha: 0.5)),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Icon(
              IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
              size: 18,
              color: habitColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                habit.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isCompleted
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (habit.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 12,
                      color: colors.tertiary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${habit.currentStreak}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.tertiary,
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
