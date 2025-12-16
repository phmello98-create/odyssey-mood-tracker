import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Widget estilo GitHub Contributions - Grid de atividade dos últimos 12 semanas
class ActivityGridWidget extends ConsumerWidget {
  const ActivityGridWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    
    // Coletar atividades dos últimos 84 dias (12 semanas)
    final activityMap = _collectActivity(ref, now);
    
    // Gerar grid de 12 semanas x 7 dias
    final weeks = _generateWeeks(now, activityMap);
    
    // Estatísticas
    final totalDays = weeks.expand((w) => w).where((d) => d.level > 0).length;
    final currentStreak = _calculateStreak(weeks);

    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outline.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Atividade',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                if (currentStreak > 0) ...[
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$currentStreak dias',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ] else
                  Text(
                    '$totalDays dias ativos',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Grid de contribuições
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeks.map((week) => _buildWeekColumn(context, week, colors)).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Menos',
                  style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
                ),
                const SizedBox(width: 4),
                ...List.generate(5, (i) => _buildLegendCell(colors, i / 4)),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.more,
                  style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, int> _collectActivity(WidgetRef ref, DateTime now) {
    final Map<DateTime, int> activity = {};
    
    // Mood records
    try {
      final moodRepo = ref.watch(moodRecordRepositoryProvider);
      final records = moodRepo.fetchMoodRecords();
      for (final record in records.values) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        activity[date] = (activity[date] ?? 0) + 1;
      }
    } catch (_) {}
    
    // Completed tasks
    try {
      final taskRepo = ref.watch(taskRepositoryProvider);
      taskRepo.getAllTasks().then((tasks) {
        for (final task in tasks) {
          if (task.completed && task.completedAt != null) {
            final date = DateTime(task.completedAt!.year, task.completedAt!.month, task.completedAt!.day);
            activity[date] = (activity[date] ?? 0) + 1;
          }
        }
      });
    } catch (_) {}
    
    // Pomodoro sessions
    try {
      final timeRepo = ref.watch(timeTrackingRepositoryProvider);
      final sessions = timeRepo.fetchAllTimeTrackingRecords();
      for (final session in sessions) {
        if (session.isCompleted) {
          final date = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
          activity[date] = (activity[date] ?? 0) + 1;
        }
      }
    } catch (_) {}
    
    return activity;
  }

  List<List<_DayCell>> _generateWeeks(DateTime now, Map<DateTime, int> activityMap) {
    final List<List<_DayCell>> weeks = [];
    final today = DateTime(now.year, now.month, now.day);
    
    // Começar do domingo da semana 12 semanas atrás
    var startDate = today.subtract(Duration(days: 83 + today.weekday % 7));
    
    for (int week = 0; week < 12; week++) {
      final List<_DayCell> weekDays = [];
      
      for (int day = 0; day < 7; day++) {
        final date = startDate.add(Duration(days: week * 7 + day));
        final count = activityMap[date] ?? 0;
        final isToday = date.isAtSameMomentAs(today);
        final isFuture = date.isAfter(today);
        
        // Calcular nível (0-4) baseado na atividade
        int level = 0;
        if (!isFuture && count > 0) {
          if (count == 1) {
            level = 1;
          } else if (count == 2) level = 2;
          else if (count <= 4) level = 3;
          else level = 4;
        }
        
        weekDays.add(_DayCell(
          date: date,
          level: level,
          isToday: isToday,
          isFuture: isFuture,
        ));
      }
      
      weeks.add(weekDays);
    }
    
    return weeks;
  }

  int _calculateStreak(List<List<_DayCell>> weeks) {
    // Flatten e reverter para começar de hoje
    final allDays = weeks.expand((w) => w).toList().reversed.toList();
    
    int streak = 0;
    bool started = false;
    
    for (final day in allDays) {
      if (day.isFuture) continue;
      
      if (!started && day.isToday) {
        started = true;
        if (day.level > 0) streak++;
        continue;
      }
      
      if (started) {
        if (day.level > 0) {
          streak++;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }

  Widget _buildWeekColumn(BuildContext context, List<_DayCell> week, ColorScheme colors) {
    return Column(
      children: week.map((day) => _buildDayCell(context, day, colors)).toList(),
    );
  }

  Widget _buildDayCell(BuildContext context, _DayCell day, ColorScheme colors) {
    Color cellColor;
    
    if (day.isFuture) {
      cellColor = colors.surfaceContainerHighest.withValues(alpha: 0.3);
    } else {
      cellColor = _getLevelColor(day.level, colors);
    }
    
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
        border: day.isToday 
          ? Border.all(color: colors.primary, width: 1.5)
          : null,
      ),
    );
  }

  Widget _buildLegendCell(ColorScheme colors, double intensity) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: _getLevelColor((intensity * 4).round(), colors),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getLevelColor(int level, ColorScheme colors) {
    const baseColor = Color(0xFF4CAF50);
    
    switch (level) {
      case 0:
        return colors.surfaceContainerHighest;
      case 1:
        return baseColor.withValues(alpha: 0.25);
      case 2:
        return baseColor.withValues(alpha: 0.5);
      case 3:
        return baseColor.withValues(alpha: 0.75);
      case 4:
        return baseColor;
      default:
        return colors.surfaceContainerHighest;
    }
  }
}

class _DayCell {
  final DateTime date;
  final int level; // 0-4
  final bool isToday;
  final bool isFuture;
  
  _DayCell({
    required this.date,
    required this.level,
    required this.isToday,
    required this.isFuture,
  });
}
