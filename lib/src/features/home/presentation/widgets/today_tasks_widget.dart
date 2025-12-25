import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/tasks/data/synced_task_repository.dart';
import 'package:odyssey/src/features/tasks/presentation/tasks_screen.dart';

class TodayTasksWidget extends ConsumerStatefulWidget {
  const TodayTasksWidget({super.key});

  @override
  ConsumerState<TodayTasksWidget> createState() => _TodayTasksWidgetState();
}

class _TodayTasksWidgetState extends ConsumerState<TodayTasksWidget> {
  bool _initialized = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.init();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  List<TaskData> _getTasksForToday(Box box) {
    final now = DateTime.now();
    final tasks = <TaskData>[];

    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        final task = TaskData.fromMap(key, Map<String, dynamic>.from(value));
        if (task.dueDate != null &&
            task.dueDate!.year == now.year &&
            task.dueDate!.month == now.month &&
            task.dueDate!.day == now.day) {
          tasks.add(task);
        }
      }
    }

    // Ordena: não completadas primeiro, depois por prioridade
    tasks.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      return (priorityOrder[a.priority] ?? 1).compareTo(
        priorityOrder[b.priority] ?? 1,
      );
    });

    return tasks.take(4).toList();
  }

  Future<void> _toggleTask(TaskData task) async {
    if (_isUpdating) return;

    HapticFeedback.lightImpact();
    setState(() => _isUpdating = true);

    try {
      final syncedRepo = ref.read(syncedTaskRepositoryProvider);
      await syncedRepo.toggleTaskCompletion(task.key);
    } catch (e) {
      debugPrint('Erro ao alternar tarefa: $e');
    }

    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final repo = ref.watch(taskRepositoryProvider);

    if (!_initialized) {
      return _buildContainer(
        colors,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final boxListenable = repo.boxListenable;
    if (boxListenable == null) {
      return _buildContainer(
        colors,
        child: const Center(child: Text('Carregando...')),
      );
    }

    return ValueListenableBuilder<Box>(
      valueListenable: boxListenable,
      builder: (context, box, _) {
        final tasks = _getTasksForToday(box);

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
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.tarefasDoDia,
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
                      MaterialPageRoute(builder: (_) => const TasksScreen()),
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
              _buildTasksContent(colors, tasks),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksContent(ColorScheme colors, List<TaskData> tasks) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.celebration_outlined, color: colors.tertiary, size: 20),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.nenhumaTarefaParaHoje,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final completed = tasks.where((t) => t.completed).length;
    final total = tasks.length;

    return Column(
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colors.tertiary),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Task list
        ...tasks.map((task) => _buildTaskItem(task, colors)),
      ],
    );
  }

  Widget _buildTaskItem(TaskData task, ColorScheme colors) {
    final isCompleted = task.completed;

    return GestureDetector(
      onTap: () => _toggleTask(task),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCompleted
              ? colors.tertiary.withValues(alpha: 0.08)
              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted
                ? colors.tertiary.withValues(alpha: 0.3)
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
                    ? colors.tertiary
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: isCompleted
                    ? null
                    : Border.all(color: colors.outline.withValues(alpha: 0.3)),
              ),
              child: isCompleted
                  ? Icon(Icons.check, size: 14, color: colors.onTertiary)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
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
            if (task.priority == 'high')
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
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
