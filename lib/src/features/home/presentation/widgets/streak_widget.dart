import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odyssey/src/features/gamification/data/gamification_repository.dart';
import 'package:odyssey/src/constants/app_theme.dart';

class StreakWidget extends ConsumerStatefulWidget {
  const StreakWidget({super.key});

  @override
  ConsumerState<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends ConsumerState<StreakWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _countController;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _todayCompleted = 0;
  int _weekCompleted = 0;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final box = await Hive.openBox('gamification');
      final repo = GamificationRepository(box);
      final stats = repo.getStats();
      setState(() {
        _currentStreak = stats.currentStreak;
        _longestStreak = stats.longestStreak;
        _todayCompleted = stats.tasksCompleted;
        _weekCompleted = stats.pomodoroSessions;
      });
      _countController.forward();
    } catch (e) {
      debugPrint('Error loading streak: $e');
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const fireColor = Color(0xFFFF9500);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com streak principal
          Row(
            children: [
              // Fire icon com glow
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9500), Color(0xFFFF3B30)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: fireColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Streak count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedBuilder(
                          animation: _countController,
                          builder: (context, child) {
                            final progress = Curves.easeOut.transform(
                              _countController.value.clamp(0.0, 1.0),
                            );
                            return Text(
                              '${(_currentStreak * progress).round()}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: fireColor,
                                height: 1,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'dias',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Sequência atual',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Record badge
              if (_longestStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 14,
                        color: Color(0xFFFFCC00),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_longestStreak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFCC00),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats pills row
          Row(
            children: [
              // Tarefas pill
              Expanded(
                child: _buildStatPill(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Tarefas',
                  value: '$_todayCompleted',
                  color: WellnessColors.success,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 10),
              // Pomodoros pill
              Expanded(
                child: _buildStatPill(
                  icon: Icons.timer_rounded,
                  label: 'Pomodoros',
                  value: '$_weekCompleted',
                  color: WellnessColors.primary,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 10),
              // Melhor streak pill
              Expanded(
                child: _buildStatPill(
                  icon: Icons.emoji_events_rounded,
                  label: 'Melhor',
                  value: '$_longestStreak d',
                  color: const Color(0xFFFF9500),
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
