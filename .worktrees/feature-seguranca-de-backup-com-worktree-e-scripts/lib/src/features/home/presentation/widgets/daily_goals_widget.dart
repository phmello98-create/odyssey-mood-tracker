import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';

/// Widget minimalista estilo iOS - Histórico visual dos últimos 7 dias
/// Inspirado no GitHub contributions e Apple Activity
class DailyGoalsWidget extends ConsumerWidget {
  const DailyGoalsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    
    // Pegar registros de humor dos últimos 7 dias
    Map<DateTime, int> activityMap = {};
    try {
      final moodRepo = ref.watch(moodRecordRepositoryProvider);
      final records = moodRepo.fetchMoodRecords();
      
      for (final record in records.values) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        activityMap[date] = (activityMap[date] ?? 0) + 1;
      }
    } catch (_) {}

    // Últimos 7 dias
    final days = List.generate(7, (i) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      return _DayData(
        date: date,
        count: activityMap[date] ?? 0,
        isToday: i == 6,
      );
    });

    final totalThisWeek = days.fold<int>(0, (sum, d) => sum + d.count);
    final activeDays = days.where((d) => d.count > 0).length;

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
                  Icons.insights_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sua semana',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '$activeDays/7 dias ativos',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Grid de dias - estilo minimalista
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) => _buildDayCell(context, day, colors)).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Barra de progresso semanal sutil
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: activeDays / 7,
                minHeight: 4,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  activeDays >= 5 
                    ? const Color(0xFF4CAF50) 
                    : activeDays >= 3 
                      ? const Color(0xFF2196F3)
                      : colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, _DayData day, ColorScheme colors) {
    final dayNames = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    final dayName = dayNames[day.date.weekday % 7];
    
    // Intensidade baseada na atividade
    final intensity = day.count == 0 
      ? 0.0 
      : day.count == 1 
        ? 0.4 
        : day.count == 2 
          ? 0.7 
          : 1.0;
    
    final baseColor = day.isToday ? colors.primary : const Color(0xFF4CAF50);
    
    return Column(
      children: [
        Text(
          dayName,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: day.count > 0 
              ? baseColor.withValues(alpha: intensity)
              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: day.isToday 
              ? Border.all(color: colors.primary, width: 2)
              : null,
          ),
          child: Center(
            child: day.count > 0
              ? Text(
                  '${day.count}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: intensity > 0.5 ? Colors.white : colors.onSurface,
                  ),
                )
              : null,
          ),
        ),
      ],
    );
  }
}

class _DayData {
  final DateTime date;
  final int count;
  final bool isToday;
  
  _DayData({required this.date, required this.count, required this.isToday});
}

// Manter provider para compatibilidade
final dailyMissionsProvider = FutureProvider.autoDispose<DailyMissionsStatus>((ref) async {
  return DailyMissionsStatus(hasMood: false, hasTask: false, hasPomodoro: false);
});

class DailyMissionsStatus {
  final bool hasMood;
  final bool hasTask;
  final bool hasPomodoro;
  DailyMissionsStatus({required this.hasMood, required this.hasTask, required this.hasPomodoro});
  int get completed => (hasMood ? 1 : 0) + (hasTask ? 1 : 0) + (hasPomodoro ? 1 : 0);
}
