import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/home/data/home_widgets_provider.dart';
import 'package:odyssey/src/features/home/presentation/widgets/quick_notes_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/quick_pomodoro_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/daily_goals_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/activity_grid_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/streak_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/today_tasks_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/current_reading_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/quick_mood_widget.dart';
import 'package:odyssey/src/features/home/presentation/widgets/water_tracker_widget.dart';

/// Renderiza os widgets da home baseado nas configurações do usuário
class HomeWidgetRenderer extends ConsumerWidget {
  const HomeWidgetRenderer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledWidgets = ref.watch(enabledHomeWidgetsProvider);

    if (enabledWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: enabledWidgets.map((config) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildWidget(config.type),
        );
      }).toList(),
    );
  }

  Widget _buildWidget(HomeWidgetType type) {
    switch (type) {
      case HomeWidgetType.quickNotes:
        return const QuickNotesWidget();
      case HomeWidgetType.quickPomodoro:
        return const QuickPomodoroWidget();
      case HomeWidgetType.dailyGoals:
        return const DailyGoalsWidget();
      case HomeWidgetType.activityGrid:
        return const ActivityGridWidget();
      case HomeWidgetType.streak:
        return const StreakWidget();
      case HomeWidgetType.todayTasks:
        return const TodayTasksWidget();
      case HomeWidgetType.dailyQuote:
        return const _DailyQuoteWidget();
      case HomeWidgetType.weeklyChart:
        return const _WeeklyChartWidget();
      case HomeWidgetType.currentReading:
        return const CurrentReadingWidget();
      case HomeWidgetType.habits:
        return const _HabitsWidget();
      case HomeWidgetType.quickMood:
        return const QuickMoodWidget();
      case HomeWidgetType.weekCalendar:
        return const _WeekCalendarWidget();
      case HomeWidgetType.monthlyOverview:
        return const _MonthlyOverviewWidget();
      case HomeWidgetType.waterTracker:
        return const WaterTrackerWidget();
    }
  }
}

/// Widget de citação do dia (placeholder - a home já tem esse, pode ser customizado)
class _DailyQuoteWidget extends StatelessWidget {
  const _DailyQuoteWidget();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Lista de citações
    final quotes = [
      l10n.quotesMaslow1,
      l10n.quotesEpictetus,
      l10n.quotesLennon,
      l10n.quotesSocrates,
      l10n.quotesMaslow2,
    ];

    final todayQuote = quotes[DateTime.now().day % quotes.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7E57C2).withValues(alpha: 0.1),
            const Color(0xFF7E57C2).withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7E57C2).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Color(0xFF7E57C2),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todayQuote,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: colors.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.citacaoDoDia,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de gráfico semanal (placeholder simples)
class _WeeklyChartWidget extends StatelessWidget {
  const _WeeklyChartWidget();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF26A69A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.atividadeSemanal,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final isToday = index == todayIndex;
                final height =
                    15.0 + (index * 5) + (isToday ? 15 : 0); // Demo heights

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: height.clamp(10, 45),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [
                                  const Color(0xFF26A69A),
                                  const Color(
                                    0xFF26A69A,
                                  ).withValues(alpha: 0.7),
                                ]
                              : [
                                  const Color(
                                    0xFF26A69A,
                                  ).withValues(alpha: 0.4),
                                  const Color(
                                    0xFF26A69A,
                                  ).withValues(alpha: 0.2),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF26A69A)
                            : colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de hábitos (placeholder - integrar com habit_repository)
class _HabitsWidget extends StatelessWidget {
  const _HabitsWidget();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.repeat_rounded,
                  color: Color(0xFF5C6BC0),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.habitosDoDia,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.vejaSeusHabitosNoCalendario,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de calendário semanal (placeholder)
class _WeekCalendarWidget extends StatelessWidget {
  const _WeekCalendarWidget();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_view_week_rounded,
                  color: Color(0xFF42A5F5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Esta Semana',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isToday =
                  days[i].day == now.day && days[i].month == now.month;
              return Column(
                children: [
                  Text(
                    dayNames[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? const Color(0xFF42A5F5)
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF42A5F5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? null
                          : Border.all(
                              color: colors.outline.withValues(alpha: 0.2),
                            ),
                    ),
                    child: Center(
                      child: Text(
                        '${days[i].day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isToday ? Colors.white : colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Widget de visão mensal (placeholder)
class _MonthlyOverviewWidget extends StatelessWidget {
  const _MonthlyOverviewWidget();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthNames = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E57C2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF7E57C2),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${monthNames[now.month - 1]} ${now.year}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  context,
                  'Dias ativos',
                  '${now.day}',
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStat(
                  context,
                  'Progresso',
                  '${((now.day / 30) * 100).round()}%',
                  const Color(0xFF7E57C2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
