import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;

class HabitsCalendarScreen extends ConsumerStatefulWidget {
  const HabitsCalendarScreen({super.key});

  @override
  ConsumerState<HabitsCalendarScreen> createState() =>
      _HabitsCalendarScreenState();
}

class _HabitsCalendarScreenState extends ConsumerState<HabitsCalendarScreen> {
  // Showcase keys
  final GlobalKey _showcaseAdd = GlobalKey();
  final GlobalKey _showcaseCalendar = GlobalKey();
  final GlobalKey _showcaseStreak = GlobalKey();

  late HabitRepository _habitRepo;
  bool _isLoading = true;
  List<Habit> _habits = [];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Track completions per day
  final Map<DateTime, List<Habit>> _completedHabitsPerDay = {};
  final Map<DateTime, int> _completionCountPerDay = {};

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _initData();
  }

  Future<void> _initData() async {
    try {
      _habitRepo = HabitRepository();
      await _habitRepo.init();
      _loadHabits();
    } catch (e) {
      debugPrint('Error initializing habit repo: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadHabits() {
    _habits = _habitRepo.getAllHabits();
    _calculateCompletions();
    if (mounted) setState(() => _isLoading = false);
  }

  void _calculateCompletions() {
    _completedHabitsPerDay.clear();
    _completionCountPerDay.clear();

    for (final habit in _habits) {
      for (final date in habit.completedDates) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        _completedHabitsPerDay.putIfAbsent(normalizedDate, () => []);
        _completedHabitsPerDay[normalizedDate]!.add(habit);
        _completionCountPerDay[normalizedDate] =
            (_completionCountPerDay[normalizedDate] ?? 0) + 1;
      }
    }
  }

  List<Habit> _getHabitsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _completedHabitsPerDay[normalizedDay] ?? [];
  }

  int _getCompletionCountForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _completionCountPerDay[normalizedDay] ?? 0;
  }

  // Calculate streak
  int _calculateStreak() {
    if (_habits.isEmpty) return 0;

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

  void _initShowcase() {
    final keys = [_showcaseStreak, _showcaseCalendar, _showcaseAdd];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.habits,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.habits, keys);
  }

  void _startTour() {
    final keys = [_showcaseStreak, _showcaseCalendar, _showcaseAdd];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.habits, keys);
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.habits);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    final streak = _calculateStreak();
    final monthCompletions = _getMonthCompletions();
    final selectedDayHabits = _getHabitsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: colors.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendário de Hábitos',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: colors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: colors.primary),
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
                      context: context,
                      icon: Icons.local_fire_department,
                      value: '$streak',
                      label: 'Dias seguidos',
                      color: colors.error, // Orange-like color in themes
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.check_circle_outline,
                      value: '$monthCompletions',
                      label: 'Este mês',
                      color: colors.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.repeat,
                      value: '${_habits.length}',
                      label: 'Hábitos',
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
              child: TableCalendar<Habit>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getHabitsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'pt_BR',
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  leftChevronIcon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: colors.onSurface,
                      size: 18,
                    ),
                  ),
                  rightChevronIcon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: colors.onSurface,
                      size: 18,
                    ),
                  ),
                  headerMargin: const EdgeInsets.only(bottom: 16),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: colors.error.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.8),
                  ),
                  defaultTextStyle: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  todayDecoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  todayTextStyle: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  selectedTextStyle: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  markerDecoration: BoxDecoration(
                    color: colors.tertiary,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  markerSize: 5,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
                  cellMargin: const EdgeInsets.all(6),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: events.take(3).map((e) {
                          final habit = e as Habit;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Color(habit.colorValue),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event_note,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hábitos Completados',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        DateFormat('d MMMM', 'pt_BR').format(_selectedDay),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Habits completed on selected day
            if (selectedDayHabits.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: colors.outline.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum hábito neste dia',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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
                itemCount: selectedDayHabits.length,
                itemBuilder: (context, index) {
                  final habit = selectedDayHabits[index];
                  return _buildHabitCompletedCard(context, habit);
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCompletedCard(BuildContext context, Habit habit) {
    final colors = Theme.of(context).colorScheme;
    final habitColor = Color(habit.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: habitColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: habitColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
              color: habitColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Concluído',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: colors.tertiary, size: 24),
        ],
      ),
    );
  }
}
