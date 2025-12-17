import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart' as showcase;

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with TickerProviderStateMixin {
  // Showcase keys
  final GlobalKey _showcaseAdd = GlobalKey();
  // Showcase keys
  final GlobalKey _showcaseList = GlobalKey();
  // Showcase keys
  final GlobalKey _showcaseFilter = GlobalKey();
  late Box _box;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _tabController = TabController(length: 2, vsync: this);
    _openBox();
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox('tasks');
    setState(() {
      _isLoading = false;
    });
  }

  void _addTask() {
    _showTaskEditor();
  }

  void _showTaskEditor({String? id, String? initialTitle}) {
    final controller = TextEditingController(text: initialTitle);
    final isEditing = id != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Editar Tarefa' : 'Nova Tarefa',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'O que você precisa fazer?',
                filled: true,
                fillColor: UltravioletColors.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.check_circle_outline,
                  color: UltravioletColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final title = controller.text.trim();
                  if (title.isEmpty) return;

                  HapticFeedback.mediumImpact();

                  if (isEditing) {
                    final existing = _box.get(id) as Map;
                    _box.put(id, {
                      'title': title,
                      'completed': existing['completed'] ?? false,
                      'createdAt': existing['createdAt'] ?? DateTime.now().toIso8601String(),
                    });
                  } else {
                    final newId = DateTime.now().millisecondsSinceEpoch.toString();
                    _box.put(newId, {
                      'title': title,
                      'completed': false,
                      'createdAt': DateTime.now().toIso8601String(),
                    });
                  }

                  Navigator.pop(context);
                  setState(() {});
                  
                  // Feedback visual
                  FeedbackService.showSuccess(
                    context, 
                    isEditing ? '✏️ Tarefa atualizada!' : '✅ Tarefa adicionada!',
                    icon: isEditing ? Icons.edit : Icons.task_alt,
                  );
                  
                  // XP para novas tarefas
                  if (!isEditing) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        FeedbackService.showXPGained(context, 5, reason: 'por criar tarefa');
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(isEditing ? 'Salvar' : 'Adicionar Tarefa'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _toggleTask(String id) {
    final item = _box.get(id) as Map;
    final wasCompleted = item['completed'] as bool? ?? false;
    final nowCompleted = !wasCompleted;
    
    _box.put(id, {
      'title': item['title'],
      'completed': nowCompleted,
      'createdAt': item['createdAt'],
    });
    setState(() {});
    
    HapticFeedback.mediumImpact();
    
    if (nowCompleted) {
      FeedbackService.showSuccess(
        context, 
        '🎉 Tarefa concluída! Excelente!',
        icon: Icons.celebration,
      );
      // XP por completar tarefa
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          FeedbackService.showXPGained(context, 15, reason: 'por completar tarefa');
        }
      });
    } else {
      FeedbackService.showInfo(
        context, 
        'Tarefa marcada como pendente',
        icon: Icons.replay,
      );
    }
  }

  void _deleteTask(String id) {
    _box.delete(id);
    setState(() {});
    HapticFeedback.lightImpact();
    FeedbackService.showWarning(
      context, 
      'Tarefa removida',
      icon: Icons.delete_outline,
    );
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.tasks);
    _tabController.dispose();
    super.dispose();
  }

  List<MapEntry<String, Map>> _getTasks({required bool completed}) {
    if (_isLoading) return [];
    return _box.keys
        .map((key) => MapEntry(key as String, _box.get(key) as Map))
        .where((entry) => (entry.value['completed'] ?? false) == completed)
        .toList()
        .reversed
        .toList();
  }
  void _initShowcase() {
    final keys = [_showcaseFilter, _showcaseList, _showcaseAdd];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.tasks,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.tasks, keys);
  }
  
  void _startTour() {
    final keys = [_showcaseFilter, _showcaseList, _showcaseAdd];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.tasks, keys);
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pendingTasks = _getTasks(completed: false);
    final completedTasks = _getTasks(completed: true);
    final totalTasks = pendingTasks.length + completedTasks.length;
    final completionRate = totalTasks > 0 
        ? (completedTasks.length / totalTasks * 100).round() 
        : 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                    style: IconButton.styleFrom(
                      backgroundColor: UltravioletColors.surfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarefas',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$completionRate% concluído',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: UltravioletColors.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${completedTasks.length}/$totalTasks tarefas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: UltravioletColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalTasks > 0 ? completedTasks.length / totalTasks : 0,
                      backgroundColor: UltravioletColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation(UltravioletColors.accentGreen),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: UltravioletColors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: UltravioletColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: UltravioletColors.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Pendentes (${pendingTasks.length})'),
                  Tab(text: 'Concluídas (${completedTasks.length})'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Task lists
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pending tasks
                  pendingTasks.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'Nenhuma tarefa pendente',
                          subtitle: 'Adicione uma nova tarefa para começar',
                        )
                      : _buildTaskList(pendingTasks),
                  // Completed tasks
                  completedTasks.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.task_alt,
                          title: 'Nenhuma tarefa concluída',
                          subtitle: 'Complete suas tarefas para vê-las aqui',
                        )
                      : _buildTaskList(completedTasks),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        backgroundColor: UltravioletColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Tarefa', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTaskList(List<MapEntry<String, Map>> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final entry = tasks[index];
        final isCompleted = entry.value['completed'] ?? false;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Dismissible(
            key: Key(entry.key),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _deleteTask(entry.key),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: UltravioletColors.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: UltravioletColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted 
                      ? UltravioletColors.accentGreen.withOpacity(0.3)
                      : UltravioletColors.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: GestureDetector(
                  onTap: () => _toggleTask(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? UltravioletColors.accentGreen 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted 
                            ? UltravioletColors.accentGreen 
                            : UltravioletColors.outline,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                title: Text(
                  entry.value['title'] ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted 
                        ? UltravioletColors.onSurfaceVariant 
                        : UltravioletColors.onSurface,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: UltravioletColors.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _showTaskEditor(
                      id: entry.key,
                      initialTitle: entry.value['title'],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              child: Icon(
                icon,
                size: 40,
                color: UltravioletColors.accentGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: UltravioletColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
