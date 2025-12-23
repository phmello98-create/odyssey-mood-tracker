import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';
import 'package:odyssey/src/features/habits/data/habit_repository.dart';
import 'package:odyssey/src/features/time_tracker/data/time_tracking_repository.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/mood_record_repository.dart';

class HomeStatsSection extends ConsumerStatefulWidget {
  final bool habitRepoInitialized;

  const HomeStatsSection({super.key, required this.habitRepoInitialized});

  @override
  ConsumerState<HomeStatsSection> createState() => _HomeStatsSectionState();
}

class _HomeStatsSectionState extends ConsumerState<HomeStatsSection> {
  int _selectedChartIndex = 0; // 0: Habits, 1: Focus, 2: Mood
  int _chartViewMode = 0; // 0: Trend, 1: Analysis
  int _focusTouchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (!widget.habitRepoInitialized) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return OdysseyCard(
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estatísticas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              // Chart Toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _chartViewMode = _chartViewMode == 0 ? 1 : 0;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _chartViewMode == 0
                          ? Icons.pie_chart_rounded
                          : Icons.show_chart_rounded,
                      key: ValueKey(_chartViewMode),
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Premium Category Selector Pills
          Row(
            children: [
              _buildPremiumTab(0, 'Hábitos', Icons.check_circle_outline),
              _buildPremiumTab(1, 'Foco', Icons.timer_outlined),
              _buildPremiumTab(2, 'Humor', Icons.mood_outlined),
            ],
          ),

          const SizedBox(height: 32),

          // Chart Area
          SizedBox(
            height: 220,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInBack,
              child: KeyedSubtree(
                key: ValueKey(_selectedChartIndex),
                child: _buildSelectedChart(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTab(int index, String label, IconData icon) {
    final isSelected = _selectedChartIndex == index;
    final colors = Theme.of(context).colorScheme;

    // Cores por categoria
    final categoryColors = [
      const Color(0xFF4CAF50), // Hábitos - Verde
      const Color(0xFF2196F3), // Foco - Azul
      const Color(0xFFFF9800), // Humor - Laranja
    ];
    final color = categoryColors[index];

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedChartIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChart(BuildContext context) {
    if (_chartViewMode == 1) {
      switch (_selectedChartIndex) {
        case 0:
          return _buildHabitsRadarChartAnalysis(context);
        case 1:
          return _buildFocusDonutChart(context);
        case 2:
          return _buildMoodFrequencyChart(context);
      }
    }

    switch (_selectedChartIndex) {
      case 0:
        return _buildHabitsBarChart(context);
      case 1:
        return _buildFocusLineChart(context);
      case 2:
        return _buildMoodTrendChart(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHabitsBarChart(BuildContext context) {
    final habitRepo = ref.watch(habitRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: habitRepo.box.listenable(),
      builder: (context, box, _) {
        final weekRates = habitRepo.getWeekCompletionRates();
        final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

        double totalRate = 0;
        for (var rate in weekRates.values) {
          totalRate += rate;
        }
        final avgRate = (totalRate / 7 * 100).toInt();

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnalysisBadge(
                  context,
                  'Média Semanal',
                  '$avgRate%',
                  Icons.bar_chart_rounded,
                  colors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colors.surfaceContainerHighest,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${(rod.toY * 100).toInt()}%',
                          TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '\nConcluído',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= 7) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayNames[value.toInt()],
                              style: TextStyle(
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final date = DateTime.now().subtract(
                      Duration(days: DateTime.now().weekday - 1 - i),
                    );
                    final dateKey =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final rate = weekRates[dateKey] ?? 0.0;
                    final isToday =
                        date.day == DateTime.now().day &&
                        date.month == DateTime.now().month;

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: rate,
                          color: isToday
                              ? colors.primary
                              : colors.primary.withValues(alpha: 0.4),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 1,
                            color: colors.surfaceContainerHighest.withOpacity(
                              0.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFocusLineChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timeRepo = ref.watch(timeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        final dailyMinutes = List.filled(7, 0.0);

        final allRecords = timeRepo.fetchAllTimeTrackingRecords();
        for (var record in allRecords) {
          if (record.startTime.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              record.startTime.isBefore(endOfWeek)) {
            final dayIndex = record.startTime.weekday - 1;
            if (dayIndex >= 0 && dayIndex < 7) {
              dailyMinutes[dayIndex] += record.durationInSeconds / 60;
            }
          }
        }

        final maxVal = dailyMinutes.reduce(max);

        if (maxVal == 0) {
          return Center(
            child: Text(
              'Sem sessões de foco',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        final totalMinutes = dailyMinutes.reduce(
          (value, element) => value + element,
        );
        final totalHours = totalMinutes / 60;
        final dailyAvg = totalHours / 7;

        final allPoints = <FlSpot>[];
        for (int i = 0; i < 7; i++) {
          allPoints.add(FlSpot(i.toDouble(), dailyMinutes[i]));
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnalysisBadge(
                  context,
                  'Total Semanal',
                  '${totalHours.toStringAsFixed(1)}h',
                  Icons.timer_rounded,
                  colors.secondary,
                ),
                const SizedBox(width: 12),
                _buildAnalysisBadge(
                  context,
                  'Média Diária',
                  '${(dailyAvg * 60).toInt()}m',
                  Icons.trending_up,
                  colors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Seg',
                            'Ter',
                            'Qua',
                            'Qui',
                            'Sex',
                            'Sáb',
                            'Dom',
                          ];
                          if (value < 0 || value >= 7) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colors.surfaceContainerHighest,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toInt()} min',
                            TextStyle(
                              color: colors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: allPoints,
                      isCurved: true,
                      color: colors.secondary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            colors.secondary.withValues(alpha: 0.2),
                            colors.secondary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFocusDonutChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timeRepo = ref.watch(timeTrackingRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: timeRepo.box.listenable(),
      builder: (context, box, _) {
        final records = timeRepo.fetchAllTimeTrackingRecords();
        if (records.isEmpty) {
          return Center(
            child: Text(
              'Ainda sem dados de foco',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        // Agrupar por categoria
        final Map<String, int> categories = {};
        for (var r in records) {
          final cat = r.category ?? 'Geral';
          categories[cat] = (categories[cat] ?? 0) + r.durationInSeconds;
        }

        final sortedCats = categories.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCats = sortedCats.take(4).toList();

        final total = categories.values.fold(0, (sum, v) => sum + v);

        final List<PieChartSectionData> sections = [];
        final List<Color> pieColors = [
          colors.primary,
          colors.secondary,
          colors.tertiary,
          colors.error,
        ];

        for (int i = 0; i < topCats.length; i++) {
          final isTouched = i == _focusTouchedIndex;
          final fontSize = isTouched ? 16.0 : 12.0;
          final radius = isTouched ? 60.0 : 50.0;
          final percentage = (topCats[i].value / total * 100).toInt();

          sections.add(
            PieChartSectionData(
              color: pieColors[i % pieColors.length],
              value: topCats[i].value.toDouble(),
              title: '$percentage%',
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _focusTouchedIndex = -1;
                          return;
                        }
                        _focusTouchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(topCats.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: pieColors[i % pieColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        topCats[i].key,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodTrendChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final moodRepo = ref.watch(moodRecordRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: moodRepo.box.listenable(),
      builder: (context, box, _) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));

        final allRecords = moodRepo.fetchMoodRecords().values.toList();
        final List<FlSpot> points = [];

        // Valor do humor: 1 (péssimo) a 5 (ótimo)
        final Map<String, List<int>> dailyMoods = {};

        for (var record in allRecords) {
          if (record.date.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              record.date.isBefore(endOfWeek)) {
            final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
            if (!dailyMoods.containsKey(dateKey)) dailyMoods[dateKey] = [];
            dailyMoods[dateKey]!.add(record.score);
          }
        }

        for (int i = 0; i < 7; i++) {
          final date = startOfWeek.add(Duration(days: i));
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          if (dailyMoods.containsKey(dateKey)) {
            final avg =
                dailyMoods[dateKey]!.reduce((a, b) => a + b) /
                dailyMoods[dateKey]!.length;
            points.add(FlSpot(i.toDouble(), avg));
          } else {
            // Se não tiver registro, podemos colocar 0 ou ignorar.
            // Aqui optamos por não adicionar o ponto para não distorcer o gráfico.
          }
        }

        if (points.isEmpty) {
          return Center(
            child: Text(
              'Ainda sem registros de humor',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnalysisBadge(
                  context,
                  'Tendência',
                  'Estável',
                  Icons.trending_flat,
                  colors.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 1,
                  maxY: 5,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.outlineVariant.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Seg',
                            'Ter',
                            'Qua',
                            'Qui',
                            'Sex',
                            'Sáb',
                            'Dom',
                          ];
                          if (value < 0 || value >= 7) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 1:
                              return const Text(
                                '😫',
                                style: TextStyle(fontSize: 10),
                              );
                            case 3:
                              return const Text(
                                '😐',
                                style: TextStyle(fontSize: 10),
                              );
                            case 5:
                              return const Text(
                                '🤩',
                                style: TextStyle(fontSize: 10),
                              );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: colors.tertiary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.tertiary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodFrequencyChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final moodRepo = ref.watch(moodRecordRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: moodRepo.box.listenable(),
      builder: (context, box, _) {
        final records = moodRepo.fetchMoodRecords().values.toList();
        if (records.isEmpty) {
          return Center(
            child: Text(
              'Ainda sem dados de humor',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          );
        }

        final counts = List.filled(5, 0);
        for (var r in records) {
          final idx = r.score - 1;
          if (idx >= 0 && idx < 5) counts[idx]++;
        }

        final total = records.length;
        final barGroups = List.generate(5, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[i].toDouble(),
                color: [
                  WellnessColors.error,
                  Colors.orange,
                  Colors.amber,
                  WellnessColors.primary,
                  WellnessColors.success,
                ][i],
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        });

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnalysisBadge(
                  context,
                  'Total de Registros',
                  '$total',
                  Icons.history_rounded,
                  colors.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const icons = ['😫', '🙁', '😐', '🙂', '🤩'];
                          if (value < 0 || value >= 5) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(icons[value.toInt()]),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHabitsRadarChartAnalysis(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Just a placeholder for radar chart as it's more complex to implement correctly
    // with actual habit data without proper categorization.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radar_rounded,
            size: 48,
            color: colors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Análise Multidimensional',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          Text(
            'Em breve: Visão 360º dos seus hábitos',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisBadge(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
