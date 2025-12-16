import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.init();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!_initialized) {
      return _buildContainer(colors, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    final taskRepo = ref.watch(taskRepositoryProvider);

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
                  color: const Color(0xFF42A5F5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF42A5F5), size: 18),
              ),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.tarefasDoDia, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())),
                child: Text(AppLocalizations.of(context)!.verTodas, style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          FutureBuilder<List<TaskData>>(
            future: taskRepo.getTasksForDate(DateTime.now()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              
              final tasks = snapshot.data?.take(4).toList() ?? [];

              if (tasks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration_outlined, color: Color(0xFF07E092), size: 20),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.nenhumaTarefaParaHoje, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              final completed = tasks.where((t) => t.completed).length;
              final total = tasks.length;

              return Column(
                children: [
                  // Progress
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? completed / total : 0,
                            backgroundColor: colors.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF07E092)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$completed/$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Task list
                  ...tasks.map((task) {
                    final isCompleted = task.completed;
                    final title = task.title;
                    final priority = task.priority;
                    
                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final syncedRepo = ref.read(syncedTaskRepositoryProvider);
                        await syncedRepo.toggleTaskCompletion(task.key);
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isCompleted ? const Color(0xFF07E092).withValues(alpha: 0.3) : colors.outline.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isCompleted ? const Color(0xFF07E092) : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                                border: isCompleted ? null : Border.all(color: colors.outline.withValues(alpha: 0.3)),
                              ),
                              child: isCompleted
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isCompleted ? colors.onSurfaceVariant : colors.onSurface,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (priority == 'high')
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
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
        boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
