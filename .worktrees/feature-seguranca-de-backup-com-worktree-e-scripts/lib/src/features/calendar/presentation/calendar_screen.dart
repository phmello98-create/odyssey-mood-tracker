import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';
import 'package:odyssey/src/features/time_tracker/data/synced_time_tracking_repository.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/onboarding/onboarding.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart' as showcase;

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Showcase keys
  final GlobalKey _showcaseCalendar = GlobalKey();
  final GlobalKey _showcaseDayDetails = GlobalKey();
  final GlobalKey _showcaseFormat = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }
  
  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.calendar);
    super.dispose();
  }

  void _initShowcase() {
    final keys = [_showcaseCalendar, _showcaseDayDetails, _showcaseFormat];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.calendar,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.calendar, keys);
  }

  void _startTour() {
    final keys = [_showcaseCalendar, _showcaseDayDetails, _showcaseFormat];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.calendar, keys);
  }

  List<TaskData> _getTasksForDay(DateTime day, List<TaskData> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return _isSameDay(task.dueDate, day);
    }).toList();
  }

  String _getRelativeDateLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today).inDays;
    
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = l10n.localeName == 'en';
    
    if (difference == 0) {
      return l10n.today;
    } else if (difference == 1) {
      return l10n.tomorrow;
    } else if (difference == -1) {
      return isEnglish ? 'Yesterday' : 'Ontem';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final moodRepo = ref.watch(moodRecordRepositoryProvider);
    final timeRepo = ref.watch(syncedTimeTrackingRepositoryProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);

    final colors = Theme.of(context).colorScheme;
    
    return FirstTimeDetector(
      screenId: 'calendar_screen',
      category: FeatureCategory.general,
      tourId: null, // No tour defined yet for calendar
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.agenda),
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: Builder(
        builder: (context) {
          final taskListenable = taskRepo.boxListenable;
          if (taskListenable == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ValueListenableBuilder(
            valueListenable: taskListenable,
            builder: (context, taskBox, _) {
              // Parse tasks from box
              final allTasks = taskBox.keys.map((key) {
                final data = taskBox.get(key);
                if (data is Map) {
                  return TaskData.fromMap(key, Map<String, dynamic>.from(data));
                }
                return null;
              }).whereType<TaskData>().toList();
              
              return ValueListenableBuilder(
                valueListenable: moodRepo.box.listenable(),
                builder: (context, moodBox, _) {
                  return ValueListenableBuilder(
                    valueListenable: timeRepo.box.listenable(),
                    builder: (context, timeBox, _) {
                      final moodRecords = moodBox.values.cast<MoodRecord>().toList();
                      final timeRecords = timeBox.values.cast<TimeTrackingRecord>().toList();

                      // Get records for selected day
                      final selectedMoods = moodRecords
                          .where((r) => _isSameDay(r.date, _selectedDay))
                          .toList();
                      final selectedTimes = timeRecords
                          .where((r) => _isSameDay(r.startTime, _selectedDay))
                          .toList();
                  final selectedTasks = _getTasksForDay(_selectedDay, allTasks);
                  final relativeLabel = _getRelativeDateLabel(context, _selectedDay);

                  return Column(
                    children: [
                      // Calendar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TableCalendar<dynamic>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          locale: 'pt_BR',
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!isSameDay(_selectedDay, selectedDay)) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            }
                          },
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          eventLoader: (day) {
                            final moods = moodRecords.where((r) => _isSameDay(r.date, day)).length;
                            final times = timeRecords.where((r) => _isSameDay(r.startTime, day)).length;
                            final tasks = _getTasksForDay(day, allTasks).length;
                        return List.generate(moods + times + tasks, (_) => 'event');
                      },
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        defaultTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        selectedDecoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: UltravioletColors.accentGradient,
                          ),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                        markerDecoration: const BoxDecoration(
                          color: Color(0xFF07E092),
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 3,
                        markerSize: 6,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        formatButtonDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        formatButtonTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        titleTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        weekendStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selected day header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy', 'pt_BR').format(_selectedDay),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (relativeLabel.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    relativeLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (selectedMoods.isNotEmpty || selectedTimes.isNotEmpty || selectedTasks.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF07E092).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${selectedMoods.length + selectedTimes.length + selectedTasks.length} registros',
                              style: const TextStyle(
                                color: Color(0xFF07E092),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Records list
                  Expanded(
                    child: (selectedMoods.isEmpty && selectedTimes.isEmpty && selectedTasks.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_note_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum registro neste dia',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Adicione humor, sessões de foco ou tarefas',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (selectedTasks.isNotEmpty) ...[
                                _buildSectionHeader(AppLocalizations.of(context)!.tasks, Icons.check_circle_outline, const Color(0xFF8B5CF6)),
                                ...selectedTasks.map((t) => _buildTaskCard(t)),
                                const SizedBox(height: 16),
                              ],
                              if (selectedMoods.isNotEmpty) ...[
                                _buildSectionHeader('Humor', Icons.mood, UltravioletColors.moodGood),
                                ...selectedMoods.map((m) => _buildMoodCard(m)),
                              ],
                              if (selectedTimes.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildSectionHeader('Tempo Focado', Icons.timer, Theme.of(context).colorScheme.secondary),
                                ...selectedTimes.map((t) => _buildTimeCard(t)),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
},
      ),
    ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(MoodRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color(record.color).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(record.color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getMoodEmoji(record.label),
                style: const TextStyle(fontSize: 22),
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (record.note != null && record.note!.isNotEmpty)
                  Text(
                    record.note!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(record.date),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(TimeTrackingRecord record) {
    final hours = record.duration.inHours;
    final minutes = record.duration.inMinutes.remainder(60);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timer,
              color: Theme.of(context).colorScheme.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.activityName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hours > 0 ? '${hours}h ${minutes}min' : '${minutes}min',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(record.startTime),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
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

  Widget _buildTaskCard(TaskData task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final priorityColors = {
      'high': Colors.red,
      'medium': Colors.orange,
      'low': Colors.green,
    };
    final color = priorityColors[task.priority] ?? const Color(0xFF8B5CF6);
    
    // Calculate task tags
    List<Widget> tags = [];
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = l10n.localeName == 'en';
    
    if (task.dueDate != null) {
      final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final difference = dueDate.difference(today).inDays;
      
      if (!task.completed) {
        if (difference < 0) {
          // Overdue
          final daysOverdue = difference.abs();
          tags.add(_buildTag(
            '🔥 ${daysOverdue}d ${isEnglish ? "late" : "atrasada"}',
            Colors.red,
            Colors.red.withValues(alpha: 0.15),
          ));
        } else if (difference == 0) {
          // Today
          tags.add(_buildTag(
            '📌 ${l10n.today.toUpperCase()}',
            const Color(0xFF8B5CF6),
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ));
        } else if (difference == 1) {
          // Tomorrow
          tags.add(_buildTag(
            '⏰ ${l10n.tomorrow}',
            Colors.blue,
            Colors.blue.withValues(alpha: 0.15),
          ));
        } else if (difference <= 3) {
          // Next few days
          tags.add(_buildTag(
            '📅 ${isEnglish ? "In $difference days" : "Em $difference dias"}',
            Colors.orange,
            Colors.orange.withValues(alpha: 0.15),
          ));
        } else if (difference <= 7) {
          // This week
          tags.add(_buildTag(
            '🗓️ ${l10n.thisWeek}',
            Colors.teal,
            Colors.teal.withValues(alpha: 0.15),
          ));
        }
      } else {
        // Completed
        final completedTime = task.completedAt ?? now;
        final completedDuration = now.difference(completedTime);
        
        if (completedDuration.inHours < 1) {
          tags.add(_buildTag(
            '✨ ${isEnglish ? "Just done" : "Acabou"}',
            const Color(0xFF07E092),
            const Color(0xFF07E092).withValues(alpha: 0.15),
          ));
        } else if (completedDuration.inDays == 0) {
          tags.add(_buildTag(
            '✓ ${l10n.today}',
            const Color(0xFF07E092),
            const Color(0xFF07E092).withValues(alpha: 0.15),
          ));
        }
      }
    }
    
    // Priority tag
    if (task.priority == 'high' && !task.completed) {
      tags.add(_buildTag(
        '⚡ ${isEnglish ? "URGENT" : "URGENTE"}',
        Colors.red,
        Colors.red.withValues(alpha: 0.15),
      ));
    }
    
    // Time tag
    if (task.dueTime != null && !task.completed) {
      tags.add(_buildTag(
        '🕐 ${task.dueTime}',
        Theme.of(context).colorScheme.secondary,
        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
      ));
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.completed 
              ? const Color(0xFF07E092).withValues(alpha: 0.3)
              : color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: task.completed
                      ? const Color(0xFF07E092).withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: task.completed ? const Color(0xFF07E092) : color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.category != null && task.category!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          task.category!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    return a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;
  }
}