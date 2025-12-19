import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';
import 'package:odyssey/src/features/tasks/presentation/widgets/task_form_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openTaskSheet({TaskData? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormSheet(
        task: task,
        onSave: (newTask) async {
          final taskRepo = ref.read(taskRepositoryProvider);
          if (task == null) {
            await taskRepo.addTask(newTask);
            if (mounted) {
              FeedbackService.showSuccess(
                context,
                '✅ Tarefa criada!',
                icon: Icons.task_alt,
              );
            }
          } else {
            await taskRepo.updateTask(newTask);
            if (mounted) {
              FeedbackService.showSuccess(
                context,
                'Tarefa atualizada',
                icon: Icons.check,
              );
            }
          }
          setState(() {});
        },
      ),
    );
  }

  Future<void> _toggleTaskCompletion(TaskData task) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    HapticFeedback.mediumImpact();

    await taskRepo.toggleTaskCompletion(task.key);
    setState(() {});

    if (!task.completed && mounted) {
      try {
        final gamificationRepo = ref.read(gamificationRepositoryProvider);
        await gamificationRepo.completeTask();
        if (mounted) {
          FeedbackService.showSuccess(
            context,
            '🎉 Concluída! +15 XP',
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
    }
  }

  Future<void> _deleteTask(TaskData task) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.deleteTask(task.key);
    setState(() {});
    if (mounted) {
      FeedbackService.showWarning(
        context,
        'Tarefa removida',
        icon: Icons.delete_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskRepo = ref.watch(taskRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskSheet(),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Tarefa'),
        elevation: 4,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header with Filter Chips e Mock Generator
            _buildHeader(context, colors),

            // Pills Tab Section
            const SizedBox(height: 16),
            _buildPillsTabSection(context, colors, taskRepo),

            // Content
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

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
          child: Row(
            children: [
              // Back button
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minhas Tarefas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Organize seu dia',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Mock/Debug Button
            ],
          ),
        ),
        // Horizontal Filter Chips
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'Todas',
                  value: 'all',
                  icon: Icons.list_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Hoje',
                  value: 'today',
                  icon: Icons.today_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Semana',
                  value: 'week',
                  icon: Icons.date_range_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Alta Prioridade',
                  value: 'high',
                  icon: Icons.priority_high_rounded,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == value;
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = value);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary
                : colors.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillsTabSection(
    BuildContext context,
    ColorScheme colors,
    TaskRepository taskRepo,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<List<TaskData>>(
        future: taskRepo.getAllTasks(),
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];
          final pending = allTasks.where((t) => !t.completed).length;
          final completed = allTasks.where((t) => t.completed).length;

          return Container(
            height: 50,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pendentes'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pending',
                          style: TextStyle(fontSize: 12, color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Concluídas'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.onSurfaceVariant.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2,
            ),
          );
        }

        var tasks = snapshot.data ?? [];

        // Apply filters
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
        } else if (_selectedFilter == 'high') {
          tasks = tasks.where((t) => t.priority == 'high').toList();
        }

        if (tasks.isEmpty) {
          return _buildEmptyState(completed: completed);
        }

        // Group tasks by date
        final groupedTasks = <String, List<TaskData>>{};
        for (final task in tasks) {
          final dateKey = task.dueDate != null
              ? DateFormat('dd/MM/yyyy').format(task.dueDate!)
              : 'Sem data';
          groupedTasks.putIfAbsent(dateKey, () => []).add(task);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: groupedTasks.keys.length,
          itemBuilder: (context, index) {
            final dateKey = groupedTasks.keys.elementAt(index);
            final dateTasks = groupedTasks[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                _buildDateHeader(dateKey),
                // Tasks
                ...dateTasks.map((task) => _buildTaskCard(task)),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(String dateKey) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    String label = dateKey;

    if (dateKey != 'Sem data') {
      try {
        final date = DateFormat('dd/MM/yyyy').parse(dateKey);
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          label = 'Hoje';
        } else if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day + 1) {
          label = 'Amanhã';
        } else if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day - 1) {
          label = 'Ontem';
        } else {
          label = DateFormat('EEEE, dd MMM', 'pt_BR').format(date);
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label.substring(0, 1).toUpperCase() + label.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskData task) {
    final colors = Theme.of(context).colorScheme;
    final priorityColor = _getPriorityColor(task.priority);
    final isCompleted = task.completed;

    return Dismissible(
      key: Key(task.key.toString()),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: colors.surface,
              title: const Text('Excluir Tarefa?'),
              content: const Text(
                'Tem certeza que deseja apagar esta tarefa permanentemente?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          );
          return confirmed;
        } else {
          _openTaskSheet(task: task);
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _deleteTask(task);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? UltravioletColors.accentGreen.withOpacity(0.3)
                : priorityColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isCompleted ? UltravioletColors.accentGreen : priorityColor)
                      .withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openTaskSheet(task: task),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _buildAnimatedCheckbox(task, priorityColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? colors.onSurfaceVariant.withOpacity(0.6)
                                : colors.onSurface,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: colors.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                        if (task.notes != null && task.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.notes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPriorityBadge(task.priority, priorityColor),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.category ?? 'Geral',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (task.dueTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.dueTime!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      if (!isCompleted)
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: colors.onSurfaceVariant.withOpacity(0.6),
                          ),
                          onPressed: () => _openTaskSheet(task: task),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCheckbox(TaskData task, Color priorityColor) {
    final isCompleted = task.completed;

    return GestureDetector(
      onTap: () => _toggleTaskCompletion(task),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isCompleted
              ? UltravioletColors.accentGreen
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted
                ? UltravioletColors.accentGreen
                : priorityColor.withOpacity(0.5),
            width: 2.5,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: UltravioletColors.accentGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isCompleted
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                  key: ValueKey('check'),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    // Helper para ícones
    IconData icon;
    if (value == 'high') {
      icon = Icons.keyboard_double_arrow_up_rounded;
    } else if (value == 'low') {
      icon = Icons.keyboard_double_arrow_down_rounded;
    } else {
      icon = Icons.remove_rounded;
    }

    // Ajuste de label se necessário
    String displayLabel = label;
    if (label.isEmpty) {
      switch (value.toLowerCase()) {
        case 'high':
          displayLabel = 'Alta';
          break;
        case 'low':
          displayLabel = 'Baixa';
          break;
        default:
          displayLabel = 'Média';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Wrapper para usar o widget acima que espera Color e label
  Widget _buildPriorityBadge(String priority, Color color) {
    String label;
    switch (priority.toLowerCase()) {
      case 'high':
        label = 'Alta';
        break;
      case 'low':
        label = 'Baixa';
        break;
      default:
        label = 'Média';
    }
    return _buildPriorityChip(priority, label, color);
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade400;
      case 'medium':
        return Colors.orange.shade400;
      case 'low':
        return Colors.blue.shade400;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState({required bool completed}) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    UltravioletColors.accentGreen.withOpacity(0.2),
                    UltravioletColors.accentGreen.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                completed ? Icons.celebration_rounded : Icons.task_alt_rounded,
                size: 48,
                color: UltravioletColors.accentGreen,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              completed ? 'Ainda sem conquistas' : 'Tudo em dia! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              completed
                  ? 'Complete suas tarefas e veja\nsuas conquistas aqui'
                  : 'Nenhuma tarefa pendente.\nAproveite o momento!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (!completed) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => _openTaskSheet(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar Tarefa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
