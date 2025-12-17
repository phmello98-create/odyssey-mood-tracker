import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quickAddController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _createQuickTask() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;

    final taskRepo = ref.read(taskRepositoryProvider);
    HapticFeedback.mediumImpact();

    final newTask = TaskData(
      key: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      notes: '',
      completed: false,
      priority: 'medium',
      category: 'Personal',
      dueDate: DateTime.now(),
      dueTime: null,
      createdAt: DateTime.now(),
      completedAt: null,
    );

    await taskRepo.addTask(newTask);
    _quickAddController.clear();

    if (mounted) {
      FeedbackService.showSuccess(
        context,
        '✅ Tarefa criada!',
        icon: Icons.task_alt,
      );
    }
  }

  Future<void> _toggleTaskCompletion(TaskData task) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    HapticFeedback.mediumImpact();

    await taskRepo.toggleTaskCompletion(task.key);

    if (!task.completed && mounted) {
      try {
        final gamificationRepo = ref.read(gamificationRepositoryProvider);
        await gamificationRepo.completeTask();
        if (mounted) {
          FeedbackService.showSuccess(
            context,
            '🎉 Tarefa concluída! +15 XP',
            icon: Icons.celebration,
          );
        }
      } catch (e) {
        if (mounted) {
          FeedbackService.showSuccess(
            context,
            '🎉 Tarefa concluída!',
            icon: Icons.celebration,
          );
        }
      }
    } else if (mounted) {
      FeedbackService.showInfo(context, 'Tarefa reaberta', icon: Icons.replay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskRepo = ref.watch(taskRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tarefas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Buscar tarefas...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quickAddController,
                        onSubmitted: (_) => _createQuickTask(),
                        decoration: InputDecoration(
                          hintText: 'Nova tarefa rápida...',
                          hintStyle: TextStyle(
                            color: colors.onSurfaceVariant.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _createQuickTask,
                      icon: Icon(Icons.add_circle, color: colors.primary),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'Todas', Icons.list),
                  const SizedBox(width: 8),
                  _buildFilterChip('today', 'Hoje', Icons.today),
                  const SizedBox(width: 8),
                  _buildFilterChip('week', 'Esta Semana', Icons.date_range),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: FutureBuilder<List<TaskData>>(
                future: taskRepo.getAllTasks(),
                builder: (context, snapshot) {
                  final allTasks = snapshot.data ?? [];
                  final pending = allTasks.where((t) => !t.completed).length;
                  final completed = allTasks.where((t) => t.completed).length;

                  return TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: colors.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Pendentes ($pending)'),
                      Tab(text: 'Concluídas ($completed)'),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskListView(taskRepo, completed: false),
                  _buildTaskListView(taskRepo, completed: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedFilter == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        HapticFeedback.selectionClick();
      },
      selectedColor: colors.primary,
      backgroundColor: colors.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : colors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? colors.primary : colors.outline.withOpacity(0.2),
      ),
    );
  }

  Widget _buildTaskListView(
    TaskRepository taskRepo, {
    required bool completed,
  }) {
    return FutureBuilder<List<TaskData>>(
      future: completed
          ? taskRepo.getCompletedTasks()
          : taskRepo.getPendingTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var tasks = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          tasks = tasks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
        }

        final now = DateTime.now();
        if (_selectedFilter == 'today') {
          tasks = tasks.where((t) {
            if (t.dueDate == null) return false;
            return t.dueDate!.year == now.year &&
                t.dueDate!.month == now.month &&
                t.dueDate!.day == now.day;
          }).toList();
        } else if (_selectedFilter == 'week') {
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 7));
          tasks = tasks.where((t) {
            if (t.dueDate == null) return false;
            return t.dueDate!.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                t.dueDate!.isBefore(weekEnd);
          }).toList();
        }

        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: completed ? Icons.task_alt : Icons.check_circle_outline,
            title: completed
                ? 'Nenhuma tarefa concluída'
                : 'Nenhuma tarefa pendente',
            subtitle: completed
                ? 'Complete suas tarefas para vê-las aqui'
                : 'Adicione uma nova tarefa acima',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskCard(task);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(TaskData task) {
    final colors = Theme.of(context).colorScheme;
    final priorityColor = _getPriorityColor(task.priority);

    return Dismissible(
      key: Key(task.key.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        final taskRepo = ref.read(taskRepositoryProvider);
        await taskRepo.deleteTask(task.key);
        if (mounted) {
          FeedbackService.showWarning(
            context,
            'Tarefa removida',
            icon: Icons.delete_outline,
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.completed
                ? UltravioletColors.accentGreen.withOpacity(0.3)
                : priorityColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: GestureDetector(
            onTap: () => _toggleTaskCompletion(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: task.completed
                    ? UltravioletColors.accentGreen
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: task.completed
                      ? UltravioletColors.accentGreen
                      : priorityColor,
                  width: 2.5,
                ),
              ),
              child: task.completed
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.completed
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.dueDate != null
                        ? DateFormat('dd/MM').format(task.dueDate!)
                        : 'Sem data',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: UltravioletColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: UltravioletColors.accentGreen),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
