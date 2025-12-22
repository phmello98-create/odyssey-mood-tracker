import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart';
import 'package:odyssey/src/features/mood_records/presentation/mood_log/mood_log_screen_controller.dart';
import 'package:odyssey/src/utils/icon_map.dart';
import 'package:odyssey/src/utils/widgets/staggered_list_animation.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart'
    as showcase;

class MoodRecordsScreen extends ConsumerStatefulWidget {
  const MoodRecordsScreen({super.key});

  static void showAddMoodRecordForm(
    context,
    MapEntry<dynamic, MoodRecord>? recordToEdit,
  ) {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>
            AddMoodRecordForm(recordToEdit: recordToEdit),
      ),
    );
  }

  @override
  ConsumerState<MoodRecordsScreen> createState() => _MoodRecordsScreenState();
}

class _MoodRecordsScreenState extends ConsumerState<MoodRecordsScreen> {
  DateTime _selectedDate = DateTime.now();

  // Showcase keys
  final GlobalKey _showcaseMoodChart = GlobalKey();
  final GlobalKey _showcaseAddMood = GlobalKey();
  final GlobalKey _showcaseMoodList = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initShowcase();
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.moodLog);
    super.dispose();
  }

  void _initShowcase() {
    final keys = [_showcaseMoodChart, _showcaseAddMood, _showcaseMoodList];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.moodLog,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.moodLog, keys);
  }

  void _startTour() {
    final keys = [_showcaseMoodChart, _showcaseAddMood, _showcaseMoodList];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.moodLog, keys);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(moodRecordScreenControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.surface,
      body: ValueListenableBuilder(
        valueListenable: controller.repository.box.listenable(),
        builder: (context, box, _) {
          final allRecords = box.values.toList().cast<MoodRecord>();

          final now = DateTime.now();
          final last7Days = List.generate(7, (i) {
            final d = now.subtract(Duration(days: 6 - i));
            return DateTime(d.year, d.month, d.day);
          });

          double averageMood = 0;
          if (allRecords.isNotEmpty) {
            averageMood =
                allRecords.map((e) => e.score).reduce((a, b) => a + b) /
                allRecords.length;
          }

          final todayRecords = allRecords
              .where((r) => _isSameDay(r.date, now))
              .length;
          final weekRecords = allRecords
              .where(
                (r) => r.date.isAfter(now.subtract(const Duration(days: 7))),
              )
              .length;

          final streak = _calculateStreak(allRecords);

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Header iOS style
                  SliverToBoxAdapter(
                    child: _buildIOSHeader(colors, streak, todayRecords),
                  ),

                  // Summary Card
                  SliverToBoxAdapter(
                    child: _buildSummaryCard(
                      colors,
                      averageMood,
                      weekRecords,
                      allRecords.length,
                    ),
                  ),

                  // Gráfico clean
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildCleanChart(
                        colors,
                        allRecords,
                        last7Days,
                        averageMood,
                      ),
                    ),
                  ),

                  // Mood Distribution
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildMoodDistribution(colors, allRecords),
                    ),
                  ),

                  // Insights Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildInsightsSection(colors, allRecords),
                    ),
                  ),

                  // Date Selector iOS style
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildIOSDateSelector(colors),
                    ),
                  ),

                  // Section Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildSectionHeader(colors, l10n),
                    ),
                  ),

                  // Records List
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: _buildRecordsList(allRecords, colors),
                  ),
                ],
              ),

              // Botão de adicionar discreto iOS style
              _buildIOSAddButton(colors),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIOSHeader(ColorScheme colors, int streak, int todayRecords) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.moodDiary,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.emotionalJourney,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: colors.tertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streak dias',
                      style: TextStyle(
                        color: colors.tertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (todayRecords > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$todayRecords hoje',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ColorScheme colors,
    double avgMood,
    int weekRecords,
    int totalRecords,
  ) {
    final moodColor = _getMoodColor(avgMood);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Ícone SVG do humor médio
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: SvgPicture.asset(
                  _getMoodSvgPath(avgMood.round()),
                  width: 36,
                  height: 36,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMoodLabel(avgMood),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Média: ${avgMood.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Stats
            Row(
              children: [
                _buildCompactStat(
                  value: '$weekRecords',
                  label: 'Semana',
                  colors: colors,
                ),
                const SizedBox(width: 16),
                _buildCompactStat(
                  value: '$totalRecords',
                  label: 'Total',
                  colors: colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat({
    required String value,
    required String label,
    required ColorScheme colors,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCleanChart(
    ColorScheme colors,
    List<MoodRecord> allRecords,
    List<DateTime> days,
    double avgMood,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.last7Days,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getMoodColor(avgMood).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.average(avgMood.toStringAsFixed(1)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getMoodColor(avgMood),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: _MoodChart(records: allRecords, days: days, colors: colors),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution(ColorScheme colors, List<MoodRecord> records) {
    if (records.isEmpty) return const SizedBox.shrink();

    final moodCounts = <int, int>{};
    for (final record in records) {
      moodCounts[record.score] = (moodCounts[record.score] ?? 0) + 1;
    }

    final moodLabels = {5: 'Ótimo', 4: 'Bem', 3: 'Ok', 2: 'Mal', 1: 'Péssimo'};
    final moodColors = {
      5: UltravioletColors.moodGreat,
      4: UltravioletColors.moodGood,
      3: UltravioletColors.moodOkay,
      2: UltravioletColors.moodBad,
      1: UltravioletColors.moodTerrible,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.moodDistribution,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...(moodCounts.entries.toList()
                ..sort((a, b) => b.key.compareTo(a.key)))
              .map((entry) {
                final percentage = (entry.value / records.length * 100);
                final moodColor = moodColors[entry.key]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        _getMoodSvgPath(entry.key),
                        width: 22,
                        height: 22,
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 50,
                        child: Text(
                          moodLabels[entry.key] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: colors.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(moodColor),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(ColorScheme colors, List<MoodRecord> records) {
    if (records.length < 3) return const SizedBox.shrink();

    final now = DateTime.now();

    // Calcular média da semana atual vs semana passada
    final thisWeekRecords = records
        .where((r) => r.date.isAfter(now.subtract(const Duration(days: 7))))
        .toList();
    final lastWeekRecords = records
        .where(
          (r) =>
              r.date.isAfter(now.subtract(const Duration(days: 14))) &&
              r.date.isBefore(now.subtract(const Duration(days: 7))),
        )
        .toList();

    double? weekComparison;
    if (thisWeekRecords.isNotEmpty && lastWeekRecords.isNotEmpty) {
      final thisWeekAvg =
          thisWeekRecords.map((r) => r.score).reduce((a, b) => a + b) /
          thisWeekRecords.length;
      final lastWeekAvg =
          lastWeekRecords.map((r) => r.score).reduce((a, b) => a + b) /
          lastWeekRecords.length;
      weekComparison = thisWeekAvg - lastWeekAvg;
    }

    // Melhor dia da semana
    final dayScores = <int, List<int>>{};
    for (final record in records) {
      final day = record.date.weekday;
      dayScores.putIfAbsent(day, () => []).add(record.score);
    }
    int? bestDay;
    double bestDayAvg = 0;
    for (final entry in dayScores.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avg > bestDayAvg) {
        bestDayAvg = avg;
        bestDay = entry.key;
      }
    }

    // Horário mais frequente
    final hourCounts = <int, int>{};
    for (final record in records) {
      final hour = record.date.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    int? mostFrequentHour;
    int maxCount = 0;
    for (final entry in hourCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostFrequentHour = entry.key;
      }
    }

    // Atividades associadas a bom humor (score >= 4)
    final goodMoodActivities = <String, int>{};
    for (final record in records.where((r) => r.score >= 4)) {
      for (final activity in record.activities) {
        goodMoodActivities[activity.activityName] =
            (goodMoodActivities[activity.activityName] ?? 0) + 1;
      }
    }
    final topActivities = goodMoodActivities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Maior sequência histórica
    int longestStreak = _calculateLongestStreak(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Insights',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cards de insights em grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Comparação com semana anterior
            if (weekComparison != null)
              _buildInsightCard(
                colors,
                weekComparison > 0
                    ? Icons.trending_up_rounded
                    : weekComparison < 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded,
                weekComparison > 0
                    ? 'Melhora'
                    : weekComparison < 0
                    ? 'Queda'
                    : 'Estável',
                weekComparison > 0
                    ? '+${weekComparison.toStringAsFixed(1)} vs semana passada'
                    : weekComparison < 0
                    ? '${weekComparison.toStringAsFixed(1)} vs semana passada'
                    : 'Igual à semana passada',
                weekComparison > 0
                    ? UltravioletColors.moodGreat
                    : weekComparison < 0
                    ? UltravioletColors.moodBad
                    : colors.primary,
              ),

            // Melhor dia
            if (bestDay != null)
              _buildInsightCard(
                colors,
                Icons.calendar_today_rounded,
                _getWeekdayFull(bestDay),
                'Melhor dia (média ${bestDayAvg.toStringAsFixed(1)})',
                UltravioletColors.moodGood,
              ),

            // Horário mais frequente
            if (mostFrequentHour != null)
              _buildInsightCard(
                colors,
                Icons.schedule_rounded,
                _formatHour(mostFrequentHour),
                'Hora mais frequente',
                colors.tertiary,
              ),

            // Maior sequência
            if (longestStreak > 1)
              _buildInsightCard(
                colors,
                Icons.local_fire_department_rounded,
                '$longestStreak dias',
                'Maior sequência',
                Colors.orange,
              ),
          ],
        ),

        // Atividades que melhoram o humor
        if (topActivities.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_rounded,
                      size: 16,
                      color: UltravioletColors.moodGreat,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Atividades que melhoram seu humor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: topActivities.take(5).map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: UltravioletColors.moodGreat.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: UltravioletColors.moodGreat,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${e.value}x',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInsightCard(
    ColorScheme colors,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  int _calculateLongestStreak(List<MoodRecord> records) {
    if (records.isEmpty) return 0;

    final sortedDates =
        records
            .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
            .toSet()
            .toList()
          ..sort();

    if (sortedDates.isEmpty) return 0;

    int longest = 1;
    int current = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        longest = current > longest ? current : longest;
      } else {
        current = 1;
      }
    }

    return longest;
  }

  String _getWeekdayFull(int weekday) {
    const weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    return weekdays[weekday - 1];
  }

  String _formatHour(int hour) {
    if (hour < 6) return 'Madrugada';
    if (hour < 12) return 'Manhã';
    if (hour < 18) return 'Tarde';
    return 'Noite';
  }

  Widget _buildIOSDateSelector(ColorScheme colors) {
    final today = DateTime.now();

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: 7 - index));
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, today);
          final hasMoodRecord = _hasMoodRecordForDate(date);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDate = date);
            },
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayAbbr(date.weekday),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : colors.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? colors.primary
                          : colors.onSurface,
                      fontSize: 17,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasMoodRecord
                          ? (isSelected ? Colors.white : colors.primary)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colors, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.dailyRecords,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        Text(
          DateFormat("d MMM", 'pt_BR').format(_selectedDate),
          style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildRecordsList(List<MoodRecord> allRecords, ColorScheme colors) {
    final filteredRecords = allRecords
        .where((record) => _isSameDay(record.date, _selectedDate))
        .toList();

    if (filteredRecords.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(colors));
    }

    filteredRecords.sort((a, b) => b.date.compareTo(a.date));

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final record = filteredRecords[index];
        return StaggeredListAnimation(
          index: index,
          child: _buildMoodCard(record, colors),
        );
      }, childCount: filteredRecords.length),
    );
  }

  Widget _buildMoodCard(MoodRecord record, ColorScheme colors) {
    final moodColor = Color(record.color);
    final timeFormat = DateFormat('HH:mm');
    final score = record.score;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            final controller = ref.read(
              moodRecordScreenControllerProvider.notifier,
            );
            final entry = controller.repository.box.toMap().entries.firstWhere(
              (e) => e.value == record,
            );
            MoodRecordsScreen.showAddMoodRecordForm(context, entry);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Ícone SVG com background
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      _getMoodSvgPath(score),
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            record.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Score badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: moodColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$score/5',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: moodColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Horário e data
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeFormat.format(record.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                _getRelativeDate(record.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (record.note != null && record.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.notes_outlined,
                              size: 14,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                record.note!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onSurfaceVariant,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (record.activities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: record.activities.take(4).map((activity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: moodColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    OdysseyIcons.fromCodePoint(
                                      activity.iconCode,
                                    ),
                                    size: 13,
                                    color: moodColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.activityName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Retorna a data relativa (Hoje, Ontem, ou data formatada)
  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoje';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Ontem';
    if (date.isAfter(now.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE', 'pt_BR').format(date);
    }
    return DateFormat('d MMM', 'pt_BR').format(date);
  }

  Widget _buildEmptyState(ColorScheme colors) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.sentiment_satisfied_alt_rounded,
                size: 32,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noRecords,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tapToRecordMood,
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSAddButton(ColorScheme colors) {
    return Positioned(
      bottom: 110,
      right: 20,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          MoodRecordsScreen.showAddMoodRecordForm(context, null);
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  int _calculateStreak(List<MoodRecord> records) {
    if (records.isEmpty) return 0;

    final sortedDates =
        records
            .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    if (!sortedDates.contains(todayDate) && !sortedDates.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = sortedDates.contains(todayDate)
        ? todayDate
        : yesterday;

    for (int i = 0; i < sortedDates.length; i++) {
      if (sortedDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Color _getMoodColor(double score) {
    if (score >= 4.5) return UltravioletColors.moodGreat;
    if (score >= 3.5) return UltravioletColors.moodGood;
    if (score >= 2.5) return UltravioletColors.moodOkay;
    if (score >= 1.5) return UltravioletColors.moodBad;
    return UltravioletColors.moodTerrible;
  }

  String _getMoodLabel(double score) {
    if (score >= 4.5) return 'Você está ótimo!';
    if (score >= 3.5) return 'Tudo bem!';
    if (score >= 2.5) return 'Humor estável';
    if (score >= 1.5) return 'Dia difícil';
    return 'Momento delicado';
  }

  /// Retorna o path do SVG do mood baseado no score
  String _getMoodSvgPath(int score) {
    switch (score) {
      case 5:
        return 'assets/emojis/noto_awesome.svg';
      case 4:
        return 'assets/emojis/noto_good.svg';
      case 3:
        return 'assets/emojis/noto_neutral.svg';
      case 2:
        return 'assets/emojis/noto_bad.svg';
      case 1:
      default:
        return 'assets/emojis/noto_terrible.svg';
    }
  }

  String _getWeekdayAbbr(int weekday) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return weekdays[weekday - 1];
  }

  bool _hasMoodRecordForDate(DateTime date) {
    final controller = ref.read(moodRecordScreenControllerProvider.notifier);
    final allRecords = controller.repository.box.values
        .toList()
        .cast<MoodRecord>();
    return allRecords.any((record) => _isSameDay(record.date, date));
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    return a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;
  }
}

class _MoodChart extends StatelessWidget {
  final List<MoodRecord> records;
  final List<DateTime> days;
  final ColorScheme colors;

  const _MoodChart({
    required this.records,
    required this.days,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight - 20;

        final dailyMoods = days.map((day) {
          final dayRecords = records
              .where(
                (r) =>
                    r.date.year == day.year &&
                    r.date.month == day.month &&
                    r.date.day == day.day,
              )
              .toList();

          if (dayRecords.isEmpty) return null;

          final sum = dayRecords.map((r) => r.score).reduce((a, b) => a + b);
          return sum / dayRecords.length;
        }).toList();

        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                size: Size(width, height),
                painter: _ChartPainter(
                  dailyMoods: dailyMoods,
                  color: colors.primary,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((day) {
                return Text(
                  DateFormat('E', 'pt_BR').format(day)[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double?> dailyMoods;
  final Color color;
  final Color backgroundColor;

  _ChartPainter({
    required this.dailyMoods,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    bool firstPoint = true;
    final segmentWidth = size.width / dailyMoods.length;

    for (int i = 0; i < dailyMoods.length; i++) {
      final mood = dailyMoods[i];
      if (mood == null) continue;

      final normalizedY = size.height - ((mood - 1) / 4 * size.height);
      final x = (i * segmentWidth) + (segmentWidth / 2);

      if (firstPoint) {
        path.moveTo(x, normalizedY);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, normalizedY);
        firstPoint = false;
      } else {
        final prevMood = _findPrevMood(i - 1);
        if (prevMood != null) {
          final prevIndex = _findPrevIndex(i - 1);
          final prevX = (prevIndex * segmentWidth) + (segmentWidth / 2);
          final prevY = size.height - ((prevMood - 1) / 4 * size.height);

          final controlPoint1X = prevX + (x - prevX) / 2;
          final controlPoint1Y = prevY;
          final controlPoint2X = prevX + (x - prevX) / 2;
          final controlPoint2Y = normalizedY;

          path.cubicTo(
            controlPoint1X,
            controlPoint1Y,
            controlPoint2X,
            controlPoint2Y,
            x,
            normalizedY,
          );
          fillPath.cubicTo(
            controlPoint1X,
            controlPoint1Y,
            controlPoint2X,
            controlPoint2Y,
            x,
            normalizedY,
          );
        } else {
          path.lineTo(x, normalizedY);
          fillPath.lineTo(x, normalizedY);
        }
      }
    }

    if (!firstPoint) {
      final lastIndex = _findLastIndex();
      final lastX = (lastIndex * segmentWidth) + (segmentWidth / 2);
      fillPath.lineTo(lastX, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);

      // Desenhar pontos
      for (int i = 0; i < dailyMoods.length; i++) {
        final mood = dailyMoods[i];
        if (mood == null) continue;

        final normalizedY = size.height - ((mood - 1) / 4 * size.height);
        final x = (i * segmentWidth) + (segmentWidth / 2);

        canvas.drawCircle(Offset(x, normalizedY), 4, Paint()..color = color);
        canvas.drawCircle(
          Offset(x, normalizedY),
          2,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  double? _findPrevMood(int index) {
    for (int i = index; i >= 0; i--) {
      if (dailyMoods[i] != null) return dailyMoods[i];
    }
    return null;
  }

  int _findPrevIndex(int index) {
    for (int i = index; i >= 0; i--) {
      if (dailyMoods[i] != null) return i;
    }
    return 0;
  }

  int _findLastIndex() {
    for (int i = dailyMoods.length - 1; i >= 0; i--) {
      if (dailyMoods[i] != null) return i;
    }
    return 0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
