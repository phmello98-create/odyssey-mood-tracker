import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';

/// Tela de calendário de tarefas
class TasksCalendarScreen extends StatefulWidget {
  const TasksCalendarScreen({super.key});

  @override
  State<TasksCalendarScreen> createState() => _TasksCalendarScreenState();
}

class _TasksCalendarScreenState extends State<TasksCalendarScreen> {
  late Box _box;
  bool _isLoading = true;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Track completions per day
  final Map<DateTime, List<Map>> _completedTasksPerDay = {};
  final Map<DateTime, int> _completionCountPerDay = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _box = await Hive.openBox('tasks');
    _calculateCompletions();
    setState(() => _isLoading = false);
  }

  void _calculateCompletions() {
    _completedTasksPerDay.clear();
    _completionCountPerDay.clear();

    for (final key in _box.keys) {
      final task = _box.get(key) as Map;
      final completed = task['completed'] as bool? ?? false;

      if (completed && task['createdAt'] != null) {
        try {
          final createdAt = DateTime.parse(task['createdAt'] as String);
          final normalizedDate = DateTime(
            createdAt.year,
            createdAt.month,
            createdAt.day,
          );

          _completedTasksPerDay.putIfAbsent(normalizedDate, () => []);
          _completedTasksPerDay[normalizedDate]!.add({
            'id': key,
            'title': task['title'],
            'createdAt': createdAt,
          });
          _completionCountPerDay[normalizedDate] =
              (_completionCountPerDay[normalizedDate] ?? 0) + 1;
        } catch (e) {
          debugPrint('Error parsing date: $e');
        }
      }
    }
  }

  List<Map> _getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _completedTasksPerDay[normalizedDay] ?? [];
  }

  int _getCompletionCountForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _completionCountPerDay[normalizedDay] ?? 0;
  }

  // Calculate streak
  int _calculateStreak() {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final normalizedDate = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
      );
      final count = _completionCountPerDay[normalizedDate] ?? 0;

      if (count > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Calculate total completions this month
  int _getMonthCompletions() {
    int total = 0;
    final now = DateTime.now();

    _completionCountPerDay.forEach((date, count) {
      if (date.year == now.year && date.month == now.month) {
        total += count;
      }
    });

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    final streak = _calculateStreak();
    final monthCompletions = _getMonthCompletions();
    final selectedDayTasks = _getTasksForDay(_selectedDay);
    final totalTasks = _box.length;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calendário de Tarefas',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'Ir para hoje',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_fire_department,
                      value: '$streak',
                      label: 'Dias seguidos',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_outline,
                      value: '$monthCompletions',
                      label: 'Este mês',
                      color: UltravioletColors.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.task_alt,
                      value: '$totalTasks',
                      label: 'Total',
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Calendar
            OdysseyCard(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              child: TableCalendar<Map>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getTasksForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'pt_BR',
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  titleTextStyle: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: colors.onSurfaceVariant,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  weekendStyle: TextStyle(
                    color: colors.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                  defaultTextStyle: TextStyle(color: colors.onSurface),
                  todayDecoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: UltravioletColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  markerSize: 6,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    final count = events.length;
                    return Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          count > 3 ? 3 : count,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? UltravioletColors.accentGreen
                                  : index == 1
                                  ? colors.primary
                                  : colors.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),

            const SizedBox(height: 24),

            // Selected Day Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.event_note, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, d MMMM', 'pt_BR').format(_selectedDay),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tasks completed on selected day
            if (selectedDayTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: OdysseyCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sentiment_neutral,
                        size: 48,
                        color: colors.onSurfaceVariant.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma tarefa concluída',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: selectedDayTasks.length,
                itemBuilder: (context, index) {
                  final task = selectedDayTasks[index];
                  return _buildTaskCompletedCard(task);
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return OdysseyCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      backgroundColor: color.withOpacity(0.1),
      borderColor: color.withOpacity(0.2),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCompletedCard(Map task) {
    final colors = Theme.of(context).colorScheme;

    return OdysseyCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: UltravioletColors.accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle,
                color: UltravioletColors.accentGreen,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Concluída',
                  style: TextStyle(
                    fontSize: 12,
                    color: UltravioletColors.accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.task_alt,
            color: UltravioletColors.accentGreen,
            size: 24,
          ),
        ],
      ),
    );
  }
}
