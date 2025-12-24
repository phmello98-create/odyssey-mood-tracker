import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';

class TimerTaskSelector extends ConsumerStatefulWidget {
  final String? customTaskName;
  final TextEditingController taskNameController;
  final List<Map<String, dynamic>> activities; // Assuming passed from parent
  final VoidCallback onNewTaskTap;
  final Function(String, String?, String?) onTaskSelected;
  final Function(int, String, String?, String?)
  onTaskEdited; // Callback for when a task is edited in the list
  final Function(int) onTaskDeleted;
  final bool isPomodoro;

  const TimerTaskSelector({
    super.key,
    required this.customTaskName,
    required this.taskNameController,
    required this.activities,
    required this.onNewTaskTap,
    required this.onTaskSelected,
    required this.onTaskEdited,
    required this.onTaskDeleted,
    this.isPomodoro = true,
  });

  @override
  ConsumerState<TimerTaskSelector> createState() => _TimerTaskSelectorState();
}

class _TimerTaskSelectorState extends ConsumerState<TimerTaskSelector> {
  Color _getMainColor() {
    return widget.isPomodoro
        ? const Color(0xFFFF6B6B)
        : Theme.of(context).colorScheme.primary;
  }

  Color _getActivityColor(String? activityName) {
    if (activityName == null) return _getMainColor();
    final activity = widget.activities.firstWhere(
      (a) => a['name'] == activityName,
      orElse: () => {'color': _getMainColor()},
    );
    return activity['color'] as Color;
  }

  Future<bool?> _showSwitchTaskConfirmation(String newTaskName) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentTask = widget.customTaskName ?? widget.taskNameController.text;
    final mainColor = _getMainColor();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.swap_horiz_rounded, color: mainColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Trocar Tarefa?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isPomodoro
                  ? 'O Pomodoro está em andamento.'
                  : 'O timer está em andamento.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentTask.isNotEmpty ? currentTask : 'Sem tarefa',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF27AE60),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          newTaskName,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'O tempo continuará contando normalmente.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Trocar'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Map<String, dynamic> activity, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameController = TextEditingController(
      text: activity['name'] as String,
    );
    final categoryController = TextEditingController(
      text: activity['category'] as String? ?? '',
    );
    final projectController = TextEditingController(
      text: activity['project'] as String? ?? '',
    );
    final currentColor = activity['color'] as Color;
    final currentIcon = activity['icon'] as IconData;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: currentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(currentIcon, color: currentColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar Tarefa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Segure para editar ou deletar',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão deletar
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteTask(activity, index);
                    },
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    tooltip: 'Deletar',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Campo nome
              TextField(
                controller: nameController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Nome da Tarefa',
                  prefixIcon: Icon(Icons.edit_outlined, color: currentColor),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: currentColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campos categoria e projeto lado a lado
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: categoryController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: projectController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Projeto',
                        prefixIcon: Icon(
                          Icons.folder_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          widget.onTaskEdited(
                            index,
                            nameController.text,
                            categoryController.text.isNotEmpty
                                ? categoryController.text
                                : null,
                            projectController.text.isNotEmpty
                                ? projectController.text
                                : null,
                          );
                          Navigator.pop(context);
                          FeedbackService.showSuccess(
                            context,
                            '✅ Tarefa atualizada',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Salvar'),
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

  void _confirmDeleteTask(Map<String, dynamic> activity, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = activity['name'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            const Text('Deletar Tarefa?'),
          ],
        ),
        content: Text('Tem certeza que deseja deletar "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onTaskDeleted(index);
              Navigator.pop(context);
              FeedbackService.showInfo(context, '🗑️ Tarefa deletada');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mainColor = _getMainColor();
    final hasTask =
        widget.customTaskName != null ||
        widget.taskNameController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Row(
            children: [
              Text(
                '📋 Tarefa',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Botão para criar nova tarefa
              GestureDetector(
                onTap: widget.onNewTaskTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: mainColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: mainColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Nova',
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tarefa selecionada ou placeholder
          if (hasTask) _buildSelectedTimerTask() else _buildTaskPlaceholder(),

          const SizedBox(height: 12),

          // Lista horizontal de tarefas rápidas - Design Premium
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.activities.length,
              itemBuilder: (context, index) {
                final activity = widget.activities[index];
                final name = activity['name'] as String;
                final color = activity['color'] as Color;
                final icon = activity['icon'] as IconData;
                final isSelected =
                    widget.customTaskName == name ||
                    widget.taskNameController.text == name;

                return GestureDetector(
                  onTap: () async {
                    if (isSelected) return;

                    HapticFeedback.lightImpact();

                    // Verificar diretamente no provider se o timer está rodando
                    final timerState = ref.read(timerProvider);
                    final isTimerActive =
                        timerState.isRunning &&
                        ((widget.isPomodoro &&
                                timerState.isPomodoroMode &&
                                !timerState.isPomodoroBreak) ||
                            (!widget.isPomodoro && !timerState.isPomodoroMode));

                    if (isTimerActive) {
                      final shouldSwitch = await _showSwitchTaskConfirmation(
                        name,
                      );
                      if (shouldSwitch != true) return;
                    }

                    // Notificar seleção
                    widget.onTaskSelected(
                      name,
                      activity['category'] as String?,
                      activity['project'] as String?,
                    );

                    if (isTimerActive) {
                      ref.read(timerProvider.notifier).updateTaskName(name);
                      if (context.mounted) {
                        FeedbackService.showInfo(context, '🔄 Tarefa: $name');
                      }
                    }
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    _showEditTaskDialog(activity, index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : colorScheme.onSurface.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone com background
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nome
                        Text(
                          name.length > 12
                              ? '${name.substring(0, 12)}...'
                              : name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        // Check se selecionado
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTimerTask() {
    final colorScheme = Theme.of(context).colorScheme;
    final taskName = widget.customTaskName ?? widget.taskNameController.text;
    final color = _getActivityColor(taskName);
    final activityData = widget.activities.firstWhere(
      (a) => a['name'] == taskName,
      orElse: () => {
        'icon': Icons.check_circle_outline,
        'project': null,
        'category': null,
      },
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activityData['icon'] as IconData,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activityData['category'] != null ||
                    activityData['project'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (activityData['project'] != null)
                        Text(
                          activityData['project'],
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.7,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      if (activityData['project'] != null &&
                          activityData['category'] != null)
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      if (activityData['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            activityData['category'],
                            style: TextStyle(
                              color: color.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Limpar tarefa
              widget.onTaskSelected('', null, null);
              ref.read(timerProvider.notifier).updateTaskName(null);
            },
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onNewTaskTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_task_rounded,
                color: colorScheme.primary.withOpacity(0.8),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O que vamos focar?',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecione ou crie uma tarefa',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
