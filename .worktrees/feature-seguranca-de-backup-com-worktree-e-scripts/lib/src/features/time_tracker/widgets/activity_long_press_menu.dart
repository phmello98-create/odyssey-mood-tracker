import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/utils/icon_map.dart';

/// Menu de ações para long-press em atividades do timer
/// Opções: Editar, Editar Tempo, Marcar/Desmarcar, Excluir, Duplicar
class ActivityLongPressMenu extends StatelessWidget {
  final TimeTrackingRecord record;
  final VoidCallback onEdit;
  final VoidCallback onEditTime;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const ActivityLongPressMenu({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onEditTime,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onDuplicate,
  });

  static Future<void> show({
    required BuildContext context,
    required TimeTrackingRecord record,
    required VoidCallback onEdit,
    required VoidCallback onEditTime,
    required Future<bool> Function() onToggleComplete,
    required VoidCallback onDelete,
    required VoidCallback onDuplicate,
  }) async {
    HapticFeedback.mediumImpact();
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ActivityLongPressMenuSheet(
        record: record,
        onEdit: () {
          Navigator.pop(ctx);
          onEdit();
        },
        onEditTime: () {
          Navigator.pop(ctx);
          onEditTime();
        },
        onToggleComplete: () async {
          final shouldProceed = await onToggleComplete();
          if (shouldProceed && ctx.mounted) {
            Navigator.pop(ctx);
          }
        },
        onDelete: () {
          Navigator.pop(ctx);
          onDelete();
        },
        onDuplicate: () {
          Navigator.pop(ctx);
          onDuplicate();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ActivityLongPressMenuSheet extends StatelessWidget {
  final TimeTrackingRecord record;
  final VoidCallback onEdit;
  final VoidCallback onEditTime;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _ActivityLongPressMenuSheet({
    required this.record,
    required this.onEdit,
    required this.onEditTime,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCompleted = record.isCompleted;
    final recordColor = record.colorValue != null 
        ? Color(record.colorValue!) 
        : colors.primary;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Header com info da tarefa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Ícone colorido
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: recordColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      OdysseyIcons.fromCodePoint(record.iconCode),
                      color: recordColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.activityName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(record.duration),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF07E092).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: Color(0xFF07E092),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Concluída',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF07E092),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
            
            // Menu de ações
            _MenuOption(
              icon: Icons.edit_rounded,
              label: 'Editar Detalhes',
              subtitle: 'Nome, categoria, projeto, notas',
              color: colors.primary,
              onTap: onEdit,
            ),
            
            _MenuOption(
              icon: Icons.schedule_rounded,
              label: 'Editar Tempo',
              subtitle: 'Ajustar duração da atividade',
              color: const Color(0xFF9B51E0),
              onTap: onEditTime,
            ),
            
            _MenuOption(
              icon: isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
              label: isCompleted ? 'Desmarcar como Concluída' : 'Marcar como Concluída',
              subtitle: isCompleted 
                  ? 'Voltar para pendente' 
                  : 'Definir como finalizada',
              color: isCompleted ? Colors.orange : const Color(0xFF07E092),
              onTap: onToggleComplete,
            ),
            
            _MenuOption(
              icon: Icons.copy_rounded,
              label: 'Duplicar',
              subtitle: 'Criar cópia desta atividade',
              color: const Color(0xFF00B4D8),
              onTap: onDuplicate,
            ),
            
            Divider(height: 1, color: colors.outline.withValues(alpha: 0.1)),
            
            _MenuOption(
              icon: Icons.delete_outline_rounded,
              label: 'Excluir',
              subtitle: 'Remover permanentemente',
              color: colors.error,
              onTap: onDelete,
              isDestructive: true,
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDestructive ? 0.1 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? color : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
