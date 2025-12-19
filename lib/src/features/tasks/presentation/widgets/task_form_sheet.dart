import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:odyssey/src/features/tasks/data/task_repository.dart';

class TaskFormSheet extends StatefulWidget {
  final TaskData? task;
  final Function(TaskData) onSave;

  const TaskFormSheet({super.key, this.task, required this.onSave});

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _priority;
  late String _category;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  final List<String> _categories = [
    'Trabalho',
    'Pessoal',
    'Estudo',
    'Saúde',
    'Projeto',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    _priority = widget.task?.priority ?? 'medium';
    _category = widget.task?.category ?? 'Pessoal';
    _dueDate = widget.task?.dueDate ?? DateTime.now();

    if (widget.task?.dueTime != null) {
      final parts = widget.task!.dueTime!.split(':');
      if (parts.length == 2) {
        _dueTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;

    final newTask = TaskData(
      key: widget.task?.key ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      completed: widget.task?.completed ?? false,
      priority: _priority,
      category: _category,
      dueDate: _dueDate,
      dueTime: _dueTime != null
          ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      completedAt: widget.task?.completedAt,
    );

    widget.onSave(newTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEditing = widget.task != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Editar Tarefa' : 'Nova Tarefa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                if (isEditing)
                  IconButton(
                    onPressed: () {
                      // Delete logic handled by parent via callback usually,
                      // but for now let's just close
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerHighest
                          .withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input
                  TextField(
                    controller: _titleController,
                    autofocus: !isEditing,
                    decoration: InputDecoration(
                      hintText: 'O que precisa ser feito?',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: colors.onSurfaceVariant.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  // Description Input
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Adicionar descrição...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                        size: 20,
                        color: colors.primary.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.outline.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.outline.withOpacity(0.1),
                        ),
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),

                  const SizedBox(height: 24),

                  // Priority Selection
                  Text(
                    'PRIORIDADE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant.withOpacity(0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPriorityChip('low', 'Baixa', Colors.blue),
                      const SizedBox(width: 8),
                      _buildPriorityChip('medium', 'Média', Colors.orange),
                      const SizedBox(width: 8),
                      _buildPriorityChip('high', 'Alta', Colors.red),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Category Selection
                  Text(
                    'CATEGORIA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant.withOpacity(0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _category == cat;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        onSelected: (selected) {
                          if (selected) setState(() => _category = cat);
                        },
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colors.onPrimary
                              : colors.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: colors.surfaceContainerHighest
                            .withOpacity(0.5),
                        selectedColor: colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : colors.outline.withOpacity(0.1),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(
                          context,
                          icon: Icons.calendar_today_rounded,
                          label: _dueDate != null
                              ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                              : 'Sem data',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimePicker(
                          context,
                          icon: Icons.access_time_rounded,
                          label: _dueTime != null
                              ? _dueTime!.format(context)
                              : 'Sem horário',
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _dueTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() => _dueTime = picked);
                            }
                          },
                          onClear: _dueTime != null
                              ? () => setState(() => _dueTime = null)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isEditing ? 'Salvar Alterações' : 'Criar Tarefa',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = _priority == value;
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : colors.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : colors.outline.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                value == 'high'
                    ? Icons.keyboard_double_arrow_up_rounded
                    : value == 'low'
                    ? Icons.keyboard_double_arrow_down_rounded
                    : Icons.remove_rounded,
                color: isSelected ? color : colors.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : colors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
