import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart' as showcase;

class HabitsCalendarScreen extends ConsumerStatefulWidget {
  const HabitsCalendarScreen({super.key});

  @override
  ConsumerState<HabitsCalendarScreen> createState() => _HabitsCalendarScreenState();
}

class _HabitsCalendarScreenState extends ConsumerState<HabitsCalendarScreen> {
  // Showcase keys
  final GlobalKey _showcaseAdd = GlobalKey();
  // Showcase keys
  final GlobalKey _showcaseCalendar = GlobalKey();
  // Showcase keys
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
        _completionCountPerDay[normalizedDate] = (_completionCountPerDay[normalizedDate] ?? 0) + 1;
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
      final normalizedDate = DateTime(checkDate.year, checkDate.month, checkDate.day);
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: UltravioletColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final streak = _calculateStreak();
    final monthCompletions = _getMonthCompletions();
    final selectedDayHabits = _getHabitsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: UltravioletColors.background,
      appBar: AppBar(
        backgroundColor: UltravioletColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calendário de Hábitos',
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
                      icon: Icons.repeat,
                      value: '${_habits.length}',
                      label: 'Hábitos',
                      color: UltravioletColors.primary,
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
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: UltravioletColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: UltravioletColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  titleTextStyle: const TextStyle(
                    color: UltravioletColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: UltravioletColors.onSurfaceVariant),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: UltravioletColors.onSurfaceVariant),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: const TextStyle(color: UltravioletColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                  weekendStyle: TextStyle(color: UltravioletColors.onSurfaceVariant.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: UltravioletColors.onSurface.withOpacity(0.6)),
                  defaultTextStyle: const TextStyle(color: UltravioletColors.onSurface),
                  todayDecoration: BoxDecoration(
                    color: UltravioletColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: UltravioletColors.onSurface, fontWeight: FontWeight.w600),
                  selectedDecoration: const BoxDecoration(
                    color: UltravioletColors.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                                      ? UltravioletColors.primary
                                      : UltravioletColors.tertiary,
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
                  const Icon(Icons.event_note, color: UltravioletColors.primary, size: 20),
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

            // Habits completed on selected day
            if (selectedDayHabits.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: OdysseyCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sentiment_neutral,
                        size: 48,
                        color: UltravioletColors.onSurfaceVariant.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhum hábito completado',
                        style: TextStyle(
                          color: UltravioletColors.onSurfaceVariant,
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
                itemCount: selectedDayHabits.length,
                itemBuilder: (context, index) {
                  final habit = selectedDayHabits[index];
                  return _buildHabitCompletedCard(habit);
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
            style: const TextStyle(
              fontSize: 11,
              color: UltravioletColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCompletedCard(Habit habit) {
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
            child: Center(
              child: Icon(
                IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                color: Color(habit.colorValue),
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
                  habit.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Concluído',
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
            Icons.check_circle,
            color: UltravioletColors.accentGreen,
            size: 24,
          ),
        ],
      ),
    );
  }
}
