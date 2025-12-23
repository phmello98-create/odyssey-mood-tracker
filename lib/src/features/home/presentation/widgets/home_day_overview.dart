import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/providers/timer_provider.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/features/notes/data/notes_repository.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';

import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';

class HomeDayOverview extends ConsumerWidget {
  const HomeDayOverview({
    super.key,
    required this.habitRepoInitialized,
    required this.taskRepoInitialized,
    this.onTapTasks,
    this.onTapNotes,
    this.onTapMood,
    this.onTapTimer,
  });

  final bool habitRepoInitialized;
  final bool taskRepoInitialized;
  final VoidCallback? onTapTasks;
  final VoidCallback? onTapNotes;
  final VoidCallback? onTapMood;
  final VoidCallback? onTapTimer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final timerState = ref.watch(timerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.2),
                      colors.tertiary.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visão Geral',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMM', 'pt_BR').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (timerState.isRunning)
                _ActiveTimerIndicator(timerState: timerState),
            ],
          ),
          const SizedBox(height: 16),

          // Grid de Overview Items
          if (!habitRepoInitialized || !taskRepoInitialized)
            _buildLoadingGrid(colors)
          else
            _buildOverviewGrid(context, ref, colors, timerState),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(ColorScheme colors) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: List.generate(
        6,
        (index) => _OverviewItemPlaceholder(colors: colors),
      ),
    );
  }

  Widget _buildOverviewGrid(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
    TimerState timerState,
  ) {
    final taskRepo = ref.watch(taskRepositoryProvider);
    final notesRepo = ref.watch(notesRepositoryProvider);
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final timeTrackingRepo = ref.watch(timeTrackingRepositoryProvider);

    return FutureBuilder(
      future: Future.wait<dynamic>([
        taskRepo.getPendingTasksForToday(),
        Future.value(notesRepo.getAllNotes()),
        Future.value(moodRepo.fetchMoodRecords()),
        Future.value(
          timeTrackingRepo.fetchTimeTrackingRecordsByDate(DateTime.now()),
        ),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingGrid(colors);
        }

        final results = snapshot.data as List<dynamic>;
        final tasks = results[0] as List<TaskData>;
        final notes = results[1] as List<Map<String, dynamic>>;
        final moodRecordsMap = results[2] as Map<dynamic, MoodRecord>;
        final timeRecords = results[3] as List<TimeTrackingRecord>;

        final moodRecords = moodRecordsMap.values.toList();

        final totalFocusMinutes = timeRecords.fold<int>(
          0,
          (sum, record) => sum + record.duration.inMinutes,
        );

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: [
            _OverviewItem(
              icon: Icons.check_circle_outline_rounded,
              label: 'Tarefas',
              value: '${tasks.length}',
              subtitle: 'pendentes',
              color: Colors.blue,
              onTap: onTapTasks ?? () {},
            ),
            _OverviewItem(
              icon: Icons.notes_rounded,
              label: 'Notas',
              value: '${notes.length}',
              subtitle: 'criadas',
              color: Colors.amber,
              onTap: onTapNotes ?? () {},
            ),
            _OverviewItem(
              icon: Icons.mood_rounded,
              label: 'Humor',
              value: moodRecords.isNotEmpty
                  ? _getMoodEmoji(moodRecords.first.score)
                  : '—',
              subtitle: 'hoje',
              color: Colors.purple,
              onTap: onTapMood ?? () {},
            ),
            _OverviewItem(
              icon: Icons.timer_outlined,
              label: 'Foco',
              value: '${totalFocusMinutes}m',
              subtitle: 'hoje',
              color: Colors.orange,
              onTap: onTapTimer ?? () {},
              isActive: timerState.isRunning,
            ),
            _OverviewItem(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              value: '12', // Mock
              subtitle: 'dias',
              color: Colors.redAccent,
              onTap: () {},
            ),
            _OverviewItem(
              icon: Icons.star_outline_rounded,
              label: 'Nível',
              value: '8', // Mock
              subtitle: 'Explorer',
              color: Colors.teal,
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  String _getMoodEmoji(int level) {
    if (level >= 5) return '🤩';
    if (level >= 4) return '🙂';
    if (level >= 3) return '😐';
    if (level >= 2) return '😔';
    return '😫';
  }
}

class _ActiveTimerIndicator extends StatefulWidget {
  const _ActiveTimerIndicator({required this.timerState});
  final TimerState timerState;

  @override
  State<_ActiveTimerIndicator> createState() => _ActiveTimerIndicatorState();
}

class _ActiveTimerIndicatorState extends State<_ActiveTimerIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: WellnessColors.success.withValues(
              alpha: 0.15 * _animation.value,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: WellnessColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: WellnessColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Ativo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: WellnessColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const Spacer(),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewItemPlaceholder extends StatelessWidget {
  const _OverviewItemPlaceholder({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
