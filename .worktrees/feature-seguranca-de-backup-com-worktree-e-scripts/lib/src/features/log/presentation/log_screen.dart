import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/time_tracker/data/synced_time_tracking_repository.dart';
import 'package:odyssey/src/features/habits/domain/habit.dart';
import 'package:odyssey/src/utils/icon_map.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _viewTabController;
  bool _isListView = true;
  late ScrollController _calendarScrollController;

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 7, vsync: this); // 7 abas agora
    _calendarScrollController = ScrollController();
    
    // Scroll para o dia atual depois do build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    // Calcula a posição do dia atual
    final today = DateTime.now();
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysDiff = today.difference(firstDay).inDays + 7; // +7 porque mostramos 7 dias antes
    const itemWidth = 60.0; // 52 + margins
    final offset = (daysDiff * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
    
    if (_calendarScrollController.hasClients) {
      _calendarScrollController.animateTo(
        offset.clamp(0.0, _calendarScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.history,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // View toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildViewToggle(Icons.view_list, true),
                        _buildViewToggle(Icons.grid_view, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Calendar
            SizedBox(
              height: 100,
              child: _buildHorizontalCalendar(),
            ),

            // Type filter tabs - Scrollable para caber todas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _viewTabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  dividerColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tabs: [
                    const Tab(text: 'Tudo'),
                    const Tab(text: 'Humor'),
                    Tab(text: AppLocalizations.of(context)!.habits),
                    Tab(text: AppLocalizations.of(context)!.tasks),
                    const Tab(text: 'Tempo'),
                    const Tab(text: '📖 Leitura'),
                    const Tab(text: '📝 Notas'),
                  ],
                ),
              ),
            ),

            // Stats do dia selecionado
            _buildDayStats(moodRepo, timeRepo),

            // Content
            Expanded(
              child: TabBarView(
                controller: _viewTabController,
                children: [
                  _buildAllRecordsView(moodRepo, timeRepo),
                  _buildMoodRecordsView(moodRepo),
                  _buildHabitsRecordsView(),
                  _buildTasksRecordsView(),
                  _buildTimeRecordsView(timeRepo),
                  _buildReadingRecordsView(timeRepo),
                  _buildNotesRecordsView(),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildViewToggle(IconData icon, bool isListView) {
    final isSelected = _isListView == isListView;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isListView = isListView);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDayStats(MoodRecordRepository moodRepo, SyncedTimeTrackingRepository timeRepo) {
    // Using key to force rebuild when date changes
    return FutureBuilder<_DayStatsData>(
      key: ValueKey(_selectedDate),
      future: _calculateDayStats(moodRepo, timeRepo),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? _DayStatsData(0, '-', Theme.of(context).colorScheme.onSurfaceVariant, Duration.zero);
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  '${stats.totalRecords}',
                  'registros',
                  Icons.timeline,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  stats.avgMood,
                  'humor médio',
                  Icons.mood,
                  stats.avgMoodColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStat(
                  _formatTrackedTime(stats.totalTime),
                  'tempo rastreado',
                  Icons.timer,
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_DayStatsData> _calculateDayStats(MoodRecordRepository moodRepo, SyncedTimeTrackingRepository timeRepo) async {
    int totalRecords = 0;
    Duration totalTime = Duration.zero;
    String avgMood = '-';
    Color avgMoodColor = Theme.of(context).colorScheme.onSurfaceVariant;
    
    // Mood records
    final moodRecords = moodRepo.box.values
        .cast<MoodRecord>()
        .where((r) => _isSameDay(r.date, _selectedDate))
        .toList();
    totalRecords += moodRecords.length;
    
    // Calculate average mood
    if (moodRecords.isNotEmpty) {
      final moodScores = {'Ótimo': 5, 'Great': 5, 'Bem': 4, 'Good': 4, 'Ok': 3, 'Okay': 3, 'Alright': 3, 'Mal': 2, 'Bad': 2, 'Triste': 2, 'Péssimo': 1, 'Terrible': 1};
      final avgScore = moodRecords.map((m) => moodScores[m.label] ?? 3).reduce((a, b) => a + b) / moodRecords.length;
      if (avgScore >= 4.5) { avgMood = '😊 Ótimo'; avgMoodColor = UltravioletColors.moodGreat; }
      else if (avgScore >= 3.5) { avgMood = '🙂 Bem'; avgMoodColor = UltravioletColors.moodGood; }
      else if (avgScore >= 2.5) { avgMood = '😐 Ok'; avgMoodColor = UltravioletColors.moodOkay; }
      else if (avgScore >= 1.5) { avgMood = '😔 Mal'; avgMoodColor = UltravioletColors.moodBad; }
      else { avgMood = '😢 Péssimo'; avgMoodColor = UltravioletColors.moodTerrible; }
    }
    
    // Time records
    final timeRecords = timeRepo.box.values
        .cast<TimeTrackingRecord>()
        .where((r) => _isSameDay(r.startTime, _selectedDate))
        .toList();
    totalRecords += timeRecords.length;
    totalTime = timeRecords.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.duration,
    );
    
    // Habits completed
    try {
      final habitsBox = await Hive.openBox<Habit>('habits');
      final completedHabits = habitsBox.values
          .where((h) => h.isCompletedOn(_selectedDate))
          .length;
      totalRecords += completedHabits;
    } catch (e) {
      debugPrint('Error loading habits for stats: $e');
    }
    
    // Tasks completed
    try {
      final tasksBox = await Hive.openBox('tasks');
      final completedTasks = tasksBox.values.where((t) {
        if (t is Map && t['completed'] == true && t['completedAt'] != null) {
          final completedAt = DateTime.tryParse(t['completedAt']);
          return completedAt != null && _isSameDay(completedAt, _selectedDate);
        }
        return false;
      }).length;
      totalRecords += completedTasks;
    } catch (e) {
      debugPrint('Error loading tasks for stats: $e');
    }
    
    // Notes count
    try {
      final notesBox = await Hive.openBox('quick_notes');
      final notesCount = notesBox.values.where((n) {
        if (n is Map && n['createdAt'] != null) {
          final createdAt = DateTime.tryParse(n['createdAt']);
          return createdAt != null && _isSameDay(createdAt, _selectedDate);
        }
        return false;
      }).length;
      totalRecords += notesCount;
    } catch (e) {
      debugPrint('Error loading notes for stats: $e');
    }
    
    return _DayStatsData(totalRecords, avgMood, avgMoodColor, totalTime);
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    final today = DateTime.now();
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final colors = Theme.of(context).colorScheme;
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    
    return ListView.builder(
      controller: _calendarScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: daysInMonth + 14,
      itemBuilder: (context, index) {
        final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final date = firstDay.add(Duration(days: index - 7));
        
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, today);
        final isCurrentMonth = date.month == _selectedDate.month;
        final isWeekend = date.weekday == 6 || date.weekday == 7;
        
        // Verificar se tem registros nesse dia
        final hasRecords = moodRepo.box.values
            .cast<MoodRecord>()
            .any((r) => _isSameDay(r.date, date));

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedDate = date);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 48,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary,
                        colors.primary.withValues(alpha: 0.85),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : isToday
                      ? colors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : isToday
                        ? colors.primary.withValues(alpha: 0.4)
                        : isCurrentMonth
                            ? colors.outline.withValues(alpha: 0.08)
                            : Colors.transparent,
                width: isToday && !isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias, // ← FIX: Previne vazamento do gradient
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dia da semana
                Text(
                  _getWeekdayAbbr(date.weekday),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : isWeekend && isCurrentMonth
                            ? colors.primary.withValues(alpha: 0.7)
                            : isCurrentMonth
                                ? colors.onSurfaceVariant.withValues(alpha: 0.7)
                                : colors.onSurfaceVariant.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Número do dia
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? colors.primary
                            : isCurrentMonth
                                ? colors.onSurface
                                : colors.onSurface.withValues(alpha: 0.35),
                    fontSize: isSelected ? 18 : 16,
                    fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                    height: 1,
                  ),
                  child: Text('${date.day}'),
                ),
                const SizedBox(height: 6),
                // Indicador de registros ou mês diferente
                if (date.month != _selectedDate.month)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.2)
                          : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getMonthAbbr(date.month).toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : colors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else if (hasRecords)
                  // Dot indicator para dias com registros
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : colors.primary.withValues(alpha: 0.7),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected ? Colors.white : colors.primary).withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllRecordsView(MoodRecordRepository moodRepo, SyncedTimeTrackingRepository timeRepo) {
    return ValueListenableBuilder(
      valueListenable: moodRepo.box.listenable(),
      builder: (context, moodBox, _) {
        return ValueListenableBuilder(
          valueListenable: timeRepo.box.listenable(),
          builder: (context, timeBox, _) {
            return FutureBuilder<List<_LogItem>>(
              future: _getAllRecordsForDate(moodBox, timeBox),
              builder: (context, snapshot) {
                final allItems = snapshot.data ?? [];

                if (allItems.isEmpty) {
                  return _buildEmptyState();
                }

                if (_isListView) {
                  return _buildListView(allItems);
                } else {
                  return _buildGridView(allItems);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<List<_LogItem>> _getAllRecordsForDate(Box moodBox, Box timeBox) async {
    final allItems = <_LogItem>[];
    
    // Mood records
    final moodRecords = moodBox.values
        .cast<MoodRecord>()
        .where((r) => _isSameDay(r.date, _selectedDate))
        .toList();
    for (final m in moodRecords) {
      allItems.add(_LogItem(type: 'mood', date: m.date, data: m));
    }
    
    // Time records
    final timeRecords = timeBox.values
        .cast<TimeTrackingRecord>()
        .where((r) => _isSameDay(r.startTime, _selectedDate))
        .toList();
    for (final t in timeRecords) {
      allItems.add(_LogItem(type: 'time', date: t.startTime, data: t));
    }
    
    // Habits completions
    try {
      final habitsBox = await Hive.openBox<Habit>('habits');
      final habits = habitsBox.values.toList();
      
      for (final habit in habits) {
        if (habit.isCompletedOn(_selectedDate)) {
          // Cria um registro de hábito completado
          allItems.add(_LogItem(
            type: 'habit',
            date: _selectedDate,
            data: habit,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading habits: $e');
    }
    
    // Tasks completed
    try {
      final tasksBox = await Hive.openBox('tasks');
      final tasks = tasksBox.values.where((t) {
        if (t is Map && t['completed'] == true && t['completedAt'] != null) {
          final completedAt = DateTime.tryParse(t['completedAt']);
          return completedAt != null && _isSameDay(completedAt, _selectedDate);
        }
        return false;
      }).toList();
      
      for (final task in tasks) {
        final completedAt = DateTime.parse(task['completedAt']);
        allItems.add(_LogItem(
          type: 'task',
          date: completedAt,
          data: task,
        ));
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
    
    // Pomodoro sessions
    try {
      final pomodoroBox = await Hive.openBox('pomodoro_sessions');
      final sessions = pomodoroBox.values.where((s) {
        if (s is Map && s['completedAt'] != null) {
          final completedAt = DateTime.tryParse(s['completedAt']);
          return completedAt != null && _isSameDay(completedAt, _selectedDate);
        }
        return false;
      }).toList();
      
      for (final session in sessions) {
        final completedAt = DateTime.parse(session['completedAt']);
        allItems.add(_LogItem(
          type: 'pomodoro',
          date: completedAt,
          data: session,
        ));
      }
    } catch (e) {
      debugPrint('Error loading pomodoro sessions: $e');
    }
    
    // Notes/Quick notes
    try {
      final notesBox = await Hive.openBox('quick_notes');
      final notes = notesBox.values.where((n) {
        if (n is Map && n['createdAt'] != null) {
          final createdAt = DateTime.tryParse(n['createdAt']);
          return createdAt != null && _isSameDay(createdAt, _selectedDate);
        }
        return false;
      }).toList();
      
      for (final note in notes) {
        final createdAt = DateTime.parse(note['createdAt']);
        allItems.add(_LogItem(
          type: 'note',
          date: createdAt,
          data: note,
        ));
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
    
    // Sort by date descending
    allItems.sort((a, b) => b.date.compareTo(a.date));
    
    return allItems;
  }

  Widget _buildMoodRecordsView(MoodRecordRepository moodRepo) {
    return ValueListenableBuilder(
      valueListenable: moodRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values
            .cast<MoodRecord>()
            .where((r) => _isSameDay(r.date, _selectedDate))
            .toList();
        
        records.sort((a, b) => b.date.compareTo(a.date));

        if (records.isEmpty) {
          return _buildEmptyState(message: 'Nenhum registro de humor');
        }

        final items = records.map((r) => _LogItem(type: 'mood', date: r.date, data: r)).toList();

        if (_isListView) {
          return _buildListView(items);
        } else {
          return _buildGridView(items);
        }
      },
    );
  }

  Widget _buildHabitsRecordsView() {
    return FutureBuilder<Box<Habit>>(
      future: Hive.openBox<Habit>('habits'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final box = snapshot.data!;
        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, habitBox, _) {
            final completedHabits = habitBox.values
                .where((h) => h.isCompletedOn(_selectedDate))
                .toList();
            
            if (completedHabits.isEmpty) {
              return _buildEmptyState(message: 'Nenhum hábito completado');
            }
            
            final items = completedHabits.map((h) => _LogItem(
              type: 'habit',
              date: _selectedDate,
              data: h,
            )).toList();
            
            if (_isListView) {
              return _buildListView(items);
            } else {
              return _buildGridView(items);
            }
          },
        );
      },
    );
  }

  Widget _buildTasksRecordsView() {
    return FutureBuilder<Box>(
      future: Hive.openBox('tasks'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final box = snapshot.data!;
        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, taskBox, _) {
            final completedTasks = taskBox.values.where((t) {
              if (t is Map && t['completed'] == true && t['completedAt'] != null) {
                final completedAt = DateTime.tryParse(t['completedAt']);
                return completedAt != null && _isSameDay(completedAt, _selectedDate);
              }
              return false;
            }).toList();
            
            if (completedTasks.isEmpty) {
              return _buildEmptyState(message: AppLocalizations.of(context)!.noTasksCompleted);
            }
            
            final items = completedTasks.map((t) {
              final completedAt = DateTime.parse(t['completedAt']);
              return _LogItem(type: 'task', date: completedAt, data: t);
            }).toList();
            
            items.sort((a, b) => b.date.compareTo(a.date));
            
            if (_isListView) {
              return _buildListView(items);
            } else {
              return _buildGridView(items);
            }
          },
        );
      },
    );
  }

  Widget _buildTimeRecordsView(SyncedTimeTrackingRepository timeRepo) {
    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = box.values
            .cast<TimeTrackingRecord>()
            .where((r) => _isSameDay(r.startTime, _selectedDate))
            .toList();
        
        records.sort((a, b) => b.startTime.compareTo(a.startTime));

        if (records.isEmpty) {
          return _buildEmptyState(message: 'Nenhum registro de tempo');
        }

        final items = records.map((r) => _LogItem(type: 'time', date: r.startTime, data: r)).toList();

        if (_isListView) {
          return _buildListView(items);
        } else {
          return _buildGridView(items);
        }
      },
    );
  }

  Widget _buildReadingRecordsView(SyncedTimeTrackingRepository timeRepo) {
    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        // Filter only reading sessions (category == 'Leitura')
        final records = box.values
            .cast<TimeTrackingRecord>()
            .where((r) => 
                _isSameDay(r.startTime, _selectedDate) &&
                r.category == 'Leitura')
            .toList();
        
        records.sort((a, b) => b.startTime.compareTo(a.startTime));

        if (records.isEmpty) {
          return _buildEmptyState(message: 'Nenhuma sessão de leitura');
        }

        final items = records.map((r) => _LogItem(type: 'reading', date: r.startTime, data: r)).toList();

        if (_isListView) {
          return _buildListView(items);
        } else {
          return _buildGridView(items);
        }
      },
    );
  }

  Widget _buildNotesRecordsView() {
    return FutureBuilder<Box>(
      future: Hive.openBox('quick_notes'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final box = snapshot.data!;
        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, notesBox, _) {
            final notes = notesBox.values.where((n) {
              if (n is Map && n['createdAt'] != null) {
                final createdAt = DateTime.tryParse(n['createdAt']);
                return createdAt != null && _isSameDay(createdAt, _selectedDate);
              }
              return false;
            }).toList();
            
            if (notes.isEmpty) {
              return _buildEmptyState(message: 'Nenhuma nota criada');
            }
            
            final items = notes.map((n) {
              final createdAt = DateTime.parse(n['createdAt']);
              return _LogItem(type: 'note', date: createdAt, data: n);
            }).toList();
            
            items.sort((a, b) => b.date.compareTo(a.date));
            
            if (_isListView) {
              return _buildListView(items);
            } else {
              return _buildGridView(items);
            }
          },
        );
      },
    );
  }

  Widget _buildListView(List<_LogItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: _buildTimelineItem(item, index, items.length),
        );
      },
    );
  }

  Widget _buildGridView(List<_LogItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value.clamp(0.0, 1.0),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: _buildGridCard(item),
        );
      },
    );
  }

  Widget _buildTimelineItem(_LogItem item, int index, int totalLength) {
    Color color;
    switch (item.type) {
      case 'mood':
        color = Color((item.data as MoodRecord).color);
        break;
      case 'habit':
        final habit = item.data as Habit;
        color = Color(habit.colorValue);
        break;
      case 'task':
        final task = item.data as Map;
        final priority = task['priority'] ?? 'medium';
        color = priority == 'high' ? Colors.red : priority == 'low' ? Colors.green : Colors.orange;
        break;
      case 'pomodoro':
        color = Colors.red.shade400;
        break;
      case 'reading':
        color = Colors.teal;
        break;
      case 'note':
        color = Colors.amber;
        break;
      default:
        color = Theme.of(context).colorScheme.secondary;
    }
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Text(
                timeFormat.format(item.date),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (index < totalLength - 1)
                Container(
                  width: 2,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.5),
                        color.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: _buildItemContent(item, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemContent(_LogItem item, Color color) {
    switch (item.type) {
      case 'mood':
        return _buildMoodContent(item.data as MoodRecord);
      case 'time':
        return _buildTimeContent(item.data as TimeTrackingRecord);
      case 'reading':
        return _buildReadingContent(item.data as TimeTrackingRecord, color);
      case 'habit':
        return _buildHabitContent(item.data as Habit, color);
      case 'task':
        return _buildTaskContent(item.data as Map, color);
      case 'pomodoro':
        return _buildPomodoroContent(item.data as Map, color);
      case 'note':
        return _buildNoteContent(item.data as Map, color);
      default:
        return const SizedBox();
    }
  }

  Widget _buildGridCard(_LogItem item) {
    Color color;
    String typeLabel;
    switch (item.type) {
      case 'mood':
        color = Color((item.data as MoodRecord).color);
        typeLabel = 'Humor';
        break;
      case 'habit':
        final habit = item.data as Habit;
        color = Color(habit.colorValue);
        typeLabel = 'Hábito';
        break;
      case 'task':
        final task = item.data as Map;
        final priority = task['priority'] ?? 'medium';
        color = priority == 'high' ? Colors.red : priority == 'low' ? Colors.green : Colors.orange;
        typeLabel = 'Tarefa';
        break;
      case 'pomodoro':
        color = Colors.red.shade400;
        typeLabel = 'Pomodoro';
        break;
      case 'reading':
        color = Colors.teal;
        typeLabel = 'Leitura';
        break;
      case 'note':
        color = Colors.amber;
        typeLabel = 'Nota';
        break;
      default:
        color = Theme.of(context).colorScheme.secondary;
        typeLabel = 'Tempo';
    }
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                typeLabel,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                timeFormat.format(item.date),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildItemContentCompact(item, color),
          ),
        ],
      ),
    );
  }

  Widget _buildItemContentCompact(_LogItem item, Color color) {
    switch (item.type) {
      case 'mood':
        return _buildMoodContentCompact(item.data as MoodRecord);
      case 'time':
        return _buildTimeContentCompact(item.data as TimeTrackingRecord);
      case 'reading':
        return _buildReadingContentCompact(item.data as TimeTrackingRecord, color);
      case 'habit':
        return _buildHabitContentCompact(item.data as Habit, color);
      case 'task':
        return _buildTaskContentCompact(item.data as Map, color);
      case 'pomodoro':
        return _buildPomodoroContentCompact(item.data as Map, color);
      case 'note':
        return _buildNoteContentCompact(item.data as Map, color);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMoodContent(MoodRecord record) {
    final timeFormat = DateFormat('HH:mm');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(record.color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _getMoodEmoji(record.label),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${timeFormat.format(record.date)} • ${_getRelativeTime(record.date)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(record.color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${record.score}/5',
                style: TextStyle(
                  color: Color(record.color),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        // Nota
        if (record.note != null && record.note!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Tags/Atividades
        if (record.activities.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: record.activities.take(4).map((activity) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Color(record.color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Color(record.color).withValues(alpha: 0.3)),
              ),
              child: Text(
                activity.activityName,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(record.color),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return DateFormat('dd/MM').format(date);
  }

  Widget _buildMoodContentCompact(MoodRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getMoodEmoji(record.label),
          style: const TextStyle(fontSize: 26),
        ),
        const Spacer(),
        Text(
          record.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (record.note != null && record.note!.isNotEmpty)
          Text(
            record.note!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildTimeContent(TimeTrackingRecord record) {
    final hours = record.duration.inHours;
    final minutes = record.duration.inMinutes.remainder(60);
    final seconds = record.duration.inSeconds.remainder(60);
    final timeFormat = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.timer,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.activityName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${timeFormat.format(record.startTime)} - ${timeFormat.format(record.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Duração
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDurationWithSeconds(hours, minutes, seconds),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        // Categoria
        if (record.category != null && record.category!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Categoria: ${record.category}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
        // Nota
        if (record.notes != null && record.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeContentCompact(TimeTrackingRecord record) {
    final hours = record.duration.inHours;
    final minutes = record.duration.inMinutes.remainder(60);
    final seconds = record.duration.inSeconds.remainder(60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer,
          color: Theme.of(context).colorScheme.secondary,
          size: 26,
        ),
        const Spacer(),
        Text(
          record.activityName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Text(
              _formatDurationWithSeconds(hours, minutes, seconds),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (record.category != null) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '• ${record.category}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ==========================================
  // READING CONTENT
  // ==========================================
  Widget _buildReadingContent(TimeTrackingRecord record, Color color) {
    final hours = record.duration.inHours;
    final minutes = record.duration.inMinutes.remainder(60);
    final seconds = record.duration.inSeconds.remainder(60);
    final timeFormat = DateFormat('HH:mm');
    
    // Extract book title from project field
    final bookTitle = record.project ?? 'Livro';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('📖', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${timeFormat.format(record.startTime)} - ${timeFormat.format(record.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Duração
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDurationWithSeconds(hours, minutes, seconds),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        // Nota
        if (record.notes != null && record.notes!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReadingContentCompact(TimeTrackingRecord record, Color color) {
    final hours = record.duration.inHours;
    final minutes = record.duration.inMinutes.remainder(60);
    final seconds = record.duration.inSeconds.remainder(60);
    final bookTitle = record.project ?? 'Livro';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('📖', style: TextStyle(fontSize: 26)),
        const Spacer(),
        Text(
          bookTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _formatDurationWithSeconds(hours, minutes, seconds),
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HABIT CONTENT
  // ==========================================
  Widget _buildHabitContent(Habit habit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
child: Icon(
                 OdysseyIcons.fromCodePoint(habit.iconCode),
                 color: color,
                 size: 20,
               ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Hábito completado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: color, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${habit.currentStreak}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHabitContentCompact(Habit habit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
Icon(
           OdysseyIcons.fromCodePoint(habit.iconCode),
           color: color,
           size: 26,
         ),
        const Spacer(),
        Text(
          habit.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Icon(Icons.local_fire_department, color: color, size: 12),
            const SizedBox(width: 2),
            Text(
              '${habit.currentStreak} dias',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TASK CONTENT
  // ==========================================
  Widget _buildTaskContent(Map task, Color color) {
    final title = task['title'] ?? 'Tarefa';
    final priority = task['priority'] ?? 'medium';
    final priorityLabel = priority == 'high' ? AppLocalizations.of(context)!.priorityHigh : priority == 'low' ? AppLocalizations.of(context)!.priorityLow : AppLocalizations.of(context)!.priorityMedium;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.done_all, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Tarefa concluída',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                priorityLabel,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskContentCompact(Map task, Color color) {
    final title = task['title'] ?? 'Tarefa';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          color: color,
          size: 26,
        ),
        const Spacer(),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Concluída ✓',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // POMODORO CONTENT
  // ==========================================
  Widget _buildPomodoroContent(Map session, Color color) {
    final duration = session['duration'] ?? 25;
    final activityName = session['activityName'] ?? 'Pomodoro';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🍅', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Sessão Pomodoro',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${duration}min',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPomodoroContentCompact(Map session, Color color) {
    final duration = session['duration'] ?? 25;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🍅', style: TextStyle(fontSize: 26)),
        const Spacer(),
        Text(AppLocalizations.of(context)!.pomodoro,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$duration minutos',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // NOTE CONTENT
  // ==========================================
  Widget _buildNoteContent(Map note, Color color) {
    final content = note['content'] ?? '';
    final title = note['title'] ?? AppLocalizations.of(context)!.quickNote;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('📝', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.edit_note, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.quickNote,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoteContentCompact(Map note, Color color) {
    final content = note['content'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('📝', style: TextStyle(fontSize: 26)),
        const Spacer(),
        Text(
          content.isNotEmpty ? content : 'Nota vazia',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.history,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message ?? 'Nenhum registro neste dia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd/MM/yyyy').format(_selectedDate),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(String label) {
    final moodEmojis = {
      'Great': '😊', 'Good': '🙂', 'Okay': '😐', 'Alright': '😐',
      'Bad': '😔', 'Terrible': '😢',
      'Ótimo': '😊', 'Bem': '🙂', 'Ok': '😐', 'Triste': '😔', 'Mal': '😢',
    };
    return moodEmojis[label] ?? '😐';
  }

  String _getWeekdayAbbr(int weekday) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return weekdays[weekday - 1];
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return months[month - 1];
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    return a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;
  }

  String _formatTrackedTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDurationWithSeconds(int hours, int minutes, int seconds) {
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class _LogItem {
  final String type;
  final DateTime date;
  final dynamic data;

  _LogItem({required this.type, required this.date, required this.data});
}

class _DayStatsData {
  final int totalRecords;
  final String avgMood;
  final Color avgMoodColor;
  final Duration totalTime;

  _DayStatsData(this.totalRecords, this.avgMood, this.avgMoodColor, this.totalTime);
}
